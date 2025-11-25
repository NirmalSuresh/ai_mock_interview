class CreateQuestions < ActiveRecord::Migration[7.1]
  def change
    create_table :questions do |t|
      t.references :assistant_session, null: false, foreign_key: true
      t.integer :number
      t.text :content

      t.timestamps
    end
  end
end
