class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_session

  def create
    # End interview if timer expired
    if @session.expired?
      @session.update!(status: "completed") unless @session.completed?
      return redirect_to final_report_assistant_session_path(@session),
                         alert: "Time is up. Interview finished."
    end

    # Normalize user input
    raw_input = params.dig(:message, :content).to_s
    user_input = raw_input.strip

    # Ignore empty answers
    if user_input.blank?
      return redirect_to assistant_session_path(@session)
    end

    # Check for end commands BEFORE saving message
    if end_command?(user_input)
      @session.update!(status: "completed")
      return redirect_to final_report_assistant_session_path(@session),
                         notice: "Interview ended by you."
    end

    # Save user's answer
    @message = @session.messages.create!(
      role: "user",
      content: user_input
    )

    # If already at last question
    if @session.current_question_number >= 25
      @session.update!(status: "completed")
      return redirect_to final_report_assistant_session_path(@session),
                         notice: "Interview completed."
    end

    # Generate the next question
    next_q = @session.current_question_number + 1

    # Take conversation history for context (last 10 messages)
    history = @session.messages.order(:created_at)
                 .last(10)
                 .map { |m| "#{m.role.capitalize}: #{m.content}" }
                 .join("\n")

    chat = RubyLLM.chat(model: "gpt-4o-mini")

    ai_response = chat.ask(<<~PROMPT)
      #{SystemPrompt.text}

      Role: #{@session.role}

      Recent conversation:
      #{history}

      Ask interview question number #{next_q}.
    PROMPT

    @assistant_message = @session.messages.create!(
      role: "assistant",
      content: ai_response.content
    )

    # Update session progress
    @session.update!(current_question_number: next_q)

    # Turbo Stream append messages + clear input
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to assistant_session_path(@session) }
    end
  end

  private

  def set_session
    @session = current_user.assistant_sessions.find(params[:assistant_session_id])
  end

  def end_command?(content)
    normalized = content.downcase.strip
    ["end", "end test", "end the test", "finish", "stop", "quit"].include?(normalized)
  end
end
