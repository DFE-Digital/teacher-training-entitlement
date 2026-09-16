module Admin
  module CourseBuilder
    module Steps
      class Milestones
        include DfE::Wizard::Step

        REQUIRED_MILESTONE_TYPES = [
          Milestone::STARTED,
          Milestone::COMPLETED,
        ].freeze

        OFFSET_OPTIONS = (1..12).map { |months|
          ["#{months} #{'month'.pluralize(months)}", months]
        }.freeze

        attribute :milestones, default: -> { {} }

        validates :milestone_types, presence: true
        validate :milestone_types_are_supported
        validate :offsets_are_supported

        def self.permitted_params
          [{ milestones: {} }]
        end

        def milestones=(value)
          super(normalize(value))
        end

        def milestone_types
          selected_milestone_types = milestones.filter_map do |declaration_type, attributes|
            declaration_type if ActiveModel::Type::Boolean.new.cast(attributes["selected"])
          end

          selected_milestone_types | REQUIRED_MILESTONE_TYPES
        end

        def required_milestone_type?(milestone_type)
          milestone_type.in?(REQUIRED_MILESTONE_TYPES)
        end

        def milestone_selected?(milestone_type)
          ActiveModel::Type::Boolean.new.cast(milestone_data(milestone_type)["selected"])
        end

        def milestone_data(milestone_type)
          default_milestone_data(milestone_type).merge(milestones.fetch(milestone_type, {}))
        end

      private

        def default_milestone_data(milestone_type)
          {
            "selected" => required_milestone_type?(milestone_type),
            "acceptance_window_start_offset" => 6,
            "acceptance_window_end_offset" => 8,
          }
        end

        def normalize(value)
          milestone_data = (value || {}).to_h.transform_values do |attributes|
            attributes = attributes.to_h.slice(
              "selected",
              "acceptance_window_start_offset",
              "acceptance_window_end_offset",
              "payment_percentage",
            )

            attributes["acceptance_window_start_offset"] = Integer(
              attributes["acceptance_window_start_offset"],
              exception: false,
            )
            attributes["acceptance_window_end_offset"] = Integer(
              attributes["acceptance_window_end_offset"],
              exception: false,
            )
            attributes["payment_percentage"] = attributes["payment_percentage"].presence
            attributes
          end

          REQUIRED_MILESTONE_TYPES.each do |milestone_type|
            milestone_data[milestone_type] = default_milestone_data(milestone_type)
                                            .merge(milestone_data.fetch(milestone_type, {}), "selected" => true)
          end

          milestone_data
        end

        def milestone_types_are_supported
          unsupported_types = milestone_types - Milestone::DECLARATION_TYPES
          return if unsupported_types.empty?

          errors.add(:milestone_types, "include unsupported milestone types")
        end

        def offsets_are_supported
          supported_offsets = OFFSET_OPTIONS.map(&:last)

          milestone_types.each do |milestone_type|
            data = milestone_data(milestone_type)
            validate_offset(milestone_type, :acceptance_window_start_offset, data, supported_offsets)
            validate_offset(milestone_type, :acceptance_window_end_offset, data, supported_offsets)
          end
        end

        def validate_offset(milestone_type, attribute, data, supported_offsets)
          return if data[attribute.to_s].in?(supported_offsets)

          errors.add(:"#{milestone_type}_#{attribute}", "is not included in the list")
        end
      end
    end
  end
end
