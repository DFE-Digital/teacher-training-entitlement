# frozen_string_literal: true

require "rails_helper"

RSpec.describe ValidTestDataGenerators::APITestScenariosSeeder do
  let(:seeder) { described_class.new(lead_provider:, cohort_year:) }
  let(:lead_provider) { create(:lead_provider) }
  let(:cohort_year) { 2026 }

  before do
    create(:school)
    allow(Rails).to receive(:env).and_return(environment.inquiry)
  end

  describe "#custom_data" do
    subject(:custom_data) { seeder.custom_data(nb_cohort: 1, nb_app_per_state: 2) }

    let(:environment) { "sandbox" }

    context "when creating historical data" do
      before { custom_data }

      let(:cohort_year) { Time.zone.now.year - 1 }
      let(:applications) { lead_provider.applications.group_by(&:status) }

      it "creates application each application statuses" do
        Application::STATUSES.each do |status|
          expect(applications[status.to_s].size).to eq 2
          expect(applications[status.to_s].map(&:eligible_for_funding)).to contain_exactly(true, false)
        end
        expect(applications.keys).to match_array(Application::STATUSES)
      end
    end

    context "when creating present/future data" do
      before { custom_data }

      let(:cohort_year) { Time.zone.now.year }
      let(:applications) { lead_provider.applications.group_by(&:status) }

      it "creates application with status pending, accepted and rejected only" do
        [Application::PENDING, Application::ACCEPTED, Application::REJECTED].each do |status|
          expect(applications[status.to_s].size).to eq 2
          expect(applications[status.to_s].map(&:eligible_for_funding)).to contain_exactly(true, false)
        end
        expect(applications.keys).to contain_exactly(Application::PENDING, Application::ACCEPTED, Application::REJECTED)
      end
    end
  end

  describe "#call" do
    %w[production test].each do |env|
      context "when running in #{env} environment" do
        subject(:outcome) { seeder.call }

        let(:environment) { env }

        it { expect(outcome.success).to be false }
        it { expect(outcome.error).to eq("Only available in development, review, and sandbox environments") }

        it "does not create any data" do
          expect { seeder.call }.not_to change(Application, :count)
        end
      end
    end

    context "when running in sandbox environment" do
      subject(:outcome) { seeder.call }

      let(:environment) { "sandbox" }

      describe "successful seeding" do
        it "returns success outcome" do
          expect(outcome.success).to be true
          expect(outcome.applications_count).to eq(12)
          expect(outcome.cohort_year).to eq(cohort_year)
        end

        it "creates 12 applications" do
          expect { outcome }.to change(Application, :count).by(12)
        end

        it "creates 12 users" do
          expect { outcome }.to change(User, :count).by(12)
        end

        it "creates applications with correct emails" do
          seeder.call

          created_emails = Application.joins(:user).where(lead_provider:).pluck("users.email")

          expect(created_emails).to match_array(seeder.test_emails)
        end

        it "creates all applications in pending status" do
          seeder.call

          applications = Application.where(lead_provider: lead_provider)
          expect(applications.pluck(:status).uniq).to eq([Application::PENDING])
        end

        it "creates applications with correct funding eligibility" do
          seeder.call

          eligible_count = Application.joins(:user)
                                      .where(lead_provider: lead_provider, eligible_for_funding: true)
                                      .count

          not_eligible_count = Application.joins(:user)
                                          .where(lead_provider: lead_provider, eligible_for_funding: false)
                                          .count

          expect(eligible_count).to eq(11) # All except APP-004
          expect(not_eligible_count).to eq(1) # Only APP-004
        end

        it "creates 2 cohorts" do
          expect { seeder.call }.to change(Cohort, :count).by_at_least(2)

          expect(Cohort.find_by(start_year: cohort_year)).to be_present
          expect(Cohort.find_by(start_year: cohort_year + 1)).to be_present
        end

        it "creates 2 course_cohorts" do
          seeder.call

          course = Course.find_by!(identifier: "tte-early-years")
          primary_cohort = Cohort.find_by(start_year: cohort_year)
          secondary_cohort = Cohort.find_by(start_year: cohort_year + 1)

          expect(CourseCohort.find_by(course:, cohort: primary_cohort)).to be_present
          expect(CourseCohort.find_by(course:, cohort: secondary_cohort)).to be_present
        end

        it "creates 11 applications in primary course_cohort and 1 in secondary course_cohort" do
          seeder.call

          course = Course.find_by!(identifier: "tte-early-years")
          primary_course_cohort = CourseCohort.find_by(course:, cohort: Cohort.find_by(start_year: cohort_year))
          secondary_course_cohort = CourseCohort.find_by(course:, cohort: Cohort.find_by(start_year: cohort_year + 1))

          expect(Application.where(course_cohort: primary_course_cohort, lead_provider: lead_provider).count).to eq(11)
          expect(Application.where(course_cohort: secondary_course_cohort, lead_provider: lead_provider).count).to eq(1)
        end

        it "creates 2 statements" do
          expect { seeder.call }.to change(Statement, :count).by(2)
        end

        it "creates statements with correct states" do
          seeder.call

          statements = Statement.where(lead_provider: lead_provider)
          expect(statements.pluck(:state)).to match_array(%w[paid payable])
        end

        it "creates schedules for both cohorts" do
          seeder.call

          expect(Schedule.find_by(identifier: "tte-reception-spring")).to be_present
          expect(Schedule.find_by(identifier: "tte-reception-autumn")).to be_present
        end

        it "creates users with verified TRNs" do
          seeder.call

          users = User.where(email: seeder.test_emails)
          expect(users.pluck(:trn_verified).uniq).to eq([true])
          expect(users.pluck(:trn_lookup_status).uniq).to eq(%w[Found])
        end

        it "creates applications with correct lead provider" do
          seeder.call

          applications = Application.where(lead_provider: lead_provider)
          expect(applications.count).to eq(12)
          expect(applications.pluck(:lead_provider_id).uniq).to eq([lead_provider.id])
        end
      end

      describe "idempotency (running twice)" do
        before do
          seeder.call
        end

        it "deletes and recreates applications" do
          expect { seeder.call }.not_to change(Application, :count)
        end

        it "deletes and recreates users with no other applications" do
          expect { seeder.call }.not_to change(User, :count)
        end

        it "maintains the same test emails" do
          original_emails = Application.joins(:user).where(lead_provider: lead_provider).pluck("users.email")

          seeder.call

          new_emails = Application.joins(:user).where(lead_provider: lead_provider).pluck("users.email")
          expect(new_emails).to match_array(original_emails)
        end

        it "resets all applications to pending status" do
          Application.where(lead_provider: lead_provider).limit(3).update_all(
            status: Application::ACCEPTED,
          )

          seeder.call

          applications = Application.where(lead_provider: lead_provider)
          expect(applications.pluck(:status).uniq).to eq([Application::PENDING])
        end

        it "does not delete users with other applications" do
          # Create another application for one of the test users
          user = User.find_by(email: seeder.test_emails.first)
          other_provider = create(:lead_provider)
          create(:application, user: user, lead_provider: other_provider)

          expect { seeder.call }.to not_change(User, :count)
          expect(user.reload).to be_present
        end
      end

      describe "with different cohort year" do
        let(:cohort_year) { 2027 }

        it "creates cohorts for the specified year" do
          seeder.call

          expect(Cohort.find_by(start_year: 2027)).to be_present
          expect(Cohort.find_by(start_year: 2028)).to be_present
        end

        it "creates statements for the specified year" do
          seeder.call

          statements = Statement.where(lead_provider: lead_provider, year: 2027)
          expect(statements.count).to eq(2)
        end
      end
    end
  end
end
