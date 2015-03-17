require 'poltergrind/worker'

module Poltergrind
  describe Worker do
    let(:klass) do
      Class.new do
        def self.name; 'TestClass'; end
        include Poltergrind::Worker
      end
    end

    let(:instance) do
      klass.new
    end

    it 'provides the Capybara DSL' do
      expect(instance).to respond_to :visit
    end

    it 'provides #time' do
      expect(instance).to respond_to :time
    end

    it 'provides .namespace' do
      expect(klass.namespace).to eq 'poltergrind.TestClass'
    end

    it 'includes Sidekiq::Worker' do
      expect(klass).to respond_to :perform_async
    end

    describe '#statsd' do
      it 'is a Statsd client' do
        expect(instance.statsd).to be_a Statsd
      end

      it 'has a namespace for the class' do
        expect(instance.statsd.namespace).to eq 'poltergrind.TestClass'
      end
    end

    it 'delegates statsd methods' do
      %i(time increment decrement timing gauge count).each do |method|
        expect(instance).to respond_to method
      end
    end

    describe '#perform' do
      it 'times each job' do
        expect(instance).to receive(:time).with('perform.total')

        instance.perform { nil }
      end

      it 'calls #gauge for the start and end time of each job' do
        allow(Time).to receive(:now).and_return(12345, 12346)
        expect(instance).to receive(:gauge).with('perform.start', 12345)
        expect(instance).to receive(:gauge).with('perform.finish', 12346)

        instance.perform { nil }
      end
    end
  end
end
