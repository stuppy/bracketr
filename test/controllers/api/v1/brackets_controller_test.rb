require "test_helper"

class Api::V1::BracketsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @bracket = brackets(:one)
  end

  test "should get index" do
    get api_v1_brackets_index_url
    assert_response :success
    brackets = json_response["brackets"]
    assert_equal true, brackets.is_a?(Array)
    # Tests reuse the same DB, so this could be 1, 2, 3, N.
    assert_equal false, brackets.empty?
  end

  test "should get show" do
    get api_v1_brackets_show_url(@bracket)
    assert_response :success
    assert_equal @bracket.name, json_response["name"]
  end

  private

  def json_response
    @json_response ||= ActiveSupport::JSON.decode @response.body
  end
end
