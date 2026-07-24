# Integration — "What larger pattern emerges?"
#
# Protects against: fragmented reasoning, isolated facts.
#
# Observable, and structural: a claim whose subjects appear nowhere else in the
# document. It is asserted, and then nothing connects to it — no other claim is
# about the same referent. Klein's point in miniature: no claim stands alone,
# and one that does is either misplaced or the pattern around it is missing.
#
# Only runs where there is a pattern to be part of: a document of one claim
# cannot have an isolated one, and a claim with no grounded subject is not
# isolated, it is ungrounded — which is Identity's business, not this one.
module Sentinels
  class Integration < DomainSentinel
    def self.domain_key = "integration"

    private

    def findings
      return [] if claims.size < 3

      claims.filter_map do |claim|
        subjects = referents_in(claim)
        next if subjects.empty?
        next if subjects.any? { |id| elsewhere?(id, claim) }
        next if already_flagged?(claim)

        Finding.new(
          subject: claim,
          severity: "notice",
          message: "Nothing else in this document is about #{names_in(claim)}. This claim is " \
                   "asserted and then left unconnected"
        )
      end
    end

    def referents_in(claim) = claim.mentions.filter_map { it.referent&.id }

    def names_in(claim) = claim.mentions.filter_map { it.referent&.name }.uniq.join(", ")

    def elsewhere?(referent_id, claim)
      claims.any? { it != claim && referents_in(it).include?(referent_id) }
    end
  end
end
