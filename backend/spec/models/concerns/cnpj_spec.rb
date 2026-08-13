require "rails_helper"

RSpec.describe Cnpj do
  describe ".normalize" do
    it "strips punctuation, keeping only digits" do
      expect(Cnpj.normalize("11.222.333/0001-81")).to eq("11222333000181")
    end

    it "passes through an already-normalized value unchanged" do
      expect(Cnpj.normalize("11222333000181")).to eq("11222333000181")
    end
  end

  describe ".valid?" do
    it "accepts well-known real, checksum-valid CNPJs" do
      expect(Cnpj.valid?("11222333000181")).to be true
      expect(Cnpj.valid?("11444777000161")).to be true
    end

    it "accepts a masked CNPJ" do
      expect(Cnpj.valid?("11.222.333/0001-81")).to be true
    end

    it "rejects a value with the wrong length" do
      expect(Cnpj.valid?("1122233300018")).to be false
      expect(Cnpj.valid?("112223330001811")).to be false
    end

    it "rejects a wrong check digit" do
      expect(Cnpj.valid?("11222333000180")).to be false
      expect(Cnpj.valid?("11222333000182")).to be false
    end

    it "rejects every repeated-digit placeholder" do
      %w[00000000000000 11111111111111 99999999999999].each do |placeholder|
        expect(Cnpj.valid?(placeholder)).to be false
      end
    end

    it "rejects blank input" do
      expect(Cnpj.valid?("")).to be false
      expect(Cnpj.valid?(nil)).to be false
    end
  end
end
