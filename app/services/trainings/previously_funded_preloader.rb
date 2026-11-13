module Trainings
  # Application#previously_funded? runs a query per application unless the application
  # responds to `transient_previously_funded`. This sets that value for a whole page in one query.
  class PreviouslyFundedPreloader
    def initialize(applications)
      @applications = applications
    end

    def call
      funded_ids_by_user = funded_application_ids_by_user

      applications.each do |application|
        previously_funded = funded_ids_by_user.fetch(application.user_id, []).any? { |id| id != application.id }
        application.define_singleton_method(:transient_previously_funded) { previously_funded }
      end
    end

  private

    attr_reader :applications

    # Mirrors Application#previously_funded?
    def funded_application_ids_by_user
      Application
        .where(user_id: applications.map(&:user_id))
        .has_been_accepted
        .eligible_for_funding
        .where(funded_place: [nil, true])
        .pluck(:user_id, :id)
        .group_by(&:first)
        .transform_values { |pairs| pairs.map(&:last) }
    end
  end
end
