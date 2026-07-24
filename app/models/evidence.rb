# Something that supports an assertion without being identical to it.
#
# The distinction is load-bearing. One document may support many assertions;
# one assertion may rest on many forms of evidence. Collapsing evidence into
# the assertion would lose both relationships and make provenance untraceable.
class Evidence < ApplicationRecord
  KINDS = %w[document observation measurement prior_assertion process cryptographic_proof].freeze

  has_many :evidence_links, dependent: :destroy
  has_many :assertions, through: :evidence_links

  validates :kind, inclusion: { in: KINDS }

  scope :of_kind, ->(kind) { where(kind: kind) }
end
