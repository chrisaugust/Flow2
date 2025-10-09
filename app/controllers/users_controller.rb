class UsersController < ApplicationController
  include AuthHelper
  before_action :set_user, only: [:show, :update]
  skip_before_action :authorized_user, only: [:create] # Allow registration without auth

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
    render json: user_response(@user)
  end

  # PATCH /users/:id
  def update
    if @user.update(user_params)
      render json: user_response(@user)
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
    
    # Security check: users can only view/update their own profile
    unless @user.id == @current_user.id
      render json: { errors: ['Not authorized to access this user'] }, status: :forbidden
    end
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :hourly_wage)
  end
end