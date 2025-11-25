class AssistantSessionsController < ApplicationController
  before_action :authenticate_user!

  def index
    @assistant_sessions = current_user.assistant_sessions.order(created_at: :desc)
  end
end
