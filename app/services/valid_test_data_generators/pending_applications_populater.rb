# frozen_string_literal: true

require "active_support/testing/time_helpers"

module ValidTestDataGenerators
  class PendingApplicationsPopulater < ApplicationsPopulater
    include ActiveSupport::Testing::TimeHelpers

    def populate
      return unless Rails.env.in?(%w[development review sandbox])

      logger.info "PendingApplicationsPopulater: Started!"

      ActiveRecord::Base.transaction do
        create_participants!
      end

      logger.info "PendingApplicationsPopulater: Finished!"
    end

  private

    def create_participant(school:, user:)
      course = courses.sample
      course_cohort = CourseCohort.find_or_create_by!(cohort:, course:)
      create_application(user, school, course, course_cohort)
    end
  end
end
