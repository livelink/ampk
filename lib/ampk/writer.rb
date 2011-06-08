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
		write_entry("DLEN", data.size.to_s)
		write_entry("TYPE", options[:type] || 'application/octet-stream')
		if options[:sign] || options[:signature]
			write_entry("SIGN", options[:signature] || @private_key.sign(data))
		end
		filter = ""
		if options[:encrypt] || options[:crypt]
			filter << "C"
			data = @private_key.encrypt(data)
		end
		orig_size = data.size
		if options[:compress] and data.size > 256
			filter << "Z"
			data = Zlib::Deflate.deflate(data)
		end
		unless filter.empty?
			write_entry('FILT', filter)
		end
		write_size = data.size
		write_entry("DATA", data)
	end
	
	def close
		write('ENDS')
		@fp.close()
	end
	
	protected
	def write(str)
		@fp.write(str)
	end
	def write_data(data)
		write("#{data.size}\0")
		write(data)
	end
	def write_entry(name, data)
		write(name)
		write_data(data)
	end
end

