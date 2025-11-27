require "open-uri"
require "base64"

class FileAnalyzer
  def self.call(message)
    blob = message.attachment.blob

    # Generate signed URL for the blob (works with Cloudinary)
    url = Rails.application.routes.url_helpers.rails_blob_url(blob, only_path: false)

    # Download the file (ActiveStorage will proxy it)
    file_data = URI.open(url).read
    base64_file = Base64.strict_encode64(file_data)

    chat = RubyLLM.chat(model: "gpt-4o-mini")

    result = chat.ask(
      prompt: prompt_for(blob.content_type),
      input: {
        file: {
          name: blob.filename.to_s,
          mime_type: blob.content_type,
          data: base64_file
        }
      }
    )

    result&.content || "I couldn't analyze the file."
  end

  def self.prompt_for(content_type)
    if content_type.start_with?("image/")
      <<~PROMPT
        Analyze this image:
        1. Describe it.
        2. Extract text (OCR).
        3. Give interview-related insights.
      PROMPT

    elsif content_type.start_with?("audio/")
      <<~PROMPT
        Analyze this audio:
        1. Transcribe it.
        2. Summarize.
        3. Give communication feedback.
      PROMPT

    elsif %w[
      application/pdf
      application/msword
      application/vnd.openxmlformats-officedocument.wordprocessingml.document
      text/plain
    ].include?(content_type)
      <<~PROMPT
        Analyze this document:
        1. Extract important text.
        2. Summarize briefly.
        3. Give interview-related insights.
      PROMPT

    else
      "Analyze this file."
    end
  end
end
