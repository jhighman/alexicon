# A measurement of a model, recorded so a later one can be compared to it.
#
# Everything else here insists that a judgement be attributable and
# challengeable. A measurement OF the system had no such home: three real
# findings about a model existed only in a conversation and in invocation rows
# that said a call happened without saying what it showed.
#
# So a measurement is an assertion about the LlmModel, like any other claim about
# any other subject. It can be superseded by a better measurement rather than
# overwritten, and two baselines can be compared because both are still there.
#
# What is stored is deliberately more than the number. A rate without its sample
# and its conditions cannot be compared to anything — the second reading would
# differ and nobody could say whether the model changed, the code changed, or
# the question did. So the conditions and the code revision are part of the
# claim, and where detail was not retained the record says so rather than
# implying completeness.
class Baseline
  RECORDER = "baseline-recorder".freeze

  Measurement = Data.define(:assertion) do
    def criterion = assertion.claim["criterion"]
    def version   = assertion.claim["baseline"]
    def rate      = assertion.claim.dig("measured", "rate")&.to_f
    def measured  = assertion.claim["measured"] || {}
    def sample    = assertion.claim["sample"] || {}
    def conditions = assertion.claim["conditions"] || {}
    def detail    = assertion.claim["detail"]
    def code_sha  = assertion.claim.dig("code", "sha")
    def caveats   = assertion.claim["caveats"]
    def model     = assertion.subject
    def recorded_at = assertion.asserted_at

    def to_s = "#{criterion}: #{rate ? "#{(rate * 100).round(1)}%" : 'n/a'}"
  end

  def self.recorder = Referent.find_by!(key: RECORDER)

  # `caveats` is not decoration. A baseline whose limits are not written down
  # gets compared to things it cannot be compared to.
  def self.record!(version:, criterion:, model:, measured:, sample:, conditions:,
                   detail: nil, caveats: nil, code_sha: nil)
    Measurement.new(assertion: Assertion.create!(
      asserter: recorder, subject: model, act: "assert",
      claim: {
        "baseline" => version.to_s,
        "criterion" => criterion,
        "measured" => measured.deep_stringify_keys,
        "sample" => sample.deep_stringify_keys,
        "conditions" => conditions.deep_stringify_keys,
        "detail" => detail,
        "caveats" => caveats,
        "code" => { "sha" => code_sha || current_sha }
      }.compact
    ))
  end

  # Standing measurements only: a superseded one is kept but is no longer what
  # the baseline says.
  def self.for(version:, model: nil)
    scope = Assertion.where(asserter: recorder).acting("assert").standing.chronological
    scope = scope.where(subject: model) if model
    scope.select { it.claim["baseline"] == version.to_s }.map { Measurement.new(assertion: it) }
  end

  def self.criteria(version:, model: nil) = self.for(version: version, model: model).map(&:criterion)

  # Two baselines side by side, matched on criterion. A criterion present in one
  # and absent from the other is reported as such rather than dropped — a
  # measurement that was not repeated is not a measurement that agreed.
  def self.compare(from:, to:, model: nil)
    before = self.for(version: from, model: model).index_by(&:criterion)
    after  = self.for(version: to, model: model).index_by(&:criterion)

    (before.keys | after.keys).sort.map do |criterion|
      a = before[criterion]
      b = after[criterion]
      { criterion: criterion,
        from: a&.rate, to: b&.rate,
        delta: (a&.rate && b&.rate) ? (b.rate - a.rate).round(4) : nil,
        comparable: comparable?(a, b),
        note: note_for(a, b) }
    end
  end

  # Same conditions or the numbers are not answering the same question.
  def self.comparable?(before, after)
    return false if before.nil? || after.nil?

    before.conditions == after.conditions
  end

  def self.note_for(before, after)
    return "not measured in #{before ? 'the later' : 'the earlier'} baseline" if before.nil? || after.nil?
    return "conditions differ — #{differing(before, after).join(', ')}" unless comparable?(before, after)

    nil
  end

  def self.differing(before, after)
    (before.conditions.keys | after.conditions.keys)
      .reject { before.conditions[it] == after.conditions[it] }
  end

  # The code that produced the measurement is part of it. Without this, a
  # changed rate cannot be told apart from a changed instrument.
  def self.current_sha
    return nil unless File.directory?(Rails.root.join(".git"))

    sha = `git -C #{Rails.root} rev-parse --short HEAD 2>/dev/null`.strip
    dirty = `git -C #{Rails.root} status --porcelain 2>/dev/null`.strip.present?
    sha.presence && (dirty ? "#{sha}-dirty" : sha)
  rescue StandardError
    nil
  end
end
