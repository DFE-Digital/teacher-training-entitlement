# frozen_string_literal: true

module Applications
  class Resume
    include ActiveModel::Validations

    validate :not_already_active

    def initialize(application:)
      @application = application
    end

    def call
      return if invalid?

      @application.application_states.create!
      @application.active_training_status!
    end

  private

    def not_already_active
      add_error(:base, :already_active) if @application&.active_training_status?
    end

    def add_error(group, key)
      message = I18n.t("activemodel.errors.models.applications/resume.attributes.#{group}.#{key}")
      errors.add(group, message)
    end
  end
end
