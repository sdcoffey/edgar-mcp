# frozen_string_literal: true

ActionController::Renderers.add :pretty_json do |obj, _options|
  json = JSON.pretty_generate(obj.as_json)
  self.content_type ||= Mime[:json]
  self.response_body = "#{json}\n"
end
