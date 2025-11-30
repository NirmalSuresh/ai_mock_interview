class AssistantSessionsController < ApplicationController
  before_action :authenticate_user!

  def index
    @sessions = current_user.assistant_sessions.order(created_at: :desc)
  end

  def new
    @session = AssistantSession.new
  end

  def create
    # --- Validate Role ---
    if params[:role].blank?
      return redirect_to new_assistant_session_path, alert: "Please choose a role to start."
    end

    # --- Create session with proper initial state ---
    @session = current_user.assistant_sessions.create!(
      role: params[:role],
      current_question_number: 0,      # FIXED
      started_at: Time.current,
      ends_at: Time.current + 60.minutes,
      status: "in_progress"
    )

    chat = RubyLLM.chat(model: "gpt-4o-mini")

    prompt = <<~PROMPT
      #{SystemPrompt.text}
      Role: #{params[:role]}
      Ask Interview Question Number 1 now.
    PROMPT

    # --- Safe question generation ---
    first_question = chat.ask(prompt)&.content.presence ||
                     "Let's begin the interview. Tell me about yourself."

    @session.messages.create!(role: "assistant", content: first_question)

    # --- Mark Q1 as asked ---
    @session.update!(current_question_number: 1)

    redirect_to assistant_session_path(@session)
  end

  def show
    @session  = current_user.assistant_sessions.find(params[:id])
    @messages = @session.messages.order(:created_at)
    @time_left_seconds = @session.time_left.to_i
  end

  def final_report
    @session = current_user.assistant_sessions.find(params[:id])
    InterviewEvaluator.call(@session)
  end
end
