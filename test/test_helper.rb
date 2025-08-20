ENV["RAILS_ENV"] ||= "test"

# Configure SimpleCov for code coverage analysis
require "simplecov"
require "simplecov-html"

SimpleCov.start "rails" do
  # Coverage configuration for atomic design architecture
  add_filter "/test/"
  add_filter "/config/"
  add_filter "/vendor/"
  add_filter "/bin/"
  add_filter "/db/"

  # Group coverage by atomic design levels
  add_group "Service Atoms", "app/services/atoms"
  add_group "Service Molecules", "app/services/molecules"
  add_group "Service Organisms", "app/services/organisms"
  add_group "Component Atoms", "app/components/atoms"
  add_group "Component Molecules", "app/components/molecules"
  add_group "Component Organisms", "app/components/organisms"
  add_group "Component Templates", "app/components/templates"
  add_group "Component Pages", "app/components/pages"
  add_group "Models", "app/models"
  add_group "Controllers", "app/controllers"
  add_group "Helpers", "app/helpers"
  add_group "Jobs", "app/jobs"
  add_group "Mailers", "app/mailers"

  # Set minimum coverage threshold (disabled during initial setup)
  # minimum_coverage 95

  # Configure formatters
  formatter SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter
  ])
end

require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"
require "factory_bot_rails"
require "shoulda/matchers"
require "timecop"
require "webmock/minitest"
require "vcr"

# Configure WebMock for HTTP request stubbing
WebMock.disable_net_connect!(allow_localhost: true)

# Configure VCR for recording HTTP interactions
VCR.configure do |config|
  config.cassette_library_dir = "test/vcr_cassettes"
  config.hook_into :webmock
  config.ignore_localhost = true
  config.default_cassette_options = {
    record: :once,
    match_requests_on: [ :method, :uri, :body ]
  }
end

# Configure Shoulda Matchers
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :minitest
    with.library :rails
  end
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Include FactoryBot methods
    include FactoryBot::Syntax::Methods

    # Setup and teardown for each test
    def setup
      super
      # Reset time to current time before each test
      Timecop.return
      # Clear any mocks from previous tests
      Mocha::Mockery.instance.teardown if Mocha::Mockery.instance.stubba
    end

    def teardown
      super
      # Ensure time is reset after each test
      Timecop.return
      # Clear WebMock stubs
      WebMock.reset!
    end

    # Helper methods for atomic design testing

    # Create a mock atom service
    def mock_atom_service(service_class, method_name, return_value)
      mock_service = mock
      mock_service.expects(method_name).returns(return_value)
      service_class.expects(:new).returns(mock_service)
      mock_service
    end

    # Create a stub for external API calls
    def stub_external_api(url, response_body, status: 200)
      stub_request(:get, url)
        .to_return(status: status, body: response_body, headers: { "Content-Type" => "application/json" })
    end

    # Time travel helper for testing time-dependent functionality
    def travel_to_time(time, &block)
      Timecop.travel(time, &block)
    end

    # Performance testing helper
    def assert_performance(max_time_seconds = 1.0)
      start_time = Time.current
      yield
      end_time = Time.current
      execution_time = end_time - start_time

      assert execution_time <= max_time_seconds,
        "Expected execution time to be <= #{max_time_seconds}s, but was #{execution_time}s"
    end

    # Memory usage testing helper
    def assert_memory_usage(max_mb = 50)
      GC.start
      memory_before = `ps -o rss= -p #{Process.pid}`.to_i

      yield

      GC.start
      memory_after = `ps -o rss= -p #{Process.pid}`.to_i
      memory_used_mb = (memory_after - memory_before) / 1024.0

      assert memory_used_mb <= max_mb,
        "Expected memory usage to be <= #{max_mb}MB, but was #{memory_used_mb}MB"
    end

    # Database query counting helper
    def assert_queries(expected_count)
      query_count = 0
      callback = lambda { |*| query_count += 1 }

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        yield
      end

      assert_equal expected_count, query_count,
        "Expected #{expected_count} database queries, but #{query_count} were executed"
    end

    # Authentication testing helpers

    # Helper method to create valid users with strong passwords
    def create_valid_user(attributes = {})
      default_attributes = {
        email: "test#{SecureRandom.hex(4)}@example.com",
        password: "Password123",
        password_confirmation: "Password123",
        first_name: "Test",
        last_name: "User"
      }
      User.create!(default_attributes.merge(attributes))
    end

    def build_valid_user(attributes = {})
      default_attributes = {
        email: "test#{SecureRandom.hex(4)}@example.com",
        password: "Password123",
        password_confirmation: "Password123",
        first_name: "Test",
        last_name: "User"
      }
      User.new(default_attributes.merge(attributes))
    end
  end
end
