spec = Gem::Specification.new do |s|
  s.name = "ampk"
  s.version = "0.0.4"
  s.author = "Geoff Youngs"
  s.email = "g@intersect-uk.co.uk"
  s.homepage = "http://github.com/livelink/ampk"
  s.platform = Gem::Platform::RUBY
  s.summary = "Simple signed/encrypted archive format library"
  s.files = Dir["{bin,lib}/**/*"].to_a
  s.require_path = "lib"
  s.executables = ['ampk']
  s.description = <<-EOF
  	AMPK is simple archive format which allows contents to be encrypted or signed
	using a public/private key system.
	
	Entities (i.e. files) can be stored encrypted or signed with a private key.
  EOF
end
