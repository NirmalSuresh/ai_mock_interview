require "json"

class InterviewEvaluator
  def self.call(session)
    return unless session.completed?
    return if session.total_score.present?

    transcript = session.messages.order(:created_at).map do |m|
      "#{m.role}: #{m.content}"
    end.join("\n")

    chat = RubyLLM.chat(model: "gpt-4o-mini")

    response = chat.ask(<<~PROMPT)
      You are now evaluating a completed mock interview for the role #{session.role}.

      Conversation transcript:
      #{transcript}

      Evaluate the candidate's overall performance.

      Respond in VALID JSON only, no markdown, no comments.
      Use exactly this structure:

      {
        "score": 0-100 integer,
        "strengths": "one or two paragraphs",
        "weaknesses": "one or two paragraphs",
        "summary": "short paragraph summarizing the performance"
      }
    PROMPT

    begin
      data = JSON.parse(response.content)
      session.update!(
        total_score:  data["score"],
        strengths:    data["strengths"],
        weaknesses:   data["weaknesses"],
        summary:      data["summary"]
      )
    rescue JSON::ParserError
      # If AI messes up JSON, just skip update
      Rails.logger.warn "InterviewEvaluator: invalid JSON from LLM"
    end
  end
end
