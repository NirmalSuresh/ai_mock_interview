class FileAnalyzer
  def self.call(message)
    file = message.attachment

    # -- 1. Download actual file bytes from Cloudinary (ActiveStorage handles it)
    begin
      raw_data = file.download
    rescue => e
      return "I couldn't download your file: #{e.message}"
    end

    return "File is empty or unreadable." if raw_data.nil? || raw_data.empty?

    # -- 2. Base64 encode the file
    base64 = Base64.strict_encode64(raw_data)

    # -- 3. Build proper Base64 data URL
    data_url = "data:#{message.attachment_content_type};base64,#{base64}"

    # -- 4. Build prompt
    content_type = message.attachment_content_type

    prompt = case content_type
    when /\Aimage\//
      <<~PROMPT
        Analyze this IMAGE:
        1. Describe the image.
        2. Extract any text (OCR).
        3. Give interview feedback.
      PROMPT

    when /\Aaudio\//
      <<~PROMPT
        Analyze this AUDIO:
        1. Transcribe it.
        2. Summarize it.
        3. Provide communication feedback.
      PROMPT

    when "application/pdf",
         "text/plain",
         "application/msword",
         "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      <<~PROMPT
        Analyze this DOCUMENT:
        1. Extract key text.
        2. Summarize it.
        3. Give interview insights.
      PROMPT

    else
      "This file type is #{content_type}. Analyze if possible."
    end

    # -- 5. Send to RubyLLM (IMPORTANT: Use `file:` key)
    chat = RubyLLM.chat(model: "gpt-4o-mini")
    result = chat.ask(prompt, with: { file: data_url })

    result&.content || "I couldn't analyze that file."
  end
end
