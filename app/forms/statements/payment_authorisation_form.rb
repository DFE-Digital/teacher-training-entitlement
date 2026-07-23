# frozen_string_literal: true

module Statements
  class PaymentAuthorisationForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    attr_reader :statement

    attribute :checks_done, :boolean

    validates :checks_done, acceptance: true, allow_nil: false

    def initialize(statement, *args, **params)
      @statement = statement
      super(*args, **params)
    end

    def save_form
      return false unless valid?

      statement.mark_as_frozen!
    end
  end
end
