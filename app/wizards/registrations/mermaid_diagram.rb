module Registrations
  class MermaidDiagram
    def initialize(journey_definition:)
      @journey_definition = journey_definition
    end

    def call
      ["flowchart TD", *node_lines, *edge_lines].join("\n")
    end

  private

    attr_reader :journey_definition

    def step_definitions
      @step_definitions ||= journey_definition.step_definitions
    end

    def node_lines
      step_definitions.map do |step_definition|
        "  #{node_id(step_definition)}[\"#{escape_label(step_definition.name)}\"]"
      end
    end

    def edge_lines
      step_definitions.flat_map { |step_definition|
        answers_with_destinations = step_definition.answer_options.select(&:next_step)
        default_next_step = step_definition.default_next_step

        if answers_with_destinations.any?
          conditional_edge_lines(step_definition, answers_with_destinations) +
            default_answer_edge_lines(step_definition, default_next_step)
        elsif default_next_step
          Array(edge_line(step_definition, default_next_step))
        else
          []
        end
      }.uniq
    end

    def conditional_edge_lines(step_definition, answers)
      answers.map do |answer|
        edge_line(step_definition, answer.next_step, label: answer.name)
      end
    end

    def default_answer_edge_lines(step_definition, default_next_step)
      return [] unless default_next_step

      step_definition.answer_options.reject(&:next_step).map do |answer|
        edge_line(step_definition, default_next_step, label: answer.name)
      end
    end

    def edge_line(from, to, label: nil)
      label_text = label.present? ? "|\"#{escape_label(label)}\"|" : ""

      "  #{node_id(from)} -->#{label_text} #{node_id(to)}"
    end

    def node_id(step_definition)
      "step_#{step_definition.graph_id}"
    end

    def escape_label(label)
      label.to_s.gsub("\\", "\\\\").gsub('"', '\\"')
    end
  end
end
