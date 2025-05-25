# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # TODO: Uncomment these lines to track page views using Ahoy
  # after_action :track_page_view, if: :should_track_page_view?
  #
  # def should_track_page_view?
  #   !request.xhr? &&
  #     request.get? &&
  #     !turbo_request? &&
  #     !response.redirect? &&
  #     response.media_type == 'text/html'
  # end
  #
  # def track_page_view
  #   ahoy.track('$view', { path: request.path, query: request.query_parameters })
  # end
  #
  # def turbo_request?
  #   request.headers['Turbo-Frame'].present? || request.headers['Accept'].include?('vnd.turbo-stream')
  # end
end
