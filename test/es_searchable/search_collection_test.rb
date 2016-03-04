require 'test_helper'

class SearchCollectionTest < ActiveSupport::TestCase
	setup	do
	  class Foo
			include EsSearchable
		end

		@coll = EsSearchable::SearchCollection.new(Foo)
		@full_response = {
			"took"=>1,
			"timed_out"=>false,
			"_shards"=>{"total"=>5, "successful"=>5, "failed"=>0},
			"hits"=> {
				"total"=>2,
				"max_score"=>1.0,
				"hits"=> [
					{
						"_index"=>"outlets",
						"_type"=>"outlet",
						"_id"=>"3",
						"_score"=>1.0,
						"_source"=> {
							"id"=>3,
							"name" => "foo3"
						}
					},
					{
						"_index"=>"outlets",
						"_type"=>"outlet",
						"_id"=>"4",
						"_score"=>1.0,
						"_source"=> {
							"id"=>4,
							"name" => "foo4"
						}
					}
				]
			}
		}

		@select_response = {
			"took"=>1,
			"timed_out"=>false,
			"_shards"=>{"total"=>5, "successful"=>5, "failed"=>0},
			"hits"=> {
				"total"=>2,
				"max_score"=>1.0,
				"hits"=> [
					{
						"_index"=>"outlets",
						"_type"=>"outlet",
						"_id"=>"3",
						"_score"=>1.0,
						"fields"=> {
							"id"=>3,
							"name" => "foo3"
						}
					},
					{
						"_index"=>"outlets",
						"_type"=>"outlet",
						"_id"=>"4",
						"_score"=>1.0,
						"fields"=> {
							"id"=>4,
							"name" => "foo4"
						}
					}
				]
			}
		}
			
	end


	test "#initialize" do
		assert_equal @coll.instance_variable_get("@klass"), Foo
	end

	test "::SearchName" do
		assert_equal EsSearchable::SearchCollection::SearchName, {
			and: :must, 
			or: :should, 
			not: :must_not
		}
	end

	test "::Attrs" do
		assert_equal EsSearchable::SearchCollection::Attrs, [
			:collections, :response, :count, :time
		]
	end

	test "#and" do
		assert_call @coll, :set_filters, [], :must do
			@coll.and({})
		end

		assert_call @coll, :parse_params, {} do
			@coll.and({})
		end
	end

	test "#or" do
		assert_call @coll, :set_filters, [], :should do
			@coll.or({})
		end

		assert_call @coll, :parse_params, {} do
			@coll.or({})
		end
	end

	test "#not" do
		assert_call @coll, :set_filters, [], :must_not do
			@coll.not({})
		end

		assert_call @coll, :parse_params, {} do
			@coll.not({})
		end
	end

	test "#where is alias to #and" do
		assert_equal @coll.where({}), @coll.and({})
		assert_equal @coll.where({id: 1}), @coll.and({id: 1})
	end

	test "#es_and is alias to #and" do
		assert_equal @coll.es_and({}), @coll.and({})
		assert_equal @coll.es_and({name: :name}), @coll.and({name: :name})
	end

	test "#like" do
		assert_call @coll, :store_conditions, :query, :must, [] do
		  @coll.like({})
		end

		assert_call @coll, :parse_like_params, :name, 'name' do
		  @coll.like({name: 'name'})
		end
	end

	test "#parse_like_params" do
		assert_equal @coll.parse_like_params(:name, 'foo'), { match: { name: 'foo' } }

		assert_equal @coll.parse_like_params(:name, {and: 'foo'}), {
			match: { 
				name: {
					operator: :and, query: 'foo'
				}
			}
		}
	end

	test "#select" do
		assert_equal @coll.search_params[:fields], {}
		assert_equal @coll.select(:id, :name), @coll
		assert_equal @coll.search_params[:fields], [:id, :name]
	end

	test "#limit" do
		assert_equal @coll.search_params[:size], {}
		assert_equal @coll.limit(10), @coll
		assert_equal @coll.search_params[:size], 10
		assert_equal @coll.instance_variable_get('@limit'), 10
	end

	test "#offset" do
		assert_equal @coll.search_params[:from], {}
		assert_equal @coll.offset(10), @coll
		assert_equal @coll.search_params[:from], 10
		assert_equal @coll.instance_variable_get('@offset'), 10
	end

	test "#es_method defined by ::SearchMethods alias with prefix es_" do
		EsSearchable::SearchMethods.each do |method|
			params = {}
			es_method = "es_#{method}"
			assert_respond_to @coll, es_method
			assert_equal @coll.send(es_method, params), @coll.send(method, params)
		end
	end

	test "#collections" do
		assert_call @coll, :load_data do
		  @coll.collections
		end
		@coll.stubs(:load_data)
		assert_nil @coll.collections

		@coll.instance_variable_set '@collections', []
		assert_equal @coll.collections, []
	end

	test "#response" do
		assert_call @coll, :load_data do
		  @coll.response
		end
		@coll.stubs(:load_data)
		assert_nil @coll.response

		@coll.instance_variable_set '@response', []
		assert_equal @coll.response, []
	end

	test "#count" do
		assert_call @coll, :load_data do
		  @coll.count
		end
		@coll.stubs(:load_data)
		assert_nil @coll.count

		@coll.instance_variable_set '@count', []
		assert_equal @coll.count, []
	end

	test "#time" do
		assert_call @coll, :load_data do
		  @coll.time
		end
		@coll.stubs(:load_data)
		assert_nil @coll.time

		@coll.instance_variable_set '@time', []
		assert_equal @coll.time, []
	end

	test "#load" do
		assert_call @coll, :load_data do
		  @coll.load
		end

		@coll.stubs(:load_data)
		assert_call @coll.instance_variable_get("@klass"), :handle_es_response, @coll do
		  @coll.load
		end
	end

	test "#load_json" do
		assert_call @coll, :load_data do
		  @coll.load_json
		end

		@coll.stubs(:load_data).returns('x1x1x1')
		assert_equal @coll.load_json, 'x1x1x1'
	end

	test "#each" do
		collections = [1, 2, 3]
		@coll.stubs(:collections).returns(collections)

		assert_call @coll, :load, return_value: @coll.clone do
			@coll.each {}
		end

		@coll.stubs(:load).returns(@coll.clone)
		assert_call collections, :each do
			@coll.each {}
		end

		assert_equal @coll.each {|i| i.to_s}, collections.each {|i| i.to_s}
	end

	test "#map" do
		collections = [1, 2, 3]
		@coll.stubs(:collections).returns(collections)

		assert_call @coll, :load, return_value: @coll.clone do
			@coll.map do; end
		end

		@coll.stubs(:load).returns(@coll.clone)
		assert_call collections, :map do
			@coll.map do; end
		end

		assert_equal @coll.each {|i| i.to_s}, collections.each {|i| i.to_s}
	end

	test "#search_params" do
		assert_call @coll, :conditions do
			@coll.search_params
		end

		@coll.stubs(:conditions).returns('x2x2x2')
		assert_equal @coll.search_params, 'x2x2x2'
	end

	test "#== return false when search_params not equal" do
		coll = EsSearchable::SearchCollection.new(Foo)
		@coll.stubs(:search_params).returns(1)
		coll.stubs(:search_params).returns(2)
		assert_not_equal @coll, coll
	end

	test "#== return true when search_params equal" do
		coll = EsSearchable::SearchCollection.new(Foo)
		@coll.stubs(:search_params).returns(1)
		coll.stubs(:search_params).returns(1)
		assert_equal @coll, coll
	end

	test "#load_data call Foo::es_search" do
		conditions = {}
		@coll.stubs(:conditions).returns(conditions)
		assert_call Foo, :es_search, conditions, return_value: @full_response do
			@coll.send(:load_data)

			assert_equal @coll.time, 1
			assert_equal @coll.count, 2
			assert_equal @coll.response, @full_response
			assert_equal @coll.collections, [
				{"id"=>3, "name"=>"foo3"}, {"id"=>4, "name"=>"foo4"}
			]
		end
	end

	test "#load_data with select conditions" do
		Foo.stubs(:es_search).returns(@select_response)
		@coll.select(:id, :name).send(:load_data)
		
		assert_equal @coll.response, @select_response
		assert_equal @coll.collections, [
			{"id"=>3, "name"=>"foo3"}, {"id"=>4, "name"=>"foo4"}
		]
	end

	test "#conditions" do
		conditions = @coll.send(:conditions)
		assert_equal conditions, {}
		assert_equal conditions[:a], {}

		@coll.instance_variable_set '@conditions', 'xxx'
		assert_equal @coll.send(:conditions), 'xxx'
	end

	test "#set_filters" do
		type = :must
		filters = []
		assert_call @coll, :store_conditions, :filter, type, filters do
			@coll.send(:set_filters, filters, type)
		end
	end

	test "#set_queries" do
		type = :must
		queries = []
		assert_call @coll, :store_conditions, :query, type, queries do
			@coll.send(:set_queries, queries, type)
		end
	end

	test "#store_conditions return nil when conditions is blank?" do
		assert_nil @coll.send(:store_conditions, :filter, :must, nil)
		assert_nil @coll.send(:store_conditions, :filter, :must, [])
		assert_nil @coll.send(:store_conditions, :filter, :must, {})
		assert_nil @coll.send(:store_conditions, :filter, :must, '')
	end

	test "#store_conditions when conditions is empty" do
		conditions = @coll.send(:conditions)
		assert_not conditions[:query][:filtered].key(:filter)
		assert_not conditions[:query][:filtered][:filter][:bool].key(:must)

		assert_equal conditions[:query][:filtered][:filter][:bool][:must], {}
		@coll.send :store_conditions, :filter, :must, :conds

		conditions = @coll.send(:conditions)
		assert_equal conditions[:query][:filtered][:filter][:bool][:must], :conds
	end

	test "#store_conditions when conditions exists " do
		conditions = { query: {
			filtered: {
				filter: {
					bool: {
						must: [{
							terms: {:id=>[3, 4]}
						}]
					}
				}
			}
		}}

		@coll.instance_variable_set '@conditions', conditions
		@coll.send :store_conditions, :filter, :must, [{terms: {name: 'foo'}}]
		assert_equal conditions[:query][:filtered][:filter][:bool][:must], [
			{ terms: {:id=>[3, 4]} }, { terms: {name: 'foo'} }
		]
	end

	test "#parse_params return blank? array when params is blank" do
		assert_equal @coll.send(:parse_params, {}), []
	end

	test "#parse_params when params value is not Array or Hash" do
		assert_equal @coll.send(:parse_params, {name: 'foo'}), [{term: {name: 'foo'}}]

		assert_equal @coll.send(:parse_params, {name: 'foo', id: 1}), [
			{term: {name: 'foo'}}, 
			{term: {id: 1}}
		]
	end

	test "#parse_params when params value is Array" do
		assert_equal @coll.send(:parse_params, {id: [1, 2]}), [{terms: {id: [1, 2]}}]
	end

	test "#params when params value is Hash" do
		assert_equal @coll.send(:parse_params, {realname: {like:  { and: "zuozuo"} }}), [{
			query: {
				match: {
					realname: {
						operator: :and,
						query: "zuozuo"
					}
				}
			}
		}]
		assert_equal @coll.send(:parse_params, { id: {lt: 202, gt: 200 } }), [{
			range: {
				id: {
					lt: 202, gt: 200
				}
			}
		}]
		assert_equal @coll.send(:parse_params, { tel: 18510705036, or: {email: {like: 'edaixi.com'}, is_admin: true}}), [{
			term: {
				tel: 18510705036
			}
		}, {
			bool: {
				should: [{
					query: {
						match: {
							email: "edaixi.com"
						}
					}
				}, {
					term: {
						is_admin: true
					}
				}]
			}
		}]
	end
end
