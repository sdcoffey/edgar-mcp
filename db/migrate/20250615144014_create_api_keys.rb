# frozen_string_literal: true

class CreateApiKeys < ActiveRecord::Migration[8.0]
  def change
    create_table :api_keys do |t|
      t.string :token
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    add_index :api_keys, :token
  end
end
