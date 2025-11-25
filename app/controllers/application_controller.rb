class ApplicationController < ActionController::Base
  # Prevent CSRF issues
  protect_from_forgery with: :exception

  # Where to go after login
  def after_sign_in_path_for(resource)
    new_interview_path
  end
end
