Gem::Specification.new do |s|
  s.name = "xbuilder"
  s.version = "0.9"
  s.authors = ["Nikita Afanasenko"]
  s.email = ["nikita@afanasenko.name"]
  s.homepage = "http://github.com/nikitug/xbuilder"

  s.summary = "API-compatible Builder implementation using libxml."

  s.files = Dir["lib/**/*.rb"] + Dir["test/**/*"] + %w[Gemfile README.rdoc Rakefile]
  s.test_files = Dir["test/**/*"]
  s.require_paths = ["lib"]
  s.extra_rdoc_files = ["README.rdoc"]

  s.add_runtime_dependency "blankslate"
  s.add_runtime_dependency "libxml-ruby", ">= 2.3.4"

  s.add_development_dependency "rdoc", "~> 3.12"
  s.add_development_dependency "rake"
  s.add_development_dependency "bundler"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "nokogiri"
  s.add_development_dependency "builder"
end
