# Orientation — "What enduring way of being emerges?"
#
# Protects against: opportunistic drift, cynicism.
#
# This one does not read the text. It reads the dispositions.
#
# Chapter 7.4 names four ways a sentinel architecture fails, and the fourth is
# the one no other check here can see: governance that exists but performs no
# meaningful evaluation. A reviewer who accepts every flag is performing
# ceremony; one who rejects every flag is performing cynicism. Both produce a
# clean-looking document, and both mean the flags were never actually weighed.
#
# So the pattern of answers is itself an observable, and it is the only place
# in this system where a sentinel governs the people rather than the text.
# That is uncomfortable by design: an architecture whose whole claim is that
# every transition needs an independent observer cannot exempt the observers.
#
# It reports a pattern, not a verdict on anyone. Answering every flag the same
# way may be exactly right — if every flag deserved the same answer.
module Sentinels
  class Orientation < DomainSentinel
    # Below this, a uniform run is unremarkable rather than a pattern.
    THRESHOLD = 4

    def self.domain_key = "orientation"

    private

    def findings
      dispositions_by_reviewer.filter_map do |reviewer, acts|
        next if acts.size < THRESHOLD
        next unless acts.uniq.one?
        next if already_flagged?(document)

        Finding.new(subject: document, severity: "notice", message: message_for(reviewer, acts))
      end
    end

    # Every disposition made about this document's flags, grouped by who made it.
    def dispositions_by_reviewer
      Assertion.where(subject_type: "Assertion", subject_id: document.flags.select(:id))
               .where(act: Assertion::DISPOSING)
               .includes(:asserter)
               .group_by(&:asserter)
               .transform_values { |assertions| assertions.map(&:act) }
    end

    def message_for(reviewer, acts)
      posture = acts.first == "accept" ? "let every one of them stand" : "set every one of them aside"
      "#{reviewer.name} has answered #{acts.size} flags here and #{posture}. That may be exactly " \
        "right — but a uniform answer is also what it looks like when flags are not being weighed"
    end
  end
end
