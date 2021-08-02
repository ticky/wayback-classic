require 'digest/sha2'
require 'fileutils'
require 'tmpdir'
require 'yaml'

module WaybackClassic
  class WebClient
    class Cache
      CACHE_VALID_DURATION = 60 * 60 * 24

      class << self
        attr_accessor :enabled
      end

      @enabled = true
      @cache_dir = File.join(Dir.tmpdir, 'webclient-cache')

      def self.get(uri)
        return unless @enabled

        file_name = generate_file_name uri

        return unless Dir.exist? file_name

        return if File.mtime(file_name) < Time.now - CACHE_VALID_DURATION

        meta_name = File.join(file_name, 'meta.yml')
        body_name = File.join(file_name, 'body')

        return unless File.exist? body_name

        meta = if File.exist? meta_name
                 File.open(meta_name, 'r') do |file|
                   YAML.safe_load file.read, permitted_classes: [Symbol]
                 end
               end

        response = File.open(body_name, 'r') do |file|
          StringIO.new file.read
        end

        if meta && response
          response.instance_variable_set(:"@meta", meta)

          def response.meta
            @meta
          end

          def response.status
            @meta[:status]
          end

          def response.content_type
            @meta['content-type']
          end

          def response.base_uri
            URI(@meta[:base_uri])
          end
        end

        response
      end

      def self.put(uri, response)
        return response unless @enabled

        file_name = generate_file_name uri

        # We'll base cache freshness on the directory's modification time
        if Dir.exist? file_name
          FileUtils.touch file_name
        else
          FileUtils.mkdir_p file_name
        end

        meta = response.meta
        meta[:status] = response.status
        meta[:base_uri] = response.base_uri.to_s

        File.open(File.join(file_name, 'meta.yml'), 'w') do |file|
          YAML.dump(meta, file)
        end

        File.open(File.join(file_name, 'body'), 'w') do |file|
          file.write response.read
        end

        response.rewind

        response
      end

      def self.generate_file_name(uri)
        File.join @cache_dir, uri.host, Digest::SHA256.hexdigest(uri.to_s)
      end
    end
  end
end
