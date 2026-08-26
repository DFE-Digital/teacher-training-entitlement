class RegistrationJourneyGraph
  def initialize(registration_journey)
    @registration_journey = registration_journey
    @registration_steps = registration_journey.registration_steps.to_a
  end

  def to_mermaid
    [
      "flowchart TD",
      *node_lines,
      *edge_lines,
    ].join("\n")
  end

  def configuration_rows
    registration_steps.map do |registration_step|
      answer_data = answer_data_for(registration_step)

      {
        id: registration_step.id,
        name: registration_step.name,
        answer_names: answer_data.map { |answer| answer["name"] },
        previous_step_name: configured_step_name(registration_step.previous_step_id),
        answer_next_steps: answer_data.filter_map do |answer|
          next_step_id = answer["next_step_id"]
          next if next_step_id.blank?

          {
            answer_name: answer["name"],
            step_name: configured_step_name(next_step_id),
          }
        end,
        branch_join_step_name: configured_step_name(registration_step.branch_join_step_id),
      }
    end
  end

  def previous_step_for(registration_step, state_store: nil)
    return registration_step.previous_registration_step unless state_store

    selected_branch_previous_step_for(registration_step, state_store:) ||
      registration_step.previous_registration_step
  end

  def next_steps_for(registration_step)
    branch_edges = branch_edges_for(registration_step)

    return branch_edges.map { |edge| { step: edge[:to], label: edge[:label] } } if branch_edges.any?

    next_step = default_next_step_for(registration_step)
    return [] unless next_step

    [{ step: next_step }]
  end

  def branch_steps_for_answer(registration_step, answer)
    next_step = registration_step.next_registration_step_for(answer:)
    return [] unless next_step

    branch_definition = branch_definitions.find { |definition| definition[:root] == registration_step }
    stop_id = branch_definition&.dig(:join)&.id

    branch_tree_for(next_step.id, stop_id:).filter_map do |step_id|
      registration_steps.find { |step| step.id == step_id }
    end
  end

  def default_next_step_for(registration_step)
    explicit_next_step = registration_steps.find { |step| step.previous_step_id.to_i == registration_step.id }
    return explicit_next_step if explicit_next_step

    branch_definition = innermost_branch_containing(registration_step)
    return branch_definition[:join] if branch_definition&.dig(:join)

    registration_steps[registration_steps.index(registration_step) + 1]
  end

  def order_groups
    visited_step_ids = Set.new

    registration_steps.filter_map do |registration_step|
      next if visited_step_ids.include?(registration_step.id)

      group_step_ids = order_group_step_ids_for(registration_step)
      visited_step_ids.merge(group_step_ids)

      registration_steps.select { |step| group_step_ids.include?(step.id) }
    end
  end

  def order_group_for(registration_step)
    order_groups.find { |group| group.include?(registration_step) }
  end

  def order_group_root?(registration_step)
    order_group_for(registration_step)&.first == registration_step
  end

private

  attr_reader :registration_steps

  def node_lines
    registration_steps.map do |registration_step|
      "  #{node_id(registration_step)}[\"#{escape_label(registration_step.name)}\"]"
    end
  end

  def edge_lines
    edges.uniq.map do |edge|
      label = edge[:label].present? ? "|\"#{escape_label(edge[:label])}\"|" : ""

      "  #{node_id(edge[:from])} -->#{label} #{node_id(edge[:to])}"
    end
  end

  def edges
    registration_steps.flat_map do |registration_step|
      [
        *branch_edges_for(registration_step),
        *default_answer_edges_for(registration_step),
        default_edge_for(registration_step),
      ].compact
    end
  end

  def branch_edges_for(registration_step)
    return [] if registration_step.answer_data.empty?

    registration_step.answer_data.filter_map do |answer|
      next_step = registration_steps.find { |step| step.id == answer["next_step_id"].to_i }
      next unless next_step

      { from: registration_step, to: next_step, label: answer["name"] }
    end
  end

  def default_answer_edges_for(registration_step)
    return [] if registration_step.answer_data.empty?
    return [] if branch_edges_for(registration_step).empty?

    next_step = default_next_step_for(registration_step)
    return [] unless next_step

    registration_step.answer_data.filter_map do |answer|
      next if answer["next_step_id"].present?

      { from: registration_step, to: next_step, label: answer["name"] }
    end
  end

  def default_edge_for(registration_step)
    next_step = next_steps_for(registration_step).first&.fetch(:step)
    return unless next_step
    return if branch_edges_for(registration_step).any?

    { from: registration_step, to: next_step }
  end

  def order_group_step_ids_for(registration_step)
    branch_definition = branch_definitions.find { |definition| definition[:root] == registration_step }
    return [registration_step.id] unless branch_definition

    [registration_step.id, *branch_definition[:member_ids]]
  end

  def branch_definitions
    @branch_definitions ||= registration_steps.filter_map do |registration_step|
      next if registration_step.answer_data.empty?

      branch_root_ids = registration_step.answer_data.filter_map { |answer| answer["next_step_id"].presence&.to_i }.uniq
      next unless branch_root_ids.many?

      explicit_join = registration_step.branch_join_registration_step
      member_ids = branch_root_ids.flat_map do |root_id|
        branch_tree_for(root_id, stop_id: explicit_join&.id)
      end
      member_ids.uniq!

      {
        root: registration_step,
        member_ids:,
        join: explicit_join || next_step_after_branch_group(member_ids),
      }
    end
  end

  def selected_branch_previous_step_for(registration_step, state_store:)
    branch_definitions
      .select { |definition| definition[:join] == registration_step }
      .filter_map { |definition| previous_step_from_branch_definition(definition, registration_step, state_store:) }
      .max_by { |step| registration_steps.index(step) || 0 }
  end

  def previous_step_from_branch_definition(branch_definition, registration_step, state_store:)
    root_step = branch_definition[:root]
    answer = value_from_state_store(state_store, root_step.answer_key)
    branch_root = root_step.next_registration_step_for(answer:)

    return unless branch_root
    return root_step if branch_root == registration_step

    last_step_before(registration_step, from: branch_root, state_store:)
  end

  def last_step_before(target_step, from:, state_store:)
    visited_step_ids = Set.new
    current_step = from

    while current_step && !visited_step_ids.include?(current_step.id)
      visited_step_ids.add(current_step.id)

      next_step = selected_next_step_for(current_step, state_store:)
      return current_step if next_step == target_step

      current_step = next_step
    end
  end

  def selected_next_step_for(registration_step, state_store:)
    answer = value_from_state_store(state_store, registration_step.answer_key)
    registration_step.next_registration_step_for(answer:) ||
      default_next_step_for(registration_step)
  end

  def value_from_state_store(state_store, key)
    state_store[key] || state_store[key.to_sym]
  end

  def innermost_branch_containing(registration_step)
    branch_definitions
      .select { |definition| registration_step.id.in?(definition[:member_ids]) }
      .min_by { |definition| definition[:member_ids].size }
  end

  def branch_tree_for(root_id, stop_id: nil, visited: Set.new)
    return [] if root_id == stop_id || visited.include?(root_id)

    visited = visited.dup.add(root_id)
    child_ids = registration_steps
      .select { |step| step.previous_step_id.to_i == root_id && step.id != stop_id }
      .flat_map do |step|
        branch_tree_for(step.id, stop_id:, visited:)
      end

    [root_id, *child_ids]
  end

  def next_step_after_branch_group(member_ids)
    branch_group_indexes = member_ids.filter_map do |step_id|
      registration_steps.index { |registration_step| registration_step.id == step_id }
    end

    return if branch_group_indexes.empty?

    registration_steps[branch_group_indexes.max + 1]
  end

  def node_id(registration_step)
    "step_#{registration_step.id}"
  end

  def escape_label(label)
    label.to_s.gsub("\\", "\\\\\\").gsub("\"", "\\\"")
  end

  def configured_step_name(step_id)
    return if step_id.blank?

    registration_steps.find { |step| step.id == step_id.to_i }&.name || "Unknown step (#{step_id})"
  end

  def answer_data_for(registration_step)
    return [] unless registration_step.respond_to?(:answer_data)

    registration_step.answer_data
  end
end
