module API
  module V2
    class TrainingPresenter
      DEFAULT_FUNDING_CHOICE = "dfe".freeze
      INSTITUTION_TYPES = {
        "School" => "school",
        "PrivateChildcareProvider" => "private_childcare_provider",
        "LocalAuthority" => "local_authority",
      }.freeze

      attr_reader :application, :assignment, :outcome

      delegate :ecf_id, :status, :created_at, :institution, to: :application, allow_nil: true
      delegate :assigned_at, :unassigned_at, to: :assignment

      # outcome: the latest outcome visible to the requesting provider, preloaded by the caller.
      def initialize(assignment, outcome: nil)
        @assignment = assignment
        @outcome = outcome
        @application = assignment.application
      end

      def id
        ecf_id
      end

      def contract_assigned_at
        assigned_at
      end

      def contract_unassigned_at
        unassigned_at
      end

      def updated_at
        application.updated_at
      end

      # Training notification email; temporarily the teacher's email.
      def email
        teacher.email
      end

      # Not yet sourced.
      def status_reason
        nil
      end

      def teacher
        application.user
      end

      def teacher_id
        teacher.trn.presence || teacher.ecf_id
      end

      def contract_id
        application.course_cohort.ecf_id
      end

      def course
        {
          identifier: application.course_cohort.course.identifier,
          role: nil,
          experience: nil,
        }
      end

      def institution_type
        INSTITUTION_TYPES[institution&.institutionable_type]
      end

      def institution_details
        {
          institution_type: institution_type,
          reference_number: institution&.institution_reference_number,
          ukprn: institution&.ukprn,
          country_code: institution&.alpha3_country_code,
          subdivision: institution&.subdivision_code,
        }
      end

      def funding
        {
          eligible: application.eligible_for_funding,
          uplift: nil,
          confirmed: application.funded_place,
          choice: application.funding_choice || DEFAULT_FUNDING_CHOICE,
          reason: application.ineligible_for_funding_reason,
          confirmation_reason: nil,
        }
      end

      def outcome_id
        outcome&.ecf_id
      end

      # No survey data exists in the service yet.
      def surveys
        []
      end

      def survey_ids
        []
      end

      def expected_declarations
        @expected_declarations ||= application.course_cohort.milestones.map do |milestone|
          ExpectedDeclaration.new(ecf_id, milestone.declaration_type)
        end
      end

      def expected_declaration_ids
        expected_declarations.map(&:id)
      end
    end
  end
end
