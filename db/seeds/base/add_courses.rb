course = Course.find_or_initialize_by(ecf_id: "7fbefdd4-dd2d-4a4f-8995-d59e525124b7")
course.update!(
  name: "NPD excellence in reception teaching",
  ecf_id: "7fbefdd4-dd2d-4a4f-8995-d59e525124b7",
  # identifier: "npd-excellence-in-reception-teaching",
  identifier: "tte-early-years",
  course_group: "reception",
  description: "The Excellence in reception teaching course is aimed at teachers who have completed their induction and are currently teaching reception age children, or plan to in the future.",
  short_code: "NPDEIRT",
)
