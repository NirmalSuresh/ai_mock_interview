class InterviewsController < ApplicationController
  before_action :authenticate_user!

  def new
  end

  def create
    role = params[:role]

    assistant_session = AssistantSession.create!(
      user: current_user,
      role: role,
      current_question_number: 1,
      start_time: Time.now,
      time_limit: 60.minutes
    )

    # Generate 25 questions
    25.times do |i|
      Question.create!(
        assistant_session: assistant_session,
        number: i + 1,
        content: "Question #{i + 1} for #{role} (AI generated later)"
      )
    end

    redirect_to interview_path(assistant_session)
  end

  def show
    @session = AssistantSession.find(params[:id])
    @question = @session.questions.find_by(number: @session.current_question_number)
  end

  def answer
    session_id = params[:interview_id]
    @session = AssistantSession.find(session_id)

    user_answer = params[:answer]

    Message.create!(
      assistant_session: @session,
      role: "user",
      content: user_answer
    )

    ai_feedback = "AI feedback for your answer to Q#{@session.current_question_number}"

    Message.create!(
      assistant_session: @session,
      role: "assistant",
      content: ai_feedback
    )

    @session.update(current_question_number: @session.current_question_number + 1)

    if @session.current_question_number > 25
      @session.update(end_time: Time.now)
      redirect_to summary_interview_path(@session)
    else
      redirect_to interview_path(@session)
    end
  end

  def summary
    @session = AssistantSession.find(params[:interview_id])
  end
end
