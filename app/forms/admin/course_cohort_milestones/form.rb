module Admin
  module CourseCohortMilestones
    class Form
      include ActiveModel::Model
      include ActiveModel::Attributes

      ATTRIBUTE_KEYS = %i[
        declaration_type
        acceptance_window_start_offset
        acceptance_window_end_offset
        payment_percentage
      ].freeze

      FORM_ATTRIBUTE_KEYS = ATTRIBUTE_KEYS.freeze

      attribute :declaration_type, :string
      attribute :acceptance_window_start_offset, :integer
      attribute :acceptance_window_end_offset, :integer
      attribute :payment_percentage, :decimal

      attr_reader :taken_declaration_types

      def initialize(attributes = {}, taken_declaration_types: [])
        @taken_declaration_types = taken_declaration_types

        attributes = attributes.with_indifferent_access
        attributes[:payment_percentage] = payment_percentage_for_form(attributes)

        super(attributes.slice(*ATTRIBUTE_KEYS).compact)
      end

      def milestone_attributes
        attributes.symbolize_keys.merge(
          payment_percentage: payment_percentage_for_milestone,
        )
      end

      def declaration_type_taken?(declaration_type)
        declaration_type.in?(taken_declaration_types)
      end

      def date_attributes_from_params(attributes)
        DATE_ATTRIBUTE_KEYS.index_with { |attribute| date_from_params(attributes, attribute) }
      end

      def date_from_params(attributes, attribute)
        return attributes[attribute] if attributes[attribute].present?

        year = attributes[:"#{attribute}(1i)"]
        month = attributes[:"#{attribute}(2i)"]
        day = attributes[:"#{attribute}(3i)"]
        return if [year, month, day].any?(&:blank?)

        Date.new(year.to_i, month.to_i, day.to_i)
      end

      def date_parameter_keys
        DATE_ATTRIBUTE_KEYS.flat_map { |attribute| [:"#{attribute}(1i)", :"#{attribute}(2i)", :"#{attribute}(3i)"] }
      end

      def payment_percentage_for_form(attributes)
        return attributes[:payment_percentage] unless attributes.key?(:id) && attributes[:payment_percentage].present?

        BigDecimal(attributes[:payment_percentage].to_s) * 100
      end

      def payment_percentage_for_milestone
        return if payment_percentage.blank?

        payment_percentage / 100
      end
    end
  end
end
