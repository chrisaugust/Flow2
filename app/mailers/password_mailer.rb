class PasswordMailer < ApplicationMailer
  default from: 'noreply@yourapp.com'

  def reset_instructions(user, token)
    @user = user
    @reset_url = "http://localhost:5173/reset-password?token=#{token}" # Adjust port for your frontend
    
    mail(
      to: @user.email,
      subject: 'Password Reset Instructions'
    )
  end
end