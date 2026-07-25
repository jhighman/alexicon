# An occurrence of an identifier inside a claim -- the unit the Identity
# Sentinel acts on.
#
# Status is DERIVED, not stored. It is the Sentinel's verdict about the INPUT,
# read from the mention's standing judgements: whether a referent was
# established, never who the referent "really" is.
#
# Re-verification supersedes prior judgements, so exactly one judgement stands
# at a time and the derived status cannot disagree with the record.
class Mention < ApplicationRecord
  # Statuses other than `resolved` and `unresolved` name an Entity Noise
  # condition, carried on the flag that detected it.
  NOISE = %w[ambiguous out_of_distribution unanchored].freeze
  STATUSES = (%w[unresolved resolved] + NOISE).freeze

  # There is no partial credit: a subject is grounded or it is not.
  BLOCKING = (STATUSES - %w[resolved]).freeze

  belongs_to :claim

  # Resolutions and flags are both assertions about this mention. NOT
  # dependent: :destroy -- deleting would erase the governance history that
  # explains why the mention was blocked.
  has_many :assertions, as: :subject, dependent: :restrict_with_error

  validates :text, presence: true

  def self.standing_resolutions
    Assertion.acting("resolve").standing.where(subject_type: "Mention")
  end

  scope :resolved, -> { where(id: standing_resolutions.select(:subject_id)) }
  scope :blocking, -> { where.not(id: standing_resolutions.select(:subject_id)) }

  def flags = assertions.flags.standing.chronological

  # What the Identity Proposer suggested this name refers to, if it has been
  # asked. A proposal is inference awaiting a person: it does not resolve the
  # mention, and #status ignores it entirely.
  def identity_proposal
    assertions.acting("assert").standing.chronological
              .reverse_each.find { it.claim["proposal"].present? }
  end

  def resolutions = assertions.acting("resolve").standing.chronological

  # A person's resolution wins over a system's, without erasing it.
  def resolution
    candidates = resolutions.includes(:asserter).to_a
    candidates.select(&:human?).last || candidates.last
  end

  def referent = resolution&.object

  def anchored? = resolution.present?

  # Read from the standing judgements rather than remembered alongside them.
  def status
    return "resolved" if anchored?

    flags.filter_map { it.claim["noise"] }.last || "unresolved"
  end

  # The judgement a fresh verification should supersede, if any.
  def standing_judgement
    assertions.standing.chronological.select { it.act.in?(%w[resolve flag]) }.last
  end
end
