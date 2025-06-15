# frozen_string_literal: true

class CreateOrganizationMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :organization_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :organization, null: false, foreign_key: true
      t.string :role, null: false, default: 'member'

      t.timestamps
    end

    add_index :organization_memberships, %i[user_id organization_id], unique: true,
                                                                      name: 'index_org_memberships_on_user_and_org'
    add_index :organization_memberships, :role
  end
end
