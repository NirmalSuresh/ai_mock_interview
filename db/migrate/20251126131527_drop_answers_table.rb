class DropAnswersTable < ActiveRecord::Migration[7.1]
  def change
    drop_table :answers, if_exists: true
  end
end
