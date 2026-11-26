require "rails_helper"

RSpec.describe API::V2::ParameterError do
  it "is a bad request" do
    expect(described_class.new("bad", parameter: "sort")).to be_a(ActionController::BadRequest)
  end

  it "builds a JSON:API error object pointing at the parameter" do
    expect(described_class.new("bad", parameter: "sort").to_error_object).to eq(
      status: "400", title: I18n.t(:bad_request), detail: "bad", source: { parameter: "sort" },
    )
  end

  it "adds the type link and meta when given" do
    error = described_class.new("too big", parameter: "page[size]", type: "https://example.com/type", meta: { page: { maxSize: 3 } })

    expect(error.to_error_object.slice(:links, :meta)).to eq(
      links: { type: ["https://example.com/type"] }, meta: { page: { maxSize: 3 } },
    )
  end
end
