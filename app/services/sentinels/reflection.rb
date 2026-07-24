# Reflection — "Can this experience be viewed differently?"
#
# Protects against: emotional capture, narrative lock-in.
#
# Observable, and purely structural: a document that makes interpretive or
# ontological claims while making no objective or observational one. The
# narrative has left its evidential base entirely — there is nothing in the
# document a different reading could be checked against.
#
# This is the strongest of the five, because it needs no lexicon and no
# world knowledge. It reads the categories already assigned and asks whether
# anything grounds them. It also cannot run before classification, and says so
# rather than firing on an unclassified document.
module Sentinels
  class Reflection < DomainSentinel
    GROUNDING_RANK = 1

    def self.domain_key = "reflection"

    private

    def findings
      return [] if classified.empty?
      return [] if grounded.any?
      return [] if elevated.empty?
      return [] if already_flagged?(document)

      [ Finding.new(
        subject: document,
        severity: "concern",
        message: "Every classified claim here is interpretation or assertion about what exists; " \
                 "none is an observation or a checkable fact. There is nothing in the document " \
                 "against which a different reading could be tested"
      ) ]
    end

    def classified = @classified ||= claims.filter_map(&:category)

    def grounded = classified.select { it.justification_rank == GROUNDING_RANK }

    def elevated = classified.select { (it.justification_rank || 0) > GROUNDING_RANK }
  end
end
