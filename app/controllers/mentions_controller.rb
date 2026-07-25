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
    attrs = params.require(:referent).permit(:subject, :role)

    referent = Referent.create!(
      name: mention.text,
      subject: attrs[:subject].presence,
      role: attrs[:role].presence,
      primitive: "person"
    )

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

  # A judgement about a name applies wherever that name appears. Scoped to the
  # exact surface form, since that is what was actually judged.
  def same_name_as(mention) = Mention.where(text: mention.text).to_a
end
