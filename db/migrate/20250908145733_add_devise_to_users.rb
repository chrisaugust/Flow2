class AddDeviseToUsers < ActiveRecord::Migration[7.1]
  def change
    change_table :users do |t|
      # Keep password_digest - don't remove it!
      # Add Devise's encrypted_password alongside it
      t.string :encrypted_password unless column_exists?(:users, :encrypted_password)
      
      # Track migration status
      t.boolean :migrated_to_devise, default: false, null: false
      
      # Devise fields
      t.string   :reset_password_token unless column_exists?(:users, :reset_password_token)
      t.datetime :reset_password_sent_at unless column_exists?(:users, :reset_password_sent_at)
      t.datetime :remember_created_at unless column_exists?(:users, :remember_created_at)
      
      # Trackable (optional but useful)
      t.integer  :sign_in_count, default: 0, null: false unless column_exists?(:users, :sign_in_count)
      t.datetime :current_sign_in_at unless column_exists?(:users, :current_sign_in_at)
      t.datetime :last_sign_in_at unless column_exists?(:users, :last_sign_in_at)
      t.string   :current_sign_in_ip unless column_exists?(:users, :current_sign_in_ip)
      t.string   :last_sign_in_ip unless column_exists?(:users, :last_sign_in_ip)
    end
    
    add_index :users, :reset_password_token, unique: true unless index_exists?(:users, :reset_password_token)
  end
end
