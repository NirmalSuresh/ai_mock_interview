require "json"

class InterviewEvaluator
  def self.call(session)
    return unless session.completed?
    return if session.total_score.present?  # evaluate only once

    transcript = session.messages.order(:created_at).map do |m|
      "#{m.role.upcase}: #{m.content}"
    end.join("\n\n")

    chat = RubyLLM.chat(model: "gpt-4o-mini")

    llm_response = chat.ask(<<~PROMPT)
      You are an interview evaluator.

      Evaluate this mock interview for the role #{session.role}.

      Conversation:
      #{transcript}

      Provide a JSON object with EXACTLY these keys:
      {
        "score": number 0-100,
        "strengths": "text",
        "weaknesses": "text",
        "summary": "text",
        "ai_feedback": "overall feedback in 2-3 sentences"
      }

      Respond ONLY in valid JSON. No commentary. No explanation. No code block fences.
    PROMPT

    begin
      data = JSON.parse(llm_response.content)

      session.update!(
        total_score: data["score"],
        strengths:   data["strengths"],
        weaknesses:  data["weaknesses"],
        summary:     data["summary"],
        ai_feedback: data["ai_feedback"]
      )

    rescue JSON::ParserError
      Rails.logger.warn "InterviewEvaluator: invalid JSON from LLM"

      # Fallback to prevent 500 errors on final_report view
      session.update!(
        ai_feedback: "The AI could not generate structured feedback, but the interview was completed."
      )
    end
  end
end
