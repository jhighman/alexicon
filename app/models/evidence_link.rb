# Binds a piece of evidence to an assertion it supports. `note` records HOW
# the evidence bears on the claim, which is often the part a later reviewer
# needs and the part nobody writes down.
class EvidenceLink < ApplicationRecord
  belongs_to :assertion
  belongs_to :evidence

  validates :assertion_id, uniqueness: { scope: :evidence_id }
end
