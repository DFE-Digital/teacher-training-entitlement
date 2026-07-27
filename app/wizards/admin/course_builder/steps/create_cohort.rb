module Admin
  module CourseBuilder
    module Steps
      class CreateCohort
        include DfE::Wizard::Step

        attribute :description, :string
        attribute :registration_starts_at, :date, default: -> { Admin::CourseBuilder::Steps::CreateCohort.default_registration_starts_at }
        attribute :registration_ends_at, :date, default: -> { Admin::CourseBuilder::Steps::CreateCohort.default_registration_ends_at }
        attribute :funding_cap, :boolean

        validates :description, :registration_starts_at, presence: true

        def initialize(attributes = {})
          super

          self.registration_starts_at ||= self.class.default_registration_starts_at
          self.registration_ends_at ||= self.class.default_registration_ends_at
        end

        def self.default_registration_starts_at
          Time.zone.today.next_month.beginning_of_month
        end

        def self.default_registration_ends_at
          Time.zone.today.advance(months: 2).beginning_of_month
        end

        def self.permitted_params
          %i[
            description
            registration_starts_at
            registration_ends_at
            funding_cap
          ]
        end
      end
    end
  end
end
