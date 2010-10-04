require 'mime/types'
require 'mongoid'
module Mongoid
  module Grid

    def self.included(base)
      base.send(:extend,  ClassMethods)
      base.send(:include, InstanceMethods)
    end

    module ClassMethods

      ##
      # Declare an attachment for the object
      #
      # eg: attachment :image
      def attachment(name,prefix='grid')
        ##
        # Callbacks to handle the attachment saving and deleting
        after_save     :create_attachments
        after_save     :delete_attachments
        after_destroy  :destroy_attachments

        ##
        # Fields for the attachment.
        #
        # Only the _id is really needed, the others are helpful cached
        # so you don't need to hit GridFS
        field "#{name}_id".to_sym,   :type => BSON::ObjectId
        field "#{name}_name".to_sym, :type => String
        field "#{name}_size".to_sym, :type => Integer
        field "#{name}_type".to_sym, :type => String

        ##
        # Add this name to the attachment_types
        attachment_types.push(name).uniq!

        ##
        # Return the GridFS object.
        # eg: image.filename, image.read
        define_method(name) do
          grid.get(attributes["#{name}_id"]) if attributes["#{name}_id"]
        end

        ##
        # Create a method to set the attachment
        # eg: object.image = File.open('/tmp/somefile.jpg')
        define_method("#{name}=") do |file|
          if file.respond_to?(:read)
            send(:create_attachment, name, file)
          else
            send(:delete_attachment, name, send("#{name}_id"))
          end
        end

        ##
        # Return the relative URL to the file for use with Rack::Grid
        # eg: /grid/4ba69fde8c8f369a6e000003/somefile.png
        define_method("#{name}_url") do
          _id   = send("#{name}_id")
          _name = send("#{name}_name")
          ["/#{prefix}", _id, _name].join('/') if _id && _name
        end

      end

      ##
      # Accessor to GridFS
      def grid
        @grid ||= Mongo::Grid.new(Mongoid.database)
      end

      ##
      # All the attachments types for this class
      def attachment_types
        @attachment_types ||= []
      end

    end

    module InstanceMethods

      private
      ##
      # Accessor to GridFS
      def grid
        @grid ||= self.class.grid
      end

      ##
      # Holds queue of attachments to create
      def create_attachment_queue
        @create_attachment_queue ||= {}
      end

      ##
      # Holds queue of attachments to delete
      def delete_attachment_queue
        @delete_attachment_queue ||= {}
      end

      ##
      # Attachments we need to add after save.
      def create_attachment(name,file)
        if file.respond_to?(:read)
          filename = file.respond_to?(:original_filename) ?
                     file.original_filename : File.basename(file.path)
          type = MIME::Types.type_for(filename).first
          mime = type ? type.content_type : "application/octet-stream"
          send("#{name}_id=",   BSON::ObjectId.new)
          send("#{name}_name=", filename)
          send("#{name}_size=", File.size(file))
          send("#{name}_type=", mime)
          create_attachment_queue[name] = file
        end
      end

      ##
      # Save an attachment to GridFS
      def create_grid_attachment(name,file)
        grid.put(
          file.read,
          :filename => attributes["#{name}_name"],
          :content_type => attributes["#{name}_type"],
          :_id => attributes["#{name}_id"]
        )
        create_attachment_queue.delete(name)
      end

      ##
      # Attachments we need to remove after save
      def delete_attachment(name,id)
        delete_attachment_queue[name] = id if id.is_a?(BSON::ObjectId)
        send("#{name}_id=", nil)
        send("#{name}_name=", nil)
        send("#{name}_size=", nil)
        send("#{name}_type=", nil)
      end

      ##
      # Delete an attachment from GridFS
      def delete_grid_attachment(name,id)
        grid.delete(id) if id.is_a?(BSON::ObjectId)
        delete_attachment_queue.delete(name)
      end

      ##
      # Create attachments marked for creation
      def create_attachments
        create_attachment_queue.each {|k,v| create_grid_attachment(k,v)}
      end

      ##
      # Delete attachments marked for deletion
      def delete_attachments
        delete_attachment_queue.each {|k,v| delete_grid_attachment(k,v)}
      end

      ##
      # Deletes all attachments from document
      def destroy_attachments
        self.class.attachment_types.each do |name|
          delete_attachment(name, send("#{name}_id"))
        end
      end
    end
  end
end
