# frozen_string_literal: true

class AddLastUsedAtAndExpiresAtToApiKeys < ActiveRecord::Migration[8.0]
  def change
    add_column :api_keys, :last_used_at, :datetime
    add_column :api_keys, :expires_at, :datetime
  end
end
