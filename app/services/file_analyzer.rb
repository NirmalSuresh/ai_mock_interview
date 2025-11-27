require "groq"
require "down"
require "base64"

class FileAnalyzer
  def self.call(message)
    file = message.attachment

    # 1) Download file from Cloudinary URL
    temp_file = Down.download(file.url)

    # 2) Read & Base64 encode
    base64_data = Base64.strict_encode64(temp_file.read)

    # 3) Build data URI based on file MIME type
    data_uri = "data:#{file.content_type};base64,#{base64_data}"

    client = Groq::Client.new(api_key: ENV["GROQ_API_KEY"])

    model = if file.image?
      "llama-3.2-11b-vision-preview"
    else
      "llama-3.1-70b-versatile"
    end

    # 4) Send file to Groq
    response = client.chat.completions.create(
      model: model,
      messages: [
        {
          role: "user",
          content: [
            { type: "input_text", text: prompt_for(file) },
            {
              type: "input_file",
              file: {
                file_data: data_uri
              }
            }
          ]
        }
      ]
    )

    response.choices[0].message["content"]
  rescue => e
    "Error analyzing file: #{e.message}"
  end

  # Prompts depending on file type
  def self.prompt_for(file)
    if file.image?
      "Analyze this IMAGE. Extract text, describe it, and give interview-related insights."
    else
      "Analyze this DOCUMENT/PDF. Extract content, summarize, and give interview-related insights."
    end
  end
end
