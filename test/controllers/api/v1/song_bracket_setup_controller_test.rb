require 'test_helper'

class Api::V1::SongBracketSetupControllerTest < ActionDispatch::IntegrationTest
  test "should get search" do
    get api_v1_song_bracket_setup_search_url, params: { query: "__NO_SEARCH__" }
    assert_response :success
  end

  test "should post submit" do
    post api_v1_song_bracket_setup_submit_url, params: { ref: "__NO_REF__" }
    assert_response :success
  end

end
