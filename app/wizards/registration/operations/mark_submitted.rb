module Registration
  module Operations
    # Records that the teacher confirmed their answers, which is what makes the
    # registration submitted page reachable.
    class MarkSubmitted
      def initialize(repository:, **)
        @repository = repository
      end

      def execute
        @repository.write(submitted: true)

        { success: true }
      end

      def rollback; end
    end
  end
end
