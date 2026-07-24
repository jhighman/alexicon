# Agency — "What choices remain?"
#
# Protects against: determinism, context collapse.
#
# Observable: a claim that asserts necessity about a grounded agent. "He had no
# choice", "she was bound to fail" — language that removes the possibility of
# acting otherwise from someone the graph knows to be a person.
#
# The narrowing matters. Necessity language about the weather is not a collapse
# of agency; necessity language about a person is. So the check requires both
# the marker and a resolved person referent in the same claim, which is why it
# can run at all: both halves are already established facts about the input.
module Sentinels
  class Agency < DomainSentinel
    NECESSITY = /\b(
      had\s+no\s+choice | no\s+choice | could\s+not\s+help | couldn't\s+help |
      was\s+bound\s+to | were\s+bound\s+to | destined\s+to | doomed\s+to |
      inevitab\w+ | unavoidab\w+ | powerless | forced\s+to | compelled\s+to
    )\b/xi

    def self.domain_key = "agency"

    private

    def findings
      claims.filter_map do |claim|
        next unless claim.text.match?(NECESSITY)
        next unless agent_in?(claim)
        next if already_flagged?(claim)

        Finding.new(
          subject: claim,
          severity: "notice",
          message: "This describes a person as having no choice. That may be true, but it is " \
                   "a claim about their agency and not an observation of it"
        )
      end
    end

    def agent_in?(claim)
      claim.mentions.any? { it.referent&.primitive == "person" }
    end
  end
end
