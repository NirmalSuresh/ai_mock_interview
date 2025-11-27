require "ruby_llm"
require "pdf-reader"

class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_session

  def create
    # End interview when time expired
    if @session.expired?
      @session.update!(status: "completed")
      return redirect_to final_report_assistant_session_path(@session)
    end

    @message = @session.messages.new(message_params)

    raw_input = @message.content.to_s.strip.downcase

    # Detect "end"
    if raw_input.start_with?("end")
      @session.update!(status: "completed")
      return redirect_to final_report_assistant_session_path(@session)
    end

    # If PDF uploaded
    if @message.file.attached?
      @message.save!

      ai_summary = handle_pdf(@message.file)

      @assistant_msg = @session.messages.create!(
        role: "assistant",
        content: ai_summary
      )

      return respond_with_turbo
    end

    # Normal text answer
    @message.save!

    # If last question
    if @session.current_question_number >= 25
      @session.update!(status: "completed")
      return redirect_to final_report_assistant_session_path(@session)
    end

    next_question = @session.current_question_number + 1

    history = @session.messages.order(:created_at).last(10)
      .map { |m| "#{m.role.capitalize}: #{m.content}" }
      .join("\n")

    chat = RubyLLM.chat(model: "gpt-4o-mini")

    ai_response = chat.ask(<<~PROMPT)
      #{SystemPrompt.text}

      Role: #{@session.role}

      Recent conversation:
      #{history}

      Ask interview question number #{next_question}.
    PROMPT

    @assistant_msg = @session.messages.create!(
      role: "assistant",
      content: ai_response.content
    )

    @session.update!(current_question_number: next_question)

    respond_with_turbo
  end

  private

  def handle_pdf(file)
    text = extract_pdf_text(file)

    chat = RubyLLM.chat(model: "gpt-4o-mini")

    response = chat.ask(<<~PROMPT)
      A PDF was uploaded. Extract meaning and summarize it clearly.

      PDF Content:
      #{text}

      Provide a structured summary.
    PROMPT

    response.content
  end

  def extract_pdf_text(file)
    reader = PDF::Reader.new(StringIO.new(file.download))
    reader.pages.map(&:text).join("\n")
  end

  def respond_with_turbo
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to assistant_session_path(@session) }
    end
  end

  def message_params
    params.require(:message).permit(:content, :file)
  end

  def set_session
    @session = current_user.assistant_sessions.find(params[:assistant_session_id])
  end
end
