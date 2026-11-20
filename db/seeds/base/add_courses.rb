Course.find_or_initialize_by(identifier: Course::TTE_EARLY_YEARS).tap do |course|
  course.update!(
    name: "Excellence in reception teaching",
    ecf_id: "7fbefdd4-dd2d-4a4f-8995-d59e525124b7",
    course_group: "reception",
    description: "The Excellence in reception teaching course is aimed at teachers who have completed their induction and are currently teaching reception age children, or plan to in the future.",
    short_code: "NPDEIRT",
  )
end

Course.find_or_initialize_by(identifier: Course::SEND_INCLUSIVE_TEACHERS).tap do |course|
  course.update!(
    name: "Embedding inclusive pratice",
    course_group: "send",
    short_code: "NPDEIP",
    ecf_id: "09047d04-8fcb-48bd-b1d6-3769e720f477",
  )
end

Course.find_or_initialize_by(identifier: Course::SEND_INCLUSIVE_LEADERS).tap do |course|
  course.update!(
    name: "Embedding inclusive pratice for leaders",
    course_group: "send",
    short_code: "NPDEIPL",
    ecf_id: "a2aa3d0b-5caa-42a0-92c3-889346c79ea1",
  )
end
