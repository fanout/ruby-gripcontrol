Gem::Specification.new do |s|
  s.name        = 'gripcontrol'
  s.version     = '0.0.3'
  s.date        = '2015-01-04'
  s.summary     = 'GRIP library for Ruby'
  s.description = 'A Ruby convenience library for using the GRIP protocol'
  s.authors     = ['Konstantin Bokarius']
  s.email       = 'bokarius@comcast.net'
  s.files       = ['lib/gripcontrol.rb', 'lib/websocketmessageformat.rb',
      'lib/websocketevent.rb', 'lib/httpstreamformat.rb', 'lib/channel.rb',
      'lib/httpresponseformat.rb', 'lib/grippubcontrol.rb']
  s.homepage    = 'http://rubygems.org/gems/gripcontrol'
  s.license     = 'MIT'
  s.required_ruby_version = '>= 1.9.0'
  s.add_runtime_dependency 'pubcontrol', '= 0.0.5'
  s.add_runtime_dependency 'jwt', '= 1.2.0'
end
