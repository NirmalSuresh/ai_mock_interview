class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_session

  def create
    # ❗ End interview if time expired
    if @session.expired?
      @session.update!(status: "completed")
      return redirect_to final_report_assistant_session_path(@session)
    end

    raw_input = params.dig(:message, :content).to_s
    user_input = raw_input.strip.downcase

    # ❗ Detect "end" BEFORE saving user message
    if user_input.start_with?("end")
      @session.update!(status: "completed")

      respond_to do |format|
        format.html { redirect_to final_report_assistant_session_path(@session) }

        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "messages",
            partial: "assistant_sessions/redirect_to_report",
            locals: { session: @session }
          )
        end
      end

      return
    end

    # -----------------------------------------
    # ⭐ Save user message
    # -----------------------------------------
    @message = @session.messages.create!(
      role: "user",
      content: raw_input
    )

    # -----------------------------------------
    # ⭐ If last question reached
    # -----------------------------------------
    if @session.current_question_number >= 25
      @session.update!(status: "completed")
      return redirect_to final_report_assistant_session_path(@session)
    end

    # -----------------------------------------
    # ⭐ Prepare next question
    # -----------------------------------------
    next_q = @session.current_question_number + 1

    history = @session.messages.order(:created_at).last(10)
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

    # -----------------------------------------
    # ⭐ Handle if LLM fails or returns nil
    # -----------------------------------------
    if ai_response.present? && ai_response.content.present?
      @assistant_msg = @session.messages.create!(
        role: "assistant",
        content: ai_response.content
      )
    else
      @assistant_msg = @session.messages.create!(
        role: "assistant",
        content: "I’m sorry, I didn’t get that properly. Please answer again."
      )
    end

    # -----------------------------------------
    # ⭐ Update session progress
    # -----------------------------------------
    @session.update!(current_question_number: next_q)

    # -----------------------------------------
    # ⭐ Respond with Turbo
    # -----------------------------------------
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to assistant_session_path(@session) }
    end
  end

  private

  def set_session
    @session = current_user.assistant_sessions.find(params[:assistant_session_id])
  end
end
