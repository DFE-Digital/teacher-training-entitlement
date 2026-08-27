module Registrations
  module Courses
    module Npd
      class CompletionService < Registrations::BaseStepService
        def call
          ActiveRecord::Base.transaction do
            application = user.applications.create!(
              course_cohort: CourseCohort.next_open_for(course: Course.reception),
              application_lead_providers: [ApplicationLeadProvider.new(current: true, lead_provider_id: store["lead_provider_id"], assigned_at: Time.zone.now)],
              institution: (Institution.find(wizard.state_store["institution_id"]) if wizard.state_store["institution_id"].present?),
              eligible_for_funding: store["funding_eligibility_result"] == "funded",
              funding_eligiblity_status_code: store["funding_eligibility_result"],
              funding_choice: nil,
              teacher_catchment: store["teacher_catchment"],
              works_in_school: true,
              work_setting: store["tell_us_where_you_work"],
              raw_application_data: store.read.except("current_user", "current_user_id"),
              status: Application::PENDING,
            )

            store.write(application_ecf_id: application.ecf_id)
          end
        end

      private

        def user
          @user = User.find_by_email("ben.keeping@education.gov.uk")
          # @user ||= store["current_user"].presence || User.find(store["current_user_id"])
        end

        def store
          @store ||= wizard.state_store
        end
      end
    end
  end
end
