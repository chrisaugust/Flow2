class PasswordMailer < ApplicationMailer
  default from: 'noreply@yourapp.com'

  def reset_instructions(user, token)
    @user = user
    frontend_host = ENV.fetch('FRONTEND_URL')
    @reset_url = "#{frontend_host}/reset-password?token=#{token}" # Adjust port for your frontend
    
    mail(
      to: @user.email,
      subject: 'Password Reset Instructions'
    )
  end
end