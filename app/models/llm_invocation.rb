# One row per call to a model.
#
# Immutable, like every other record of something that happened. Written in the
# same transaction as the assertion it produced, and NOT best-effort: a
# swallowed write would leave a judgement in the graph with no account of the
# call that produced it, which is precisely the gap this system exists to
# refuse elsewhere.
#
# A failed call is recorded too. An architecture that only logs its successes
# cannot tell "the model was never asked" from "the model was asked and broke".
class LlmInvocation < ApplicationRecord
  # `rate_limited` is kept apart from `error`: being throttled says something
  # about how hard this application is pushing a provider, not about whether
  # the model can do the work. Collapsing the two hides a capacity problem
  # inside a correctness one.
  STATUSES = %w[success error timeout rate_limited].freeze

  belongs_to :llm_model
  belongs_to :llm_assignment, optional: true
  belongs_to :agent, class_name: "Referent"
  # The judgements this call produced. Empty when the model abstained or failed,
  # and more than one when a batch was sent -- a call that classified twelve
  # claims is answerable for all twelve.
  has_many :assertions, dependent: :nullify

  validates :status, inclusion: { in: STATUSES }
  validates :input_tokens, :output_tokens, :total_tokens,
            numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :cost_usd, numericality: { greater_than_or_equal_to: 0 }

  before_validation :calculate_totals, on: :create

  scope :recent, -> { order(created_at: :desc) }
  scope :successful, -> { where(status: "success") }
  scope :failed, -> { where(status: STATUSES - %w[success]) }
  scope :by_agent, ->(agent) { where(agent: agent) }
  scope :in_range, ->(from, to) { where(created_at: from..to) }

  # Immutable: an invocation records what happened, and what happened does not
  # change.
  def readonly? = persisted?

  def succeeded? = status == "success"

  def self.total_cost = sum(:cost_usd)
  def self.total_tokens = sum(:total_tokens)
  def self.average_latency = average(:latency_ms)&.round

  def self.success_rate
    return nil if count.zero?

    (successful.count.to_f / count * 100).round(1)
  end

  private

  def calculate_totals
    self.total_tokens = input_tokens.to_i + output_tokens.to_i
    self.cost_usd = llm_model&.cost_for(input_tokens: input_tokens.to_i,
                                        output_tokens: output_tokens.to_i) || 0
  end
end
