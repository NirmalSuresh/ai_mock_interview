require "groq"
require "down"
require "base64"
require "pdf-reader"

class FileAnalyzer
  def self.call(message)
    file = message.attachment

    # DOWNLOAD FILE FROM CLOUDINARY
    tmp = Down.download(file.url)
    bytes = tmp.read
    ext = File.extname(file.filename.to_s).downcase

    client = Groq::Client.new(api_key: ENV["GROQ_API_KEY"])

    # -----------------------------------------------------
    # A) IMAGE → Groq Vision (best model)
    # -----------------------------------------------------
    if file.image?
      base64_img = Base64.strict_encode64(bytes)
      data_uri = "data:#{file.content_type};base64,#{base64_img}"

      response = client.chat.completions.create(
        model: "llama-3.2-11b-vision-preview",
        messages: [
          {
            role: "user",
            content: [
              { type: "input_text", text: "Analyze this image: extract text + describe + give interview insights." },
              { type: "input_image", image_url: data_uri }
            ]
          }
        ]
      )

      return response.choices[0].message["content"]
    end

    # -----------------------------------------------------
    # B) PDF → Extract locally → Send text to Groq
    # -----------------------------------------------------
    if ext == ".pdf"
      reader = PDF::Reader.new(tmp.path)
      pdf_text = reader.pages.map(&:text).join("\n")

      ai = client.chat.completions.create(
        model: "llama-3.1-70b-versatile",
        messages: [
          { role: "system", content: "You are an expert resume/document analyzer." },
          {
            role: "user",
            content: "Here is the PDF text:\n\n#{pdf_text}\n\nSummarize it and give interview-relevant insights."
          }
        ]
      )

      return ai.choices[0].message["content"]
    end

    # -----------------------------------------------------
    # C) TEXT FILES
    # -----------------------------------------------------
    if ext == ".txt" || ext == ".md"
      text = bytes.force_encoding("UTF-8")

      ai = client.chat.completions.create(
        model: "llama-3.1-70b-versatile",
        messages: [
          { role: "user", content: "Analyze this text:\n\n#{text}" }
        ]
      )

      return ai.choices[0].message["content"]
    end

    # -----------------------------------------------------
    # UNSUPPORTED FILE
    # -----------------------------------------------------
    "Unsupported file format. Upload image or PDF."

  rescue => e
    "Error analyzing file: #{e.message}"
  end
end
