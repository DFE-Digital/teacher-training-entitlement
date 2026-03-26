# frozen_string_literal: true

module Applications
  class Defer
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :application
    attribute :reason

    DEFERRAL_REASONS = %w[
      bereavement
      long-term-sickness
      parental-leave
      career-break
      other
    ].freeze

    def initialize(application:, reason:, admin_user: nil)
      @application = application
      @reason = reason
      @admin_user = admin_user
    end

    attr_reader :reason

    validates :reason, inclusion: { in: DEFERRAL_REASONS, message: :missing_reason }, allow_blank: false
    validate :not_already_deferred
    validate :not_withdrawn
    validate :has_declarations

    def call
      return if invalid?

      @application.update_status!(status: Application::DEFERRED,
                                  reason:,
                                  admin_user: @admin_user)
    end

  private

    def not_withdrawn
      add_error(:base, :already_withdrawn) if @application&.withdrawn_status?
    end

    def not_already_deferred
      add_error(:base, :already_deferred) if @application&.deferred_status?
    end

    def has_declarations
      add_error(:base, :no_declarations) if @application.declarations.none?
    end

    def add_error(group, key)
      message = I18n.t("activemodel.errors.models.applications/defer.attributes.#{group}.#{key}")
      errors.add(group, message)
    end
  end
end
