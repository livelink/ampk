spec = Gem::Specification.new do |s| 
  s.name = "ampk"
  s.version = "0.0.1"
  s.author = "Geoff Youngs"
  s.email = "g@intersect-uk.co.uk"
  s.homepage = "http://github.com/geoffyoungs/ampk"
  s.platform = Gem::Platform::RUBY
  s.summary = "Template language for generating Ruby bindings for C libraries"
  s.files = Dir["{bin,lib}/**/*"].to_a
  s.require_path = "lib"
  s.description = <<-EOF
  	AMPK is simple archive format which allows contents to be encrypted or signed
	using a public/private key system.
  EOF
end
