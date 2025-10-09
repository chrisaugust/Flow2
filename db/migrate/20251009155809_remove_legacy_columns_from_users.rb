class RemoveLegacyColumnsFromUsers < ActiveRecord::Migration[7.1]
  def change
    remove_column :users, :password_digest, :string
    remove_column :users, :migrated_to_devise, :boolean
  end
end
