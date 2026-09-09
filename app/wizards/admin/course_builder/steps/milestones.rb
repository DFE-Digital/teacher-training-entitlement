module Admin
  module CourseBuilder
    module Steps
      class Milestones
        include DfE::Wizard::Step

        attribute :milestone_types, default: -> { [] }

        validates :milestone_types, presence: true
        validate :milestone_types_are_supported

        def self.permitted_params
          [{ milestone_types: [] }]
        end

        def milestone_types=(value)
          super(Array(value).reject(&:blank?))
        end

      private

        def milestone_types_are_supported
          unsupported_types = milestone_types - Milestone::DECLARATION_TYPES
          return if unsupported_types.empty?

          errors.add(:milestone_types, "include unsupported milestone types")
        end
      end
    end
  end
end
