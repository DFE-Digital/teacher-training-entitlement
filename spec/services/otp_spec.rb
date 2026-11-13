require "rails_helper"

RSpec.describe OTP do
  let(:code) { "ABCD2345" }
  let(:expires_at) { 2.minutes.from_now }
  let(:crockford_base32_alphabet) { /\A[0-9A-HJKMNP-TV-Z]{8}\z/ }

  describe ".generate" do
    subject(:otp) { described_class.generate }

    it "builds a code that is 8 characters long" do
      expect(otp.code.length).to eq(8)
    end

    it "builds a code using only the Crockford Base32 alphabet" do
      expect(otp.code).to match(crockford_base32_alphabet)
    end

    it "maps random indexes 0 and 31 to the first and last alphabet characters" do
      allow(SecureRandom).to receive(:random_number).with(32).and_return(0, 31, 0, 31, 0, 31, 0, 31)
      expect(described_class.generate.code).to eq("0Z0Z0Z0Z")
    end

    it "expires after the validity period" do
      freeze_time do
        expect(otp.expires_at).to eq(described_class::VALIDITY_PERIOD.from_now)
      end
    end
  end

  describe "validity period" do
    it "is 10 minutes" do
      expect(described_class::VALIDITY_PERIOD).to eq(10.minutes)
    end

    it "is not expired at the exact expiry time" do
      freeze_time do
        expect(described_class.new(code:, expires_at: Time.current).expired?).to be(false)
      end
    end

    it "is expired just after the expiry time" do
      expect(described_class.new(code:, expires_at: 1.second.ago).expired?).to be(true)
    end
  end

  describe "secure comparison" do
    it "compares using a constant-time comparison" do
      allow(ActiveSupport::SecurityUtils).to receive(:secure_compare).and_call_original
      described_class.new(code:, expires_at:).matches?("abcd2345")
      expect(ActiveSupport::SecurityUtils).to have_received(:secure_compare).with(code, code)
    end

    it "generates codes with SecureRandom" do
      allow(SecureRandom).to receive(:random_number).and_call_original
      described_class.generate
      expect(SecureRandom).to have_received(:random_number).exactly(8).times
    end
  end

  describe "initialisation" do
    it "uses the code it was given" do
      expect(described_class.new(code:, expires_at:).code).to eq(code)
    end

    it "uses the expiry it was given" do
      expect(described_class.new(code:, expires_at:).expires_at).to eq(expires_at)
    end

    it "rejects a nil code" do
      expect { described_class.new(code: nil, expires_at:) }.to raise_error(OTP::Invalid)
    end

    it "rejects a code that is not 8 characters" do
      expect { described_class.new(code: "ABCD234", expires_at:) }.to raise_error(OTP::Invalid)
    end

    it "rejects a code with characters outside the alphabet" do
      expect { described_class.new(code: "ABCDILO1", expires_at:) }.to raise_error(OTP::Invalid)
    end

    it "rejects a nil expiry" do
      expect { described_class.new(code:, expires_at: nil) }.to raise_error(OTP::Invalid)
    end

    it "rejects an expiry that is not a time" do
      expect { described_class.new(code:, expires_at: "soon") }.to raise_error(OTP::Invalid)
    end
  end

  describe ".valid_code_format?" do
    it "is true for 8 characters from the alphabet" do
      expect(described_class.valid_code_format?("ABCD2345")).to be(true)
    end

    it "is false for nil" do
      expect(described_class.valid_code_format?(nil)).to be(false)
    end

    it "is false for the wrong length" do
      expect(described_class.valid_code_format?("ABCD234")).to be(false)
    end

    it "is false for characters outside the alphabet" do
      expect(described_class.valid_code_format?("ABCDILO1")).to be(false)
    end
  end

  describe "#matches?" do
    subject(:otp) { described_class.new(code:, expires_at:) }

    it "matches when the entered code is identical" do
      expect(otp.matches?(code)).to be(true)
    end

    it "matches when the entered code is in lower case" do
      expect(otp.matches?(code.downcase)).to be(true)
    end

    {
      "O" => "0",
      "o" => "0",
      "I" => "1",
      "i" => "1",
      "L" => "1",
      "l" => "1",
    }.each do |typed, digit|
      it "treats '#{typed}' as '#{digit}'" do
        stored = "#{digit}BCD2345"
        entered = "#{typed}BCD2345"
        expect(described_class.new(code: stored, expires_at:).matches?(entered)).to be(true)
      end
    end

    it "does not match a different code" do
      expect(otp.matches?("WXYZ6789")).to be(false)
    end

    it "does not match a nil entered code" do
      expect(otp.matches?(nil)).to be(false)
    end
  end

  describe "#expired?" do
    it "is false when the expiry is in the future" do
      expect(described_class.new(code:, expires_at: 10.minutes.from_now).expired?).to be(false)
    end

    it "is true when the expiry is in the past" do
      expect(described_class.new(code:, expires_at: 1.minute.ago).expired?).to be(true)
    end
  end
end
