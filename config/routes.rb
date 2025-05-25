# frozen_string_literal: true

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root 'root#index'

  # TODO: authenticate admin routes
  scope :admin do
    get '', to: redirect('/admin/avo')

    mount Flipper::UI.app, at: 'flipper'
    mount Blazer::Engine, at: 'blazer'
    mount Avo::Engine, at: 'avo'
  end
end
