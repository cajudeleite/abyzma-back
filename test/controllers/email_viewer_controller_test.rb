require "test_helper"

class EmailViewerControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get email_viewer_index_url
    assert_response :success
  end
end
