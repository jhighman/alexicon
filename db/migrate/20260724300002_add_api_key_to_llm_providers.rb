# A credential an admin can set from the browser, encrypted at rest.
#
# Deliberately NOT deterministic: nothing needs to query by key, and a
# deterministic ciphertext would let anyone with read access to the table
# confirm a guessed key by comparing ciphertexts.
#
# Who set it and when are recorded; the value itself never appears in an
# assertion, an invocation, or a log line.
class AddApiKeyToLlmProviders < ActiveRecord::Migration[8.1]
  def change
    add_column :llm_providers, :api_key, :text
    add_column :llm_providers, :api_key_set_at, :datetime
    add_reference :llm_providers, :api_key_set_by, foreign_key: { to_table: :referents }
  end
end
