class ApplicationController < ActionController::API
  include AuthHelper

  before_action :authorized_user
end
