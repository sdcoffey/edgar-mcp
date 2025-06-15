# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

# Create a default organization
organization = Organization.find_or_create_by!(name: 'Default Organization')

# Create a default user
user = User.find_or_create_by!(email: 'user@example.com') do |u|
  u.organization = organization
end

# Create an API key for the user
api_key = ApiKey.find_or_create_by!(user: user)

Rails.logger.debug { "API Key: #{api_key.token}" }
