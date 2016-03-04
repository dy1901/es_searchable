# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../../test/dummy/config/environment.rb",  __FILE__)
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../../test/dummy/db/migrate", __FILE__)]
require "rails/test_help"
require 'minitest/mock'
require 'pry'
require "mocha/mini_test"

# Filter out Minitest backtrace while allowing backtrace from other libraries
# to be shown.
Minitest.backtrace_filter = Minitest::BacktraceFilter.new

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = File.expand_path("../fixtures", __FILE__)
  ActionDispatch::IntegrationTest.fixture_path = ActiveSupport::TestCase.fixture_path
  ActiveSupport::TestCase.fixtures :all
end

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

