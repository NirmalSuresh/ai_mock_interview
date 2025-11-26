class AddInterviewFieldsToAssistantSessions < ActiveRecord::Migration[7.1]
  def change
    change_table :assistant_sessions do |t|
      t.string :role
      t.integer :current_question_number, default: 1
      t.datetime :started_at
      t.datetime :ends_at
      t.string :status, default: "in_progress"

      t.integer :total_score
      t.text :strengths
      t.text :weaknesses
      t.text :summary
    end
  end
end
