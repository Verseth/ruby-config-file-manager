# frozen_string_literal: true

require_relative 'lib/config_file_manager/version'

Gem::Specification.new do |spec|
  spec.name = 'config_file_manager'
  spec.version = ConfigFileManager::VERSION
  spec.authors = ['Mateusz Drewniak']
  spec.email = ['matmg24@gmail.com']

  spec.summary = 'Gem that makes it easy to load config files.'
  spec.description = spec.summary
  spec.homepage = 'https://github.com/Verseth/ruby-config-loader'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.3.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/Verseth/ruby-config-loader'
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  spec.add_dependency 'pastel', '~> 0.8'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata['rubygems_mfa_required'] = 'true'
end
