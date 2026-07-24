# What a domain protects against -- the "Protects" branch of the concept map.
class DomainFailureMode < ApplicationRecord
  belongs_to :domain

  validates :name, presence: true
end
