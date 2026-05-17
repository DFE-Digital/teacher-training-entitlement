require "rails_helper"

RSpec.describe "Reception registration development login", type: :request do
  before do
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("development"))
  end

  let(:user) { create(:user, email: "ben.keeping@education.gov.uk") }

  it "signs in the requested user and redirects to the requested reception registration step" do
    get "/development_login", params: { step: "course-start-date", user_email: user.email }

    expect(session["user_id"]).to eq(user.id)
    expect(response).to redirect_to(reception_registration_path("course-start-date"))
  end

  it "defaults to the course start date step" do
    get "/development_login", params: { user_email: user.email }

    expect(response).to redirect_to(reception_registration_path("course-start-date"))
  end
end
