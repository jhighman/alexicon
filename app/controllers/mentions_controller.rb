# Answering an identity STOP.
#
# The extractor cannot tell "Ketamine" from "Alec" — both are capitalised words
# it has never seen — and no amount of structural cleverness will, because the
# difference is world knowledge. So it is asked of a person once:
#
#   ground  — this IS a subject, and here is its passport
#   ignore  — this is not a subject at all
#
# Either answer is recorded with its author, and neither is guessed.
class MentionsController < ApplicationController
  def ground
    mention = Mention.find(params[:id])
    authorize mention
    attrs = params.require(:referent).permit(:subject, :role, :same_as_id)

    if attrs[:same_as_id].blank? && (attrs[:subject].blank? || attrs[:role].blank?)
      return redirect_back fallback_location: root_path,
                           alert: "A passport needs a subject and a role — a partial one is no anchor. " \
                                  "Or say which subject this is another name for."
    end

    referent = attrs[:same_as_id].present? ? alias_to(mention, attrs[:same_as_id]) : new_referent(mention, attrs)

    # Re-verify: the resolution supersedes the STOP, so exactly one judgement
    # stands and the derived status follows.
    #
    # Every occurrence of the name, not just the one clicked. "Polanyi" appearing
    # three times is one identity question, and answering it three times is the
    # same answer typed twice more.
    resolved = same_name_as(mention).each { IdentitySentinel.verify!(it) }

    redirect_back fallback_location: root_path,
                  notice: "#{referent.passport} — #{mention.reload.status} " \
                          "(#{helpers.pluralize(resolved.size, 'occurrence')})."
  rescue ActiveRecord::RecordInvalid => e
    redirect_back fallback_location: root_path, alert: e.message
  end

  def ignore
    mention = Mention.find(params[:id])
    authorize mention

    IgnoredForm.find_or_create_by!(form: mention.text) do |entry|
      entry.reason = "Judged not to be a subject during review."
      entry.decided_by = current_reviewer
    end

    # The flag is set aside rather than deleted -- the record of why this was
    # ever blocked stays intact. Every occurrence, because IgnoredForm is about
    # the form: leaving the other six "Every" mentions blocking would contradict
    # the judgement just recorded.
    ignored = same_name_as(mention).each do |sibling|
      sibling.flags.select(&:open?).each { it.dispose!(as: "rejected", by: current_reviewer) }
    end

    redirect_back fallback_location: root_path,
                  notice: "#{mention.text.inspect} will not be proposed as a subject again " \
                          "(#{helpers.pluralize(ignored.size, 'occurrence')} cleared)."
  end

  private

  # Two spellings, one philosopher. "Polayani" is a typo for "Polanyi", and
  # grounding it separately would create a second person who wrote the same
  # book — object constancy broken by a transposed letter.
  #
  # The alias is recorded rather than the mention being edited: the document
  # said what it said, and correcting the text would destroy the evidence that
  # the misspelling was ever there.
  def alias_to(mention, referent_id)
    referent = Referent.find(referent_id)

    ReferentAlias.find_or_create_by!(referent: referent, name: mention.text) do |entry|
      entry.source = "Judged during review to be another name for #{referent.name}."
    end

    referent
  end

  def new_referent(mention, attrs)
    Referent.create!(name: mention.text, subject: attrs[:subject].presence,
                     role: attrs[:role].presence, primitive: "person")
  end

  # A judgement about a name applies wherever that name appears. Scoped to the
  # exact surface form, since that is what was actually judged.
  def same_name_as(mention) = Mention.where(text: mention.text).to_a
end
