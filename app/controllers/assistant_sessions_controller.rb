class AssistantSessionsController < ApplicationController
  before_action :authenticate_user!

  def index
    @sessions = current_user.assistant_sessions.order(created_at: :desc)
  end

  def new
    @session = AssistantSession.new
  end

  def create
    @session = current_user.assistant_sessions.create!(
      role: params[:role],
      current_question_number: 1,
      started_at: Time.current,
      ends_at: Time.current + 60.minutes,
      status: "in_progress"
    )
    redirect_to assistant_session_path(@session)
  end

  def show
    @session = current_user.assistant_sessions.find(params[:id])
    @messages = @session.messages.order(:created_at)
    @time_left = @session.time_left
  end

  def report
    @session = current_user.assistant_sessions.find(params[:id])
    InterviewEvaluator.call(@session) if @session.completed?
  end
end
