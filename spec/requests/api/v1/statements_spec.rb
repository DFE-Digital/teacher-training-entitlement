require "rails_helper"

RSpec.describe "Statements endpoint", type: "request" do
  let(:current_lead_provider) { create(:lead_provider) }
  let(:query) { Statements::Query }
  let(:serializer) { API::StatementSerializer }

  describe "GET /api/v1/statements" do
    let(:path) { api_v1_statements_path }
    let(:resource_id_key) { :ecf_id }

    def counter
      # workaround to avoid uniqueness constraint on statement creation
      # counter increases every time the create_resource is invoked
      # rubocop:disable RSpec/InstanceVariable
      if @counter.nil?
        @counter = 0
      else
        @counter += 1
      end
      # rubocop:enable RSpec/InstanceVariable
    end

    def create_resource(**attrs)
      create(:statement, start_date: counter.months.ago, **attrs)
    end

    it_behaves_like "an API index endpoint with pagination"
    it_behaves_like "an API index endpoint with filter by updated_since"
  end
end
