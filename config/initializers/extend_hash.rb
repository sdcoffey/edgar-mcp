# frozen_string_literal: true

module Extensions
  module DeepUnderscore
    def deeply_underscore
      deep_transform_keys do |key|
        next key.to_s.underscore.to_sym if key.length > 1

        key
      end
    end

    def deeply_camelize(method = :lower)
      deep_transform_keys { |key| key.to_s.camelize(method).to_sym }
    end

    def deeply_camelize!(method = :lower)
      deep_transform_keys! { |key| key.to_s.camelize(method).to_sym }
    end
  end
end

Hash.include Extensions::DeepUnderscore
