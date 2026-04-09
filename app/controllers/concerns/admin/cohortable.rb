module Admin
  module Cohortable
    extend ActiveSupport::Concern

    included do
      before_action :set_cohorts
    end

  protected

    def set_cohorts
      @cohorts = Cohort.order_by_latest
      @current_cohort = params[:cohort_id].present? ? @cohorts.find(params[:cohort_id]) : @cohorts.first
    end
  end
end
