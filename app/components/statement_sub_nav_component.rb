class StatementSubNavComponent < BaseComponent
  include Rails.application.routes.url_helpers

  attr_accessor :statement,
                :current

  def initialize(statement:, current:)
    @statement = statement
    @current = current
  end

  def items
    @items ||= {
      "summary" => admin_finance_statement_path(statement),
      "received" => received_admin_finance_statement_path(statement),
      "expected" => expected_admin_finance_statement_path(statement),
      "outstanding" => outstanding_admin_finance_statement_path(statement),
    }
  end

  def item_classes(item)
    class_names(
      "x-govuk-sub-navigation__section-item",
      "x-govuk-sub-navigation__section-item--current" => current_item?(item),
    )
  end

  def current_item?(item)
    item == current
  end

  def item_link(item)
    aria = current_item?(item) ? { current: true } : {}
    link_to(
      item.titleize,
      items.fetch(item),
      class: "govuk-link x-govuk-sub-navigation__link",
      aria:,
    )
  end
end
