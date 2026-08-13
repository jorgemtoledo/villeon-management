class CnpjValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    record.errors.add(attribute, "não é um CNPJ válido") unless Cnpj.valid?(value)
  end
end
