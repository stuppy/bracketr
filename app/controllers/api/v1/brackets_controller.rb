class Api::V1::BracketsController < ApplicationController
  def index
    brackets = Bracket.all.order(created_at: :desc)
    response = IndexResponse.new
    response.brackets.concat(
      brackets.to_a.map { |bracket| IndexResponse::Bracket.new(bracket.id, bracket.name, bracket.description) }
    )
    render json: response
  end

  def show
    if bracket
      response = ShowResponse.new(bracket.name, bracket.description)
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
      def initialize(id, name, description)
        @id = id
        @name = name
        @description = description
      end
    end
  end

  class ShowResponse
    def initialize(name, description)
      @name = name
      @description = description
    end
  end

  def bracket
    @bracket ||= Bracket.find(params[:id])
  end
end
