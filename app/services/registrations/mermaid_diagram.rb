module Registrations
  class MermaidDiagram
    def initialize(registration_journey:)
      @registration_journey = registration_journey
    end

    def call
      ["flowchart TD", *node_lines, *edge_lines].join("\n")
    end

  private

    attr_reader :registration_journey

    def registration_steps
      @registration_steps ||= registration_journey.registration_steps.order(:id)
    end

    def node_lines
      registration_steps.map do |registration_step|
        "  #{node_id(registration_step)}[\"#{escape_label(registration_step.name)}\"]"
      end
    end

    def edge_lines
      registration_steps.flat_map { |registration_step|
        answers_with_destinations = registration_step.registration_step_answers.select(&:next_step)
        default_next_step = RegistrationSteps::BranchTraversal::DefaultNextStep.new(registration_journey:, registration_step:).call

        if answers_with_destinations.any?
          conditional_edge_lines(registration_step, answers_with_destinations) +
            default_answer_edge_lines(registration_step, default_next_step)
        elsif default_next_step
          Array(edge_line(registration_step, default_next_step))
        else
          []
        end
      }.uniq
    end

    def conditional_edge_lines(registration_step, answers)
      answers.map do |answer|
        edge_line(registration_step, answer.next_step, label: answer.name)
      end
    end

    def default_answer_edge_lines(registration_step, default_next_step)
      return [] unless default_next_step

      registration_step.registration_step_answers.reject(&:next_step).map do |answer|
        edge_line(registration_step, default_next_step, label: answer.name)
      end
    end

    def edge_line(from, to, label: nil)
      label_text = label.present? ? "|\"#{escape_label(label)}\"|" : ""

      "  #{node_id(from)} -->#{label_text} #{node_id(to)}"
    end

    def node_id(registration_step)
      "step_#{registration_step.id}"
    end

    def escape_label(label)
      label.to_s.gsub("\\", "\\\\").gsub('"', '\\"')
    end
  end
end
