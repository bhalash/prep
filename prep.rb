# The MIT License (MIT)
# 
# Copyright (c) 2015 Mark Grealish (mark@bhalash.com)
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# https://github.com/net-ssh/net-scp
require 'net/scp'
# Should be included by default.
require 'optparse'
require 'tmpdir'

# https://github.com/rmagick/rmagick
require 'rmagick'
include Magick

#
# Default Options
#

options = {
  placeholder: 'CHANGE ME',
  sizes: [1024, 840, 768, 640, 424],
  thumb_dir: 'm',
  protocol: 'https',
}

#
# Parse Options
#

optsparse = OptionParser.new do |opts|
  opts.banner = "Usage: ruby ./%s [options]" % __FILE__
  
  opts.on('-h', '--help', 'Display this help menu.') do
    puts "\n#{opts}\n"
    exit
  end

  opts.on('-s', '--sizes [size,size]', Array, 'Srcset image sizes. (Default: %s)' % options[:sizes].join(' ')) do |sizes|
    options[:sizes] = sizes.map(&:to_i)
  end

  opts.on('-l', '--placeholder [text]', 'Hyperlink title and alt placeholder text. (Default: %s)' % options[:placeholder]) do |placeholder|
    options[:placeholder] = placeholder
  end

  opts.on('-r', '--protocol [protocol]', 'Hyperlink protocol. (Default: %s)' % options[:protocol]) do |protocol|
    options[:protocol] = protocol
  end

  opts.on('-t', '--thumbnail-folder [folder]', 'Name of thumbnail subfolder.') do |dir|
    options[:thumb_dir] = dir.split('/')[-1]
  end

  opts.on('-d', '--dir [dir]', 'Name of remote directory.') do |dir|
    options[:prep_dir] = dir.split('/')[-1]
  end

  opts.on('-u', '--user [user@host]', 'scp username and host.') do |login|
    options[:credentials] = login
  end

  opts.on('-f', '--files [file,file]', Array, 'Images to process and upload.') do |files|
    options[:files] = files
  end

  opts.on('-p', '--remote-path [path]', 'scp path to remote parent directory. Separate to destination folder.') do |path|
    options[:path] = path
  end

  opts.on('-o', '--domain [domain.com]', 'Remote domain for hyperlink HTML.') do |domain|
    options[:domain] = domain
  end

  if ARGV.empty?
    puts "\n#{opts}\n"
    exit
  end
end

#
# Return only files in a dir.
#

def dir_files_only dir
  Dir.entries(dir).reject do |file|
    File.directory? file
  end
end

#
# Mogrify Images
# Proportionally /reduce/ file dimensions to size.
# Image will *never* be upscaled.
#

def mog_file file, size
  mog_file = Image.read(file)[0]

  mog_file.change_geometry("#{size}x\>") do |width, height, image|
    image.resize! width, height, Magick::LanczosFilter
  end

  mog_file.write(file) do
    self.quality = 60
    self.interlace = Magick::PlaneInterlace
  end
end

begin
  optsparse.parse!

  # Validate that essential arguments aren't missing.
  missing = [:prep_dir, :credentials, :files, :path, :domain].select do |opt|
    options[opt].nil?
  end

  # unless missing.empty?
  #     puts "\nMissing options: #{missing.join(', ')}"      
  #     puts "\n#{optsparse}\n"
  # end
rescue OptionParser::InvalidOption, OptionParser::MissingArgument
  # Print missing options.
  p $!.to_s
end

Dir.mktmpdir(nil, '/var/tmp/') do |temp|
  options[:files].each do |file|
    # Copy files to temp dir.
    if File.exist? file 
      FileUtils.cp file, temp
    end
  end

  # chdir and create temp
  Dir.chdir(temp)
  Dir.mkdir options[:thumb_dir]

  dir_files_only('.').each_with_index do |file, index|
    # Rename files into sequential numerical order, and copy them to the
    # thumbnail dir for later processing.
    FileUtils.cp file, options[:thumb_dir]
    File.rename file, index.to_s + File.extname(file)
  end

  Dir.chdir options[:thumb_dir]
  
  dir_files_only('.').each_with_index do |file, index|
    # 1. Copy file in numerical order.
    # 2. For each size, shrink file to size and apply other mogrify options.
    options[:sizes].each do |size|
      mog_file_name = '%s_%s.jpg' % [index, size]
      FileUtils.cp file, mog_file_name
      mog_file mog_file_name, size
      # TODO tomorrow: Generate HTML for images.
    end

    FileUtils.rm file
  end

  # Testing.
  exec 'open .'
  sleep 30.seconds
  p dir_files_only '.'
  # Dir.mkdir options[:dir]
end
