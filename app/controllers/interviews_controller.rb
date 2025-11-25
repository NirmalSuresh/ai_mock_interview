class InterviewsController < ApplicationController
  before_action :authenticate_user!

  def new
    @interview = AssistantSession.new
  end

  def create
    @interview = current_user.assistant_sessions.create!(
      role: params[:role],
      current_question_number: 1
    )

    redirect_to interview_path(@interview)
  end

  def show
    @interview = AssistantSession.find(params[:id])
    @question = @interview.questions[@interview.current_question_number - 1]
  end

  def answer
    @interview = AssistantSession.find(params[:id])
    @question = @interview.questions[@interview.current_question_number - 1]

    @interview.interview_answers.create!(
      content: params[:answer],
      question_number: @interview.current_question_number
    )

    if @interview.current_question_number < 25
      @interview.update(current_question_number: @interview.current_question_number + 1)
      redirect_to interview_path(@interview)
    else
      redirect_to summary_interview_path(@interview)
    end
  end

  def timeout
    @interview = AssistantSession.find(params[:id])
    redirect_to summary_interview_path(@interview)
  end

  def summary
    @interview = AssistantSession.find(params[:id])
    @answers = @interview.interview_answers
  end
end
