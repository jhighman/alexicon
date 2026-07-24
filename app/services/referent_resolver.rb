# Decides whether a mention names a grounded entity.
#
# Deliberately deterministic rather than model-backed. The resolver's whole
# purpose is to refuse to guess, and a probabilistic resolver would reintroduce
# the guess it exists to prevent. A model may later PROPOSE candidates; the
# decision to accept one stays here, where it is legible and testable.
#
# The three non-resolving outcomes map onto the framework's three detection
# criteria for Entity Noise:
#
#   :ambiguous            -- attention-map dispersion
#   :out_of_distribution  -- no match in memory
#   :unanchored           -- Cognitive Passport could not be assigned
#
class ReferentResolver
  Result = Data.define(:status, :referent, :candidates, :reason) do
    def resolved? = status == :resolved
  end

  def initialize(mention)
    @mention = mention
    @text = mention.text.to_s.strip
  end

  def call
    return blank_text if @text.empty?

    candidates = find_candidates

    return out_of_distribution if candidates.empty?
    return ambiguous(candidates, dispersion_reason(candidates)) if dispersed?(candidates)

    referent = candidates.sole
    return unanchored(referent) unless referent.anchored?

    Result.new(status: :resolved, referent: referent, candidates: candidates,
               reason: "resolved to #{referent.passport}")
  end

  private

  attr_reader :mention, :text

  # Case-insensitive match against canonical names and declared aliases.
  def find_candidates
    by_name  = Referent.where("LOWER(name) = ?", text.downcase)
    by_alias = Referent.joins(:referent_aliases).where("LOWER(referent_aliases.name) = ?", text.downcase)
    Referent.where(id: by_name.select(:id)).or(Referent.where(id: by_alias.select(:id))).distinct.to_a
  end

  # More than one candidate is dispersion. So is a single candidate reached
  # through a surface form flagged as carrying non-entity senses -- "Wednesday"
  # matching one person does not establish that this "Wednesday" is that person
  # rather than the weekday.
  def dispersed?(candidates)
    candidates.size > 1 || matched_ambiguous_alias?
  end

  def matched_ambiguous_alias?
    ReferentAlias.ambiguous.where("LOWER(name) = ?", text.downcase).exists?
  end

  def dispersion_reason(candidates)
    if candidates.size > 1
      "#{candidates.size} candidate entities match #{text.inspect}: " \
        "#{candidates.map(&:passport).join('; ')}"
    else
      "#{text.inspect} is a surface form with non-entity senses; " \
        "a single entity match does not establish the referent"
    end
  end

  def blank_text
    Result.new(status: :out_of_distribution, referent: nil, candidates: [],
               reason: "mention has no text to resolve")
  end

  def out_of_distribution
    Result.new(status: :out_of_distribution, referent: nil, candidates: [],
               reason: "#{text.inspect} matches no known entity")
  end

  def ambiguous(candidates, reason)
    Result.new(status: :ambiguous, referent: nil, candidates: candidates, reason: reason)
  end

  def unanchored(referent)
    missing = [ ("subject" if referent.subject.blank?), ("role" if referent.role.blank?) ].compact
    Result.new(status: :unanchored, referent: referent, candidates: [ referent ],
               reason: "Cognitive Passport incomplete for #{referent.name.inspect}: " \
                       "missing #{missing.join(' and ')}")
  end
end
