require "rspotify"

class Api::V1::SongBracketSetupController < ApplicationController
  def search
    query = params[:query] || params[:q]
    if query.blank?
      raise ActionController::BadRequest.new("query/q is required")
    end

    RSpotify.authenticate(ENV["SPOTIFY_CLIENT_ID"], ENV["SPOTIFY_CLIENT_SECRET"])
    # TODO(stuppy): Get the market from the user, if known.
    artists = RSpotify::Artist.search(query, market: "US")
    response = SearchResponse.new
    response.add_results(
      artists.to_a.map { |artist| SearchResponse::Result.new(artist.name, artist.id) }
    )
    render json: response
  end

  def select
    ref = params[:ref]
    if ref.blank?
      raise ActionController::BadRequest.new("ref is required")
    end

    render json: {}
  end

  def submit
    render json: {}
  end

  private

  class SearchRequest
    def self.params
      params.permit(:q, :query)
    end
  end

  class SearchResponse
    def initialize
      @results = Array.new
    end

    def add_result(result)
      @brackets.push(result)
    end

    def add_results(results)
      @results.concat(results)
    end

    class Result
      def initialize(name, ref)
        @name = name
        @ref = ref
      end
    end
  end
end
