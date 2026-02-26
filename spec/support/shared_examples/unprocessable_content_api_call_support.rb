RSpec.shared_examples "an unprocessable content api call" do
  it do
    expect(response.status).to eq(422)
    expect(response.content_type).to eql("application/json")
    expect(parsed_response).to eq(expected_response)
  end
end
