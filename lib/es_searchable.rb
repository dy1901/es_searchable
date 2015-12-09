require "es_searchable/version"
require "awesome_print"

module EsSearchable
  extend ActiveSupport::Concern

  SearchMethods = [:where, :like, :limit, :offset, :or, :not, :select, :and]

	DEFAULTS = { 
		log: true,
		retry_on_failure: 5, 
		reload_on_failure: true, 
		hosts: ['localhost:9200'], 
		logger: Logger.new($stdout), 
	}

	class << self
		def configure
			yield self
		end

		def options
			@options ||= DEFAULTS.dup
		end

		def options=(opts)
			@options = opts
		end
	end

	DEFAULTS.each do |k, v|
		self.define_singleton_method "#{k}=" do |value|
			self.options.merge!(k => value)
		end

		self.define_singleton_method k do
			self.options[k]
		end
	end

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
				es_coll.response
			end

      def client
        @client ||= Elasticsearch::Client.new(EsSearchable.options)
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
