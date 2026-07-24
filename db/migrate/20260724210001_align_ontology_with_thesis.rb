# The thesis reserves "Entity" for institutional actors -- organisations,
# corporations, governments -- explicitly distinct from Person. Our model held
# whatever a mention resolves to, which is usually a person.
#
# Renamed to Referent: the thing a mention refers to, whatever primitive it
# turns out to be. `primitive` records which of the thesis's four actor types
# it is, and is nullable because the G3/G7 material does not specify it.
#
# Relationship, the fifth primitive, is deliberately not modelled yet.
class AlignOntologyWithThesis < ActiveRecord::Migration[8.1]
  def change
    rename_table :entities, :referents
    rename_table :entity_aliases, :referent_aliases
    rename_column :referent_aliases, :entity_id, :referent_id
    rename_column :resolutions, :entity_id, :referent_id

    # person | entity | system | process -- the thesis's four actor primitives.
    add_column :referents, :primitive, :string
    add_index  :referents, :primitive
  end
end
