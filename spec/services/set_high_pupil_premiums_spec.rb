require "rails_helper"

RSpec.describe SetHighPupilPremiums do
  subject(:service) { described_class.new(path_to_csv: file.path) }

  let(:file) do
    Tempfile.new(["urns", ".csv"]).tap do |f|
      f.write("urn\n#{school.urn}\n")
      f.close
    end
  end
  let(:school) { create(:school).institution }
  let!(:other_school) { create(:school).institution }

  after { file.unlink }

  it "flags listed schools" do
    expect { service.call }.to change { school.reload.high_pupil_premium }.from(false).to(true)
  end

  it "leaves other schools untouched" do
    service.call

    expect(other_school.reload.high_pupil_premium).to be(false)
  end
end
