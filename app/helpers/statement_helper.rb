module StatementHelper
  def statement_name(statement)
    statement.start_date&.to_fs(:govuk_approx)
  end

  def statement_period(statement)
    [
      statement.start_date&.to_fs(:govuk_short),
      statement.deadline_date&.to_fs(:govuk_short),
    ].join("-")
  end
end
