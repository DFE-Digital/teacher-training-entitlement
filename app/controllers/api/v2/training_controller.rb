module API
  module V2
    class TrainingController < BaseController
      include Pagination
      include FilterByDate

      UUID_FORMAT = /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/
      INCLUDES = %w[teacher outcome surveys expected_declarations].freeze
      BOOLEAN_VALUES = { "true" => true, "false" => false }.freeze
      FILTER_KEYS = %i[course term academic_year funding_eligible funding_uplift teacher_trn teacher_ecf_id teacher_email updated_since].freeze

      def index
        includes = requested_includes
        assignments = paginate(training_query.application_lead_providers)
        Trainings::PreviouslyFundedPreloader.new(assignments.map(&:application)).call
        outcomes = outcomes_by_application(assignments)
        trainings = assignments.map { |assignment| TrainingPresenter.new(assignment, outcome: outcomes[assignment.application_id]) }

        render_document(
          TrainingSerializer.new(trainings, include: includes, links: pagination_links, meta: pagination_meta).serializable_hash,
        )
      end

    private

      def outcomes_by_application(assignments)
        Trainings::OutcomesQuery.new(lead_provider: current_lead_provider, application_ids: assignments.map(&:application_id)).call
      end

      def training_query
        Trainings::Query.new(lead_provider: current_lead_provider, filters:)
      end

      def filters
        {
          course: list_filter(:course),
          term: list_filter(:term, allowed: CourseCohort::TERM_IDENTIFIERS.keys.map(&:to_s)),
          academic_year: list_filter(:academic_year, format: /\A\d{4}\z/),
          funding_eligible: boolean_filter(:funding_eligible),
          funding_uplift: boolean_filter(:funding_uplift),
          teacher_trn: list_filter(:teacher_trn),
          teacher_ecf_id: list_filter(:teacher_ecf_id, format: UUID_FORMAT),
          teacher_email: list_filter(:teacher_email),
          updated_since:,
        }
      end

      # Filters must be a flat hash of supported keys with string values.
      def filter_params
        @filter_params ||= validated_filters(params[:filter])
      end

      def validated_filters(raw)
        return {} if raw.nil?

        raise ActionController::BadRequest, I18n.t(:invalid_filter_structure) unless raw.is_a?(ActionController::Parameters)

        unsupported = raw.keys.map(&:to_sym) - FILTER_KEYS
        raise ActionController::BadRequest, I18n.t(:unsupported_filters, keys: unsupported.join(", ")) if unsupported.any?
        raise ActionController::BadRequest, I18n.t(:invalid_filter_structure) unless raw.values.all?(String)

        raw.to_unsafe_h.symbolize_keys
      end

      def list_filter(name, allowed: nil, format: nil)
        value = filter_params[name]
        return if value.blank?

        values = value.split(",")
        invalid = values.reject { |v| (allowed.nil? || allowed.include?(v)) && (format.nil? || v.match?(format)) }
        raise ActionController::BadRequest, I18n.t(:invalid_filter, attribute: name) if invalid.any?

        values
      end

      def boolean_filter(name)
        value = filter_params[name]
        return if value.blank?

        BOOLEAN_VALUES.fetch(value) { raise ActionController::BadRequest, I18n.t(:invalid_filter, attribute: name) }
      end

      def requested_includes
        raise ActionController::BadRequest, I18n.t(:unsupported_include, paths: "include") unless params[:include].nil? || params[:include].is_a?(String)

        requested = params[:include].to_s.split(",").map(&:strip)
        unsupported = requested - INCLUDES
        raise ActionController::BadRequest, I18n.t(:unsupported_include, paths: unsupported.join(", ")) if unsupported.any?

        requested.uniq.map(&:to_sym)
      end

      def pagination_links
        {
          self: page_url(@pagy.page),
          prev: (page_url(@pagy.prev) if @pagy.prev),
          next: (page_url(@pagy.next) if @pagy.next),
        }
      end

      def pagination_meta
        { page: @pagy.page, per_page: @pagy.limit }
      end

      # Preserves filter, include and any other query parameters.
      def page_url(page_number)
        query = request.query_parameters.deep_merge("page" => { "page" => page_number, "per_page" => per_page })

        "#{request.base_url}#{request.path}?#{Rack::Utils.build_nested_query(query)}"
      end

      def invalid_pagination_response(_exception)
        render_errors(status: :bad_request, title: I18n.t(:bad_request), details: I18n.t(:invalid_page_parameters))
      end
    end
  end
end
