class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_session

  def create
    raw = params.dig(:message, :content).to_s.strip

    # User typed "end"
    if raw.downcase == "end"
      @session.update!(status: "completed")
      return redirect_to final_report_assistant_session_path(@session)
    end

    # Create message
    @message = @session.messages.create!(
      role: "user",
      content: raw.presence,
      attachment: message_params[:attachment]
    )

    if @message.attachment.attached?
      reply = analyze_file(@message)
      @session.messages.create!(role: "assistant", content: reply)
      ask_next_question
      return respond_ok
    end

    ask_next_question
    respond_ok
  end

  private

  ######################################################
  # FILE ANALYZER (RubyLLM only — works for ANY file)
  ######################################################
  def analyze_file(message)
    file = message.attachment

    client = RubyLLM::Client.new

    prompt = <<~TEXT
      You are a professional interview assistant.

      The candidate uploaded a file.
      URL: #{file.url}

      Please:
      - Extract text/content
      - Summarize
      - Give insights relevant to job interviews
    TEXT

    begin
      resp = client.chat(
        model: "gpt-4o-mini",
        messages: [
          { role: "user", content: prompt }
        ]
      )

      return resp["content"]

    rescue => e
      return "Error analyzing file: #{e.message}"
    end
  end

  ######################################################
  # GENERATE NEXT QUESTION (Stable, no errors)
  ######################################################
  def ask_next_question
    # Stop at 25
    if @session.current_question_number >= 25
      @session.update!(status: "completed")
      return
    end

    next_q = @session.current_question_number + 1

    history = @session.messages.last(12).map do |m|
      "#{m.role}: #{m.content}"
    end.join("\n")

    client = RubyLLM::Client.new

    ai = client.chat(
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: SystemPrompt.text },
        { role: "user", content: "Role: #{@session.role}" },
        { role: "user", content: "Conversation:\n#{history}" },
        { role: "user", content: "Ask interview question number #{next_q}." }
      ]
    )

    @session.messages.create!(role: "assistant", content: ai["content"])
    @session.update!(current_question_number: next_q)
  end

  ######################################################
  # Helpers
  ######################################################
  def respond_ok
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to assistant_session_path(@session) }
    end
  end

  def set_session
    @session = current_user.assistant_sessions.find(params[:assistant_session_id])
  end

  def message_params
    params.require(:message).permit(:content, :attachment)
  end
end
