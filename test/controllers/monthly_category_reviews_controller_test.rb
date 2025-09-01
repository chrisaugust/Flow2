require "test_helper"

class MonthlyCategoryReviewsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get monthly_category_reviews_index_url
    assert_response :success
  end

  test "should get show" do
    get monthly_category_reviews_show_url
    assert_response :success
  end

  test "should get create" do
    get monthly_category_reviews_create_url
    assert_response :success
  end

  test "should get update" do
    get monthly_category_reviews_update_url
    assert_response :success
  end

  test "should get destroy" do
    get monthly_category_reviews_destroy_url
    assert_response :success
  end
end
