require "rails_helper"
require "rake"

RSpec.describe "products:import rake task" do
  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  after do
    Rake::Task["products:import"].reenable
    Rake::Task["products:import_subcategories"].reenable
    ENV.delete("DRY_RUN")
  end

  it "defaults to the in-container mounted spreadsheet path and DRY_RUN=false when not given" do
    fake_report = instance_double(Importers::ProductCatalogImporter::Report, to_s: "relatório padrão")
    fake_importer = instance_double(Importers::ProductCatalogImporter, call: fake_report)
    allow(Importers::ProductCatalogImporter).to receive(:new)
      .with("/docs/data/MAPA COMPRAS.xlsx", dry_run: false)
      .and_return(fake_importer)

    expect { Rake::Task["products:import"].invoke }.to output(/relatório padrão/).to_stdout
  end

  it "passes a custom path and honors DRY_RUN=true" do
    fake_report = instance_double(Importers::ProductCatalogImporter::Report, to_s: "relatório dry run")
    fake_importer = instance_double(Importers::ProductCatalogImporter, call: fake_report)
    allow(Importers::ProductCatalogImporter).to receive(:new)
      .with("/tmp/outro.xlsx", dry_run: true)
      .and_return(fake_importer)

    ENV["DRY_RUN"] = "true"

    expect { Rake::Task["products:import"].invoke("/tmp/outro.xlsx") }.to output(/relatório dry run/).to_stdout
  end
end

RSpec.describe "products:import_subcategories rake task" do
  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  after do
    Rake::Task["products:import_subcategories"].reenable
    ENV.delete("DRY_RUN")
  end

  it "defaults to the in-container mounted spreadsheet path and DRY_RUN=false when not given" do
    fake_report = instance_double(Importers::ProductSubcategoryImporter::Report, to_s: "relatório padrão")
    fake_importer = instance_double(Importers::ProductSubcategoryImporter, call: fake_report)
    allow(Importers::ProductSubcategoryImporter).to receive(:new)
      .with("/docs/data/MAPA COMPRAS.xlsx", dry_run: false)
      .and_return(fake_importer)

    expect { Rake::Task["products:import_subcategories"].invoke }.to output(/relatório padrão/).to_stdout
  end

  it "passes a custom path and honors DRY_RUN=true" do
    fake_report = instance_double(Importers::ProductSubcategoryImporter::Report, to_s: "relatório dry run")
    fake_importer = instance_double(Importers::ProductSubcategoryImporter, call: fake_report)
    allow(Importers::ProductSubcategoryImporter).to receive(:new)
      .with("/tmp/outro.xlsx", dry_run: true)
      .and_return(fake_importer)

    ENV["DRY_RUN"] = "true"

    expect { Rake::Task["products:import_subcategories"].invoke("/tmp/outro.xlsx") }.to output(/relatório dry run/).to_stdout
  end
end
