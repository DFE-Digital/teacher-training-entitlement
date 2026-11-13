module Admin
  module CourseBuilder
    module Steps
      class DeliveryPartners
        include DfE::Wizard::Step

        attribute :delivery_partners, default: -> { {} }

        validate :selected_lead_providers_have_delivery_partners
        validate :delivery_partners_reference_existing_records

        def self.permitted_params
          [{ delivery_partners: {} }]
        end

        def delivery_partners=(value)
          super(normalize(value))
        end

        def selected_providers
          return [] unless wizard

          wizard.state_store.selected_lead_providers
        end

        def delivery_partner_selected?(lead_provider, delivery_partner)
          delivery_partners.fetch(lead_provider.id.to_s, {}).fetch(delivery_partner.id.to_s, "0") != "0"
        end

        def error_for(lead_provider)
          errors[:"lead_provider_#{lead_provider.id}"].first
        end

      private

        def normalize(value)
          return {} unless value.is_a?(Hash) || value.is_a?(ActionController::Parameters)

          value.to_h.transform_values do |partner_selections|
            next {} unless partner_selections.is_a?(Hash) || partner_selections.is_a?(ActionController::Parameters)

            partner_selections.to_h
          end
        end

        def selected_lead_providers_have_delivery_partners
          selected_providers.each do |selected_provider|
            lead_provider = selected_provider.lead_provider
            next if selected_delivery_partner_ids_for(lead_provider).any?

            errors.add(:"lead_provider_#{lead_provider.id}", "Select at least one delivery partner for #{lead_provider.name}")
          end
        end

        def delivery_partners_reference_existing_records
          return if unknown_lead_provider_ids.empty? && unknown_delivery_partner_ids.empty?

          lead_provider = selected_providers.first&.lead_provider

          if lead_provider
            errors.add(:"lead_provider_#{lead_provider.id}", "Select delivery partners from the list")
          else
            errors.add(:base, "Select delivery partners from the list")
          end
        end

        def selected_delivery_partner_ids_for(lead_provider)
          ticked_delivery_partner_ids_for(lead_provider) & existing_delivery_partner_ids
        end

        def ticked_delivery_partner_ids_for(lead_provider)
          delivery_partners.fetch(lead_provider.id.to_s, {}).filter_map do |delivery_partner_id, value|
            delivery_partner_id.to_s unless value.to_s == "0"
          end
        end

        def submitted_delivery_partner_ids
          delivery_partners.values.flat_map(&:keys).map(&:to_s)
        end

        def existing_delivery_partner_ids
          @existing_delivery_partner_ids ||= DeliveryPartner.where(id: submitted_delivery_partner_ids).pluck(:id).map(&:to_s)
        end

        def unknown_delivery_partner_ids
          submitted_delivery_partner_ids - existing_delivery_partner_ids
        end

        def submitted_lead_provider_ids
          delivery_partners.keys.map(&:to_s)
        end

        def existing_lead_provider_ids
          @existing_lead_provider_ids ||= LeadProvider.where(id: submitted_lead_provider_ids).pluck(:id).map(&:to_s)
        end

        def unknown_lead_provider_ids
          submitted_lead_provider_ids - existing_lead_provider_ids
        end
      end
    end
  end
end
