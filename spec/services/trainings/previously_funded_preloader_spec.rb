require "rails_helper"

RSpec.describe Trainings::PreviouslyFundedPreloader do
  let(:user) { create(:user) }
  let!(:earlier) { create(:application, :accepted, user:, eligible_for_funding: true, course: create(:course)) }
  let!(:later) { create(:application, user:, course: create(:course)) }

  before { described_class.new([earlier.reload, later.reload]).call }

  it "flags an application when another accepted funded application exists" do
    expect(later.previously_funded?).to be(true)
  end

  it "does not flag the funded application itself" do
    expect(earlier.previously_funded?).to be(false)
  end
end
