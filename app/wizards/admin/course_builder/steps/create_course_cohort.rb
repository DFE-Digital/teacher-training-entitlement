module Admin
  module CourseBuilder
    module Steps
      class CreateCourseCohort
        include DfE::Wizard::Step

        attribute :participant_funding, :decimal
        attribute :service_fee, :decimal
        attribute :registration_starts_at, :date
        attribute :registration_ends_at, :date
        attribute :training_starts_at, :date
        attribute :training_ends_at, :date

        validates :participant_funding, :service_fee, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

        def self.permitted_params
          %i[
            participant_funding
            service_fee
            registration_starts_at
            registration_ends_at
            training_starts_at
            training_ends_at
          ]
        end
      end
    end
  end
end
