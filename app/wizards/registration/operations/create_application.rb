module Registration
  module Operations
    # Creates the application from the confirmed answers. It runs after the step
    # is validated. Once the application exists the answers are cleared, so that
    # going back cannot submit twice, and only the created application is kept
    # to show the registration submitted page.
    class CreateApplication
      # The answers saved in `applications.registration_data`. They are the keys
      # of the legacy journey, which the analytics team consumes: do not add,
      # rename or remove one without an analytics review. Wizard internal keys
      # are not part of it.
      REGISTRATION_DATA_KEYS = %w[
        teacher_catchment
        work_setting
        institution_id
        institution_name
        funding
        course_start_date
        course_cohort_ecf_id
        lead_provider_id
        can_share_choices
      ].freeze

      def initialize(repository:, step:)
        @repository = repository
        @step = step
      end

      def execute
        service = Applications::Create.new(
          user: state_store.current_user,
          course_cohort: state_store.course_cohort,
          lead_provider: state_store.lead_provider,
          institution: state_store.institution,
          registration_data:,
          **FundingEligibilities.for_course(state_store.course).submission_attributes(state_store),
        )

        return failure(service) unless service.call

        @repository.clear
        @repository.write(StateStore::SUBMITTED_APPLICATION_KEY => service.application.id)

        { success: true }
      end

      def rollback; end

    private

      def state_store
        @step.wizard.state_store
      end

      # Cleared answers are stored as nil, the legacy journey deleted them.
      # `funding_amount` is always empty once submitted, as in the legacy journey.
      def registration_data
        answers = state_store.read.to_h.stringify_keys.slice(*REGISTRATION_DATA_KEYS).compact
        answers["course_cohort_ecf_id"] = answers["course_start_date"]

        answers.merge("funding_amount" => nil, "submitted" => true)
      end

      def failure(service)
        @step.errors.add(:base, :submission_failed)
        Rails.logger.warn("Registration submission failed: #{service.errors.full_messages.to_sentence}")

        { success: false, errors: @step.errors }
      end
    end
  end
end
