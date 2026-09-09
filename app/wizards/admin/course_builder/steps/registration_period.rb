module Admin
  module CourseBuilder
    module Steps
      class RegistrationPeriod
        include DfE::Wizard::Step

        REGISTRATION_PERIOD_LENGTHS = {
          "1 month" => 1,
          "2 months" => 2,
          "3 months" => 3,
          "4 months" => 4,
          "5 months" => 5,
          "6 months" => 6,
        }.freeze

        DATE_PARAMETER_KEYS = %i[
          registration_starts_at(1i)
          registration_starts_at(2i)
          registration_starts_at(3i)
        ].freeze

        attribute :registration_starts_at, :date
        attribute :registration_period_length, :integer
        attribute :cohort_id, :integer

        validate :existing_cohort_or_registration_period

        def self.permitted_params
          [:cohort_id, :registration_period_length, *DATE_PARAMETER_KEYS]
        end

        def initialize(attributes = {})
          attributes = attributes.to_h.symbolize_keys
          attributes[:registration_starts_at] ||= date_from_multiparameter_attributes(attributes)

          super(attributes.except(*DATE_PARAMETER_KEYS))
        end

        def registration_ends_at
          return if registration_starts_at.blank? || registration_period_length.blank?

          registration_starts_at.advance(months: registration_period_length)
        end

      private

        def existing_cohort_or_registration_period
          return if cohort_id.present?

          errors.add(:registration_starts_at, :blank) if registration_starts_at.blank?
          errors.add(:registration_period_length, :blank) if registration_period_length.blank?
          errors.add(:registration_period_length, :inclusion) if registration_period_length.present? && REGISTRATION_PERIOD_LENGTHS.values.exclude?(registration_period_length)
        end

        def date_from_multiparameter_attributes(attributes)
          year = attributes[:"registration_starts_at(1i)"]
          month = attributes[:"registration_starts_at(2i)"]
          day = attributes[:"registration_starts_at(3i)"]

          return if year.blank? || month.blank? || day.blank?

          Date.new(year.to_i, month.to_i, day.to_i)
        rescue Date::Error
          nil
        end
      end
    end
  end
end
