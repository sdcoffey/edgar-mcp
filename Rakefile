# frozen_string_literal: true

# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative 'config/application'

Rails.application.load_tasks

namespace 'javascript' do
  task build: :environment do
    system('bun run build')
  end
end

namespace 'css' do
  task build: :environment do
    system('bun run build:css')
  end
end

if Rake::Task.task_defined?('assets:precompile')
  precompile_task = Rake::Task['assets:precompile']

  precompile_task.prerequisites.push('javascript:build')
  precompile_task.prerequisites.push('css:build')
end
