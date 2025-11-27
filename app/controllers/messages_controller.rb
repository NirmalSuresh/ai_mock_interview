require "pdf/reader"

class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_session

  def create
    # END if time expired
    if @session.expired?
      @session.update!(status: "completed")
      return redirect_to final_report_assistant_session_path(@session)
    end

    @message = @session.messages.new(message_params)
    raw_input = @message.content.to_s.strip.downcase

    # 🔥 Detect "end" BEFORE saving
    if raw_input.start_with?("end")
      @session.update!(status: "completed")
      return redirect_to final_report_assistant_session_path(@session)
    end

    # 🔥 PDF Upload Flow (must attach BEFORE checking)
    if params[:message][:file].present?
      @message.file.attach(params[:message][:file])
      @message.save!

      ai_summary = handle_pdf(@message.file)

      @session.messages.create!(
        role: "assistant",
        content: ai_summary
      )

      return respond_with_turbo
    end

    # 🔥 Normal TEXT flow
    @message.save!

    # If last question → finish
    if @session.current_question_number >= 25
      @session.update!(status: "completed")
      return redirect_to final_report_assistant_session_path(@session)
    end

    next_question_number = @session.current_question_number + 1

    history = @session.messages.order(:created_at).last(10)
                .map { |m| "#{m.role.capitalize}: #{m.content}" }
                .join("\n")

    chat = RubyLLM.chat(model: "gpt-4o-mini")

    ai_response = chat.ask(<<~PROMPT)
      #{SystemPrompt.text}

      Role: #{@session.role}

      Recent conversation:
      #{history}

      Ask interview question number #{next_question_number}.
    PROMPT

    @session.messages.create!(
      role: "assistant",
      content: ai_response.content
    )

    @session.update!(current_question_number: next_question_number)
    respond_with_turbo
  end

  private

  def handle_pdf(file)
    text = extract_pdf_text(file)

    chat = RubyLLM.chat(model: "gpt-4o-mini")

    response = chat.ask(<<~PROMPT)
      You are a professional assistant.
      A PDF was uploaded by the user. Extract meaning and summarize it.

      PDF Content:
      #{text}

      Provide a clear, structured explanation.
    PROMPT

    response.content
  end

  # Safe PDF reader with error handling
  def extract_pdf_text(file)
    PDF::Reader.new(file.download).pages.map(&:text).join("\n")
  rescue => e
    "PDF extraction error: #{e.message}"
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
