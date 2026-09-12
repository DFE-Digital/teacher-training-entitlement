# frozen_string_literal: true

module Admin
  module Finance
    module Statements
      class DetailsController < AdminController
        def index
          @statement = Statement
                         .includes(
                           :declarations,
                           :milestones,
                           :course_cohorts,
                         )
                         .find(params[:id])
          @declarations = @statement
                            .declarations
                            .includes(:course_cohort)
                            .order(created_at: :desc)
        end

        def outstanding
          @group = {} # grouped by milestones
        end

      private

        def previous_declarations(milestone:)
          Statement
            .includes(:declarations)
            .where(lead_provider: @statement.lead_provider)
            .where.not(id: @statement.id)
            .where(declarations: { milestone: })
        end
      end
    end
  end
end
