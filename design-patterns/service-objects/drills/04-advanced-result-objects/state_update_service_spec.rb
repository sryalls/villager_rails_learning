RSpec.describe Game::StateUpdateService do
  let(:village) { create(:village, :with_buildings, :with_resources) }

  describe "#call" do
    subject { described_class.call(village) }

    it "returns a comprehensive result object" do
      expect(subject).to be_a(GameStateResult)
      expect(subject.village).to eq(village)
      expect(subject.production_metrics).to be_present
      expect(subject.population_changes).to be_present
      expect(subject.score_changes).to be_present
    end

    it "includes detailed production metrics" do
      result = subject

      expect(result.production_metrics).to include(:total_resources_produced)
      expect(result.production_metrics).to include(:buildings_processed)
      expect(result.production_metrics).to include(:successful_productions)
      expect(result.production_metrics).to include(:failed_productions)
      expect(result.production_metrics).to include(:production_by_type)
    end

    it "tracks population changes" do
      result = subject

      expect(result.population_changes).to include(:previous_population)
      expect(result.population_changes).to include(:new_population)
      expect(result.population_changes).to include(:growth_rate)
      expect(result.population_changes).to include(:growth_factors)
    end

    it "records score changes" do
      result = subject

      expect(result.score_changes).to include(:previous_score)
      expect(result.score_changes).to include(:new_score)
      expect(result.score_changes).to include(:score_delta)
      expect(result.score_changes).to include(:score_breakdown)
    end

    it "captures random events" do
      result = subject

      expect(result.events_triggered).to be_an(Array)
      expect(result.events_triggered.length).to be >= 0

      if result.events_triggered.any?
        event = result.events_triggered.first
        expect(event).to include(:type, :description, :effects)
      end
    end

    it "supports method chaining" do
      notifications_sent = []

      result = subject
        .on_success { |r| notifications_sent << "success: #{r.summary}" }
        .on_failure { |r| notifications_sent << "failure: #{r.errors}" }
        .on_partial_success { |r| notifications_sent << "partial: #{r.summary}" }

      expect(result).to be_a(GameStateResult)
      expect(notifications_sent).not_to be_empty
    end
  end

  describe "partial success handling" do
    context "with building production failures" do
      before do
        # Simulate a building that fails to produce
        allow_any_instance_of(Building).to receive(:produce_resources)
          .and_raise(StandardError, "Production facility damaged")
      end

      it "handles partial failures gracefully" do
        result = described_class.call(village)

        expect(result).to be_partial_success
        expect(result.errors).not_to be_empty
        expect(result.production_metrics[:failed_productions]).to be > 0
        expect(result.production_metrics[:successful_productions]).to be >= 0
      end

      it "continues processing despite individual failures" do
        result = described_class.call(village)

        # Should still process population and score even if production fails
        expect(result.population_changes).to be_present
        expect(result.score_changes).to be_present
      end
    end

    context "with population calculation errors" do
      before do
        allow_any_instance_of(Village).to receive(:calculate_population_growth)
          .and_raise(StandardError, "Population census failed")
      end

      it "marks result as partial success" do
        result = described_class.call(village)

        expect(result).to be_partial_success
        expect(result.errors.any? { |e| e.include?("Population") }).to be true
      end
    end
  end

  describe "result object features" do
    let(:result) { described_class.call(village) }

    it "provides detailed metrics" do
      expect(result.production_metrics[:total_resources_produced]).to be_a(Hash)
      expect(result.production_metrics[:buildings_processed]).to be_a(Integer)
      expect(result.population_changes[:growth_rate]).to be_a(Numeric)
      expect(result.score_changes[:score_delta]).to be_a(Numeric)
    end

    it "generates meaningful summaries" do
      summary = result.summary

      expect(summary).to be_a(String)
      expect(summary).to include("Village")
      expect(summary.length).to be > 50
      expect(summary).to match(/\d+/) # Should include numbers
    end

    it "supports dynamic attribute access" do
      # OpenStruct should allow dynamic attributes
      expect(result.village).to eq(village)
      expect(result.success?).to be_in([true, false])
      expect(result.partial_success?).to be_in([true, false])
    end

    it "provides chainable methods that return self" do
      chained_result = result
        .on_success { |r| r.processing_complete = true }
        .on_partial_success { |r| r.needs_attention = true }

      expect(chained_result).to eq(result)
      expect(chained_result).to be_a(GameStateResult)
    end
  end

  describe "error accumulation" do
    context "with multiple system failures" do
      before do
        allow_any_instance_of(Building).to receive(:produce_resources)
          .and_raise(StandardError, "Production failed")
        allow_any_instance_of(Village).to receive(:calculate_population_growth)
          .and_raise(StandardError, "Population calculation failed")
      end

      it "accumulates all errors" do
        result = described_class.call(village)

        expect(result.errors.length).to be >= 2
        expect(result.errors.any? { |e| e.include?("Production") }).to be true
        expect(result.errors.any? { |e| e.include?("Population") }).to be true
      end

      it "provides error categorization" do
        result = described_class.call(village)

        expect(result.error_categories).to be_a(Hash)
        expect(result.error_categories).to include(:production_errors)
        expect(result.error_categories).to include(:population_errors)
      end
    end
  end

  describe "performance metrics" do
    it "tracks execution timing" do
      result = described_class.call(village)

      expect(result.execution_metrics).to include(:total_time_ms)
      expect(result.execution_metrics).to include(:production_time_ms)
      expect(result.execution_metrics).to include(:population_time_ms)
      expect(result.execution_metrics).to include(:scoring_time_ms)
    end

    it "includes resource efficiency metrics" do
      result = described_class.call(village)

      expect(result.efficiency_metrics).to include(:resources_per_building)
      expect(result.efficiency_metrics).to include(:score_per_resource)
      expect(result.efficiency_metrics).to include(:population_efficiency)
    end
  end
end
