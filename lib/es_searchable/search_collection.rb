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

		Attrs = [:collections, :response, :count, :time]

		# define method #and#, #or# and #not#
		SearchName.each do |k, v|
			define_method k do |params|
				set_filters(parse_params(params), v)
				self.clone
			end
		end

		alias_method :where, :and
		alias_method :es_and, :and

		def like(params)
			store_conditions :query, :must, params.map { |k, v| parse_like_params(k, v) }
			self.clone
		end

		def parse_like_params(key, value)
			if value.is_a?(Hash)
				{ match: { key => value.map {|k, v| { operator: k, query: v}}.first }}
			else
				{ match: { key => value }}
			end
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

		attr_reader *Attrs

		Attrs.each do |attr|
			define_method attr do
				instance_variable_get("@#{attr}").nil? and load_data
				instance_variable_get("@#{attr}")
			end
		end

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

		def ==(coll)
			self.search_params == coll.search_params
		end

		delegate :first, :last, :[], :length, to: :collections

		private

		def load_data
			@response = @klass.es_search(conditions)
			@time = @response["took"]
			@count = @response["hits"]["total"]

			@collections = @response["hits"]["hits"].map do |i| 
				if self.search_params[:fields].blank?
					i['_source']
				else
					{}.tap do |hash|
						i['fields'].each do |k, v|
							hash[k] = [v].flatten.first
						end
					end
				end
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
			[].tap do |filters|
				params.each do |k, v|
					case v
					when Array
						filters << { terms: { k => v } }
					when Hash
						if SearchName.include?(k)
							filters << { bool: { SearchName[k.to_sym] => parse_params(v) } }
						else
							v[:like].present? and filters << { query: parse_like_params(k, v[:like]) }

							v.slice!(:lte, :gte, :lt, :gt)
							v.present? and filters << { range: { k => v } }
						end
					else 
						filters << { term: { k => v } }
					end
				end
			end
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
				if args.length == 1
					conds = [{ match: { $1 => args.first } }]
					store_conditions(:query, :must, conds)
				elsif args.length == 2 && %w(and or).include?(args.last.to_s)
					conds = [{ match: { $1 => { operator: args.last, query: args.first } } }]
					store_conditions(:query, :must, conds)
				else
				end
				return self.clone
			else
				super
			end
		end

	end
end
