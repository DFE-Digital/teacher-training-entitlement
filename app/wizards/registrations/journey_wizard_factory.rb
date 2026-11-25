module Registrations
  class JourneyWizardFactory
    WIZARD_CLASSES = {
      Course::TTE_EARLY_YEARS => Registrations::Journeys::ExcellenceInReceptionWizard,
      Course::SEND_INCLUSIVE_TEACHERS => Registrations::Journeys::SendInclusivePracticeWizard,
      Course::SEND_INCLUSIVE_LEADERS => Registrations::Journeys::SendInclusivePracticeWizard,
      "course-selection" => Registrations::Journeys::CourseSelectionWizard,
      Course::COURSE_ONE => Registrations::Journeys::Spikes::CourseOneWizard,
      Course::COURSE_TWO => Registrations::Journeys::Spikes::CourseTwoWizard,
    }.freeze

    DOCUMENTATION_WIZARD = Registrations::Journeys::DocumentationExampleWizard
    COURSE_SELECTION_SLUG = "course-selection".freeze
    COURSE_IDENTIFIERS = WIZARD_CLASSES.keys.reject { |identifier| identifier == COURSE_SELECTION_SLUG }.freeze

    def self.wizard(slug, **options)
      slug = slug.to_s
      return DOCUMENTATION_WIZARD.new(**options) if slug == DOCUMENTATION_WIZARD::SLUG

      wizard_class = WIZARD_CLASSES[slug]
      raise ActiveRecord::RecordNotFound, "Registration journey #{slug.inspect} not found" unless wizard_class

      return wizard_class.new(**options) if slug == COURSE_SELECTION_SLUG

      course = Course.find_by!(identifier: slug)
      wizard_class.new(**options.merge(course:))
    end

    def self.build(slug)
      wizard = wizard(slug, session: {})
      wizard.steps_processor
      wizard.journey_definition
    end

    def self.build_all
      WIZARD_CLASSES.keys.map { |slug| build(slug) }
    end

    def self.slugs
      WIZARD_CLASSES.keys + [DOCUMENTATION_WIZARD::SLUG]
    end
  end
end
