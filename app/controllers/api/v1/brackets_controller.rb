class Api::V1::BracketsController < ApplicationController
  def index
    brackets = Bracket.all.order(created_at: :desc)
    response = IndexResponse.new
    response.brackets.concat(
      brackets.to_a.map { |bracket|
        b = IndexResponse::Bracket.new(bracket.id, bracket.name, bracket.description)
        image = ((bracket.data.dig "artist", "images") || []).first
        b.image = Image.new(image) if image
        b
      }
    )
    render json: response
  end

  def show
    if bracket
      response = ShowResponse.new(bracket.name, bracket.description)
      image = ((bracket.data.dig "artist", "images") || []).first
      response.image = Image.new(image) if image
      count = bracket.data.count
      response.num_teams = count
      response.num_rounds = Math.log2(count).to_int
      region_count = (count / 4).to_i
      response.nw = to_matchups(bracket.data.items[0 * region_count, region_count])
      response.ne = to_matchups(bracket.data.items[1 * region_count, region_count])
      response.sw = to_matchups(bracket.data.items[2 * region_count, region_count])
      response.se = to_matchups(bracket.data.items[3 * region_count, region_count])
      render json: response
    else
      render json: bracket.errors
    end
  end

  private

  class IndexRequest
  end

  class IndexResponse
    attr_reader :brackets, :description, :id, :name

    def initialize
      @brackets = []
    end

    class Bracket
      attr_accessor :image

      def initialize(id, name, description)
        @id = id
        @name = name
        @description = description
      end
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

  class ShowResponse
    attr_accessor :image, :ne, :nw, :se, :sw, :num_teams, :num_rounds

    def initialize(name, description)
      @name = name
      @description = description
    end

    class Team
      attr_accessor :image

      def initialize(name, seed)
        @name = name
        @seed = seed
      end
    end

    class Matchup
      def initialize(team1, team2)
        @team1 = team1
        @team2 = team2
      end
    end
  end

  def to_team(item, seed)
    team = ShowResponse::Team.new(item["name"], seed)
    image = (item.dig "album", "images").first
    team.image = Image.new(image) if image
    team
  end

  def to_matchups(teams)
    games = teams.length / 2
    matchups = Array.new
    for game in 1..games
      # Seeds 1, 2, 3
      a_seed = game
      a = teams[a_seed - 1]
      # opposite seed (16, 15, 14)
      b_seed = teams.length - game + 1
      b = teams[b_seed - 1]
      matchups.push(ShowResponse::Matchup.new(to_team(a, a_seed), to_team(b, b_seed)))
    end
    return matchups
  end

  def bracket
    @bracket ||= Bracket.find(params[:id])
  end
end
