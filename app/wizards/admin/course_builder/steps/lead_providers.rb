module Admin
  module CourseBuilder
    module Steps
      class LeadProviders
        include DfE::Wizard::Step

        attribute :lead_providers, default: -> { {} }

        validate :selected_lead_provider_details_are_valid

        def self.permitted_params
          [{ lead_providers: {} }]
        end

        def lead_providers=(value)
          super(normalize(value))
        end

        def lead_provider_selected?(lead_provider)
          ActiveModel::Type::Boolean.new.cast(lead_providers.dig(lead_provider.id.to_s, "selected"))
        end

      private

        def normalize(value)
          (value || {}).to_h.transform_values do |attributes|
            attributes = attributes.to_h.slice("selected", "url", "email").transform_values { _1.is_a?(String) ? _1.strip : _1 }
            attributes.merge("url" => normalize_url(attributes["url"]))
          end
        end

        def normalize_url(url)
          return url if url.blank?
          return url if URI.parse(url).scheme.present?

          "http://#{url}"
        rescue URI::InvalidURIError
          url
        end

        def selected_lead_provider_details_are_valid
          lead_providers.each do |lead_provider_id, attributes|
            next unless ActiveModel::Type::Boolean.new.cast(attributes["selected"])

            validate_url(lead_provider_id, attributes["url"])
            validate_email(lead_provider_id, attributes["email"])
          end
        end

        def validate_url(lead_provider_id, url)
          return if url.blank?

          uri = URI.parse(url)
          return if uri.is_a?(URI::HTTP) && uri.host.present?

          errors.add(:"lead_provider_#{lead_provider_id}_url", "must be a valid URL")
        rescue URI::InvalidURIError
          errors.add(:"lead_provider_#{lead_provider_id}_url", "must be a valid URL")
        end

        def validate_email(lead_provider_id, email)
          return if email.blank?
          return if NotifyEmailValidator.valid?(email)

          errors.add(:"lead_provider_#{lead_provider_id}_email", I18n.t("errors.email.invalid"))
        end
      end
    end
  end
end
