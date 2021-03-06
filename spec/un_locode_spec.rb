require 'spec_helper'
require 'un_locode'

describe UnLocode::Locode do

  describe 'scopes' do

    describe 'retrieving locodes by name' do

      let!(:city) { UnLocode::Locode.create(name: 'Eindhoven', name_wo_diacritics: 'Eeindhoven') }
      let!(:other_city) { UnLocode::Locode.create(name: 'Weert') }

      subject { UnLocode::Locode.find_by_fuzzy_name(search_term) }

      context 'exact match' do
        let(:search_term) { city.name }
        its(:first) { should eql(city) }
        its(:count) { should eql(1) }
      end

      context 'fuzzy match' do
        let(:search_term) { city.name[1..4] }
        its(:first) { should eql(city) }
        its(:count) { should eql(1) }
      end

      [:name, :name_wo_diacritics, :alternative_name, :alternative_name_wo_diacritics].each do |attr|
        context "matches against the #{attr} name fields" do
          let!(:city) { UnLocode::Locode.create(attr => 'Eindhoven') }
          let(:search_term) { 'Eindhoven' }
          its(:first) { should eql(city) }
          its(:count) { should eql(1) }
        end
      end

      context 'case insensitive names' do
        let(:search_term) { city.name.downcase }

        its(:first) { should eql(city) }
        its(:count) { should eql(1) }
      end

    end

    describe 'retrieving locodes by name and function' do
      let!(:port) { UnLocode::Locode.create(name: 'Eindhoven', port: true) }
      let!(:rail_terminal) { UnLocode::Locode.create(name: 'Eindhoven', rail_terminal: true) }

      context 'with supported functions' do
        subject { UnLocode::Locode.find_by_name_and_function(search_term, :port) }
        let(:search_term) { port.name }

        its(:first) { should eql(port) }
        its(:count) { should eql(1) }
      end

      context 'with unsupported function' do
        it 'raises an error' do
          expect { UnLocode::Locode.find_by_name_and_function(search_term, :derp) }.to raise_error(NameError)
        end
      end
    end

    describe 'retrieves locodes for' do
      let!(:port) { UnLocode::Locode.create(name: 'Eindhoven', port: true) }
      let!(:airport) { UnLocode::Locode.create(name: 'Eindhoven', airport: true) }

      subject { UnLocode::Locode.find_by_function(function) }

      context 'ports function' do
        let(:function) { :port }

        its(:first) { should eql(port) }
        its(:count) { should eql(1) }
        it { should_not include airport }
      end

      context 'airports function' do
        let(:function) { :airport }

        its(:first) { should eql(airport) }
        its(:count) { should eql(1) }
        it { should_not include port }
      end

      context 'unsupported function' do
        it 'raises an error' do
          expect { UnLocode::Locode.find_by_function(:derp) }.to raise_error(RuntimeError)
        end
      end
    end

    describe 'retrieving country by locode' do
      let!(:country) { UnLocode::Country.create name: 'NETHERLANDS', code: 'NL' }
      let!(:location) { UnLocode::Locode.create name: 'Venlo', city_code: 'VEN', country: country }

      context 'with supported functions and space in search' do
        subject { UnLocode::Locode.find_by_locode(search_term) }
        let(:search_term) { 'NL VEN' }
        its(:city_code) { should eql('VEN') }
        its(:name) { should eql('Venlo') }
        its(:country) { should eql(country) }
      end
      context 'with supported functions with actual space-less locode' do
        subject { UnLocode::Locode.find_by_locode(search_term) }
        let(:search_term) { 'NLVEN' }
        its(:city_code) { should eql('VEN') }
        its(:name) { should eql('Venlo') }
        its(:country) { should eql(country) }
      end
      context 'with supported functions with mixed case locode' do
        subject { UnLocode::Locode.find_by_locode(search_term) }
        let(:search_term) { 'NlVen' }
        its(:city_code) { should eql('VEN') }
      end

    end
  end

  describe 'as_json' do
    let!(:country) { UnLocode::Country.create name: 'Belgium', code: 'BE' }
    let!(:location) { UnLocode::Locode.create name: 'Eindhoven', port: true, country: country }

    subject { location.as_json }

    its(['country']) { should eql({'code' => 'BE', 'name' => 'Belgium'}) }
    it { should_not have_key('country_id') }
    it { should_not have_key('id') }
  end
end
