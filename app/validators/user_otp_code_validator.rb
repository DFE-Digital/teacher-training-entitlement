class UserOTPCodeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    otp = record.user&.otp

    if otp.nil? || !otp.matches?(value)
      record.errors.add(attribute, :incorrect)
      return
    end

    record.errors.add(attribute, :expired) if otp.expired?
  end
end
