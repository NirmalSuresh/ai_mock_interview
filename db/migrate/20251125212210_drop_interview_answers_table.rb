class DropInterviewAnswersTable < ActiveRecord::Migration[7.1]
  def change
    drop_table :interview_answers
  end
end
