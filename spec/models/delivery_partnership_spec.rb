require "rails_helper"

RSpec.describe DeliveryPartnership, type: :model do
  describe "auditing", :versioning do
    before { PaperTrail.request.whodunnit = "AdminUser 42" }

    after { PaperTrail.request.whodunnit = nil }

    it { is_expected.to be_versioned }

    context "when created" do
      let!(:partnership) { create(:delivery_partnership) }

      it "records a create version attributed to the admin" do
        version = partnership.versions.last
        expect([version.event, version.whodunnit]).to eq(["create", "AdminUser 42"])
      end
    end

    context "when archived" do
      let(:partnership) { create(:delivery_partnership) }

      before { partnership.archive! }

      it "records an update version with the archived_at change" do
        version = partnership.versions.last
        expect([version.event, version.whodunnit, version.object_changes.keys]).to eq(["update", "AdminUser 42", %w[archived_at]])
      end
    end

    context "when unarchived" do
      let(:partnership) { create(:delivery_partnership, archived_at: 1.day.ago) }

      before { partnership.unarchive! }

      it "records an update version resetting archived_at" do
        version = partnership.versions.last
        expect([version.event, version.whodunnit, version.object_changes["archived_at"].last]).to eq(["update", "AdminUser 42", nil])
      end
    end

    context "when destroyed" do
      let!(:partnership) { create(:delivery_partnership) }

      it "records a destroy version" do
        expect { partnership.destroy! }.to change { PaperTrail::Version.where(item_type: "DeliveryPartnership", event: "destroy").count }.by(1)
      end
    end
  end

  describe "relationships" do
    it { is_expected.to belong_to :delivery_partner }
    it { is_expected.to belong_to :lead_provider }
    it { is_expected.to belong_to :course }
    it { is_expected.to have_many(:course_cohorts).through(:course) }
  end

  describe "scopes" do
    let!(:active_partnership) { create(:delivery_partnership) }
    let!(:archived_partnership) { create(:delivery_partnership, archived_at: 1.day.ago) }

    it { expect(described_class.active).to contain_exactly(active_partnership) }
    it { expect(described_class.archived).to contain_exactly(archived_partnership) }
  end

  describe "#archive!" do
    subject(:partnership) { create(:delivery_partnership) }

    it "sets archived_at" do
      freeze_time do
        expect { partnership.archive! }.to change { partnership.reload.archived_at }.from(nil).to(Time.current)
      end
    end
  end

  describe "#unarchive!" do
    subject(:partnership) { create(:delivery_partnership, archived_at: 1.day.ago) }

    it "clears archived_at" do
      expect { partnership.unarchive! }.to change { partnership.reload.archived_at }.to(nil)
    end
  end

  describe "#archived?" do
    it { expect(build(:delivery_partnership, archived_at: Time.current)).to be_archived }
    it { expect(build(:delivery_partnership)).not_to be_archived }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of :delivery_partner_id }
    it { is_expected.to validate_presence_of :lead_provider_id }
    it { is_expected.to validate_presence_of :course_id }

    it "does not require the lead provider to deliver the course (no course cohort provider needed)" do
      expect(create(:delivery_partnership)).to be_persisted
    end

    describe "uniqueness" do
      subject { described_class.new }

      before { create :delivery_partnership }

      it "delivery partner must be unique for a given lead provider and course" do
        expect(subject).to validate_uniqueness_of(:delivery_partner_id).scoped_to(%i[lead_provider_id course_id])
      end
    end
  end
end
