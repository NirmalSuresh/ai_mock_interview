class FileAnalyzer
  def self.call(message)
    file = message.attachment

    # Download actual binary file data from ActiveStorage
    file_data = file.download
    filename = file.filename.to_s
    content_type = file.content_type

    # Build prompt depending on file type
    prompt = case content_type
    when /\Aimage\//
      "You are an AI that analyzes an uploaded IMAGE. " \
      "Describe the image, extract any visible text, and give brief interview-related insights."

    when /\Aaudio\//
      "You are an AI that analyzes an uploaded AUDIO file. " \
      "Transcribe it, summarize it, and provide communication-related interview feedback."

    when "application/pdf",
         "text/plain",
         "application/msword",
         "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      "You are an AI that analyzes a DOCUMENT uploaded by the user. " \
      "Extract text, summarize it, and give interview-related insights."

    else
      "Analyze this uploaded file (type: #{content_type}). Describe useful information."
    end

    chat = RubyLLM.chat(model: "gpt-4o-mini")

    response = chat.ask(
      prompt,
      files: [
        {
          name: filename,
          mime_type: content_type,
          data: file_data
        }
      ]
    )

    response.content.presence || "I couldn't analyze the file."
  end
end
