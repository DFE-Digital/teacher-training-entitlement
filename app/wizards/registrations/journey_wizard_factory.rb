module Registrations
  class JourneyWizardFactory
    WIZARD_CLASSES = {
      Courses::ExcellenceInReception => Registrations::Journeys::ExcellenceInReceptionWizard,
      Courses::SendInclusivePracticeTeachers => Registrations::Journeys::SendInclusivePracticeTeachersWizard,
      Courses::SendInclusivePracticeLeaders => Registrations::Journeys::SendInclusivePracticeLeadersWizard,
      Courses::CourseSelection => Registrations::Journeys::CourseSelectionWizard,
      Courses::CourseOne => Registrations::Journeys::Spikes::CourseOneWizard,
      Courses::CourseTwo => Registrations::Journeys::Spikes::CourseTwoWizard,
    }.freeze

    DOCUMENTATION_WIZARD = Registrations::Journeys::DocumentationExampleWizard
    COURSES = WIZARD_CLASSES.keys.reject { |definition| definition == Courses::CourseSelection }.freeze

    def self.wizard(slug, **options)
      slug = slug.to_s
      return DOCUMENTATION_WIZARD.new(**options) if slug == DOCUMENTATION_WIZARD::SLUG

      course_definition = WIZARD_CLASSES.keys.find { |definition| slug == definition::JOURNEY_SLUG }
      raise ActiveRecord::RecordNotFound, "Registration journey #{slug.inspect} not found" unless course_definition

      wizard_class = WIZARD_CLASSES.fetch(course_definition)
      wizard_options = options.merge(course_definition:)
      wizard_class.new(**wizard_options)
    end

    def self.build(slug)
      wizard = wizard(slug, session: {})
      wizard.steps_processor
      wizard.journey_definition
    end

    def self.build_all
      WIZARD_CLASSES.keys.map { |course_definition| build(course_definition::JOURNEY_SLUG) }
    end

    def self.slugs
      WIZARD_CLASSES.keys.map { |course_definition| course_definition::JOURNEY_SLUG } + [DOCUMENTATION_WIZARD::SLUG]
    end
  end
end
