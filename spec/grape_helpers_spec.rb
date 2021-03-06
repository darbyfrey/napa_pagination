require 'spec_helper'
require 'napa_pagination/grape_helpers'

class FooApi < Grape::API; end
class FooRepresenter < Napa::Representer; end

describe NapaPagination::GrapeHelpers do
  before do
    @endpoint = Grape::Endpoint.new(nil, {path: '/test', method: :get})
  end

  context '#represent_pagination' do
    before do
      Foo.create(word: 'bar')
      Foo.create(word: 'baz')
    end

    after do
      Foo.destroy_all
    end

    it 'returns the collection if it is already paginated' do
      objects = Kaminari.paginate_array([Foo.new, Foo.new, Foo.new]).page(1)
      output = @endpoint.represent_pagination(objects)

      expect(output.class).to eq(objects.class)
    end

    it 'returns a paginated collection if given an array' do
      output = @endpoint.represent_pagination(Foo.all.page(1))

      expect(output.class).to be(Foo::ActiveRecord_Relation)
      expect(output.total_pages).to be(1)
      expect(output.total_count).to be(2)
    end

    it 'returns a paginated collection if given an ActiveRecord_Relation' do
      output = @endpoint.represent_pagination(Foo.all)

      expect(output.total_count).to be(2)
      expect(output.total_pages).to be(1)
    end

    it 'overrides the page and per_page defaults if supplied as params' do
      allow(@endpoint).to receive_message_chain(:params, :page).and_return(2)
      allow(@endpoint).to receive_message_chain(:params, :per_page).and_return(1)

      output = @endpoint.represent_pagination(Foo.all)

      expect(output.current_page).to be(2)
      expect(output.total_count).to be(2)
      expect(output.total_pages).to be(2)
    end
  end

  context '#paginate' do
    it 'raises an exception if no representer is given' do
      object = Foo.new
      expect{ @endpoint.paginate(object) }.to raise_error
    end

    it 'returns the object nested in the data key when given a single object' do
      object = Foo.new
      output = @endpoint.paginate(object, with: FooRepresenter)

      expect(output.has_key?(:data)).to be true
      expect(output[:data]['object_type']).to eq('foo')
    end

    it 'returns a collection of objects nested in the data key' do
      objects = [Foo.new, Foo.new, Foo.new]
      output = @endpoint.paginate(objects, with: FooRepresenter)

      expect(output.has_key?(:data)).to be true
      expect(output[:data].class).to be(Array)
      expect(output[:data].first['object_type']).to eq('foo')
    end

    it 'returns a collection with pagination attributes if the collection is paginated' do
      objects = Kaminari.paginate_array([Foo.new, Foo.new, Foo.new]).page(1)
      output = @endpoint.paginate(objects, with: FooRepresenter)

      expect(output.has_key?(:data)).to be true
      expect(output.has_key?(:pagination)).to be true
      expect(output[:pagination][:page]).to eq(1)
      expect(output[:pagination][:per_page]).to eq(25)
      expect(output[:pagination][:total_pages]).to eq(1)
      expect(output[:pagination][:total_count]).to eq(3)
    end
  end
end
