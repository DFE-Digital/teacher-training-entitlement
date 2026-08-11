# frozen_string_literal: true

module Admin
  class StatementDetailsComponent < BaseComponent
    attr_reader :calculator, :link_to_voids, :statement

    def initialize(statement:, link_to_voids: true)
      @calculator = ::Statements::Calculate.new(statement:)
      @link_to_voids = link_to_voids
      @statement = statement
    end
  end
end
