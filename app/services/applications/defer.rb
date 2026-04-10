# frozen_string_literal: true

module Applications
  class Defer
    include ActiveModel::Model
    include ActiveModel::Attributes
    include CourseHelper

    DEFERRAL_REASONS = %w[
      bereavement
      long-term-sickness
      parental-leave
      career-break
      other
    ].freeze

    def initialize(application:, reason:, admin_user: nil)
      @application = application
      @application.admin_user = admin_user
      @reason = reason
      @admin_user = admin_user
    end

    attr_reader :application, :reason

    validates :reason, inclusion: { in: DEFERRAL_REASONS, message: :missing_reason }, allow_blank: false
    validates :application, presence: true
    validate :application_already_deferred, if: -> { application }
    validate :application_deferrable, if: -> { application }

    def call
      return if invalid?

      Application.transaction do
        @application.state_changes.create!(
          event: Application::DEFERRED,
          metadata: { reason: @reason },
        )
        @application.deferred_status!
      end

      GenericMailer.with(
        to: @application.user.email,
        full_name: @application.user.full_name,
        provider_name: @application.lead_provider.name,
        course_name: title_embedded_course_name(@application.course),
        deferral_date: @application.deferred_at&.to_fs(:govuk),
        ecf_id: @application.ecf_id,
      ).deferral_notification.deliver_later
    end

  private

    def application_already_deferred
      errors.add(:application, :has_already_been_deferred) if @application.deferred_status?
    end

    def application_deferrable
      old_status = @application.status
      @application.status = Application::DEFERRED
      errors.add(:application, :not_deferrable) if @application.invalid?
      @application.status = old_status
    end
  end
end
