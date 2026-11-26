module API
  module V2
    class ApplicationSerializer
      include JSONAPI::Serializer

      set_type :application
      set_id :id

      attributes :email, :contract_assigned_at, :contract_unassigned_at,
                 :created_at, :updated_at, :status, :status_reason, :course, :institution, :funding

      has_one :teacher,
              serializer: TeacherSerializer,
              id_method_name: :teacher_id,
              links: { related: ->(application) { "/api/v2/teachers/#{application.teacher_id}" } }

      has_one :contract,
              serializer: ContractSerializer,
              id_method_name: :contract_id,
              links: { related: ->(application) { "/api/v2/contracts/#{application.contract_id}?application_id=#{application.id}" } }

      has_one :outcome,
              serializer: OutcomeSerializer,
              id_method_name: :outcome_id,
              links: { related: ->(application) { "/api/v2/outcomes/#{application.outcome_id}" if application.outcome_id } }

      has_many :surveys,
               serializer: SurveySerializer,
               id_method_name: :survey_ids,
               links: { related: ->(application) { "/api/v2/surveys?filter[application_id]=#{application.id}" } }

      has_many :expected_declarations,
               serializer: ExpectedDeclarationSerializer,
               id_method_name: :expected_declaration_ids,
               links: { related: ->(application) { "/api/v2/expected-declarations?filter[application_id]=#{application.id}" } }
    end
  end
end
