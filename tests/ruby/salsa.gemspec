# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "salsa"
  spec.version       = "0.0.1"
  spec.authors       = ["Grant Birkinbine"]
  spec.license       = "MIT"

  spec.summary       = "A test gem"
  spec.description   = <<~SPEC_DESC
    It does nothing
  SPEC_DESC

  spec.homepage = "https://github.com/github/salsa"
  spec.metadata = {
    "source_code_uri" => "https://github.com/github/salsa",
    "documentation_uri" => "https://github.com/github/salsa",
    "bug_tracker_uri" => "https://github.com/github/salsa/issues"
  }

  spec.required_ruby_version = ">= 2.4"

  spec.files = %w[lib/salsa.rb]
  spec.require_paths = ["tests/ruby/lib"]
end
