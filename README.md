# Introducing the got_mp3 gem

This gem aims to make it convenient to add album art or change titles for Mp3 files in a file directory.

Usage:

    require 'got_mp3'

    gotmp3 = GotMP3.new(dir: '/home/james/Music/The Best of Scottish Dance Bands')
    gotmp3.add_jpg # writes the jpg file in the file directory to each MP3 file

    # Rename the MP3 file
    gotmp3.rename() {|mp3file| mp3file.sub(/Disc \d - (\d+) - /,'\1. ')}

    # Add a title for each MP3 track from a .txt file in the same directory
    gotmp3.add_titles

    # Add the album art, modify the track title and rename the MP3 file
    gotmp3.go

    # write the track title to a .txt file in the same directory
    gotmp3.write_titles

## Resources

* got_mp3 https://rubygems.org/gems/got_mp3

gotmp3 got_mp3 mp3 mp3info audio music 
