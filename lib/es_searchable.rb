require "awesome_print"
require "es_searchable/version"
require "es_searchable/configurable"
require "es_searchable/indexer_creator"

module EsSearchable
	extend Configurable
  extend ActiveSupport::Concern

	included do
    class << self
			delegate *SearchMethods, to: :es_collection, prefix: :es
		end

		if self < ActiveRecord::Base
			include Elasticsearch::Model

			if EsSearchable.async_callback
				cattr_accessor :indexer, :indexed_attributes, :attribute_blacklist

				self.indexer = IndexerCreator.create(self)
				self.attribute_blacklist = %w(
					hashed_password encrypted_password reset_password_token
				)

				after_save do
					should_perform_index? and indexer.perform_async(
						:index,  self.id, self.changed_attributes
					)
				end

				after_destroy do
					should_perform_index? and indexer.perform_async(
						:delete, self.id, self.changed_attributes
					)
				end
			else
				include Elasticsearch::Model::Callbacks
			end
		end
	end

	def should_perform_index?
		self.class.indexed_attributes ||=
			self.class.mapping.to_hash[self.class.name.underscore.to_sym][:properties].keys
		(self.class.indexed_attributes & self.changed.map(&:to_sym)).present?
	end

	def to_indexed_json
		self.attributes.except *self.class.attribute_blacklist
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
