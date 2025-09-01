require "test_helper"

class ReportsControllerTest < ActionDispatch::IntegrationTest
  test "should get monthly_summary" do
    get reports_monthly_summary_url
    assert_response :success
  end
end
