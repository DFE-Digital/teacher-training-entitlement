require "rails_helper"

RSpec.describe Statements::MilestoneCourseCohortCalculator do
  subject(:calculator) do
    described_class.new(
      statement:,
      course_cohort:,
      milestone:,
      funded_place:,
      contract:,
    )
  end

  let(:lead_provider) { create(:lead_provider) }
  let(:statement) { create(:statement, lead_provider:, deadline_date: Time.zone.today) }
  let(:paid_statement) { create(:statement, :paid, lead_provider:) }
  let(:course_cohort) do
    create(:course_cohort, training_starts_at: 1.week.ago.to_date).tap do |course_cohort|
      create(:course_cohort_provider, course_cohort:, lead_provider:, teacher_funding: 100)
    end
  end
  let(:contract) { lead_provider.contract(course_cohort:) }
  let(:milestone) { course_cohort.course.milestones.detect(&:started_declaration_type?) }
  let(:funded_place) { [true] }

  def create_declaration(application:, statement:, milestone:)
    if milestone.started_declaration_type?
      application.update!(status: Application::STARTED)
    else
      application.update!(status: Application::STARTED) if application.accepted_status?
      application.update!(status: Application::COMPLETED)
    end

    create(
      :declaration,
      :eligible,
      milestone.declaration_type.to_sym,
      application:,
      statement:,
      milestone:,
      lead_provider: statement.lead_provider,
    )
  end

  describe "#scopes" do
    subject(:scopes) do
      described_class.new(
        statement:,
        course_cohort:,
        milestone:,
        funded_place:,
        contract:,
      ).scopes
    end

    context "with funded context" do
      let(:funded_place) { [true] }

      context "and without any funded declaration or any declaration on previous statement" do
        before do
          self_funded_app = create(:application, :accepted, :without_funded_place, course_cohort:, lead_provider:)
          create_declaration(application: self_funded_app, statement:, milestone:)
        end

        let!(:applications) do
          create_list(:application, 3, :accepted, :with_funded_place, course_cohort:, lead_provider:)
        end

        it do
          expect(scopes[:declaration_type]).to eq(milestone.declaration_type)
          expect(scopes[:expected]).to match_array(applications)
          expect(scopes[:outstanding]).to match_array(applications)
          expect(scopes[:value]).to eq(BigDecimal(60))
          expect(scopes[:expected_value]).to eq(BigDecimal(60) * applications.size)
          expect(scopes[:received_value]).to eq(0)

          expect(scopes[:received]).to eq(Declaration.none)
        end
      end

      context "and without any funded declaration and declarations on previous statement" do
        let!(:applications) do
          create_list(:application, 3, :accepted, :with_funded_place, course_cohort:, lead_provider:)
        end

        before do
          applications[0..1].each { |application| create_declaration(application:, statement: paid_statement, milestone:) }
        end

        it do
          expected = [applications.last]
          expect(scopes[:declaration_type]).to eq(milestone.declaration_type)
          expect(scopes[:expected]).to match_array(expected)
          expect(scopes[:outstanding]).to match_array(expected)
          expect(scopes[:value]).to eq(BigDecimal(60))
          expect(scopes[:expected_value]).to eq(BigDecimal(60) * expected.size)
          expect(scopes[:received_value]).to eq(0)

          expect(scopes[:received]).to eq(Declaration.none)
        end
      end

      context "and with a funded declaration and not declaration on previous statement" do
        let!(:applications) do
          create_list(:application, 3, :accepted, :with_funded_place, course_cohort:, lead_provider:)
        end
        let!(:declarations) do
          [create_declaration(application: applications[0], statement:, milestone:)]
        end

        it do
          outstanding = applications[1..2]
          expect(scopes[:declaration_type]).to eq(milestone.declaration_type)
          expect(scopes[:expected]).to match_array(applications)
          expect(scopes[:outstanding]).to match_array(outstanding)
          expect(scopes[:value]).to eq(BigDecimal(60))
          expect(scopes[:expected_value]).to eq(BigDecimal(60) * applications.size)
          expect(scopes[:received_value]).to eq(BigDecimal(60) * declarations.size)

          expect(scopes[:received]).to match_array(declarations)
        end
      end

      context "and with a funded declaration and declaration on previous statement" do
        let!(:applications) do
          create_list(:application, 3, :accepted, :with_funded_place, course_cohort:, lead_provider:)
        end
        let!(:declarations) do
          [create_declaration(application: applications[1], statement:, milestone:)]
        end

        before do
          create_declaration(application: applications[0], statement: paid_statement, milestone:)
        end

        it do
          expected = applications[1..2]
          outstanding = applications[2..2]
          expect(scopes[:declaration_type]).to eq(milestone.declaration_type)
          expect(scopes[:expected]).to match_array(expected)
          expect(scopes[:outstanding]).to match_array(outstanding)
          expect(scopes[:value]).to eq(BigDecimal(60))
          expect(scopes[:expected_value]).to eq(BigDecimal(60) * expected.size)
          expect(scopes[:received_value]).to eq(BigDecimal(60) * declarations.size)

          expect(scopes[:received]).to match_array(declarations)
        end
      end

      context "and with funded declarations and no outstanding declaration" do
        let!(:applications) do
          create_list(:application, 3, :accepted, :with_funded_place, course_cohort:, lead_provider:)
        end
        let!(:declarations) do
          [create_declaration(application: applications[2], statement:, milestone:)]
        end

        before do
          applications[0..1].each { |application| create_declaration(application:, statement: paid_statement, milestone:) }
        end

        it do
          expected = applications[2..2]
          outstanding = Application.none
          expect(scopes[:declaration_type]).to eq(milestone.declaration_type)
          expect(scopes[:expected]).to match_array(expected)
          expect(scopes[:outstanding]).to match_array(outstanding)
          expect(scopes[:value]).to eq(BigDecimal(60))
          expect(scopes[:expected_value]).to eq(BigDecimal(60) * expected.size)
          expect(scopes[:received_value]).to eq(BigDecimal(60) * declarations.size)

          expect(scopes[:received]).to match_array(declarations)
        end
      end
    end

    context "with self-funded context" do
      let(:funded_place) { [false] }

      context "and without any received self funded declaration" do
        before do
          funded_app = create(:application, :accepted, :with_funded_place, course_cohort:, lead_provider:)
          create_declaration(application: funded_app, statement:, milestone:)
        end

        it do
          expect(scopes[:declaration_type]).to eq(milestone.declaration_type)
          expect(scopes[:expected]).to eq(Application.none)
          expect(scopes[:outstanding]).to eq(Application.none)
          expect(scopes[:value]).to be_nil
          expect(scopes[:expected_value]).to be_nil
          expect(scopes[:received_value]).to be_nil

          expect(scopes[:received]).to eq(Declaration.none)
        end
      end

      context "and with a received self-funded declaration" do
        before do
          funded_app = create(:application, :accepted, :with_funded_place, course_cohort:, lead_provider:)
          create_declaration(application: funded_app, statement:, milestone:)
        end

        let(:self_funded_app) { create(:application, :accepted, :without_funded_place, course_cohort:, lead_provider:) }
        let!(:declaration) { create_declaration(application: self_funded_app, statement:, milestone:) }

        it do
          expect(scopes[:declaration_type]).to eq(milestone.declaration_type)
          expect(scopes[:expected]).to eq(Application.none)
          expect(scopes[:outstanding]).to eq(Application.none)
          expect(scopes[:value]).to be_nil
          expect(scopes[:expected_value]).to be_nil
          expect(scopes[:received_value]).to be_nil

          expect(scopes[:received]).to eq(Declaration.where(id: declaration.id))
        end
      end
    end
  end
end
