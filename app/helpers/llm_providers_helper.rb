module LlmProvidersHelper
  def key_placeholder(provider)
    case provider.credential_source
    when "stored" then "unchanged"
    when "environment" then "using #{provider.credential_env}"
    else "sk-…"
    end
  end

  # Which key would actually be used, and where it came from. An admin who has
  # set one and an admin who has exported one should be able to tell them apart
  # at a glance, because they fail and rotate differently.
  def credential_badge(provider)
    case provider.credential_source
    when "stored"
      tag.span("stored", class: "badge text-bg-success")
    when "environment"
      tag.span("environment", class: "badge text-bg-info")
    else
      tag.span("none", class: "badge text-bg-warning")
    end
  end
end
