class MonthlyCategoryReviewsController < ApplicationController
  include AuthHelper
  before_action :authorized_user

  def update
    review_item = @current_user.monthly_category_reviews.find(params[:id])

    if review_item.update(reflection_params)
      render json: review_item
    else
      render json: { errors: review_item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def reflection_params
    params.require(:monthly_category_review).permit(
      :received_fulfillment,
      :aligned_with_values,
      :would_change_post_fi,
    )
  end
end