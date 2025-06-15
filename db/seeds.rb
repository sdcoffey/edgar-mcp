# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

# Clear existing data in development
if Rails.env.development?
  Rails.logger.debug '🗑️  Cleaning up existing data...'
  ApiKey.destroy_all
  OrganizationMembership.destroy_all
  Organization.destroy_all
  User.destroy_all
  Rails.logger.debug '✅ Data cleaned up!'
end

Rails.logger.debug '🌱 Creating seed data...'

# Create users
users = [
  {
    name: 'Alice Johnson',
    email: 'alice@example.com',
    password: 'password123'
  },
  {
    name: 'Bob Smith',
    email: 'bob@example.com',
    password: 'password123'
  },
  {
    name: 'Charlie Brown',
    email: 'charlie@example.com',
    password: 'password123'
  }
]

created_users = users.map do |user_attrs|
  user = User.create!(user_attrs)
  Rails.logger.debug { "👤 Created user: #{user.name} (#{user.email})" }
  user
end

# Create organizations
organizations = [
  {
    name: 'Acme Corp'
  },
  {
    name: 'Widget Inc'
  }
]

created_orgs = organizations.map do |org_attrs|
  org = Organization.create!(org_attrs)
  Rails.logger.debug { "🏢 Created organization: #{org.name}" }
  org
end

# Create organization memberships
memberships = [
  # Alice is owner of Acme Corp
  { user: created_users[0], organization: created_orgs[0], role: 'owner' },
  # Bob is admin of Acme Corp
  { user: created_users[1], organization: created_orgs[0], role: 'admin' },
  # Charlie is member of Acme Corp
  { user: created_users[2], organization: created_orgs[0], role: 'member' },
  # Alice is also owner of Widget Inc
  { user: created_users[0], organization: created_orgs[1], role: 'owner' },
  # Bob is member of Widget Inc
  { user: created_users[1], organization: created_orgs[1], role: 'member' }
]

memberships.each do |membership_attrs|
  membership = OrganizationMembership.create!(membership_attrs)
  Rails.logger.debug do
    "🤝 Created membership: #{membership.user.name} is #{membership.role} of #{membership.organization.name}"
  end
end

# Create API keys
api_keys = [
  {
    user: created_users[0],
    organization: created_orgs[0],
    name: 'Production API Key',
    expires_at: 1.year.from_now
  },
  {
    user: created_users[1],
    organization: created_orgs[0],
    name: 'Development API Key',
    expires_at: 6.months.from_now
  },
  {
    user: created_users[2],
    organization: created_orgs[0],
    name: 'Read Only API Key',
    expires_at: 3.months.from_now
  }
]

api_keys.each do |api_key_attrs|
  api_key = ApiKey.create!(api_key_attrs)
  Rails.logger.debug { "🔑 Created API key: #{api_key.name} for #{api_key.user.name} (#{api_key.organization.name})" }
  Rails.logger.debug { "   Token: #{api_key.plain_token}" } if api_key.plain_token
end

Rails.logger.debug '🎉 Seed data created successfully!'
Rails.logger.debug ''
Rails.logger.debug '📊 Summary:'
Rails.logger.debug { "   Users: #{User.count}" }
Rails.logger.debug { "   Organizations: #{Organization.count}" }
Rails.logger.debug { "   Memberships: #{OrganizationMembership.count}" }
Rails.logger.debug { "   API Keys: #{ApiKey.count}" }
