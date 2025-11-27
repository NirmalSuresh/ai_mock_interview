require "pdf/reader"
require "stringio"

class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_session

  def create
    if @session.expired?
      @session.update!(status: "completed")
      return redirect_to final_report_assistant_session_path(@session)
    end

    @message = @session.messages.new(message_params)

    # Detect "end"
    if @message.content.to_s.strip.downcase.start_with?("end")
      @session.update!(status: "completed")
      return redirect_to final_report_assistant_session_path(@session)
    end

    # SAVE EARLY so attachment exists
    @message.save!

    # 🔥 CORRECT PDF CHECK
    if @message.file.attached?
      ai_summary = handle_pdf(@message.file)

      @session.messages.create!(
        role: "assistant",
        content: ai_summary
      )

      return respond_with_turbo
    end

    # Normal text flow
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
      Summarize the uploaded PDF in clear bullet points.

      PDF CONTENT:
      #{text}
    PROMPT

    response.content
  end

  def extract_pdf_text(file)
    data = file.download   # raw bytes from Cloudinary
    io = StringIO.new(data)

    reader = PDF::Reader.new(io)
    reader.pages.map(&:text).join("\n")

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
