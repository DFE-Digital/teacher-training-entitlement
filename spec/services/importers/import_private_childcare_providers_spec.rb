require "rails_helper"

RSpec.describe Importers::ImportPrivateChildcareProviders do
  subject do
    described_class.new(
      file_name:,
      csv_row_parser:,
    )
  end

  let(:run_import) { subject.call }

  describe "#call" do
    def find_provider_with_institution(urn)
      institution = Institution.find_by(institution_reference_number: urn)
      provider = institution&.institutionable

      {
        # Provider attributes
        "disabled_at" => provider&.disabled_at,
        "early_years_individual_registers" => provider&.early_years_individual_registers,
        "local_authority" => provider&.local_authority,
        "provider_compulsory_childcare_register_flag" => provider&.provider_compulsory_childcare_register_flag,
        "provider_early_years_register_flag" => provider&.provider_early_years_register_flag,
        "urn" => provider&.urn,
        # Institution attributes
        "name" => institution&.name,
        "address_1" => institution&.address_1,
        "address_2" => institution&.address_2,
        "address_3" => institution&.address_3,
        "town" => institution&.town,
        "postcode" => institution&.postcode,
        "postcode_without_spaces" => institution&.postcode_without_spaces,
        "region" => institution&.region,
      }
    end

    context "private childcare providers" do
      let(:csv_row_parser) { Importers::ImportPrivateChildcareProviders::ChildcareProviderWrappedCSVRow }

      context "with all rows valid" do
        # File contains sample of real data
        let(:file_name) { "spec/fixtures/files/private_childcare_providers_sample.csv" }

        it "imports rows as PrivateChildcareProvider records" do
          expect { run_import }.to change(PrivateChildcareProvider, :count).by(7)

          expect(find_provider_with_institution("520917")).to eq({
            "disabled_at" => nil,
            "early_years_individual_registers" => %w[CCR VCR EYR],
            "local_authority" => "Leeds",
            "provider_compulsory_childcare_register_flag" => true,
            "provider_early_years_register_flag" => true,
            "urn" => "520917",
            "name" => "Rosewood Nursery",
            "address_1" => "21 Roseville Road",
            "address_2" => "Harehills",
            "address_3" => nil,
            "town" => "Leeds",
            "postcode" => "LS8 5DT",
            "postcode_without_spaces" => "LS85DT",
            "region" => "Yorkshire and The Humber",
          })

          expect(find_provider_with_institution("EY790942")).to eq({
            "address_1" => "High Ridge Park",
            "address_2" => "Rothwell",
            "address_3" => nil,
            "disabled_at" => nil,
            "early_years_individual_registers" => %w[CCR],
            "local_authority" => "Leeds",
            "name" => "Daisy Chain Childcare",
            "postcode" => "LS26 0NL",
            "postcode_without_spaces" => "LS260NL",
            "provider_compulsory_childcare_register_flag" => true,
            "provider_early_years_register_flag" => true,
            "region" => "Yorkshire and The Humber",
            "town" => "Leeds",
            "urn" => "EY790942",
          })

          expect(find_provider_with_institution("EY565343")).to eq({
            "address_1" => "34 Church Street",
            "address_2" => "Stapleford",
            "address_3" => nil,
            "disabled_at" => nil,
            "early_years_individual_registers" => %w[CCR VCR],
            "local_authority" => "Nottinghamshire",
            "name" => "Sparkle Daycare",
            "postcode" => "NG9 8DJ",
            "postcode_without_spaces" => "NG98DJ",
            "provider_compulsory_childcare_register_flag" => true,
            "provider_early_years_register_flag" => true,
            "region" => "East Midlands",
            "town" => "NOTTINGHAM",
            "urn" => "EY565343",
          })

          expect(find_provider_with_institution("EY426355")).to eq({
            "address_1" => "The Old Library",
            "address_2" => "Bath Road",
            "address_3" => nil,
            "disabled_at" => nil,
            "early_years_individual_registers" => %w[EYR],
            "local_authority" => "Wiltshire",
            "name" => "Cricklade Preschool Playgroup",
            "postcode" => "SN6 6AT",
            "postcode_without_spaces" => "SN66AT",
            "provider_compulsory_childcare_register_flag" => false,
            "provider_early_years_register_flag" => true,
            "region" => "South West",
            "town" => "Cricklade",
            "urn" => "EY426355",
          })

          expect(find_provider_with_institution("EY426356")).to eq({
            "address_1" => "The Old Library",
            "address_2" => "Bath Road",
            "address_3" => nil,
            "disabled_at" => nil,
            "early_years_individual_registers" => %w[CCR EYR],
            "local_authority" => "Wiltshire",
            "name" => "Cricklade Preschool Playgroup",
            "postcode" => "SN6 6AT",
            "postcode_without_spaces" => "SN66AT",
            "provider_compulsory_childcare_register_flag" => false,
            "provider_early_years_register_flag" => true,
            "region" => "South West",
            "town" => "Cricklade",
            "urn" => "EY426356",
          })

          expect(find_provider_with_institution("EY426357")).to eq({
            "address_1" => "The Old Library",
            "address_2" => "Bath Road",
            "address_3" => nil,
            "disabled_at" => nil,
            "early_years_individual_registers" => %w[VCR EYR],
            "local_authority" => "Wiltshire",
            "name" => "Cricklade Preschool Playgroup",
            "postcode" => "SN6 6AT",
            "postcode_without_spaces" => "SN66AT",
            "provider_compulsory_childcare_register_flag" => false,
            "provider_early_years_register_flag" => false,
            "region" => "South West",
            "town" => "Cricklade",
            "urn" => "EY426357",
          })

          expect(find_provider_with_institution("EY426358")).to eq({
            "address_1" => "The Old Library",
            "address_2" => "Bath Road",
            "address_3" => nil,
            "disabled_at" => nil,
            "early_years_individual_registers" => %w[VCR],
            "local_authority" => "Wiltshire",
            "name" => "Cricklade Preschool Playgroup",
            "postcode" => "SN6 6AT",
            "postcode_without_spaces" => "SN66AT",
            "provider_compulsory_childcare_register_flag" => true,
            "provider_early_years_register_flag" => false,
            "region" => "South West",
            "town" => "Cricklade",
            "urn" => "EY426358",
          })
        end

        it "returns the correct number of imported records" do
          run_import
          expect(subject.imported_records).to eq(7)
        end

        it "returns no errors for invalid rows" do
          run_import
          expect(subject.import_errors).to eq({})
        end

        context "with headers missing" do
          let(:file_name) { "spec/fixtures/files/example_csv.csv" }

          it "raises an error" do
            expect { run_import }.to raise_error(/Header invalid/).and not_change(PrivateChildcareProvider, :count)
          end
        end
      end

      context "with a row that uses a unicode character 'start of guarded area' U+0096 () instead of an en dash (–) in the provider name" do
        # File contains sample of real data
        # also, this file is deliberately encoded in ISO-8859-1, as that what the latest files are
        let(:file_name) { "spec/fixtures/files/private_childcare_providers_sample_wrong_unicode.csv" }

        it "translates the unicode character to an en dash" do
          run_import
          expect(PrivateChildcareProvider.first.name).to eq("Little Tots – Peterborough Mother & Baby Nursery")
        end
      end

      context "with invalid rows" do
        # File contains sample of real data
        let(:file_name) { "spec/fixtures/files/private_childcare_providers_sample_with_errors.csv" }

        it "returns errors for invalid rows" do
          run_import
          expect(subject.import_errors).to eq({
            3 => ["Validation failed: Institution reference number can't be blank"],
            4 => ["Unknown Individual Register combinations value: ABC only"],
          })
        end

        it "imports valid rows" do
          expect { run_import }.to change(PrivateChildcareProvider, :count).by(1)

          expect(find_provider_with_institution("520917")).to eq({
            "address_1" => "21 Roseville Road",
            "address_2" => "Harehills",
            "address_3" => nil,
            "disabled_at" => nil,
            "early_years_individual_registers" => %w[CCR VCR EYR],
            "local_authority" => "Leeds",
            "postcode" => "LS8 5DT",
            "postcode_without_spaces" => "LS85DT",
            "provider_compulsory_childcare_register_flag" => true,
            "provider_early_years_register_flag" => true,
            "name" => "Rosewood Nursery",
            "urn" => "520917",
            "region" => "Yorkshire and The Humber",
            "town" => "Leeds",
          })
        end

        it "returns the correct number of imported records" do
          run_import
          expect(subject.imported_records).to eq(1)
        end
      end

      context "with records that already exist" do
        let(:file_name) { "spec/fixtures/files/private_childcare_providers_sample.csv" }

        # the update file is the same as the import but the first two records have been changed
        let(:updates) do
          described_class.new(
            file_name: "spec/fixtures/files/private_childcare_providers_sample_with_updates.csv",
            csv_row_parser:,
          )
        end

        let(:run_update) { updates.call }

        before { run_import }

        it "makes the correct number of updates" do
          run_update
          expect(updates.updated_records).to be(2)
        end

        it "doesn't reinsert existing records" do
          run_update
          expect(updates.imported_records).to be(0)
        end

        it "makes the updates correctly" do
          expect(find_provider_with_institution("520917")).to eq({
            "provider_compulsory_childcare_register_flag" => true,
            "provider_early_years_register_flag" => true,
            "address_1" => "21 Roseville Road",
            "address_2" => "Harehills",
            "address_3" => nil,
            "disabled_at" => nil,
            "early_years_individual_registers" => %w[CCR VCR EYR],
            "local_authority" => "Leeds",
            "postcode" => "LS8 5DT",
            "postcode_without_spaces" => "LS85DT",
            "name" => "Rosewood Nursery",
            "urn" => "520917",
            "region" => "Yorkshire and The Humber",
            "town" => "Leeds",
          })

          expect(find_provider_with_institution("EY790942")).to eq({
            "provider_compulsory_childcare_register_flag" => true,
            "provider_early_years_register_flag" => true,
            "address_1" => "High Ridge Park",
            "address_2" => "Rothwell",
            "address_3" => nil,
            "disabled_at" => nil,
            "early_years_individual_registers" => %w[CCR],
            "local_authority" => "Leeds",
            "name" => "Daisy Chain Childcare",
            "postcode" => "LS26 0NL",
            "postcode_without_spaces" => "LS260NL",
            "region" => "Yorkshire and The Humber",
            "town" => "Leeds",
            "urn" => "EY790942",
          })

          run_update

          expect(find_provider_with_institution("520917")).to eq({
            "provider_compulsory_childcare_register_flag" => false,
            "provider_early_years_register_flag" => false,
            "address_1" => "21 Roseville Road",
            "address_2" => "Harehills",
            "address_3" => nil,
            "disabled_at" => nil,
            "early_years_individual_registers" => %w[CCR VCR EYR],
            "local_authority" => "Leeds",
            "postcode" => "LS8 5DT",
            "postcode_without_spaces" => "LS85DT",
            "name" => "Rosewood Nursery",
            "urn" => "520917",
            "region" => "Yorkshire and The Humber",
            "town" => "Leeds",
          })

          expect(find_provider_with_institution("EY790942")).to eq({
            "provider_compulsory_childcare_register_flag" => false,
            "provider_early_years_register_flag" => false,
            "address_1" => "High Ridge Park",
            "address_2" => "Rothwell",
            "address_3" => nil,
            "disabled_at" => nil,
            "early_years_individual_registers" => %w[CCR],
            "local_authority" => "Leeds",
            "name" => "Daisy Chain Childcare",
            "postcode" => "LS26 0NL",
            "postcode_without_spaces" => "LS260NL",
            "region" => "Yorkshire and The Humber",
            "town" => "Leeds",
            "urn" => "EY790942",
          })
        end
      end
    end

    context "private childminder agencies" do
      let(:csv_row_parser) { Importers::ImportPrivateChildcareProviders::ChildminderAgencyWrappedCSVRow }

      context "with all rows valid" do
        # File contains sample of real data
        let(:file_name) { "spec/fixtures/files/private_childminder_agencies_sample.csv" }

        it "returns no errors" do
          run_import
          expect(subject.import_errors).to eq({})
        end

        it "imports rows as PrivateChildcareProvider records" do
          expect { run_import }.to change(PrivateChildcareProvider, :count).by(10)

          expect(find_provider_with_institution("CA000006")).to eq({
            "address_1" => "108 Regent Studios",
            "address_2" => "1 Thane Villas",
            "address_3" => "London",
            "disabled_at" => nil,
            "early_years_individual_registers" => %w[CCR VCR EYR],
            "local_authority" => "Islington",
            "postcode" => "N7 7PH",
            "postcode_without_spaces" => "N77PH",
            "provider_compulsory_childcare_register_flag" => nil,
            "provider_early_years_register_flag" => nil,
            "name" => "Daryel Care",
            "urn" => "CA000006",
            "region" => nil,
            "town" => nil,
          })
          expect(find_provider_with_institution("CA000012")).to eq({
            "address_1" => "157 - 159 St. Barnabas Road",
            "address_2" => "Woodford Green",
            "address_3" => "Essex",
            "disabled_at" => nil,
            "early_years_individual_registers" => %w[CCR VCR EYR],
            "local_authority" => "Redbridge",
            "postcode" => "IG8 7DG",
            "postcode_without_spaces" => "IG87DG",
            "provider_compulsory_childcare_register_flag" => nil,
            "provider_early_years_register_flag" => nil,
            "name" => "City Childcare Childminding Agency",
            "urn" => "CA000012",
            "region" => nil,
            "town" => nil,
          })
        end

        it "strips whitespace (including unicode non-breaking spaces) from the postcode" do
          run_import

          expect(find_provider_with_institution("CA000026")).to include({
            "postcode" => "IP13 0RD",
            "postcode_without_spaces" => "IP130RD",
          })
        end

        it "returns the correct number of imported records" do
          run_import
          expect(subject.imported_records).to eq(10)
        end

        context "with headers missing" do
          let(:file_name) { "spec/fixtures/files/example_csv.csv" }

          it "raises an error" do
            expect { run_import }.to raise_error(/Header invalid/).and not_change(PrivateChildcareProvider, :count)
          end
        end
      end

      context "with invalid rows" do
        # File contains sample of real data
        let(:file_name) { "spec/fixtures/files/private_childminder_agencies_sample_with_errors.csv" }

        it "returns errors for invalid rows" do
          run_import
          expect(subject.import_errors).to eq({
            3 => ["Validation failed: Institution reference number can't be blank"],
            4 => ["Unknown Individual Register combinations value: EYR"],
          })
        end

        it "imports valid rows" do
          expect { run_import }.to change(PrivateChildcareProvider, :count).by(1)

          expect(find_provider_with_institution("CA000006")).to eq({
            "address_1" => "108 Regent Studios",
            "address_2" => "1 Thane Villas",
            "address_3" => "London",
            "disabled_at" => nil,
            "early_years_individual_registers" => %w[CCR VCR EYR],
            "local_authority" => "Islington",
            "postcode" => "N7 7PH",
            "postcode_without_spaces" => "N77PH",
            "provider_compulsory_childcare_register_flag" => nil,
            "provider_early_years_register_flag" => nil,
            "name" => "Daryel Care",
            "urn" => "CA000006",
            "region" => nil,
            "town" => nil,
          })
        end

        it "returns the correct number of imported records" do
          run_import
          expect(subject.imported_records).to eq(1)
        end
      end

      context "with records that already exist" do
        let(:file_name) { "spec/fixtures/files/private_childminder_agencies_sample.csv" }

        # the update file is the same as the import but the first record has been changed
        let(:updates) do
          described_class.new(
            file_name: "spec/fixtures/files/private_childminder_agencies_sample_with_updates.csv",
            csv_row_parser:,
          )
        end

        let(:run_update) { updates.call }

        before { run_import }

        it "makes the correct number of updates" do
          # Address changes are on Institution now, so PrivateChildcareProvider
          # model itself isn't updated - only institution is updated
          expect {
            run_update
          }.to change {
            Institution.find_by(institution_reference_number: "CA000006").institutionable.institution.address_1
          }.from("108 Regent Studios").to("109 Regent Studios")

          expect(updates.updated_records).to be(0)
        end

        it "doesn't reinsert existing records" do
          run_update

          expect(updates.imported_records).to be(0)
        end

        it "makes the updates correctly" do
          expect(find_provider_with_institution("CA000006")).to eq({
            "address_1" => "108 Regent Studios",
            "address_2" => "1 Thane Villas",
            "address_3" => "London",
            "disabled_at" => nil,
            "early_years_individual_registers" => %w[CCR VCR EYR],
            "local_authority" => "Islington",
            "postcode" => "N7 7PH",
            "postcode_without_spaces" => "N77PH",
            "provider_compulsory_childcare_register_flag" => nil,
            "provider_early_years_register_flag" => nil,
            "name" => "Daryel Care",
            "urn" => "CA000006",
            "region" => nil,
            "town" => nil,
          })

          run_update

          expect(find_provider_with_institution("CA000006")).to eq({
            "address_1" => "109 Regent Studios", # changed in updates csv
            "address_2" => "1 Thane Villas",
            "address_3" => "London",
            "disabled_at" => nil,
            "early_years_individual_registers" => %w[CCR VCR EYR],
            "local_authority" => "Islington",
            "postcode" => "N7 7PH",
            "postcode_without_spaces" => "N77PH",
            "provider_compulsory_childcare_register_flag" => nil,
            "provider_early_years_register_flag" => nil,
            "name" => "Daryel Care",
            "urn" => "CA000006",
            "region" => nil,
            "town" => nil,
          })
        end
      end
    end

    context "with file that doesn't exist" do
      let(:file_name) { "spec/fixtures/files/fake_file.csv" }
      let(:csv_row_parser) { Importers::ImportPrivateChildcareProviders::ChildcareProviderWrappedCSVRow }

      it "returns an error and creates no records" do
        expect {
          expect { run_import }.to(raise_error(RuntimeError, "File not found: #{file_name}"))
        }.not_to(change(PrivateChildcareProvider, :count))

        expect(subject.imported_records).to eq(0)
      end
    end
  end
end
