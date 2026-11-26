require "selenium-webdriver"
require "capybara/selenium/driver_specializations/chrome_driver"

# Capybara's Chrome reset uses Storage.clearDataForOrigin with origin "*".
# Recent Chrome versions reject that as an invalid URL, so use Selenium's
# standard reset, which clears cookies and storage for the current origin.
module Capybara::Selenium::Driver::ChromeDriver
  def reset!
    Capybara::Selenium::Driver.instance_method(:reset!).bind(self).call
  end
end

Capybara.register_driver :selenium_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless=new")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

RSpec.shared_context "with axe driver" do
  around do |example|
    Capybara.current_driver = :selenium_headless
    example.run
  ensure
    Capybara.current_driver = Capybara.default_driver
  end
end

RSpec.configure do |config|
  config.include_context "with axe driver", :axe
end
