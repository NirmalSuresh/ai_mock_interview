class MessagesController < ApplicationController
  before_action :set_session

  def create
    @message = @session.messages.create!(message_params.merge(sender: "user"))

    if params[:message][:file].present?
      @assistant_msg = @session.messages.create!(
        sender: "assistant",
        content: handle_pdf(@message.file)
      )
    else
      @assistant_msg = @session.messages.create!(
        sender: "assistant",
        content: handle_text(@message.content)
      )
    end

    @session.update(current_question_number: @session.current_question_number + 1)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @session }
    end
  end

  private

  def set_session
    @session = AssistantSession.find(params[:assistant_session_id])
  end

  def message_params
    params.require(:message).permit(:content, :file)
  end

  # -----------------------------
  # TEXT HANDLER
  # -----------------------------
  def handle_text(text)
    chat = RubyLLM.chat(model: "gpt-4o-mini")

    response = chat.ask(<<~PROMPT)
      You are a mock interview assistant.
      The user answered:

      "#{text}"

      Give a helpful, short response.
    PROMPT

    response.content
  end

  # -----------------------------
  # PDF HANDLER
  # -----------------------------
  def handle_pdf(file)
    pdf_text = extract_pdf_text(file)

    chat = RubyLLM.chat(model: "gpt-4o-mini")

    response = chat.ask(<<~PROMPT)
      The user uploaded a PDF resume. Analyze and summarize the key information.

      PDF CONTENT:
      #{pdf_text}
    PROMPT

    response.content
  end

  # -----------------------------
  # PDF EXTRACTION
  # -----------------------------
  def extract_pdf_text(file)
    # Download bytes from ActiveStorage → wrap in IO
    io = StringIO.new(file.download)

    reader = PDF::Reader.new(io)
    reader.pages.map(&:text).join("\n")
  rescue => e
    "PDF extraction failed: #{e.message}"
  end
end
