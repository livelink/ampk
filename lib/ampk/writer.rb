require 'zlib'

class AmpkWriter
	def initialize(path, private_key, &block)
		@fp = File.open(path,'wb')
		write("AMPK")
		@private_key = private_key
		if block_given?
			begin
				yield(self)
			ensure
				close()
			end
		end
	end
	def add_entity(name, data, options = {})
		write_entry("NAME", name)
		write_entry("DLEN", size(data).to_s)
		
		if data.respond_to?(:encoding)
			write_entry("ENCD", data.encoding.name)
			data = data.force_encoding("ASCII-8BIT")
		end
		
		write_entry("TYPE", options[:type] || 'application/octet-stream')
		if options[:sign] || options[:signature]
			write_entry("SIGN", options[:signature] || @private_key.sign(data))
		end
		filter = ""
		if options[:encrypt] || options[:crypt]
			filter << "C"
			data = @private_key.encrypt(data)
		end
		orig_size = size(data)
		if options[:compress] and size(data) > 256
			filter << "Z"
			data = Zlib::Deflate.deflate(data)
		end
		unless filter.empty?
			write_entry('FILT', filter)
		end
		write_size = size(data)
		write_entry("DATA", data)
	end
	
	def close
		write('ENDS')
		@fp.close()
	end
	
	protected
	def size(data)
		sz = data.size
		sz = data.bytesize if data.respond_to?(:bytesize)
		sz
	end
	def write(str)
		@fp.write(str)
	end
	def write_data(data)
		write("#{size(data)}\0")
		write(data)
	end
	def write_entry(name, data)
		write(name)
		write_data(data)
	end
end

