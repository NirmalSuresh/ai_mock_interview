class FileAnalyzer
  def self.call(message)
    file = message.attachment
    file_data = file.download
    filename = file.filename.to_s
    content_type = file.content_type

    prompt = case content_type
    when /\Aimage\//
      "You are an AI that analyzes an uploaded IMAGE. Describe it, extract text, and give interview insights."
    when /\Aaudio\//
      "You are an AI that analyzes an uploaded AUDIO file. Transcribe it, summarize it, and give communication feedback."
    when "application/pdf",
         "text/plain",
         "application/msword",
         "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      "You are an AI that analyzes an uploaded DOCUMENT. Extract text, summarize it, and give interview insights."
    else
      "Analyze this uploaded file (type: #{content_type})."
    end

    chat = RubyLLM.chat(model: "gpt-4o-mini")

    response = chat.ask(
      prompt,
      attachments: [
        {
          name: filename,
          content_type: content_type,
          data: file_data
        }
      ]
    )

    response.content.presence || "I couldn't analyze the file."
  end
end
