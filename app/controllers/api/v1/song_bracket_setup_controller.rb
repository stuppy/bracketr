require "rspotify"

class Api::V1::SongBracketSetupController < ApplicationController
  # TODO(stuppy): Get the market from the user, if known.
  MARKET = "US"
  BRACKET_SIZES = [4, 8, 16, 32, 64, 128]
  DEFAULT_BRACKET_SIZE = 64

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
      artists.to_a.map { |artist|
        result = SearchResponse::Result.new(artist.name, artist.id)
        first_image = artist.images.first
        result.image = Image.new(first_image) if first_image
        result
      }
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
      selected_refs = (refs.is_a?(Array) ? refs : refs.split(",")).uniq
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
    response.page = next_page

    to_page_album = ->(album) {
      pa = SubmitResponse::Album.new(album.name, album.id)
      first_image = album.images.first
      pa.artwork = Image.new(first_image) if first_image
      # Assume selected if... selected.
      pa.selected = true
      return pa
    }

    case next_page
    when SubmitPage::ALBUMS
      album_ids = get_album_ids(artist_id, MARKET)
      albums = get_full_albums(album_ids)
      # Sort by the popularity DESC.
      albums.sort! { |a, b| b.popularity <=> a.popularity }
      # Then make unique by the name; the first one is kept (the more popular).
      albums.uniq! { |a| a.name }
      response.albums.concat(albums.map(&to_page_album))
    when SubmitPage::DONE
      artist = RSpotify::Artist.find(ref)
      track_ids = selected_refs
      num_tracks = track_ids.length
      raise ActionController::BadRequest.new(
        "refs must have # entries: [%s]; got %d" % [BRACKET_SIZES.join(", "), num_tracks]
      ) unless BRACKET_SIZES.include?(num_tracks)
      tracks = get_tracks(track_ids)
      bracket = Bracket.new(name: "Top %d %s tracks!" % [num_tracks, artist.name])
      data = Bracket::BData.new
      data.artist = artist
      data.count = num_tracks
      # Shuffle the quadrants/seeds for now.
      data.items = tracks.shuffle
      data.type = Bracket::BData::TYPE_SPOTIFY_TRACKS
      bracket.data = data
      bracket.save
      response.bracket_id = bracket.id
    when SubmitPage::TRACKS
      album_ids = selected_refs
      albums = get_full_albums(album_ids)
      has_artist = ->(track) { track.artists.any? { |artist| artist.id === artist_id } }
      tracks = albums.map { |album| album.tracks }.flatten.filter(&has_artist)
      # top_track_ids_map = get_top_track_ids(artist_id, MARKET).map { |id| [id, true] }.to_h
      # 2 ^ (log2(num tracks) truncated)
      top_count = tracks.any? ? [2 ** Math.log2(tracks.length).floor, DEFAULT_BRACKET_SIZE].min : 0
      track_ids = tracks.map { |track| track.id }
      # The existing tracks from albums do not have things like popularity, so load manually.
      # Fingers crossed that this doesn't trigger a TooManyRequests error.
      top_track_ids_map = get_tracks(track_ids)
        .max(top_count) { |track| track.popularity || 0 }
        .map { |track| [track.id, true] }
        .to_h
      response.albums.concat(
        albums.map { |album|
          pa = to_page_album.call(album)
          album_tracks = album.tracks.filter(&has_artist)
          pa.num_discs = album_tracks.map { |track| track.disc_number }.max
          pa.tracks.concat(
            album_tracks.map { |track|
              pt = SubmitResponse::Track.new(track.name, track.id)
              pt.selected = !!top_track_ids_map[track.id]
              pt.track_number = track.track_number
              pt.disc_number = track.disc_number
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

  class Image
    attr_reader :url, :height, :width

    def initialize(obj = {})
      @url = obj["url"]
      @height = obj["height"]
      @width = obj["width"]
    end
  end

  class SearchResponse
    attr_reader :results

    def initialize
      @results = Array.new
    end

    class Result
      attr_accessor :image

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
      attr_accessor :artwork, :selected, :num_discs
      attr_reader :name, :ref, :tracks

      def initialize(name, ref)
        @name = name
        @ref = ref
        @tracks = Array.new
      end
    end

    class Track
      attr_accessor :selected, :track_number, :disc_number
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
    response = RSpotify.get "artists/#{artist_id}/albums?country=#{market}&limit=#{limit}&offset=#{offset}"
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
    return chunks.map { |chunk| RSpotify::Album.find(chunk) }.flatten
  end

  def get_tracks(track_ids)
    chunks = track_ids.each_slice(50).to_a
    return chunks.map { |chunk| RSpotify::Track.find(chunk) }.flatten
  end
end
