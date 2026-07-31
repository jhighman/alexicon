# Who may act, and as whom.
#
# Roles are deliberately few. A long role list tends to encode job titles
# rather than capabilities, and then every policy has to know the titles.
# Policies here ask capability questions instead — `can_review?`, not
# `role == "reviewer"` — so changing who may do what is one edit in one file.
class User < ApplicationRecord
  include Capabilities

  ROLES = Capabilities::ROLES

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
  #
  # The role is self-asserted — "Jeff says Jeff is Admin" — which is
  # attributable and honest: at registration there is nobody else in the room
  # to say it. The referent must exist before it can assert anything, so the
  # two steps share a transaction.
  def self.register!(username:, password:, role: "viewer", name: nil)
    referent = Referent.transaction do
      Referent.create!(name: name.presence || username,
                       subject: "Person", primitive: "person")
              .tap { it.assert_role!(role.titleize, by: it, rationale: "self-asserted at registration") }
    end
    create!(username: username, password: password, role: role, referent: referent)
  end

  def to_s = username
end
