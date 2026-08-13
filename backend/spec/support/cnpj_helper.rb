# Mints a real, checksum-valid CNPJ from a numeric seed — used wherever a
# spec/factory needs a CNPJ that must actually pass CnpjValidator (a random
# or sequential 14-digit string almost never has valid check digits).
module CnpjHelper
  def self.generate(seed)
    base = format("%012d", seed)
    check1 = Cnpj.check_digit(base, Cnpj::FIRST_DIGIT_WEIGHTS)
    base13 = base + check1
    check2 = Cnpj.check_digit(base13, Cnpj::SECOND_DIGIT_WEIGHTS)

    base13 + check2
  end
end
