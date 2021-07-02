# frozen_string_literal: true

require_relative "../../lib/generators/install_generator"

RSpec.describe ActiveWebhook::Generators::InstallGenerator do
  before do
    remove_config
    remove_migrations
  end

  it "installs config file properly" do
    described_class.start
    expect(File.file?(config_file)).to be true
    expect(migration_files.count).to eq(1)
    migration_files.each do |migration_file|
      expect(File.file?(migration_file)).to be true
    end
  end
end
