class AmpkReader
	attr_reader :items, :path
	def initialize(path, public_key)
		@fp = File.open(@path=path,'rb')
		@public_key = public_key
	end
	def verify!(verify_data=false)
		@fp.rewind
		must('start AMPK') { read4 == 'AMPK' }
		until @fp.eof?
			break if peek4 == 'ENDS'
			name = verify_entry('NAME', true)
			headers = {}
			signature = nil
			
			until (header = peek4).eql?('DATA')
				headers[header] ||= 0
				headers[header] += 1
				raise "Duplicate #{header} entry for #{name}" if headers[header] > 1
				
				case header
				when 'FILT', 'DLEN', 'TYPE'
					verify_entry(header, false)
				when 'SIGN'
					signature = verify_entry('SIGN', true)
				end
			end
			
			if signature
				verify_entry_with_sig('DATA', verify_data, signature)
			else
				verify_entry('DATA', verify_data)
			end
		end
	end
	def entities
		auto_scan
		@items.map { |item| item[:name] }
	end
	def entity_signed?(name)
		entity(name).has_key?(:signature)
	end
	def entity_encrypted?(name)
		item = entity(name)
		item.has_key?(:filter) and item[:filter].include?(?C)
	end
	def entity_compressed?(name)
		item = entity(name)
		item.has_key?(:filter) and item[:filter].include?(?Z)
	end
	def entity_size(name)
		entity(name)[:length]
	end
	alias :entity_length :entity_size
	def entity_type(name)
		entity(name)[:type]
	end
	def entity(name)
		auto_scan
		item = @items.find { |item| item[:name] == name }
		raise Errno::ENOENT, name if item.nil?
		item
	end
	def read_entity(name)
		auto_scan unless @items
		item = @items.find { |item| item[:name] == name }
		raise Errno::ENOENT, name if item.nil?
		read_entity_data(item)
	end
	def close
		@fp.close
	end
	
	protected
	def auto_scan
		read_headers unless @items
		nil
	end

	def read_headers
		@fp.rewind
		must('start AMPK') { read4 == 'AMPK' }
		@items = []
		until @fp.eof?
			break if peek4 == 'ENDS'
			@items << read_entity_header()
			skip_entry('DATA')
		end
		@items
	end
	
	def read_entity_header
		start = @fp.tell
		name = read_entry('NAME')
		item = { :name => name, :header => start }
		until (header=peek4).eql?('DATA')
			case header
			when 'SIGN'
				item[:signature] = read_entry(header)
			when 'DLEN'
				item[:length] = read_entry(header).to_i
			when 'FILT'
				item[:filter] = read_entry(header)
			when 'TYPE'
				item[:type] = read_entry(header)
			else
				raise RuntimeError, "Unknown/invalid header #{header}"
			end
		end
		item[:offset] = @fp.tell
		item
	end
	
	def read_entity_data(item)
		@fp.seek(item[:offset])
		data = read_entry('DATA')
		
		if item[:filter]
			item[:filter].reverse.each_byte do |byte|
				case byte
				when ?Z
					data = Zlib::Inflate.inflate(data)
				when ?C
					data = @public_key.decrypt(data)
				end
			end
		end
		
		if item[:signature]
			if @public_key.verify(item[:signature], data)
				return data
			else
				raise RuntimeError, "Invalid data for #{item[:name]}"
			end
		else
			return data
		end
	end
	
	def read_entry(name)
		must("have a #{name} entry") { read4 == name }
		size, data = read_data
		must("have some #{name} data") { size == data.size }
		data
	end
	
	def skip_entry(name)
		must("have a #{name} entry'") { read4 == name }
		size, skipped = skip_data
		must("have some #{name} data") { size == skipped }
		nil
	end
	
	def verify_entry(name, verify_data)
		must("have a #{name} entry") { read4 == name }
		if verify_data
			size, data = read_data
			must("have some #{name} data") { size == data.size }
			data
		else
			size, skipped = skip_data
			must("have at least as much data left") { skipped == size }
			nil
		end
	end
	
	def verify_entry_with_sig(name, verify_data, sig)
		data = verify_entry(name, verify_data)
		if data and sig
			must('be valid, signed data') { @public_key.verify(sig, data) }
		end
	end
	
	def must(description,&block)
		raise RuntimeError, "Archive is invalid: It must #{description}" unless yield
	end
	
	def read4
		str = @fp.read(4)
		str
	end
	
	def peek4
		pos = @fp.tell
		str = @fp.read(4)
		@fp.seek(pos, IO::SEEK_SET)
		str
	end
	
	def read_data_size
		size = ""
		while (c = @fp.getc).nonzero?
			size << c
		end
		size.to_i		
	end
	
	def read_data
		size = read_data_size
		data = @fp.read(size)
		[size, data]
	end
	
	def skip_data
		size = read_data_size
		posn = @fp.tell
		@fp.seek(size, IO::SEEK_CUR)
		skipped = @fp.tell - posn
		[size, skipped]
	end
end

