# Test environment encryption keys are set in config/environments/test.rb
unless Rails.env.test?
  ActiveRecord::Encryption.configure(
    primary_key: ENV.fetch("ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"),
    deterministic_key: ENV.fetch("ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY"),
    key_derivation_salt: ENV.fetch("ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT"),
  )
end
