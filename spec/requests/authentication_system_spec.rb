require 'rails_helper'

RSpec.describe "Authentication System", type: :request do
  let(:valid_password) { 'SecurePassword123!' }
  let(:new_password) { 'NewSecurePassword456!' }
  let(:headers) { { 'Content-Type': 'application/json' } }

  let!(:devise_user) do
    User.create!(
      email: 'devise@example.com',
      password: valid_password,
      password_confirmation: valid_password
    )
  end

  # Helper for logging in and returning JWT token
  def login_user(email, password)
    post '/login',
         params: { email: email, password: password }.to_json,
         headers: headers

    return nil unless response.successful?
    JSON.parse(response.body)['token']
  end

  describe "User Registration" do
    let(:user_params) do
      {
        user: {
          email: 'newuser@example.com',
          password: valid_password,
          password_confirmation: valid_password
        }
      }
    end

    context "with valid parameters" do
      before { post '/signup', params: user_params.to_json, headers: headers }

      it 'creates user with Devise' do
        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['user']['email']).to eq('newuser@example.com')
        expect(json['token']).to be_present

        user = User.find_by(email: 'newuser@example.com')
        expect(user.encrypted_password).to be_present
      end

      it 'creates default categories' do
        user = User.find_by(email: 'newuser@example.com')
        expect(user.categories.count).to eq(11)
        expect(user.categories.pluck(:name)).to include('Housing', 'Food', 'Transportation')
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        { user: { email: 'test@example.com', password: 'short', password_confirmation: 'short' } }
      end

      before { post '/signup', params: invalid_params.to_json, headers: headers }

      it 'returns validation errors' do
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to include('Password is too short (minimum is 6 characters)')
      end
    end
  end

  describe "JWT Token Authentication" do
    let(:token) { login_user(devise_user.email, valid_password) }
    let(:auth_headers) { headers.merge('Authorization' => "Bearer #{token}") }

    context "with valid token" do
      before { get "/users/#{devise_user.id}", headers: auth_headers }

      it 'allows access to protected endpoints' do
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['email']).to eq(devise_user.email)
      end
    end

    context "without token" do
      before { get "/users/#{devise_user.id}", headers: headers }

      it 'rejects unauthenticated requests' do
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['errors']).to include('Not authorized')
      end
    end
  end

  describe "User Profile Updates" do
    let(:token) { login_user(devise_user.email, valid_password) }
    let(:auth_headers) { headers.merge('Authorization' => "Bearer #{token}") }

    it 'allows email updates' do
      patch "/users/#{devise_user.id}",
            params: { user: { email: 'newemail@example.com' } }.to_json,
            headers: auth_headers

      expect(response).to have_http_status(:ok)
      devise_user.reload
      expect(devise_user.email).to eq('newemail@example.com')
    end

    it 'allows password updates' do
      patch "/users/#{devise_user.id}",
            params: { user: { password: new_password, password_confirmation: new_password } }.to_json,
            headers: auth_headers

      expect(response).to have_http_status(:ok)
      devise_user.reload
      expect(devise_user.valid_password?(new_password)).to be true
    end
  end

  describe "Password Reset Flow" do
    let(:new_password) { 'NewSecurePassword456!' }

    before do
      # Ensure FRONTEND_URL is set for test environment
      ENV['FRONTEND_URL'] ||= 'http://localhost:3000'
    end

    describe "forgot password" do
      it 'sends reset instructions for existing user' do
        post '/forgot_password', params: { email: devise_user.email }.to_json, headers: headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['message']).to eq('Password reset instructions sent to your email')

        devise_user.reload
        expect(devise_user.reset_password_token).to be_present
        expect(devise_user.reset_password_sent_at).to be_present
      end
    end

    describe "reset password" do
      let(:raw_token) do
        raw, hashed = Devise.token_generator.generate(User, :reset_password_token)
        devise_user.update_columns(
          reset_password_token: hashed,
          reset_password_sent_at: Time.current
        )
        raw
      end

      context "with valid token" do
        before do
          post '/reset_password',
              params: { token: raw_token, password: new_password, password_confirmation: new_password }.to_json,
              headers: headers
        end

        it 'resets password and returns success' do
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json['message']).to eq('Password successfully reset')
          expect(json['token']).to be_present

          devise_user.reload
          expect(devise_user.valid_password?(new_password)).to be true
          expect(devise_user.reset_password_token).to be_nil
        end
      end

      context "with expired token" do
        it 'rejects expired token' do
          raw, hashed = Devise.token_generator.generate(User, :reset_password_token)
          devise_user.update_columns(
            reset_password_token: hashed,
            reset_password_sent_at: 3.hours.ago
          )

          post '/reset_password',
              params: { token: raw, password: new_password, password_confirmation: new_password }.to_json,
              headers: headers

          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)
          expect(json['errors']).to include('Invalid or expired reset token')
        end
      end

      context "with invalid token" do
        it 'rejects invalid token' do
          post '/reset_password',
              params: { token: 'invalid_token', password: new_password, password_confirmation: new_password }.to_json,
              headers: headers

          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)
          expect(json['errors']).to include('Invalid or expired reset token')
        end
      end
    end
  end
end
