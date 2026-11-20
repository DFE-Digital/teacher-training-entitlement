module DeliveryPartnerships
  # Creates new delivery partners from names, each with an active partnership
  # for the course + lead provider. All or nothing.
  class CreatePartners
    Result = Struct.new(:success, :errors, keyword_init: true) do
      def success? = success
    end

    BLANK_ERROR = "Enter a delivery partner name".freeze
    EXISTS_ERROR = "This delivery partner already exists, select it on the edit form instead".freeze
    DUPLICATE_ERROR = "This delivery partner name is entered more than once".freeze

    # errors are keyed by input index; :base errors by :base
    def initialize(course:, lead_provider:, names:)
      @course = course
      @lead_provider = lead_provider
      @names = Array(names).map { _1.to_s.strip }
    end

    def call
      return failure(base: BLANK_ERROR) if entered.empty?

      errors = validation_errors
      return failure(errors) if errors.any?

      ActiveRecord::Base.transaction do
        entered.each do |(_index, name)|
          partner = DeliveryPartner.create!(name:, ecf_id: SecureRandom.uuid)
          DeliveryPartnership.create!(delivery_partner: partner, course: @course, lead_provider: @lead_provider)
        end
      end

      Result.new(success: true, errors: {})
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      failure(base: "The delivery partners could not be saved, please try again")
    end

  private

    def entered
      @entered ||= @names.each_with_index.filter_map { |name, index| [index, name] if name.present? }
    end

    def validation_errors
      existing = DeliveryPartner.where("lower(name) IN (?)", entered.map { _2.downcase }).pluck(:name).map(&:downcase)
      seen = []

      entered.each_with_object({}) do |(index, name), errors|
        key = name.downcase
        if existing.include?(key)
          errors[index] = EXISTS_ERROR
        elsif seen.include?(key)
          errors[index] = DUPLICATE_ERROR
        end
        seen << key
      end
    end

    def failure(errors)
      Result.new(success: false, errors:)
    end
  end
end
