# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)
Rails.logger.debug 'Deleting existing data...'

# Delete in order to avoid foreign key constraint issues
ApiKey.delete_all
User.delete_all
Organization.delete_all

Rails.logger.debug 'All existing data deleted.'

Rails.logger.debug 'Seeding database with sample data...'

# --- Organizations ---
org_names = [
  'Acme Corp',
  'Globex Industries',
  'Umbrella Co.'
]

organizations = org_names.map do |name|
  Organization.find_or_create_by!(name: name)
end

Rails.logger.debug { "Created/Found #{organizations.size} organizations." }

# --- Users & API Keys ---
organizations.each do |org|
  3.times do |n|
    user = User.find_or_create_by!(
      organization: org,
      email: "user#{n + 1}@#{org.name.parameterize}.example",
      name: "#{org.name} User #{n + 1}"
    )

    # One API key per user
    api_key = ApiKey.create!(organization: org, user: user)

    Rails.logger.debug { "Organization: #{org.name} | User: #{user.email} | API Token: #{api_key.token}" }
  end
end

Rails.logger.debug 'Seeding complete.'
