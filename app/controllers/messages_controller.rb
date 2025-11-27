class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_session

  def create
    @message = @session.messages.create!(
      message_params.merge(sender: "user")
    )

    # If PDF is attached → process PDF
    if @message.file.attached?
      @assistant_msg = @session.messages.create!(
        sender: "assistant",
        content: process_pdf(@message.file)
      )
    else
      @assistant_msg = @session.messages.create!(
        sender: "assistant",
        content: process_answer(@message.content)
      )
    end

    # Increase question counter
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

  # ======================================
  # TEXT HANDLER
  # ======================================
  def process_answer(text)
    chat = RubyLLM.chat(model: "gpt-4o-mini")

    response = chat.ask(<<~PROMPT)
      You are a mock interview assistant.
      The candidate answered:

      "#{text}"

      Give a brief and helpful professional follow-up message.
    PROMPT

    response.content
  end

  # ======================================
  # PDF HANDLER (OCR + Summary)
  # ======================================
  def process_pdf(file)
    # Step 1: Get local temp path from ActiveStorage
    pdf_path = ActiveStorage::Blob.service.send(:path_for, file.blob.key)

    # Step 2: Cloudinary OCR
    result = Cloudinary::Uploader.upload(
      pdf_path,
      resource_type: "raw",
      ocr: "adv_ocr"
    )

    # Step 3: Extract OCR text
    ocr_text = result.dig(
      "info", "ocr", "adv_ocr", "data", 0,
      "textAnnotations", 0, "description"
    )

    return "PDF uploaded, but Cloudinary returned no readable text." if ocr_text.blank?

    # Step 4: Summarize with LLM
    chat = RubyLLM.chat(model: "gpt-4o-mini")
    response = chat.ask(<<~PROMPT)
      A resume PDF was uploaded. OCR extracted the text below:

      #{ocr_text}

      Create a professional structured resume summary containing:
      - One-line profile summary
      - Skills
      - Experience highlights
      - Education
      - Strengths
      - Mild weaknesses
      - Ideal job roles
    PROMPT

    response.content
  end
end
