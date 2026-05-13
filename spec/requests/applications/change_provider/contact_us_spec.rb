require "rails_helper"

RSpec.describe "Applications::ChangeProvider::ContactUs", type: :request do
  let(:application) { create(:application, :pending) }
  let(:user) { application.user }
  let(:url) { "/applications/#{application.ecf_id}/change-provider/contact-us" }

  before do
    allow_any_instance_of(ApplicationController)
      .to receive(:session)
      .and_return({ user_id: user.id })
  end

  describe "GET /applications/:application_id/change-provider/contact-us" do
    it "renders the index template" do
      get url
      expect(response).to render_template(:index)
    end
  end
end
