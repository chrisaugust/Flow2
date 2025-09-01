class CategoriesController < ApplicationController
  include AuthHelper
  before_action :authorized_user
  before_action :set_category, only: [:show, :update, :destroy]

  def index
    categories = @current_user.categories.order(:name)
    render json: categories
  end

  def show
    render json: @category
  end

  def create
    category = @current_user.categories.build(category_params)
    if category.save
      render json: category, status: :created
    else
      render json: { errors: category.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @category.update(category_params)
      render json: @category
    else
      render json: { errors: @category.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    if @category.is_default
      render json: { error: "Default categories can't be deleted" }, status: :forbidden
    else
      @category.destroy
      head :no_content
    end
  end

  private

  def set_category
    @category = @current_user.categories.find_by(id: params[:id])
    unless @category
      render json: { error: 'Category not found' }, status: :not_found
    end
  end

  def category_params
    params.require(:category).permit(:name)
  end
end