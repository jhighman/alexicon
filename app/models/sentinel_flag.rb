# A raised Sentinel.
#
# A flag NEVER asserts that a claim is false, or that an author is wrong. It
# asserts that the conditions for proceeding have not been satisfied -- that
# confidence now exceeds the evidence class presented, or that a subject was
# never grounded.
#
# `subject` is polymorphic: Governance flags transitions, Identity flags
# mentions, and later domains will flag other things again.
#
# Agency is preserved throughout. The author may accept or reject any flag, and
# their disposition is recorded alongside the original rather than erasing it.
class SentinelFlag < ApplicationRecord
  SEVERITIES   = %w[notice concern stop].freeze
  DISPOSITIONS = %w[open accepted rejected].freeze

  belongs_to :subject, polymorphic: true
  belongs_to :domain, optional: true

  validates :message, presence: true
  validates :severity,    inclusion: { in: SEVERITIES }
  validates :disposition, inclusion: { in: DISPOSITIONS }

  scope :open,     -> { where(disposition: "open") }
  scope :stopping, -> { where(severity: "stop") }

  # A STOP is a healthy freeze, not a failure. Dissonance signals that the
  # conditions for proceeding were not met.
  def stop? = severity == "stop"

  def dispose!(as:, by: nil)
    raise ArgumentError, "unknown disposition #{as}" unless DISPOSITIONS.include?(as)

    update!(disposition: as, disposed_by: by, disposed_at: Time.current)
  end
end
