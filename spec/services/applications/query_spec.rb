require "rails_helper"

RSpec.describe Applications::Query do
  subject(:query) do
    described_class.new(
      lead_provider:,
      cohort_start_years:,
      updated_since:,
      status:,
      participant_ids:,
      sort:,
    )
  end

  let(:lead_provider) { create(:lead_provider) }
  let(:updated_since) { :ignore }
  let(:cohort_start_years) { :ignore }
  let(:status) { :ignore }
  let(:participant_ids) { :ignore }
  let(:sort) { nil }

  describe "#applications" do
    it "returns all applications" do
      application1 = create(:application, lead_provider:)
      application2 = create(:application, lead_provider:)

      expect(query.applications).to contain_exactly(application1, application2)
    end

    it "orders applications by created_at in ascending order" do
      application1 = create(:application, lead_provider:)
      application2 = travel_to(1.hour.ago) { create(:application, lead_provider:) }
      application3 = travel_to(1.minute.ago) { create(:application, lead_provider:) }

      expect(query.applications).to eq([application2, application3, application1])
    end

    describe "filtering" do
      describe "updated since" do
        context "with date in the past" do
          let(:updated_since) { 1.day.ago }

          it "filters by updated since" do
            travel_to(2.days.ago) { create(:application, lead_provider:) }

            application = create(:application, lead_provider:, updated_at: Time.zone.now)
            application.user.update!(updated_at: 2.days.ago)

            expect(query.applications).to contain_exactly(application)
          end
        end
      end

      context "when filtering by cohort" do
        let(:cohort_2023) { create(:cohort, registration_starts_at: Date.new(2023, 4, 1)) }
        let(:cohort_2024) { create(:cohort, registration_starts_at: Date.new(2024, 4, 1)) }
        let(:cohort_2025) { create(:cohort, registration_starts_at: Date.new(2025, 4, 1)) }

        context "when 2024" do
          let(:cohort_start_years) { "2024" }

          it "filters by cohort" do
            create(:application, cohort: cohort_2023)
            application = create(:application, lead_provider:, cohort: cohort_2024)
            expect(query.applications).to contain_exactly(application)
          end
        end

        context "when 2023,2024" do
          let(:cohort_start_years) { "2023,2024" }

          it "filters by multiple cohorts" do
            application1 = create(:application, lead_provider:, cohort: cohort_2023)
            application2 = create(:application, lead_provider:, cohort: cohort_2024)
            create(:application, cohort: cohort_2025)

            expect(query.applications).to contain_exactly(application1, application2)
          end
        end

        context "when 000" do
          let(:cohort_start_years) { "000" }

          it { expect(query.applications).to be_empty }
        end

        context "when not supplied" do
          it { expect(query.scope.to_sql).not_to include(%("cohort"."start_year")) }
        end
      end

      context "when filtering by status" do
        let(:status) { Application::ACCEPTED }

        it "filters by status" do
          create(:application, :pending, lead_provider:)
          application = create(:application, :accepted, lead_provider:)
          expect(query.applications).to contain_exactly(application)
        end

        context "with multiple values" do
          let(:status) { [Application::ACCEPTED, Application::REJECTED] }

          it "filters by multiple status" do
            application1 = create(:application, :accepted, lead_provider:)
            application2 = create(:application, :rejected, lead_provider:)
            create(:application, :pending, lead_provider:)

            expect(query.applications).to contain_exactly(application1, application2)
          end
        end

        context "with bad value" do
          let(:status) { "unknown" }

          it { expect(query.applications).to be_empty }
        end

        context "when not supplied" do
          it { expect(query.scope.to_sql).to include(%("status")) }
        end

        context "when filtering by reassigned" do
          let!(:reassigned_application) do
            create(:application, :with_application_lead_provider,
                   lead_provider: create(:lead_provider),
                   old_lead_provider: lead_provider)
          end
          let!(:pending_application) { create(:application, :pending, lead_provider:) }
          let!(:accepted_application) { create(:application, :accepted, lead_provider:) }

          context "when just reassigned" do
            let(:status) { Application::REASSIGNED }

            it do
              expect(subject.applications).to contain_exactly(reassigned_application)
            end
          end

          context "when reassigned and also another status" do
            let(:status) { [Application::PENDING, Application::REASSIGNED] }

            it do
              expect(subject.applications).to contain_exactly(pending_application, reassigned_application)
            end
          end

          context "when reassigned and also two other statuses" do
            let(:status) { [Application::PENDING, Application::REASSIGNED, Application::ACCEPTED] }

            it do
              expect(subject.applications).to contain_exactly(pending_application, reassigned_application, accepted_application)
            end
          end
        end
      end

      context "when filtering by participant_id" do
        let(:user) { create(:user) }

        context "with valid id" do
          let(:application) { create(:application, lead_provider:, user:) }
          let(:participant_ids) { application.user.ecf_id }

          it "filters by participant_id" do
            create(:application, user:)

            expect(query.applications).to contain_exactly(application)
          end
        end

        context "with multiple values" do
          let(:applications) { create_list(:application, 2, lead_provider:, user:) }
          let(:participant_ids) { applications.map { _1.user.ecf_id } }

          it "filters by multiple participant_ids" do
            create(:application, user:)

            expect(query.applications).to match_array(applications)
          end
        end

        context "with unknown value" do
          let(:participant_ids) { SecureRandom.uuid }

          it { expect(query.applications).to be_empty }
        end

        context "when not supplied" do
          it {
            expect(query.scope.to_sql).not_to include(%("ecf_id"))
          }
        end
      end

      context "when filtering by lead_provider" do
        include_context "with application which changed provider"

        context "when lead provider is current provider" do
          let(:lead_provider) { current_lead_provider }

          it "includes the application" do
            expect(application.application_lead_providers.map(&:lead_provider_id).sort)
              .to eq([current_lead_provider.id, old_lead_provider.id].sort)
            expect(query.applications).to contain_exactly(application)
          end
        end

        context "when lead provider is no longer the current provider" do
          let(:lead_provider) { old_lead_provider }

          it "includes the application" do
            expect(application.application_lead_providers.map(&:lead_provider_id).sort)
              .to eq([current_lead_provider.id, old_lead_provider.id].sort)
            expect(query.applications).to contain_exactly(application)
          end
        end

        context "when lead provider has never been the provider" do
          let(:lead_provider) { create(:lead_provider) }

          it "does not include the application" do
            expect(application.application_lead_providers.map(&:lead_provider_id).sort)
              .to eq([current_lead_provider.id, old_lead_provider.id].sort)
            expect(query.applications).to be_blank
          end
        end
      end
    end

    describe "sorting" do
      let!(:application1) { travel_to(1.month.ago) { create(:application, lead_provider:) } }
      let!(:application2) { travel_to(1.week.ago) { create(:application, lead_provider:) } }
      let!(:application3) { create(:application, lead_provider:) }
      let(:sort) { nil }

      subject(:applications) { query.applications }

      it { is_expected.to eq([application1, application2, application3]) }

      context "when sorting by created at, descending" do
        let(:sort) { "-created_at" }

        it { is_expected.to eq([application3, application2, application1]) }
      end

      context "when sorting by updated at, ascending" do
        let(:sort) { "+updated_at" }

        before do
          application1.update!(updated_at: 1.day.from_now)
          application2.update!(updated_at: 2.days.from_now)
        end

        it { is_expected.to eq([application3, application1, application2]) }
      end

      context "when sorting by multiple attributes" do
        let(:sort) { "+updated_at,-created_at" }

        before do
          application1.update!(updated_at: 1.day.from_now)
          application2.update!(updated_at: application1.updated_at)
          application3.update!(updated_at: 2.days.from_now)

          application2.update!(created_at: 1.day.from_now)
          application1.update!(created_at: 1.day.ago)
        end

        it { expect(applications).to eq([application2, application1, application3]) }
      end
    end
  end

  describe "#application" do
    let(:lead_provider) { create(:lead_provider) }

    it "raises an error if no `id` or `ecf_id` is provided" do
      expect { query.application }.to raise_error(ArgumentError).with_message("id or ecf_id needed")
    end

    it "returns the application using the `id`" do
      application = create(:application, lead_provider:)

      expect(query.application(id: application.id)).to eq(application)
    end

    it "returns the application using the `ecf_id`" do
      application = create(:application, lead_provider:)

      expect(query.application(ecf_id: application.ecf_id)).to eq(application)
    end

    it "raises an error if the application does not exist" do
      expect { query.application(id: "XXX123") }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises an error if the application is not in the filtered query" do
      other_lead_provider = create(:lead_provider)
      other_application = create(:application, lead_provider: other_lead_provider)

      expect { query.application(ecf_id: other_application.ecf_id) }.to raise_error(ActiveRecord::RecordNotFound)
      expect { query.application(id: other_application.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
