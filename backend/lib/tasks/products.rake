namespace :products do
  desc "Importa produtos do Catálogo Mestre. Uso: rake products:import[/caminho/arquivo.xlsx] DRY_RUN=true"
  task :import, [ :path ] => :environment do |_task, args|
    path = args[:path].presence || "/docs/data/MAPA COMPRAS.xlsx"
    dry_run = ActiveModel::Type::Boolean.new.cast(ENV["DRY_RUN"]) || false

    report = Importers::ProductCatalogImporter.new(path, dry_run: dry_run).call

    puts report
  end

  desc "Importa a Subcategoria (coluna D) do Catálogo Mestre e vincula os produtos. " \
       "Uso: rake products:import_subcategories[/caminho/arquivo.xlsx] DRY_RUN=true"
  task :import_subcategories, [ :path ] => :environment do |_task, args|
    path = args[:path].presence || "/docs/data/MAPA COMPRAS.xlsx"
    dry_run = ActiveModel::Type::Boolean.new.cast(ENV["DRY_RUN"]) || false

    report = Importers::ProductSubcategoryImporter.new(path, dry_run: dry_run).call

    puts report
  end
end
