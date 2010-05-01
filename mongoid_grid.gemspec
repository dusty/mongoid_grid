Gem::Specification.new do |s| 
  s.name = "mongoid_grid" 
  s.version = "0.0.2" 
  s.author = "Dusty Doris" 
  s.email = "github@dusty.name" 
  s.homepage = "http://code.dusty.name" 
  s.platform = Gem::Platform::RUBY
  s.summary = "Plugin for Mongoid to use GridFS and a Rack helper" 
  s.description = "Plugin for Mongoid to use GridFS and a Rack helper" 
  s.files = [
    "README.txt",
    "lib/mongoid/grid.rb",
    "lib/rack/grid.rb",
    "test/test_mongoid_grid.rb",
    "test/test_rack_grid.rb"
  ]
  s.has_rdoc = true 
  s.extra_rdoc_files = ["README.txt"]
  s.add_dependency('mime-types')
  s.add_dependency('mongoid', ">= 2.0.0.beta4")
  s.rubyforge_project = "none"
end
