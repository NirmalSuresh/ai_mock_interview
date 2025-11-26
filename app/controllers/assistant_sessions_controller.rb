class AssistantSessionsController < ApplicationController
  before_action :authenticate_user!

  # -------------------------
  # LIST ALL SESSIONS
  # -------------------------
  def index
    @sessions = current_user.assistant_sessions.order(created_at: :desc)
  end

  # -------------------------
  # NEW INTERVIEW PAGE
  # -------------------------
  def new
    @session = AssistantSession.new
  end

  # -------------------------
  # CREATE INTERVIEW SESSION
  # -------------------------
  def create
    @session = current_user.assistant_sessions.create!(
      role: params[:role],
      current_question_number: 1,
      started_at: Time.current,
      ends_at: Time.current + 60.minutes,
      status: "in_progress"
    )

    # Ask Question 1
    chat = RubyLLM.chat(model: "gpt-4o-mini")

    ai_response = chat.ask(
      "#{SystemPrompt.text}\n\n" \
      "Role: #{params[:role]}\n" \
      "Please ask interview question number 1 for this role."
    )

    @session.messages.create!(
      role: "assistant",
      content: ai_response.content
    )

    redirect_to assistant_session_path(@session)
  end

  # -------------------------
  # SHOW LIVE INTERVIEW
  # -------------------------
  def show
    @session   = current_user.assistant_sessions.find(params[:id])
    @messages  = @session.messages.order(:created_at)
    @time_left = @session.time_left
  end

  # -------------------------
  # FINAL REPORT PAGE
  # -------------------------
  def final_report
    @session = current_user.assistant_sessions.find(params[:id])
    @messages = @session.messages.order(:created_at)

    # Generate score & feedback
    InterviewEvaluator.call(@session)

    # Always render the report page
    render :final_report
  end
end
