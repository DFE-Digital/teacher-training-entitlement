class NullTeacher < Teacher
  def null_teacher?
    true
  end

  def actual_teacher?
    false
  end

  def flipper_id
    "Teacher;#{feature_flag_id}"
  end

  attr_accessor :feature_flag_id
end
