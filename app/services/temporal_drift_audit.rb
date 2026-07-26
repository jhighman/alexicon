# Whether an actor has quietly stopped deciding the way it used to.
#
# Alexandra Krížová's second anti-poisoning mechanism, and the half of Matrix 2.0
# Q7.2 that TEI inversion does not cover. `Delegation` tightens what a broad
# permission must carry at the moment it is GRANTED; nothing watches what the
# holder does with it afterwards. A covert policy does not arrive in one
# suspicious command — it arrives as a slow shift across many reasonable ones,
# each individually defensible, which is precisely the shape TEI inversion
# cannot see.
#
# So this compares an actor against its own past: the distribution of outcomes
# it has been reaching lately, against the distribution it reached before. Not
# against a population, and not against a rule about how a reviewer ought to
# behave — for the same reason `AverageCeilingMetric` refuses a reference
# population (ADR 15). The baseline is the actor's own history, which is the only
# standard it can be held to without importing someone else's.
#
# Three things it must not do, all following from the Sentinel Principle:
#
#   * It does not revoke, block or reverse anything. It reports a shift and
#     names what moved. A person decides whether the shift is a problem.
#   * It calls no model. Every figure is a count over assertions already
#     recorded, so a finding can be checked by hand.
#   * It does not treat drift as wrongdoing. A reviewer who gets better at the
#     job drifts. A policy that legitimately changed produces drift. The output
#     says what changed, never that it was wrong — the word "attack" belongs to
#     the human reading the report, not to the report.
class TemporalDriftAudit
  AUDITOR = "temporal-drift-audit".freeze

  # Below this in either period there is nothing to compare, and a divergence
  # computed over four decisions is noise wearing a number. Reported as
  # incomparable rather than as no drift — the distinction `Baseline.compare`
  # already insists on.
  MINIMUM = 20

  DEFAULT_WINDOW = 30.days

  # Total variation distance, which has a reading in plain words: the share of
  # decisions that would have to move to reconcile the two periods. 0 is
  # identical, 1 is no overlap at all.
  NOTABLE = 0.20

  Reading = Data.define(:actor, :act, :recent, :baseline, :divergence, :moved,
                        :window, :incomparable) do
    def comparable? = incomparable.nil?
    def notable? = comparable? && divergence >= NOTABLE

    # The single outcome that moved furthest. `moved` is already ordered, so this
    # inherits its tie-break rather than picking arbitrarily among equals.
    def largest_move = moved.first

    def to_s
      return "#{actor.name}: #{incomparable}" unless comparable?
      return "#{actor.name}: no material shift in #{act}" unless notable?

      outcome, delta = largest_move
      "#{actor.name}: #{(divergence * 100).round(1)}% of #{act} decisions moved — " \
        "#{outcome} #{delta.positive? ? 'up' : 'down'} #{(delta.abs * 100).round(1)} points"
    end
  end

  def self.for(referent, act: "classify", window: DEFAULT_WINDOW, now: Time.current)
    new(referent, act: act, window: window, now: now).call
  end

  # Every actor that has done enough of this act to be worth asking about.
  def self.sweep(act: "classify", window: DEFAULT_WINDOW, now: Time.current)
    Referent.where(id: Assertion.acting(act).standing.select(:asserter_id).distinct)
            .map { self.for(it, act: act, window: window, now: now) }
  end

  def initialize(referent, act:, window:, now: Time.current)
    @referent = referent
    @act = act.to_s
    @window = window
    @now = now
  end

  def call
    cutoff = now - window
    recent, earlier = assertions.partition { it.asserted_at >= cutoff }

    return incomparable(recent, earlier) if too_few?(recent, earlier)

    recent_share = share(recent)
    baseline_share = share(earlier)

    Reading.new(actor: referent, act: act, recent: counts(recent), baseline: counts(earlier),
                divergence: divergence(recent_share, baseline_share),
                moved: moves(recent_share, baseline_share), window: window, incomparable: nil)
  end

  # A shift is a claim about the actor, so it is recorded as one — and recorded
  # whether or not it is notable, because a record of only the alarming readings
  # cannot tell you the quiet ones were ever taken.
  def record!(reading = call, auditor: nil)
    Assertion.create!(
      asserter: auditor || Referent.find_by!(key: AUDITOR),
      subject: reading.actor, act: "assert",
      claim: {
        "audit" => "temporal drift", "act" => reading.act,
        "window_days" => (reading.window / 1.day).round,
        "comparable" => reading.comparable?, "incomparable" => reading.incomparable,
        "divergence" => reading.divergence, "notable" => reading.notable?,
        "recent" => reading.recent, "baseline" => reading.baseline,
        "moved" => reading.moved
      }.compact
    )
  end

  private

  attr_reader :referent, :act, :window, :now

  def assertions
    @assertions ||= Assertion.acting(act).standing.where(asserter: referent)
                             .includes(:object).chronological.to_a
  end

  def too_few?(recent, earlier) = recent.size < MINIMUM || earlier.size < MINIMUM

  def incomparable(recent, earlier)
    Reading.new(actor: referent, act: act, recent: counts(recent), baseline: counts(earlier),
                divergence: nil, moved: {}, window: window,
                incomparable: "#{recent.size} #{act} in the window and #{earlier.size} before it, " \
                              "against a minimum of #{MINIMUM} in each — too few to tell a shift " \
                              "from noise")
  end

  # What an assertion decided. A classification points at a category; an act with
  # nothing to point at is its own outcome, which is what makes accept and reject
  # comparable as dispositions.
  def outcome_for(assertion)
    object = assertion.object
    return object.key if object.respond_to?(:key) && object.key.present?
    return object.class.name.underscore if object

    assertion.act
  end

  def counts(list) = list.map { outcome_for(it) }.tally.sort.to_h

  def share(list)
    total = list.size.to_f
    counts(list).transform_values { (it / total).round(6) }
  end

  # Total variation distance between the two distributions.
  def divergence(recent, baseline)
    keys = recent.keys | baseline.keys
    (keys.sum { (recent.fetch(it, 0.0) - baseline.fetch(it, 0.0)).abs } / 2).round(4)
  end

  # Ordered by how far each outcome moved. Every rise is matched by a fall
  # somewhere, so ties are the normal case rather than the edge case: an increase
  # wins, because "what is this actor doing MORE of" is the question a reader
  # asks first. Name breaks a remaining tie, so two runs over the same data read
  # the same.
  def moves(recent, baseline)
    keys = recent.keys | baseline.keys
    keys.to_h { [ it, (recent.fetch(it, 0.0) - baseline.fetch(it, 0.0)).round(4) ] }
        .reject { |_, delta| delta.zero? }
        .sort_by { |name, delta| [ -delta.abs, -delta, name ] }.to_h
  end
end
