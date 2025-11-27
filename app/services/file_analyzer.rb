require "base64"

class FileAnalyzer
  def self.call(message)
    blob = message.attachment.blob
    file_path = ActiveStorage::Blob.service.send(:path_for, blob.key)
    base64_file = Base64.strict_encode64(File.read(file_path))

    chat = RubyLLM.chat(model: "gpt-4o-mini")

    prompt = base_prompt(message.attachment_content_type)

    result = chat.ask(
      prompt: prompt,
      input: {
        file: {
          name: blob.filename.to_s,
          mime_type: blob.content_type,
          data: base64_file
        }
      }
    )

    result&.content || "I couldn't analyze this file."
  end

  def self.base_prompt(content_type)
    if content_type.start_with?("image/")
      <<~PROMPT
        You are analyzing an image file uploaded by the user.
        1. Describe the image.
        2. Extract text (OCR).
        3. Give interview-related feedback.
      PROMPT

    elsif content_type.start_with?("audio/")
      <<~PROMPT
        You are analyzing an audio file uploaded by the user.
        1. Transcribe.
        2. Summarize.
        3. Give interview communication feedback.
      PROMPT

    elsif %w[
      application/pdf
      application/msword
      application/vnd.openxmlformats-officedocument.wordprocessingml.document
      text/plain
    ].include?(content_type)
      <<~PROMPT
        You are analyzing a document uploaded by the user.
        1. Extract the key text.
        2. Summarize it in 3–4 lines.
        3. Provide interview-related insights.
      PROMPT

    else
      "Describe and analyze this file."
    end
  end
end
