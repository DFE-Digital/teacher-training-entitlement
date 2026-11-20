module RegistrationStepRedirectable
  extend ActiveSupport::Concern

  # Steps can redirect after they have executed, such as from check answers
  # to the created application. A state-store key can supply path parameters:
  #
  #     redirect_path: "/applications/:ecf_id"
  #     redirect_state_store_key: "application_ecf_id"
  #
  # Resolves this record's configured redirect, substituting values from the
  # state store when needed. Returns nil when there is no usable in-app target.
  def resolved_redirect_target(state_store:)
    build_redirect_target(redirect_path:, redirect_state_store_key:, state_store:)
  end

private

  # Builds an in-app redirect from a configured path, optionally replacing its
  # path parameters with a state-store value. When there is no path, the stored
  # value is used as the target. Returns nil for missing or external targets.
  def build_redirect_target(redirect_path:, redirect_state_store_key:, state_store:)
    return if redirect_path.blank? && redirect_state_store_key.blank?

    state_store_value = value_from_state_store(state_store, redirect_state_store_key)
    target = redirect_path.presence || state_store_value
    target = target.gsub(/:\w+/, state_store_value.to_s) if redirect_path.present? && state_store_value.present?

    return unless target.to_s.start_with?("/")

    target
  end

  def value_from_state_store(state_store, key)
    return if key.blank?

    state_store[key] || state_store[key.to_sym]
  end
end
