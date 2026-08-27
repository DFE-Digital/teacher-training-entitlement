require "rails_helper"

RSpec.describe "Course cohorts endpoints", type: :request do
  let(:current_lead_provider) { create(:lead_provider) }
  let(:serializer) { API::ScheduleSerializer }
  let(:serializer_version) { :v1 }

  describe "GET /api/v1/schedules" do
    let(:course) { create(:course, :npd_eirt) }
    let!(:course_cohort) { create(:course_cohort, course:, lead_providers: [current_lead_provider]) }

    context "when authorized" do
      before { api_get(api_v1_schedules_path) }

      it "returns 200" do
        expect(response.status).to eq(200)
      end

      it "returns schedules for the lead provider" do
        expect(parsed_response["data"].length).to eq(1)
        expect(parsed_response["data"].first["id"]).to eq(course_cohort.ecf_id)
      end

      it "includes the correct attributes" do
        attrs = parsed_response["data"].first["attributes"]
        expect(attrs["course_identifier"]).to eq(course.identifier)
        expect(attrs["schedule_identifier"]).to eq(course_cohort.schedule_identifier)
        expect(attrs["cohort"]).to eq(course_cohort.academic_year)
      end

      it "does not return schedules for other lead providers" do
        other_lp = create(:lead_provider)
        create(:course_cohort, course:, lead_providers: [other_lp])

        api_get(api_v1_schedules_path)

        expect(parsed_response["data"].length).to eq(0)
      end
    end

    context "when unauthorized" do
      before { api_get(api_v1_schedules_path, token: "bad-token") }

      it "returns 401" do
        expect(response.status).to eq(401)
      end
    end
  end
end
