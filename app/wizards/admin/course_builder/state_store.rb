module Admin
  module CourseBuilder
    class StateStore
      include DfE::Wizard::Core::StateStore

      CourseDetails = Struct.new(:name, :identifier, :short_code, :course_group, :description, keyword_init: true)
      MilestoneConfig = Struct.new(:declaration_type, :acceptance_window_start_offset, :acceptance_window_end_offset, :payment_percentage, keyword_init: true)
      SelectedLeadProvider = Struct.new(:lead_provider, :url, :email, keyword_init: true)
      SelectedContractFinancial = Struct.new(:lead_provider, :academic_year, :teacher_funding, :recruitment_target, keyword_init: true)

      def course_details
        CourseDetails.new(
          name: read[:name],
          identifier: read[:identifier],
          short_code: read[:short_code],
          course_group: read[:course_group],
          description: read[:description],
        )
      end

      def milestone_types
        selected_milestones.keys
      end

      def milestone_configs
        selected_milestones.map do |declaration_type, attributes|
          MilestoneConfig.new(
            declaration_type:,
            acceptance_window_start_offset: attributes["acceptance_window_start_offset"],
            acceptance_window_end_offset: attributes["acceptance_window_end_offset"],
            payment_percentage: attributes["payment_percentage"],
          )
        end
      end

      def selected_lead_providers
        selected_providers_for(:lead_providers).map do |lead_provider, attributes|
          SelectedLeadProvider.new(
            lead_provider:,
            url: attributes["url"],
            email: attributes["email"],
          )
        end
      end

      def selected_contract_financials
        selected_lead_provider_ids = selected_lead_providers.map { _1.lead_provider.id.to_s }
        contract_financials = read.fetch(:contract_financials, {})
        lead_provider_ids = contract_financials.values.flat_map { |provider_attributes| provider_attributes.to_h.keys }.uniq & selected_lead_provider_ids
        lead_providers_by_id = LeadProvider.where(id: lead_provider_ids).index_by { |lead_provider| lead_provider.id.to_s }

        contract_financials.flat_map do |academic_year_key, provider_attributes|
          provider_attributes.filter_map do |lead_provider_id, attributes|
            next unless selected_lead_provider_ids.include?(lead_provider_id)
            next unless ActiveModel::Type::Boolean.new.cast(attributes["selected"])

            SelectedContractFinancial.new(
              lead_provider: lead_providers_by_id.fetch(lead_provider_id),
              academic_year: academic_year_from_key(academic_year_key),
              teacher_funding: attributes["teacher_funding"],
              recruitment_target: attributes["recruitment_target"],
            )
          end
        end
      end

    private

      def academic_year_from_key(key)
        return if key.blank? || key == Admin::CourseBuilder::Steps::ContractFinancials::GENERIC_ACADEMIC_YEAR_KEY

        Integer(key, exception: false)
      end

      def selected_milestones
        read.fetch(:milestones, {}).select do |_declaration_type, attributes|
          ActiveModel::Type::Boolean.new.cast(attributes["selected"])
        end
      end

      def selected_providers_for(key)
        provider_attributes = read.fetch(key, {})
        lead_providers_by_id = LeadProvider.where(id: provider_attributes.keys).index_by { |lead_provider| lead_provider.id.to_s }

        provider_attributes.filter_map do |lead_provider_id, attributes|
          next unless ActiveModel::Type::Boolean.new.cast(attributes["selected"])

          [lead_providers_by_id.fetch(lead_provider_id), attributes]
        end
      end
    end
  end
end
