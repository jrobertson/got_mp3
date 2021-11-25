#!/usr/bin/env ruby

# file: got_mp3.rb

require "mp3info"


class GotMP3

  def initialize(dir: '.', debug: false)
    @dir, @debug = dir, debug
  end


  # Adds album art to each MP3 file
  #
  # Example usage:
  #   gotmp3 = GotMP3.new(dir: '/tmp/tree/Da Fustra - Over The Waves To Shetland')
  #   gotmp3.add_jpg
  #
  def add_jpg()

    find_by_ext('.jpg').each do |directory, img_filename|
      add_image directory, img_filename
    end

  end

  # Adds a track title to each MP3 file
  #
  # Example usage:
  #   gotmp3 = GotMP3.new(dir: '/tmp/tree/Da Fustra - Over The Waves To Shetland')
  #   gotmp3.add_titles
  #
  def add_titles()

    find_by_ext('.txt').each do |directory, txt_filename|
      add_tracktitles directory, txt_filename
    end

  end

  # Adds the album art, track title, and renames the MP3 file
  #
  def go()

    find_by_ext('.mp3').each do |directory, _ |

      # find the image file
      img_filename = Dir[File.join(directory, '*.jpg')].first

      # find the text file
      txt_filename = Dir[File.join(directory, '*.txt')].first
      next unless txt_filename

      add_image_and_titles(directory, img_filename, txt_filename)

    end

  end

  private

  # adds album art to each mp3 file in a file directory
  #
  def add_image(directory, img_filename)

    image_file = File.new(File.join(directory, img_filename),'rb')
    img = image_file.read

    each_mp3(directory) do |mp3, _, _|

      mp3.tag2.remove_pictures
      mp3.tag2.add_picture img

    end

  end

  def add_tracktitles(directory, txt_filename)

    txt_file = File.join(directory, txt_filename)
    track_titles = File.read(txt_file).lines[1..-1].map(&:strip)

    each_mp3(directory) do |mp3, trackno, _|

      mp3.tag.title = track_titles[trackno-1]

    end
  end

  def add_image_and_titles(directory, img_file, txt_file)

    if img_file then
      img = File.new(img_file,'rb').read
    end

    track_titles = File.read(txt_file).lines[1..-1].map(&:strip)

    found = Dir[File.join(directory, "*.mp3")].sort_by { |x| File.mtime(x) }
    found.each.with_index do |mp3_filepath, i|

      Mp3Info.open(mp3_filepath) do |mp3|

        if img_file then
          mp3.tag2.remove_pictures
          mp3.tag2.add_picture img
        end

        mp3.tag.title = track_titles[i]
      end

      File.rename(mp3_filepath, File.join(directory,
                    track_titles[i][/^[^\/]+/].gsub(/:/,'_').rstrip + '.mp3'))
    end

  end

  def each_mp3(directory, &blk)

    found = Dir[File.join(directory, "*.mp3")].sort_by { |x| File.mtime(x) }
    found.each.with_index do |mp3_filepath, i|

      Mp3Info.open(mp3_filepath) {|mp3|  blk.call(mp3, i+1, mp3_filepath) }

    end

  end

  def find_by_ext(extension)

    a = Dir[File.join(@dir, "**", "*" + extension)]
    puts 'a: ' + a.inspect if @debug

    a.inject({}) do |r, x|

      r[File.dirname(x)] = File.basename(x)
      r

    end
  end

end
