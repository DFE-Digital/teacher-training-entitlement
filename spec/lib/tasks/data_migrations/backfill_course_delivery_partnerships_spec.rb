require "rails_helper"

RSpec.describe "data_migrations:backfill_course_delivery_partnerships" do
  after do
    Rake::Task["data_migrations:backfill_course_delivery_partnerships"].reenable
    connection.clear_cache!
  end

  let(:dry_run) { nil }
  let(:connection) { ActiveRecord::Base.connection }

  let(:course) { create(:course) }
  let(:other_course) { create(:course) }
  let(:cohort_one) { create(:cohort, registration_starts_at: Date.new(2024, 9, 1)) }
  let(:cohort_two) { create(:cohort, registration_starts_at: Date.new(2025, 9, 1)) }
  let(:course_cohort_one) { create(:course_cohort, course:, cohort: cohort_one) }
  let(:course_cohort_two) { create(:course_cohort, course:, cohort: cohort_two) }
  let(:lead_provider) { create(:lead_provider) }
  let(:delivery_partner_one) { create(:delivery_partner) }
  let(:delivery_partner_two) { create(:delivery_partner) }

  before do
    # Recreate the pre-migration shape: the task runs after the structure
    # migration but before course_cohort_id is dropped, when the model no
    # longer maps the association.
    connection.execute("ALTER TABLE delivery_partnerships ALTER COLUMN course_id DROP NOT NULL")
    connection.execute("ALTER TABLE delivery_partnerships ADD COLUMN course_cohort_id bigint")
    # ALTER TABLE invalidates cached query plans for the table; clear the
    # prepared statement cache so plans are rebuilt against the legacy shape.
    connection.clear_cache!
  end

  def insert_legacy_partnership(course_cohort:, lead_provider:, delivery_partner:)
    connection.execute(<<~SQL).to_a.first["id"]
      INSERT INTO delivery_partnerships (delivery_partner_id, lead_provider_id, course_cohort_id, created_at, updated_at)
      VALUES (#{delivery_partner.id}, #{lead_provider.id}, #{course_cohort.id}, NOW(), NOW())
      RETURNING id
    SQL
  end

  def invoke_task
    original_stdout = $stdout
    $stdout = StringIO.new
    task = Rake::Task["data_migrations:backfill_course_delivery_partnerships"]
    task.reenable
    task.invoke(dry_run)
    $stdout.string
  ensure
    $stdout = original_stdout
  end

  def legacy_course_ids
    connection.select_values("SELECT course_id FROM delivery_partnerships ORDER BY id")
  end

  context "when run in dry-run mode (the default)" do
    let(:dry_run) { nil }

    before do
      insert_legacy_partnership(course_cohort: course_cohort_one, lead_provider:, delivery_partner: delivery_partner_one)
      insert_legacy_partnership(course_cohort: course_cohort_two, lead_provider:, delivery_partner: delivery_partner_one)
    end

    it "changes nothing" do
      expect { invoke_task }.not_to change(DeliveryPartnership, :count)
      expect(legacy_course_ids).to all(be_nil)
    end

    it "lists every partnership that would be created" do
      output = invoke_task

      expect(output).to include("DeliveryPartnership #{DeliveryPartnership.first.id}: course_id -> #{course.id}")
      expect(output).to include("Removing duplicate DeliveryPartnership #{DeliveryPartnership.last.id}")
      expect(output).to include("Dry run: true")
    end
  end

  context "when run for real" do
    let(:dry_run) { "false" }

    before do
      insert_legacy_partnership(course_cohort: course_cohort_one, lead_provider:, delivery_partner: delivery_partner_one)
      insert_legacy_partnership(course_cohort: course_cohort_two, lead_provider:, delivery_partner: delivery_partner_one)
      insert_legacy_partnership(course_cohort: course_cohort_two, lead_provider:, delivery_partner: delivery_partner_two)
    end

    it "creates exactly one course-level partnership per delivery partner, lead provider and course" do
      invoke_task

      partnerships = DeliveryPartnership.order(:id)
      expect(partnerships.count).to eq(2)
      expect(partnerships.map(&:course_id)).to all(eq(course.id))
      expect(partnerships.map(&:delivery_partner)).to contain_exactly(delivery_partner_one, delivery_partner_two)
    end

    it "keeps partnerships on other courses untouched" do
      other_course_partnership_id = insert_legacy_partnership(
        course_cohort: create(:course_cohort, course: other_course, cohort: cohort_one),
        lead_provider:,
        delivery_partner: delivery_partner_one,
      )

      invoke_task

      partnership = DeliveryPartnership.find(other_course_partnership_id)
      expect(partnership.course_id).to eq(other_course.id)
    end

    it "is idempotent" do
      invoke_task

      expect { invoke_task }.not_to change(DeliveryPartnership, :count)
      expect(invoke_task).to include("Backfilled partnerships: 0", "Removed duplicate partnerships: 0")
    end

    it "leaves declarations referencing a delivery partner unchanged" do
      course_cohort_one.course_cohort_providers.find_or_create_by!(lead_provider:)
      application = create(:application, :accepted, course_cohort: course_cohort_one, lead_provider:)
      declaration = create(:declaration, :submitted, application:, lead_provider:)

      expect { invoke_task }.not_to(change { declaration.reload.attributes })
      expect(declaration.delivery_partner).to be_present
    end

    context "when partner sets are identical between cohorts" do
      before do
        insert_legacy_partnership(course_cohort: course_cohort_one, lead_provider:, delivery_partner: delivery_partner_two)
      end

      it "does not report differing partner sets" do
        expect(invoke_task).to include("Lead provider/course pairs with partner sets differing between cohorts: 0")
      end
    end

    context "when partner sets differ between cohorts" do
      let(:other_lead_provider) { create(:lead_provider) }

      before do
        # delivery_partner_two is only on cohort two, so the partner sets differ
        insert_legacy_partnership(course_cohort: course_cohort_two, lead_provider: other_lead_provider, delivery_partner: delivery_partner_one)
        insert_legacy_partnership(course_cohort: course_cohort_two, lead_provider: other_lead_provider, delivery_partner: delivery_partner_two)
      end

      it "reports every lead provider and course pair whose partner set will widen" do
        output = invoke_task

        expect(output).to include(
          "Lead provider #{lead_provider.id}, course #{course.id}: partner set differs between cohorts and will widen to all cohorts",
        )
        expect(output).not_to include("Lead provider #{other_lead_provider.id}, course #{course.id}: partner set differs")
        expect(output).to include("Lead provider/course pairs with partner sets differing between cohorts: 1")
      end
    end
  end
end
