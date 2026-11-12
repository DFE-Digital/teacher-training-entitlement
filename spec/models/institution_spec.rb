require "rails_helper"

RSpec.describe Institution do
  describe "INSTITUTION_TYPES" do
    it "lists the slugs in selector evaluation order" do
      expect(described_class::INSTITUTION_TYPES).to eq(
        %w[state_funded
           further_education
           young_offender_institution
           hospital
           mod_overseas
           virtual_school
           local_authority
           private_childcare_provider],
      )
    end
  end

  describe "institution_type enum" do
    it "is backed by the slug strings" do
      expect(described_class.institution_types).to eq(described_class::INSTITUTION_TYPES.index_with(&:itself))
    end

    it "keeps INSTITUTION_TYPES in the same order as the enum" do
      expect(described_class::INSTITUTION_TYPES).to eq(described_class.institution_types.keys)
    end

    described_class::INSTITUTION_TYPES.each do |slug|
      context "with #{slug}" do
        subject(:institution) { build(:institution, institution_type: slug) }

        it { is_expected.to be_valid }
        it { expect(institution.public_send(:"institution_type_#{slug}?")).to be(true) }

        it "provides a prefixed scope" do
          institution.save!
          expect(described_class.public_send(:"institution_type_#{slug}")).to include(institution)
        end

        it "stores the slug string" do
          institution.save!
          expect(institution.reload.read_attribute_before_type_cast("institution_type")).to eq(slug)
        end
      end
    end

    it "rejects unknown values" do
      expect { build(:institution, institution_type: "bogus") }.to raise_error(ArgumentError, /bogus/)
    end

    it "requires an institution_type" do
      institution = build(:institution)
      institution.institution_type = nil

      expect(institution).not_to be_valid
    end

    it "does not override delegated_type predicates" do
      expect(build(:institution, institution_type: "hospital")).not_to be_local_authority
    end
  end

  describe "API_INSTITUTION_TYPE_MAPPING" do
    subject(:mapping) { described_class::API_INSTITUTION_TYPE_MAPPING }

    it "maps state_funded to school" do
      expect(mapping[described_class::STATE_FUNDED]).to eq("school")
    end

    it "maps local_authority to localauthority" do
      expect(mapping[described_class::LOCAL_AUTHORITY]).to eq("localauthority")
    end

    it "maps private_childcare_provider to privatechildcareprovider" do
      expect(mapping[described_class::PRIVATE_CHILDCARE_PROVIDER]).to eq("privatechildcareprovider")
    end

    it "emits other slugs unchanged" do
      expect(described_class::INSTITUTION_TYPES - mapping.keys).to all(satisfy { |slug| mapping[slug] == slug })
    end
  end

  describe "columns" do
    it "has a non-null institution_type string" do
      expect(described_class.columns_hash["institution_type"]).to have_attributes(type: :string, null: false)
    end

    it "has an open boolean" do
      expect(described_class.columns_hash["open"].type).to eq(:boolean)
    end
  end

  describe "#country_long_name" do
    subject(:institution) { build(:institution, alpha3_country_code:) }

    context "with a recognized country code" do
      let(:alpha3_country_code) { "GBR" }

      it "returns the ISO short name to preserve the API value" do
        expect(institution.country_long_name).to eq("United Kingdom of Great Britain and Northern Ireland")
      end
    end

    context "without a country code" do
      let(:alpha3_country_code) { nil }

      it { expect(institution.country_long_name).to be_nil }
    end
  end

  describe "#within_the_uk?" do
    subject(:institution) { build(:institution, alpha3_country_code:) }

    %w[GBR JEY GGY IMN].each do |country_code|
      context "with country code #{country_code}" do
        let(:alpha3_country_code) { country_code }

        it { is_expected.to be_within_the_uk }
      end
    end

    context "with another country code" do
      let(:alpha3_country_code) { "ESP" }

      it { is_expected.not_to be_within_the_uk }
    end
  end

  describe ".search" do
    context "when searching by name" do
      before { create(:school, name: "a school") }

      it "returns institutions matching the name" do
        expect(described_class.search("a school").count).to be(1)
      end
    end

    context "when searching with a blank term" do
      before { create(:school, name: "a school") }

      it "returns no results" do
        expect(described_class.search("").count).to be(0)
        expect(described_class.search(nil).count).to be(0)
        expect(described_class.search("   ").count).to be(0)
      end
    end

    context "when searching by postcode" do
      before { create(:school, postcode: "AB12 3CD") }

      it "returns institutions matching the postcode" do
        expect(described_class.search("AB12 3CD").count).to be(1)
      end
    end

    context "when searching by postcode without spaces" do
      before { create(:school, postcode_without_spaces: "AB123CD") }

      it "returns institutions matching the postcode without spaces" do
        expect(described_class.search("AB123CD").count).to be(1)
      end
    end

    context "when searching by URN" do
      before { create(:school, urn: "123456") }

      it "returns institutions matching the URN" do
        expect(described_class.search("123456").count).to be(1)
      end
    end

    context "when regarding apostrophes" do
      before { create(:school, name: "andrew's", postcode: "NW5") }

      it "can find with apostrophe" do
        expect(described_class.search("andrew's").count).to be(1)
      end

      it "can find without apostrophe" do
        expect(described_class.search("andrews").count).to be(1)
      end

      it "can find partial match" do
        expect(described_class.search("andrew").count).to be(1)
      end

      it "can return no matches" do
        expect(described_class.search("bob").count).to be(0)
      end
    end

    context "when regarding hyphen" do
      before { create(:school, name: "mary-anne") }

      it "can find with hyphen" do
        expect(described_class.search("mary-anne").count).to be(1)
      end

      it "can find without hyphen" do
        expect(described_class.search("mary anne").count).to be(1)
      end

      it "can find partial match" do
        expect(described_class.search("mary").count).to be(1)
      end
    end

    context "when synonym searching: st and saint" do
      let(:st_school) { create(:school, name: "St Mary's Catholic Primary School") }
      let(:saint_school) { create(:school, name: "Saint Mary's College") }
      let(:school_containing_st) { create(:school, name: "Some Firsaint School") }

      before do
        st_school
        saint_school
        school_containing_st
      end

      it "can find 'saint' when searching for 'st'" do
        expect(described_class.search("st mary")).to include(st_school.institution, saint_school.institution)
      end

      it "can find 'st' when searching for 'saint'" do
        expect(described_class.search("saint mary")).to include(st_school.institution, saint_school.institution)
      end

      it "does not return matches where 'st' is not a whole word" do
        expect(described_class.search("some first")).not_to include(school_containing_st.institution)
      end
    end
  end
end
