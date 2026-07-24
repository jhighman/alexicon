# Who may act, and as whom.
#
# Roles are deliberately few. A long role list tends to encode job titles
# rather than capabilities, and then every policy has to know the titles.
# Policies here ask capability questions instead — `can_review?`, not
# `role == "reviewer"` — so changing who may do what is one edit in one file.
class User < ApplicationRecord
  ROLES = %w[admin auditor reviewer viewer].freeze

  has_secure_password

  # The graph identity this person acts as. Assertions attribute to the
  # Referent, never to the User: authorisation is a different question from
  # provenance, and conflating them would put credentials in the audit trail.
  belongs_to :referent

  validates :username, presence: true, uniqueness: { case_sensitive: false }
  validates :role, inclusion: { in: ROLES }

  normalizes :username, with: ->(name) { name.to_s.strip.downcase }

  scope :with_role, ->(role) { where(role: role) }

  # Creates the person in the graph alongside the account, so a user always
  # has somewhere to attribute their judgements.
  def self.register!(username:, password:, role: "viewer", name: nil)
    referent = Referent.create!(name: name.presence || username,
                               subject: "Person", role: role.titleize, primitive: "person")
    create!(username: username, password: password, role: role, referent: referent)
  end

  def admin?    = role == "admin"
  def auditor?  = role == "auditor"
  def reviewer? = role == "reviewer"

  # --- Capabilities ---------------------------------------------------------
  #
  # Policies call these. Roles compose into them here and nowhere else.

  # Reading the work: documents, claims, flags.
  def can_view? = true

  # Answering a flag, grounding a name, marking a form as not a subject.
  # These write accountable judgements into the graph.
  def can_review? = admin? || reviewer?

  # Submitting new text for analysis, and running the analysis.
  def can_ingest? = admin? || reviewer?

  # Seeing which models exist, what they cost, and what they were asked.
  def can_view_llm_registry? = admin? || auditor?

  # Deciding that a model may influence judgements at all.
  def can_certify_models? = admin?

  def to_s = username
end
