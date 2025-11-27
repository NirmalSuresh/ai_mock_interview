class FileAnalyzer
  def self.call(message)
    file = message.attachment
    file_url = message.attachment_url
    content_type = message.attachment_content_type

    chat = RubyLLM.chat(model: "gpt-4o-mini")

    prompt = case content_type
    when /\Aimage\//
      <<~PROMPT
        Analyze this IMAGE from the user:
        URL: #{file_url}

        1. Describe what's in the image.
        2. Extract any text (OCR).
        3. Give brief interview-related feedback.
      PROMPT

    when /\Aaudio\//
      <<~PROMPT
        Analyze this AUDIO from the user:
        URL: #{file_url}

        1. Transcribe the audio.
        2. Summarize it (1–2 sentences).
        3. Give feedback related to interview communication.
      PROMPT

    when "application/pdf",
         "text/plain",
         "application/msword",
         "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      <<~PROMPT
        Analyze this DOCUMENT from the user:
        URL: #{file_url}

        1. Extract main text.
        2. Summarize it.
        3. Give short interview-relevant insights.
      PROMPT

    else
      <<~PROMPT
        This file type is #{content_type}.
        Try to describe it if possible.
      PROMPT
    end

    result = chat.ask(prompt)
    result&.content || "I couldn't analyze that file."
  end
end
