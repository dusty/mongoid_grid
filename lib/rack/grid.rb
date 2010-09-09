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

      @cache_control = options['cache_control']
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
      @env = env
      request = Rack::Request.new(@env)
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

      etag, last_modified = file.instance_variable_get(:@md5), Time.at( file.upload_date.to_i )
      headers = {
        'Content-Type' => file.content_type,
        'ETag' => "\"#{etag}\"",
        'Last-Modified' => last_modified.httpdate,
        'Cache-Control' => cache_control_header,
      }

      if not_modified?( etag, last_modified )
        [304, headers, 'Not Modified']
      else
        [200, headers, [file.read]]
      end
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

    DEFAULT_CACHE_CONTROL = "max-age=0, private, must-revalidate"
    def cache_control_header
      if @cache_control.blank?
        DEFAULT_CACHE_CONTROL

      elsif @cache_control[:no_cache]
        'no-cache'

      else
        extras  = @cache_control[:extras]
        max_age = @cache_control[:max_age]

        options = []
        options << "max-age=#{max_age.to_i}"  if max_age
        options << (@cache_control[:public] ? 'public' : 'private')
        options << 'must-revalidate'  if @cache_control[:must_revalidate]
        options.concat(extras) if extras

        options.join(', ')
      end
    end

    def not_modified?( etag, last_modified )
      if_none_match = @env['HTTP_IF_NONE_MATCH']
      if if_modified_since = @env['HTTP_IF_MODIFIED_SINCE']
        if_modified_since = Time.rfc2822( if_modified_since ) rescue nil
      end

      not_modified = if_none_match.present? || if_modified_since.present?
      not_modified &&= (if_none_match == "\"#{etag}\"")       if if_none_match && etag
      not_modified &&= (if_modified_since >= last_modified)   if if_modified_since && last_modified
      not_modified
    end
  end
end
