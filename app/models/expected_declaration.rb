# A declaration a training is expected to receive, derived from its course milestones.
# Not persisted; the composite id is "<training_id>_<declaration_type>".
ExpectedDeclaration = Struct.new(:training_id, :declaration_type) do
  def id
    "#{training_id}_#{declaration_type}"
  end
end
