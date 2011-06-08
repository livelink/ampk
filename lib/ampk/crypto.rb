require 'openssl'
require 'base64'

module Crypto
	def self.create_keys(priv = "dsa_key", pub = "#{priv}", bits = 1024)
		private_key = OpenSSL::PKey::RSA.new(bits)
		File.mkpath('private')
		File.mkpath('public')
		File.open("private/"+priv+".private", "w+") { |fp| fp << private_key.to_s }
		File.open("public/"+pub+".public",  "w+") { |fp| fp << private_key.public_key.to_s }    
		private_key
	end

	class Key
		attr_accessor :digest_string
		def initialize(data, digest_string)
			@public = (data =~ /^-----BEGIN (RSA|DSA) PRIVATE KEY-----$/).nil?
			@prefix = @public ? "public" : "private"
			@key = OpenSSL::PKey::RSA.new(data)
			@digest_string = digest_string
		end
		
		def self.from_file(filename, digest_string)
			self.new(File.read(filename), digest_string)
		end
		
		def encrypt(text)
			Base64.encode64(@key.send("#{@prefix}_encrypt", text))
		end
		
		def decrypt(text)
			@key.send("#{@prefix}_decrypt", Base64.decode64(text))
		end
		
		def sign(data)
			Base64.encode64(@key.sign(digest, data))
		end
		
		def verify(signature, data)
			@key.verify(digest, Base64.decode64(signature), data)
		end
		
		def public?
			@public
		end
		
		def digest
			OpenSSL::Digest::MD5.new(@digest_string)
		end
	end
end


