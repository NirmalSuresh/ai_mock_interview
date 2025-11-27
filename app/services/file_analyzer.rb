require "groq"
require "down"
require "base64"
require "pdf-reader"

class FileAnalyzer
  def self.call(message)
    file = message.attachment
    ext  = File.extname(file.filename.to_s).downcase

    # Download file bytes
    tmp = Down.download(file.url)
    bytes = tmp.read

    client = Groq::Client.new(api_key: ENV["GROQ_API_KEY"])

    # ----------------------------
    # A) IMAGE
    # ----------------------------
    if file.image?
      base64_img = Base64.strict_encode64(bytes)
      data_uri = "data:#{file.content_type};base64,#{base64_img}"

      response = client.chat.completions.create(
        model: "llama-3.2-11b-vision-preview",
        messages: [
          {
            role: "user",
            content: [
              { type: "input_text", text: "Extract text, describe the image & give interview insights." },
              { type: "input_image", image_data: data_uri }
            ]
          }
        ]
      )

      return response.choices[0].message["content"]
    end

    # ----------------------------
    # B) PDF
    # ----------------------------
    if ext == ".pdf"
      reader = PDF::Reader.new(tmp.path)
      text = reader.pages.map(&:text).join("\n")

      ai = client.chat.completions.create(
        model: "llama-3.1-70b-versatile",
        messages: [
          { role: "system", content: "You are a document analysis expert." },
          { role: "user", content: "Analyze this PDF text:\n#{text}" }
        ]
      )

      return ai.choices[0].message["content"]
    end

    # ----------------------------
    # C) TXT or MD
    # ----------------------------
    if [".txt", ".md"].include?(ext)
      text = bytes.force_encoding("UTF-8")

      ai = client.chat.completions.create(
        model: "llama-3.1-70b-versatile",
        messages: [
          { role: "system", content: "Analyze this text document." },
          { role: "user", content: text }
        ]
      )

      return ai.choices[0].message["content"]
    end

    "Unsupported file format. Upload image or PDF."

  rescue => e
    "Error analyzing file: #{e.message}"
  end
end
