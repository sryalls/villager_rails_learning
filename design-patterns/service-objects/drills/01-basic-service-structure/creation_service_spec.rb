# spec/services/villages/creation_service_spec.rb
RSpec.describe Villages::CreationService do
  let(:user) { create(:user) }
  let(:village_params) { { name: "Test Village" } }

  describe "#call" do
    subject { described_class.call(user, village_params) }

    it "creates a village successfully" do
      expect { subject }.to change(Village, :count).by(1)
    end

    it "returns a successful result" do
      expect(subject).to be_success
      expect(subject.village).to be_a(Village)
    end

    it "adds initial resources" do
      result = subject
      village = result.village

      expect(village.resource_amount("wood")).to eq(100)
      expect(village.resource_amount("stone")).to eq(50)
      expect(village.resource_amount("food")).to eq(25)
    end

    it "creates starting buildings" do
      result = subject
      village = result.village

      expect(village.buildings.count).to eq(1)
      expect(village.buildings.first.building_type).to eq("town_hall")
    end
  end

  describe "error handling" do
    let(:village_params) { { name: "" } } # Invalid name

    it "handles validation errors gracefully" do
      result = described_class.call(user, village_params)

      expect(result).to be_failure
      expect(result.error).to be_present
    end

    it "does not create partial data on failure" do
      expect {
        described_class.call(user, village_params)
      }.not_to change(Village, :count)
    end
  end

  describe "logging" do
    it "logs the service execution" do
      expect(Rails.logger).to receive(:info).with(/Creating village/)
      described_class.call(user, village_params)
    end
  end
end
