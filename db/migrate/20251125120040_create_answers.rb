class CreateAnswers < ActiveRecord::Migration[7.1]
  def change
    create_table :answers do |t|
      t.text :content
      t.integer :question_number
      t.references :assistant_session, null: false, foreign_key: true

      t.timestamps
    end
  end
end
