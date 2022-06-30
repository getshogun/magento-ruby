# frozen_string_literal: true

module Magento
  class CategoriesList < Model
    self.primary_key = :id
    self.endpoint = 'categories/list'

    class << self
      protected

      def query
        Query.new(self, api_resource: 'categories/list')
      end
    end
  end
end
