Gem::Specification.new do |s|
  s.name = "mongoid_grid"
  s.version = "0.0.9"
  s.author = "Dusty Doris"
  s.email = "github@dusty.name"
  s.homepage = "http://github.com/dusty/mongo_grid"
  s.platform = Gem::Platform::RUBY
  s.summary = "Plugin for Mongoid::Document to attach files via GridFS"
  s.description = "Plugin for Mongoid::Document to attach files via GridFS"
  s.files = [
    "README.txt",
    "lib/mongoid_grid.rb",
    "test/test_mongoid_grid.rb"
  ]
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.txt"]
  s.add_dependency('mime-types')
  s.rubyforge_project = "none"
end
