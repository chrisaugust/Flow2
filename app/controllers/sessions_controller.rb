class SessionsController < ApplicationController
  include AuthHelper
  skip_before_action :authorized_user, only: [:create]

  def create
    user = User.find_by(email: params[:email])
    return render_unauthorized unless user&.valid_password?(params[:password])

    token = encode_token(user_id: user.id)
    render json: { user: user_response(user), token: token }, status: :ok
  end

  private

  def render_unauthorized
    render json: { errors: ['Invalid email or password'] }
  end
end