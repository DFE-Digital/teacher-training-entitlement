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

        def self.permitted_params
          %i[uplift_percentage]
        end

        def uplift_percentage=(value)
          super(value.to_s.strip.presence)
        end
      end
    end
  end
end
