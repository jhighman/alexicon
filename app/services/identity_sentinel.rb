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

  # `by` is whoever DECIDED, when somebody did. Verification at ingest is the
  # Sentinel's own inference and passes nothing; answering a STOP by grounding a
  # name is a decision, and it belongs to the person or agent who made it.
  def self.verify!(mention, by: nil, casing: nil) = new(mention, by: by, casing: casing).verify!

  def initialize(mention, by: nil, casing: nil)
    @mention = mention
    @by = by
    @casing = casing
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

  attr_reader :mention, :by

  # Who the record says decided this. Every resolution in the database was
  # attributed to the Sentinel — all 422 of them — including the ones somebody
  # answered a STOP to make. `Mention#resolution` prefers a person's resolution
  # over a system's, and that branch could not fire, because no resolution was
  # ever asserted by a person. The profile reported "N of N inferred by an agent
  # rather than decided by a person" and would have gone on reporting it however
  # many names a person grounded by hand.
  #
  # Identity precedes reasoning here: nothing may be predicated of an ungrounded
  # subject, so the answer to "who says this name refers to that" is load-bearing
  # for every judgement downstream of it. Recording the Sentinel as the author of
  # a decision it did not make is the misattribution this system exists to catch,
  # committed at the layer everything else stands on.
  def decider = by || sentinel_referent

  # A resolution is an assertion: someone claiming this mention refers to that
  # referent. Recorded as an inference when the Sentinel made it and as a
  # decision when somebody did -- and a person may later resolve it differently
  # without erasing this.
  def record_resolution(result)
    claim = { "confidence" => 1.0, "rationale" => result.reason, "resolver" => RESOLVER }
    # Distinguishes a name somebody answered a STOP to ground from one the
    # resolver matched on its own. Both may be asserted by a system — an agent
    # grounding under delegation is not a person — so `inferred?` alone cannot
    # tell them apart, and the difference is what a reader needs.
    # Always written, both ways. If only the true case were recorded, a
    # resolution from before this distinction existed would be indistinguishable
    # from an automatic match — and 422 of those are in the record, some of which
    # somebody did answer a STOP to make. An absent key means "recorded before
    # resolutions named their decider", which is a different thing from "nobody
    # was asked" and must not be reported as it.
    claim["grounded"] = by.present?

    Assertion.create!(
      asserter: decider,
      subject: mention,
      object: result.referent,
      act: "resolve",
      claim: claim,
      supersedes: mention.standing_judgement
    )
  end

  # The flag is an assertion, attributed to the Identity Sentinel. A governance
  # signal with no accountable author would be exactly the ungrounded claim
  # this sentinel exists to refuse.
  #
  # `noise` records WHICH Entity Noise condition was detected, so the mention's
  # status can be read from the judgement rather than cached beside it.
  def raise_flag(result)
    Assertion.create!(
      asserter: sentinel_referent,
      subject: mention,
      act: "flag",
      claim: { "severity" => severity,
               "noise" => result.status.to_s,
               "message" => message_for(result) },
      supersedes: mention.standing_judgement
    )
  end

  # A STOP says the conditions for proceeding were not met. That is the right
  # answer for a name nothing explains — and the wrong one for a capital that
  # position already accounts for.
  #
  # "Distinct" opens 29 bolded notes in one appendix and appears capitalised
  # mid-sentence not once. Every occurrence of the capital is explained by where
  # it sits, so the evidence that an unknown SUBJECT exists is absent, and 29
  # STOPs raised on it locked governance over a whole document for a word that
  # is not a name.
  #
  # The candidate is still proposed, still flagged, still visible and still
  # groundable by a person. The extractor deliberately over-proposes so the
  # system never silently reasons past a subject it has never met, and dropping
  # these in extraction would have traded that guarantee away — it also dropped
  # `Lacan` and `Tononi`, which appear only at the starts of sentences in this
  # corpus and are plainly names. What changes is only whether the flag BLOCKS.
  #
  # So the evidence moves severity rather than existence: `notice` where
  # position explains the capital, `stop` where nothing does.
  def severity = positionally_explained? ? "notice" : "stop"

  def positionally_explained?
    text = mention.text.to_s
    return false if text.include?(" ")

    casing.only_ever_sentence_initial?(text)
  end

  def casing
    @casing ||= CasingEvidence.for(mention.claim&.document)
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
