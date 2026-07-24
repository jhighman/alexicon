# Be sure to restart your server when you modify this file.

# "Evidence" is uncountable. Without this, Rails names the table `evidences`,
# which is not a word anyone uses about evidence.
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.uncountable "evidence"
end

# So app/services/llm_clients/open_ai.rb defines LlmClients::OpenAI rather than
# LlmClients::OpenAi. Scoped to the autoloader rather than a global acronym,
# which would rewrite every other "_ai" segment too.
Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect("open_ai" => "OpenAI")
end
