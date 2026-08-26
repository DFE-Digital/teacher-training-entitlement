class RegistrationTemplate < ApplicationRecord
  def template_generating_services
    find_classes(path: "app/services", clazz: Registrations::StepTemplates::BaseStepTemplateService)
  end

private

  def find_classes(path:, clazz:)
    matches = Dir[Rails.root.join("#{path}/**/*.rb")].filter_map do |file_path|
      class_name = Pathname(file_path)
        .relative_path_from(Rails.root.join(path))
        .to_s
        .delete_suffix(".rb")
        .camelize
      match = class_name.safe_constantize

      match.name if match&.<(clazz) && !match.name.demodulize.start_with?("Base")
    rescue NameError
      nil
    end

    matches.sort
  end
end
