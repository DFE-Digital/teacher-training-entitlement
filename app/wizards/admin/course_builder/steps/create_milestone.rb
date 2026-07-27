module Admin
  module CourseBuilder
    module Steps
      class CreateMilestone
        include DfE::Wizard::Step

        attribute :declaration_type, :string
        attribute :acceptance_window_start_date, :date
        attribute :acceptance_window_end_date, :date
        attribute :payment_amount, :decimal

        validates :declaration_type, :acceptance_window_start_date, presence: true
        validates :declaration_type, inclusion: Milestone::DECLARATION_TYPES
        validates :payment_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

        def initialize(attributes = {})
          super

          self.acceptance_window_start_date ||= default_acceptance_window_start_date
          self.acceptance_window_end_date ||= acceptance_window_start_date&.advance(months: 2)
        end

        def self.permitted_params
          %i[
            declaration_type
            acceptance_window_start_date
            acceptance_window_end_date
            payment_amount
          ]
        end

      private

        def default_acceptance_window_start_date
          wizard&.step(:create_course_cohort)&.training_ends_at
        end
      end
    end
  end
end
