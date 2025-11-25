class CreateAssistantSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :assistant_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :role
      t.integer :current_question_number
      t.datetime :start_time
      t.datetime :end_time
      t.integer :time_limit
      t.integer :time_taken
      t.string :status
      t.integer :total_score
      t.text :strengths
      t.text :weaknesses
      t.text :summary

      t.timestamps
    end
  end
end
