class FileAnalyzer
  def self.call(message)
    file = message.attachment

    # --- Download actual file bytes ---
    raw_data = file.download

    # --- Convert to Base64 for RubyLLM ---
    base64 = Base64.strict_encode64(raw_data)
    data_url = "data:#{message.attachment_content_type};base64,#{base64}"

    content_type = message.attachment_content_type

    chat = RubyLLM.chat(model: "gpt-4o-mini")

    prompt = case content_type
    when /\Aimage\//
      <<~PROMPT
        Analyze this IMAGE:
        1. Describe what’s in the image.
        2. Extract text.
        3. Give brief interview feedback.
      PROMPT

    when /\Aaudio\//
      <<~PROMPT
        Analyze this AUDIO:
        1. Transcribe.
        2. Summarize.
        3. Give communication feedback.
      PROMPT

    when "application/pdf",
         "text/plain",
         "application/msword",
         "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      <<~PROMPT
        Analyze this DOCUMENT:
        1. Extract main text.
        2. Summarize.
        3. Give interview insights.
      PROMPT

    else
      "This file type is #{content_type}. Try to analyze it."
    end

    result = chat.ask(prompt, with: { file: data_url })
    result&.content || "I couldn't analyze that file."
  end
end
