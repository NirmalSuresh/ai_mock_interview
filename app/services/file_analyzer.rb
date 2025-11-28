class FileAnalyzer
  def self.call(message)
    file = message.attachment

    # --- 1. SAFEST way to download file from Cloudinary via ActiveStorage ---
    begin
      raw_data = file.blob.download # << use blob.download (never file.download)
    rescue => e
      return "I couldn't download your file: #{e.message}"
    end

    # --- 2. Validate data ---
    if raw_data.blank?
      return "The uploaded file was empty. Please upload the file again."
    end

    # --- 3. Convert to Base64 data URL ---
    base64 = Base64.strict_encode64(raw_data)
    data_url = "data:#{message.attachment_content_type};base64,#{base64}"

    # --- 4. Detect file type ---
    content_type = message.attachment_content_type

    prompt = case content_type
    when /\Aimage\//
      <<~PROMPT
        Analyze this IMAGE:
        1. Describe the image.
        2. Extract any visible text (OCR).
        3. Give job interview-related insights.
      PROMPT

    when /\Aaudio\//
      <<~PROMPT
        Analyze this AUDIO:
        1. Transcribe all speech.
        2. Summarize it.
        3. Give communication feedback for interviews.
      PROMPT

    when "application/pdf",
         "text/plain",
         "application/msword",
         "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      <<~PROMPT
        Analyze this DOCUMENT:
        1. Extract key text.
        2. Summarize it briefly.
        3. Give interview-related insights.
      PROMPT

    else
      "This file type (#{content_type}) may not be fully supported. Describe whatever you can."
    end

    # --- 5. Send to RubyLLM ---
    chat = RubyLLM.chat(model: "gpt-4o-mini")

    begin
      result = chat.ask(prompt, with: { file: data_url })
    rescue => e
      return "AI analysis failed: #{e.message}"
    end

    result&.content || "I couldn't analyze that file."
  end
end
