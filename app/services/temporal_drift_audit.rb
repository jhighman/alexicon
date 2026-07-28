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
  #
  # This floor alone was not enough, and the way it failed is worth keeping.
  # Total variation distance between two finite samples is never zero even when
  # nothing has changed, and how far from zero depends on how many decisions
  # there were. At twenty decisions a side — the minimum this class declares
  # sufficient — two samples drawn from an IDENTICAL distribution exceed 0.20
  # about 62% of the time, with a median of 0.25. A fixed threshold meant the
  # audit reported drift on noise, most of the time, at its own minimum.
  #
  # The diagnosis came from Alexandra Krížová's sentinel-attention sketch, where
  # a fixed additive logit bias competes against however many tokens there
  # happen to be and so means something different at every sequence length. The
  # same error, in the same shape, was already here.
  NOTABLE = 0.20

  # What noise alone produces, in closed form rather than by sampling:
  #
  #   E[TV] = ½ · √(2/π) · √(1/n₁ + 1/n₂) · Σᵢ √(pᵢ(1 - pᵢ))
  #
  # Each per-category difference is approximately normal with variance
  # p(1-p)(1/n₁ + 1/n₂), and the mean absolute value of a centred normal is
  # σ√(2/π). Checked against 4,000 simulated pairs per sample size: predicted
  # 0.240 against an observed median of 0.250 at n=20, and 0.034 against 0.032
  # at n=1000.
  #
  # The multiple puts the bar near the 95th percentile of that noise. The ratio
  # of simulated p95 to predicted mean held at 1.67 across every size tried,
  # which is what makes a single constant defensible here.
  NOISE_MULTIPLE = 1.67

  Reading = Data.define(:actor, :act, :recent, :baseline, :divergence, :moved,
                        :window, :incomparable, :noise_ceiling) do
    def comparable? = incomparable.nil?

    # What this reading had to clear. A small sample sets its own bar, so a
    # figure is never called notable for being smaller than its own noise.
    def threshold = [ NOTABLE, noise_ceiling.to_f ].max

    def notable? = comparable? && divergence >= threshold

    # Whether the sample, not the policy, is what the figure had to beat. Worth
    # surfacing: it means a real shift below this size would not have shown.
    def noise_bound? = comparable? && noise_ceiling.to_f > NOTABLE

    # The single outcome that moved furthest. `moved` is already ordered, so this
    # inherits its tie-break rather than picking arbitrarily among equals.
    def largest_move = moved.first

    def to_s
      return "#{actor.name}: #{incomparable}" unless comparable?
      unless notable?
        floor = noise_bound? ? " (needed #{(threshold * 100).round(1)}% at this sample size)" : ""
        return "#{actor.name}: no material shift in #{act}#{floor}"
      end

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
                moved: moves(recent_share, baseline_share), window: window, incomparable: nil,
                noise_ceiling: noise_ceiling(recent_share, baseline_share, recent.size, earlier.size))
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
        "threshold" => (reading.threshold if reading.comparable?),
        "noise_ceiling" => reading.noise_ceiling,
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
                divergence: nil, moved: {}, window: window, noise_ceiling: nil,
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

  # What two samples this size would differ by even if nothing had changed.
  # Closed form rather than a bootstrap: the audit calls no model and should not
  # need to call a random number generator either, or two runs over the same
  # record would disagree about whether a figure was notable.
  def noise_ceiling(recent, baseline, recent_n, earlier_n)
    return nil if recent_n.zero? || earlier_n.zero?

    pooled = (recent.keys | baseline.keys).to_h do |key|
      total = (recent.fetch(key, 0.0) * recent_n) + (baseline.fetch(key, 0.0) * earlier_n)
      [ key, total / (recent_n + earlier_n) ]
    end

    spread = pooled.values.sum { Math.sqrt(it * (1 - it)) }
    expected = 0.5 * Math.sqrt(2 / Math::PI) * Math.sqrt((1.0 / recent_n) + (1.0 / earlier_n)) * spread

    (NOISE_MULTIPLE * expected).round(4)
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
