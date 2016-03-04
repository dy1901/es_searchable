require "awesome_print"
require "es_searchable/version"
require "es_searchable/configurable"

module EsSearchable
	extend Configurable
  extend ActiveSupport::Concern

	included do
    class << self
			delegate *SearchMethods, to: :es_collection, prefix: :es
		end
	end

	module ClassMethods
		def es_collection
			SearchCollection.new(self)
		end

		def handle_es_response(es_coll)
			es_coll
		end

		def client
			@client ||= Elasticsearch::Client.new(EsSearchable.options.slice(
				:log, :retry_on_failure, :reload_on_failure, :hosts, :logger
			))
		end

		def es_search(conditions)
			client.search(index: index, body: conditions)
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

require "es_searchable/search_collection"
