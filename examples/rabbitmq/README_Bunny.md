### Direct Exchanges and Load Balancing of Messages

Direct exchanges are often used to distribute tasks between multiple workers (instances of the same application) in a round robin manner. When doing so, it is important to understand that, in AMQP 0.9.1, _messages are load balanced between consumers and not between queues_.

The [Queues and Consumers](http://rubybunny.info/articles/queues.html) guide provides more information on this subject.

### Pre-declared direct exchanges

AMQP 0.9.1 brokers must implement a direct exchange type and pre-declare two instances:

* `amq.direct`
* _""_ exchange known as _default exchange_ (unnamed, referred to as an empty string by many clients including Bunny)

Applications can rely on those exchanges always being available to them. Each vhost has separate instances of those exchanges, they are _not shared across vhosts_ for obvious reasons.

### Default exchange

The default exchange is a direct exchange with no name (Bunny refers to it using an empty string) pre-declared by the broker. It has one special property that makes it very useful for simple applications, namely that _every queue is automatically bound to it with a routing key which is the same as the queue name_.

For example, when you declare a queue with the name of "search.indexing.online", RabbitMQ will bind it to the default exchange using "search.indexing.online" as the routing key. Therefore a message published to the default exchange with routing key = "search.indexing.online" will be routed to the queue "search.indexing.online". In other words, the default exchange makes it _seem like it is possible to deliver messages directly to queues_, even though that is not technically what is happening.

> http://rubybunny.info ©
