require 'es_searchable'
require 'elasticsearch/rails'
require 'elasticsearch/model'
require 'elasticsearch-api'

module EsSearchable
	class SearchCollection

		def initialize(klass)
			@klass = klass
		end

		SearchName = {
			and: :must, 
			or: :should, 
			not: :must_not
		}

		# define method #and#, #or# and #not#
		SearchName.each do |k, v|
			define_method k do |params|
				arr = parse_params(params)

				set_filters(arr.first, v)
				set_queries(arr.last, v)
				self.clone
			end
		end

		alias_method :where, :and
		alias_method :es_and, :and

		def like(params)
			store_conditions :query, :must, params.map { |k, v|
				if v.is_a?(Hash)
					{ match: { k => v.map {|_k, _v| { operator: _k, query: _v}}.first }}
				else
					{ match: { k => v }}
				end
			}
			self.clone
		end

		def select(*attrs)
			conditions.merge!(fields: attrs)
			self.clone
		end

		def limit(limit)
			@limit = conditions[:size] = limit
			self.clone
		end

		def offset(offset)
			@offset = conditions[:from] = offset
			self.clone
		end

		EsSearchable::SearchMethods.each do |meth|
			alias_method "es_#{meth}", meth
		end

		attr_reader :collections, :response, :count, :time

		def load
			load_data
			@klass.handle_es_response(self)
		end

		def load_json
			load_data
		end

		def each(&block)
		  self.load.collections.each(&block)
		end

		def map(&block)
		  self.load.collections.map(&block)
		end

		def search_params
			conditions
		end

		private

		def load_data
			@response = @klass.es_search(conditions)
			@response = @response.response if @response.respond_to?(:response)
			@time = @response["took"]
			@count = @response["hits"]["total"]

			@collections = @response["hits"]["hits"].map do |i| 
				i[conditions[:fields].present? ? "fields" : "_source"]
			end
			@response
		end

		def conditions
			@conditions ||= Hash.new { |h,k| h[k] = Hash.new(&h.default_proc) }
		end

		def set_filters(filters, type)
			store_conditions(:filter, type, filters)
		end

		def set_queries(queries, type)
			store_conditions(:query, type, queries)
		end

		def store_conditions(search_type, condition_type, conds)
			conds.blank? and return

			if conditions[:query][:filtered][search_type][:bool][condition_type].present?
				conditions[:query][:filtered][search_type][:bool][condition_type] += conds
			else
				conditions[:query][:filtered][search_type][:bool][condition_type] = conds
			end
		end

		def parse_params(params)
			filters, queries = [], []

			params.each do |k, v|
				case v
				when Array
					filters << { terms: { k => v } }
				when Hash
					v[:like].present? and queries << { match: {k => v.delete(:like)} }

					v.slice!(:lte, :gte, :lt, :gt)
					v.present? and filters << { range: { k => v } }
				else 
					filters << { term: { k => v } }
				end
			end

			[filters, queries]
		end

		def method_missing(meth, *args, &blk)
			case meth
			when /(.*)_(gt|lt|gte|lte)/
				conds = [{ range: { $1  =>  { $2.to_sym  => args.first } } }]
				store_conditions(:filter, :must, conds)
				return self.clone
			when /(.*)_between/
				conds = [{ range: { $1  =>  { gte: args[0], lte: args[1] } } }]
				store_conditions(:filter, :must, conds)
				return self.clone
			when /(.*)_like/
				conds = [{ match: { $1 => args.first } }]
				store_conditions(:query, :must, conds)
				return self.clone
			else
				super
			end
		end

	end
end
