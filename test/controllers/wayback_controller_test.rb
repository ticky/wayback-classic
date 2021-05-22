require "test_helper"

class WaybackControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get wayback_index_url
    assert_response :success
  end
end
