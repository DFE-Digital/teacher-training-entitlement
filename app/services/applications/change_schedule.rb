# frozen_string_literal: true

module Applications
  class ChangeSchedule
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :application
    attribute :cohort

    validates :application, presence: true
    validates :cohort, presence: true
    validate :accepted_application, if: -> { application }
    validate :eligible_for_changing_funded_place, if: -> { application }
    validate :incompatible_course, if: -> { application && cohort }
    validate :cohort_in_training, if: -> { cohort }

    def call
      return false unless valid?

      application.update!(cohort:)

      true
    end

  private

    def accepted_application
      return if application.accepted_status?

      errors.add(:application, :application_not_accepted)
    end

    # Make sure the application status has started the course
    def eligible_for_changing_funded_place
      return unless application.declarations.exists?

      errors.add(:application, :application_has_started_training)
    end

    def incompatible_course
      return if cohort.course == application.course

      add_error(:application, :incompatible_schedule)
    end

    def cohort_in_training
      return unless cohort.training_starts_at < Time.zone.today

      add_error(:base, :cohort_in_training)
    end

    def add_error(group, key)
      message = I18n.t("activemodel.errors.models.applications/change_schedule.attributes.#{group}.#{key}")
      errors.add(group, message)
    end
  end
end
