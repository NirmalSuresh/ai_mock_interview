class ApplicationController < ActionController::Base
  def after_sign_in_path_for(resource)
    assistant_sessions_path
  end
end
