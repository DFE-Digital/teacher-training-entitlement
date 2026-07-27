module Admin
  module CourseBuilder
    module Steps
      class CreatePolicyPeriod
        include DfE::Wizard::Step

        attribute :start_date, :date, default: -> { Admin::CourseBuilder::Steps::CreatePolicyPeriod.default_start_date }
        attribute :end_date, :date, default: -> { Admin::CourseBuilder::Steps::CreatePolicyPeriod.default_end_date }

        validates :start_date, :end_date, presence: true

        def self.default_start_date
          Time.zone.today.next_month.beginning_of_month
        end

        def self.default_end_date
          default_start_date.advance(years: 3)
        end

        def self.permitted_params
          %i[
            start_date
            end_date
          ]
        end
      end
    end
  end
end
