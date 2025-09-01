module AuthHelper
  extend ActiveSupport::Concern

  private

  # Encode a JWT token with payload
  def encode_token(payload)
    JWT.encode(payload, Rails.application.secrets.secret_key_base)
  end

  def decode_token(token)
    begin
      decoded = JWT.decode(token, Rails.application.secrets.secret_key_base)
      decoded.first # payload is first element
    rescue JWT::DecodeError
      nil
    end
  end

  # To CRUD categories, expenses, or reviews, user must be registered and logged in
  def authorized_user
    header = request.headers['Authorization']
    token = header.split(' ').last if header

    if token
      decoded = decode_token(token)
      if decoded && decoded["user_id"]
        @current_user = User.find_by(id: decoded["user_id"])
      end
    end
    
    unless @current_user
      render json: { errors: ['Not authorized'] }, status: :unauthorized
      return
    end
  end

  # Format user response data to return in JSON
  def user_response(user)
    {
      id: user.id,
      email: user.email
    }
  end
end
