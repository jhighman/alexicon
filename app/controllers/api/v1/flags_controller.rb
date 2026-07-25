# Answering a flag: letting it stand, or setting it aside.
#
# A disposition never decides whether a claim is true. It records that someone
# looked and either accepted the flag or rejected it, written as a further
# assertion ABOUT the flag — the flag itself is never altered.
class Api::V1::FlagsController < Api::V1::BaseController
  DISPOSITIONS = %w[accepted rejected].freeze

  def index
    authorize Assertion, :index?, policy_class: FlagPolicy
    document = Document.find(params[:document_id])

    render json: { document_id: document.id,
                   flags: document.flags.select(&:open?).map { serialise(it) } }
  end

  def update
    flag = Assertion.flags.find(params[:id])
    authorize flag, :update?, policy_class: FlagPolicy
    require_delegation!("dispose_flag")

    disposition = params.require(:disposition).to_s
    return unprocessable("disposition must be one of #{DISPOSITIONS.join(', ')}") unless
      DISPOSITIONS.include?(disposition)

    flag.dispose!(as: disposition, by: current_reviewer)

    render json: { flag_id: flag.id, disposition: flag.reload.disposition,
                   decided_by: current_reviewer.name, inferred: !current_token.human? }
  end

  private

  def serialise(flag)
    { id: flag.id, severity: flag.severity, message: flag.message,
      raised_by: flag.asserter.name, about: flag.subject_type,
      subject_id: flag.subject_id, disposition: flag.disposition }
  end
end
