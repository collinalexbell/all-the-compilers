
def write_md5_digest_file(filename)
  require 'digest/md5'

  digest_file = "#{filename}.md5"
  File.open(digest_file, "w") do |f|
    f.puts Digest::MD5.file(filename).hexdigest
  end

  puts "Computed MD5 to #{digest_file}"
end

def write_sha1_digest_file(filename)
  require 'digest/sha1'

  digest_file = "#{filename}.sha1"
  File.open(digest_file, "w") do |f|
    f.puts Digest::SHA1.file(filename).hexdigest
  end

  puts "Computed SHA1 to #{digest_file}"
end

def write_sha512_digest_file(filename)
  require 'digest/sha2'

  digest_file = "#{filename}.sha512"
  File.open(digest_file, "w") do |f|
    f.puts Digest::SHA512.file(filename).hexdigest
  end

  puts "Computed SHA512 to #{digest_file}"
end

def rbx_version
  release_revision.first
end

class RubiniusPackager
  attr_writer :prefix, :root, :bin, :config, :archive, :package

  def initialize(options={})
    @prefix = options[:prefix]
    @root = options[:root]
    @bin = options[:bin]
    @config = options[:config]
    @archive = options[:archive]
    @package = options[:package]
  end

  # passed verbatim to --prefix
  def prefix
    default = "/rubinius/#{rbx_version}"
    @prefix || default
  end

  # root directory of the build
  def root
    @root ||= BUILD_CONFIG[:builddir][0...-BUILD_CONFIG[:prefixdir].size]
  end

  # path for a binary symlink
  def bin
    @bin
  end

  # any configure options
  def config
    config = ["--prefix=#{prefix} --preserve-prefix"]
    config << @config
    config.join(" ")
  end

  # "zip", "tar.gz", "tar.bz2"
  def archive
    @archive || "tar.bz2"
  end

  # name of the final package file minus #archive
  def package
    default = "rubinius-#{rbx_version}"
    @package || default
  end

  def create_archive(package_name)
    name = "#{BUILD_CONFIG[:sourcedir]}/#{package_name}"

    Dir.chdir root do
      case archive
      when "zip"
        sh "zip --symlinks -r #{name} *"
      when "tar.gz"
        sh "tar -c -f - * | gzip > #{name}"
      when "tar.bz2"
        sh "tar -c -f - * | bzip2 -9 > #{name}"
      else
        raise RuntimeError, "unknown archive format: #{archive}"
      end
    end
  end

  def build
    package_name = package + "." + archive
    sh "rm -rf #{package_name}*"

    ENV["RELEASE"] = "1"
    sh "./configure #{config}"
    load_configuration

    sh "rake -q clean"
    sh "rake -q build"

    sh "strip -S #{BUILD_CONFIG[:build_exe]}" unless BUILD_CONFIG[:debug_build]

    if bin
      sh "mkdir -p #{root}#{File.dirname(bin)}"

      bin = "#{prefix}#{BUILD_CONFIG[:bindir]}"
      bin_link = "#{root}#{bin}"

      sh "ln -sf #{bin} #{bin_link}"
    end

    create_archive package_name
    write_sha512_digest_file package_name
  rescue Object => e
    # Some rake versions swallow the backtrace, so we do it explicitly.
    STDERR.puts e.message, e.backtrace
  end
end
