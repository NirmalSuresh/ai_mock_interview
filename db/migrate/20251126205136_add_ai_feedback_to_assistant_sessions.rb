class AddAiFeedbackToAssistantSessions < ActiveRecord::Migration[7.1]
  def change
    add_column :assistant_sessions, :ai_feedback, :text
  end
end
