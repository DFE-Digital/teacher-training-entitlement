module Admin
  module CourseBuilder
    module Steps
      class UpliftInstitutions
        include DfE::Wizard::Step

        attribute :uplift_institution_ids, default: -> { [] }
        attribute :uplift_institution_search, :string

        validate :at_least_one_institution_selected

        def self.permitted_params
          [:uplift_institution_search, { uplift_institution_ids: [] }]
        end

        def uplift_institution_ids=(value)
          super(Array(value).filter_map { |id| Integer(id, exception: false) }.uniq)
        end

        def uplift_institution_search=(value)
          super(value.to_s.strip.presence)
        end

        def selected_institutions
          @selected_institutions ||= Institution.where(id: uplift_institution_ids).order(:name).to_a
        end

        def search_results
          return [] if uplift_institution_search.blank?

          Institution.search(uplift_institution_search)
                     .where.not(id: uplift_institution_ids)
                     .order(:name)
                     .to_a
        end

        def institution_options
          selected_institutions + search_results
        end

      private

        def at_least_one_institution_selected
          return if selected_institutions.any?

          errors.add(:uplift_institution_ids, "Select at least one institution")
        end
      end
    end
  end
end
