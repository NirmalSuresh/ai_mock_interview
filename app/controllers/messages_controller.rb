require "rubyllm"

class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_session

  def create
    # If time expired → finish interview
    if @session.expired?
      @session.update!(status: "completed")
      return redirect_to final_report_assistant_session_path(@session)
    end

    @message = @session.messages.new(message_params)

    raw_input = @message.content.to_s.strip.downcase

    # END early
    if raw_input.start_with?("end")
      @session.update!(status: "completed")
      return redirect_to final_report_assistant_session_path(@session)
    end

    # PDF upload flow
    if @message.file.attached?
      @message.save!

      ai_summary = handle_pdf(@message.file)

      @assistant_msg = @session.messages.create!(
        role: "assistant",
        content: ai_summary
      )

      return respond_with_turbo
    end

    # Normal text message flow
    @message.save!

    # If last question
    if @session.current_question_number >= 25
      @session.update!(status: "completed")
      return redirect_to final_report_assistant_session_path(@session)
    end

    next_question_number = @session.current_question_number + 1

    history = @session.messages.order(:created_at).last(10)
                .map { |m| "#{m.role.capitalize}: #{m.content}" }
                .join("\n")

    chat = RubyLLM.chat(model: "gpt-4o-mini")

    ai_response = chat.ask(<<~PROMPT)
      #{SystemPrompt.text}

      Role: #{@session.role}

      Recent conversation:
      #{history}

      Ask interview question number #{next_question_number}.
    PROMPT

    @assistant_msg = @session.messages.create!(
      role: "assistant",
      content: ai_response.content
    )

    @session.update!(current_question_number: next_question_number)

    respond_with_turbo
  end

  private

  ###########################################################
  #  FIXED PDF HANDLER – WORKS WITH ALL RUBYLLM VERSIONS
  ###########################################################
  def handle_pdf(file)
    pdf_data = file.download

    client = RubyLLM::Client.new(model: "gpt-4o-mini")

    response = client.chat(
      messages: [
        {
          role: "system",
          content: "You are an AI assistant. Extract and summarize the content of the uploaded PDF. Use OCR if needed."
        },
        {
          role: "user",
          content: "Summarize the following PDF."
        }
      ],
      input: [
        {
          type: "input_text",
          text: "PDF uploaded by the user."
        },
        {
          type: "input_file",
          mime_type: "application/pdf",
          data: pdf_data
        }
      ]
    )

    response["output_text"]
  end

  ###########################################################
  # Helpers
  ###########################################################
  def respond_with_turbo
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to assistant_session_path(@session) }
    end
  end

  def message_params
    params.require(:message).permit(:content, :file)
  end

  def set_session
    @session = current_user.assistant_sessions.find(params[:assistant_session_id])
    @messages = @session.messages.order(:created_at)
  end
end
