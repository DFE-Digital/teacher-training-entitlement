module Admin
  module CourseBuilder
    module Steps
      class ContractFinancials
        include DfE::Wizard::Step

        attribute :academic_year, :integer
        attribute :contract_financials, default: -> { {} }

        def self.permitted_params
          [:academic_year, { contract_financials: {} }]
        end

        def contract_financials=(value)
          super(normalize(value))
        end

        def contract_financial_data(lead_provider)
          contract_financials.fetch(lead_provider.id.to_s, {})
        end

        def contract_financial_selected?(lead_provider)
          ActiveModel::Type::Boolean.new.cast(contract_financial_data(lead_provider)["selected"])
        end

      private

        def normalize(value)
          (value || {}).to_h.transform_values do |attributes|
            attributes.to_h.slice("selected", "teacher_funding", "recruitment_target")
          end
        end
      end
    end
  end
end
