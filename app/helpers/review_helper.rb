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
    when Transition  then "the step from claim #{flag.subject.from_claim&.position} to #{flag.subject.to_claim&.position}"
    when Relationship then "a relationship"
    else "this document"
    end
  end

  def document_state(document)
    if document.open_stops.any?
      [ "Locked", "danger", "Identity was never established for #{document.blocking_mentions.count} name(s). " \
                            "Nothing can be classified until someone answers." ]
    elsif document.flags.select(&:open?).any?
      [ "Open concerns", "warning", "Nothing is blocked, but some steps are flagged as outrunning their justification." ]
    else
      [ "Clear", "success", "No flag is waiting on anyone." ]
    end
  end
end
