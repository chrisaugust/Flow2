class MonthlyReviewsController < ApplicationController
  include AuthHelper
  before_action :authorized_user
  before_action :set_review, only: [:toggle_complete]

  rescue_from StandardError do |e|
    render json: { error: e.message }, status: :unprocessable_entity
  end

  rescue_from ActiveRecord::RecordNotFound do |e|
    render json: { error: e.message }, status: :not_found
  end

  def index
    reviews = @current_user.monthly_reviews.includes(:monthly_category_reviews)
    render json: reviews, include: :monthly_category_reviews
  end

  def show
    review = @current_user.monthly_reviews.find(params[:id])
    render json: review, include: [:monthly_category_reviews, :user]
  end

  def create
    date = params[:month].present? ? Date.parse(params[:month]) : Date.today
    month_code = date.beginning_of_month.strftime('%m%Y')
    review = @current_user.monthly_reviews.find_or_initialize_by(month_code: month_code)
    if review.persisted?
      render json: review, include: :monthly_category_reviews, status: :ok
    else
      review = MonthlyReviewBuilder.new(@current_user, date).build_review
      unless review.persisted?
        Rails.logger.debug ">>> Review validation errors: #{review.errors.full_messages}"
        render json: { errors: review.errors.full_messages }, status: :unprocessable_entity
        return
      end
      render json: review, include: :monthly_category_reviews, status: :created
    end
  end

  def rebuild
    review = @current_user.monthly_reviews.find(params[:id])
    date   = review.month_start

    # blow away old category reviews & rebuild fresh
    review.monthly_category_reviews.destroy_all
    new_review = MonthlyReviewBuilder.new(@current_user, date).build_review

    render json: new_review, include: :monthly_category_reviews
  end

  def toggle_complete
    # only mark complete if not already
    unless @review.completed
      @review.update(completed: true)
    end
  end

  def by_month_code
    date = Date.strptime(params[:month_code], "%m%Y")
    month_code = date.beginning_of_month.strftime("%m%Y")

    # find or build review
    review = @current_user.monthly_reviews.find_by(month_code: month_code)

    unless review
      review = MonthlyReviewBuilder.new(@current_user, date).build_review
      unless review.persisted?
        Rails.logger.debug ">>> ByMonthCode build errors: #{review.errors.full_messages}"
        render json: { errors: review.errors.full_messages }, status: :unprocessable_entity
        return
      end
    end

    render json: review, include: [:monthly_category_reviews, :user]
  end

  def update
    @review = MonthlyReview.find(params[:id])
    if @review.update(review_params)
      render json: @review
    else
      render json: @review.errors, status: :unprocessable_entity
    end
  end

private

  def review_params
    params.require(:monthly_review).permit(:notes, :completed)
  end

  def set_review
    @review = MonthlyReview.find(params[:id])
  end

end