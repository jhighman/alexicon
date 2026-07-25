# Guards Column D: the force a claim applies, and whether it can be read at all.
#
# Named for the Situational Sentinel of the manuscript's Freud mapping. Like
# every sentinel here it does not perform the task — it does not decide what a
# claim means. It asks whether the conditions for reading the claim's direction
# have been satisfied, and says so when they have not.
#
# It raises a CONCERN, never a STOP. An unreadable polarity does not make the
# document ungroundable the way an unresolved name does: nothing downstream is
# predicating a direction of anything yet. The reader is told that the grammar
# here will mislead them, and left to read.
class SituationalSentinel
  SENTINEL = "situational-sentinel".freeze

  def self.review!(claim) = new(claim).review!

  # Every claim in a document, skipping none silently.
  def self.review_document!(document)
    document.claims.substantive.map { review!(it) }.compact
  end

  def initialize(claim)
    @claim = claim
  end

  # Returns the flag raised, or nil when the surface reading can be trusted.
  def review!
    reading = ClaimPolarity.for(claim.text)
    return nil if reading.reliable?
    return existing if existing

    Assertion.create!(
      asserter: sentinel, subject: claim, act: "flag",
      claim: { "severity" => "concern", "message" => message(reading),
               "surface_polarity" => reading.surface.to_s,
               "unreliable" => reading.unreliable.map(&:to_s) }
    )
  end

  private

  attr_reader :claim

  def sentinel = @sentinel ||= Referent.find_by!(key: SENTINEL)

  # One flag per claim, however often the document is reviewed. Re-raising would
  # bury a reviewer who had already answered it.
  def existing
    claim.assertions.flags.standing.find { it.claim["surface_polarity"].present? }
  end

  def message(reading)
    "Surface grammar reads as #{reading.surface}, but #{reading.reason} makes that " \
      "reading unreliable — a negation here may carry the intent it appears to deny. " \
      "The direction of this claim is not established by its grammar."
  end
end
