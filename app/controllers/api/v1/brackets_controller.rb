class Api::V1::BracketsController < ApplicationController
  def index
    brackets = Bracket.all.order(created_at: :desc)
    response = IndexResponse.new
    response.add_brackets(
      brackets.to_a.map { |bracket| IndexResponse::Bracket.new(bracket.name, bracket.description) })
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
    def initialize
      @brackets = []
    end

    def add_bracket(bracket)
      @brackets.push(bracket)
    end

    def add_brackets(brackets)
      @brackets.concat(brackets)
    end

    class Bracket
      def initialize(name, description)
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
