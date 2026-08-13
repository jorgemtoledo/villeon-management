# This file seeds only structural domain data backed by real, unambiguous data
# from the client's spreadsheet (docs/data/MAPA COMPRAS.xlsx). Idempotent: safe
# to run multiple times (find_or_create_by!, never truncates or overwrites).
#
# Category and Subcategory are intentionally NOT seeded yet. The spreadsheet has
# no reliable Category taxonomy at all, and the Subcategoria codes actually used
# across the 530 products (25 distinct codes) don't even fully match the
# client's own "Listas" dropdown (13 codes) — e.g. OVO, ACU, FAR, FER, GOR, ARO,
# FRU, NOZ, CON, BEB, ERV, EMB show up in real rows but aren't listed there.
# Seeding either now would mean inventing a taxonomy Felipe hasn't confirmed.

# Sectors — source: "Como usar" tab, legend "SETOR (cor do código, coluna A)".
# The spreadsheet's "Categoria" column is literally this list under a
# different label; confirmed against real usage counts in "Catálogo Mestre"
# (col C: Bar 92, Confeitaria 71, Cozinha 225, Limpeza 43, Vinhos 99).
%w[Cozinha Confeitaria Bar Vinhos Limpeza].each do |name|
  Sector.find_or_create_by!(name: name)
end

# Units — source: "Listas" tab, column C ("Unidades"). Each entry is
# [abbreviation exactly as it appears in the spreadsheet, descriptive name] —
# the abbreviation is kept verbatim (not normalized/merged) so a future
# import can match products' raw unit text without guessing at equivalences
# the client hasn't confirmed (e.g. "un"/"unid"/"unidade" stay three rows).
[
  [ "kg", "Quilograma" ],
  [ "g", "Grama" ],
  [ "L", "Litro" ],
  [ "un", "Unidade" ],
  [ "unid", "Unidade" ],
  [ "unidade", "Unidade" ],
  [ "garrafa", "Garrafa" ],
  [ "caixa", "Caixa" ],
  [ "caixa 10", "Caixa com 10 unidades" ],
  [ "caixa 12", "Caixa com 12 unidades" ],
  [ "caixa 24", "Caixa com 24 unidades" ],
  [ "fardo", "Fardo" ],
  [ "fardo 6", "Fardo com 6 unidades" ],
  [ "fardo 24", "Fardo com 24 unidades" ],
  [ "pacote", "Pacote" ],
  [ "pacote 6", "Pacote com 6 unidades" ],
  [ "lata", "Lata" ],
  [ "lata 5L", "Lata de 5L" ],
  [ "galão", "Galão" ],
  [ "galão 5L", "Galão de 5L" ],
  [ "barril 30L", "Barril de 30L" ],
  [ "copo 300ml", "Copo de 300ml" ],
  [ "pote", "Pote" ],
  [ "saco", "Saco" ],
  [ "balde", "Balde" ],
  [ "bobina", "Bobina" ],
  [ "dúzia", "Dúzia" ],
  [ "molho", "Molho" ],
  [ "rolo", "Rolo" ],
  [ "refil", "Refil" ],
  [ "maço", "Maço" ],
  [ "bandeja", "Bandeja" ],
  [ "porção", "Porção" ]
].each do |abbreviation, name|
  Unit.find_or_create_by!(abbreviation: abbreviation) do |unit|
    unit.name = name
  end
end

puts "Seeds done: #{Sector.count} sectors, #{Unit.count} units."
