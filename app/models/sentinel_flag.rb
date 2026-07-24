# A raised Sentinel.
#
# A flag NEVER asserts that a claim is false. It asserts that the confidence of
# a statement now exceeds the evidence class presented. Agency is preserved:
# the author may accept or reject the flag, and their disposition is recorded
# alongside the original rather than erasing it.
class SentinelFlag < ApplicationRecord
  SEVERITIES   = %w[notice concern stop].freeze
  DISPOSITIONS = %w[open accepted rejected].freeze

  belongs_to :transition
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
