require "rails_helper"

RSpec.describe AdminService::TeachersSearch do
  subject { described_class.new(q:) }

  let!(:teacher) { create(:teacher, preferred_name: "Jonny D") }
  let!(:application) do
    create(:application,
           teacher:)
  end

  describe "#call" do
    context "when partial email match" do
      let(:q) { teacher.email.split("@").first }

      it "returns the hit" do
        expect(subject.call).to include(teacher)
      end
    end

    context "when teacher#full_name match" do
      let(:q) { teacher.full_name }

      it "returns the hit" do
        expect(subject.call).to include(teacher)
      end
    end

    context "when teacher#preferred_name match" do
      let(:q) { teacher.preferred_name.split(" ").first }

      it "returns the hit" do
        expect(subject.call).to include(teacher)
      end
    end

    context "when teacher#ecf_id match" do
      let(:q) { teacher.ecf_id }

      it "returns the hit" do
        expect(subject.call).to include(teacher)
      end
    end

    context "when application#ecf_id match" do
      let(:q) { application.ecf_id }

      it "returns the hit" do
        expect(subject.call).to include(teacher)
      end
    end

    context "when teacher#trn match" do
      let(:q) { teacher.trn }

      it "returns the hit" do
        expect(subject.call).to include(teacher)
      end
    end

    context "when institution#school_urn match" do
      let(:q) { application.institution.urn }

      it "returns the hit" do
        expect(subject.call).to include(teacher)
      end
    end

    context "when application#private_childcare_provider_urn match" do
      let!(:application) { create(:application, :with_private_childcare_provider, teacher:) }
      let(:q) { application.private_childcare_provider.urn }

      it "returns the hit" do
        expect(subject.call).to include(teacher)
      end
    end

    context "when the teacher has multiple applications" do
      let(:q) { teacher.full_name }

      before do
        create(:application, :for_cohort_starting_on, teacher:, registration_starts_at: Date.new(2021, 4, 1))
      end

      it "returns one result" do
        expect(subject.call.count).to eq(1)
      end
    end
  end
end
