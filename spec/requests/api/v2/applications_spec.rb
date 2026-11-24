require "rails_helper"

RSpec.describe "API V2 applications endpoints", type: :request do
  include_context "with API V2 enabled"

  let(:current_lead_provider) { create(:lead_provider) }
  let(:json) { JSON.parse(response.body) }
  let(:ids) { json["data"].map { |a| a["id"] } }
  let(:item) { json["data"].first }

  def list(params: {}, lead_provider: current_lead_provider)
    api_get("/api/v2/applications", lead_provider:, params:)
  end

  def show(id, params: {}, lead_provider: current_lead_provider)
    api_get("/api/v2/applications/#{id}", lead_provider:, params:)
  end

  def count_queries(&)
    count = 0
    counter = ->(*, payload) { count += 1 unless payload[:name] == "SCHEMA" || payload[:cached] }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &)
    count
  end

  describe "GET /api/v2/applications" do
    let!(:application) { create(:application, lead_provider: current_lead_provider) }

    it "returns a JSON:API collection" do
      list

      expect([response.status, response.media_type, item.slice("id", "type")]).to eq(
        [200, "application/vnd.api+json", { "id" => application.ecf_id, "type" => "application" }],
      )
    end

    it "exposes the agreed attributes" do
      list

      expect(item["attributes"].keys).to contain_exactly(
        "email", "contract_assigned_at", "contract_unassigned_at", "created_at", "updated_at",
        "status", "status_reason", "course", "institution", "funding"
      )
    end

    it "serializes the email from Application#email" do
      list

      expect(item["attributes"]["email"]).to eq(application.email)
    end

    it "returns the application status and a null status_reason" do
      list

      expect(item["attributes"].slice("status", "status_reason")).to eq("status" => "pending", "status_reason" => nil)
    end

    it "returns null course role and experience" do
      list

      expect(item["attributes"]["course"]).to eq(
        "identifier" => application.course.identifier, "role" => nil, "experience" => nil,
      )
    end

    it "returns the nested funding object" do
      application.update_columns(funding_choice: nil, funding_eligibility: FundingEligibility::INELIGIBLE_SETTING.to_s, funded_place: false)
      list

      expect(item["attributes"]["funding"]).to eq(
        "eligible" => false, "uplift" => nil, "confirmed" => false, "choice" => "dfe",
        "reason" => "ineligible_setting", "confirmation_reason" => nil
      )
    end

    it "returns the stored funding choice when set" do
      application.update_columns(funding_choice: "school")
      list

      expect(item["attributes"]["funding"]["choice"]).to eq("school")
    end

    it "uses the requesting provider's assignment timestamps" do
      application.current_application_lead_provider.update!(assigned_at: Time.zone.parse("2025-01-02T03:04:05Z"))
      list

      expect(item["attributes"]["contract_assigned_at"]).to eq("2025-01-02T03:04:05.000Z")
    end

    it "uses the TRN as teacher identifier, keeping leading zeroes" do
      application.user.update!(trn: "0012345")
      list

      expect(item["relationships"]["teacher"]).to eq(
        "data" => { "type" => "teacher", "id" => "0012345" },
        "links" => { "related" => "/api/v2/teachers/0012345" },
      )
    end

    it "falls back to the teacher ecf_id when there is no TRN" do
      application.user.update!(trn: nil)
      list

      expect(item["relationships"]["teacher"]["data"]["id"]).to eq(application.user.ecf_id)
    end

    it "links the contract in the context of the application" do
      list

      expect(item["relationships"]["contract"]).to eq(
        "data" => { "type" => "contract", "id" => application.course_cohort.ecf_id },
        "links" => { "related" => "/api/v2/contracts/#{application.course_cohort.ecf_id}?application_id=#{application.ecf_id}" },
      )
    end

    it "has empty survey linkage and an application-filtered related link" do
      list

      expect(item["relationships"]["surveys"]).to eq(
        "data" => [], "links" => { "related" => "/api/v2/surveys?filter[application_id]=#{application.ecf_id}" },
      )
    end

    it "gives an application-filtered related link for expected declarations" do
      list

      expect(item["relationships"]["expected_declarations"]["links"]["related"]).to eq(
        "/api/v2/expected-declarations?filter[application_id]=#{application.ecf_id}",
      )
    end

    it "derives expected declarations from course milestones with underscore composite ids, in milestone order" do
      course = application.course
      course.milestones.delete_all
      { "retained-1" => 3, "completed" => 6, "started" => 0 }.each do |declaration_type, offset|
        create(:milestone, course:, declaration_type:, acceptance_window_start_offset: offset)
      end
      list

      expect(item["relationships"]["expected_declarations"]["data"]).to eq(
        %w[started retained-1 completed].map { |type| { "type" => "expected-declaration", "id" => "#{application.ecf_id}_#{type}" } },
      )
    end

    it "has null outcome linkage without an outcome" do
      list

      expect(item["relationships"]["outcome"]).to eq("data" => nil, "links" => { "related" => nil })
    end

    describe "includes" do
      it "has no included member without the include parameter" do
        list

        expect(json).not_to have_key("included")
      end

      it "keeps linkage without the include parameter" do
        list

        expect(item["relationships"].keys).to contain_exactly("teacher", "contract", "outcome", "surveys", "expected_declarations")
      end

      it "includes each shared teacher once" do
        create(:application, lead_provider: current_lead_provider, user: application.user, course: create(:course))
        list(params: { include: "teacher,surveys" })

        expect(json["included"].map { |i| [i["type"], i["id"]] }).to eq([["teacher", API::V2::TeacherSerializer.identifier(application.user)]])
      end

      it "does not include teachers of other providers' applications" do
        create(:application, lead_provider: create(:lead_provider))
        list(params: { include: "teacher" })

        expect(json["included"].map { |i| i["attributes"]["ecf_id"] }).to eq([application.user.ecf_id])
      end

      it "returns the teacher ecf_id and trn" do
        application.user.update!(trn: "0012345")
        list(params: { include: "teacher" })

        expect(json["included"].first["attributes"]).to eq("ecf_id" => application.user.ecf_id, "trn" => "0012345")
      end

      it "returns an empty included array when nothing is linked" do
        list(params: { include: "surveys" })

        expect(json["included"]).to eq([])
      end

      it "includes the contract" do
        list(params: { include: "contract" })

        expect(json["included"]).to eq([{
          "id" => application.course_cohort.ecf_id,
          "type" => "contract",
          "attributes" => {
            "academic_year" => application.course_cohort.academic_year,
            "course" => application.course.identifier,
            "term" => application.course_cohort.term_identifier,
          },
        }])
      end

      it "includes expected declarations" do
        list(params: { include: "expected_declarations" })

        expect(json["included"].map { |i| i["id"] }).to eq(item["relationships"]["expected_declarations"]["data"].map { |d| d["id"] })
      end

      %w[teacher.outcomes contract.declarations application unknown].each do |path|
        it "rejects the unsupported include #{path} with a JSON:API error" do
          list(params: { include: path })

          expect([response.status, response.media_type, json["errors"].first["status"]]).to eq([400, "application/vnd.api+json", "400"])
        end
      end

      it "does not expose applications for an unsupported include" do
        list(params: { include: "teacher.outcomes" })

        expect(json.keys).to eq(%w[errors])
      end

      it "rejects an unsupported include before querying applications" do
        query = instance_double(API::V2::Applications::Query)
        allow(API::V2::Applications::Query).to receive(:new).and_return(query)
        list(params: { include: "teacher.outcomes" })

        expect(API::V2::Applications::Query).not_to have_received(:new)
      end

      it "rejects a non-string include with a dedicated message" do
        list(params: { include: %w[teacher] })

        expect([response.status, json["errors"].first.slice("detail", "source")]).to eq(
          [400, { "detail" => I18n.t(:invalid_include_format), "source" => { "parameter" => "include" } }],
        )
      end

      ["teacher,", "teacher,,surveys", " "].each do |include_param|
        it "rejects the blank include path in #{include_param.inspect} with a dedicated message" do
          list(params: { include: include_param })

          expect([response.status, json["errors"].first["detail"]]).to eq([400, I18n.t(:blank_include_path)])
        end
      end

      it "names the unsupported include path" do
        list(params: { include: "teacher,teacher.outcomes" })

        expect(json["errors"].first["detail"]).to eq(I18n.t(:unsupported_include, paths: "teacher.outcomes"))
      end
    end

    describe "authentication and visibility" do
      it "returns a JSON:API error for an invalid token" do
        api_get("/api/v2/applications", token: "invalid")

        expect([response.status, response.media_type, json.keys]).to eq([401, "application/vnd.api+json", %w[errors]])
      end

      it "does not return another provider's applications" do
        list(lead_provider: create(:lead_provider))

        expect(json["data"]).to eq([])
      end

      context "when the application was reassigned to another provider" do
        before do
          travel_to(1.day.ago) { application }
          application.change_provider!(to: create(:lead_provider))
        end

        it "still returns it, as reassigned" do
          list

          expect([ids, item["attributes"]["status"]]).to eq([[application.ecf_id], "reassigned"])
        end

        it "exposes when the provider was unassigned" do
          list

          expect(Time.zone.parse(item["attributes"]["contract_unassigned_at"])).to be_within(1.second).of(
            application.application_lead_providers.find_by(lead_provider: current_lead_provider).unassigned_at,
          )
        end
      end

      it "returns an application once when it was assigned to the provider several times" do
        other_provider = create(:lead_provider)
        application.change_provider!(to: other_provider)
        application.reload.change_provider!(to: current_lead_provider)
        application.reload.change_provider!(to: other_provider)
        list

        expect([ids, item["attributes"]["status"]]).to eq([[application.ecf_id], "reassigned"])
      end

      it "returns the current assignment when the application was reassigned back to the provider" do
        application.change_provider!(to: create(:lead_provider))
        application.reload.change_provider!(to: current_lead_provider)
        list

        expect([ids, item["attributes"].slice("status", "contract_unassigned_at")]).to eq(
          [[application.ecf_id], { "status" => application.status, "contract_unassigned_at" => nil }],
        )
      end
    end

    context "with filters" do
      let!(:other) do
        create(:application, :ineligible_for_funding, lead_provider: current_lead_provider, course: create(:course, identifier: "other-course"))
      end

      before do
        application.update_columns(funding_eligibility: FundingEligibility::FUNDED_ELIGIBILITY_RESULT.to_s)
        application.course_cohort.update_columns(academic_year: 2025, term_identifier: "autumn")
        other.course_cohort.update_columns(academic_year: 2026, term_identifier: "spring")
      end

      {
        "course" => ->(app) { app.course.identifier },
        "term" => ->(_app) { "autumn" },
        "academic_year" => ->(_app) { "2025" },
        "funding_eligible" => ->(_app) { "true" },
        "teacher_ecf_id" => ->(app) { app.user.ecf_id },
        "email" => ->(app) { app.email },
      }.each do |name, value|
        it "filters by #{name}" do
          list(params: { filter: { name => value.call(application) } })

          expect(ids).to eq([application.ecf_id])
        end
      end

      it "filters by teacher_trn" do
        application.user.update!(trn: "0099999")
        list(params: { filter: { teacher_trn: "0099999" } })

        expect(ids).to eq([application.ecf_id])
      end

      it "filters by funding_eligible false" do
        list(params: { filter: { funding_eligible: "false" } })

        expect(ids).to eq([other.ecf_id])
      end

      it "filters by updated_since" do
        travel_to(2.days.ago) { create(:application, lead_provider: current_lead_provider) }
        list(params: { filter: { updated_since: 1.day.ago.utc.iso8601 } })

        expect(ids).to contain_exactly(application.ecf_id, other.ecf_id)
      end

      it "accepts several comma-separated values" do
        list(params: { filter: { course: "#{application.course.identifier},other-course" } })

        expect(ids).to contain_exactly(application.ecf_id, other.ecf_id)
      end

      it "combines filters with AND" do
        list(params: { filter: { course: application.course.identifier, term: "spring" } })

        expect(json["data"]).to eq([])
      end

      it "matches nothing for funding_uplift as it is always null" do
        list(params: { filter: { funding_uplift: "true" } })

        expect(json["data"]).to eq([])
      end

      it "returns an empty list when nothing matches" do
        list(params: { filter: { email: "nobody@example.com" } })

        expect(json["data"]).to eq([])
      end

      it "only returns the provider-visible applications of the filtered email" do
        create(:application, lead_provider: create(:lead_provider), user: application.user, course: create(:course))
        list(params: { filter: { email: application.email } })

        expect(ids).to eq([application.ecf_id])
      end

      {
        "a malformed boolean" => { funding_eligible: "maybe" },
        "a malformed updated_since" => { updated_since: "yesterday" },
        "a malformed teacher_ecf_id" => { teacher_ecf_id: "nope" },
        "a malformed academic_year" => { academic_year: "25" },
        "an unknown term" => { term: "winter" },
        "an array value" => { course: %w[x] },
        "a nested value" => { course: { a: "b" } },
        "an unsupported key" => { training_id: "x" },
        "a non-numeric teacher_trn" => { teacher_trn: "abc1234" },
        "a teacher_trn of the wrong length" => { teacher_trn: "123456" },
        "a malformed email" => { email: "not-an-email" },
        "a malformed email in a list" => { email: "jane@example.com,nope" },
      }.each do |description, filter|
        it "rejects #{description} with a JSON:API error and no data" do
          list(params: { filter: })

          expect([response.status, response.media_type, json.keys]).to eq([400, "application/vnd.api+json", %w[errors]])
        end
      end

      it "points the error at the invalid filter" do
        list(params: { filter: { teacher_trn: "abc" } })

        expect(json["errors"]).to eq([{
          "status" => "400",
          "title" => I18n.t(:bad_request),
          "detail" => I18n.t(:invalid_filter, attribute: :teacher_trn),
          "source" => { "parameter" => "filter[teacher_trn]" },
        }])
      end

      ["a,,b", ",a", "a,", ","].each do |value|
        it "rejects the empty value in #{value.inspect}" do
          list(params: { filter: { course: value } })

          expect([response.status, json["errors"]]).to eq([400, [{
            "status" => "400",
            "title" => I18n.t(:bad_request),
            "detail" => I18n.t(:blank_filter_value, attribute: :course),
            "source" => { "parameter" => "filter[course]" },
          }]])
        end
      end

      it "explains that updated_since needs an ISO 8601 timestamp" do
        list(params: { filter: { updated_since: "2025-01-01" } })

        expect(json["errors"].first.slice("detail", "source")).to eq(
          "detail" => I18n.t(:invalid_timestamp_filter, attribute: :updated_since),
          "source" => { "parameter" => "filter[updated_since]" },
        )
      end

      it "rejects a non-hash filter" do
        list(params: { filter: "abc" })

        expect([response.status, json.keys]).to eq([400, %w[errors]])
      end
    end

    describe "query counts" do
      let(:user) { create(:user) }

      def add_applications(count)
        count.times do
          create(:application, lead_provider: current_lead_provider, user:, course: create(:course))
        end
      end

      [nil, "teacher,contract,outcome,surveys,expected_declarations"].each do |include_param|
        it "does not grow with the number of rows (include: #{include_param.inspect})" do
          params = include_param ? { include: include_param } : {}
          add_applications(2)
          list(params:) # warm caches such as token lookup
          small = count_queries { list(params:) }
          add_applications(4)
          large = count_queries { list(params:) }

          expect(large).to eq(small)
        end
      end
    end

    context "with outcomes" do
      let(:declaration_args) { { application:, lead_provider: current_lead_provider, user: application.user } }
      let!(:completed) { create(:declaration, :completed, :payable, **declaration_args) }
      let!(:outcome) { create(:participant_outcome, declaration: completed, state: "passed", completion_date: Date.new(2025, 6, 1)) }

      it "links the provider's outcome" do
        list

        expect(item["relationships"]["outcome"]).to eq(
          "data" => { "type" => "outcome", "id" => outcome.ecf_id },
          "links" => { "related" => "/api/v2/outcomes/#{outcome.ecf_id}" },
        )
      end

      it "includes the outcome state and completion date" do
        list(params: { include: "outcome" })

        expect(json["included"].first["attributes"]).to eq("state" => "passed", "completion_date" => "2025-06-01")
      end

      it "does not expose an outcome of a voided declaration" do
        completed.update_columns(state: "voided")
        list(params: { include: "outcome" })

        expect([item["relationships"]["outcome"]["data"], json["included"]]).to eq([nil, []])
      end

      it "does not expose an outcome of a previous provider's declaration" do
        previous = create(:lead_provider)
        previous_app = create(:application, lead_provider: previous)
        previous_declaration = create(:declaration, :completed, :payable, application: previous_app, lead_provider: previous, user: previous_app.user)
        create(:participant_outcome, declaration: previous_declaration)
        previous_app.change_provider!(to: current_lead_provider)
        list(params: { include: "outcome" })
        entry = json["data"].find { |a| a["id"] == previous_app.ecf_id }

        expect([entry["relationships"]["outcome"]["data"], json["included"].map { |i| i["id"] }]).to eq([nil, [outcome.ecf_id]])
      end
    end

    context "without an institution" do
      it "returns null institution fields" do
        application.update_columns(institution_id: nil)
        list

        expect(item["attributes"]["institution"]).to eq(
          "category" => nil, "reference_number" => nil, "ukprn" => nil, "country_code" => nil, "subdivision" => nil,
        )
      end
    end

    context "with an institution" do
      %i[school private_childcare_provider local_authority].each do |factory|
        it "returns category #{factory} with the institution details" do
          institution = build(factory).tap(&:save!).institution
          application.update_columns(institution_id: institution.id)
          list

          expect(item["attributes"]["institution"]).to eq(
            "category" => factory.to_s,
            "reference_number" => institution.institution_reference_number,
            "ukprn" => institution.ukprn,
            "country_code" => institution.alpha3_country_code,
            "subdivision" => institution.subdivision_code,
          )
        end
      end
    end
  end

  describe "GET /api/v2/applications/:id" do
    let!(:application) { create(:application, lead_provider: current_lead_provider) }

    it "returns the application as a JSON:API resource" do
      show(application.ecf_id)

      expect([response.status, response.media_type, json["data"].slice("id", "type")]).to eq(
        [200, "application/vnd.api+json", { "id" => application.ecf_id, "type" => "application" }],
      )
    end

    it "matches the same record in the list, including the contextual contract link" do
      list
      listed = JSON.parse(response.body)["data"].first
      show(application.ecf_id)

      expect(JSON.parse(response.body)["data"]).to eq(listed)
    end

    it "has no included member without the include parameter" do
      show(application.ecf_id)

      expect(json).not_to have_key("included")
    end

    it "includes the requested teacher" do
      show(application.ecf_id, params: { include: "teacher" })

      expect(json["included"].map { |i| i["type"] }).to eq(%w[teacher])
    end

    it "rejects an unsupported include with a JSON:API error" do
      show(application.ecf_id, params: { include: "teacher.outcomes" })

      expect([response.status, json.keys]).to eq([400, %w[errors]])
    end

    {
      "sort" => { sort: "bogus" },
      "page" => { page: { size: "99999" } },
      "filter" => { filter: { unknown: "1" } },
    }.each do |parameter, params|
      it "rejects #{parameter} with a JSON:API error naming the parameter" do
        show(application.ecf_id, params:)

        expect([response.status, response.media_type, json["errors"]]).to eq([400, "application/vnd.api+json", [{
          "status" => "400",
          "title" => I18n.t(:bad_request),
          "detail" => I18n.t(:collection_parameter_not_supported, parameter:),
          "source" => { "parameter" => parameter },
        }]])
      end
    end

    it "rejects a valid list filter too" do
      show(application.ecf_id, params: { filter: { course: application.course.identifier } })

      expect(json["errors"].first["source"]).to eq("parameter" => "filter")
    end

    it "rejects list-only parameters before querying applications" do
      allow(API::V2::Applications::Query).to receive(:new).and_call_original
      show(application.ecf_id, params: { sort: "updated_at" })

      expect(API::V2::Applications::Query).not_to have_received(:new)
    end

    it "returns a JSON:API not found error for an unknown UUID" do
      show(SecureRandom.uuid)

      expect([response.status, response.media_type, json["errors"].first["status"]]).to eq([404, "application/vnd.api+json", "404"])
    end

    it "returns an application the provider was previously assigned as reassigned" do
      application.change_provider!(to: create(:lead_provider))
      show(application.ecf_id)

      expect([response.status, json["data"]["attributes"]["status"]]).to eq([200, "reassigned"])
    end

    it "returns not found for an application never assigned to the provider" do
      show(create(:application, lead_provider: create(:lead_provider)).ecf_id)

      expect(response).to have_http_status(:not_found)
    end

    it "returns not found for a malformed id" do
      show("not-a-uuid")

      expect(response).to have_http_status(:not_found)
    end

    it "returns a JSON:API error for an invalid token" do
      api_get("/api/v2/applications/#{application.ecf_id}", token: "invalid")

      expect([response.status, json.keys]).to eq([401, %w[errors]])
    end
  end

  it "returns JSON:API errors for unknown V2 paths" do
    api_get("/api/v2/thisdoesnotexist", lead_provider: current_lead_provider)

    expect([response.status, response.media_type, json["errors"].first["status"]]).to eq([404, "application/vnd.api+json", "404"])
  end

  it "does not route the former training resource name" do
    api_get("/api/v2/training", lead_provider: current_lead_provider)

    expect(response).to have_http_status(:not_found)
  end
end
