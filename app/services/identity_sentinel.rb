# Guards the input boundary.
#
# Trust assertion: *does this subject exist as a grounded entity?* It is asked
# and answered before anything reaches the reasoning layers.
#
# The Sentinel does not perform the task. It asks whether the conditions for
# performing the task have been satisfied. On failure it does not guess, does
# not degrade gracefully, and does not pick the likeliest candidate -- it locks
# execution and escalates to a person.
#
# A STOP is a healthy freeze. Dissonance signals that the conditions were not
# met; it is a correct outcome, not an error to be smoothed over.
class IdentitySentinel
  RESOLVER = "ReferentResolver"

  def self.verify!(mention) = new(mention).verify!

  def initialize(mention)
    @mention = mention
  end

  def verify!
    result = ReferentResolver.new(mention).call

    if result.resolved?
      record_resolution(result)
    else
      raise_flag(result)
    end

    mention
  end

  private

  attr_reader :mention

  # A resolution is an assertion: the Sentinel claiming this mention refers to
  # that referent. Recorded as an inference, never as a finding -- and a person
  # may later resolve it differently without erasing this.
  def record_resolution(result)
    mention.transaction do
      Assertion.create!(
        asserter: sentinel_referent,
        subject: mention,
        object: result.referent,
        act: "resolve",
        claim: { "confidence" => 1.0, "rationale" => result.reason, "resolver" => RESOLVER }
      )
      mention.update!(status: "resolved")
    end
  end

  # The flag is an assertion, attributed to the Identity Sentinel. A governance
  # signal with no accountable author would be exactly the ungrounded claim
  # this sentinel exists to refuse.
  def raise_flag(result)
    mention.transaction do
      mention.update!(status: result.status.to_s)
      Assertion.create!(
        asserter: sentinel_referent,
        subject: mention,
        act: "flag",
        claim: { "severity" => "stop", "message" => message_for(result) }
      )
    end
  end

  # The message states what was not established. It never asserts who the
  # referent is, and never implies the author is wrong.
  def message_for(result)
    case result.status
    when :ambiguous
      "Identity not established: #{result.reason}. Clarification required before " \
        "any inference may attach to this subject."
    when :out_of_distribution
      "Identity not established: #{result.reason}. The subject is unverified."
    when :unanchored
      "Identity not established: #{result.reason}. A partial passport is not a " \
        "weaker anchor; it is no anchor."
    else
      "Identity not established: #{result.reason}."
    end
  end

  def sentinel_referent
    @sentinel_referent ||= Referent.sentinel_for("identity")
  end
end
