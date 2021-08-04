require 'digest/sha2'
require 'fileutils'
require 'tmpdir'
require 'yaml'

module WaybackClassic
  class WebClient
    class Cache
      CACHE_VALID_DURATION = 60 * 60 * 24

      class << self
        attr_accessor :enabled, :cache_dir
      end

      @enabled = true
      @cache_dir = File.join(Dir.tmpdir, 'webclient-cache')

      def self.get(uri)
        return unless @enabled

        dir_name = generate_dir_name uri

        return unless Dir.exist? dir_name

        return if File.mtime(dir_name) < Time.now - CACHE_VALID_DURATION

        meta_name = File.join(dir_name, 'meta.yml')
        body_name = File.join(dir_name, 'body')

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

        dir_name = generate_dir_name uri

        # We'll base cache freshness on the directory's modification time
        if Dir.exist? dir_name
          FileUtils.touch dir_name
        else
          FileUtils.mkdir_p dir_name
        end

        meta = response.meta
        meta[:status] = response.status
        meta[:base_uri] = response.base_uri.to_s

        File.open(File.join(dir_name, 'meta.yml'), 'w') do |file|
          YAML.dump(meta, file)
        end

        File.open(File.join(dir_name, 'body'), 'w') do |file|
          file.write response.read
        end

        response.rewind

        response
      end

      def self.generate_dir_name(uri)
        File.join @cache_dir, uri.host, Digest::SHA256.hexdigest(uri.to_s)
      end

      def self.clean(verbose: false)
        delete_before = Time.now - CACHE_VALID_DURATION
        puts "Deleting files older than #{delete_before}" if verbose

        Dir.glob(File.join(@cache_dir, '*', '*')).each do |dir_name|
          mtime = File.mtime(dir_name)
          delete = mtime < delete_before
          puts "\"#{dir_name}\" (#{mtime}): #{delete ? 'DELETE' : 'Keep'}" if verbose

          FileUtils.rm_r dir_name if delete
        end
      end
    end
  end
end
