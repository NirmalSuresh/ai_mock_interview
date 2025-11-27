# app/services/file_analyzer.rb
class FileAnalyzer
  def self.call(message)
    file = message.attachment
    client = RubyLLM::Client.new

    prompt = <<~TEXT
      The user uploaded a file.
      URL: #{file.url}

      Please extract text or content, summarize it,
      and provide interview insights.
    TEXT

    begin
      response = client.chat(
        model: "gpt-4o-mini",
        messages: [
          { role: "user", content: prompt }
        ]
      )

      response["content"]

    rescue => e
      "Error analyzing file: #{e.message}"
    end
  end
end
