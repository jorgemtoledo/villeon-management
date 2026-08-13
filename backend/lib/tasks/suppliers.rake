namespace :suppliers do
  desc "Importa fornecedores da aba Fornecedores. Uso: rake suppliers:import[/caminho/arquivo.xlsx] DRY_RUN=true"
  task :import, [ :path ] => :environment do |_task, args|
    path = args[:path].presence || "/docs/data/MAPA COMPRAS.xlsx"
    dry_run = ActiveModel::Type::Boolean.new.cast(ENV["DRY_RUN"]) || false

    report = Importers::SupplierImporter.new(path, dry_run: dry_run).call

    puts report
  end
end
