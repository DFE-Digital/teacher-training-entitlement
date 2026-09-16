module Admin
  module CourseBuilder
    module Steps
      class ContractFinancials
        include DfE::Wizard::Step

        GENERIC_ACADEMIC_YEAR_KEY = "generic".freeze
        FINANCIAL_ATTRIBUTES = %w[selected teacher_funding recruitment_target].freeze

        attribute :academic_year_to_add, :integer
        attribute :academic_years, default: -> { [] }
        attribute :contract_financials, default: -> { {} }

        def self.permitted_params
          [:academic_year_to_add, { academic_years: [], contract_financials: {} }]
        end

        def academic_years=(value)
          super(normalize_academic_years(value))
        end

        def contract_financials=(value)
          super(normalize(value))
        end

        def academic_year_keys
          numeric_academic_years = [
            *academic_years,
            *contract_financials.keys,
          ].compact_blank.filter_map { |key| normalize_academic_year_key(key) }

          [
            GENERIC_ACADEMIC_YEAR_KEY,
            *numeric_academic_years.uniq.sort,
          ]
        end

        def academic_year_label(academic_year_key)
          return "Generic" if academic_year_key == GENERIC_ACADEMIC_YEAR_KEY

          academic_year_key
        end

        def contract_financial_data(academic_year_key, lead_provider)
          contract_financials.dig(academic_year_key.to_s, lead_provider.id.to_s) || {}
        end

        def contract_financial_selected?(academic_year_key, lead_provider)
          ActiveModel::Type::Boolean.new.cast(contract_financial_data(academic_year_key, lead_provider).fetch("selected", true))
        end

      private

        def normalize_academic_years(value)
          Array(value).compact_blank.filter_map { |year| Integer(year, exception: false) }.uniq
        end

        def normalize_academic_year_key(key)
          return if key.to_s == GENERIC_ACADEMIC_YEAR_KEY

          Integer(key, exception: false)
        end

        def normalize(value)
          (value || {}).to_h.transform_values do |lead_provider_attributes|
            lead_provider_attributes.to_h.transform_values do |attributes|
              attributes.to_h.slice(*FINANCIAL_ATTRIBUTES)
            end
          end
        end
      end
    end
  end
end
