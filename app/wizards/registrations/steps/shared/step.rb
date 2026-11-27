module Registrations
  module Steps
    module Shared
      class Step
        include DfE::Wizard::Step

        def self.with_title(title)
          const_set(:TITLE, title.to_s.freeze)
        end

        def self.with_attribute(attribute)
          const_set(:ATTRIBUTE, attribute.to_sym)
        end

        def self.with_answer_display_name(name)
          const_set(:ANSWER_DISPLAY_NAME, name.to_s.freeze)
        end

        def self.with_multiple_answers(multiple)
          const_set(:MULTIPLE_ANSWERS, multiple)
        end

        def self.with_display_on_check_answers(display)
          const_set(:DISPLAY_ON_CHECK_ANSWERS, display)
        end

        def self.with_text(text, text_class: "govuk-body")
          @texts ||= []
          @texts << { "text" => Array(text), "text_class" => text_class }
        end

        def self.texts = @texts || []

        def self.permitted_params = []

        def partial_name
          self.class.superclass.name.demodulize.underscore
        end
      end
    end
  end
end
