module ReviewHelper
  CATEGORY_STYLES = {
    "objective" => "text-bg-primary",
    "observation" => "text-bg-info",
    "interpretive" => "text-bg-warning",
    "ontological" => "text-bg-danger"
  }.freeze

  def category_badge(category)
    return tag.span("unclassified", class: "badge text-bg-light border") if category.nil?

    tag.span(category.name, class: "badge #{CATEGORY_STYLES.fetch(category.key, 'text-bg-secondary')}",
                            title: category.definition)
  end

  def verdict_badge(verdict)
    style = { "earned" => "text-bg-success", "unearned" => "text-bg-danger" }
             .fetch(verdict, "text-bg-light border")
    tag.span(verdict, class: "badge #{style}")
  end

  def severity_badge(flag)
    style = flag.stop? ? "text-bg-danger" : "text-bg-warning"
    tag.span(flag.severity, class: "badge #{style}")
  end

  def mention_status_badge(mention)
    style = mention.anchored? ? "text-bg-success" : "text-bg-danger"
    tag.span(mention.status.tr("_", " "), class: "badge #{style}")
  end

  # What a flag is about, in the reader's terms rather than the schema's.
  def flag_subject_label(flag)
    case flag.subject
    when Mention     then "the name #{flag.subject.text.inspect}"
    when Claim       then "claim #{flag.subject.position}"
    when Transition  then "the step from claim #{flag.subject.from_claim&.position} to #{flag.subject.to_claim&.position}"
    when Relationship then "a relationship"
    when Document    then "this document as a whole"
    else "this document"
    end
  end

  # An abstention is not a failed classification; it is the classifier declining
  # to guess. The live report should not blur the two.
  def outcome_verb(outcome)
    { "classified" => "Classified", "abstained" => "Abstained on",
      "skipped" => "Already classified" }.fetch(outcome.to_s, "Reading")
  end

  # Shading carries the claim's kind, not its worth. The categories differ in
  # kind rather than rank, so no colour is "good" — red marks where a step was
  # judged unearned, which is a finding about the move, not about the sentence.
  def reading_tone(claim, findings)
    return "tone-structure" if claim.structural?

    tone = "tone-#{claim.category&.key || 'none'}"
    findings.any?(&:unearned?) ? "#{tone} flagged" : tone
  end

  def document_state(document)
    if document.open_stops.any?
      [ "Identity unresolved", "danger",
        "#{document.blocking_mentions.count} name(s) have no established reference. Claims can still " \
        "be classified — typing a statement does not predicate anything of the names inside it — but " \
        "no step between claims can be judged until someone answers." ]
    elsif document.flags.select(&:open?).any?
      [ "Open concerns", "warning", "Nothing is blocked, but some steps are flagged as outrunning their justification." ]
    else
      [ "Clear", "success", "No flag is waiting on anyone." ]
    end
  end
end
