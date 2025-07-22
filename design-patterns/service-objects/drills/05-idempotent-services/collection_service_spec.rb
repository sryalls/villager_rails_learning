RSpec.describe Resources::CollectionService do
  let(:village) { create(:village, :with_buildings) }
  let(:service) { described_class.new(village.id) }

  describe "idempotency" do
    it "performs collection only once for same time window" do
      # First call should create collection
      result1 = service.call
      expect(result1).to be_success
      expect(result1.already_collected).to be_falsy

      # Second call should return existing collection
      result2 = service.call
      expect(result2).to be_success
      expect(result2.already_collected).to be true

      # Should have only one collection record
      expect(ResourceCollection.count).to eq(1)
    end

    it "handles concurrent execution safely" do
      # Simulate multiple workers trying to collect simultaneously
      results = []

      threads = 3.times.map do
        Thread.new do
          results << described_class.call(village.id)
        end
      end

      threads.each(&:join)

      # Only one should succeed in creating new collection
      successful_collections = results.count { |r| r.success? && !r.already_collected }
      expect(successful_collections).to eq(1)
      expect(ResourceCollection.count).to eq(1)
    end

    it "generates consistent idempotency keys" do
      service1 = described_class.new(village.id)
      service2 = described_class.new(village.id)

      key1 = service1.send(:generate_idempotency_key)
      key2 = service2.send(:generate_idempotency_key)

      expect(key1).to eq(key2)
    end

    it "includes collection type in idempotency key" do
      scheduled_service = described_class.new(village.id, :scheduled)
      manual_service = described_class.new(village.id, :manual)

      scheduled_key = scheduled_service.send(:generate_idempotency_key)
      manual_key = manual_service.send(:generate_idempotency_key)

      expect(scheduled_key).not_to eq(manual_key)
    end
  end

  describe "different time windows" do
    it "allows new collection in different time window" do
      # First collection
      result1 = service.call
      expect(result1).to be_success

      # Simulate time passing to next collection window
      travel 1.hour do
        result2 = described_class.new(village.id).call
        expect(result2).to be_success
        expect(result2.already_collected).to be_falsy
      end

      expect(ResourceCollection.count).to eq(2)
    end

    it "uses different keys for different time windows" do
      key1 = service.send(:generate_idempotency_key)

      travel 1.hour do
        key2 = described_class.new(village.id).send(:generate_idempotency_key)
        expect(key1).not_to eq(key2)
      end
    end
  end

  describe "distributed locking" do
    before do
      # Ensure Redis is available for testing
      skip "Redis not available" unless defined?(Redis) && Redis.current.ping == "PONG"
    end

    it "prevents race conditions across multiple processes" do
      # This test simulates distributed execution
      lock_acquired_count = 0

      3.times do |i|
        service_instance = described_class.new(village.id)

        begin
          service_instance.send(:with_distributed_lock) do
            lock_acquired_count += 1
            sleep 0.1 # Simulate work
          end
        rescue => e
          # Lock not acquired, which is expected behavior
        end
      end

      # Only one should acquire the lock at a time
      expect(lock_acquired_count).to eq(1)
    end

    it "releases locks after completion" do
      service.send(:with_distributed_lock) do
        # Lock should be held
      end

      # After block completion, another service should be able to acquire lock
      another_service = described_class.new(village.id)
      lock_acquired = false

      another_service.send(:with_distributed_lock) do
        lock_acquired = true
      end

      expect(lock_acquired).to be true
    end
  end

  describe "resource collection logic" do
    before do
      # Set up village with buildings that can produce resources
      create(:village_building, village: village, building_type: "farm", level: 2)
      create(:village_building, village: village, building_type: "mine", level: 1)
    end

    it "collects resources from all buildings" do
      result = service.call

      expect(result).to be_success
      expect(result.resources_collected).to be_a(Hash)
      expect(result.resources_collected.keys).to include("food", "stone")
      expect(result.total_resources).to be > 0
    end

    it "applies level-based production multipliers" do
      # Higher level buildings should produce more
      farm_production = result_for_building_level("farm", 3)
      basic_production = result_for_building_level("farm", 1)

      expect(farm_production["food"]).to be > basic_production["food"]
    end

    it "records collection details" do
      result = service.call
      collection = ResourceCollection.last

      expect(collection.village).to eq(village)
      expect(collection.collection_type).to eq("scheduled")
      expect(collection.resources_collected).to eq(result.resources_collected)
      expect(collection.collected_at).to be_within(1.second).of(Time.current)
    end
  end

  describe "error handling" do
    context "when village is deleted during execution" do
      it "handles missing village gracefully" do
        village_id = village.id
        village.destroy

        result = described_class.call(village_id)
        expect(result).to be_failure
        expect(result.error).to include("Village not found")
      end
    end

    context "when database constraint violation occurs" do
      it "handles unique constraint violations" do
        # Create a collection record directly to simulate race condition
        ResourceCollection.create!(
          village: village,
          idempotency_key: service.send(:generate_idempotency_key),
          collection_type: "scheduled",
          resources_collected: {},
          collected_at: Time.current
        )

        result = service.call
        expect(result).to be_success
        expect(result.already_collected).to be true
      end
    end

    context "when building production fails" do
      before do
        allow_any_instance_of(VillageBuilding).to receive(:produce_resources)
          .and_raise(StandardError, "Building damaged")
      end

      it "handles individual building failures gracefully" do
        result = service.call

        expect(result).to be_success # Overall operation succeeds
        expect(result.errors).not_to be_empty
        expect(result.partial_success).to be true
      end
    end
  end

  describe "logging and monitoring" do
    it "logs collection start and completion" do
      expect(Rails.logger).to receive(:info).with(/Starting resource collection/)
      expect(Rails.logger).to receive(:info).with(/Completed resource collection/)

      service.call
    end

    it "logs idempotency key for debugging" do
      expect(Rails.logger).to receive(:info).with(/Idempotency key:/)

      service.call
    end

    it "logs collection metrics" do
      expect(Rails.logger).to receive(:info).with(/Collected \d+ total resources/)

      service.call
    end
  end

  describe "different collection types" do
    it "supports scheduled collections" do
      scheduled_service = described_class.new(village.id, :scheduled)
      result = scheduled_service.call

      expect(result).to be_success
      expect(ResourceCollection.last.collection_type).to eq("scheduled")
    end

    it "supports manual collections" do
      manual_service = described_class.new(village.id, :manual)
      result = manual_service.call

      expect(result).to be_success
      expect(ResourceCollection.last.collection_type).to eq("manual")
    end

    it "supports event-based collections" do
      event_service = described_class.new(village.id, :event)
      result = event_service.call

      expect(result).to be_success
      expect(ResourceCollection.last.collection_type).to eq("event")
    end

    it "allows different collection types in same time window" do
      # Different collection types should be able to run in same time window
      scheduled_result = described_class.call(village.id, :scheduled)
      manual_result = described_class.call(village.id, :manual)

      expect(scheduled_result).to be_success
      expect(manual_result).to be_success
      expect(ResourceCollection.count).to eq(2)
    end
  end

  private

  def result_for_building_level(building_type, level)
    test_village = create(:village)
    create(:village_building, village: test_village, building_type: building_type, level: level)

    described_class.call(test_village.id).resources_collected
  end
end
