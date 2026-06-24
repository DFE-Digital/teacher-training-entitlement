# frozen_string_literal: true

require "csv"

module Applications
  class LateDeclarationsCsv
    HEADERS = [
      "User",
      "Application status",
      "Provider",
      "Course",
      "Cohort",
      "Expected by",
    ].freeze

    def initialize(applications:, expected_by:)
      @applications = applications
      @expected_by = expected_by
    end

    def call
      CSV.generate(encoding: "utf-8") do |csv|
        csv << HEADERS

        applications.each do |application|
          csv << [
            application.user.full_name,
            application.status.humanize,
            application.lead_provider&.name,
            application.course.name,
            application.cohort.description,
            application.schedule.public_send(expected_by).to_date.to_fs(:govuk),
          ]
        end
      end
    end

  private

    attr_reader :applications, :expected_by
  end
end
