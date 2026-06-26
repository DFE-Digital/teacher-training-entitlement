# frozen_string_literal: true

require "rails_helper"

RSpec.describe Applications::ChangeCohort, type: :service do
  let(:override_declarations_check) { false }
  let(:error_message_path) { "activemodel.errors.models.applications/change_cohort.attributes.base" }
  let(:current_cohort) { create(:cohort, start_year: 2025) }
  let(:new_cohort) { current_cohort }
  let(:application) { create(:application, cohort: current_cohort) }

  subject(:service) { described_class.new(application:, new_cohort:, override_declarations_check:) }

  before do
    subject.call
  end

  describe "validation" do
    context "when the new cohort start_year is the same" do
      let(:new_cohort) { create(:cohort, start_year: 2025) }

      it do
        expect(subject).not_to be_valid
        expect(subject).to have_error(:base, I18n.t("#{error_message_path}.must_be_different"))
      end
    end

    context "when the new cohort start_year is different" do
      let(:new_cohort) { create(:cohort, start_year: 2026) }

      it do
        expect(subject.errors).to be_blank
      end
    end

    context "when the application has declarations" do
      let(:new_cohort) { create(:cohort, start_year: 2026) }
      let(:application) { create(:application, :with_declaration, cohort: current_cohort) }

      it do
        expect(subject).not_to be_valid
        expect(subject).to have_error(:base, I18n.t("#{error_message_path}.declarations_present"))
      end

      context "when override_declarations_check is true" do
        let(:override_declarations_check) { true }

        it do
          expect(application.reload.cohort).to eq(new_cohort)
        end
      end
    end
  end
end
