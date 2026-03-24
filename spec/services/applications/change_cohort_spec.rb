# frozen_string_literal: true

require "rails_helper"

RSpec.describe Applications::ChangeCohort, type: :service do
  subject(:service) { described_class.new(application:, new_cohort:) }

  let(:cohort_2021) { create(:cohort, start_year: 2021) }
  let(:course_cohort) { create(:course_cohort, cohort: cohort_2021) }
  let(:error_message_path) { "activemodel.errors.models.applications/change_cohort.attributes.base" }
  let(:new_cohort) { create(:cohort, start_year: 2025) }
  let(:new_course_cohort) { create(:course_cohort, cohort: new_cohort) }
  let(:application) { create(:application, course_cohort:) }

  before { subject.call }

  describe "validation" do
    context "when the new cohort start_year is different to the current cohort start year" do
      let(:new_cohort) { application.cohort }

      it do
        expect(subject).not_to be_valid
        expect(subject).to have_error(:base, I18n.t("#{error_message_path}.must_be_different"))
      end
    end

    context "when the new cohort start_year is different" do
      it do
        expect(subject.errors).to be_blank
      end
    end

    context "when the application has declarations" do
      let(:application) { create(:application, :with_declaration, course_cohort:) }

      it do
        expect(subject).not_to be_valid
        expect(subject).to have_error(:base, I18n.t("#{error_message_path}.declarations_present"))
      end

      context "when override_declarations_check is true" do
        subject(:service) { described_class.new(application:, new_cohort:, override_declarations_check: true) }

        before { application.course_cohort = course_cohort }

        it { is_expected.to be_valid }
      end
    end
  end
end
