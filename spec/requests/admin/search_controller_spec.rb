require "rails_helper"

RSpec.describe Admin::SearchController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  before { sign_in_as_admin }

  describe "#index" do
    it "renders the search page" do
      get admin_search_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Find a teacher or application")
    end

    context "when searching by teacher details" do
      let(:teacher) { create(:teacher, full_name: "Jane Search", email: "jane.search@example.com", trn: "1234567") }

      before do
        create(:application, teacher:)
        create(:application, teacher:, course: create(:course, identifier: "another-course"))
        get admin_search_path, params: { q: teacher.email }
      end

      it "groups the teacher's applications by teacher" do
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Teachers (1)")
        expect(response.body).to include("Applications (2)")
        expect(response.body).to include("Jane Search")
        expect(response.body).to include("1234567")
        expect(response.body).to include(admin_teacher_path(teacher))
      end
    end

    context "when searching by teacher ID" do
      let(:teacher) { create(:teacher, :with_one_login_id, full_name: "Found Teacher") }
      let!(:application) { create(:application, teacher:) }

      before do
        get admin_search_path, params: { q: "\t#{teacher.ecf_id}", status: "" }
      end

      it "shows the applications for the matching teacher" do
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Teachers (1)")
        expect(response.body).to include("Applications (1)")
        expect(response.body).to include("Found Teacher")
        expect(response.body).to include(admin_teacher_path(teacher))
        expect(response.body).to include(admin_application_path(application))
      end
    end

    context "when the search query has leading whitespace and non-ascii characters" do
      let(:teacher) { create(:teacher, full_name: "Jane Search", email: "jane.search@example.com") }

      before do
        create(:application, teacher:)
        get admin_search_path, params: { q: " \u201C#{teacher.email}\u201D " }
      end

      it "searches using the cleaned query" do
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Jane Search")
        expect(response.body).to include(admin_teacher_path(teacher))
      end
    end

    context "when searching by application details" do
      let!(:application) { create(:application) }

      before { get admin_search_path, params: { q: application.ecf_id } }

      it "shows the matching application" do
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Teachers (1)")
        expect(response.body).to include("Applications (1)")
        expect(response.body).to include(application.teacher.full_name)
        expect(response.body).to include(application.teacher.trn)
        expect(response.body).to include(admin_teacher_path(application.teacher))
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

    context "when paginating teacher results" do
      before do
        21.times { |index| create(:teacher, email: "search-user-#{index}@example.com") }
        get admin_search_path, params: { q: "example.com" }
      end

      it "keeps the teachers tab selected when following pagination links" do
        expect(response.body).to include("teachers_page=2")
        expect(response.body).to include("tab=teachers")

        get admin_search_path, params: { q: "example.com", teachers_page: 2, tab: "teachers" }

        expect(response.body.index("Teachers (21)")).to be < response.body.index("Applications (0)")
      end
    end
  end
end
