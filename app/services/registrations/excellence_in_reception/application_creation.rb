module Registrations
  module ExcellenceInReception
    class ApplicationCreation
      def initialize(wizard_step:)
        @wizard_step = wizard_step
        @user = wizard_step.wizard.current_user
        wizard_data = wizard_step.wizard.data
        @store_data = wizard_data.fetch(:steps, {}).values.reduce({}, :merge).merge(wizard_data.except(:steps)).stringify_keys
      end

      def call
        ActiveRecord::Base.transaction do
          application = @user.applications.create!(
            course_cohort:,
            application_lead_providers: [
              ApplicationLeadProvider.new(
                current: true,
                lead_provider_id: @store_data["lead_provider_id"],
                assigned_at: Time.zone.now,
              ),
            ],
            institution:,
            funding_eligibility: @store_data["funding_eligibility_result"],
            funding_choice: funded? ? nil : @store_data["funding"],
            registration_data:,
            status: Application::PENDING,
          )

          @wizard_step.wizard.state_store.write(application_ecf_id: application.ecf_id)
          Emails::SendApplicationSubmissionEmailJob.perform_later(application:)
        end
      end

    private

      def registration_data
        @store_data.except("generated_confirmation_code", "current_user",
                           "current_user_id", "funding_eligibility_result",
                           "check_your_answers_and_submit",
                           "_display_values")
      end

      def course_cohort
        @course_cohort ||= CourseCohort.find_by(ecf_id: @store_data["course_cohort_ecf_id"])
      end

      def inside_catchment?
        @store_data["teacher_catchment"] == Institution::ENGLAND_SUBDIVISION_CODE
      end

      def institution
        return nil unless inside_catchment? && @store_data["institution_id"].present?

        @institution ||= Institution.find(@store_data["institution_id"])
      end

      def funded?
        @store_data["funding_eligibility_result"] == "funded"
      end
    end
  end
end
