RSpec.describe IdempotentResourceCollectionJob do
  let(:village) { create(:village, :with_resource_buildings) }

  describe "#perform" do
    it "collects resources successfully" do
      expect {
        described_class.perform_now(village.id)
      }.to change(ResourceCollection, :count).by(1)
    end

    it "updates village resources" do
      initial_wood = village.resource_amount("wood")

      described_class.perform_now(village.id)

      expect(village.reload.resource_amount("wood")).to be > initial_wood
    end

    it "records collection details" do
      described_class.perform_now(village.id)

      collection = ResourceCollection.last
      expect(collection.village).to eq(village)
      expect(collection.collection_period).to be_present
      expect(collection.resources_collected).to be_present
      expect(collection.total_value).to be > 0
      expect(collection.collected_at).to be_within(1.second).of(Time.current)
    end

    it "is idempotent within same collection period" do
      # First execution
      described_class.perform_now(village.id)
      initial_collection_count = ResourceCollection.count
      initial_wood = village.reload.resource_amount("wood")

      # Second execution in same period
      described_class.perform_now(village.id)

      expect(ResourceCollection.count).to eq(initial_collection_count)
      expect(village.reload.resource_amount("wood")).to eq(initial_wood)
    end

    it "allows new collection in different period" do
      # First collection
      described_class.perform_now(village.id)

      # Simulate time passing to next collection period
      travel 2.hours do
        expect {
          described_class.perform_now(village.id)
        }.to change(ResourceCollection, :count).by(1)
      end
    end

    it "handles concurrent execution safely" do
      # Simulate multiple workers processing simultaneously
      results = []

      threads = 3.times.map do
        Thread.new do
          begin
            described_class.perform_now(village.id)
            results << :success
          rescue => e
            results << e.class.name
          end
        end
      end

      threads.each(&:join)

      # Should have exactly one collection record
      expect(ResourceCollection.count).to eq(1)
      # At least one should succeed
      expect(results).to include(:success)
    end

    it "calculates collection period correctly" do
      freeze_time = Time.zone.parse("2024-01-15 14:30:00")

      travel_to freeze_time do
        job = described_class.new
        period = job.send(:calculate_collection_period)
        expect(period).to eq("2024-01-15-14")
      end
    end
  end

  describe "error handling" do
    it "handles deleted village gracefully" do
      village.destroy

      expect {
        described_class.perform_now(village.id)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "logs collection activities" do
      expect(Rails.logger).to receive(:info).with(/Starting resource collection/)
      expect(Rails.logger).to receive(:info).with(/Completed resource collection/)

      described_class.perform_now(village.id)
    end
  end

  describe "Turbo Stream broadcasting" do
    it "broadcasts resource updates" do
      expect do
        described_class.perform_now(village.id)
      end.to have_broadcasted_to(village).from_channel(Turbo::StreamsChannel)
    end
  end

  describe "database constraints" do
    it "prevents duplicate collections via unique constraint" do
      # First job creates collection
      described_class.perform_now(village.id)

      # Simulate race condition by manually trying to create duplicate
      period = described_class.new.send(:calculate_collection_period)

      expect {
        ResourceCollection.create!(
          village: village,
          collection_period: period,
          resources_collected: {},
          collected_at: Time.current
        )
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end
