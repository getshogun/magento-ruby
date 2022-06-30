# frozen_string_literal: true

module Magento
  class CategoriesAttributes < Model
    self.primary_key = :id
    self.endpoint = 'categories/attributes'

    class << self
      protected

      def query
        Query.new(self, api_resource: 'categories/attributes')
      end
    end
  end
end
