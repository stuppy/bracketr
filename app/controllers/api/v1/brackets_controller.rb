class Api::V1::BracketsController < ApplicationController
  def index
    brackets = Bracket.all.order(created_at: :desc)
    render json: brackets
  end

  def show
    if bracket
      render json: bracket
    else
      render json: bracket.errors
    end
  end

  private

  def bracket
    @bracket ||= Bracket.find(params[:id])
  end
end
