class FileAnalyzer
  def self.call(message)
    attachment = message.attachment

    return "No file found." unless attachment.attached?

    file_bytes = attachment.download
    filename = attachment.filename.to_s
    content_type = attachment.content_type

    # A simple instruction for system prompt
    system_prompt = case content_type
    when /\Aimage\//
      "You are an expert at analyzing user-uploaded IMAGES. Describe the image, extract text, and give interview insights."
    when /\Aaudio\//
      "You are an expert at analyzing AUDIO files. Transcribe the speech, summarize, and give communication feedback."
    when /pdf|msword|text|officedocument/
      "You are an expert at analyzing DOCUMENTS. Extract text, summarize, and give interview insights."
    else
      "You are an AI assistant. Analyze the uploaded file."
    end

    # RUBYLLM LEGACY API
    client = RubyLLM.chat(model: "gpt-4o-mini")

    result = client.ask(
      system_prompt,
      attachments: [
        {
          name: filename,
          data: file_bytes,
          content_type: content_type
        }
      ]
    )

    # Make sure it never returns nil
    (result&.content || "I could not analyze that file.").to_s
  end
end
