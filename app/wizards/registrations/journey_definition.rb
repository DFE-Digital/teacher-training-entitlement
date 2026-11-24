module Registrations
  class JourneyDefinition
    attr_reader :name, :slug, :course, :step_definitions

    def initialize(course_definition: nil, name: nil, slug: nil, course: nil)
      @name = course_definition ? course_definition::NAME : name
      @slug = course_definition ? course_definition::JOURNEY_SLUG : slug.presence || name.to_s.parameterize
      @course = if course_definition
                  course_definition.course if course_definition.respond_to?(:course)
                else
                  course
                end
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
