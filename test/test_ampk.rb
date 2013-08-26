# encoding: utf-8
$: << File.dirname(__FILE__)+"/../lib"
require 'test/unit'
#require 'ampk'
    require 'ampk/crypto'
    require 'ampk/writer'
    require 'ampk/reader'

class TestReadWrite < Test::Unit::TestCase
  def test_create_archive
    private_key = OpenSSL::PKey::RSA.new(1024*4)
    public_key = private_key.public_key

    filename = "/tmp/test-#{$$}-output.ampk"

    e_data = ('secret-words' * 10)
    prikey = Crypto::Key.new(private_key.to_s, "my-secret-word")
    AmpkWriter.new(filename, prikey) do |writer|
      writer.add_entity('file1', ("file1" * 1024), :type => 'text/plain', :sign => true)
      writer.add_entity('large-file', ('file2' * 100), :compress => true, :type => 'text/plain')
      writer.add_entity('secret-file', e_data, :encrypt => true)
      writer.add_entity('alt-file', "£1.00", :encrypt => true)
    end
    
    pubkey = Crypto::Key.new(public_key.to_s, "my-secret-word")
    reader = AmpkReader.new(filename, pubkey)
    assert_equal 4, reader.entities.size
    assert reader.entity_encrypted?('secret-file')
    assert_equal e_data, reader.read_entity('secret-file')
    if RUBY_VERSION >= "1.9"
      encoded = reader.read_entity('alt-file')
      assert_equal 'UTF-8', encoded.encoding.name
      assert_equal '£1.00', encoded
    end

    File.unlink(filename)
  end
end
