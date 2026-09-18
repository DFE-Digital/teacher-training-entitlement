class Admin::Finance::Statements::ReceivedController < AdminController
  before_action :set_statement

  def show
    scope = @statement.declarations.includes(:course_cohort, application: :user)

    if teacher_filter
      users = User.arel_table
      scope.merge!(
        Declaration
          .joins(:application)
          .merge!(
            Application
              .joins(:user)
              .where(users[:full_name].matches("%#{teacher_filter}%")),
          ),
      )
    end

    if funded_place_filter
      scope.merge!(
        Declaration.joins(:application)
          .where(application: { funded_place: funded_place_filter }),
      )
    end

    if state_filter
      scope.merge!(Declaration.where(state: state_filter))
    end

    if declaration_type_filter
      scope.merge!(Declaration.where(declaration_type: declaration_type_filter))
    end

    @pagy, @declarations = pagy(scope)
  end

private

  def set_statement
    @statement = Statement
                   .includes(
                     :declarations,
                     :milestones,
                     course_cohorts: %i[course milestones],
                   )
                   .find(params[:id])
  end

  def teacher_filter
    params[:q].presence
  end

  def funded_place_filter
    @funded_place_filter ||=
      if params[:funded].blank? || params[:funded].downcase == "all"
        nil
      elsif params[:funded].downcase == "yes"
        [true]
      else
        [nil, false]
      end
  end

  def state_filter
    @state_filter ||=
      if params[:status].blank? || params[:status].downcase == "all"
        nil
      else
        params[:status].downcase
      end
  end

  def declaration_type_filter
    @declaration_type_filter ||= params[:milestone].presence&.downcase
  end
end
