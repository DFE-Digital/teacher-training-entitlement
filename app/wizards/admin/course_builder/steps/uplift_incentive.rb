module Admin
  module CourseBuilder
    module Steps
      class UpliftIncentive
        include DfE::Wizard::Step

        attribute :uplift_percentage, :string

        validates :uplift_percentage,
                  numericality: {
                    greater_than_or_equal_to: 0,
                    less_than_or_equal_to: 100,
                    message: "Enter an uplift percentage between 0 and 100",
                  },
                  allow_blank: true
        validate :uplift_percentage_has_at_most_two_decimal_places

        def self.permitted_params
          %i[uplift_percentage]
        end

        def uplift_percentage=(value)
          super(value.to_s.strip.presence)
        end

      private

        # contract_years.uplift_percentage stores the fraction with scale 4,
        # so 2 decimal places in the percentage is all we can keep.
        def uplift_percentage_has_at_most_two_decimal_places
          return if uplift_percentage.blank? || errors.include?(:uplift_percentage)

          percentage = BigDecimal(uplift_percentage, exception: false)
          return if percentage.nil? || percentage.round(2) == percentage

          errors.add(:uplift_percentage, "Enter an uplift percentage with no more than 2 decimal places")
        end
      end
    end
  end
end
