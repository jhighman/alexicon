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
class EntityResolver
  Result = Data.define(:status, :entity, :candidates, :reason) do
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

    entity = candidates.sole
    return unanchored(entity) unless entity.anchored?

    Result.new(status: :resolved, entity: entity, candidates: candidates,
               reason: "resolved to #{entity.passport}")
  end

  private

  attr_reader :mention, :text

  # Case-insensitive match against canonical names and declared aliases.
  def find_candidates
    by_name  = Entity.where("LOWER(name) = ?", text.downcase)
    by_alias = Entity.joins(:entity_aliases).where("LOWER(entity_aliases.name) = ?", text.downcase)
    Entity.where(id: by_name.select(:id)).or(Entity.where(id: by_alias.select(:id))).distinct.to_a
  end

  # More than one candidate is dispersion. So is a single candidate reached
  # through a surface form flagged as carrying non-entity senses -- "Wednesday"
  # matching one person does not establish that this "Wednesday" is that person
  # rather than the weekday.
  def dispersed?(candidates)
    candidates.size > 1 || matched_ambiguous_alias?
  end

  def matched_ambiguous_alias?
    EntityAlias.ambiguous.where("LOWER(name) = ?", text.downcase).exists?
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
    Result.new(status: :out_of_distribution, entity: nil, candidates: [],
               reason: "mention has no text to resolve")
  end

  def out_of_distribution
    Result.new(status: :out_of_distribution, entity: nil, candidates: [],
               reason: "#{text.inspect} matches no known entity")
  end

  def ambiguous(candidates, reason)
    Result.new(status: :ambiguous, entity: nil, candidates: candidates, reason: reason)
  end

  def unanchored(entity)
    missing = [ ("category" if entity.category.blank?), ("role" if entity.role.blank?) ].compact
    Result.new(status: :unanchored, entity: entity, candidates: [ entity ],
               reason: "Cognitive Passport incomplete for #{entity.name.inspect}: " \
                       "missing #{missing.join(' and ')}")
  end
end
