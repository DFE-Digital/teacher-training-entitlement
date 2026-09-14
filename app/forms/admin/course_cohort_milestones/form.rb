module Admin
  module CourseCohortMilestones
    class Form
      include ActiveModel::Model
      include ActiveModel::Attributes

      ATTRIBUTE_KEYS = %i[
        declaration_type
        acceptance_window_start_offset
        acceptance_window_end_offset
        payment_amount
      ].freeze

      FORM_ATTRIBUTE_KEYS = ATTRIBUTE_KEYS.freeze

      attribute :declaration_type, :string
      attribute :acceptance_window_start_offset, :integer
      attribute :acceptance_window_end_offset, :integer
      attribute :payment_amount, :decimal

      attr_reader :taken_declaration_types

      def initialize(attributes = {}, taken_declaration_types: [])
        @taken_declaration_types = taken_declaration_types

        attributes = attributes.with_indifferent_access

        super(attributes.slice(*ATTRIBUTE_KEYS).compact)
      end

      def declaration_type_taken?(declaration_type)
        declaration_type.in?(taken_declaration_types)
      end
    end
  end
end
