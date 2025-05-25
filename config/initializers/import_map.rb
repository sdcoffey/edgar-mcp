# frozen_string_literal: true

require_relative '../../app/lib/import_map'

ImportMap.configure do |map|
  map.import '@hotwired/turbo-rails'
  map.import '@hotwired/stimulus'
  map.import 'preact', include_subpackages: true
  map.import 'dayjs', include_subpackages: true

  map.module 'dayjs-init'
  map.mount_directory 'controllers'
end
