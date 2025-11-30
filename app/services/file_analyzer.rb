class FileAnalyzer
  def self.call(message)
    file = message.attachment

    # 1. SAFE DOWNLOAD FROM CLOUDINARY
    begin
      raw_data = file.blob.download
    rescue => e
      return "I couldn't download your file: #{e.message}"
    end

    return "The uploaded file was empty. Please upload it again." if raw_data.blank?

    content_type = message.attachment_content_type
    base64 = Base64.strict_encode64(raw_data)

    chat = RubyLLM.chat(model: "gpt-4o-mini")

    # ---------------------------
    #  IMAGE (OCR)
    # ---------------------------
    if content_type.start_with?("image/")
      prompt = <<~PROMPT
        Analyze this IMAGE:
        1. Describe the image.
        2. Extract all visible text (OCR).
        3. Give job interview-related insights.
      PROMPT

      ai = chat.ask(
        prompt,
        images: [{ type: "base64", data: base64 }]
      )

      return ai.response.presence || "Could not analyze this image."
    end

    # ---------------------------
    #  AUDIO (optional)
    # ---------------------------
    if content_type.start_with?("audio/")
      prompt = <<~PROMPT
        Analyze this AUDIO:
        1. Transcribe the speech.
        2. Summarize the content.
        3. Give interview-related communication feedback.
      PROMPT

      ai = chat.ask(
        prompt,
        files: [{ type: "base64", data: base64, mime_type: content_type }]
      )

      return ai.response.presence || "Could not analyze this audio file."
    end

    # ---------------------------
    #  DOCUMENTS (PDF, DOCX, TXT)
    # ---------------------------
    if %w[
      application/pdf
      text/plain
      application/msword
      application/vnd.openxmlformats-officedocument.wordprocessingml.document
    ].include?(content_type)

      prompt = <<~PROMPT
        Analyze this DOCUMENT:
        1. Extract ALL readable text.
        2. Summarize it in simple English.
        3. Give interview-related insights.
      PROMPT

      ai = chat.ask(
        prompt,
        files: [{ type: "base64", data: base64, mime_type: content_type }]
      )

      return ai.response.presence || "Could not extract text from the document."
    end

    # ---------------------------
    # UNSUPPORTED FILE
    # ---------------------------
    "This file type (#{content_type}) is not fully supported."
  end
end
