module API
  module V2
    class TrainingSerializer
      include JSONAPI::Serializer

      set_type :training
      set_id :id

      attributes :email, :contract_assigned_at, :contract_unassigned_at,
                 :created_at, :updated_at, :status, :status_reason, :course, :funding

      attribute :institution, &:institution_details

      has_one :teacher,
              serializer: TeacherSerializer,
              id_method_name: :teacher_id,
              links: { related: ->(training) { "/api/v2/teachers/#{training.teacher_id}" } }

      has_one :contract,
              serializer: ContractSerializer,
              id_method_name: :contract_id,
              links: { related: ->(training) { "/api/v2/contracts/#{training.contract_id}?training_id=#{training.id}" } }

      has_one :outcome,
              serializer: OutcomeSerializer,
              id_method_name: :outcome_id,
              links: { related: ->(training) { "/api/v2/outcomes/#{training.outcome_id}" if training.outcome_id } }

      has_many :surveys,
               serializer: SurveySerializer,
               id_method_name: :survey_ids,
               links: { related: ->(training) { "/api/v2/surveys?filter[training_id]=#{training.id}" } }

      has_many :expected_declarations,
               serializer: ExpectedDeclarationSerializer,
               id_method_name: :expected_declaration_ids,
               links: { related: ->(training) { "/api/v2/expected-declarations?filter[training_id]=#{training.id}" } }
    end
  end
end
