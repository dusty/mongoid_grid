require 'timeout'
require 'mongo'

module Rack
  class Grid
    class ConnectionError < StandardError ; end

    attr_reader :host, :port, :database, :prefix, :username, :password

    def initialize(app, options = {})
      opts = {}
      options.each { |k,v|  opts[k.to_s] = v }
      options = {
        'host'    => 'localhost',
        'prefix'  => 'grid',
        'port'    => Mongo::Connection::DEFAULT_PORT
      }.merge(opts)

      @app        = app
      @host       = options['host']
      @port       = options['port']
      @database   = options['database']
      @prefix     = options['prefix']
      @username   = options['username']
      @password   = options['password']
      @db         = options['db']
    end

    def db
      @db = @db.call()  if Proc === @db
      connect!  unless @db
      @db
    end

    ##
    # Strip the _id out of the path.  This allows the user to send something
    # like /grid/4ba69fde8c8f369a6e000003/filename.jpg to find the file
    # with an id of 4ba69fde8c8f369a6e000003.
    def call(env)
      request = Rack::Request.new(env)
      if request.path_info =~ /^\/#{prefix}\/(\w+).*$/
        grid_request($1)
      else
        @app.call(env)
      end
    end

    ##
    # Get file from GridFS or return a 404
    def grid_request(id)
      file = Mongo::Grid.new(db).get(BSON::ObjectId.from_string(id))
      [200, {'Content-Type' => file.content_type}, [file.read]]
    rescue Mongo::GridError, BSON::InvalidObjectId
      [404, {'Content-Type' => 'text/plain'}, ['File not found.']]
    end

    private
    def connect!
      Timeout::timeout(5) do
        @db = Mongo::Connection.new(host,port).db(database)
        db.authenticate(username, password) if (username || password)
      end
    rescue StandardError => e
      raise ConnectionError, "Timeout connecting to GridFS (#{e.to_s})"
    end

  end
end
