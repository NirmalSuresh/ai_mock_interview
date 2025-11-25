class InterviewsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_session, only: [:show, :answer, :timeout, :summary]

  def new
    @assistant_session = AssistantSession.new
  end

  def create
    @assistant_session = AssistantSession.new(
      user: current_user,
      role: params[:assistant_session][:role],
      current_question_number: 1,
      start_time: Time.now,
      time_limit: 3600,
      status: "active"
    )

    if @assistant_session.save
      generate_questions(@assistant_session)
      redirect_to interview_path(@assistant_session)
    else
      render :new
    end
  end

  def show
    if @session.status != "active"
      return redirect_to summary_interview_path(@session)
    end

    @remaining_time = @session.time_limit - (Time.now - @session.start_time).to_i
    if @remaining_time <= 0
      handle_timeout
      return redirect_to summary_interview_path(@session)
    end

    @question = @session.questions.find_by(number: @session.current_question_number)
  end

  def answer
    Message.create!(
      assistant_session: @session,
      role: "user",
      content: params[:answer]
    )

    remaining = @session.time_limit - (Time.now - @session.start_time).to_i

    if remaining <= 0
      handle_timeout
      return redirect_to summary_interview_path(@session)
    end

    if @session.current_question_number < 25
      @session.update(current_question_number: @session.current_question_number + 1)
      redirect_to interview_path(@session)
    else
      complete_interview
      redirect_to summary_interview_path(@session)
    end
  end

  def timeout
    handle_timeout
    redirect_to summary_interview_path(@session)
  end

  def summary
    @session.update(time_taken: (@session.end_time - @session.start_time).to_i) if @session.end_time.present?
  end

  private

  def set_session
    @session = AssistantSession.find(params[:id])
  end

  def generate_questions(session)
    prompt = "Generate 25 interview questions for the role #{session.role}. Give only the questions."

    response = OpenAI::Client.new.chat(
      parameters: {
        model: "gpt-3.5-turbo",
        messages: [{ role: "user", content: prompt }]
      }
    )

    questions = response["choices"].first["message"]["content"].split("\n").reject(&:blank?)

    questions.first(25).each_with_index do |q, i|
      Question.create!(
        assistant_session: session,
        number: i + 1,
        content: q
      )
    end
  end

  def complete_interview
    @session.update(
      end_time: Time.now,
      status: "completed"
    )
    generate_final_report
  end

  def handle_timeout
    @session.update(
      end_time: Time.now,
      status: "timed_out"
    )
    generate_final_report
  end

  def generate_final_report
    answers = @session.messages.where(role: "user").pluck(:content).join("\n\n")

    prompt = <<~PROMPT
      Analyze this interview for role #{@session.role}:

      #{answers}

      Give:
      - Score (0–100)
      - Strengths
      - Weaknesses
      - Summary
    PROMPT

    response = OpenAI::Client.new.chat(
      parameters: {
        model: "gpt-3.5-turbo",
        messages: [{ role: "user", content: prompt }]
      }
    )

    report = response["choices"].first["message"]["content"]

    @session.update(
      summary: report,
      strengths: report[/Strengths:(.*?)(Weaknesses:|$)/m, 1]&.strip,
      weaknesses: report[/Weaknesses:(.*?)(Summary:|$)/m, 1]&.strip,
      total_score: report[/Score:\s*(\d+)/, 1]&.to_i,
      time_taken: (@session.end_time - @session.start_time).to_i
    )
  end
end
