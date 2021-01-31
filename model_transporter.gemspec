lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "model_transporter/version"

Gem::Specification.new do |spec|
  spec.name          = "model_transporter"
  spec.version       = ModelTransporter::VERSION
  spec.authors       = ["Andrew Warner"]
  spec.email         = ["wwarner.andrew@gmail.com"]

  spec.summary       = %q{Notifies listeners about model changes}
  spec.description   = %q{Notifies listeners about model changes}
  spec.homepage      = "https://github.com/a-warner/model_transporter"
  spec.license       = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/a-warner/model_transporter"
  spec.metadata["changelog_uri"] = "https://github.com/a-warner/model_transporter/blob/main/README.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "listen"
  spec.add_development_dependency "sqlite3", "~> 1.4"
  spec.add_development_dependency "sass-rails", '>= 6'
  spec.add_development_dependency "webpacker", "~> 4.0"
  spec.add_development_dependency "pry"

  spec.add_dependency "rails", "~> 6.0"
  spec.add_dependency "request_store"
end
