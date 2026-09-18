module StatementHelper
  def statement_heading(statement)
    name = [
      statement.lead_provider.name,
      statement.course_group,
      statement.start_date.to_fs(:govuk_approx),
    ].join(", ")
    tag.h1(name, class: "govuk-heading-l")
  end

  def statement_name(statement)
    statement.start_date&.to_fs(:govuk_approx)
  end

  def statement_period(statement)
    [
      statement.start_date&.to_fs(:govuk_short),
      statement.deadline_date&.to_fs(:govuk_short),
    ].join("-")
  end

  def statement_options_value(statement)
    [statement.start_date.to_fs(:succint), statement.frequency].join("::")
  end
end
