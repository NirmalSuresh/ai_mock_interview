class RemoveTitleFromAssistantSessions < ActiveRecord::Migration[7.1]
  def change
    remove_column :assistant_sessions, :title, :string
  end
end
