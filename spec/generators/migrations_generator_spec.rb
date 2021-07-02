# frozen_string_literal: true

require_relative "../../lib/generators/migrations_generator"

RSpec.describe ActiveWebhook::Generators::MigrationsGenerator do
  before do
    remove_migrations
  end

  it "installs migration files properly" do
    described_class.start
    expect(migration_files.count).to eq(1)
    migration_files.each do |migration_file|
      expect(File.file?(migration_file)).to be true
    end
  end
end
