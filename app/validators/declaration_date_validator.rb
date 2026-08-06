# frozen_string_literal: true

class DeclarationDateValidator < ActiveModel::Validator
  RFC3339_DATE_REGEX = /\A\d{4}-\d{2}-\d{2}T(\d{2}):(\d{2}):(\d{2})([.,]\d+)?(Z|[+-](\d{2})(:?\d{2})?)?\z/i

  def validate(record)
    date_has_the_right_format(record)
  end

private

  def date_has_the_right_format(record)
    return if record.raw_declaration_date.blank?

    raw_declaration_date = record.raw_declaration_date.to_s
    return if raw_declaration_date.match?(RFC3339_DATE_REGEX) && begin
      Time.zone.parse(raw_declaration_date)
    rescue ArgumentError
      false
    end

    record.errors.add(:declaration_date, :invalid)
  end
end
