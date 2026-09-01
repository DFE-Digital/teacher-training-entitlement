# frozen_string_literal: true

require "rails_helper"

RSpec.describe CourseCohorts::SetupForm, type: :model do
  subject(:form) do
    described_class.new(
      cohort:,
      course_id:,
      training_starts_at:,
      training_ends_at:,
      lead_providers:,
    )
  end

  let(:cohort) { create(:cohort, registration_starts_at: Date.new(2027, 9, 1)) }
  let(:course) { create(:course) }
  let(:course_id) { course.id }
  let(:training_starts_at) { { 1 => 2027, 2 => 9, 3 => 1 } }
  let(:training_ends_at) { nil }
  let(:lead_provider) { create(:lead_provider) }
  let(:lead_providers) do
    { lead_provider.id.to_s => { "id" => lead_provider.id.to_s, "contract" => "1000" } }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:cohort) }
    it { is_expected.to validate_presence_of(:course_id) }

    describe "#valid_training_dates" do
      context "with a valid training start date" do
        it "does not add an error on training_starts_at" do
          form.valid?

          expect(form.errors[:training_starts_at]).to be_empty
        end
      end

      context "with no training end date" do
        it "does not add an error on training_ends_at" do
          form.valid?

          expect(form.errors[:training_ends_at]).to be_empty
        end
      end

      context "with an invalid training start date" do
        let(:training_starts_at) { "not-a-date" }

        it "adds an error on training_starts_at" do
          form.valid?

          expect(form.errors[:training_starts_at]).to include("Enter a valid date")
        end
      end

      context "with an invalid training end date" do
        let(:training_ends_at) { "not-a-date" }

        it "adds an error on training_ends_at" do
          form.valid?

          expect(form.errors[:training_ends_at]).to include("Enter a valid date")
        end
      end
    end

    describe "#at_least_one_lead_provider_selected" do
      context "when no lead providers are selected" do
        let(:lead_providers) { {} }

        it "adds an error on lead_providers" do
          form.valid?

          expect(form.errors[:lead_providers]).to include("Select at least one lead provider")
        end
      end

      context "when at least one lead provider is selected" do
        it "does not add an error on lead_providers" do
          form.valid?

          expect(form.errors[:lead_providers]).to be_empty
        end
      end
    end
  end

  describe "#course_options" do
    let!(:existing_course) { create(:course, name: "Existing course") }
    let!(:apple_course) { create(:course, name: "Apple course") }
    let!(:zebra_course) { create(:course, name: "Zebra course") }

    before do
      create(:course_cohort, cohort:, course: existing_course)
    end

    it "returns courses not already assigned to the cohort, ordered by name" do
      names = form.course_options.map(&:name)

      expect(names).to include(apple_course.name, zebra_course.name)
      expect(names).not_to include(existing_course.name)
      expect(names).to eq(names.sort)
    end
  end

  describe "#lead_provider_options" do
    it "returns all lead providers" do
      expect(form.lead_provider_options).to match_array(LeadProvider.all)
    end
  end

  describe "#selected_lead_providers" do
    let(:selected_provider) { create(:lead_provider) }
    let(:another_provider) { create(:lead_provider) }
    let(:lead_providers) do
      {
        selected_provider.id.to_s => { "id" => selected_provider.id.to_s, "contract" => "1000" },
        another_provider.id.to_s => { "id" => another_provider.id.to_s, "contract" => "2000" },
        "0" => { "id" => "0" },
        "blank" => { "id" => "" },
      }
    end

    it "returns a [lead_provider, contract] pair for each selected provider" do
      expect(form.selected_lead_providers).to contain_exactly(
        [selected_provider, { "id" => selected_provider.id.to_s, "contract" => "1000" }],
        [another_provider, { "id" => another_provider.id.to_s, "contract" => "2000" }],
      )
    end

    it "ignores unselected and blank entries" do
      selected_ids = form.selected_lead_providers.map { |provider, _contract| provider.id }

      expect(selected_ids).to contain_exactly(selected_provider.id, another_provider.id)
    end
  end

  describe "#selected_course" do
    context "when a course matches the given course_id" do
      it "returns the course" do
        expect(form.selected_course).to eq(course)
      end
    end

    context "when no course matches the given course_id" do
      let(:course_id) { 0 }

      it "returns nil" do
        expect(form.selected_course).to be_nil
      end
    end
  end

  describe "#training_dates" do
    let(:training_starts_at) { { 1 => 2027, 2 => 9, 3 => 1 } }
    let(:training_ends_at) { { 1 => 2028, 2 => 7, 3 => 31 } }

    it "returns a hash of the start and end training dates" do
      expect(form.training_dates).to eq(
        start: Date.new(2027, 9, 1),
        end: Date.new(2028, 7, 31),
      )
    end
  end
end
