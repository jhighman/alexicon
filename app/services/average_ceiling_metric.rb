# The measure Equitable Baseline Scoring applies.
#
# Sources defined this and Equitable Baseline Scoring as containing each other,
# so it was left unimplemented rather than guessed at — a guess underneath the
# one part of this system with real-world stakes. Matrix 2.0 Q4 settles the
# direction: Equitable Baseline Scoring is the POLICY, the Average Ceiling
# Metric is the METHOD that policy invokes. This is the method.
#
# Q5 settles the harder question — over which reference population the ceiling
# is averaged — by refusing a population at all. A ceiling averaged over an
# already-advantaged group reproduces the advantage it exists to remove. So the
# ceiling is truncated to the entity's OWN active windows.
#
# --- The rule the whole design turns on -------------------------------------
#
# The ceiling reads ACTIVE WINDOWS ONLY. Never calendar span, never elapsed
# time, never the distance between windows.
#
# This is not a stylistic preference. A ceiling computed over calendar time
# would divide by a bigger number for a record containing a pause, so the same
# established work would score lower for having been interrupted — the exact
# penalty the anti-discrimination policy exists to remove, reintroduced through
# the denominator. Truncating to active windows makes the metric gap-invariant
# by construction: a gap adds no window, so it moves neither the score nor the
# ceiling. `PolicyAudit.call(scorer: AverageCeilingMetric.new)` proves it rather
# than assuming it.
#
# What the split buys: `ceiling` is what an entity establishes per window of
# activity, and `windows` is how many windows it had. Advantage lives almost
# entirely in the second. Reporting them apart lets a reader compare demonstrated
# rates without importing the difference in available time — which is what
# "clamps the active window instead of averaging the aggregate privilege" means
# once it has to be arithmetic.
class AverageCeilingMetric
  # The same weights Equitable Baseline Scoring uses, because the ceiling has to
  # be denominated in the units of the thing it is a ceiling on.
  KIND_WEIGHT = EquitableBaseline::KIND_WEIGHT
  EVIDENCE_WEIGHT = EquitableBaseline::EVIDENCE_WEIGHT

  Reading = Data.define(:ceiling, :windows, :total, :peer_ceiling, :relative) do
    def none? = windows.zero?

    # Whether this entity was compared to anyone. Absent a peer group the
    # ceiling stands alone, which is the honest default: there is no population
    # average here to fall back on.
    def compared? = peer_ceiling.present?

    def to_s
      return "no active window" if none?

      base = "#{ceiling.round(3)} per window across #{windows}"
      compared? ? "#{base}, #{(relative * 100).round(1)}% of peers" : base
    end
  end

  def self.for(referent, peers: []) = new.read(Timeline.new(referent), peers: peers.map { Timeline.new(it) })

  # A scorer, so it can be audited by the same contract every scorer here faces.
  def call(timeline) = ceiling(timeline)

  def to_proc = method(:call).to_proc

  # What the entity established, per window in which it was active.
  #
  # Mean rather than maximum: a ceiling taken from the single best window would
  # be a record's high-water mark, and a record with one window would define its
  # own ceiling and always sit exactly at it.
  def ceiling(timeline)
    windows = active_windows(timeline)
    return 0.0 if windows.empty?

    (windows.sum { window_score(it) } / windows.size).round(6)
  end

  # Peers are SUPPLIED, never inferred.
  #
  # Q5 asks for a peer group "sharing identical environmental or parental
  # pauses". Deriving that group would mean reading the record for who paused
  # and why — recovering the sensitive attribute from exactly the gaps this
  # policy forbids reading. So the caller names the peers on other grounds and
  # the metric compares demonstrated rates. A peer contributes its ceiling, not
  # its length: a comparison against how much time someone had is the privilege
  # comparison this replaces.
  def read(timeline, peers: [])
    windows = active_windows(timeline)
    mine = ceiling(timeline)
    peer_ceilings = peers.map { ceiling(it) }.reject(&:zero?)
    peer_mean = (peer_ceilings.sum / peer_ceilings.size).round(6) if peer_ceilings.any?

    Reading.new(ceiling: mine, windows: windows.size,
                total: (mine * windows.size).round(6),
                peer_ceiling: peer_mean,
                relative: peer_mean&.positive? ? (mine / peer_mean).round(4) : nil)
  end

  # Says what the ceiling was made of and, as importantly, what it was not.
  def explain(timeline, peers: [])
    reading = read(timeline, peers: peers)

    {
      "metric" => "average ceiling",
      "ceiling" => reading.ceiling,
      "active_windows" => reading.windows,
      "peer_ceiling" => reading.peer_ceiling,
      "relative_to_peers" => reading.relative,
      "peers_supplied" => peers.size,
      "note" => "Averaged over this record's own active windows, never over a " \
                "population. Elapsed time, continuity, recency and the spaces " \
                "between windows are not read, so a pause cannot move the ceiling " \
                "in either direction."
    }
  end

  private

  # A window is a span in which something was established. A gap is not a
  # window, which is the entire reason this is gap-invariant.
  def active_windows(timeline) = timeline.spans

  def window_score(span)
    KIND_WEIGHT + (span.relationship&.evidence&.any? ? EVIDENCE_WEIGHT : 0.0)
  end
end
