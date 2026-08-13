# frozen_string_literal: true

require "rails_helper"

RSpec.describe DeclarationDateValidator do
  let(:model_class) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Validations
      include ActiveModel::Attributes

      attribute :declaration_date, :datetime
      attr_reader :raw_declaration_date

      validates :declaration_date, declaration_date: true

      def declaration_date=(raw_date)
        self.raw_declaration_date = raw_date
        super
      end

    private

      attr_writer :raw_declaration_date
    end
  end

  let(:declaration_date) { Date.new(2022, 1, 30) }

  subject { model_class.new(declaration_date: declaration_date.rfc3339) }

  describe "#declaration_date" do
    describe "the declaration date has the right format" do
      context "when the declaration date is empty" do
        subject { model_class.new(declaration_date: "") }

        it "does not error when the declaration date is blank" do
          expect(subject).to be_valid
        end
      end

      context "when declaration date format is valid RFC3339" do
        subject { model_class.new(declaration_date: "2021-06-21T08:46:29Z") }

        it { is_expected.to be_valid }
      end

      context "when declaration date format is invalid" do
        subject { model_class.new(declaration_date: "2021-06-21 08:46:29") }

        it "has a meaningful error", :aggregate_failures do
          expect(subject).to be_invalid
          expect(subject.errors.first).to have_attributes(attribute: :declaration_date, type: :invalid)
        end
      end

      context "when declaration date is invalid" do
        subject { model_class.new(declaration_date: "2023-19-01T11:21:55Z") }

        it "has a meaningful error", :aggregate_failures do
          expect(subject).to be_invalid
          expect(subject.errors.first).to have_attributes(attribute: :declaration_date, type: :invalid)
        end
      end

      context "when declaration time is invalid" do
        subject { model_class.new(declaration_date: "2023-19-01T29:21:55Z") }

        it "has a meaningful error", :aggregate_failures do
          expect(subject).to be_invalid
          expect(subject.errors.first).to have_attributes(attribute: :declaration_date, type: :invalid)
        end
      end

      context "when declaration date is not a string" do
        subject { model_class.new(declaration_date: 1) }

        it "has a meaningful error", :aggregate_failures do
          expect(subject).to be_invalid
          expect(subject.errors.first).to have_attributes(attribute: :declaration_date, type: :invalid)
        end
      end
    end
  end
end
