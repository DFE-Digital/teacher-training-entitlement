require "rails_helper"

RSpec.describe Declaration, type: :model do
  subject(:declaration) { build(:declaration) }

  describe "associations" do
    it { is_expected.to belong_to(:application) }
    it { is_expected.to belong_to(:cohort) }
    it { is_expected.to belong_to(:lead_provider) }
    it { is_expected.to belong_to(:superseded_by).optional }
    it { is_expected.to have_many(:participant_outcomes).dependent(:destroy) }
    it { is_expected.to have_many(:statement_items) }
    it { is_expected.to have_many(:statements).through(:statement_items) }
    it { is_expected.to belong_to(:delivery_partner).without_validating_presence }
    it { is_expected.to belong_to(:secondary_delivery_partner).without_validating_presence }
    it { is_expected.to belong_to(:clawback_declaration).without_validating_presence }

    context "with delivery partners" do
      subject do
        create(:declaration, application:,
                             lead_provider:,
                             cohort:,
                             delivery_partner: primary_partner,
                             secondary_delivery_partner: secondary_partner)
      end

      let(:application) { create(:application, :accepted) }
      let(:lead_provider) { application.lead_provider }
      let(:cohort) { application.cohort }
      let(:primary_partner) { create(:delivery_partner, lead_providers: { cohort => lead_provider }) }
      let(:secondary_partner) { create(:delivery_partner, lead_providers: { cohort => lead_provider }) }

      it { is_expected.to have_attributes delivery_partner: primary_partner }
      it { is_expected.to have_attributes secondary_delivery_partner: secondary_partner }
      it { is_expected.to have_attributes delivery_partners: [primary_partner, secondary_partner] }

      context "without secondary partner" do
        subject { create(:declaration, application:, cohort:, lead_provider:, delivery_partner: primary_partner) }

        it { is_expected.to have_attributes delivery_partners: [primary_partner] }
      end
    end
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:declaration_type) }
    it { is_expected.to validate_inclusion_of(:declaration_type).in_array(described_class.declaration_types.values) }
    it { is_expected.to validate_presence_of(:declaration_date) }
    it { is_expected.to validate_uniqueness_of(:ecf_id).case_insensitive.with_message("ECF ID must be unique") }

    context "with delivery_partners" do
      before { delivery_partner && old_cohort_partner }

      let(:application) { create(:application, :accepted, lead_provider: declaration.lead_provider) }
      let :delivery_partner do
        create :delivery_partner, lead_providers: { application.cohort => declaration.lead_provider }
      end

      let :second_partner do
        create :delivery_partner, lead_providers: { application.cohort => application.lead_provider }
      end

      let :old_cohort_partner do
        create :delivery_partner, lead_providers: {
          create(:cohort, registration_starts_at: Date.new(2023, 4, 1)) => declaration.lead_provider,
        }
      end

      it { is_expected.not_to validate_presence_of(:secondary_delivery_partner_id) }

      context "when no delivery partner provided" do
        let(:declaration) { build(:declaration, delivery_partner: nil) }

        it { is_expected.not_to validate_absence_of(:delivery_partner_id) }
        it { is_expected.to validate_absence_of(:secondary_delivery_partner_id) }
      end

      describe "skipping validation for certain cases" do
        let(:declaration) { build(:declaration, cohort:, delivery_partner: nil) }
        let(:cohort) { create(:cohort, registration_starts_at: Date.new(cohort_start_year, 4, 1)) }
        let(:cohort_start_year) { described_class::DELIVER_PARTNER_REQUIRED_FROM }

        context "with earlier cohort" do
          let(:cohort_start_year) { described_class::DELIVER_PARTNER_REQUIRED_FROM - 1 }

          it { is_expected.not_to validate_presence_of(:delivery_partner_id) }
          it { is_expected.not_to validate_presence_of(:secondary_delivery_partner_id) }
        end

        context "with later cohort" do
          let(:cohort_start_year) { described_class::DELIVER_PARTNER_REQUIRED_FROM + 1 }

          it { is_expected.to validate_presence_of(:delivery_partner_id) }
          it { is_expected.not_to validate_presence_of(:secondary_delivery_partner_id) }
        end

        context "without cohort set" do
          let(:cohort) { nil }

          it { is_expected.not_to validate_presence_of(:delivery_partner_id) }
          it { is_expected.not_to validate_presence_of(:secondary_delivery_partner_id) }
        end

        context "when changing declaration state" do
          subject do
            create(:declaration, :with_delivery_partner, cohort:)
              .tap(&:mark_eligible!)
              .reload
          end

          it { is_expected.to be_eligible_state }
        end

        context "with application from another country" do
          subject do
            build(:declaration, cohort:, application:, delivery_partner: DeliveryPartner.first)
          end

          let :application do
            create(:application, teacher_catchment: nil,
                                 teacher_catchment_country: "Italy",
                                 teacher_catchment_iso_country_code: "ITA")
          end

          it { is_expected.not_to validate_presence_of(:delivery_partner) }
          it { is_expected.not_to validate_presence_of(:secondary_delivery_partner) }
          it { is_expected.to validate_absence_of(:delivery_partner_id).with_message(/outside of England/) }
          it { is_expected.to validate_absence_of(:secondary_delivery_partner_id).with_message(/outside of England/) }
        end

        context "with application from a non-english home nation" do
          subject do
            build(:declaration, cohort:, application:, delivery_partner: DeliveryPartner.first)
          end

          let(:application) { build(:application, teacher_catchment: "wales") }

          it { is_expected.not_to validate_presence_of(:delivery_partner) }
          it { is_expected.not_to validate_presence_of(:secondary_delivery_partner) }
          it { is_expected.to validate_absence_of(:delivery_partner_id).with_message(/outside of England/) }
          it { is_expected.to validate_absence_of(:secondary_delivery_partner_id).with_message(/outside of England/) }
        end
      end

      context "with existing declarations" do
        let(:cohort_start_year) { described_class::DELIVER_PARTNER_REQUIRED_FROM }
        let(:cohort) { create(:cohort, registration_starts_at: Date.new(cohort_start_year, 4, 1)) }

        subject(:declaration) { create(:declaration, cohort:) }

        before do
          declaration

          declaration.mark_eligible!
          declaration.reload
        end

        it { is_expected.to be_eligible_state }
      end

      context "when delivery_partner is blank but secondary_delivery_partner is not" do
        before do
          declaration.delivery_partner = nil
          declaration.secondary_delivery_partner = delivery_partner
          declaration.valid?
        end

        it { expect(declaration.errors).to include :secondary_delivery_partner_id }
      end

      context "when delivery_partner and secondary_delivery partner are the same" do
        before { declaration.delivery_partner = delivery_partner }

        it { is_expected.not_to allow_value(delivery_partner.id).for(:secondary_delivery_partner_id) }
      end
    end

    context "when the declaration_date is in the future" do
      before { subject.declaration_date = 1.day.from_now }

      it "has an error on create" do
        expect(subject.save).to be_falsey
        expect(subject).to have_error(:declaration_date, :future_declaration_date, "The '#/declaration_date' value cannot be a future date. Check the date and try again.")
      end

      it "has an error on update" do
        subject.declaration_date = Time.zone.now
        expect(subject.save).to be_truthy

        subject.declaration_date = 1.day.from_now
        expect(subject.save).to be_falsey
        expect(subject).to have_error(:declaration_date, :future_declaration_date, "The '#/declaration_date' value cannot be a future date. Check the date and try again.")
      end
    end

    context "when declaration_date is before the schedule start" do
      let(:declaration_date) { application.schedule.training_starts_at.prev_week }

      context "when declaration is being created" do
        before { subject.declaration_date = subject.application.schedule.training_starts_at.prev_week }

        it "has a meaningful error" do
          expect(subject).to be_invalid
          expect(subject).to have_error(:declaration_date, :declaration_before_schedule_start, "Enter a '#/declaration_date' that's on or after the schedule start.")
        end
      end

      context "when declaration already exists" do
        let(:user) { create(:user) }
        let(:course) { create(:course) }

        let(:application) { create(:application, :accepted, user:, course:) }

        subject { build(:declaration, course:, user:, application:, declaration_date:).tap { |d| d.save!(validate: false) } }

        context "when declaration_date is not changed" do
          it { is_expected.to be_valid }
        end

        context "when declaration_date is going to be changed" do
          let(:declaration_date) { application.schedule.training_starts_at.next_week }
          let(:new_declaration_date) { application.schedule.training_starts_at.prev_week }

          it "is not valid" do
            subject.declaration_date = new_declaration_date
            expect(subject).not_to be_valid
          end
        end
      end
    end

    context "when declaration_date is at the schedule start" do
      before { subject.declaration_date = subject.application.schedule.training_starts_at }

      it { is_expected.to be_valid }
    end

    context "when declaration has two or fewer statement items" do
      it "is valid" do
        create_list(:statement_item, 2, declaration: subject)
        expect(subject).to be_valid
      end
    end

    context "when declaration has more than two statement items" do
      it "is not valid" do
        create_list(:statement_item, 3, declaration: subject)

        expect(subject).not_to be_valid
        expect(subject).to have_error(:statement_items, :more_than_two_statement_items, "There cannot be more than two items per declaration")
      end
    end
  end

  describe "delegations" do
    it { is_expected.to delegate_method(:course).to(:application) }
    it { is_expected.to delegate_method(:user).to(:application) }
    it { is_expected.to delegate_method(:identifier).to(:course).with_prefix(true) }
    it { is_expected.to delegate_method(:name).to(:lead_provider).with_prefix(true) }
  end

  describe "enums" do
    it {
      expect(subject).to define_enum_for(:state).with_values(
        submitted: "submitted",
        eligible: "eligible",
        payable: "payable",
        paid: "paid",
        voided: "voided",
        ineligible: "ineligible",
      ).backed_by_column_of_type(:enum).with_suffix
    }

    it {
      expect(subject).to define_enum_for(:declaration_type).with_values(
        started: "started",
        "retained-1": "retained-1",
        "retained-2": "retained-2",
        completed: "completed",
      ).backed_by_column_of_type(:enum).with_suffix
    }

    it {
      expect(subject).to define_enum_for(:state_reason).with_values(
        duplicate: "duplicate",
      ).backed_by_column_of_type(:enum).with_suffix
    }
  end

  describe "state transition" do
    let(:declaration) { create(:declaration, state:) }

    describe ".mark_eligible" do
      let(:state) { :submitted }

      it { expect { declaration.mark_eligible }.to change(declaration, :state).from("submitted").to("eligible") }

      context "when not submitted" do
        let(:state) { :paid }

        it { expect { declaration.mark_eligible! }.to raise_error(StateMachines::InvalidTransition) }
      end
    end

    describe ".mark_payable" do
      let(:state) { :eligible }

      it { expect { declaration.mark_payable }.to change(declaration, :state).from("eligible").to("payable") }

      context "when not eligible" do
        let(:state) { :paid }

        it { expect { declaration.mark_payable! }.to raise_error(StateMachines::InvalidTransition) }
      end
    end

    describe ".mark_paid" do
      let(:state) { :payable }

      it { expect { declaration.mark_paid }.to change(declaration, :state).from("payable").to("paid") }

      context "when not payable" do
        let(:state) { :paid }

        it { expect { declaration.mark_payable! }.to raise_error(StateMachines::InvalidTransition) }
      end
    end

    describe ".mark_ineligible" do
      context "when submitted" do
        let(:state) { :submitted }

        it { expect { declaration.mark_ineligible }.to change(declaration, :state).from("submitted").to("ineligible") }
      end

      context "when not submitted/eligible/payable/paid" do
        let(:state) { :voided }

        it { expect { declaration.mark_ineligible! }.to raise_error(StateMachines::InvalidTransition) }
      end
    end

    describe ".mark_voided" do
      context "when submitted" do
        let(:state) { :submitted }

        it { expect { declaration.mark_voided }.to change(declaration, :state).from("submitted").to("voided") }
      end

      context "when eligible" do
        let(:state) { :eligible }

        it { expect { declaration.mark_voided }.to change(declaration, :state).from("eligible").to("voided") }
      end

      context "when payable" do
        let(:state) { :payable }

        it { expect { declaration.mark_voided }.to change(declaration, :state).from("payable").to("voided") }
      end

      context "when ineligible" do
        let(:state) { :ineligible }

        it { expect { declaration.mark_voided }.to change(declaration, :state).from("ineligible").to("voided") }
      end

      context "when not submitted/eligible/payable/ineligible" do
        let(:state) { :paid }

        it { expect { declaration.mark_voided! }.to raise_error(StateMachines::InvalidTransition) }
      end
    end

    describe ".revert_to_eligible" do
      let(:state) { :payable }

      it { expect { declaration.revert_to_eligible }.to change(declaration, :state).from("payable").to("eligible") }

      context "when not payable" do
        let(:state) { :paid }

        it { expect { declaration.revert_to_eligible! }.to raise_error(StateMachines::InvalidTransition) }
      end

      context "when submitted" do
        let(:state) { :submitted } # valid transition, but wrong event name

        it { expect { declaration.revert_to_eligible! }.to raise_error(StateMachines::InvalidTransition) }
      end
    end
  end

  describe "#clawback!" do
    subject(:paid_declaration) { create(:declaration, :paid) }

    before { paid_declaration.clawback! }

    it { expect(paid_declaration.clawback_declaration).to be_present }
    it { expect(paid_declaration.state).to eq("paid") }
    it { expect(paid_declaration.clawback_declaration.paid_declaration).to eq(paid_declaration) }
  end

  describe "#uplift_paid?" do
    let(:declaration_type) { :started }
    let(:state) { described_class::UPLIFT_PAID_STATES.sample }

    subject(:declaration) do
      build(:declaration, declaration_type:, state:)
    end

    it { is_expected.to be_uplift_paid }

    described_class.declaration_types.keys.excluding("started").each do |ineligible_declaration_type|
      context "when declaration_type is #{ineligible_declaration_type}" do
        let(:declaration_type) { ineligible_declaration_type }

        it { is_expected.not_to be_uplift_paid }
      end
    end

    described_class::UPLIFT_PAID_STATES.each do |eligible_state|
      context "when state is #{eligible_state}" do
        let(:state) { eligible_state }

        it { is_expected.to be_uplift_paid }
      end
    end

    described_class.states.keys.excluding(described_class::UPLIFT_PAID_STATES).each do |ineligible_state|
      context "when state is #{ineligible_state}" do
        let(:state) { ineligible_state }

        it { is_expected.not_to be_uplift_paid }
      end
    end
  end

  describe "#ineligible_for_funding_reason" do
    let(:state) { :ineligible }
    let(:state_reason) { nil }
    let(:declaration) { build(:declaration, state:, state_reason:) }

    subject { declaration.ineligible_for_funding_reason }

    it { is_expected.to be_nil }

    context "when the state_reason is 'duplicate'" do
      let(:state_reason) { "duplicate" }

      it { is_expected.to eq("duplicate_declaration") }
    end

    described_class.states.keys.excluding("ineligible").each do |ineligible_state|
      context "when the state is #{ineligible_state}" do
        let(:state) { ineligible_state }

        it { is_expected.to be_nil }
      end
    end
  end

  describe "#eligible_for_payment?" do
    subject { build(:declaration, state:) }

    context "when the state is payable" do
      let(:state) { :payable }

      it { is_expected.to be_eligible_for_payment }
    end

    context "when the state is eligible" do
      let(:state) { :eligible }

      it { is_expected.to be_eligible_for_payment }
    end

    described_class.states.keys.excluding("payable", "eligible").each do |eligible_state|
      context "when the state is #{eligible_state}" do
        let(:state) { eligible_state }

        it { is_expected.not_to be_eligible_for_payment }
      end
    end
  end

  describe "#billable_statement" do
    let(:statement_item) { create(:statement_item, state: :payable) }
    let(:declaration) { statement_item.declaration }

    subject { declaration.billable_statement }

    it { is_expected.to eq(statement_item.statement) }

    context "when there are no billable statement items" do
      let(:statement_item) { create(:statement_item, state: :awaiting_clawback) }

      it { is_expected.to be_nil }
    end
  end

  describe "#refundable_statement" do
    let(:statement_item) { create(:statement_item, state: :awaiting_clawback) }
    let(:declaration) { statement_item.declaration }

    subject { declaration.refundable_statement }

    it { is_expected.to eq(statement_item.statement) }

    context "when there are no refundable statement items" do
      let(:statement_item) { create(:statement_item, state: :payable) }

      it { is_expected.to be_nil }
    end
  end

  describe "scopes" do
    describe ".latest_first" do
      let!(:latest_declaration) { create(:declaration) }
      let!(:older_declaration) { travel_to(1.day.ago) { create(:declaration) } }

      it "returns the declarations with those created latest first" do
        expect(described_class.latest_first).to eq([latest_declaration, older_declaration])
      end
    end

    describe ".eligible_for_outcomes" do
      subject { described_class.eligible_for_outcomes(lead_provider, course_identifier) }

      let(:lead_provider) { completed_declaration.lead_provider }
      let(:course_identifier) { completed_declaration.course_identifier }
      let(:completed_declaration) { create(:declaration, :completed, :payable) }
      let(:course) { completed_declaration.course }
      let(:older_completed_declaration) { travel_to(1.hour.ago) { create(:declaration, :completed, :payable, course:, lead_provider:) } }

      before do
        # Not a completed declaration.
        create(:declaration, :payable, lead_provider:, course:, declaration_type: "retained-1")

        # Declaration on another provider.
        create(:declaration, :completed, :payable, lead_provider: create(:lead_provider), course:)

        # Declaration with different course.
        create(:declaration, :completed, :payable, lead_provider:, course:, application: create(:application, course: create(:course, identifier: "other-course")))

        # Declarations that are not billable or voidable.
        Declaration.states.keys.excluding(Declaration::BILLABLE_STATES + Declaration::VOIDABLE_STATES).each do |state|
          create(:declaration, :completed, :payable, lead_provider:, course:, state:)
        end
      end

      it { is_expected.to eq([completed_declaration, older_completed_declaration]) }

      context "when there are no declarations" do
        before { Declaration.destroy_all }

        it { is_expected.to be_empty }
      end
    end

    describe "declaration states" do
      let(:declarations) { described_class.states.keys.map { |state| create(:declaration, state:) } }
      let(:voided_paid_declaration) { create(:declaration, :voided_paid) }

      describe ".billable" do
        it "returns declarations with billable states" do
          billable_declarations = declarations.select { |d| %w[eligible payable paid].include?(d.state) && d.clawback_declaration.nil? }

          expect(described_class.billable).to match_array(billable_declarations)
        end
      end

      describe ".voidable" do
        it "returns declarations with voidable states" do
          voidable_declarations = declarations.select { |d| %w[submitted eligible payable ineligible].include?(d.state) }

          expect(described_class.voidable).to match_array(voidable_declarations)
        end
      end

      describe ".changeable" do
        it "returns declarations with changeable states" do
          changeable_declarations = declarations.select { |d| %w[eligible submitted].include?(d.state) }

          expect(described_class.changeable).to match_array(changeable_declarations)
        end
      end

      describe ".billable_or_changeable" do
        it "returns declarations with either billable or changeable states" do
          states = %w[submitted eligible payable paid]
          billable_or_changeable = declarations.select { |d| states.include?(d.state) }

          expect(described_class.billable_or_changeable).to match_array(billable_or_changeable)
        end
      end

      describe ".billable_or_voidable" do
        it "returns declarations with either billable or voidable states" do
          states = %w[submitted eligible payable paid ineligible]
          billable_or_voidable = declarations.select { |d| states.include?(d.state) }

          expect(described_class.billable_or_voidable).to match_array(billable_or_voidable)
        end
      end

      describe ".awaiting_clawback" do
        it "returns declarations which are in the awaiting_clawback state" do
          expect(described_class.awaiting_clawback.pluck(:state)).to all eq("awaiting_clawback")
        end
      end
    end

    describe ".with_lead_provider" do
      let(:lead_provider) { declaration.lead_provider }
      let(:declaration) { create(:declaration) }

      before { create(:declaration, lead_provider: create(:lead_provider)) }

      it { expect(described_class.with_lead_provider(lead_provider)).to contain_exactly(declaration) }
    end

    describe ".completed" do
      let(:completed_declaration) { create(:declaration, :completed) }

      before do
        described_class.declaration_types.keys.excluding("completed").each do |declaration_type|
          create(:declaration, declaration_type:)
        end
      end

      it { expect(described_class.completed).to contain_exactly(completed_declaration) }
    end

    describe ".with_course_identifier" do
      let(:course_identifier) { declaration.application.course.identifier }
      let(:declaration) { create(:declaration) }

      before do
        Course::IDENTIFIERS.excluding(course_identifier).each do |identifier|
          create(:declaration, course: Course.find_by(identifier:))
        end
      end

      it { expect(described_class.with_course_identifier(course_identifier)).to contain_exactly(declaration) }
    end

    describe ".for_delivery_partners" do
      subject { Declaration.for_delivery_partners(delivery_partner) }

      let(:application) { create(:application, :accepted, course_cohort:, lead_provider:) }
      let(:declaration_date) { schedule.training_starts_at + 1.hour }
      let(:course_cohort) { create(:course_cohort, schedule:) }
      let(:lead_provider) { create(:lead_provider) }
      let(:schedule) { create(:schedule, training_starts_at: 1.day.ago, training_ends_at: 1.day.from_now) }

      let(:delivery_partner) do
        create(:delivery_partner, lead_providers: { course_cohort.cohort => lead_provider })
      end
      let(:secondary_delivery_partner) do
        create(:delivery_partner, lead_providers: { course_cohort.cohort => lead_provider })
      end

      let(:declaration_as_primary) do
        create :declaration, lead_provider:, application:, delivery_partner:, cohort: application.cohort
      end

      it { is_expected.to include declaration_as_primary }

      context "when declared as secondary partner" do
        subject { Declaration.for_delivery_partners(secondary_delivery_partner) }

        let :declaration_as_secondary do
          create :declaration, lead_provider:,
                               application:,
                               cohort: application.cohort,
                               delivery_partner:,
                               secondary_delivery_partner:
        end

        it { is_expected.to include declaration_as_secondary }
      end
    end

    describe ".order_by_milestone" do
      let(:application) { create(:application, :accepted, cohort:, course:) }

      before do
        create(:declaration, :completed, :payable)
        create(:declaration, :payable, declaration_type: "started")
        create(:declaration, :payable, declaration_type: "retained-1")
        create(:declaration, :payable, declaration_type: "retained-2")
      end

      it "sorts declarations properly" do
        declarations = Declaration.order_by_milestones
        expected_types = %w[completed retained-2 retained-1 started]
        expect(declarations.pluck(:declaration_type)).to eq expected_types
      end

      it "considers state when sorting" do
        declarations = Declaration.order_by_milestones
        expect(declarations.first.state).to eq("payable")
      end
    end
  end

  describe "#duplicate_declarations" do
    let(:cohort) { create(:cohort, :current) }
    let(:course) { create(:course, :npd_eirt) }
    let(:schedule) { create(:schedule, :npq_leadership_autumn, cohort:) }
    let(:application) { create(:application, :accepted, cohort:, course:) }
    let(:participant) { application.user }
    let!(:declaration) { create(:declaration, application:) }

    context "when a user exists with the same TRN" do
      let(:other_user) { create(:user, trn: participant.trn) }

      context "when declarations have been made for a user with the same trn" do
        context "when declarations have been made for the same course" do
          let(:other_application) { create(:application, :accepted, cohort:, course:, user: other_user) }
          let!(:other_declaration) { create(:declaration, application: other_application) }

          it "returns those declarations" do
            expect(declaration.duplicate_declarations).to eq([other_declaration])
          end
        end

        context "when declarations have been made for a different course", :npq do
          before do
            course = create(:course, :npd_eirt)
            other_application = create(:application, :accepted, course:, cohort:, user: other_user)
            create(:declaration, application: other_application)
          end

          it "returns no declarations" do
            expect(declaration.duplicate_declarations).to be_empty
          end
        end
      end

      context "when no declaration has been made for a user with the same trn" do
        it "returns no declarations" do
          expect(declaration.duplicate_declarations).to be_empty
        end
      end
    end

    context "when a declaration has been superseded by another" do
      before { create(:declaration, application:, superseded_by: declaration) }

      it "returns no declarations" do
        expect(declaration.duplicate_declarations).to be_empty
      end
    end

    context "when a declaration has a different type" do
      before { create(:declaration, application:, declaration_type: :completed) }

      it "returns no declarations" do
        expect(declaration.duplicate_declarations).to be_empty
      end
    end
  end

  describe "paper_trail" do
    it "enables paper trail" do
      expect(Declaration.new).to be_versioned
    end
  end

  describe "#available_delivery_partner_ids" do
    subject(:available_delivery_partner_ids) { declaration.available_delivery_partner_ids }

    let :lead_provider do
      create :lead_provider, delivery_partners: {
        twenty_three => twenty_three_partner,
        create(:cohort, registration_starts_at: Date.new(2024, 4, 1)) => twenty_four_partner,
      }
    end

    let(:declaration) { build(:declaration, lead_provider:, cohort: twenty_three) }
    let(:twenty_three) { create(:cohort, registration_starts_at: Date.new(2023, 4, 1)) }
    let(:twenty_three_partner) { create(:delivery_partner) }
    let(:twenty_four_partner) { create(:delivery_partner) }

    it { is_expected.to include twenty_three_partner.id }
    it { is_expected.not_to include twenty_four_partner.id }

    context "without delivery_partner" do
      let(:lead_provider) { nil }

      it { is_expected.to be_empty }
    end

    context "without cohort" do
      before { allow(lead_provider).to receive(:delivery_partners_for_cohort) }

      let(:declaration) { build(:declaration, delivery_partner: nil, lead_provider:, cohort: nil) }

      it { is_expected.to be_empty }

      it "avoids querying the database" do
        available_delivery_partner_ids

        expect(lead_provider).not_to have_received(:delivery_partners_for_cohort)
      end
    end
  end

  describe "#state_history", :versioning do
    subject { declaration.state_history }

    context "with default initial state" do
      let(:declaration) { create(:declaration) }

      it { is_expected.to eq [["submitted", declaration.created_at]] }

      context "and changes" do
        let(:new_state_at) { 1.hour.ago.beginning_of_minute }

        before do
          travel_to(1.day.ago)    { declaration.update! ecf_id: SecureRandom.uuid } # changing anything other than state is ignored
          travel_to(new_state_at) { declaration.mark_eligible! }
        end

        it { is_expected.to eq [["submitted", declaration.created_at], ["eligible", new_state_at]] }
      end
    end

    context "with specific initial state" do
      let(:declaration) { create(:declaration, :payable) }

      it { is_expected.to eq [["payable", declaration.created_at]] }

      context "and changes" do
        let(:new_state_at) { 1.hour.ago.beginning_of_minute }

        before do
          travel_to(1.day.ago)    { declaration.update! ecf_id: SecureRandom.uuid } # changing anything other than state is ignored
          travel_to(new_state_at) { declaration.mark_paid! }
        end

        it { is_expected.to eq [["payable", declaration.created_at], ["paid", new_state_at]] }
      end
    end
  end
end
