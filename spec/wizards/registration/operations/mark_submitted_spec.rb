require "rails_helper"

RSpec.describe Registration::Operations::MarkSubmitted do
  let(:repository) { DfE::Wizard::Repository::InMemory.new }

  it "records that the answers were submitted" do
    described_class.new(repository:, step: nil).execute

    expect(repository.read[:submitted]).to be(true)
  end

  it "succeeds" do
    expect(described_class.new(repository:, step: nil).execute).to eq(success: true)
  end
end
