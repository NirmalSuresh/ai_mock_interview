class FileAnalyzer
  def self.call(message)
    file = message.attachment

    prompt = <<~TEXT
      Analyze this file.
      URL: #{file.url}

      Extract content, summarize it, and give interview-related insights.
    TEXT

    begin
      chat = RubyLLM.chat(model: "gpt-4o-mini")
      response = chat.ask(prompt)
      response.content
    rescue => e
      "Error analyzing file: #{e.message}"
    end
  end
end
