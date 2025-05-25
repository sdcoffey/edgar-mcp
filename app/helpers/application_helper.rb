# frozen_string_literal: true

module ApplicationHelper
  def additional_script(name)
    RequestStore.store[:additional_scripts] ||= Set.new
    RequestStore.store[:additional_scripts] << name
  end

  def additional_stylesheet(name)
    RequestStore.store[:additional_stylesheets] ||= Set.new
    RequestStore.store[:additional_stylesheets] << name
  end

  # rubocop:disable Rails/OutputSafety
  def stimulus_controllers(*controllers)
    controllers.each { additional_script("javascript/controllers/#{it}") }

    "data-controller=\"#{controllers.join(' ')}\"".html_safe
  end
  # rubocop:enable Rails/OutputSafety
end
