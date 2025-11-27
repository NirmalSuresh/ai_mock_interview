class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_session

  def create
    @message = @session.messages.create!(
      message_params.merge(sender: "user")
    )

    if @message.file.attached?
      @assistant_msg = @session.messages.create!(
        sender: "assistant",
        content: analyze_file(@message.file.blob)
      )
    else
      @assistant_msg = @session.messages.create!(
        sender: "assistant",
        content: process_answer(@message.content)
      )
    end

    @session.update!(
      current_question_number: @session.current_question_number + 1
    )

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

  # ==========================================================
  # NORMAL TEXT ANSWER
  # ==========================================================
  def process_answer(text)
    chat = RubyLLM.chat(model: "gpt-4o-mini")

    response = chat.ask(<<~PROMPT)
      You are a professional mock interview assistant.
      The candidate answered:

      "#{text}"

      Reply with a short, helpful next-step message.
    PROMPT

    response.content
  end

  # ==========================================================
  # FILE ANALYSIS — SUPER SIMPLE
  # ==========================================================
  def analyze_file(blob)
    content = extract_text(blob)
    return "File uploaded, but no readable text detected." if content.blank?

    chat = RubyLLM.chat(model: "gpt-4o-mini")

    response = chat.ask(<<~PROMPT)
      The candidate uploaded a file during the interview.

      The extracted text is:

      #{content}

      Give a short, professional analysis in 4–6 lines.
    PROMPT

    response.content
  end

  # Extracts text from ANY uploaded file (PDF or TXT)
  def extract_text(blob)
    text = ""

    blob.open do |tempfile|
      case blob.content_type
      when "application/pdf"
        reader = PDF::Reader.new(tempfile.path)
        text = reader.pages.map(&:text).join("\n")
      else
        text = File.read(tempfile.path)
      end
    end

    text
  rescue
    nil
  end
end
