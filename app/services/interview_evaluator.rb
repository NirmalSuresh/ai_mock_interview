require "json"

class InterviewEvaluator
  def self.call(session)
    return unless session.completed?
    return if session.total_score.present? # only evaluate once

    transcript = session.messages.order(:created_at).map do |m|
      "#{m.role.upcase}: #{m.content}"
    end.join("\n\n")

    chat = RubyLLM.chat(model: "gpt-4o-mini")

    response = chat.ask(<<~PROMPT)
      You are an interview evaluator.

      Evaluate this mock interview for the role #{session.role}.

      Conversation:
      #{transcript}

      Provide a JSON object with EXACTLY these keys:
      {
        "score": number,
        "strengths": "text",
        "weaknesses": "text",
        "summary": "text"
      }

      Respond with ONLY JSON. No explanation.
    PROMPT

    begin
      data = JSON.parse(response.content)

      session.update!(
        total_score: data["score"],
        strengths:   data["strengths"],
        weaknesses:  data["weaknesses"],
        summary:     data["summary"]
      )

    rescue JSON::ParserError
      Rails.logger.warn "InterviewEvaluator: invalid JSON from LLM"
      return nil   # <-- IMPORTANT FIX
    end
  end
end
