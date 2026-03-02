# frozen_string_literal: true

require "rails_helper"

RSpec.describe Applications::ChangeCohort, type: :service do
  subject(:service) { described_class.new(application:, new_cohort:) }

  let(:cohort_2021) { create(:cohort, start_year: 2021) }
  let(:new_cohort) { create(:cohort, start_year: 2025) }
  let(:application) { create(:application, cohort: cohort_2021) }

  before { subject.call }

  let(:error_message_path) { "activemodel.errors.models.applications/change_cohort.attributes.base" }

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
      let(:application) { create(:application, :with_declaration, cohort: cohort_2021, schedule: create(:schedule, :tte_reception_autumn, cohort: cohort_2021)) }

      before { create(:schedule, :tte_reception_autumn, cohort: new_cohort) }

      it do
        expect(subject).not_to be_valid
        expect(subject).to have_error(:base, I18n.t("#{error_message_path}.declarations_present"))
      end

      context "when override_declarations_check is true" do
        subject(:service) { described_class.new(application:, new_cohort:, override_declarations_check: true) }

        it { is_expected.to be_valid }
      end
    end

    context "when the application has a schedule" do
      let(:application) { create(:application, cohort: cohort_2021, schedule: create(:schedule, :tte_reception_autumn, cohort: cohort_2021)) }

      context "when the new cohort has a schedule for the course group" do
        before { create(:schedule, :tte_reception_autumn, cohort: new_cohort) }

        it { is_expected.to be_valid }
      end

      context "when the new cohort does not have a schedule for the course group" do
        it do
          expect(subject).not_to be_valid
          expect(subject).to have_error(:base, I18n.t("#{error_message_path}.schedule_not_found"))
        end
      end
    end
  end
end
