require "rails_helper"

RSpec.describe Registrations::StateStore do
  let(:session) { {} }
  let(:store) { described_class.new(session:, key: :registration) }

  describe "#read" do
    it "returns an indifferent-access view of the stored data" do
      session[:registration] = { "answer" => "yes" }

      expect(store.read[:answer]).to eq("yes")
    end
  end

  describe "#write" do
    it "merges new data into the session" do
      session[:registration] = { "answer" => "yes" }

      store.write(next_step: "details")

      expect(store.read.to_h).to eq("answer" => "yes", "next_step" => "details")
    end
  end

  describe "#clear" do
    it "removes the stored data" do
      session[:registration] = { "answer" => "yes" }

      store.clear

      expect(store.read).to eq({})
    end
  end
end
