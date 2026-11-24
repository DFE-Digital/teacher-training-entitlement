require "rails_helper"

RSpec.describe Admin::TeachersController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  before { sign_in_as_admin }

  describe "/admin/teachers/{id}" do
    let(:teacher_id) { create(:teacher).ecf_id }

    subject do
      get admin_teacher_path(teacher_id)
      response
    end

    it { is_expected.to have_http_status(:ok) }

    context "when the teacher cannot be found", :exceptions_app do
      let(:teacher_id) { SecureRandom.uuid }

      it { is_expected.to have_http_status(:not_found) }
    end
  end
end
