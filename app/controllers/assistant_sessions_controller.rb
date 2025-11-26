def create
  @session = current_user.assistant_sessions.create!(
    role: params[:role],
    current_question_number: 1,
    started_at: Time.current,
    ends_at: Time.current + 60.minutes,
    status: "in_progress"
  )

  # Generate Question 1 immediately
  chat = RubyLLM.chat(model: "gpt-4o-mini")

  ai_response = chat.ask(
    "#{SystemPrompt.text}\n\n" \
    "Role: #{params[:role]}\n" \
    "Ask ONLY interview question #1 for this role. Do NOT answer it."
  )

  @session.messages.create!(
    role: "assistant",
    content: ai_response.content
  )

  redirect_to assistant_session_path(@session)
end
