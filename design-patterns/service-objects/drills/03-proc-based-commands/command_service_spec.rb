RSpec.describe Villages::CommandService do
  let(:village) { create(:village) }
  let(:service) { described_class.new(village) }

  describe "building commands" do
    it "adds a building" do
      expect {
        service.execute(:add_building, "house", 2, 3)
      }.to change(village.buildings, :count).by(1)

      building = village.buildings.last
      expect(building.building_type).to eq("house")
      expect(building.position_x).to eq(2)
      expect(building.position_y).to eq(3)
    end

    it "removes a building" do
      building = create(:building, village: village)

      expect {
        service.execute(:remove_building, building.id)
      }.to change(village.buildings, :count).by(-1)
    end

    it "upgrades a building" do
      building = create(:building, village: village, level: 1)

      service.execute(:upgrade_building, building.id)

      expect(building.reload.level).to eq(2)
    end

    it "validates building placement" do
      # Try to place building at invalid coordinates
      expect {
        service.execute(:add_building, "house", -1, -1)
      }.to raise_error(/Invalid position/)
    end

    it "prevents building on occupied tiles" do
      create(:building, village: village, position_x: 5, position_y: 5)

      expect {
        service.execute(:add_building, "house", 5, 5)
      }.to raise_error(/Position already occupied/)
    end
  end

  describe "resource commands" do
    before do
      village.add_resource("wood", 100)
      village.add_resource("stone", 50)
    end

    it "adds resources" do
      service.execute(:add_resources, { wood: 10, stone: 5 })

      expect(village.resource_amount("wood")).to eq(110)
      expect(village.resource_amount("stone")).to eq(55)
    end

    it "consumes resources when sufficient" do
      service.execute(:consume_resources, { wood: 20, stone: 10 })

      expect(village.resource_amount("wood")).to eq(80)
      expect(village.resource_amount("stone")).to eq(40)
    end

    it "fails to consume resources when insufficient" do
      expect {
        service.execute(:consume_resources, { wood: 200, stone: 10 })
      }.to raise_error(/Insufficient resources/)
    end

    it "validates resource types" do
      expect {
        service.execute(:add_resources, { invalid_resource: 10 })
      }.to raise_error(/Unknown resource type/)
    end
  end

  describe "undo functionality" do
    before do
      village.add_resource("wood", 50)
    end

    it "undoes the last command" do
      service.execute(:add_resources, { wood: 10 })
      expect(village.resource_amount("wood")).to eq(60)

      service.undo_last
      expect(village.resource_amount("wood")).to eq(50)
    end

    it "tracks command history" do
      service.execute(:add_resources, { wood: 10 })
      service.execute(:add_resources, { stone: 5 })

      expect(service.can_undo?).to be true

      service.undo_last # Undo stone addition
      expect(village.resource_amount("stone")).to eq(0)
      expect(village.resource_amount("wood")).to eq(60)

      service.undo_last # Undo wood addition
      expect(village.resource_amount("wood")).to eq(50)
    end

    it "handles multiple undos correctly" do
      original_wood = village.resource_amount("wood")

      # Execute multiple commands
      service.execute(:add_resources, { wood: 10 })
      service.execute(:add_resources, { wood: 20 })
      service.execute(:add_resources, { wood: 5 })

      # Undo all commands
      3.times { service.undo_last }

      expect(village.resource_amount("wood")).to eq(original_wood)
      expect(service.can_undo?).to be false
    end

    it "undoes building operations" do
      service.execute(:add_building, "house", 1, 1)
      building_count = village.buildings.count

      service.undo_last
      expect(village.buildings.count).to eq(building_count - 1)
    end

    it "undoes building upgrades" do
      building = create(:building, village: village, level: 1)
      original_level = building.level

      service.execute(:upgrade_building, building.id)
      expect(building.reload.level).to eq(original_level + 1)

      service.undo_last
      expect(building.reload.level).to eq(original_level)
    end
  end

  describe "command validation" do
    it "validates command existence" do
      expect {
        service.execute(:invalid_command, "arg")
      }.to raise_error(/Unknown command/)
    end

    it "validates command arguments" do
      expect {
        service.execute(:add_building) # Missing required arguments
      }.to raise_error(/Invalid arguments/)
    end
  end

  describe "command composition" do
    it "allows chaining multiple commands" do
      # This test ensures commands can be composed
      service.execute(:add_resources, { wood: 100, stone: 50 })
      service.execute(:add_building, "house", 1, 1)
      service.execute(:consume_resources, { wood: 20, stone: 10 })

      expect(village.resource_amount("wood")).to eq(180) # 100 added - 20 consumed
      expect(village.resource_amount("stone")).to eq(90) # 50 added - 10 consumed
      expect(village.buildings.count).to eq(1)
    end
  end

  describe "error handling and rollback" do
    it "does not modify state if command fails" do
      original_count = village.buildings.count

      expect {
        service.execute(:add_building, "house", -1, -1) # Invalid position
      }.to raise_error(/Invalid position/)

      expect(village.buildings.count).to eq(original_count)
    end

    it "handles database errors gracefully" do
      # Simulate database constraint violation
      allow(village).to receive(:add_resource).and_raise(ActiveRecord::StatementInvalid)

      expect {
        service.execute(:add_resources, { wood: 10 })
      }.to raise_error(ActiveRecord::StatementInvalid)

      # Command should not be added to history if it failed
      expect(service.can_undo?).to be false
    end
  end
end
