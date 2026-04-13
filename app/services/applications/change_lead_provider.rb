module Applications
  class ChangeLeadProvider
    include ActiveModel::Model
    include ActiveModel::Validations
    include Validations::ApplicationNotSuperceded

    def initialize(current_application:, new_provider:)
      @current_application = current_application
      @new_provider = new_provider
    end

    def call
      new_application.assign_attributes(lead_provider: @new_provider,
                                        status: Application::PENDING,
                                        ecf_id: nil)
      begin
        save_applications!
      rescue StandardError => e
        Rails.logger.info("[#{self.class.name}] Errored saving applications: #{e.message}")
        e.backtrace.take(10).each { |l| Rails.logger.info("[#{self.class.name}] #{l}") }
        errors.add(:base, e.message)
      end
    end

  private

    def save_applications!
      Application.transaction do
        @current_application.update!(status: Application::SUPERCEDED)
        @current_application.application_states.create!(status: Application::SUPERCEDED)
        new_application.save!
        @current_application.update!(superceding_application: new_application)
      end
    end

    def new_application
      @new_application ||= @current_application.dup
    end
  end
end
