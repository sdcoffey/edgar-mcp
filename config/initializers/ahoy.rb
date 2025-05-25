# frozen_string_literal: true

module Ahoy
  class Store < Ahoy::DatabaseStore
  end
end

# set to true for JavaScript tracking
Ahoy.api = false

# set to true for geocoding (and add the geocoder gem to your Gemfile)
# we recommend configuring local geocoding as well
# see https://github.com/ankane/ahoy#geocoding
Ahoy.track_bots = true
Ahoy.geocode = false
Ahoy.job_queue = :low

Ahoy.exclude_method = lambda do |_controller, request|
  request.path.starts_with? '/rails'
end
