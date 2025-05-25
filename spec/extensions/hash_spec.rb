# frozen_string_literal: true

require 'rails_helper'

describe Hash do
  describe '#deeply_underscore' do
    subject(:deeply_underscored) { hash.deeply_underscore }

    let(:hash) do
      {
        keyOne: 'valueOne',
        keyTwo: [{ nestedKey: 'nestedValue' }],
        keyFour: { keyFive: 'valueFive' }
      }
    end

    it 'deeplies underscore all keys' do
      expect(deeply_underscored).to eq(
        {
          key_one: 'valueOne',
          key_two: [{ nested_key: 'nestedValue' }],
          key_four: { key_five: 'valueFive' }
        }
      )
    end

    context 'with one-letter keys' do
      let(:hash) do
        { k: 'valueOne', K: [{ b: 'nestedValue' }], B: { c: 'valueFive' } }
      end

      it 'does nothing' do
        expect(deeply_underscored).to eq hash
      end
    end
  end

  describe '#deeply_camelize' do
    subject(:deeply_camelized) { hash.deeply_camelize }

    let(:hash) do
      {
        key_one: 'valueOne',
        key_two: [{ nested_key: 'nestedValue' }],
        key_four: { key_five: 'valueFive' }
      }
    end

    it 'deeplies underscore all keys' do
      expect(deeply_camelized).to eq(
        {
          keyOne: 'valueOne',
          keyTwo: [{ nestedKey: 'nestedValue' }],
          keyFour: { keyFive: 'valueFive' }
        }
      )
    end
  end
end
