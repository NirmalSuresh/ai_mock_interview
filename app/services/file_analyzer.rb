require "groq"
require "down"
require "base64"

class FileAnalyzer
  def self.call(message)
    file = message.attachment
    ext  = File.extname(file.filename.to_s).downcase

    # --------------------------------------------
    # 1) Download file from Cloudinary
    # --------------------------------------------
    tmp = Down.download(file.url)
    bytes = tmp.read

    client = Groq::Client.new(api_key: ENV["GROQ_API_KEY"])

    # --------------------------------------------
    # CASE A: IMAGE → Groq Vision
    # --------------------------------------------
    if file.image?
      base64_img = Base64.strict_encode64(bytes)
      data_uri = "data:#{file.content_type};base64,#{base64_img}"

      response = client.chat.completions.create(
        model: "llama-3.2-11b-vision-preview",
        messages: [
          {
            role: "user",
            content: [
              { type: "input_text", text: "Extract text from this image and summarize it for interview use." },
              { type: "input_image", image_url: data_uri }
            ]
          }
        ]
      )

      return response.choices[0].message["content"]
    end

    # --------------------------------------------
    # CASE B: PDF → Extract text locally → send text to Groq
    # --------------------------------------------
    if ext == ".pdf"
      require "pdf-reader"

      reader = PDF::Reader.new(tmp.path)
      text = reader.pages.map(&:text).join("\n")

      ai = client.chat.completions.create(
        model: "llama-3.1-70b-versatile",
        messages: [
          { role: "system", content: "You are a document analysis expert." },
          { role: "user", content: "Here is a PDF’s extracted text:\n\n#{text}\n\nSummarize it and give interview insights." }
        ]
      )

      return ai.choices[0].message["content"]
    end

    # --------------------------------------------
    # CASE C: DOCX / TXT / OTHERS → Treat as text
    # --------------------------------------------
    if ext == ".txt" || ext == ".md"
      text = bytes.force_encoding("UTF-8")

      ai = client.chat.completions.create(
        model: "llama-3.1-70b-versatile",
        messages: [
          { role: "system", content: "Analyze this document." },
          { role: "user", content: text }
        ]
      )

      return ai.choices[0].message["content"]
    end

    # --------------------------------------------
    # DEFAULT FALLBACK
    # --------------------------------------------
    return "Unsupported file format. Please upload PDF or an image."

  rescue => e
    "Error analyzing file: #{e.message}"
  end
end
