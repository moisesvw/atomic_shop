require "test_helper"
require "capybara/cuprite"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Use cuprite driver which is a headless Chrome driver that doesn't rely on
  # Selenium's automatic driver download mechanism
  Capybara.register_driver(:cuprite) do |app|
    Capybara::Cuprite::Driver.new(app, window_size: [ 1400, 1400 ])
  end

  driven_by :cuprite
end
