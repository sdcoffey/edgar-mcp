# frozen_string_literal: true

class PreactComponent < ApplicationComponent
  def initialize(options: {}, render_mode: 'hydrate')
    @props = props
    @options = options
    @render_mode = render_mode
    @render_id = SecureRandom.hex(4)

    ImportMap.config.module(component_path)

    super()
  end

  def component_path
    raise NotImplementedError
  end

  def props
    {}
  end

  def requires_props?
    %w[client hydrate].include? render_mode
  end

  def ssr?
    %w[hydrate ssr].include? render_mode
  end

  def render_mode
    return 'client' if %w[hydrate ssr].include?(@render_mode) && ssr.nil?

    @render_mode
  end

  def ssr
    return @ssr if @ssr.present?

    response = HTTP.post(ssr_url, json: {
                           url: request.original_url,
                           component: File.basename(component_path),
                           props: @props
                         })

    return nil unless response.status.success?

    @ssr = response.to_s
  rescue StandardError
    nil
  end

  private

  def ssr_url
    host = ENV.fetch('SSR_HOST', 'localhost')
    port = ENV.fetch('SSR_PORT', '3400')

    "http://#{host}:#{port}"
  end
end
