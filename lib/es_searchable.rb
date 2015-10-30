require "es_searchable/version"

module EsSearchable
  extend ActiveSupport::Concern

  SearchMethods = [:where, :like, :limit, :offset, :or, :not]

  included do
    if self < ActiveRecord::Base
      include Elasticsearch::Model, Elasticsearch::Model::Callbacks
    end

    class << self
      delegate *SearchMethods, to: :es_collection, prefix: :es

      def es_collection
        SearchCollection.new(self)
      end

			def handle_es_response(es_coll)
				es_coll
			end

      def client
        @client ||= Elasticsearch::Client.new log: true
      end

      def es_search(conditions)
        if self < ActiveRecord::Base
          self.__elasticsearch__.search(conditions)
        else
          client.search(index: index, body: conditions)
        end
      end

      def es_index(index)
        @index = index
      end

      def index
        @index ||= self.name.demodulize.downcase.pluralize
      end

      def method_missing(meth, *args, &blk)
        case meth
        when /(.*)_(gt|lt|gte|lte|between|like)/
          es_collection.send(meth, *args, &blk)
        else
          super
        end
      end
    end

  end
end

require "es_searchable/search_collection"
