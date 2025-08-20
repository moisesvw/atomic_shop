# frozen_string_literal: true

class EnhanceUsersForAuthentication < ActiveRecord::Migration[8.0]
  def change
    # Add missing columns (some already exist with different names)
    add_column :users, :email_verified_at, :datetime unless column_exists?(:users, :email_verified_at)
    add_column :users, :password_reset_token, :string unless column_exists?(:users, :password_reset_token)
    add_column :users, :password_reset_sent_at, :datetime unless column_exists?(:users, :password_reset_sent_at)

    # Rename existing columns to match our model
    rename_column :users, :failed_attempts, :failed_login_attempts if column_exists?(:users, :failed_attempts)
    rename_column :users, :last_sign_in_at, :last_login_at if column_exists?(:users, :last_sign_in_at)

    # Add indexes for performance
    add_index :users, :email_verification_token, unique: true unless index_exists?(:users, :email_verification_token)
    add_index :users, :password_reset_token, unique: true unless index_exists?(:users, :password_reset_token)
    add_index :users, :email_verified unless index_exists?(:users, :email_verified)
    add_index :users, :locked_at unless index_exists?(:users, :locked_at)
  end
end
