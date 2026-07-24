class DomainComponent < ApplicationRecord
  belongs_to :domain

  validates :name, presence: true
  validates :position, numericality: { only_integer: true, greater_than: 0 }
end
