require "selenium-webdriver"

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
    Capybara.current_driver = :cuprite
  end
end

RSpec.configure do |config|
  config.include_context "with axe driver", :axe
end
