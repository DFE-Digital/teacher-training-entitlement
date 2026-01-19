module CourseHelper
  def localise_course_name(course)
    I18n.t(course.identifier, scope: "course.name")
  end

  # Returns either "the #{course_name}" (for EHCO) or "the #{course_name} NPQ" in all other cases
  # Saves having this logic in a bunch of different templates
  def localise_sentence_embedded_course_name(course)
    I18n.t("course.embedded_sentence.default", course_name: localise_course_name(course))
  end

  def course_short_code(course)
    I18n.t(course.identifier, scope: "course.short_code")
  end

  def title_embedded_course_name(course)
    I18n.t("course.embedded_sentence.title", course_name: localise_course_name(course))
  end
end
