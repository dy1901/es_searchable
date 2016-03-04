require 'test_helper'

class EsSearchableTest < ActiveSupport::TestCase
	setup do
	  class Foo
			include EsSearchable
		end
	end

	test "self.es_collection" do
		assert_kind_of EsSearchable::SearchCollection, Foo.es_collection
	end

	test "self.handle_es_response" do
		assert_equal Foo.handle_es_response('xxxx'), 'xxxx'
	end

	test "self.client" do
		client = Foo.client
		assert_kind_of Elasticsearch::Transport::Client, Foo.client

		transport = client.transport
		assert_equal transport.max_retries, EsSearchable.retry_on_failure
		assert_kind_of Logger, transport.logger
		assert_equal transport.options[:reload_on_failure], EsSearchable.reload_on_failure
		assert_equal transport.options[:hosts], EsSearchable.hosts
	end

	test "self.es_search" do
		Foo.client.stubs(:search).returns('search_result')
		assert_equal Foo.es_search({}), 'search_result'
	end

	test "self.es_index" do
		Foo.es_index 'index'
		assert_equal Foo.instance_variable_get(:@index), 'index'

		Foo.es_index nil
	end

	test 'self.index returns the default index' do
		assert_equal Foo.index, 'foos'
	end

	test 'self.index returns index setted by self.es_index method' do
		Foo.es_index 'index'
		assert_equal Foo.index, 'index'
		Foo.es_index nil
	end

	test "delegate SearchMethods to es_collection" do
		EsSearchable::SearchMethods.each do |method|
			assert Foo.respond_to?("es_#{method}")
			assert_equal Foo.send("es_#{method}", {id: 1}).search_params,
				Foo.es_collection.send(method, {id: 1}).search_params
		end
	end
end
