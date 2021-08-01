require 'tmpdir'

# Monkey patch permitting use of a world-writable temp directory
# --------------------------------------------------------------
# This is generally going to be a bad idea, as in most situations it reduces
# security. In my case, my web host uses a complicated chroot-style setup which
# they alledge relieves these security issues, and there's no user-serviceable
# way to change the permissions. Do not enable this patch unless you are
# absolutely certain this is reasonable for you.
# Based on Ruby 2.7 code at https://github.com/ruby/ruby/blob/67f1cd20bfb97ff6e5a15d27c8ef06cdb97ed37a/lib/tmpdir.rb#L18-L34

class Dir
  ##
  # Returns the operating system's temporary file path.

  def self.tmpdir
    tmp = nil
    [ENV['TMPDIR'], ENV['TMP'], ENV['TEMP'], @@systmpdir, '/tmp', '.'].each do |dir|
      next unless dir

      dir = File.expand_path(dir)
      begin
        if (stat = File.stat(dir)) && stat.directory? && stat.writable?
          tmp = dir
          break
        end
      rescue StandardError
        nil
      end
    end
    raise ArgumentError, 'could not find a temporary directory' unless tmp

    tmp
  end
end
