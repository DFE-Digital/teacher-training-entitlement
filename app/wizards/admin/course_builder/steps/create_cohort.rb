module Admin
  module CourseBuilder
    module Steps
      class CreateCohort
        include DfE::Wizard::Step

        attribute :description, :string
        attribute :registration_starts_at, :date
        attribute :registration_ends_at, :date
        attribute :funding_cap, :boolean

        validates :description, :registration_starts_at, presence: true

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
