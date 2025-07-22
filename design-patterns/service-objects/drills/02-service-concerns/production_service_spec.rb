RSpec.describe Resources::ProductionService do
  let(:village_building) { create(:village_building, :with_house) }

  describe "tracking" do
    it "logs service execution" do
      expect(Rails.logger).to receive(:info).with(/Started/)
      expect(Rails.logger).to receive(:info).with(/Completed/)

      described_class.call(village_building)
    end

    it "includes execution time in logs" do
      expect(Rails.logger).to receive(:info).with(/Started Resources::ProductionService/)
      expect(Rails.logger).to receive(:info).with(/Completed Resources::ProductionService.*\d+ms/)

      described_class.call(village_building)
    end

    it "logs success/failure status" do
      expect(Rails.logger).to receive(:info).with(/Started/)
      expect(Rails.logger).to receive(:info).with(/Completed.*success: true/)

      described_class.call(village_building)
    end
  end

  describe "caching" do
    it "caches results" do
      service = described_class.new(village_building)

      # First call should hit the service
      expect(service).to receive(:perform_production).once.and_call_original
      result1 = service.call

      # Second call should use cache
      expect(service).not_to receive(:perform_production)
      result2 = service.call

      expect(result1.resources).to eq(result2.resources)
    end

    it "generates unique cache keys for different buildings" do
      building1 = create(:village_building, :with_house)
      building2 = create(:village_building, :with_farm)

      service1 = described_class.new(building1)
      service2 = described_class.new(building2)

      # Both should be called since they have different cache keys
      expect_any_instance_of(described_class).to receive(:perform_production).twice.and_call_original

      result1 = service1.call
      result2 = service2.call

      expect(result1.resources).not_to eq(result2.resources)
    end

    it "respects cache expiration" do
      service = described_class.new(village_building)

      # First call
      result1 = service.call

      # Simulate cache expiration
      Rails.cache.clear

      # Should call service again after cache clear
      expect(service).to receive(:perform_production).once.and_call_original
      result2 = service.call

      expect(result1.resources).to eq(result2.resources)
    end
  end

  describe "service functionality" do
    it "produces resources based on building type" do
      result = described_class.call(village_building)

      expect(result).to be_success
      expect(result.resources).to be_a(Hash)
      expect(result.resources.keys).to include("wood", "stone", "food")
    end

    it "calculates production based on building level" do
      low_level_building = create(:village_building, :with_house, level: 1)
      high_level_building = create(:village_building, :with_house, level: 3)

      low_result = described_class.call(low_level_building)
      high_result = described_class.call(high_level_building)

      # Higher level buildings should produce more
      expect(high_result.resources.values.sum).to be > low_result.resources.values.sum
    end
  end

  describe "concern integration" do
    it "includes both Trackable and Cacheable concerns" do
      expect(described_class.included_modules).to include(Trackable)
      expect(described_class.included_modules).to include(Cacheable)
    end

    it "responds to concern methods" do
      service = described_class.new(village_building)

      expect(service).to respond_to(:call_with_cache)
      expect(service.private_methods).to include(:track_service_start)
      expect(service.private_methods).to include(:track_service_end)
    end
  end
end
