require "rails_helper"

RSpec.describe API::DeclarationSerializer, type: :serializer do
  let(:declaration) do
    create(:declaration,
           application:,
           delivery_partner:,
           secondary_delivery_partner:)
  end

  let(:application) { create(:application, :accepted, :for_cohort_starting_on, registration_starts_at: Date.new(2021, 4, 1)) }
  let(:cohort) { application.cohort }
  let(:lead_provider) { application.lead_provider }
  let(:delivery_partner) do
    create(:delivery_partner, lead_providers: { cohort => lead_provider })
  end
  let(:secondary_delivery_partner) do
    create(:delivery_partner, lead_providers: { cohort => lead_provider })
  end

  describe "core attributes" do
    subject(:response) { JSON.parse(described_class.render(declaration)) }

    it "serializes the `id`" do
      declaration.ecf_id = "fe1a5280-1b13-4b09-b9c7-e2b01d37e851"

      expect(response["id"]).to eq("fe1a5280-1b13-4b09-b9c7-e2b01d37e851")
    end

    it "serializes the `type`" do
      response = JSON.parse(described_class.render(declaration))

      expect(response["type"]).to eq("declaration")
    end
  end

  describe "nested attributes" do
    %i[v1].each do |view|
      context "when serializing the `#{view}` view" do
        subject(:attributes) { JSON.parse(described_class.render(declaration, view:))["attributes"] }

        it "serializes the `participant_id`" do
          expect(attributes["participant_id"]).to eq(declaration.application.user.ecf_id)
        end

        it "serializes the `declaration_type`" do
          expect(attributes["declaration_type"]).to eq(declaration.declaration_type)
        end

        it "serializes the `course_identifier`" do
          expect(attributes["course_identifier"]).to eq(declaration.application.course.identifier)
        end

        it "serializes the `declaration_date`" do
          expect(attributes["declaration_date"]).to eq(declaration.declaration_date.rfc3339)
        end

        it "serializes the `updated_at`" do
          expect(attributes["updated_at"]).to eq(declaration.updated_at.rfc3339)
        end

        context "when declaration.updated_at is not the latest" do
          let(:old_datetime) { Time.utc(2023, 5, 5, 5, 0, 0) }
          let(:latest_datetime) { Time.utc(2024, 8, 8, 8, 0, 0) }

          before do
            travel_to(old_datetime) do
              declaration
              create(:participant_outcome, declaration:)
            end
          end

          context "when a linked statement item is moved to another statement" do
            let!(:statement_item) { create(:statement_item, declaration:) }

            before do
              travel_to(latest_datetime) do
                statement_item.update!(statement: create(:statement))
              end
            end

            it "returns the updated declaration's `updated_at`" do
              expect(attributes["updated_at"]).to eq(latest_datetime.rfc3339)
            end
          end
        end

        it "serializes the `state`" do
          expect(attributes["state"]).to eq(declaration.state)
        end

        context "when there is no participant outcome" do
          it "serializes `has_passed`" do
            expect(attributes["has_passed"]).to be_nil
          end
        end

        context "when there are participant outcomes" do
          let!(:voided_outcome) { create(:participant_outcome, :voided, declaration:) }
          let!(:passed_outcome) { create(:participant_outcome, :passed, declaration:) }
          let!(:failed_outcome) { create(:participant_outcome, :failed, declaration:) }

          context "when the latest outcome is voided" do
            before { voided_outcome.update!(created_at: 1.day.from_now) }

            it "serializes `has_passed`" do
              expect(attributes["has_passed"]).to be_nil
            end
          end

          context "when the latest outcome has passed" do
            before { passed_outcome.update!(created_at: 1.day.from_now) }

            it "serializes `has_passed`" do
              expect(attributes["has_passed"]).to be(true)
            end
          end

          context "when the latest outcome has failed" do
            before { failed_outcome.update!(created_at: 1.day.from_now) }

            it "serializes `has_passed`" do
              expect(attributes["has_passed"]).to be(false)
            end
          end
        end
      end
    end

    context "when serializing the `v1` view" do
      subject(:attributes) { JSON.parse(described_class.render(declaration, view: :v1))["attributes"] }

      it "serializes the `application_id`" do
        expect(attributes["application_id"]).to eq(application.ecf_id)
      end

      it "serializes the `delivery_partner_id`" do
        expect(attributes["delivery_partner_id"]).to eq(delivery_partner.ecf_id)
      end

      it "serializes the `delivery_partner_name`" do
        expect(attributes["delivery_partner_name"]).to eq(delivery_partner.name)
      end

      it "serializes the `secondary_delivery_partner_id`" do
        expect(attributes["secondary_delivery_partner_id"]).to eq(secondary_delivery_partner.ecf_id)
      end

      it "serializes the `secondary_delivery_partner_name`" do
        expect(attributes["secondary_delivery_partner_name"]).to eq(secondary_delivery_partner.name)
      end

      it "serializes the `created_at`" do
        expect(attributes["created_at"]).to eq(declaration.created_at.rfc3339)
      end

      it "serializes the `uplift_paid`" do
        expect(attributes["uplift_paid"]).to eq(declaration.uplift_paid?)
      end

      it "serializes the `ineligible_for_funding_reason`" do
        expect(attributes["ineligible_for_funding_reason"]).to eq(declaration.ineligible_for_funding_reason)
      end

      it "serializes the `clawback_declaration_id`" do
        expect(attributes["clawback_declaration_id"]).to be_nil
      end

      it "serializes the `paid_declaration_id`" do
        expect(attributes["paid_declaration_id"]).to be_nil
      end

      context "when paid declaration is clawed back" do
        let(:declaration) { create(:declaration, :voided_paid) }

        it "serializes the `clawback_declaration_id`" do
          expect(attributes["clawback_declaration_id"]).to eq(declaration.clawback_declaration.ecf_id)
          expect(attributes["paid_declaration_id"]).to be_nil
        end
      end

      context "when it is a clawback_declaration" do
        let(:declaration) { create(:clawback_declaration) }

        it "serializes the `clawback_declaration_id`" do
          expect(attributes["clawback_declaration_id"]).to be_nil
          expect(attributes["paid_declaration_id"]).to eq(declaration.paid_declaration.ecf_id)
        end
      end

      it "serializes the `lead_provider_name`" do
        expect(attributes["lead_provider_name"]).to eq(declaration.lead_provider.name)
      end
    end
  end
end
