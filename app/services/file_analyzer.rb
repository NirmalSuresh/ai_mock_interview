class FileAnalyzer
  def self.call(message)
    file = message.attachment

    # 1. SAFE DOWNLOAD
    begin
      raw_data = file.blob.download
    rescue => e
      return "I couldn't download your file: #{e.message}"
    end

    return "The uploaded file was empty." if raw_data.blank?

    # FIXED: Correct way to read content-type
    content_type = file.blob.content_type
    base64 = Base64.strict_encode64(raw_data)
    data_url = "data:#{content_type};base64,#{base64}"

    chat = RubyLLM.chat(model: "gpt-4o-mini")

    # --------------------------------------------------------
    # IMAGE
    # --------------------------------------------------------
    if content_type.start_with?("image/")
      prompt = <<~PROMPT
        Analyze this IMAGE:
        1. Describe everything clearly.
        2. Extract ALL visible text (OCR).
        3. Give interview-related insights.
      PROMPT

      ai = chat.ask(prompt, with: { file: data_url })
      return ai.content.presence || "Could not analyze this image."
    end

    # --------------------------------------------------------
    # AUDIO
    # --------------------------------------------------------
    if content_type.start_with?("audio/")
      prompt = <<~PROMPT
        Analyze this AUDIO:
        1. Transcribe the full speech.
        2. Summarize it.
        3. Give interview communication feedback.
      PROMPT

      ai = chat.ask(prompt, with: { file: data_url })
      return ai.content.presence || "Could not analyze this audio."
    end

    # --------------------------------------------------------
    # DOCUMENTS (PDF, DOCX, TXT)
    # --------------------------------------------------------
    if %w[
      application/pdf
      text/plain
      application/msword
      application/vnd.openxmlformats-officedocument.wordprocessingml.document
    ].include?(content_type)

      prompt = <<~PROMPT
        Analyze this DOCUMENT:
        1. Extract all readable text.
        2. Summarize it in simple English.
        3. Provide interview-related insights.
      PROMPT

      ai = chat.ask(prompt, with: { file: data_url })
      return ai.content.presence || "Could not extract text."
    end

    # --------------------------------------------------------
    # UNSUPPORTED
    # --------------------------------------------------------
    "This file type (#{content_type}) is not supported."
  end
end
