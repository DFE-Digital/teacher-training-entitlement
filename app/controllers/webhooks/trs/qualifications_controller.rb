class Webhooks::Trs::QualificationsController < WebhooksController
  def show
    render json: to_json(participant_outcomes)
  end

private

  def trn
    params[:trn]
  end

  def participant_outcomes
    user = User.find_by!(trn:)
    user
      .participant_outcomes
      .passed_state
      .order(completion_date: :desc)
  end

  def to_json(outcomes)
    Webhooks::QualificationsSerializer.render(trn, root: "data", outcomes:)
  end
end
