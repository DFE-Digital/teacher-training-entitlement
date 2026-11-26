module API
  module V2
    # Shapes one provider assignment of an application for ApplicationSerializer.
    class ApplicationPresenter
      DEFAULT_FUNDING_CHOICE = "dfe".freeze
      INSTITUTION_CATEGORIES = {
        "School" => "school",
        "PrivateChildcareProvider" => "private_childcare_provider",
        "LocalAuthority" => "local_authority",
      }.freeze

      attr_reader :application, :assignment, :outcome

      delegate :email, :created_at, to: :application

      # outcome: the latest outcome visible to the requesting provider, preloaded by the caller.
      def initialize(assignment, outcome: nil)
        @assignment = assignment
        @outcome = outcome
        @application = assignment.application
      end

      def id
        application.ecf_id
      end

      # Latest change to the application or the related records it exposes; selected by
      # Applications::Query so clients can resume a sync with filter[updated_since].
      def updated_at
        assignment.effective_updated_at
      end

      def contract_assigned_at
        assignment.assigned_at
      end

      def contract_unassigned_at
        assignment.unassigned_at
      end

      # Applications the provider was previously assigned to read as reassigned, as in V1.
      def status
        assignment.current? ? application.status : Application::REASSIGNED
      end

      # Not yet sourced.
      def status_reason
        nil
      end

      def course
        {
          identifier: contract.course.identifier,
          role: nil,
          experience: nil,
        }
      end

      def institution
        institution = application.institution

        {
          category: INSTITUTION_CATEGORIES[institution&.institutionable_type],
          reference_number: institution&.institution_reference_number,
          ukprn: institution&.ukprn,
          country_code: institution&.alpha3_country_code,
          subdivision: institution&.subdivision_code,
        }
      end

      def funding
        {
          eligible: application.eligible_for_funding?,
          uplift: nil,
          confirmed: application.funded_place,
          choice: application.funding_choice || DEFAULT_FUNDING_CHOICE,
          reason: application.funding_ineligible_reason,
          confirmation_reason: nil,
        }
      end

      def teacher
        application.user
      end

      def teacher_id
        TeacherSerializer.identifier(teacher)
      end

      def contract
        application.course_cohort
      end

      def contract_id
        contract.ecf_id
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

      # In course milestone order; sorted in memory so the preloaded milestones need no query.
      def expected_declarations
        @expected_declarations ||= contract.course.milestones.sort_by(&:declaration_sort_order).map do |milestone|
          ExpectedDeclaration.new(id, milestone.declaration_type)
        end
      end

      def expected_declaration_ids
        expected_declarations.map(&:id)
      end
    end
  end
end
