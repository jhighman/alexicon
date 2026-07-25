require "rails_helper"

# A run that stops must say so. The worst outcome is a progress bar that
# animates forever because the failure path forgot to speak.
RSpec.describe ClassifyDocumentJob do
  before { seed_quietly }

  let(:document) { Document.create!(body: "The wall fell.") }

  def broadcasts
    @broadcasts ||= []
  end

  before do
    document.claims.create!(position: 1, text: "The wall fell.")

    allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to) do |*, **kwargs|
      broadcasts << kwargs.dig(:locals, :status)
    end
    allow(Turbo::StreamsChannel).to receive(:broadcast_refresh_to)
  end

  it "announces the run, then refreshes the page from the record" do
    allow(DocumentClassification).to receive(:call)

    described_class.perform_now(document)

    expect(broadcasts).to include "running"
    expect(Turbo::StreamsChannel).to have_received(:broadcast_refresh_to)
  end

  it "says why it stopped when no key is configured" do
    allow(DocumentClassification).to receive(:call)
      .and_raise(ClaimClassifier::MissingCredentials, "no key")

    described_class.perform_now(document)

    expect(broadcasts.last).to eq "failed"
    expect(Turbo::StreamsChannel).not_to have_received(:broadcast_refresh_to)
  end

  it "says why it stopped when nothing is routed to the classifier" do
    allow(DocumentClassification).to receive(:call)
      .and_raise(ClaimClassifier::NoGovernedModel, "no assignment matches")

    described_class.perform_now(document)

    expect(broadcasts.last).to eq "failed"
  end

  it "reports an unexpected failure rather than going quiet" do
    allow(DocumentClassification).to receive(:call).and_raise(IOError, "connection reset")

    expect { described_class.perform_now(document) }.to raise_error(IOError)

    expect(broadcasts.last).to eq "failed"
  end
end
