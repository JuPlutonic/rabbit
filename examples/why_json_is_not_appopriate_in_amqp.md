# Serialisation format to choose

Note that because AMQP is a binary protocol, text formats like JSON
  largely lose their advantage of being easy to inspect as data travels across
  the network, so if bandwidth efficiency is important, consider using
  Protocol Buffers or Msgpack or BSON(widely used) or BERT.

  Protocol Buffers: beefcake

  BSON: bson gem for JRuby (implemented as a J.extension). For C-based Rubies?

  Message Pack has Ruby bindings and provides a Java implementation for JRuby

  Bert: format came from Erlang. [Gem](https://github.com/github/bert)

  Thrift: thrift gem - Ruby bindings for the Apache Thrift RPC system

  JSON: json gem part of standard Ruby => 1.9 library or yajl-ruby gem.
 
  XML: Nokogiri for XML processing with Ruby, built on top of libxml2.

> There is interesting gem rabl: "General ruby templating with json,
  bson, xml and msgpack support". Templating?
  Ok, but how about serialisation?

Links:

  http://code.google.com/p/protobuf/

  http://msgpack.org/

  http://bsonspec.org/

  http://bert-rpc.org/

  http://thrift.apache.org/

  [yajl-ruby (bindings to YAJL, streaming JSON parsing and encoding)](
  https://github.com/brianmario/yajl-ruby)

  [Intresting article](https://spin.atomicobject.com/2011/11/23/binary-serialization-tour-guide/)