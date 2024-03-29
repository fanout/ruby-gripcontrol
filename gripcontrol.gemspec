Gem::Specification.new do |s|
  s.name        = 'gripcontrol'
  s.version     = '1.3.0'
  s.date        = '2023-12-13'
  s.summary     = 'GRIP library for Ruby'
  s.description = 'A Ruby convenience library for using the GRIP protocol'
  s.authors     = ['Konstantin Bokarius']
  s.email       = 'bokarius@comcast.net'
  s.files       = ['lib/gripcontrol.rb', 'lib/websocketmessageformat.rb',
      'lib/websocketevent.rb', 'lib/httpstreamformat.rb', 'lib/channel.rb',
      'lib/httpresponseformat.rb', 'lib/grippubcontrol.rb', 'lib/response.rb']
  s.homepage    = 'https://github.com/fanout/ruby-gripcontrol'
  s.license     = 'MIT'
  s.required_ruby_version = '>= 1.9.0'
  s.add_runtime_dependency 'pubcontrol', '~> 1.3'
  s.add_runtime_dependency 'jwt', '~> 1.2'
end
