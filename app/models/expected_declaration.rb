# A declaration an application is expected to receive, derived from its course milestones.
# Not persisted; the composite id is "<application ecf_id>_<declaration_type>".
ExpectedDeclaration = Struct.new(:application_id, :declaration_type) do
  def id
    "#{application_id}_#{declaration_type}"
  end
end
