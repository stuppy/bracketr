require "test_helper"

# Controller tests are deprecated? IDK figure that out.
class HomepageControllerTest < ActionDispatch::IntegrationTest
  test "should get index from root url" do
    get root_url
    assert_response :success
  end

  test "should get index from any url" do
    get "/anywhere"
    assert_response :success
  end
end
