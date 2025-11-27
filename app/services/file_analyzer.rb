require "base64"
require "groq"

class FileAnalyzer
  def self.call(message)
    blob = message.attachment.blob
    file_bytes = blob.download
    content_type = blob.content_type

    client = Groq::Client.new(api_key: ENV["GROQ_API_KEY"])

    # ---------------------------------------------------
    # 1. Detect file type and choose correct model
    # ---------------------------------------------------
    if content_type.start_with?("image/")
      return analyze_image(client, file_bytes)
    elsif content_type.start_with?("audio/")
      return analyze_audio(client, file_bytes)
    elsif content_type.in?(["application/pdf",
                             "text/plain",
                             "application/msword",
                             "application/vnd.openxmlformats-officedocument.wordprocessingml.document"])
      return analyze_document(client, file_bytes)
    else
      return "Unsupported file type: #{content_type}"
    end
  end

  # ---------------------------------------------------
  # IMAGE ANALYSIS (OCR + Summary + Interview Insight)
  # ---------------------------------------------------
  def self.analyze_image(client, bytes)
    base64_img = Base64.strict_encode64(bytes)

    response = client.chat.completions.create(
      model: "llava-v1.6-34b",
      messages: [
        { role: "system", content: "You analyze images with OCR and give interview-related insights." },
        {
          role: "user",
          content: [
            {
              type: "input_image",
              image_url: "data:image/jpeg;base64,#{base64_img}"
            },
            {
              type: "text",
              text: "Describe image + Extract text + Give interview insights."
            }
          ]
        }
      ]
    )

    response.choices[0].message.content
  end

  # ---------------------------------------------------
  # AUDIO TRANSCRIPTION (Whisper)
  # ---------------------------------------------------
  def self.analyze_audio(client, bytes)
    file = Tempfile.new(["audio", ".mp3"])
    file.binmode
    file.write(bytes)
    file.rewind

    transcript = client.audio.transcriptions.create(
      model: "whisper-large-v3",
      file: file
    )

    text = transcript.text

    # Analyze the transcription with LLaMA model
    response = client.chat.completions.create(
      model: "llama-3.1-70b-versatile",
      messages: [
        { role: "system", content: "Summarize and give communication feedback." },
        { role: "user", content: text }
      ]
    )

    file.close
    file.unlink

    response.choices[0].message.content
  end

  # ---------------------------------------------------
  # PDF / DOCUMENT ANALYSIS
  # ---------------------------------------------------
  def self.analyze_document(client, bytes)
    base64_doc = Base64.strict_encode64(bytes)

    response = client.chat.completions.create(
      model: "llama-3.1-70b-versatile",
      messages: [
        { role: "system", content: "You read documents, extract text, summarize and give interview insights." },
        {
          role: "user",
          content: [
            {
              type: "input_file",
              file: "data:application/octet-stream;base64,#{base64_doc}"
            },
            {
              type: "text",
              text: "Extract full text + Summarize + Give interview-related insights."
            }
          ]
        }
      ]
    )

    response.choices[0].message.content
  end
end
