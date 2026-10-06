require "rails_helper"

RSpec.describe Admin::SearchController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  before { sign_in_as_admin }

  describe "#index" do
    it "renders the search page" do
      get admin_search_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Find a user or application")
    end

    context "when searching by user details" do
      let(:user) { create(:user, full_name: "Jane Search", email: "jane.search@example.com", trn: "1234567") }

      before do
        create(:application, user:)
        create(:application, user:, course: create(:course, identifier: "another-course"))
        get admin_search_path, params: { q: user.email }
      end

      it "groups the user's applications by user" do
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Users (1)")
        expect(response.body).to include("Applications (2)")
        expect(response.body).to include("Jane Search")
        expect(response.body).to include("1234567")
        expect(response.body).to include(admin_user_path(user))
      end
    end

    context "when searching by user ID" do
      let(:user) { create(:user, :with_one_login_id, full_name: "Found User") }
      let!(:application) { create(:application, user:) }

      before do
        get admin_search_path, params: { q: "\t#{user.ecf_id}", status: "" }
      end

      it "shows the applications for the matching user" do
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Users (1)")
        expect(response.body).to include("Applications (1)")
        expect(response.body).to include("Found User")
        expect(response.body).to include(admin_user_path(user))
        expect(response.body).to include(admin_application_path(application))
      end
    end

    context "when the search query has leading whitespace and non-ascii characters" do
      let(:user) { create(:user, full_name: "Jane Search", email: "jane.search@example.com") }

      before do
        create(:application, user:)
        get admin_search_path, params: { q: " \u201C#{user.email}\u201D " }
      end

      it "searches using the cleaned query" do
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Jane Search")
        expect(response.body).to include(admin_user_path(user))
      end
    end

    context "when searching by application details" do
      let!(:application) { create(:application) }

      before { get admin_search_path, params: { q: application.ecf_id } }

      it "shows the matching application" do
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Users (1)")
        expect(response.body).to include("Applications (1)")
        expect(response.body).to include(application.user.full_name)
        expect(response.body).to include(application.user.trn)
        expect(response.body).to include(admin_user_path(application.user))
        expect(response.body).to include(admin_application_path(application))
      end
    end

    context "when filtering applications" do
      let!(:pending_application) { create(:application, :pending) }
      let!(:accepted_application) { create(:application, :accepted) }

      before { get admin_search_path, params: { status: Application::ACCEPTED } }

      it "only shows applications matching the filter" do
        expect(response).to have_http_status(:success)
        expect(response.body).to include(admin_application_path(accepted_application))
        expect(response.body).not_to include(admin_application_path(pending_application))
      end
    end

    context "when paginating user results" do
      before do
        21.times { |index| create(:user, email: "search-user-#{index}@example.com") }
        get admin_search_path, params: { q: "example.com" }
      end

      it "keeps the users tab selected when following pagination links" do
        expect(response.body).to include("users_page=2")
        expect(response.body).to include("tab=users")

        get admin_search_path, params: { q: "example.com", users_page: 2, tab: "users" }

        expect(response.body.index("Users (21)")).to be < response.body.index("Applications (0)")
      end
    end
  end
end
