class MessagesController < ApplicationController
  before_action :authenticate_user!

  def create
    @session = current_user.assistant_sessions.find(params[:assistant_session_id])

    # If time over, mark completed and show session
    if @session.expired?
      @session.update!(status: "completed")
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to assistant_session_path(@session), alert: "Time is up!" }
      end
      return
    end

    # Save user's answer
    @session.messages.create!(
      role: "user",
      content: params[:content]
    )

    # If already at 25 questions, end interview
    if @session.current_question_number >= 25
      @session.update!(status: "completed")
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to report_assistant_session_path(@session) }
      end
      return
    end

    # Ask next question
    next_q = @session.current_question_number + 1

    history = @session.messages.order(:created_at)
                 .last(10)
                 .map { |m| "#{m.role}: #{m.content}" }
                 .join("\n")

    chat = RubyLLM.chat(model: "gpt-4o-mini")

    ai_response = chat.ask(
      "#{SystemPrompt.text}\n\n" \
      "Role: #{@session.role}\n\n" \
      "Conversation so far:\n#{history}\n\n" \
      "Now ask interview question ##{next_q} for this role. " \
      "Do NOT answer the question yourself."
    )

    @session.messages.create!(
      role: "assistant",
      content: ai_response.content
    )

    @session.update!(current_question_number: next_q)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to assistant_session_path(@session) }
    end
  end
end
