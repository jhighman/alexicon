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
#
# The judgements themselves live in GroundMention and IgnoreMention, so this
# controller and the API drive one implementation rather than two that drift.
class MentionsController < ApplicationController
  def ground
    mention = Mention.find(params[:id])
    authorize mention
    attrs = params.require(:referent).permit(:subject, :role, :same_as_id)

    result = GroundMention.call(mention, by: current_reviewer, subject: attrs[:subject],
                                         role: attrs[:role], same_as: attrs[:same_as_id].presence)

    redirect_back fallback_location: root_path,
                  notice: "#{result.referent.passport} — #{result.mention.status} " \
                          "(#{helpers.pluralize(result.occurrences, 'occurrence')})."
  rescue GroundMention::IncompletePassport
    redirect_back fallback_location: root_path,
                  alert: "A passport needs a subject and a role — a partial one is no anchor. " \
                         "Or say which subject this is another name for."
  rescue ActiveRecord::RecordInvalid => e
    redirect_back fallback_location: root_path, alert: e.message
  end

  def ignore
    mention = Mention.find(params[:id])
    authorize mention

    result = IgnoreMention.call(mention, by: current_reviewer)

    redirect_back fallback_location: root_path,
                  notice: "#{result.form.inspect} will not be proposed as a subject again " \
                          "(#{helpers.pluralize(result.occurrences, 'occurrence')} cleared)."
  end
end
