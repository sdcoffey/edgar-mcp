# frozen_string_literal: true

def mock_ahoy_visit(**factory_args)
  create(:ahoy_visit, **factory_args).tap do |ahoy_visit|
    cookies['ahoy_visit'] = ahoy_visit.visit_token
    cookies['ahoy_visitor'] = ahoy_visit.visitor_token
  end
end
