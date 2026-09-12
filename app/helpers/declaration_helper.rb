module DeclarationHelper
  include Pagy::Frontend

  def application_status_colour(status)
    {
      ineligible: "red",
      submitted: "grey",
      voided: "yellow",
      awaiting_clawback: "yellow",
      eligible: "green",
      payable: "green",
      paid: "blue",
      clawed_back: "blue",
    }.fetch(status.to_sym, "grey")
  end

  def declaration_status_badge(status)
    return nil unless status.presence

    govuk_tag(text: status.humanize, colour: application_status_colour(status))
  end
end
