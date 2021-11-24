#!/usr/bin/env ruby
# file: got_mp3.rb

require "mp3info"


class GotMP3

  def initialize(dir: '.', debug: false)
    @dir, @debug = dir, debug
  end


  # Example usage:
  #   gotmp3 = GotMP3.new(dir: '/tmp/tree/Da Fustra - Over The Waves To Shetland')
  #   gotmp3.add_jpg
  # 
  def add_jpg()

    a = Dir[File.join(@dir, "**", "*.jpg")]
    puts 'a: ' + a.inspect if @debug
    directories = a.inject({}) {|r, x| r[File.dirname(x)] = File.basename(x); r }

    directories.each do |directory, img_filename|
      add_image directory, img_filename
    end

  end

  private

  # adds album art to each mp3 file in a file directory
  #
  def add_image(directory, img_filename)

    image_file = File.new(File.join(directory, img_filename),'rb') 
    img = image_file.read

    each_mp3(directory) do |mp3|

      mp3.tag2.remove_pictures
      mp3.tag2.add_picture img

    end

  end

  def each_mp3(directory, &blk)

    Dir[File.join(directory, "*.mp3")].each do |mp3_filepath|

      Mp3Info.open mp3_filepath do |mp3|
        blk.call mp3
      end

    end

  end

end
