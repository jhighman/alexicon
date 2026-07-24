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
  before_action :require_reviewer!

  def ground
    mention = Mention.find(params[:id])
    attrs = params.require(:referent).permit(:subject, :role)

    referent = Referent.create!(
      name: mention.text,
      subject: attrs[:subject].presence,
      role: attrs[:role].presence,
      primitive: "person"
    )

    # Re-verify: the resolution supersedes the STOP, so exactly one judgement
    # stands and the derived status follows.
    IdentitySentinel.verify!(mention)

    redirect_back fallback_location: root_path,
                  notice: "#{referent.passport} — #{mention.reload.status}."
  rescue ActiveRecord::RecordInvalid => e
    redirect_back fallback_location: root_path, alert: e.message
  end

  def ignore
    mention = Mention.find(params[:id])

    IgnoredForm.find_or_create_by!(form: mention.text) do |entry|
      entry.reason = "Judged not to be a subject during review."
      entry.decided_by = current_reviewer
    end

    # The flag is set aside rather than deleted -- the record of why this was
    # ever blocked stays intact.
    mention.flags.each { it.dispose!(as: "rejected", by: current_reviewer) }

    redirect_back fallback_location: root_path,
                  notice: "#{mention.text.inspect} will not be proposed as a subject again."
  end
end
