class RegistrationStep < ApplicationRecord
  self.inheritance_column = :sti_type

  SIMPLE_QUESTION_TYPES = RegistrationSteps::HtmlComponent::TYPES
  COMPLICATED_TYPES = [
    "Check answers",
    "Choose institution",
    RegistrationSteps::CustomStep::TYPE,
    RegistrationSteps::CustomView::TYPE,
  ].freeze

  TYPES = SIMPLE_QUESTION_TYPES + COMPLICATED_TYPES

  def self.new(attributes = nil, &block)
    return super unless self == RegistrationStep

    attributes = attributes.to_h if attributes.respond_to?(:to_h)
    if attributes.present?
      attributes = attributes.with_indifferent_access
      attributes[:sti_type] ||= sti_type_for(attributes[:type])
    end

    super(attributes, &block)
  end

  def self.sti_type_for(type)
    if type.in?(SIMPLE_QUESTION_TYPES)
      RegistrationSteps::HtmlComponent.name
    elsif type == RegistrationSteps::CustomStep::TYPE
      RegistrationSteps::CustomStep.name
    elsif type == RegistrationSteps::CustomView::TYPE
      RegistrationSteps::CustomView.name
    end
  end

  belongs_to :registration_journey
  attr_accessor :after_step_id

  scope :ordered, -> { order(arel_table[:order].asc.nulls_last, :id) }

  before_validation :set_sti_type
  before_save :set_slug

  def services_to_run(execute_point:)
    service_config = config["services"] || []
    service_config.select { |c| c.fetch("execute_point", c[:execute_point]).to_s == execute_point.to_s }.map { |c| c.fetch("class_name", c[:class_name]) }
  end

  SERVICE_EXECUTE_POINT_OPTIONS = {
    "execute service before step" => "before_step",
    "execute service after step" => "after_update",
  }.freeze
  DEFAULT_SERVICE_EXECUTE_POINT = "before_step".freeze

  def add_service!(class_name:, execute_point:)
    service_config = config["services"] ||= []
    service_config << { class_name:, execute_point: }
    update!(config:)
  end

  def set_service!(class_name:, execute_point:)
    return false unless class_name.in?(available_services)
    return false unless execute_point.in?(SERVICE_EXECUTE_POINT_OPTIONS.values)

    config["services"] = [
      {
        "class_name" => class_name,
        "execute_point" => execute_point,
      },
    ]

    update!(config:)
  end

  def configured_services
    config["services"] || []
  end

  def configured_service_class_name
    configured_services.first&.then { |service| service.fetch("class_name", service[:class_name]) }
  end

  def configured_service_execute_point
    configured_services.first&.then { |service| service.fetch("execute_point", service[:execute_point]) }
  end

  def available_services
    find_classes(path: "app/services", clazz: Registrations::BaseStepService)
  end

  def funding_eligibility_step?
    type == "Funding eligibity"
  end

  def custom_step?
    RegistrationSteps::CustomStep.handles?(self)
  end

  def custom_view?
    RegistrationSteps::CustomView.handles?(self)
  end

  def simple_question_type?
    RegistrationSteps::HtmlComponent.handles?(self)
  end

  def next_registration_step_for(answer:)
    next_step_id = answer_data.find { |configured_answer| answer_matches?(configured_answer, answer) }&.fetch("next_step_id", nil)
    if next_step_id
      RegistrationStep.find_by(id: next_step_id)
    end
  end

  def previous_step_id
    config["previous_step_id"]
  end

  def previous_step_id=(previous_step_id)
    self.config ||= {}

    if previous_step_id.present?
      config["previous_step_id"] = previous_step_id.to_i
    else
      config.delete("previous_step_id")
    end
  end

  def previous_registration_step
    registration_journey.registration_steps.find_by(id: previous_step_id)
  end

  def branch_join_step_id
    config["branch_join_step_id"]
  end

  def branch_join_step_id=(branch_join_step_id)
    self.config ||= {}

    if branch_join_step_id.present?
      config["branch_join_step_id"] = branch_join_step_id.to_i
    else
      config.delete("branch_join_step_id")
    end
  end

  def branch_join_registration_step
    registration_journey.registration_steps.find_by(id: branch_join_step_id)
  end

  def add_redirect!(redirect_path:, redirect_state_store_key: nil)
    update!(redirect_path:, redirect_state_store_key:)
  end

  def redirect_target_for(state_store:, answer: nil)
    answer_based_redirect = redirect_from_config(answer_redirect_config_for(answer), state_store:)
    return answer_based_redirect if answer_based_redirect

    redirect_from_config(
      {
        "path" => redirect_path,
        "state_store_key" => redirect_state_store_key,
      },
      state_store:,
    )
  end

  def stored_answer_keys
    [answer_key.to_sym]
  end

  def answers
    answer_data
  end

  def answer_data
    config.dig(type_as_param, "answers") || []
  end

  def answer_value_for(answer)
    normalized_answer_value(name: answer["name"], value: answer["value"])
  end

  def set_answers!(answers:)
    config_for_type = config[type_as_param] ||= {}
    config_for_type["answers"] = answers.filter_map do |answer|
      next if answer["name"].blank?

      {
        "name" => answer["name"],
        "value" => normalized_answer_value(name: answer["name"], value: answer["value"]),
        "next_step_id" => answer["next_step_id"],
        "redirect" => redirect_config(
          path: answer.dig("redirect", "path") || answer["redirect_path"],
          state_store_key: answer.dig("redirect", "state_store_key") || answer["redirect_state_store_key"],
        ),
      }.compact
    end

    update!(config:)
  end

  def type_as_param
    type.underscore.parameterize.underscore
  end

  def answer_key
    self[:answer_key].presence || name_as_param
  end

  def name_as_param
    return nil unless name

    name.underscore.parameterize.underscore
  end

  def other_registration_steps
    registration_journey.registration_steps.where.not(id:)
  end

  def step_class
    Forms::RegistrationStepForm
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
    end

    matches.sort
  end

  def set_sti_type
    self.sti_type = self.class.sti_type_for(type)
  end

  def set_slug
    return if slug.present? || !name_changed?

    self.slug = name.underscore.parameterize.underscore.gsub("_", "-")
  end

  def answer_redirect_config_for(answer)
    return if answer.blank?

    answer_data.find { |configured_answer| answer_matches?(configured_answer, answer) }&.fetch("redirect", nil)
  end

  def answer_matches?(configured_answer, answer)
    configured_answer["value"] == answer || configured_answer["name"] == answer
  end

  def redirect_from_config(redirect_config, state_store:)
    return if redirect_config.blank?

    target = redirect_config["path"].presence
    state_store_value = value_from_state_store(state_store, redirect_config["state_store_key"])

    target = if target
               replace_path_params(target, state_store_value)
             else
               state_store_value
             end

    return unless target.to_s.start_with?("/")

    target
  end

  def replace_path_params(path, value)
    return path if value.blank?

    path.gsub(/:\w+/, value.to_s)
  end

  def value_from_state_store(state_store, key)
    return if key.blank?

    state_store[key] || state_store[key.to_sym]
  end

  def redirect_config(path:, state_store_key:)
    {
      "path" => path.presence,
      "state_store_key" => state_store_key.presence,
    }.compact.presence
  end

  def normalized_answer_value(name:, value:)
    value.presence || name.to_s.underscore.parameterize.underscore
  end
end
