class Bracket < ApplicationRecord
  validates :name, presence: true

  def data
    @data ||= BData.new(super)
  end

  def data=(value)
    raise "data is not BData; got %s" % value.class unless value.is_a?(BData)
    @data = value
    super(value.to_h)
  end

  class BData < OpenStruct
    TYPE_SPOTIFY_TRACKS = "SPOTIFY_TRACKS"
  end
end
