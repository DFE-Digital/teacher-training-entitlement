require "rails_helper"

RSpec.describe Institutions::BackfillFromDelegated do
  subject(:backfill) { described_class.new.call }

  let!(:school) do
    create(:school, establishment_type_code: "1", establishment_status_code: "1", la_code: "201",
                    la_name: "City", number_of_pupils: 10, ukprn: "10000001", high_pupil_premium: true)
  end
  let!(:further_education) { create(:school, establishment_type_code: "18", establishment_status_code: "2") }
  let!(:hospital_school) { create(:school, establishment_type_code: "99", establishment_status_code: "3", name: "Hospital School") }
  let!(:local_authority) { create(:local_authority, high_pupil_premium: true) }
  let!(:provider) do
    create(:private_childcare_provider, local_authority: "Leeds", early_years_individual_registers: %w[EYR],
                                        provider_early_years_register_flag: true)
  end
  let!(:disabled_provider) { create(:private_childcare_provider, :disabled) }

  before do
    Institution.update_all(institution_type: Institution::STATE_FUNDED, open: nil, ukprn: nil, high_pupil_premium: false)
  end

  it "does not change the number of institutions" do
    expect { backfill }.not_to change(Institution, :count)
  end

  it "leaves the delegated references untouched" do
    expect { backfill }.not_to(change { Institution.order(:id).pluck(:institutionable_type, :institutionable_id) })
  end

  describe "folded school columns" do
    before { backfill }

    it "copies the delegated values" do
      expect(school.institution.reload).to have_attributes(
        establishment_type_code: "1", la_code: "201", la_name: "City", number_of_pupils: 10,
        ukprn: "10000001", high_pupil_premium: true, phase_name: school.phase_name
      )
    end
  end

  describe "folded private childcare provider columns" do
    before { backfill }

    it "copies the delegated values" do
      expect(provider.institution.reload).to have_attributes(
        local_authority_name: "Leeds", early_years_individual_registers: %w[EYR],
        provider_early_years_register_flag: true
      )
    end

    it "includes disabled providers" do
      expect(disabled_provider.institution.reload.disabled_at).to be_present
    end
  end

  describe "folded local authority columns" do
    it "copies high_pupil_premium" do
      backfill

      expect(local_authority.institution.reload.high_pupil_premium).to be(true)
    end
  end

  describe "institution_type" do
    before { backfill }

    it { expect(school.institution.reload).to be_institution_type_state_funded }
    it { expect(further_education.institution.reload).to be_institution_type_further_education }
    it { expect(hospital_school.institution.reload).to be_institution_type_hospital }
    it { expect(local_authority.institution.reload).to be_institution_type_local_authority }
    it { expect(provider.institution.reload).to be_institution_type_private_childcare_provider }
  end

  describe "open" do
    before { backfill }

    it { expect(school.institution.reload.open).to be(true) }
    it { expect(further_education.institution.reload.open).to be(false) }
    it { expect(hospital_school.institution.reload.open).to be(true) }
    it { expect(local_authority.institution.reload.open).to be(true) }
    it { expect(provider.institution.reload.open).to be(true) }
    it { expect(disabled_provider.institution.reload.open).to be(false) }
  end

  context "with more institutions than the batch size" do
    before { stub_const("#{described_class}::BATCH_SIZE", 2) }

    it "backfills every row" do
      backfill

      expect(Institution.where(open: nil)).to be_empty
    end
  end
end
