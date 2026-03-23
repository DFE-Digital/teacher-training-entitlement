require "selenium-webdriver"

Capybara.register_driver :selenium_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless=new")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

RSpec.configure do |config|
  config.before(:all, :axe) do
    Capybara.reset_sessions!
    Capybara.current_driver = :selenium_headless
  end

  config.after(:all, :axe) do
    Capybara.reset_sessions!
    Capybara.current_driver = :cuprite
  end
end
