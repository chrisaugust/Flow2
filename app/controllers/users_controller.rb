class UsersController < ApplicationController
  include AuthHelper
  before_action :set_user, only: [:show, :update]

  def create
    user = User.new(user_params)

    if user.save
      token = encode_token({ user_id: user.id })
      render json: { user: user_response(user), token: token }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /users/:id
  def show
    render json: @user
  end

  # PATCH /users/:id
  def update
    if @user.update(user_params)
      render json: @user
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :hourly_wage)
  end
end
