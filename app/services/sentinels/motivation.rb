# Motivation — "Why does this matter?"
#
# Protects against: local optimization, false objectives.
#
# Observable: a prescription. "Everyone should…", "you ought to…" — a claim
# that tells someone to act, in a document that never says what the action is
# for. A prescription without a purpose is the shape a false objective takes:
# the instruction survives, the reason for it does not.
#
# This sentinel does not judge whether the prescription is right. It asks what
# it is for, which is a question only a person can answer — the flag is an
# escalation, not a finding.
module Sentinels
  class Motivation < DomainSentinel
    PRESCRIPTIVE = /\b(
      should | ought\s+to | must\s+be | needs?\s+to | have\s+to | has\s+to |
      everyone\s+\w+ | nobody\s+should | one\s+must
    )\b/xi

    # A purpose is stated when the document connects the prescription to an
    # end: "so that", "in order to", "because", "to avoid".
    PURPOSE = /\b(so\s+that|in\s+order\s+to|because|since|to\s+avoid|for\s+the\s+sake\s+of)\b/i

    def self.domain_key = "motivation"

    private

    def findings
      return [] if purpose_stated?

      claims.filter_map do |claim|
        next unless claim.text.match?(PRESCRIPTIVE)
        next if already_flagged?(claim)

        Finding.new(
          subject: claim,
          severity: "notice",
          message: "This prescribes an action, and nothing in the document says what it is for"
        )
      end
    end

    # Checked across the whole document: the purpose may be stated in a
    # neighbouring claim rather than the prescriptive one.
    def purpose_stated? = claims.any? { it.text.match?(PURPOSE) }
  end
end
