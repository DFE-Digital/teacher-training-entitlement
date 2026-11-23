module Teachers
  class Query
    attr_reader :teacher

    def initialize(teacher:)
      @teacher = teacher
    end

    def teacher_with_matching_email
      Teacher.where(email: teacher.email).where.not(id: teacher.id).first
    end
  end
end
