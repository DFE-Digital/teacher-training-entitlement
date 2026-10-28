class ImportGiasSchoolsJob < ApplicationJob
  queue_as :default

  def perform
    Importers::GiasSchools.new.call
  end
end
