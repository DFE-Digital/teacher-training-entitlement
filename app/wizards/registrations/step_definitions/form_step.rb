module Registrations
  module StepDefinitions
    class FormStep
      include DfE::Wizard::Step

      # Shared step classes get their answer key from the definition and expose
      # it as a per-instance ActiveModel attribute.
      def initialize(step_attributes = {})
        attributes = step_attributes.symbolize_keys
        wizard = attributes[:wizard]
        step_id = attributes[:step_id]
        definition = wizard&.journey_definition&.find_step_by_slug(step_id.to_s.dasherize)
        answer_field = definition&.answer_key&.to_sym

        if dynamic_answer_field?(definition, answer_field)
          @dynamic_answer_field = answer_field
          @dynamic_answer_value = attributes.delete(answer_field)
          super(attributes)
          define_dynamic_answer_methods
        else
          super(attributes)
        end
      end

      def serializable_data
        return super unless @dynamic_answer_field

        super.merge(@dynamic_answer_field.to_s => @dynamic_answer_value)
      end

      def valid?(context = nil)
        valid = super(context)
        return valid unless @dynamic_answer_field && requires_answer?

        errors.add(@dynamic_answer_field, required_answer_message.presence || "Select an answer") if @dynamic_answer_value.blank?
        errors.empty?
      end

      def step_definition
        wizard.journey_definition.find_step_by_slug(step_id.to_s.dasherize)
      end

      def html_partial?
        step_definition.step_class <= Registrations::StepDefinitions::HtmlPartial
      end

      delegate :state_store, :current_user, to: :wizard

      delegate :name, :slug, :type_as_param, :text_data, :partial_name,
               :answer_key, :answer_display_name,
               :requires_answer?, :required_answer_message,
               :display_on_check_answers?, :multiple_answers?, :display_answer_value,
               :config, to: :step_definition

      def answer_options
        step_definition.answer_options
      end

      def journey_definition
        wizard.journey_definition
      end

      def journey_slug
        journey_definition.slug
      end

      def captured_values
        data = wizard.data
        step_values = data.fetch(:steps, {}).values.reduce({}, :merge)
        step_values.merge(data.except(:steps))
      end

      def answer_field_name
        answer_key.to_sym
      end

      def step_answer
        public_send(answer_field_name) if respond_to?(answer_field_name)
      end

      def service_config
        config["services"] || []
      end

      def redirect_target
        step_definition.resolved_redirect_target(
          state_store:,
          answer: step_answer,
        )
      end

    private

      def dynamic_answer_field?(definition, answer_field)
        definition && answer_field && (definition.state_store_key.present? || definition.requires_answer?) &&
          !self.class.attribute_names.map(&:to_sym).include?(answer_field)
      end

      def define_dynamic_answer_methods
        answer_field = @dynamic_answer_field
        define_singleton_method(answer_field) { @dynamic_answer_value }
        define_singleton_method("#{answer_field}=") { |value| @dynamic_answer_value = value }
      end
    end
  end
end
