require "rspotify"

class Api::V1::SongBracketSetupController < ApplicationController
  # TODO(stuppy): Get the market from the user, if known.
  MARKET = "US"
  BRACKET_SIZES = [4, 8, 16, 32, 64, 128]

  def initialize
    RSpotify.authenticate(ENV["SPOTIFY_CLIENT_ID"], ENV["SPOTIFY_CLIENT_SECRET"]) unless Rails.env.test?
  end

  def search
    query = params[:query] || params[:q]
    if query.blank?
      raise ActionController::BadRequest.new("query/q is required")
    end

    # TODO(stuppy): Is there a better way to do this?
    if Rails.env.test?
      render json: {}
      return
    end

    artists = RSpotify::Artist.search(query, market: MARKET)
    response = SearchResponse.new
    response.results.concat(
      artists.to_a.map { |artist| SearchResponse::Result.new(artist.name, artist.id) }
    )
    render json: response
  end

  def submit
    ref = params[:ref]
    refs = params[:refs]
    token = params[:token]

    next_page = nil
    selected_refs = nil
    if token.blank?
      raise ActionController::BadRequest.new("ref is required") if ref.blank?
      next_page = SubmitPage::ALBUMS
    else
      raise ActionController::BadRequest.new("refs is required") if refs.blank?
      selected_refs = refs.split(",").uniq
      submit_token = SubmitToken.from_token(token)
      ref = submit_token.ref
      case submit_token.page
      when SubmitPage::ALBUMS
        next_page = SubmitPage::TRACKS
      when SubmitPage::TRACKS
        next_page = SubmitPage::DONE
      else
        raise "unknown page: %s" % submit_token.page
      end
    end

    # TODO(stuppy): Is there a better way to do this?
    if Rails.env.test?
      render json: {}
      return
    end

    # Artist ID is the ref (from search).
    artist_id = ref

    response = SubmitResponse.new

    to_page_album = ->(album) {
      pa = SubmitResponse::Album.new(album.name, album.id)
      first_image = album.images.first
      pa.artwork = SubmitResponse::Image.new(first_image) if first_image
      # Assume selected if... selected.
      pa.selected = true
      return pa
    }

    puts next_page
    case next_page
    when SubmitPage::ALBUMS
      album_ids = get_album_ids(artist_id, MARKET)
      albums = get_full_albums(album_ids)
      response.albums.concat(albums.map(&to_page_album))
    when SubmitPage::DONE
      track_ids = selected_refs
      num_tracks = track_ids.length
      log2 = Math.log2(num_tracks)
      log2int = log2.to_i
      raise ActionController::BadRequest.new("refs must have a power of 2") if log2 != log2int
      raise ActionController::BadRequest.new("refs must have # entries: %s" % BRACKET_SIZES) unless BRACKET_SIZES.include?(log2int)
      tracks = get_tracks(track_ids, MARKET)
      albums = tracks.map { |track| track.album }.uniq { |album| album.id }
      # TODO(stuppy): Save the Bracket!
    when SubmitPage::TRACKS
      album_ids = selected_refs
      albums = get_full_albums(album_ids)
      tracks = albums.map { |album| album.tracks }.flatten
      top_track_ids_map = get_top_track_ids(artist_id, MARKET).map { |id| [id, true] }.to_h
      response.albums.concat(
        albums.map { |album|
          pa = to_page_album.call(album)
          pa.tracks.concat(
            album.tracks.map { |track|
              pt = SubmitResponse::Track.new(track.name, track.id)
              pt.selected = !!top_track_ids_map[track.id]
              pt.track_number = track.track_number
              pt
            }
          )
          pa
        }
      )
    else
      raise "unknown next_page: %s" % next_page
    end

    submit_token = SubmitToken.new
    submit_token.ref = ref
    submit_token.page = next_page
    response.token = submit_token.to_token

    render json: response
  end

  private

  class SearchResponse
    attr_reader :results

    def initialize
      @results = Array.new
    end

    class Result
      def initialize(name, ref)
        @name = name
        @ref = ref
      end
    end
  end

  module SubmitPage
    ALBUMS = "ALBUMS"
    TRACKS = "TRACKS"
    DONE = "DONE"
  end

  class SubmitToken
    attr_accessor :ref, :page

    def self.from_token(token)
      json = Base64.decode64(token)
      obj = JSON.parse(json)
      return SubmitToken.new(obj)
    end

    def initialize(obj = {})
      @ref = obj["ref"]
      @page = obj["page"]
    end

    def to_token()
      Base64.strict_encode64(self.to_json)
    end
  end

  class SubmitResponse
    attr_accessor :bracket_id, :page, :token
    attr_reader :albums

    def initialize
      @albums = Array.new
    end

    class Album
      attr_accessor :artwork, :selected
      attr_reader :name, :ref, :tracks

      def initialize(name, ref)
        @name = name
        @ref = ref
        @tracks = Array.new
      end
    end

    class Image
      attr_reader :url, :height, :width

      def initialize(obj = {})
        @url = obj["url"]
        @height = obj["height"]
        @width = obj["width"]
      end
    end

    class Track
      attr_accessor :selected, :track_number
      attr_reader :name, :ref

      def initialize(name, ref)
        @name = name
        @ref = ref
      end
    end
  end

  # RSpotify doesn't expose a way to get an Artist's albums from the album_id, which we know.
  # Additionally, the RSpotify::Album returned from RSpotify::Artist doesn't include the tracks.
  # SO, fetch the album ids directly, then lookup with the fuller-album lookup which includes
  # Tracks, so subsequent #tracks calls do NOT make the HTTP call (leads to too many calls).
  def get_album_ids(artist_id, market, limit: 50, offset: 0)
    response = RSpotify.get "artists/#{artist_id}/albums?market=#{market}&limit=#{limit}&offset=#{offset}"
    return response if RSpotify.raw_response
    return (response["items"] || []).map { |album| album["id"] }
  end

  def get_top_track_ids(artist_id, market)
    response = RSpotify.get "artists/#{artist_id}/top-tracks?market=#{market}"
    return response if RSpotify.raw_response
    return (response["tracks"] || []).map { |track| track["id"] }
  end

  def get_full_albums(album_ids)
    chunks = album_ids.each_slice(20).to_a
    all = chunks.map { |chunk|
      response = RSpotify.get "albums?ids=#{chunk.join(",")}"
      return response if RSpotify.raw_response
      return response["albums"].map { |album| RSpotify::Album.new(album) }
    }
    puts all
    return all.flatten
  end

  def get_tracks(track_ids, market)
    chunks = track_ids.each_slice(50).to_a
    all = chunks.map { |chunk|
      return RSpotify::Track.find(chunk, market: market)
    }
    puts all
    return all.flatten
  end
end
