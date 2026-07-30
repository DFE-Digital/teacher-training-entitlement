require "rails_helper"

RSpec.describe Statement, type: :model do
  subject(:statement) { build(:statement) }

  describe "relationships" do
    it { is_expected.to belong_to(:lead_provider).required }
    it { is_expected.to have_many(:declarations) }
    it { is_expected.to have_many(:clawback_declarations) }
    it { is_expected.to have_many(:contracts) }
    it { is_expected.to have_many(:milestones).through(:declarations) }
    it { is_expected.to have_many(:adjustments) }
  end

  describe "validations" do
    it do
      expect(statement).to define_enum_for(:frequency)
                             .with_values(Statement::FREQUENCIES.keys.index_with(&:itself))
                             .backed_by_column_of_type(:enum)
                             .with_suffix
    end

    it { is_expected.to validate_presence_of(:start_date) }
    it { is_expected.to allow_value(%w[true false]).for(:output_fee).with_message("Output fee must be true or false") }
    it { is_expected.not_to allow_value(nil).for(:output_fee).with_message("Choose yes or no for output fee") }
    it { is_expected.to validate_uniqueness_of(:ecf_id).case_insensitive.with_message("ECF ID must be unique") }
    it { is_expected.to validate_uniqueness_of(:lead_provider_id).scoped_to(:start_date, :frequency).with_message("A statement for this lead provider, cohort, year and month already exists") }

    describe "State validation" do
      context "when setting invalid state" do
        let(:statement) { build(:statement, state: "madeup") }

        it "returns error" do
          expect(statement).to have_error(:state, :invalid, "is invalid")
        end
      end
    end

    describe "statement dates" do
      context "when only start_date and frequency are provided" do
        let(:start_date) { Date.new(2026, 2, 1) }
        let(:frequency) { :monthly }
        let(:statement) { create(:statement, start_date:, frequency:) }

        it "sets deadline_date" do
          expect(statement.deadline_date).to eq(Date.new(2026, 2, 28))
        end

        it "sets payment_date" do
          expect(statement.payment_date).to eq(Date.new(2026, 3, 31))
        end
      end

      context "when there is no payment date" do
        subject(:statement) { build(:statement, payment_date: nil, deadline_date: Time.zone.today) }

        it { is_expected.to be_valid }
      end

      context "when there is no deadline date" do
        subject(:statement) { build(:statement, payment_date: Time.zone.today, deadline_date: nil) }

        it { is_expected.to be_valid }
      end
    end

    describe "output_fee validation" do
      context "when changing an attribute other than output_fee with milestones attached" do
        let(:statement) { create(:statement, :with_milestones, output_fee: true) }

        it "is valid" do
          statement.output_fee = true
          existing_deadline_date = statement.deadline_date
          statement.deadline_date = existing_deadline_date + 1.day
          expect(statement).to be_valid
        end
      end
    end

    describe "changing reconcile_amount when the statement is payable" do
      subject(:statement) { create(:statement, :payable) }

      before { statement.reconcile_amount = 100 }

      it "returns an error" do
        expect(statement).to have_error(:base, :statement_payable, "Statement cannot be changed once it is payable")
      end
    end

    describe "changing output_fee when the statement is payable" do
      subject(:statement) { create(:statement, :payable, output_fee: true) }

      before { statement.output_fee = false }

      it { is_expected.to be_valid }
    end

    describe "changing reconcile_amount when the statement is paid" do
      subject(:statement) { create(:statement, :paid) }

      before { statement.reconcile_amount = 100 }

      it "returns an error" do
        expect(statement).to have_error(:base, :statement_paid, "Statement cannot be changed once it is paid")
      end
    end

    describe "changing output_fee when the statement is paid" do
      subject(:statement) { create(:statement, :paid, output_fee: true) }

      before { statement.output_fee = false }

      it "returns an error" do
        expect(statement).to have_error(:base, :statement_paid, "Statement cannot be changed once it is paid")
      end
    end
  end

  describe "scopes" do
    describe ".paid" do
      it "selects only paid statements" do
        expect(Statement.paid.to_sql).to include(%(WHERE "statements"."state" = 'paid'))
      end
    end

    describe ".unpaid" do
      it "selects only unpaid statements" do
        expect(Statement.unpaid.to_sql).to include(%(WHERE "statements"."state" IN ('open', 'payable')))
      end
    end

    describe ".with_state" do
      it "selects only statements with states matching the provided name" do
        expect(Statement.with_state("foo").to_sql).to include(%(WHERE "statements"."state" = 'foo'))
      end

      it "selects only multiple statements with states matching the provided names" do
        expect(Statement.with_state("foo", "bar").to_sql).to include(%(WHERE "statements"."state" IN ('foo', 'bar')))
      end
    end

    describe ".with_output_fee" do
      it "selects only output fee statements" do
        expect(Statement.with_output_fee.to_sql).to include(%(WHERE "statements"."output_fee" = TRUE))
      end
    end
  end

  describe "paper_trail" do
    subject { create(:statement, :open) }

    it "enables paper trail" do
      expect(subject).to be_versioned
    end

    it "creates a version with a note" do
      with_versioning do
        expect(PaperTrail).to be_enabled

        subject.update!(
          state: :payable,
          version_note: "This is a test",
        )
        version = subject.versions.last
        expect(version.note).to eq("This is a test")
        expect(version.object_changes["state"]).to eq(%w[open payable])
      end
    end
  end

  describe "State transition" do
    context "when from open to payable" do
      let(:statement) { create(:statement, :open) }

      it "transitions state to payable" do
        expect(statement).to be_open
        statement.mark_payable!
        expect(statement).to be_payable
      end
    end

    context "when from payable to paid" do
      let(:statement) { create(:statement, :payable, marked_as_paid_at: 1.week.ago) }

      it "transitions state to payable" do
        expect(statement).to be_payable
        statement.mark_paid!
        expect(statement).to be_paid
      end
    end

    context "when from paid to payable" do
      let(:statement) { create(:statement, :paid) }

      it "raises error" do
        expect(statement).to be_paid
        expect { statement.mark_payable! }.to raise_error(StateMachines::InvalidTransition)
      end
    end
  end

  describe "#mark_as_frozen!" do
    subject(:statement) { build(:statement, :payable) }

    it "sets marked_as_paid_at and state" do
      expect { statement.tap(&:mark_as_frozen!).reload }
        .to change(statement, :marked_as_paid_at)
              .and change(statement, :state).from("payable").to("paid")
    end

    it "updates declarations"
    it "updates clawback declarations"
  end

  describe "#prepare_to_freeze!" do
    subject(:statement) { build(:statement, :open) }

    it "updates state" do
      expect { statement.tap(&:prepare_to_freeze!).reload }
        .to change(statement, :state).from("open").to("payable")
    end

    it "updates declarations"
    it "updates clawback declarations"
  end

  describe "#marked_as_paid_with_date?" do
    context "with a statement marked as paid" do
      subject { create(:statement, :paid) }

      it { is_expected.to be_marked_as_paid_with_date }
    end

    context "with a statement not marked as paid" do
      it { is_expected.not_to be_marked_as_paid_with_date }
    end
  end

  describe "#allow_marking_as_paid?" do
    subject(:allow_marking_as_paid) { statement.allow_marking_as_paid? }

    let(:declaration) { create(:declaration, :payable, statement:) }

    before do
      statement.declarations << declaration if declaration
    end

    context "with payable statement with declarations" do
      let(:statement) { create(:statement, :next_output_fee, :payable, start_date: 1.month.from_now) }

      it { is_expected.to be true }
    end

    context "with non output fee statement" do
      let(:statement) { create(:statement, :payable, output_fee: false) }

      it { is_expected.to be false }
    end

    context "with statement not in payable state" do
      let :statement do
        create(:statement, :open, :next_output_fee, deadline_date: Time.zone.yesterday)
      end

      it { is_expected.to be false }
    end

    context "with statement without declarations" do
      let(:declaration) { nil }
      let(:statement) { create(:statement, :next_output_fee, :payable) }

      it { is_expected.to be false }
    end

    context "with future deadline date" do
      let :statement do
        create(:statement, :next_output_fee, :payable, deadline_date: Time.zone.today)
      end

      it { is_expected.to be false }
    end

    context "with nil deadline date" do
      let :statement do
        create(:statement, :next_output_fee, :payable, deadline_date: nil)
      end

      it { is_expected.to be false }
    end
  end

  describe "#authorising_for_payment?" do
    subject { statement.authorising_for_payment? }

    context "with payable statement with marked_as_paid_at set" do
      let(:statement) { build(:statement, :payable, marked_as_paid_at: Time.zone.now) }

      it { is_expected.to be true }
    end

    context "with payable statement without marked_as_paid_at set" do
      let(:statement) { build(:statement, :payable, marked_as_paid_at: nil) }

      it { is_expected.to be false }
    end

    context "with paid statement with marked_as_paid_at set" do
      let(:statement) { build(:statement, :paid, marked_as_paid_at: Time.zone.now) }

      it { is_expected.to be false }
    end

    context "with open statement with marked_as_paid_at_set" do
      let(:statement) { build(:statement, :open, marked_as_paid_at: Time.zone.now) }

      it { is_expected.to be false }
    end
  end
end
