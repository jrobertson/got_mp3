#!/usr/bin/env ruby

# file: got_mp3.rb

require 'dxlite'
require 'ostruct'
require 'mp3info'
require 'ogginfo'
require 'playlist_creator'


class GotMP3

  attr_accessor :dir

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

      puts 'add_jpg to directory: ' + directory.inspect if @debug
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

  # Adds an XSPF playlist file to each file directory containing MP3s
  #
  def add_playlist(dir: @dir)

    # .new('/home/james/Music2/Christmas)
    #mp3s = Dir[File.join(@dir, '*.mp3')].sort_by {|x| File.mtime(x)}.reverse
    a = Dir.glob(File.join(dir, '*')).select {|f| File.directory? f}

    tracks = []

    a.each do |dir|

      tracks += add_playlist(dir: dir)

      each_media_track(dir) do |media, trackno, filepath|

        info = case File.extname(filepath)
        when '.mp3'
          mp3info(media)
        when '.ogg'
          ogginfo(media)
        end

        h = {
          title: info[:title],
          location: File.join(File.basename(dir), File.basename(filepath)),
          album: info[:album]
        }

        tracks << h

      end

    end



    pc = PlaylistCreator.new()

    tracks.each do |x|
      pc.add title: x[:title], location: x[:location], album: x[:album]
    end

    File.write File.join(dir,'playlist.xspf'), pc.to_xspf

    return tracks

  end

  # Copies all MP3 directories through the category file-directory stucture.
  # To accomplish this, it need a reference (source) directory containing the
  # .txt for each album.
  #
  def compile(source_directory: '', target_directory: '')

    raise 'target_directory cannot be empty' if target_directory.empty?

    find_by_ext('.txt').each do |directory, _ |

      Dir[File.join(directory, '*.txt')].each do |txt_filename|

        album = File.join(source_directory,
                          File.basename(txt_filename).sub(/\.txt$/,''))
        library_dir = File.join(target_directory, File.basename(directory))
        FileUtils.mkdir_p library_dir

        if @debug then
          puts 'copying from:' + album.inspect
          puts 'copying to: ' + library_dir.inspect
        end

        puts 'copying ' + album + ' ...'
        FileUtils.cp_r album, library_dir, remove_destination: true

      end
    end

  end

  # copy the .txt file from each mp3 directory into a central file directory
  #
  def consolidate_txt(target_directory: '')

    raise 'target_directory cannot be empty' if target_directory.empty?

    find_by_ext('.mp3').each do |directory, _ |

      txt_filename = Dir[File.join(directory, '*.txt')].first

      next unless txt_filename

      target_file = File.basename(directory)
      FileUtils.cp txt_filename, File.join(target_directory,
                                           target_file + '.txt')

    end

  end

  def each_media_file(directory=@dir, &blk)

    puts 'each_media_file - directory: ' + directory.inspect if @debug
    found = Dir[File.join(directory, "*.{mp3,ogg}")].sort_by { |x| File.mtime(x) }
    puts 'each_nedia_file - found: ' + found.inspect if @debug

    found.each.with_index do |media_filepath, i|

      puts 'each_medi... - media_filepath: ' + media_filepath.inspect if @debug

      next unless File.exists? media_filepath

      blk.call(media_filepath, i )

    end

  end

  # Adds the album art, track title, renames the MP3 file, and adds a playlist
  #
  def go()

    find_by_ext('.mp3').each do |directory, _ |

      # find the image file
      img_filename = Dir[File.join(directory, '*.jpg')].first
      puts 'img_filename: ' + img_filename.inspect if @debug

      # find the text file
      txt_filename = Dir[File.join(directory, '*.txt')].first
      next unless txt_filename

      add_image_and_titles(directory, img_filename, txt_filename)

    end

  end

  # rename 1 or more mp3 files within 1 or more file directories
  #
  # example usage:
  #   rename() {|mp3file| mp3files.sub(/Disc \d - /,'')}
  #   rename() {|mp3file| mp3file.sub(/Disc \d - (\d+) - /,'\1. ')}
  #
  def rename()

    each_media_file do |mp3_filepath|

      mp3_directory = File.dirname(mp3_filepath)
      mp3_filename = File.basename(mp3_filepath)

      newname = yield(mp3_filename)
      File.rename(mp3_filepath, File.join(mp3_directory, newname))

    end

  end

  # sort MP3 or OGG by track number in the filename
  #
  def sort_by_tracknum!()

    each_media_file do |filepath|

      directory = File.dirname(filepath)
      a = Dir[File.join(directory, '*.{mp3,ogg}')]
      a.sort_by {|x| x[/^\d+/]}.each {|file| FileUtils.touch file}

    end

  end

  # write either a track listing into the media filepath, either in
  # plain text or XML format.
  #
  def write_titles(format: 'txt')

    puts 'inside write_titles()' if @debug

    find_by_ext('.{mp3,ogg}').each do |directory, _ |

      puts 'write_titles() - directory: ' + directory.inspect if @debug
      txt_filename = Dir[File.join(directory, '*.txt')].first

      next if txt_filename and format.to_sym == :txt

      tracks = []

      each_media_track(directory) do |media, trackno, media_filepath|

        info = case File.extname(media_filepath)
        when '.mp3'
          mp3info(media)
        when '.ogg'
          ogginfo(media)
        end

        info[:filename] = File.basename(media_filepath)
        tracks << OpenStruct.new(info)

      end

      puts 'tracks: ' + tracks.inspect if @debug

      heading = tracks[0].album_artist + ' - ' + tracks[0].album

      s = "# %s\n\n" % [heading]


      if format.to_sym == :txt then

        h = tracks.group_by(&:disc)

        body = if h.length == 1 then

          list(tracks)

        else

          "\n" + h.map do |disc, tracks2|
            ("## Disc %d\n\n" % disc) + list(tracks2) + "\n\n"
          end.join("\n")

        end

        File.write File.join(directory, heading + '.txt'), s + body

      else

        # :xml
        puts 'xml' if @debug

        dx = DxLite.new('album[album_artist, album]/track(tracknum, title, ' +
                                                 'artist, disc, album_artist)')

        #h.each {|_,x| puts x.inspect } if @debug
        #h.each {|_,x| x.each {|track| dx.create(track.to_h) } }
        tracks.each {|track| dx.create(track.to_h) }

        dx.album_artist = dx.all[0].album_artist
        dx.album = dx.all[0].album
        dx.save File.join(directory, 'playlist.dx')

        yield(directory) if block_given?

      end

    end

  end

  private

  # adds album art to each mp3 file in a file directory
  #
  def add_image(directory, img_filename)

    puts 'inside add_image - directory: ' + directory.inspect if @debug
    puts 'img_filename: ' + img_filename.inspect if @debug
    image_file = File.new(File.join(directory, img_filename),'rb')
    img = image_file.read

    each_media_track(directory) do |mp3, _, _|

      mp3.tag2.remove_pictures
      mp3.tag2.add_picture img

    end

  end

  # Modifies the MP3s' tags using the track titles in the .txt file
  #
  def add_tracktitles(directory, txt_filename)

    txt_file = File.join(directory, txt_filename)
    track_titles = File.read(txt_file).lines[1..-1].map(&:strip)

    each_media_track(directory) do |media, trackno, _|

      media.tag.title = track_titles[trackno-1]

    end
  end

  def add_image_and_titles(directory, img_file, txt_file)

    if img_file then
      img = File.new(img_file,'rb').read
    end

    track_titles = File.read(txt_file).lines[1..-1].map(&:strip)

    titles_mp3 = track_titles.map do |title|
      title[/^[^\/]+/].gsub(/:/,'_').rstrip + '.mp3'
    end

    found = Dir[File.join(directory, "*.mp3")].sort_by { |x| File.mtime(x) }
    found.each.with_index do |mp3_filepath, i|

      Mp3Info.open(mp3_filepath) do |mp3|

        if img_file then
          mp3.tag2.remove_pictures
          mp3.tag2.add_picture img
        end

        mp3.tag.title = track_titles[i]
      end

      File.rename(mp3_filepath, File.join(directory, titles_mp3[i]))

    end

    File.write File.join(directory, 'playlist.m3u'), titles_mp3.join("\n")

  end

  def each_media_track(directory, &blk)

    each_media_file(directory) do |filepath, i|

      case File.extname(filepath)
      when '.mp3'
        Mp3Info.open(filepath) {|mp3|  blk.call(mp3, i+1, filepath) }
      when '.ogg'
        OggInfo.open(filepath) {|ogg|  blk.call(ogg, i+1, filepath) }
      end

    end

  end

  def find_by_ext(extension)

    puts 'find_by_ext() - @dir' + @dir.inspect if @debug
    a = Dir[File.join(@dir, "**", "*" + extension)]
    puts 'a: ' + a.inspect if @debug

    a.inject({}) do |r, x|

      r[File.dirname(x)] = File.basename(x)
      r

    end
  end

  # used by public method *write_titles* to list the tracks in plain text
  #
  def list(tracks)

    a = if tracks.map(&:artist).uniq.length < 2 then
      tracks.map {|x| "%02d. %s" % [x.tracknum, x.title] }
    else
      tracks.map {|x| "%02d. %s - %s" % [x.tracknum, x.title, x.artist] }
    end

    a.join("\n")

  end

  def mp3info(mp3)
    {
      title: mp3.tag.title.sub(/^\d+\. */,''),
      artist: mp3.tag.artist,
      album: mp3.tag.album,
      album_artist: mp3.tag2['TPE2'] || mp3.tag.artist,
      disc: mp3.tag2['TPOS'] || 1,
      tracknum: mp3.tag.tracknum,
    }
  end

  def ogginfo(ogg)

    # options
    # ["title", "artist", "tracknumber", "tracktotal", "album", "albumartist",
    #  "genre", "discid", "musicbrainz_discid"]

    {
      title: ogg.tag.title.sub(/^\d+\. */,''),
      artist: ogg.tag.artist,
      album: ogg.tag.album,
      album_artist: ogg.tag.albumartist || ogg.tag.artist,
      disc: ogg.tag.discid || 1,
      tracknum: ogg.tag.tracknumber,
    }
  end

end

class Titles

  def initialize(filename, target_directory: 'titles')
    @titles = File.read filename
    @target_directory = target_directory
  end

  def titleize()
    @titles.gsub(/[\w']+/) {|x| x[0].upcase + x[1..-1]}
  end

  def titleize!()
    @titles.gsub!(/[\w']+/) {|x| x[0].upcase + x[1..-1]}
  end

  def split(target_directory: @target_directory)

    FileUtils.mkdir_p @target_directory
    a = @titles.strip.split(/(?=^#)/)

    a.each do |x|

      filename = x.lines.first.chomp[/(?<=# cd ).*/i].strip + '.txt'
      puts 'processing file ' + filename.inspect
      heading = x.lstrip.lines.first

      tracks = x.strip.lines[1..-1].map.with_index do |line, i|
        "%02d. %s" % [i+1, line]
      end

      File.write File.join(target_directory, filename), heading + tracks.join

    end

    puts 'split done'

  end

end
