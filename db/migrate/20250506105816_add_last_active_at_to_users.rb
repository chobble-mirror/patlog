class AddLastActiveAtToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :last_active_at, :datetime
  end
end
