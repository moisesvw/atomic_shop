# frozen_string_literal: true

class CreateUserSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :user_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :session_token, null: false
      t.string :remember_token
      t.datetime :remember_token_expires_at
      t.string :ip_address
      t.string :user_agent
      t.datetime :last_activity_at
      t.timestamps
    end

    add_index :user_sessions, :session_token, unique: true
    add_index :user_sessions, :remember_token, unique: true
    add_index :user_sessions, :remember_token_expires_at
    add_index :user_sessions, :last_activity_at
  end
end
