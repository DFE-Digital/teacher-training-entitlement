module Registrations
  class JourneyDefinition
    attr_reader :name, :slug, :course, :step_definitions

    def initialize(course: nil, name: nil, slug: nil)
      @name = course&.name || name
      @slug = course&.identifier || slug.presence || name.to_s.parameterize
      @course = course
      @step_definitions = []
    end

    def add_step(step_definition)
      step_definitions << step_definition
      step_definition.journey_definition = self
      step_definition
    end

    def find_step_by_slug(step_slug)
      normalized_slug = step_slug.to_s.dasherize if step_slug.is_a?(Symbol)
      normalized_slug ||= step_slug.to_s
      step_definitions.find { |step| step.slug.to_s == normalized_slug }
    end
  end
end
