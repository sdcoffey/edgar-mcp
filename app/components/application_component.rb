# frozen_string_literal: true

class ApplicationComponent < ViewComponent::Base
  def before_render
    self.class.sidecar_files(['ts']).each { helpers.additional_script(sidecar_asset_name(it, '.ts')) }

    super
  end

  delegate :additional_script, :additional_stylesheet, :stimulus_controller, to: :helpers

  private

  def sidecar_asset_name(path, ext)
    base_path = Rails.root.join('app/')
    path = path.to_s.gsub(base_path.to_s, '')
    path.gsub(ext, '')
  end
end
