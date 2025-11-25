class CreateInterviewAnswers < ActiveRecord::Migration[7.1]
  def change
    create_table :interview_answers do |t|
      t.references :assistant_session, null: false, foreign_key: true
      t.integer :question_number
      t.text :content

      t.timestamps
    end
  end
end
