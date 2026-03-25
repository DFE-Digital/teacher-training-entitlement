require "rails_helper"

RSpec.describe "Schedule endpoints", type: :request do
  let(:current_lead_provider) { create(:lead_provider) }
  let(:serializer) { API::ScheduleSerializer }
  let(:serializer_version) { :v1 }

  describe "GET /api/v1/schedules" do
    let(:cohort) { create(:cohort, :current) }
    let(:course) { create(:course, :tte_early_years) }
    let(:schedule) { create(:schedule, :tte_reception_autumn, cohort:) }
    let!(:course_cohort) { create(:course_cohort, course:, cohort:, schedule:, lead_providers: [current_lead_provider]) }

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
        expect(attrs["schedule_identifier"]).to eq(schedule.identifier)
        expect(attrs["cohort"]).to eq(cohort.start_year.to_s)
      end

      it "does not return schedules for other lead providers" do
        other_lp = create(:lead_provider)
        other_schedule = create(:schedule, :tte_reception_spring, cohort:)
        create(:course_cohort, course:, cohort:, schedule: other_schedule, lead_providers: [other_lp])

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
