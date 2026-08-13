require "rails_helper"

RSpec.describe RegistrationWizard do
  subject { described_class.new(current_step:, store:, request:, current_user: user) }

  let(:store) { {} }
  let(:session) { {} }
  let(:request) { ActionController::TestRequest.new({}, session, ApplicationController) }
  let(:user) { create(:user) }
  let(:current_step) { "share_provider" }

  before { create(:course, :npd_eirt) }

  describe "#current_step" do
    it "returns current step" do
      expect(subject.current_step).to be(:share_provider)
    end

    context "when invalid step" do
      subject { described_class.new(current_step: "i_do_not_exist", store:, request:, current_user: user) }

      it "raises an error" do
        expect {
          subject.current_step
        }.to raise_error(RegistrationWizard::InvalidStep)
      end
    end
  end

  describe "#answers" do
    let(:school) { create(:school, establishment_type_code: "1") }

    context "when work setting has not been answered" do
      let(:lead_provider) { create(:lead_provider) }
      let(:store) do
        {
          "course_identifier" => "tte-early-years",
          "lead_provider_id" => lead_provider.id,
          "teacher_catchment" => "another",
          "funding" => "self",
        }
      end

      it "does not show work setting answers" do
        expect(subject.answers.map(&:key)).not_to include("Work setting", "Workplace")
      end
    end

    context "when working in Local authority maintained nursery" do
      let(:store) do
        {
          "chosen_provider" => "yes",
          "teacher_catchment" => "england",
          "teacher_catchment_country" => "",
          "works_in_school" => "no",
          "trn_knowledge" => "yes",
          "trn" => "123456",
          "full_name" => "Maia Mack",
          "date_of_birth" => 30.years.ago,
          "national_insurance_number" => "123420",
          "works_in_childcare" => "yes",
          "work_setting" => "early_years_or_childcare",
          "kind_of_nursery" => "local_authority_maintained_nursery",
          "institution_name" => "",
          "institution_id" => school.institution.id,
          "course_identifier" => "tte-early-years",
          "lead_provider_id" => LeadProvider.all.sample.id,
          "funding" => "self",
          "referred_by_return_to_teaching_adviser" => "no",
        }
      end

      it "does not show Ofsted registration details" do
        expect(subject.answers.map(&:key)).not_to include("Ofsted registration details")
      end
    end

    context "when working in private nursery" do
      let(:private_childcare_provider) { create(:private_childcare_provider) }
      let(:store) do
        {
          "chosen_provider" => "yes",
          "course_identifier" => "tte-early-years",
          "date_of_birth" => 30.years.ago,
          "full_name" => "Tatyana Christensen",
          "has_ofsted_urn" => has_ofsted_urn,
          "institution_id" => institution_id,
          "institution_name" => "",
          "kind_of_nursery" => "private_nursery",
          "lead_provider_id" => LeadProvider.all.sample.id,
          "national_insurance_number" => "123420",
          "teacher_catchment" => "england",
          "teacher_catchment_country" => "",
          "trn" => "123456",
          "trn_knowledge" => "yes",
          "works_in_childcare" => "yes",
          "works_in_school" => "no",
          "referred_by_return_to_teaching_adviser" => "no",
        }
      end

      context "without urn" do
        let(:has_ofsted_urn) { "no" }
        let(:institution_id) { nil }

        it "does not show Ofsted registration details" do
          expect(subject.answers.map(&:key)).not_to include("Ofsted registration details")
        end

        it "does not show Nursery" do
          expect(subject.answers.map(&:key)).not_to include("Nursery")
        end
      end

      context "with urn" do
        let(:has_ofsted_urn) { "yes" }
        let(:institution_id) { private_childcare_provider.institution.id }

        it "does not show Do you have a URN?" do
          expect(subject.answers.map(&:key)).not_to include("Do you have a URN?")
        end

        it "does not show Nursery" do
          expect(subject.answers.map(&:key)).not_to include("Nursery")
        end
      end
    end
  end
end
