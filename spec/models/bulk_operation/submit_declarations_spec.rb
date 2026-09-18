require "rails_helper"

RSpec.describe BulkOperation::SubmitDeclarations do
  let(:admin) { create(:admin) }
  let(:bulk_operation) { create(:submit_declarations_bulk_operation, admin:) }
  let(:contract) { create(:course_cohort_provider) }
  let(:course_cohort) { contract.course_cohort }
  let(:lead_provider) { contract.lead_provider }
  let(:milestone) do
    course_cohort.course.milestones.find_or_initialize_by(declaration_type: Milestone::STARTED).tap do |milestone|
      milestone.update!(acceptance_window_start_offset: 0, acceptance_window_end_offset: 1)
    end
  end
  let(:declaration_date) { milestone.acceptance_window_start_date_for(training_starts_at: application.training_starts_at) + 1.day }
  let(:delivery_partner) do
    create(:delivery_partner, lead_providers: { course_cohort.cohort => lead_provider })
  end
  let(:csv_headers) { described_class::FILE_HEADERS.join(",") }
  let(:csv_row) do
    [
      application.lead_provider.name,
      application.ecf_id,
      milestone.declaration_type,
      declaration_date.rfc3339,
      delivery_partner.ecf_id,
    ].join(",")
  end
  let(:csv_file) do
    tempfile <<~CSV
      #{csv_headers}
      #{csv_row}
    CSV
  end

  let!(:application) { create(:application, :accepted, course_cohort:, lead_provider:) }

  describe "validations" do
    before { bulk_operation.file.attach(csv_file.open) }

    context "with valid CSV file" do
      it { expect(bulk_operation).to be_valid }
    end

    context "with invalid CSV format" do
      let(:csv_headers) { "wrong,headers,in,csv,file,here" }

      it do
        expect(bulk_operation).not_to be_valid
        expect(bulk_operation.errors[:file]).to include("Uploaded file is wrong format")
      end
    end
  end

  describe "#run!" do
    subject(:run) { bulk_operation.run! }

    let(:csv_file) do
      tempfile <<~CSV
        #{csv_headers}
        #{csv_row}
        #{csv_second_row}
      CSV
    end
    let(:csv_second_row) do
      [
        application2.lead_provider.name,
        application2.ecf_id,
        milestone.declaration_type,
        declaration_date.rfc3339,
        delivery_partner.ecf_id,
      ].join(",")
    end
    let(:result) { JSON.parse(bulk_operation.reload.result) }
    let!(:application2) { create(:application, :accepted, course_cohort:, lead_provider:) }

    before do
      bulk_operation.file.attach(csv_file.open)
      bulk_operation.save!
      run
    end

    context "when the entire CSV is valid" do
      it "saves successful results for all rows" do
        expect(result["1"]).to eq("Declaration created successfully")
        expect(result["2"]).to eq("Declaration created successfully")
      end

      it "creates declarations with correct attributes" do
        declaration1 = Declaration.find_by(application: application)
        declaration2 = Declaration.find_by(application: application2)

        expect(declaration1.declaration_type).to eq("started")
        expect(declaration1.delivery_partner).to eq(delivery_partner)
        expect(declaration2.declaration_type).to eq("started")
        expect(declaration2.delivery_partner).to eq(delivery_partner)
      end
    end

    context "when some rows are invalid" do
      let(:csv_second_row) do
        [
          application2.lead_provider.name,
          "error",
          milestone.declaration_type,
          declaration_date.rfc3339,
          delivery_partner.ecf_id,
        ].join(",")
      end

      it { expect(bulk_operation.reload.finished_at).to be_present }

      it "records both success and failure results" do
        expect(result["1"]).to eq("Declaration created successfully")
        expect(result["2"]).to eq("Application not found")
      end
    end

    context "when lead provider does not exist" do
      let(:csv_row) do
        [
          "not a lead provider name",
          application.ecf_id,
          "other",
          declaration_date,
          delivery_partner.ecf_id,
        ].join(",")
      end

      it { expect(result["1"]).to eq("Lead provider not found") }
    end

    context "when declaration service validation fails" do
      let(:csv_row) do
        [
          application.lead_provider.name,
          application.ecf_id,
          "other",
          declaration_date,
          delivery_partner.id,
        ].join(",")
      end

      it do
        expect(result["1"]).to include("The entered '#/declaration_type' is not recognised")
      end
    end
  end
end
