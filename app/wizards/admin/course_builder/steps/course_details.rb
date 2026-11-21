module Admin
  module CourseBuilder
    module Steps
      class CourseDetails
        include DfE::Wizard::Step

        attribute :name, :string
        attribute :identifier, :string
        attribute :short_code, :string
        attribute :course_group, :string
        attribute :description, :string
        attribute :funding_eligibility, :string

        validates :name, :course_group, presence: true
        validates :funding_eligibility, inclusion: { in: ->(_step) { FundingEligibilities.keys } }

        def self.permitted_params
          %i[name identifier short_code course_group description funding_eligibility]
        end
      end
    end
  end
end
