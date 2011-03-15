Mongoid::Grid

  mongoid_grid is a GridFS plugin for Mongoid::Document

  ***NOTE: The rack helper is no longer included in this project.  If you
  need it, please switch to rack_grid: https://github.com/dusty/rack_grid

Installation

  # git clone https://github.com/dusty/mongoid_grid.git
  # gem build mongoid_grid.gemspec
  # gem install mongoid_grid-0.0.x.gem

Usage

  require 'mongoid_grid'
  class Monkey
    include Mongoid::Document
    include Mongoid::Grid
    field :name
    attachment :image
  end

  m = Monkey.create(:name => 'name')

  # To add an attachment
  m.image = File.open('/tmp/me.jpg')
  m.save

  # To remove an attachment
  m.image = nil
  m.save

  # To get the attachment
  m.image.read

Inspired By
  - http://github.com/jnunemaker/grip

