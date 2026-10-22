class RefreshAllGiasSchoolsJob < ApplicationJob
  queue_as :default

  def perform
    Importers::GiasSchools.new(refresh_all: true).call
  end
end
