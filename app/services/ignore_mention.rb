# Answering an identity STOP the other way: this is not a subject at all.
#
# The form is remembered globally, so the extractor stops proposing it, and the
# flags it raised are set ASIDE rather than deleted — the record of why this was
# ever blocked stays intact.
class IgnoreMention
  Result = Data.define(:form, :cleared) do
    def occurrences = cleared.size
  end

  def self.call(mention, by:) = new(mention, by: by).call

  def initialize(mention, by:)
    @mention = mention
    @by = by
  end

  def call
    IgnoredForm.find_or_create_by!(form: mention.text) do |entry|
      entry.reason = "Judged not to be a subject during review."
      entry.decided_by = by
    end

    # Every occurrence, because IgnoredForm is about the form: leaving the other
    # six "Every" mentions blocking would contradict the judgement just made.
    cleared = Mention.where(text: mention.text).to_a
    cleared.each { |sibling| sibling.flags.select(&:open?).each { it.dispose!(as: "rejected", by: by) } }

    Result.new(form: mention.text, cleared: cleared)
  end

  private

  attr_reader :mention, :by
end
