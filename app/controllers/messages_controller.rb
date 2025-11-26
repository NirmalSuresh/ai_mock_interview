class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_session

  def create
    # Return safely if expired
    if @session.expired?
      @session.update!(status: "completed")
      return redirect_to final_report_assistant_session_path(@session)
    end

    raw_input = params.dig(:message, :content).to_s
    user_input = raw_input.strip

    # IGNORE empty
    if user_input.blank?
      return respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("message_form", partial: "messages/form", locals: { session: @session }) }
        format.html { redirect_to assistant_session_path(@session) }
      end
    end

    # "END" command
    if end_command?(user_input)
      @session.update!(status: "completed")

      return respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.redirect(final_report_assistant_session_path(@session))
        end
        format.html { redirect_to final_report_assistant_session_path(@session) }
      end
    end

    # Save user answer
    @session.messages.create!(role: "user", content: user_input)

    # Last question check
    if @session.current_question_number >= 25
      @session.update!(status: "completed")
      return respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.redirect(final_report_assistant_session_path(@session)) }
        format.html { redirect_to final_report_assistant_session_path(@session) }
      end
    end

    # History
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

      Ask interview question number #{@session.current_question_number + 1}.
    PROMPT

    @assistant_msg = @session.messages.create!(
      role: "assistant",
      content: ai_response.content
    )

    @session.update!(current_question_number: @session.current_question_number + 1)

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
    content.to_s.downcase.strip.start_with?("end")
  end
end
