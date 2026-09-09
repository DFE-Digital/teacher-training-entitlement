module Admin
  module CourseBuilder
    class StateStore
      include DfE::Wizard::Core::StateStore

      CourseDetails = Struct.new(:name, :identifier, :short_code, :description, keyword_init: true)
      RegistrationPeriod = Struct.new(:cohort, :starts_at, :length_in_months, :ends_at, keyword_init: true)
      TrainingPeriod = Struct.new(:starts_at, :ends_at, keyword_init: true)
      SelectedLeadProvider = Struct.new(:lead_provider, :url, :email, keyword_init: true)
      SelectedContractFinancial = Struct.new(:lead_provider, :academic_year, :teacher_funding, :recruitment_target, keyword_init: true)

      def course_details
        CourseDetails.new(
          name: read[:name],
          identifier: read[:identifier],
          short_code: read[:short_code],
          description: read[:description],
        )
      end

      def registration_period
        RegistrationPeriod.new(
          cohort: registration_period_cohort,
          starts_at: registration_starts_at,
          length_in_months: registration_period_length,
          ends_at: registration_ends_at,
        )
      end

      def training_period
        TrainingPeriod.new(
          starts_at: registration_ends_at + 1.day,
          ends_at: registration_ends_at + 1.day + 3.months,
        )
      end

      def milestone_types
        Array(read[:milestone_types])
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
        selected_providers_for(:contract_financials).map do |lead_provider, attributes|
          SelectedContractFinancial.new(
            lead_provider:,
            academic_year: read[:academic_year],
            teacher_funding: attributes["teacher_funding"],
            recruitment_target: attributes["recruitment_target"],
          )
        end
      end

    private

      def selected_providers_for(key)
        provider_attributes = read.fetch(key, {})
        lead_providers_by_id = LeadProvider.where(id: provider_attributes.keys).index_by { |lead_provider| lead_provider.id.to_s }

        provider_attributes.filter_map do |lead_provider_id, attributes|
          next unless ActiveModel::Type::Boolean.new.cast(attributes["selected"])

          [lead_providers_by_id.fetch(lead_provider_id), attributes]
        end
      end

      def registration_starts_at
        return registration_period_cohort.registration_starts_at if registration_period_cohort.present?

        parse_date(read[:registration_starts_at])
      end

      def registration_period_length
        read[:registration_period_length]&.to_i
      end

      def registration_ends_at
        return registration_period_cohort.registration_ends_at if registration_period_cohort.present?
        return if registration_starts_at.blank? || registration_period_length.blank?

        registration_starts_at.advance(months: registration_period_length) - 1.day
      end

      def registration_period_cohort
        return if read[:cohort_id].blank?

        @registration_period_cohort ||= Cohort.find_by(id: read[:cohort_id])
      end

      def parse_date(value)
        return value if value.is_a?(Date)
        return if value.blank?

        Date.parse(value.to_s)
      rescue Date::Error
        nil
      end
    end
  end
end
