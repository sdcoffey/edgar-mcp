# frozen_string_literal: true

class TestComponent < PreactComponent
  def initialize(title:, **)
    @title = title
    super(**)
  end

  def component_path
    'TestComponent'
  end

  def props
    {
      title:
    }
  end

  private

  attr_reader :title
end
