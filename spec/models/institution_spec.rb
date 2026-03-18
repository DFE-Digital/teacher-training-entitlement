require "rails_helper"

RSpec.describe Institution do
  describe ".search_by_name" do
    context "searching by name" do
      before { create(:school, name: "a school") }

      it "returns institutions matching the name" do
        expect(described_class.search_by_name("a school").count).to be(1)
      end
    end

    context "searching by la_name" do
      before { create(:school, la_name: "Swindon") }

      it "returns institutions matching the la_name" do
        expect(described_class.search_by_name("Swindon").count).to be(1)
      end
    end

    context "searching by address_1" do
      before { create(:school, address_1: "someplace") }

      it "returns institutions matching the address_1" do
        expect(described_class.search_by_name("someplace").count).to be(1)
      end
    end

    context "searching by address_2" do
      before { create(:school, address_2: "someplace") }

      it "returns institutions matching the address_2" do
        expect(described_class.search_by_name("someplace").count).to be(1)
      end
    end

    context "searching by address_3" do
      before { create(:school, address_3: "someplace") }

      it "returns institutions matching the address_3" do
        expect(described_class.search_by_name("someplace").count).to be(1)
      end
    end

    context "searching by town" do
      before { create(:school, town: "someplace") }

      it "returns institutions matching the town" do
        expect(described_class.search_by_name("someplace").count).to be(1)
      end
    end

    context "searching by county" do
      before { create(:school, county: "someplace") }

      it "returns institutions matching the county" do
        expect(described_class.search_by_name("someplace").count).to be(1)
      end
    end

    context "searching by postcode" do
      before { create(:school, postcode: "AB12 3CD") }

      it "returns institutions matching the postcode" do
        expect(described_class.search_by_name("AB12 3CD").count).to be(1)
      end
    end

    context "searching by postcode without spaces" do
      before { create(:school, postcode_without_spaces: "AB123CD") }

      it "returns institutions matching the postcode without spaces" do
        expect(described_class.search_by_name("AB123CD").count).to be(1)
      end
    end

    context "searching by region" do
      before { create(:school, region: "someplace") }

      it "returns institutions matching the region" do
        expect(described_class.search_by_name("someplace").count).to be(1)
      end
    end

    context "searching by URN" do
      before { create(:school, urn: "123456") }

      it "returns institutions matching the URN" do
        expect(described_class.search_by_name("123456").count).to be(1)
      end
    end

    context "regarding apostrophes" do
      before { create(:school, name: "andrew's", postcode: "NW5") }

      it "can find with apostrophe" do
        expect(described_class.search_by_name("andrew's").count).to be(1)
      end

      it "can find without apostrophe" do
        expect(described_class.search_by_name("andrews").count).to be(1)
      end

      it "can find partial match" do
        expect(described_class.search_by_name("andrew").count).to be(1)
      end

      it "can return no matches" do
        expect(described_class.search_by_name("bob").count).to be(0)
      end
    end

    context "regarding hyphen" do
      before { create(:school, name: "mary-anne") }

      it "can find with hyphen" do
        expect(described_class.search_by_name("mary-anne").count).to be(1)
      end

      it "can find without hyphen" do
        expect(described_class.search_by_name("mary anne").count).to be(1)
      end

      it "can find partial match" do
        expect(described_class.search_by_name("mary").count).to be(1)
      end
    end

    context "synonym searching: st and saint" do
      let(:st_school) { create(:school, name: "St Mary's Catholic Primary School") }
      let(:saint_school) { create(:school, name: "Saint Mary's College") }
      let(:school_containing_st) { create(:school, name: "Some Firsaint School") }

      before do
        st_school
        saint_school
        school_containing_st
      end

      it "can find 'saint' when searching for 'st'" do
        expect(described_class.search_by_name("st mary")).to include(st_school.institution, saint_school.institution)
      end

      it "can find 'st' when searching for 'saint'" do
        expect(described_class.search_by_name("saint mary")).to include(st_school.institution, saint_school.institution)
      end

      it "does not return matches where 'st' is not a whole word" do
        expect(described_class.search_by_name("some first")).not_to include(school_containing_st.institution)
      end
    end
  end
end
