require "rails_helper"

RSpec.describe "API V2 training endpoint", type: :request do
  let(:current_lead_provider) { create(:lead_provider) }
  let(:json) { JSON.parse(response.body) }
  let(:ids) { json["data"].map { |t| t["id"] } }

  def list(params: {}, lead_provider: current_lead_provider)
    api_get("/api/v2/training", lead_provider:, params:)
  end

  describe "GET /api/v2/training" do
    let!(:application) { create(:application, lead_provider: current_lead_provider) }

    it "returns a JSON:API collection" do
      list

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/vnd.api+json")
      expect(json["data"].first).to include("id" => application.ecf_id, "type" => "training")
    end

    it "exposes the agreed attributes" do
      list

      expect(json["data"].first["attributes"].keys).to include(
        "email", "contract_assigned_at", "contract_unassigned_at", "created_at", "updated_at",
        "status", "status_reason", "course", "institution", "funding"
      )
    end

    it "uses the teacher email as training email" do
      list

      expect(json["data"].first["attributes"]["email"]).to eq(application.user.email)
    end

    it "returns null course role and experience" do
      list

      expect(json["data"].first["attributes"]["course"]).to eq(
        "identifier" => application.course.identifier, "role" => nil, "experience" => nil,
      )
    end

    it "returns dfe funding choice when none is set and null uplift" do
      application.update!(funding_choice: nil)
      list

      expect(json["data"].first["attributes"]["funding"]).to include("choice" => "dfe", "uplift" => nil)
    end

    it "returns the stored funding choice when set" do
      application.update!(funding_choice: "school")
      list

      expect(json["data"].first["attributes"]["funding"]["choice"]).to eq("school")
    end

    it "uses the requesting provider's assignment timestamps" do
      assignment = application.current_application_lead_provider
      assignment.update!(assigned_at: Time.zone.parse("2025-01-02T03:04:05Z"))
      list

      expect(json["data"].first["attributes"]["contract_assigned_at"]).to eq("2025-01-02T03:04:05.000Z")
    end

    it "uses the TRN as teacher identifier with the ecf_id attribute" do
      application.user.update!(trn: "0012345")
      list
      teacher = json["data"].first["relationships"]["teacher"]

      expect(teacher["data"]).to eq("type" => "teacher", "id" => "0012345")
      expect(teacher["links"]["related"]).to eq("/api/v2/teachers/0012345")
    end

    it "falls back to the teacher ecf_id when there is no TRN" do
      application.user.update!(trn: nil)
      list

      expect(json["data"].first["relationships"]["teacher"]["data"]["id"]).to eq(application.user.ecf_id)
    end

    it "links the contract in the context of the training" do
      list
      contract = json["data"].first["relationships"]["contract"]

      expect(contract["links"]["related"]).to eq(
        "/api/v2/contracts/#{application.course_cohort.ecf_id}?training_id=#{application.ecf_id}",
      )
    end

    it "gives related links for surveys and expected declarations" do
      list
      relationships = json["data"].first["relationships"]

      expect(relationships["surveys"]["links"]["related"]).to eq("/api/v2/surveys?filter[training_id]=#{application.ecf_id}")
      expect(relationships["expected_declarations"]["links"]["related"]).to eq("/api/v2/expected-declarations?filter[training_id]=#{application.ecf_id}")
    end

    it "derives expected declarations from course milestones with composite ids" do
      create(:milestone, course: application.course, declaration_type: "started") if application.course.milestones.empty?
      list
      linkage = json["data"].first["relationships"]["expected_declarations"]["data"]

      expect(linkage).to all(include("type" => "expected-declaration", "id" => match(/\A#{application.ecf_id}_/)))
    end

    it "has a null outcome linkage without an outcome" do
      list

      expect(json["data"].first["relationships"]["outcome"]["data"]).to be_nil
    end

    it "does not include an included member without the include parameter" do
      list

      expect(json).not_to have_key("included")
    end

    it "includes teachers once per canonical id" do
      create(:application, lead_provider: current_lead_provider, user: application.user, course: create(:course))
      list(params: { include: "teacher,surveys" })

      expect(json["included"].map { |i| [i["type"], i["id"]] }.uniq.size).to eq(json["included"].size)
    end

    it "returns the included teacher" do
      list(params: { include: "teacher" })

      expect(json["included"].first).to include("type" => "teacher")
    end

    it "returns an empty included array when related resources do not exist" do
      list(params: { include: "surveys" })

      expect(json["included"]).to eq([])
    end

    it "includes expected declarations when requested" do
      create(:milestone, course: application.course, declaration_type: "started") if application.course.milestones.empty?
      list(params: { include: "expected_declarations" })

      expect(json["included"]).to all(include("type" => "expected-declaration"))
    end

    %w[teacher.outcomes contract unknown].each do |path|
      it "rejects the unsupported include #{path} with JSON:API errors" do
        list(params: { include: path })

        expect(response).to have_http_status(:bad_request)
        expect(response.media_type).to eq("application/vnd.api+json")
        expect(json["errors"].first).to include("status" => "400")
      end
    end

    it "returns JSON:API errors for an invalid token" do
      api_get("/api/v2/training", token: "invalid")

      expect(response).to have_http_status(:unauthorized)
      expect(json["errors"].first).to include("status" => "401")
    end

    it "does not return another provider's training" do
      list(lead_provider: create(:lead_provider))

      expect(json["data"]).to eq([])
    end

    it "does not return training the provider was previously assigned" do
      other = create(:lead_provider)
      application.change_provider!(to: other)
      list

      expect(json["data"]).to eq([])
    end

    context "with filters" do
      let!(:other) { create(:application, lead_provider: current_lead_provider, eligible_for_funding: !application.eligible_for_funding) }

      let!(:other_course_application) do
        create(:application, lead_provider: current_lead_provider, course: create(:course, identifier: "other-course"))
      end

      before do
        application.course_cohort.update_columns(academic_year: 2025, term_identifier: "autumn")
        other_course_application.course_cohort.update_columns(academic_year: 2026, term_identifier: "spring")
      end

      it "filters by course and excludes other courses" do
        list(params: { filter: { course: application.course.identifier } })

        expect(ids).to include(application.ecf_id)
        expect(ids).not_to include(other_course_application.ecf_id)
      end

      it "accepts several comma-separated courses" do
        list(params: { filter: { course: "#{application.course.identifier},other-course" } })

        expect(ids).to include(application.ecf_id, other_course_application.ecf_id)
      end

      it "filters by academic_year and excludes other years" do
        list(params: { filter: { academic_year: "2025" } })

        expect(ids).to include(application.ecf_id)
        expect(ids).not_to include(other_course_application.ecf_id)
      end

      it "filters by term and excludes other terms" do
        list(params: { filter: { term: "spring" } })

        expect(ids).to include(other_course_application.ecf_id)
        expect(ids).not_to include(application.ecf_id)
      end

      it "combines filters with AND" do
        list(params: { filter: { course: application.course.identifier, term: "spring" } })

        expect(ids).not_to include(application.ecf_id, other_course_application.ecf_id)
      end

      it "filters by funding_eligible" do
        list(params: { filter: { funding_eligible: application.eligible_for_funding.to_s } })

        expect(ids).to include(application.ecf_id)
        expect(ids).not_to include(other.ecf_id)
      end

      it "matches no training for funding_uplift as it is always null" do
        list(params: { filter: { funding_uplift: "true" } })

        expect(ids).to eq([])
      end

      it "filters by teacher_trn" do
        application.user.update!(trn: "0000123")
        list(params: { filter: { teacher_trn: "0000123" } })

        expect(ids).to eq([application.ecf_id])
      end

      it "filters by teacher_ecf_id" do
        list(params: { filter: { teacher_ecf_id: application.user.ecf_id } })

        expect(ids).to eq([application.ecf_id])
      end

      it "filters by teacher_email" do
        list(params: { filter: { teacher_email: application.user.email } })

        expect(ids).to eq([application.ecf_id])
      end

      it "filters by updated_since" do
        other.update_columns(updated_at: 2.days.ago)
        list(params: { filter: { updated_since: 1.day.ago.iso8601 } })

        expect(ids).to include(application.ecf_id)
        expect(ids).not_to include(other.ecf_id)
      end

      it "rejects a malformed boolean filter" do
        list(params: { filter: { funding_eligible: "maybe" } })

        expect(response).to have_http_status(:bad_request)
      end

      it "rejects a malformed updated_since" do
        list(params: { filter: { updated_since: "yesterday" } })

        expect(json["errors"]).to be_present
      end

      it "rejects a non-hash filter" do
        list(params: { filter: "abc" })

        expect(response).to have_http_status(:bad_request)
        expect(json["errors"]).to be_present
      end

      it "rejects an array filter value instead of ignoring it" do
        list(params: { filter: { course: %w[x] } })

        expect(response).to have_http_status(:bad_request)
      end

      it "rejects nested filter values" do
        list(params: { filter: { course: { a: "b" } } })

        expect(response).to have_http_status(:bad_request)
      end

      it "rejects unsupported filter keys" do
        list(params: { filter: { unknown: "x" } })

        expect(response).to have_http_status(:bad_request)
      end

      it "rejects a malformed teacher_ecf_id" do
        list(params: { filter: { teacher_ecf_id: "nope" } })

        expect(response).to have_http_status(:bad_request)
      end
    end

    context "with pagination" do
      before { create_list(:application, 6, lead_provider: current_lead_provider) }

      it "orders by application id" do
        list(params: { page: { per_page: 3 } })

        expect(ids).to eq(Application.order(:id).limit(3).pluck(:ecf_id))
      end

      it "links to the next page preserving filters and include" do
        list(params: { page: { per_page: 3 }, include: "teacher", filter: { updated_since: "2000-01-01T00:00:00Z" } })
        next_link = Rack::Utils.parse_nested_query(URI(json["links"]["next"]).query)

        expect(next_link).to include("include" => "teacher", "filter" => { "updated_since" => "2000-01-01T00:00:00Z" }, "page" => { "page" => "2", "per_page" => "3" })
      end

      it "has no invented totals" do
        list(params: { page: { per_page: 3 } })

        expect(json["meta"].keys).to contain_exactly("page", "per_page")
      end

      it "rejects an invalid page" do
        list(params: { page: { page: "0" } })

        expect(response).to have_http_status(:bad_request)
        expect(json["errors"]).to be_present
      end
    end

    describe "query counts" do
      let(:user) { create(:user) }

      def add_trainings(count)
        count.times do
          create(:application, lead_provider: current_lead_provider, user:, course: create(:course))
        end
      end

      [nil, "teacher,outcome,expected_declarations"].each do |include_param|
        it "does not grow with the number of rows (include: #{include_param.inspect})" do
          params = include_param ? { include: include_param } : {}
          add_trainings(2)
          list(params:) # warm caches such as token lookup
          small = count_queries { list(params:) }
          add_trainings(4)
          large = count_queries { list(params:) }

          expect(large).to eq(small)
        end
      end
    end

    context "with outcomes" do
      let(:declaration_factory_args) { { application:, lead_provider: current_lead_provider, user: application.user } }
      let!(:completed) { create(:declaration, :completed, :payable, **declaration_factory_args) }
      let!(:outcome) { create(:participant_outcome, declaration: completed, state: "passed", completion_date: Date.new(2025, 6, 1)) }

      it "links the provider's outcome and includes its state and date" do
        list(params: { include: "outcome" })
        included = json["included"].find { |i| i["type"] == "outcome" }

        expect(json["data"].first["relationships"]["outcome"]["data"]).to eq("type" => "outcome", "id" => outcome.ecf_id)
        expect(included["attributes"]).to include("state" => "passed", "completion_date" => "2025-06-01")
      end

      it "does not expose an outcome of a voided completed declaration" do
        completed.update_columns(state: "voided")
        list(params: { include: "outcome" })

        expect(json["data"].first["relationships"]["outcome"]["data"]).to be_nil
        expect(json["included"]).to eq([])
      end

      it "does not expose an outcome of a declaration of a previous provider" do
        previous = create(:lead_provider)
        previous_app = create(:application, lead_provider: previous)
        previous_declaration = create(:declaration, :completed, :payable, application: previous_app, lead_provider: previous, user: previous_app.user)
        create(:participant_outcome, declaration: previous_declaration)
        previous_app.change_provider!(to: current_lead_provider)
        list(params: { include: "outcome" })
        entry = json["data"].find { |t| t["id"] == previous_app.ecf_id }

        expect(entry["relationships"]["outcome"]["data"]).to be_nil
        expect(json["included"].map { |i| i["id"] }).not_to include(previous_declaration.participant_outcomes.first.ecf_id)
      end
    end

    context "without an institution" do
      it "returns null institution fields" do
        application.update_columns(institution_id: nil)
        list

        expect(json["data"].first["attributes"]["institution"].values).to all(be_nil)
      end
    end

    context "with an institution" do
      {
        school: "school",
        private_childcare_provider: "private_childcare_provider",
        local_authority: "local_authority",
      }.each do |factory, expected_type|
        it "returns institution_type #{expected_type} and no category key" do
          institutionable = build(factory).tap(&:save!)
          institution = institutionable.institution
          application.update_columns(institution_id: institution.id)
          list
          attributes = json["data"].first["attributes"]["institution"]

          expect(attributes).to include("institution_type" => expected_type, "reference_number" => institution.institution_reference_number)
          expect(attributes).not_to have_key("category")
        end
      end
    end

    it "returns JSON:API errors for unknown V2 paths" do
      api_get("/api/v2/thisdoesnotexist", lead_provider: current_lead_provider)

      expect(response).to have_http_status(:not_found)
      expect(response.media_type).to eq("application/vnd.api+json")
      expect(json["errors"].first).to include("status" => "404")
    end
  end

  def count_queries(&)
    count = 0
    counter = ->(*, payload) { count += 1 unless payload[:name] == "SCHEMA" || payload[:cached] }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &)
    count
  end
end
