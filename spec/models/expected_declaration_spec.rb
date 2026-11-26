require "rails_helper"

RSpec.describe ExpectedDeclaration do
  it "builds an underscore composite id" do
    expect(described_class.new("abc", "retained-1").id).to eq("abc_retained-1")
  end
end
