$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "two_net/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "two_net"
  s.version     = TwoNet::VERSION
  s.authors     = ["Justin Evaniew"]
  s.email       = ["jevaniew@gmail.com"]
  s.homepage    = "https://github.com/JustinJruby/two_net"
  s.summary     = "Connect to Qualcomm 2Net."
  s.description = "Connect to the Qualcomm 2net system. Setup, Register and track users."

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.0.2"
  s.add_dependency "httparty", "~> 0.13.0"
  s.add_dependency "builder", "3.1.4"

end
