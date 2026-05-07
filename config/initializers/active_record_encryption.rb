# Test environment encryption keys are set in config/environments/test.rb
# to ensure they're available before eager loading.
unless Rails.env.test?
  Rails.application.configure do
    config.active_record.encryption.primary_key = Rails.application.credentials.dig(:active_record_encryption, :primary_key)
    config.active_record.encryption.deterministic_key = Rails.application.credentials.dig(:active_record_encryption, :deterministic_key)
    config.active_record.encryption.key_derivation_salt = Rails.application.credentials.dig(:active_record_encryption, :key_derivation_salt)
  end
end
