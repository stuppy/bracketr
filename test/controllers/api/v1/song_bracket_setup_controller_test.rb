require 'test_helper'

class Api::V1::SongBracketSetupControllerTest < ActionDispatch::IntegrationTest
  test "should get search" do
    get api_v1_song_bracket_setup_search_url
    assert_response :success
  end

  test "should get select" do
    get api_v1_song_bracket_setup_select_url
    assert_response :success
  end

  test "should post submit" do
    post api_v1_song_bracket_setup_submit_url
    assert_response :success
  end

end
