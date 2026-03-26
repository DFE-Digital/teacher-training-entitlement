RSpec.shared_examples "a successful api call" do
  it do
    expect(response.status).to eq(200)
    expect(response.content_type).to eql("application/json")
    expect(response.headers).to include("cache-control" => "no-store")
    expect(parsed_response["data"]["id"]).to eq(expected_data_id)
  end
end
