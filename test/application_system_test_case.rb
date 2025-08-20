require "test_helper"
require "capybara/cuprite"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Use cuprite driver which is a headless Chrome driver that doesn't rely on
  # Selenium's automatic driver download mechanism
  Capybara.register_driver(:cuprite) do |app|
    options = {
      window_size: [ 1400, 1400 ],
      # Increase timeout for CI environments
      process_timeout: 30,
      # Add Chrome options for better CI compatibility
      browser_options: {
        'no-sandbox': nil,
        'disable-gpu': nil,
        'disable-dev-shm-usage': nil,
        'disable-web-security': nil,
        'disable-features=VizDisplayCompositor': nil
      }
    }

    # Add headless mode for CI
    if ENV['CI'] || ENV['HEADLESS']
      options[:browser_options]['headless'] = nil
    end

    Capybara::Cuprite::Driver.new(app, **options)
  end

  driven_by :cuprite

  # Increase default wait times for CI environments
  setup do
    if ENV['CI']
      Capybara.default_max_wait_time = 10
      Capybara.server_host = '127.0.0.1'
      Capybara.server_port = 3001
    end
  end
end
