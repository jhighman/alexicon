class DomainPolicy < ApplicationRecord
  belongs_to :policy
  belongs_to :domain

  validates :policy_id, uniqueness: { scope: :domain_id }
end
