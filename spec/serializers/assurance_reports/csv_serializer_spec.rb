# frozen_string_literal: true

require "rails_helper"

RSpec.describe AssuranceReports::CsvSerializer, type: :serializer do
  subject(:instance) { described_class.new(statement) }

  before { declaration }

  let(:lead_provider) { create(:lead_provider) }
  let(:statement)     { create(:statement, lead_provider:) }
  let(:declaration) { create(:declaration, statement:) }
  let(:period) do
    [
      statement.start_date.to_fs(:govuk_short),
      statement.deadline_date.to_fs(:govuk_short),
    ].join("-")
  end

  describe "#filename" do
    subject { instance.filename }

    let(:name) do
      statement.lead_provider.name.gsub(/\W/, "")
    end

    it { is_expected.to match(%r{TTE-Declarations-#{name}-#{period.gsub(/\W/, "")}\.csv}) }
  end

  describe "#serialize" do
    let(:rows) { CSV.parse(instance.serialize, headers: true).to_a }

    describe "header row" do
      subject { rows.first }

      let :expected_headers do
        [
          "Participant ID",
          "Participant Name",
          "TRN",
          "Course Identifier",
          "Cohort",
          "Eligible For Funding",
          "Funded place",
          "Lead Provider Name",
          "School Urn",
          "School Name",
          "Status",
          "Status Reason",
          "Declaration ID",
          "Declaration Status",
          "Declaration Type",
          "Declaration Date",
          "Declaration Created At",
          "Statement Period",
          "Statement ID",
        ]
      end

      it { is_expected.to eq expected_headers }
    end

    describe "a data row" do
      subject { rows.second }

      let(:status)        { Application::ACCEPTED }
      let(:status_reason) { nil }

      let :expected_data do
        [
          declaration.user.ecf_id,
          declaration.user.full_name,
          declaration.user.trn,
          declaration.course.identifier,
          declaration.application.cohort.description,
          declaration.application.eligible_for_funding.to_s,
          declaration.application.funded_place.to_s,
          lead_provider.name,
          declaration.application.school.urn,
          declaration.application.school.name,
          status,
          status_reason,
          declaration.ecf_id,
          declaration.state,
          declaration.declaration_type,
          declaration.declaration_date.iso8601,
          declaration.created_at.iso8601,
          period,
          statement.ecf_id,
        ]
      end

      it { is_expected.to eq expected_data }

      context "when withdrawn" do
        before do
          declaration.application.update_columns(status: Application::WITHDRAWN)

          create(:state_change, :withdrawn, application: declaration.application,
                                            lead_provider: declaration.lead_provider)
        end

        let(:status)        { Application::WITHDRAWN }
        let(:status_reason) { "other" }

        it { is_expected.to eq expected_data }
      end

      context "when deferred" do
        before do
          declaration.application.update_columns(status: Application::DEFERRED)

          create(:state_change, :deferred, application: declaration.application,
                                           lead_provider: declaration.lead_provider)
        end

        let(:status) { Application::DEFERRED }
        let(:status_reason) { "other" }

        it { is_expected.to eq expected_data }
      end
    end
  end
end
