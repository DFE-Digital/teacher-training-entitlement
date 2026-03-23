module RenderedHtmlAccessibilityHelper
  include Capybara::DSL

  def check_accessibility_of_html(html)
    html_app = lambda do |env|
      if env["PATH_INFO"] == "/accessibility-test"
        [200, { "Content-Type" => "text/html" }, [html]]
      else
        Rails.application.call(env)
      end
    end

    original_app = Capybara.app
    Capybara.app = html_app

    begin
      visit "/accessibility-test"
      expect(page).to be_axe_clean
    ensure
      Capybara.app = original_app
    end
  end
end
