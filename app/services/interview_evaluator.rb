require "json"

class InterviewEvaluator
  def self.call(session)
    return unless session.completed?
    return if session.total_score.present? # Already evaluated

    transcript = session.messages.order(:created_at).map do |m|
      "#{m.role.upcase}: #{m.content}"
    end.join("\n\n")

    chat = RubyLLM.chat(model: "gpt-4o-mini")

    response = chat.ask(<<~PROMPT)
      You are an interview evaluator.

      Evaluate this mock interview for the role #{session.role}.

      Conversation:
      #{transcript}

      Provide a JSON object with exactly these keys:
      {
        "score": number (0-100),
        "strengths": "text",
        "weaknesses": "text",
        "summary": "text"
      }

      ❗ VERY IMPORTANT:
      - Output ONLY valid JSON.
      - NO commentary.
      - NO markdown.
      - NO backticks.
      - If unsure, output {"score":50,"strengths":"-","weaknesses":"-","summary":"-"}
    PROMPT

    content = response.content.to_s.strip

    # --- Fix: Clean AI output ---
    content.gsub!(/```json|```/, "")
    content.gsub!(/\A.*?\{/, "{")   # everything before first {
    content.gsub!(/\}.*\z/, "}")   # everything after last }

    begin
      data = JSON.parse(content)

      session.update!(
        total_score: data["score"] || 50,
        strengths:   data["strengths"] || "Not provided",
        weaknesses:  data["weaknesses"] || "Not provided",
        summary:     data["summary"] || "Not provided"
      )

    rescue JSON::ParserError => e
      Rails.logger.warn "InterviewEvaluator: invalid JSON → #{content}"
      session.update!(
        total_score: 50,
        strengths: "AI was unable to generate strengths.",
        weaknesses: "AI was unable to generate weaknesses.",
        summary: "AI was unable to generate summary."
      )
    end
  end
end
