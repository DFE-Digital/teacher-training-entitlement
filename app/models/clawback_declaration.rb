# Internal declaration created when voiding a paid declaration
# paid declaration references clawback declaration
class ClawbackDeclaration < Declaration
  validates :paid_declaration, presence: true

  enum :state, {
    submitted: "submitted",
    awaiting_clawback: "awaiting_clawback",
    clawed_back: "clawed_back",
  }, suffix: true

  state_machine :state, initial: :submitted do
    event :mark_awaiting_clawback do
      transition %i[submitted] => :awaiting_clawback
    end

    event :mark_clawed_back do
      transition %i[awaiting_clawback] => :clawed_back
    end
  end
end
