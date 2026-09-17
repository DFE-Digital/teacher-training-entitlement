require "rails_helper"

RSpec.describe "shared/analytics/_google.html.erb", type: :view do
  around do |example|
    original_google_analytics_id = Rails.configuration.x.google_analytics_id
    Rails.configuration.x.google_analytics_id = "G-TEST"

    example.run
  ensure
    Rails.configuration.x.google_analytics_id = original_google_analytics_id
  end

  it "loads Google Analytics" do
    allow(view).to receive(:cookies).and_return({ "consented-to-cookies" => "accept" })

    render partial: "shared/analytics/google"

    expect(rendered).to include("https://www.googletagmanager.com/gtag/js?id=G-TEST")
    expect(rendered).to include("gtag('config', 'G-TEST');")
  end

  it "renders queued Google Analytics events and clears them from the session" do
    queued_events = [
      {
        event_name: :one_login_completed,
        params: {
          page_path: "/users/auth/teacher_auth/callback",
        },
      },
    ]
    session = { google_analytics_events: queued_events }

    allow(view).to receive(:cookies).and_return({ "consented-to-cookies" => "accept" })
    allow(view).to receive(:session).and_return(session)

    render partial: "shared/analytics/google"

    expect(rendered).to include('gtag("event", "one_login_completed", {"page_path":"/users/auth/teacher_auth/callback"});')
    expect(session).not_to have_key(:google_analytics_events)
  end
end
