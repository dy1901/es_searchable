require 'pry'
require 'es_searchable'
require 'minitest/autorun'
require 'minitest/pride'
require 'minitest/mock'
require 'mocha/mini_test'
require 'active_support/all'

# Filter out Minitest backtrace while allowing backtrace from other libraries
# to be shown.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

ActiveSupport::TestCase.test_order = :random

class ActiveSupport::TestCase
	def assert_call obj, method, *args, &blk
		return_value = if args.last && args.last.is_a?(Hash) && args.last.key?(:return_value)
										 args.pop[:return_value]
									 end

		mock = MiniTest::Mock.new
		mock.expect(:call, return_value, args)

		obj.stub(method, mock, &blk)
		mock.verify
	end

end
