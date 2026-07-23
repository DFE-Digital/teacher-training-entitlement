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

        def self.permitted_params
          %i[
            declaration_type
            acceptance_window_start_date
            acceptance_window_end_date
            payment_amount
          ]
        end
      end
    end
  end
end
