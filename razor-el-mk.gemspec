# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "razor-mk-agent"
  spec.version       = "0.0.1"
  spec.authors       = ["David Lutterkort"]
  spec.email         = ["lutter@watzmann.net"]
  spec.description   = "The agent for Razor Microkernels"
  spec.summary       = "The OS-independent bits of a Razor Microkernel"
  spec.homepage      = ""
  spec.license       = "ASL2"

  spec.files         = `git ls-files`.split($/)
  spec.bindir        = "bin"
  spec.executables   = ['mk']
  spec.test_files    = spec.files.grep(%r{^spec/})
  spec.require_paths = ["lib"]

  # @todo lutter 2013-08-20: we really do depend on facter, but because of
  # how we build the microkernel, we can't fulfill it from rubygems, and
  # use the RPM packaged facter instead which is not a rubygem
  # spec.add_dependency "facter"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
