class PasswordsController < ApplicationController
  include AuthHelper
  skip_before_action :authorized_user, only: [:forgot, :reset]

  # POST /forgot_password
  def forgot
    user = User.find_by(email: params[:email])
    
    if user
      # Ensure user is migrated before sending reset
      unless user.migrated_to_devise?
        temp_password = SecureRandom.hex(16)
        user.migrate_to_devise!(temp_password)
      end
      
      # Generate reset token
      raw_token, hashed_token = Devise.token_generator.generate(User, :reset_password_token)
      user.reset_password_token = hashed_token
      user.reset_password_sent_at = Time.current
      user.save(validate: false)
      
      # Send reset email with raw_token
      # PasswordMailer.reset_instructions(user, raw_token).deliver_later
      
      render json: { 
        message: 'Password reset instructions sent to your email' 
      }, status: :ok
    else
      # Don't reveal that user doesn't exist
      render json: { 
        message: 'Password reset instructions sent to your email' 
      }, status: :ok
    end
  end

  # POST /reset_password
  def reset
    hashed_token = Devise.token_generator.digest(User, :reset_password_token, params[:token])
    user = User.find_by(reset_password_token: hashed_token)
    
    if user && user.reset_password_sent_at > 2.hours.ago
      user.password = params[:password]
      user.password_confirmation = params[:password_confirmation]
      user.reset_password_token = nil
      user.reset_password_sent_at = nil
      
      if user.save
        token = encode_token({ user_id: user.id })
        render json: { 
          user: user_response(user), 
          token: token,
          message: 'Password successfully reset' 
        }, status: :ok
      else
        render json: { 
          errors: user.errors.full_messages 
        }, status: :unprocessable_entity
      end
    else
      render json: { 
        errors: ['Invalid or expired reset token'] 
      }, status: :unprocessable_entity
    end
  end
end