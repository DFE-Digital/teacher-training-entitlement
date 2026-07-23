require "rails_helper"

RSpec.describe Admin::CourseCohortMilestonesController, type: :request do
  include Helpers::NPQSeparationAdminLogin

  subject { response }

  let(:cohort) { create(:cohort, registration_starts_at: Date.new(2026, 4, 1), registration_ends_at: Date.new(2026, 6, 30)) }
  let(:course_cohort) { create(:course_cohort, cohort:) }
  let(:course) { course_cohort.course }
  let(:milestone) { create(:milestone, course_cohort:, declaration_type: "started") }
  let(:valid_create_params) do
    {
      form: {
        declaration_type: "started",
        "acceptance_window_start_date(1i)": "2026",
        "acceptance_window_start_date(2i)": "1",
        "acceptance_window_start_date(3i)": "1",
        "acceptance_window_end_date(1i)": "2026",
        "acceptance_window_end_date(2i)": "1",
        "acceptance_window_end_date(3i)": "31",
        payment_amount: "123.45",
      },
    }
  end
  let(:valid_update_params) do
    {
      form: valid_create_params.fetch(:form),
    }
  end

  context "when logged in as super admin" do
    before { sign_in_as_admin(super_admin: true) }

    describe "#new" do
      before { get new_admin_cohort_course_milestone_path(cohort, course) }

      it { is_expected.to have_http_status :success }

      it "pre-fills acceptance window dates from the cohort registration dates" do
        html = Nokogiri::HTML(response.body)

        expect(html.at_css('input[name="form[acceptance_window_start_date(3i)]"]')["value"]).to eq("1")
        expect(html.at_css('input[name="form[acceptance_window_start_date(2i)]"]')["value"]).to eq("4")
        expect(html.at_css('input[name="form[acceptance_window_start_date(1i)]"]')["value"]).to eq("2026")
        expect(html.at_css('input[name="form[acceptance_window_end_date(3i)]"]')["value"]).to eq("30")
        expect(html.at_css('input[name="form[acceptance_window_end_date(2i)]"]')["value"]).to eq("6")
        expect(html.at_css('input[name="form[acceptance_window_end_date(1i)]"]')["value"]).to eq("2026")
      end

      it "disables declaration types already used by another milestone on the course cohort" do
        create(:milestone, course_cohort:, declaration_type: "started")

        get new_admin_cohort_course_milestone_path(cohort, course)

        html = Nokogiri::HTML(response.body)
        started_radio = html.at_css('input[name="form[declaration_type]"][value="started"]')
        completed_radio = html.at_css('input[name="form[declaration_type]"][value="completed"]')

        expect(started_radio["disabled"]).to eq("disabled")
        expect(completed_radio["disabled"]).to be_nil
        expect(response.body).to include("Already added")
      end
    end

    describe "#create" do
      it "creates a milestone" do
        expect { post admin_cohort_course_milestones_path(cohort, course), params: valid_create_params }
          .to change(Milestone, :count).by(1)

        expect(response).to redirect_to admin_cohort_course_path(cohort, course)
        expect(Milestone.last).to have_attributes(
          course_cohort:,
          declaration_type: "started",
          acceptance_window_start_date: Date.new(2026, 1, 1),
          acceptance_window_end_date: Date.new(2026, 1, 31),
          payment_amount: BigDecimal("123.45"),
        )
      end

      context "when the params are invalid" do
        before do
          post admin_cohort_course_milestones_path(cohort, course), params: {
            form: valid_create_params[:form].except(:declaration_type),
          }
        end

        it { is_expected.to have_http_status :unprocessable_content }
      end
    end

    describe "#edit" do
      before { get edit_admin_cohort_course_milestone_path(cohort, course, milestone) }

      it { is_expected.to have_http_status :success }

      it "does not disable the milestone's current declaration type" do
        create(:milestone, course_cohort:, declaration_type: "completed")

        get edit_admin_cohort_course_milestone_path(cohort, course, milestone)

        html = Nokogiri::HTML(response.body)
        started_radio = html.at_css('input[name="form[declaration_type]"][value="started"]')
        completed_radio = html.at_css('input[name="form[declaration_type]"][value="completed"]')

        expect(started_radio["disabled"]).to be_nil
        expect(completed_radio["disabled"]).to eq("disabled")
      end
    end

    describe "#update" do
      it "updates a milestone" do
        patch admin_cohort_course_milestone_path(cohort, course, milestone), params: {
          form: valid_update_params[:form].merge(declaration_type: "completed"),
        }

        expect(response).to redirect_to admin_cohort_course_path(cohort, course)
        expect(milestone.reload).to have_attributes(
          declaration_type: "completed",
          acceptance_window_start_date: Date.new(2026, 1, 1),
          acceptance_window_end_date: Date.new(2026, 1, 31),
          payment_amount: BigDecimal("123.45"),
        )
      end

      context "when the params are invalid" do
        before do
          patch admin_cohort_course_milestone_path(cohort, course, milestone), params: {
            form: valid_update_params[:form].merge(declaration_type: ""),
          }
        end

        it { is_expected.to have_http_status :unprocessable_content }
      end
    end
  end

  context "when logged in as normal admin" do
    before { sign_in_as_admin }

    describe "#new" do
      before { get new_admin_cohort_course_milestone_path(cohort, course) }

      it { is_expected.to redirect_to admin_cohort_course_path(cohort, course) }
    end

    describe "#create" do
      before { post admin_cohort_course_milestones_path(cohort, course), params: valid_create_params }

      it { is_expected.to redirect_to admin_cohort_course_path(cohort, course) }
    end

    describe "#edit" do
      before { get edit_admin_cohort_course_milestone_path(cohort, course, milestone) }

      it { is_expected.to redirect_to admin_cohort_course_path(cohort, course) }
    end

    describe "#update" do
      before { patch admin_cohort_course_milestone_path(cohort, course, milestone), params: valid_update_params }

      it { is_expected.to redirect_to admin_cohort_course_path(cohort, course) }
    end
  end

  context "when not logged in" do
    describe "#new" do
      before { get new_admin_cohort_course_milestone_path(cohort, course) }

      it { is_expected.to redirect_to sign_in_path }
    end

    describe "#create" do
      before { post admin_cohort_course_milestones_path(cohort, course), params: valid_create_params }

      it { is_expected.to redirect_to sign_in_path }
    end

    describe "#edit" do
      before { get edit_admin_cohort_course_milestone_path(cohort, course, milestone) }

      it { is_expected.to redirect_to sign_in_path }
    end

    describe "#update" do
      before { patch admin_cohort_course_milestone_path(cohort, course, milestone), params: valid_update_params }

      it { is_expected.to redirect_to sign_in_path }
    end
  end
end
