class CleanAssistantSessions < ActiveRecord::Migration[7.1]
  def change
    remove_column :assistant_sessions, :role, :string
    remove_column :assistant_sessions, :current_question_number, :integer
    remove_column :assistant_sessions, :start_time, :datetime
    remove_column :assistant_sessions, :end_time, :datetime
    remove_column :assistant_sessions, :time_limit, :integer
    remove_column :assistant_sessions, :time_taken, :integer
    remove_column :assistant_sessions, :status, :string
    remove_column :assistant_sessions, :total_score, :integer
    remove_column :assistant_sessions, :strengths, :text
    remove_column :assistant_sessions, :weaknesses, :text
    remove_column :assistant_sessions, :summary, :text

    add_column :assistant_sessions, :title, :string
  end
end
