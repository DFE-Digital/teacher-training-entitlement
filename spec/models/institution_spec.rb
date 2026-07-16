require "rails_helper"

RSpec.describe Institution do
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
