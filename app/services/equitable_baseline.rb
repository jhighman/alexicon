# A scorer that satisfies gap invariance by construction.
#
# It replaces Ideal-based Scoring, which measures a record against an unbroken
# reference path and reads every departure as a shortfall. This measures what
# was established: which kinds of relationship the record evidences, and how
# many are backed by evidence. It never reads elapsed time, continuity, recency
# or the spaces between spans, and so it cannot penalise them.
#
# What this does NOT claim: that its output is fair. Fairness in general is not
# a property a scorer can have — the standard criteria are provably not
# simultaneously satisfiable. The claim is exactly one property, named, checked
# by GapInvariance and provable by test.
#
# Sources defined this and the Average Ceiling Metric as containing each other
# (THEORY.md §7.4), so the metric was left unimplemented rather than guessed at.
# Matrix 2.0 Q4 settles the direction — this is the POLICY, the metric is the
# METHOD it invokes — and `AverageCeilingMetric` now exists. `#ceiling` and
# `#explain` invoke it; the absolute score is unchanged.
class EquitableBaseline
  CRITERION = GapInvariance::CRITERION

  # Weighted only by what a record establishes, never by how it is spaced.
  KIND_WEIGHT = 1.0
  EVIDENCE_WEIGHT = 0.5

  def self.for(referent) = new.call(Timeline.new(referent))

  def call(timeline)
    (timeline.established_kinds.size * KIND_WEIGHT) +
      (timeline.evidenced_spans * EVIDENCE_WEIGHT)
  end

  def to_proc = method(:call).to_proc

  # The measure this policy applies (Matrix 2.0 Q4). Kept separate from `call`:
  # the score says what a record established, the ceiling says what it
  # established per window of activity, and only the second is comparable
  # between records with different amounts of available time.
  def ceiling(timeline, peers: []) = AverageCeilingMetric.new.read(timeline, peers: peers)

  # States what the score was made of, and — as importantly — what it was not.
  def explain(timeline, peers: [])
    {
      "criterion" => CRITERION,
      "score" => call(timeline),
      "established_kinds" => timeline.established_kinds,
      "evidenced_spans" => timeline.evidenced_spans,
      "gaps_observed" => timeline.gaps.size,
      "gaps_scored" => 0,
      "ceiling" => AverageCeilingMetric.new.explain(timeline, peers: peers),
      "note" => "Gaps are reported so a reviewer may ask about them. They contribute " \
                "nothing to the score: an absence of evidence is not evidence of degradation."
    }
  end
end
