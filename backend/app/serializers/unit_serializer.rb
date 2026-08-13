class UnitSerializer
  def self.call(unit)
    new(unit).call
  end

  def initialize(unit)
    @unit = unit
  end

  def call
    {
      id: unit.id,
      name: unit.name,
      abbreviation: unit.abbreviation
    }
  end

  private

  attr_reader :unit
end
