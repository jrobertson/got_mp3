Gem::Specification.new do |s|
  s.name = 'got_mp3'
  s.version = '0.4.0'
  s.summary = 'A ruby-mp3info wrapper to make it convenient to update the ' +
      'album art and track titles of multiple MP3 files in a batch process.'
  s.authors = ['James Robertson']
  s.files = Dir['lib/got_mp3.rb']
  s.add_runtime_dependency('dxlite', '~> 0.3', '>=0.3.5')
  s.add_runtime_dependency('ruby-mp3info', '~> 0.8', '>=0.8.10')
  s.add_runtime_dependency('ruby-ogginfo', '~> 0.7', '>=0.7.2')
  s.add_runtime_dependency('playlist_creator', '~> 0.2', '>=0.2.0')
  s.signing_key = '../privatekeys/got_mp3.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'digital.robertson@gmail.com'
  s.homepage = 'https://github.com/jrobertson/got_mp3'
end
