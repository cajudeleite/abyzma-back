class Api::V1::BaseController < ApplicationController
  # Completely disable CSRF protection for API controllers
  skip_before_action :verify_authenticity_token
  
  # Set content type to JSON for all API responses
  before_action :set_json_format
  
  private
  
  def set_json_format
    request.format = :json
  end
end
