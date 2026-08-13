# Standalone CNPJ format/checksum logic (mod-11 check digits), independent
# of ActiveModel so it can be reused by CnpjValidator and by specs/factories
# that need to mint a real, valid CNPJ instead of an arbitrary digit string.
module Cnpj
  FIRST_DIGIT_WEIGHTS = [ 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2 ].freeze
  SECOND_DIGIT_WEIGHTS = [ 6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2 ].freeze

  module_function

  def normalize(value)
    value.to_s.gsub(/\D/, "")
  end

  def valid?(value)
    digits = normalize(value)
    return false if digits.length != 14
    # Known invalid placeholders (e.g. "00000000000000", "11111111111111")
    # would otherwise slip through: a repeated digit always yields sum 0 mod
    # 11 for both check digits, which happens to "check out" mathematically.
    return false if digits.chars.uniq.length == 1

    digits[12] == check_digit(digits[0...12], FIRST_DIGIT_WEIGHTS) &&
      digits[13] == check_digit(digits[0...13], SECOND_DIGIT_WEIGHTS)
  end

  def check_digit(base, weights)
    sum = base.chars.each_with_index.sum { |digit, index| digit.to_i * weights[index] }
    remainder = sum % 11
    (remainder < 2 ? 0 : 11 - remainder).to_s
  end
end
