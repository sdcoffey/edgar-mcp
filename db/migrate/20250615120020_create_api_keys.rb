# frozen_string_literal: true

class CreateApiKeys < ActiveRecord::Migration[8.0]
  def change
    create_table :api_keys do |t|
      t.string :token, null: false
      t.datetime :last_used_at
      t.datetime :expires_at
      t.datetime :revoked_at

      t.references :user, foreign_key: true
      t.references :organization, null: false, foreign_key: true

      t.timestamps
    end

    add_index :api_keys, :token, unique: true
    add_index :api_keys, :last_used_at
  end
end
