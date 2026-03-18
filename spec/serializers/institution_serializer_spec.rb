require "rails_helper"

RSpec.describe InstitutionSerializer, type: :serializer do
  context "when passed a school institution" do
    let(:school) { build(:school, :with_address) }
    let(:hash) { InstitutionSerializer.render_as_hash(school.institution) }

    it "only includes id, name and address" do
      expect(hash.keys).to eq(%i[id name address])
    end

    it("serializes id") { expect(hash[:id]).to eql(school.institution.id) }
    it("serializes name") { expect(hash[:name]).to eql(school.institution.name) }
    it("serializes the address") { expect(hash[:address]).to eql(school.institution.address_string) }
  end

  context "when passed a local authority institution" do
    let(:local_authority) { build(:local_authority) }
    let(:hash) { InstitutionSerializer.render_as_hash(local_authority.institution) }

    it "only includes id, name and address" do
      expect(hash.keys).to eq(%i[id name address])
    end

    it("serializes id") { expect(hash[:id]).to eql(local_authority.institution.id) }
    it("serializes name") { expect(hash[:name]).to eql(local_authority.institution.name) }
    it("serializes the address") { expect(hash[:address]).to eql(local_authority.institution.address_string) }
  end
end
