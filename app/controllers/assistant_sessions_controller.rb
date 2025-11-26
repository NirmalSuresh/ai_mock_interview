class AssistantSessionsController < ApplicationController
  before_action :authenticate_user!

  def index
    @sessions = current_user.assistant_sessions.order(created_at: :desc)
  end

  def new
    @session = AssistantSession.new
  end

  def create
    session = current_user.assistant_sessions.create!
    redirect_to assistant_session_path(session)
  end

  def show
    @session = current_user.assistant_sessions.find(params[:id])
    @messages = @session.messages.order(:created_at)
  end
end
