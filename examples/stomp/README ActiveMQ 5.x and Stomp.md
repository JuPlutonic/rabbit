### ActiveMQ:

====

ActiveMQ started as a open source Java Message Service ( JMS )  implementation, so at its core all JMS concepts like *queues*, *topics* and *durable subscriptions* are implemented as the first-class citizens.

It's all based on OpenWire protocol developed within the project
and even KahaDB message store is OpenWire centric.

This means that all other supported protocols,
like MQTT and AMQP are translated internally into OpenWire.

You can connect to Active MQ in a variety of ways, including REST and XMPP,
but it is more convienent to use the JMS API with JRuby.

With MRI Ruby it's better to use **gem Stomp** to interoperate with ActiveMQ
message broker.



### Stomp:

====

STOMP stands for The Streaming Text Orientated Messaging Protocol.

It defines an [interoperable wire format](http://stomp.github.io/stomp-specification-1.1.html) and supports *ack*, *nack*, *begin* - *commit* - *abort* for transactional sending, etc.

It’s an open protocol that supports a variety of messaging brokers and
programming languages, and, in combination with StompConnect,
it is possible to use any other messaging broker that supports the JMS API.



### Other message brokers:

1. StimpConnect: provides a bridge to any other JMS provider.

2. StompServer: a pure ruby StompServer so no need to use another protocol's server just run `gem install stompserver`.

3. RabbitMQ via [plugin](http://www.rabbitmq.com/plugins.html#rabbitmq-stomp). 

====

> See also STOMP over WebSockets realizations: http://jmesnil.net/stomp-websocket/doc/




















