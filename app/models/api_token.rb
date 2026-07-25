# A credential that acts as a Referent.
#
# Deliberately NOT `belongs_to :user`. A token authenticates something that
# acts, and what acts must attribute its judgements to itself. An agent holding
# a person's session would leave a record saying that person decided, which is
# inference wearing evidence's costume — the exact failure this system exists
# to catch, and the easiest one to introduce through an API.
#
# So the rule is one line and has no exceptions: whatever the token's role, its
# assertions carry its own referent, and `human?` is a fact about that referent
# rather than about the credential.
class ApiToken < ApplicationRecord
  include Capabilities

  PREFIX = "alx".freeze
  ROLES = Capabilities::ROLES

  belongs_to :referent
  belongs_to :issued_by, class_name: "Referent", optional: true

  validates :name, presence: true
  validates :role, inclusion: { in: ROLES }
  validates :token_digest, presence: true, uniqueness: true

  scope :live, -> { where(revoked_at: nil) }

  # Returned once, at issue. The plaintext is never stored and cannot be
  # recovered — a token that can be read back out of the database is a
  # credential sitting in the record, which is what the audit trail is not for.
  attr_reader :plaintext

  def self.issue!(referent:, name:, role: "viewer", issued_by: nil, expires_at: nil)
    secret = "#{PREFIX}_#{SecureRandom.urlsafe_base64(32)}"

    token = create!(referent: referent, name: name, role: role, issued_by: issued_by,
                    expires_at: expires_at, token_digest: digest(secret),
                    hint: "…#{secret.last(4)}")
    token.instance_variable_set(:@plaintext, secret)
    token
  end

  # Constant-time lookup by digest, so a wrong token takes the same work as a
  # right one and cannot be probed by timing.
  def self.authenticate(secret)
    return nil if secret.blank?

    token = live.find_by(token_digest: digest(secret))
    return nil if token.nil? || token.expired?

    token.touch(:last_used_at)
    token
  end

  def self.digest(secret) = OpenSSL::Digest::SHA256.hexdigest(secret.to_s)

  def expired? = expires_at.present? && expires_at.past?
  def revoked? = revoked_at.present?

  def revoke!(reason: nil)
    update!(revoked_at: Time.current, revocation_reason: reason)
  end

  # Whether this token may make a review judgement of this kind.
  #
  # Two conditions, and both must hold. The role says what this credential is
  # for at all; the delegation says whether a judgement of this kind may be made
  # without a person present. A person's token needs no delegation — they are
  # the person the gate was asking for.
  def may_judge?(act)
    return false unless can_review? || can_certify_models?
    return true if human?

    Delegation.permits?(referent: referent, act: act)
  end

  def to_s = "#{name} (#{hint})"
end
