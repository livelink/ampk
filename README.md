# AMPK
AMbit PacKage

A simple archive format containing blobs of data with various pieces of meta data relating to the entry.

## Format

Each block starts with a 4 letter word describing it's content

First block (length: 0)
AMPK

...  0 or more entries ...

Last block (length: 0)
ENDS

An entry is one of format:

HEADER (4 bytes)
LENGTH (0 byte terminated)
DATA (N bytes)

HEADER is one of
NAME - data is filename of next DATA entry
DLEN - data is original length of DATA entry (not including compression, etc)
SIGN - data is signature of data (signed using private key)
FILT - data describes data content - "C" => enCrypted (ie. encrypted using private key), "Z" => Zlib compressed.
TYPE - data is mimetype of next DATA entry
ENCD - data is encoding of next DATA entry
DATA - data is the original payload (potentially compressed/encrypted)

## Basic usage

### To create an archive

    require 'ampk/crypto'
    require 'ampk/writer'

    key = Crypto::Key.from_file("private_key.rsa", "my-secret-word")
    AmpkWriter.new("output.ampk", key) do |writer|
      writer.add_entry('file1', File.read('file1'), :type => 'text/plain', :sign => true)
      writer.add_entry('large-file', File.read('file2'), :compress => true, :type => 'text/plain')
      writer.add_entry('secret-file', File.read('secret-words'), :encrypt => true)
    end


### To read an archive

    require 'ampk/crypto'
    require 'ampk/reader'
    
    key = Crypto::Key.from_file("public_key.rsa", "my-secret-word")
    reader = AmpkReader.new("output.ampk", key)
    puts reader.entities
    puts "Was secret-file encrypted? #{ reader.entity_encrypted?('secret-file') }"
    puts "Secret contents: #{ reader.read_entity('secret-file') }"

