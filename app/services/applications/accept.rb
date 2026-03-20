# frozen_string_literal: true

module Applications
  class Accept
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :application
    attribute :funded_place

    validates :application, presence: true
    validates :funded_place, inclusion: { in: [true, false], if: :validate_funded_place? }
    validate :not_already_accepted
    validate :cannot_change_from_rejected
    validate :other_accepted_applications_with_same_course_and_cohort?
    validate :eligible_for_funded_place

    def accept
      return false unless valid?

      ApplicationRecord.transaction do
        accept_application!
        create_application_state!
        reject_other_applications_in_same_cohort!
      end

      application.reload

      true
    end

  private

    delegate :cohort, :user, :course, :lead_provider,
             to: :application

    def not_already_accepted
      return if application.blank?

      errors.add(:application, :has_already_been_accepted) if application.accepted_lead_provider_approval_status?
    end

    def cannot_change_from_rejected
      return if application.blank?

      errors.add(:application, :cannot_change_from_rejected) if application.rejected_lead_provider_approval_status?
    end

    def other_accepted_applications_with_same_course_and_cohort?
      errors.add(:application, :has_another_accepted_application) if other_accepted_applications_with_same_course_and_cohort.present?
    end

    def accept_application!
      opts = {
        lead_provider_approval_status: "accepted",
        accepted_at: Time.zone.now,
        training_status: :active,
      }

      if cohort&.funding_cap?
        opts[:funded_place] = funded_place
      end

      application.update!(opts)
    end

    def reject_other_applications_in_same_cohort!
      return if other_applications_in_same_cohort.blank?

      other_applications_in_same_cohort.update!(
        lead_provider_approval_status: "rejected",
        reason_for_rejection: Application.reason_for_rejections[:other_application_in_this_cohort_accepted],
      )
    end

    def other_accepted_applications_with_same_course_and_cohort
      return if application.blank?

      @other_accepted_applications_with_same_course_and_cohort ||= Application
        .not_withdrawn
        .where(lead_provider_approval_status: "accepted",
               user: [user, same_trn_users].flatten.compact.uniq,
               course_cohort: CourseCohort.where(course: course.rebranded_alternative_courses, cohort:))
        .where.not(id: application.id)
    end

    def other_applications_in_same_cohort
      return if cohort.blank?

      @other_applications_in_same_cohort ||= Application
        .where(course_cohort: CourseCohort.where(cohort:, course:), user:)
        .where.not(id: application.id)
    end

    def trn
      @trn ||= user.trn_verified? ? user.trn : nil
    end

    def same_trn_users
      return if trn.blank?

      @same_trn_users ||= User
                         .where(trn:)
                         .where.not(id: user.id)
    end

    def eligible_for_funded_place
      return if errors.any?
      return unless cohort&.funding_cap?

      if funded_place && !application.eligible_for_funding
        errors.add(:application, :not_eligible_for_funded_place)
      end
    end

    def validate_funded_place?
      errors.blank? && cohort&.funding_cap?
    end

    def create_application_state!
      ApplicationState.create!(
        application:,
        lead_provider:,
        state: "active",
      )
    end
  end
end
