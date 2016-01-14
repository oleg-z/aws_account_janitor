# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'aws_account_janitor/version'

Gem::Specification.new do |spec|
  spec.name          = "aws_account_janitor"
  spec.version       = AwsAccountJanitor::VERSION
  spec.authors       = ["Oleg Z"]
  spec.email         = ["olegz@alertlogic.com"]
  spec.summary       = %q{"Report AWS resources not matching usage filters"}
  spec.description   = %q{Write a longer description. Optional.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "pry"

  spec.add_dependency "aws-sdk"
end
