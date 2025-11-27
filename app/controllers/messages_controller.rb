require "open-uri"

class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_session

  def create
    # END interview if time is up
    if @session.expired?
      @session.update!(status: "completed")
      return redirect_to final_report_assistant_session_path(@session)
    end

    @message = @session.messages.new(message_params)

    # Detect END typed by user
    raw_input = @message.content.to_s.strip.downcase
    if raw_input.start_with?("end")
      @session.update!(status: "completed")
      return redirect_to final_report_assistant_session_path(@session)
    end

    # ---------- PDF FLOW ----------
    if @message.file.attached?
      @message.save!

      ai_summary = handle_pdf(@message.file)

      @assistant_msg = @session.messages.create!(
        role: "assistant",
        content: ai_summary
      )

      return respond_with_turbo
    end

    # ---------- NORMAL TEXT FLOW ----------
    @message.save!

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

    @assistant_msg = @session.messages.create!(
      role: "assistant",
      content: ai_response.content
    )

    @session.update!(current_question_number: next_question_number)

    respond_with_turbo
  end

  private

  # NEW — WORKING PDF EXTRACTION (NO PDF::READER)
  def handle_pdf(file)
    pdf_data = file.download

    chat = RubyLLM.chat(model: "gpt-4o-mini")

    response = chat.ask(
      <<~PROMPT,
        You are a professional assistant.

        The user uploaded a PDF. Extract all readable text using OCR,
        understand the meaning, and generate a clear, structured summary.
      PROMPT
      files: [
        {
          name: "document.pdf",
          mime_type: "application/pdf",
          data: pdf_data
        }
      ]
    )

    response.content
  end

  # TurboStream response
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
