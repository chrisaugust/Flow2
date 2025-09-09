class SessionsController < ApplicationController
  include AuthHelper
  skip_before_action :authorized_user, only: [:create]

  def create
    user = User.find_by(email: params[:email])

    if user
      # Check authentication method and authenticate accordingly
      authenticated_user = nil
      
      if user.migrated_to_devise?
        # Use Devise authentication
        authenticated_user = user if user.valid_password?(params[:password])
      else
        # Use legacy BCrypt authentication directly
        begin
          # Access password_digest directly using read_attribute to bypass protection
          password_digest = user.read_attribute(:password_digest)
          if password_digest && BCrypt::Password.new(password_digest).is_password?(params[:password])
            # Auto-migrate to Devise on successful login
            user.migrate_to_devise!(params[:password])
            authenticated_user = user
          end
        rescue BCrypt::Errors::InvalidHash => e
          Rails.logger.error "BCrypt error for user #{user.email}: #{e.message}"
          authenticated_user = nil
        end
      end

      if authenticated_user
        token = encode_token({ user_id: user.id })
        
        # Log migration if it just happened
        if user.previous_changes.key?('migrated_to_devise')
          Rails.logger.info "User #{user.email} auto-migrated to Devise on login"
        end
        
        render json: { user: user_response(user), token: token }, status: :ok
      else
        render json: { errors: ['Invalid email or password'] }, status: :unauthorized
      end
    else
      render json: { errors: ['Invalid email or password'] }, status: :unauthorized
    end
  end
end