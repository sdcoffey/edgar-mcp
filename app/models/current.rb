# frozen_string_literal: true

class Current < ActiveSupport::CurrentAttributes
  attribute :user, :organization, :api_key
end
