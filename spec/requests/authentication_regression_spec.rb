require 'rails_helper'

RSpec.describe "Authentication System Migration", type: :request do
  let(:valid_password) { 'SecurePassword123!' }
  let(:new_password) { 'NewSecurePassword456!' }
  let(:headers) { { 'Content-Type': 'application/json' } }

  # Shared contexts
  shared_context 'legacy user' do
    let!(:legacy_user) do
      create_legacy_user('legacy@example.com', valid_password)
    end
  end

  shared_context 'devise user' do
    let!(:devise_user) do
      create_devise_user('devise@example.com', valid_password)
    end
  end

  shared_context 'authenticated user' do
    include_context 'devise user'
    let(:token) { login_user(devise_user.email, valid_password) }
    let(:auth_headers) { headers.merge('Authorization' => "Bearer #{token}") }
  end

  # Shared examples
  shared_examples 'successful authentication' do |email_key|
    it 'returns user data and token' do
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['user']['email']).to eq(send(email_key).email)
      expect(json['token']).to be_present
    end
  end

  shared_examples 'failed authentication' do
    it 'returns unauthorized with error message' do
      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json['errors']).to include('Invalid email or password')
    end
  end

  shared_examples 'requires authentication' do
    it 'rejects unauthenticated requests' do
      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json['errors']).to include('Not authorized')
    end
  end

  shared_examples 'password reset success' do
    it 'resets password and returns token' do
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['message']).to eq('Password successfully reset')
      expect(json['token']).to be_present
      
      subject.reload
      expect(subject.valid_password?(new_password)).to be true
      expect(subject.reset_password_token).to be_nil
    end
  end

  describe "Legacy User Authentication" do
    include_context 'legacy user'

    context "login with correct password" do
      before { login_user(legacy_user.email, valid_password) }
      
      include_examples 'successful authentication', :legacy_user

      it 'auto-migrates user to Devise' do
        legacy_user.reload
        expect(legacy_user.migrated_to_devise).to be true
        expect(legacy_user.encrypted_password).to be_present
      end
    end

    context "login with incorrect password" do
      before { login_user(legacy_user.email, 'wrong_password') }
      
      include_examples 'failed authentication'

      it 'does not migrate user' do
        legacy_user.reload
        expect(legacy_user.migrated_to_devise).to be false
        expect(legacy_user.encrypted_password).to be_blank
      end
    end

    context "after auto-migration" do
      before do
        login_user(legacy_user.email, valid_password)
        legacy_user.reload
      end

      it 'can login with Devise authentication' do
        post '/login', 
             params: { email: legacy_user.email, password: valid_password }.to_json, 
             headers: headers
        
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['user']['email']).to eq(legacy_user.email)
        expect(json['user']['migrated_to_devise']).to be true
        expect(json['token']).to be_present
      end

      it 'preserves legacy password_digest but uses Devise' do
        expect(legacy_user.read_attribute(:password_digest)).to be_present
        expect(legacy_user.encrypted_password).to be_present
        expect(legacy_user.valid_password?(valid_password)).to be true
        expect(legacy_user.migrated_to_devise).to be true
      end
    end

    context "legacy authentication methods" do
      it 'validates legacy password before migration' do
        expect(legacy_user.valid_legacy_password?(valid_password)).to be true
        expect(legacy_user.valid_legacy_password?('wrong')).to be false
      end

      it 'legacy validation returns false after migration' do
        legacy_user.migrate_to_devise!(valid_password)
        expect(legacy_user.valid_legacy_password?(valid_password)).to be false
        expect(legacy_user.migrated_to_devise).to be true
      end
    end
  end

  describe "New User Registration" do
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

      it 'creates user with Devise from start' do
        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['user']['email']).to eq('newuser@example.com')
        expect(json['user']['migrated_to_devise']).to be true
        expect(json['token']).to be_present

        user = User.find_by(email: 'newuser@example.com')
        expect(user.migrated_to_devise).to be true
        expect(user.encrypted_password).to be_present
        expect(user.read_attribute(:password_digest)).to be_blank
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
    include_context 'authenticated user'

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
      include_examples 'requires authentication'
    end

    context "with expired token" do
      let(:expired_token) do
        JWT.encode(
          { user_id: devise_user.id, exp: 1.hour.ago.to_i },
          Rails.application.secrets.secret_key_base
        )
      end

      before do
        get "/users/#{devise_user.id}", 
            headers: headers.merge('Authorization' => "Bearer #{expired_token}")
      end

      include_examples 'requires authentication'
    end

    context "with invalid token" do
      before do
        get "/users/#{devise_user.id}", 
            headers: headers.merge('Authorization' => "Bearer invalid_token")
      end

      include_examples 'requires authentication'
    end
  end

  describe "User Profile Updates" do
    include_context 'authenticated user'

    context "updating own profile" do
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
              params: { 
                user: { 
                  password: new_password, 
                  password_confirmation: new_password 
                } 
              }.to_json, 
              headers: auth_headers

        expect(response).to have_http_status(:ok)
        devise_user.reload
        expect(devise_user.valid_password?(new_password)).to be true
      end

      it 'validates password confirmation' do
        patch "/users/#{devise_user.id}", 
              params: { 
                user: { 
                  password: new_password, 
                  password_confirmation: 'different' 
                } 
              }.to_json, 
              headers: auth_headers

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to include("Password confirmation doesn't match Password")
      end
    end

    context "accessing other user's profile" do
      let!(:other_user) { create_devise_user('other@example.com', valid_password) }

      it 'prevents viewing other profiles' do
        get "/users/#{other_user.id}", headers: auth_headers

        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json['errors']).to include('Not authorized to access this user')
      end

      it 'prevents updating other profiles' do
        patch "/users/#{other_user.id}", 
              params: { user: { email: 'hacked@example.com' } }.to_json, 
              headers: auth_headers

        expect(response).to have_http_status(:forbidden)
        other_user.reload
        expect(other_user.email).to eq('other@example.com')
      end
    end
  end

  describe "Password Reset Flow" do
    include_context 'devise user'

    describe "forgot password" do
      it 'sends reset instructions for existing user' do
        post '/forgot_password', 
             params: { email: devise_user.email }.to_json, 
             headers: headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['message']).to eq('Password reset instructions sent to your email')
        
        devise_user.reload
        expect(devise_user.reset_password_token).to be_present
        expect(devise_user.reset_password_sent_at).to be_present
      end

      it 'auto-migrates legacy user before reset' do
        legacy_user = create_legacy_user('legacy_reset@example.com', valid_password)

        post '/forgot_password', 
             params: { email: legacy_user.email }.to_json, 
             headers: headers

        expect(response).to have_http_status(:ok)
        
        legacy_user.reload
        expect(legacy_user.migrated_to_devise).to be true
        expect(legacy_user.reset_password_token).to be_present
      end

      it 'does not reveal non-existent emails' do
        post '/forgot_password', 
             params: { email: 'nonexistent@example.com' }.to_json, 
             headers: headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['message']).to eq('Password reset instructions sent to your email')
      end
    end

    describe "reset password" do
      subject { devise_user }
      let(:reset_token) { generate_reset_token(devise_user) }

      context "with valid token" do
        before do
          post '/reset_password', 
               params: { 
                 token: reset_token, 
                 password: new_password, 
                 password_confirmation: new_password 
               }.to_json, 
               headers: headers
        end

        include_examples 'password reset success'
      end

      context "with expired token" do
        it 'rejects expired token' do
          # Generate token first
          raw_token, hashed_token = Devise.token_generator.generate(User, :reset_password_token)
          
          # Set token and expired timestamp
          devise_user.update_columns(
            reset_password_token: hashed_token,
            reset_password_sent_at: 3.hours.ago
          )
          
          post '/reset_password', 
               params: { 
                 token: raw_token, 
                 password: new_password, 
                 password_confirmation: new_password 
               }.to_json, 
               headers: headers

          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)
          expect(json['errors']).to include('Invalid or expired reset token')
        end
      end

      context "with invalid token" do
        before do
          post '/reset_password', 
               params: { 
                 token: 'invalid_token', 
                 password: new_password, 
                 password_confirmation: new_password 
               }.to_json, 
               headers: headers
        end

        it 'rejects invalid token' do
          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)
          expect(json['errors']).to include('Invalid or expired reset token')
        end
      end
    end
  end

  describe "Backward Compatibility" do
    it 'maintains API response structure for signup' do
      post '/signup', 
           params: { 
             user: { 
               email: 'api_test@example.com', 
               password: valid_password, 
               password_confirmation: valid_password 
             } 
           }.to_json, 
           headers: headers

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      
      expect(json).to have_key('user')
      expect(json).to have_key('token')
      expect(json['user']).to have_key('id')
      expect(json['user']).to have_key('email')
    end

    it 'maintains error response structure' do
      post '/login', 
           params: { email: 'wrong@example.com', password: 'wrong' }.to_json, 
           headers: headers

      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      
      expect(json).to have_key('errors')
      expect(json['errors']).to be_an(Array)
    end
  end

  # Additional test for token lookup
  describe "Token Lookup Verification" do
    include_context 'devise user'

    it 'correctly handles reset token lookup' do
      raw_token, hashed_token = Devise.token_generator.generate(User, :reset_password_token)
      devise_user.reset_password_token = hashed_token
      devise_user.reset_password_sent_at = Time.current
      devise_user.save!(validate: false)

      # Verify the controller should be looking up by hashed token
      found_user = User.find_by(reset_password_token: hashed_token)
      expect(found_user).to eq(devise_user)
      
      # Raw token shouldn't fin the user
      found_by_raw = User.find_by(reset_password_token: raw_token)
      expect(found_by_raw).to be_nil
    end
  end

  private

  # Helper methods
  def create_legacy_user(email, password)
    user = User.new(email: email, migrated_to_devise: false)
    user.password_digest = BCrypt::Password.create(password)
    user.save(validate: false)
    user
  end

  def create_devise_user(email, password)
    User.create!(
      email: email,
      password: password,
      password_confirmation: password,
      migrated_to_devise: true
    )
  end

  def login_user(email, password)
    post '/login', 
         params: { email: email, password: password }.to_json, 
         headers: headers
    
    return nil unless response.successful?
    JSON.parse(response.body)['token']
  end

  def generate_reset_token(user)
    raw_token, hashed_token = Devise.token_generator.generate(User, :reset_password_token)
    user.reset_password_token = hashed_token
    user.reset_password_sent_at = Time.current
    user.save!(validate: false)
    raw_token
  end
end