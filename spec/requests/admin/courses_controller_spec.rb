require "rails_helper"

RSpec.describe Admin::CoursesController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  context "when signed in as admin" do
    before { sign_in_as_admin }

    describe "GET /admin/courses" do
      subject do
        get admin_courses_path
        response
      end

      it { is_expected.to have_http_status(:ok) }
    end

    describe "GET /admin/courses/{id}" do
      let(:course_id) { create(:course).id }

      subject do
        get admin_course_path(course_id)
        response
      end

      it { is_expected.to have_http_status(:ok) }

      context "when the course cannot be found", :exceptions_app do
        let(:course_id) { -1 }

        it { is_expected.to have_http_status(:not_found) }
      end
    end

    describe "GET /admin/courses/{id}/edit" do
      let(:course) { create(:course) }

      subject do
        get edit_admin_course_path(course)
        response
      end

      it { is_expected.to redirect_to(sign_in_path) }
    end

    describe "PATCH /admin/courses/{id}" do
      let(:course) { create(:course) }

      subject do
        patch admin_course_path(course), params: { course: { name: "Updated" } }
        response
      end

      it { is_expected.to redirect_to(sign_in_path) }
    end
  end

  context "when signed in as super admin" do
    before { sign_in_as_admin(super_admin: true) }

    describe "GET /admin/courses/{id}/edit" do
      let(:course) { create(:course) }

      subject do
        get edit_admin_course_path(course)
        response
      end

      it { is_expected.to have_http_status(:ok) }
    end

    describe "PATCH /admin/courses/{id}" do
      let(:course) { create(:course) }

      subject do
        patch admin_course_path(course), params: { course: { name: "Updated" } }
        response
      end

      it { is_expected.to redirect_to(admin_course_path(course)) }

      it "updates the course" do
        subject
        expect(course.reload.name).to eq("Updated")
      end
    end
  end

  describe "/admin/courses/:id" do
    subject do
      get admin_course_path(create(:course))
      response
    end

    it { is_expected.to have_http_status(:ok) }
  end
end
