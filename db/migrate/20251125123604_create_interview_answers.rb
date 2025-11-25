class CreateInterviewAnswers < ActiveRecord::Migration[7.1]
  def change
    create_table :interview_answers do |t|
      t.references :assistant_session, null: false, foreign_key: true
      t.text :content
      t.integer :question_number

      t.timestamps
    end
  end
end
