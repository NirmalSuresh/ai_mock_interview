class RemoveSenderFromMessages < ActiveRecord::Migration[7.1]
  def change
    remove_column :messages, :sender, :string
  end
end
