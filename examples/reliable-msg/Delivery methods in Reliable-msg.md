##### Delivery methods in reliable-msg:

Specify the delivery method. By default, it’s “best effort”
`( :best_effort )`,
which means it will try to deliver the message once, and if it fails, the message will be discarded.

Let’s say you wanted a little more resilience.
You decide to change the delivery behavior to repeat delivery six times,
and if it fails,
to place the message in the dead-letter queue:

```
queue.put message, delivery: :repeated
```

You can also set the delivery: argument to be :once, which will try to deliver the
message once, and if it fails,
the message will be placed in the dead-letter queue.

---

These parameters can also be set on Queue objects so that the behavior becomes the default for any message object passed to it:
```
queue = Queue.new('my_queue', delivery: :repeated)
```
This will cause any message put in that queue to be delivered using the repeated
method rather than the default.