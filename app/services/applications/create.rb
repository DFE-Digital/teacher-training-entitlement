# frozen_string_literal: true

module Applications
  # Creates a pending application for a teacher, with its current lead provider,
  # and queues the submission email. Used by both registration journeys.
  class Create
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :user
    attribute :course_cohort
    attribute :lead_provider
    attribute :institution
    attribute :funding_eligibility, :string
    attribute :funding_choice, :string
    attribute :registration_data, default: -> { {} }

    attr_reader :application

    # Set when a concurrent request created the application between the
    # validation and the insert.
    attr_reader :concurrent_application

    validates :user, presence: true
    validates :course_cohort, presence: true
    validates :lead_provider, presence: true
    validates :funding_eligibility, presence: true
    validate :no_application_for_course_cohort

    def call
      return false unless valid?

      ActiveRecord::Base.transaction do
        @application = user.applications.create!(
          course_cohort:,
          institution:,
          funding_eligibility:,
          funding_choice:,
          registration_data:,
          status: Application::PENDING,
          application_lead_providers: [ApplicationLeadProvider.new(current: true, lead_provider:, assigned_at: Time.zone.now)],
        )
      end

      Emails::SendApplicationSubmissionEmailJob.perform_later(application:)

      true
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
      Rails.logger.warn("Application creation failed: #{e.class}")
      @application = nil
      @concurrent_application = user.applications.find_by(course_cohort:)
      errors.add(:application, :could_not_be_saved)
      false
    end

  private

    def no_application_for_course_cohort
      return if user.blank? || course_cohort.blank?

      errors.add(:application, :already_exists) if user.applications.exists?(course_cohort:)
    end
  end
end
