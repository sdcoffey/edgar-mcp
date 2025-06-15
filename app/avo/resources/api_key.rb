# frozen_string_literal: true

module Avo
  module Resources
    class ApiKey < Avo::BaseResource
      # self.includes = []
      # self.attachments = []
      # self.search = {
      #   query: -> { query.ransack(id_eq: params[:q], m: "or").result(distinct: false) }
      # }

      def fields
        field :id, as: :id
        field :token, as: :text
        field :user, as: :belongs_to
      end
    end
  end
end
