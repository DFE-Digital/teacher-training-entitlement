class Admin::Npd2::ContractsController < AdminController
  def index
    @contracts = Contract
      .includes(:lead_provider, :policy_periods)
      .order(:id)
  end
end
