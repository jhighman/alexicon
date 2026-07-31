# Answering an identity STOP: this IS a subject, and here is its passport — or
# it is another name for a subject already grounded.
#
# Extracted so the browser and the API drive one implementation. Two paths to
# the same judgement drift, and the one that drifts is always the one nobody is
# looking at.
class GroundMention
  Result = Data.define(:referent, :mention, :resolved) do
    def occurrences = resolved.size
  end

  class IncompletePassport < StandardError; end

  def self.call(mention, by:, **) = new(mention, by: by, **).call

  # `same_as` grounds this name as another spelling of an existing referent.
  # Otherwise a passport is required, and both levels of it: a partial passport
  # is not a weaker anchor, it is no anchor.
  #
  # `person:` is its own question, defaulting to no (ADR 22). Personhood
  # allocates authority — whose reading settles a claim, who may grant a
  # delegation — so it is never inferred from what somebody typed into the
  # subject field. Grounding a person is a deliberate act the grounder
  # knowingly performs, and the grounding's attribution records who performed
  # it.
  def initialize(mention, by:, subject: nil, role: nil, same_as: nil, person: false)
    @mention = mention
    @by = by
    @subject = subject.presence
    @role = role.presence
    @same_as = same_as
    @person = person
  end

  def call
    referent = same_as ? alias_to_existing : create_referent

    # Every occurrence of the name, not just the one asked about: answering the
    # same question once per occurrence is the same answer typed again.
    resolved = Mention.where(text: mention.text).to_a
    # Attributed to whoever decided, not to the Sentinel that checked them. Every
    # occurrence carries the same attribution because they are all consequences
    # of the one decision.
    resolved.each { IdentitySentinel.verify!(it, by: by) }

    Result.new(referent: referent, mention: mention.reload, resolved: resolved)
  end

  private

  attr_reader :mention, :by, :subject, :role, :same_as, :person

  # Two spellings, one philosopher. Grounding "Polayani" separately would create
  # a second person who wrote the same book. The alias is recorded rather than
  # the mention corrected: the document said what it said.
  def alias_to_existing
    referent = same_as.is_a?(Referent) ? same_as : Referent.find(same_as)

    ReferentAlias.find_or_create_by!(referent: referent, name: mention.text) do |entry|
      entry.source = "Judged to be another name for #{referent.name} by #{by.name}."
    end

    referent
  end

  def create_referent
    raise IncompletePassport, "a passport needs a subject and a role" if subject.nil? || role.nil?

    # The role is an assertion attributed to whoever answered the STOP, in the
    # same transaction that creates the referent — the column stays empty, per
    # ADR 21. Attribution reaches the role the same way ADR 19 made it reach
    # the resolution: the record says who decided, not which service ran.
    Referent.transaction do
      Referent.create!(name: mention.text, subject: subject,
                       primitive: person ? "person" : "entity",
                       notes: "Grounded during review by #{by.name}.")
              .tap { it.assert_role!(role, by: by) }
    end
  end
end
