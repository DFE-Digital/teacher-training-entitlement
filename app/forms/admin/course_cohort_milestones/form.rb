module Admin
  module CourseCohortMilestones
    class Form
      include ActiveModel::Model
      include ActiveModel::Attributes

      DATE_ATTRIBUTE_KEYS = %i[
        acceptance_window_start_date
        acceptance_window_end_date
      ].freeze

      ATTRIBUTE_KEYS = %i[
        declaration_type
        payment_amount
      ].concat(DATE_ATTRIBUTE_KEYS).freeze

      FORM_ATTRIBUTE_KEYS = (
        ATTRIBUTE_KEYS +
        DATE_ATTRIBUTE_KEYS.flat_map { |attribute| [:"#{attribute}(1i)", :"#{attribute}(2i)", :"#{attribute}(3i)"] }
      ).freeze

      attribute :declaration_type, :string
      attribute :payment_amount, :decimal
      attribute :acceptance_window_start_date, :date
      attribute :acceptance_window_end_date, :date

      attr_reader :taken_declaration_types

      def initialize(attributes = {}, taken_declaration_types: [])
        @taken_declaration_types = taken_declaration_types

        attributes = attributes.with_indifferent_access

        super(attributes
              .except(*date_parameter_keys)
              .merge(date_attributes_from_params(attributes))
              .slice(*ATTRIBUTE_KEYS)
              .compact)
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
    end
  end
end
