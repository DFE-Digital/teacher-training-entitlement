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

      it { is_expected.to redirect_to(admin_courses_path) }

      it "updates the course" do
        subject
        expect(course.reload.name).to eq("Updated")
      end
    end
  end
end
