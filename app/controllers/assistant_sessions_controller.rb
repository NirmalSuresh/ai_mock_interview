class AssistantSessionsController < ApplicationController
  before_action :authenticate_user!

  def index
    @sessions = current_user.assistant_sessions.order(created_at: :desc)
  end

  def new
    @session = AssistantSession.new
  end

  def create
  role = params.dig(:assistant_session, :role)

  if role.blank?
    return redirect_to new_assistant_session_path, alert: "Please choose a role."
  end

  @session = current_user.assistant_sessions.create!(
    role: role,
    current_question_number: 0,
    started_at: Time.current,
    ends_at: Time.current + 60.minutes,
    status: "in_progress"
  )

  chat = RubyLLM.chat(model: "gpt-4o-mini")

  prompt = <<~PROMPT
    #{SystemPrompt.text}
    Role: #{role}
    Ask Interview Question Number 1 now.
  PROMPT

  first_question = chat.ask(prompt)&.content.presence ||
                   "Let's begin. Tell me about yourself."

  @session.messages.create!(role: "assistant", content: first_question)
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
