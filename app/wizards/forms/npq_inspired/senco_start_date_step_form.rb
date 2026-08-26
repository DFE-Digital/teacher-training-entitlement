module Forms
  module NpqInspired
    class SencoStartDateStepForm < CustomRegistrationStepForm
      include DfE::Wizard::Step

      attribute :senco_start_month, :integer
      attribute :senco_start_year, :integer

      validates :senco_start_month,
                presence: true,
                numericality: { only_integer: true, in: 1..12 }
      validates :senco_start_year,
                presence: true,
                numericality: {
                  only_integer: true,
                  greater_than_or_equal_to: 1960,
                  less_than_or_equal_to: ->(_) { Time.zone.today.year },
                }
      validate :start_date_is_not_in_the_future

      def view_component(form:, registration_step:)
        Registrations::NpqInspired::SencoStartDateComponent.new(step: self, form:, registration_step:)
      end

      def form_param_names
        %i[senco_start_month senco_start_year]
      end

    private

      def start_date_is_not_in_the_future
        return unless valid_month_and_year?
        return unless Date.new(senco_start_year, senco_start_month, 1).future?

        errors.add(:senco_start_month, "and year must not be in the future")
      end

      def valid_month_and_year?
        senco_start_month.in?(1..12) && senco_start_year.to_i >= 1960
      end
    end
  end
end
