class Admin::Finance::Statements::ReceivedController < AdminController
  before_action :set_statement

  def show
    @declarations = @statement.declarations.includes(:course_cohort, application: :user)

    if funded_place_filter
      @declarations.merge!(
        Declaration.joins(:application)
          .where(application: { funded_place: funded_place_filter }),
      )
    end

    if state_filter
      @declarations.merge!(Declaration.where(state: state_filter))
    end

    if declaration_type_filter
      @declarations.merge!(Declaration.where(declaration_type: declaration_type_filter))
    end

    @name = @declarations.size
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

  def funded_place_filter
    return @funded_place_filter if instance_variable_defined?(:@funded_place_filter)

    @funded_place_filter =
      if params[:funded].blank? || params[:funded].downcase == "all"
        nil
      elsif params[:funded].downcase == "yes"
        [true]
      else
        [nil, false]
      end
  end

  def state_filter
    return @state_filter if instance_variable_defined?(:@state_filter)

    @state_filter =
      if params[:status].blank? || params[:status].downcase == "all"
        nil
      else
        params[:status].downcase
      end
  end

  def declaration_type_filter
    return @declaration_type_filter if instance_variable_defined?(:@declaration_type_filter)

    @declaration_type_filter = params[:milestone].presence&.downcase
  end
end
