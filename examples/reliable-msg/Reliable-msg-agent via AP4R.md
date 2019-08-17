## A tired IT engineer's blog

###### Site: HatenaDiary.org id: hamajyotan date: 2011-04-11

## Execute dispatch via Ap4r in ReliableMsgAgent

###### tags: Ruby reliable-msg-agent

##### ReliableMsgAgent performs "message dispatch via ap4r"

> Gem **ap4r** - Asynchronous Processing for Ruby - is the implementation of reliable asynchronous message processing. It provides message queuing, and message dispatching 
> 
> Docs: https://www.rubydocs.info/gems/ap4r/0.3.7/Ap4r
> 
> Runtime dependencies (3):
> 
> - mongrel >= 0
> 
> - rake >= 0
> 
> - reliable-msg = 1.1.0

- Put a message using [ap4r](https://rubygems.org/gems/ap4r)

- Put message, let reliable-msg-agent autonomously don't dispatch to ap4r. In short, something like ap4r with a pull approach

- In this case, the dispatch method follows the same rules as ap4r.
  
  - For example, ap4r dispatch mode HTTP is considered successful if the following conditions are met:
    - Status code is 200
    
    - The string true is present in the response body

##### Preparing ap4r

---

The following assumes ap4r's working directory is $HOME/ap4r/
Install ap4r

```
  $ gem install ap4r --no-ri --no-rdoc
```

Install activesupport. Required for ap4r initialization

```
  $ gem install activesupport -v '<3.0.0' --no-ri --no-rdoc
```

Create ap4r workspace

```
$ cd ~/ap4r/
$ ap4r_setup .
make application root directory [/home/hamajyotan/ap4r]…
make directories for AP4R [config, log, public, script, tmp]…
copy files from $GEM_HOME/gems/ap4r-0.3.7/config to /home/hamajyotan/ap4r/config…
copy files from $GEM_HOME/gems/ap4r-0.3.7/script to /home/hamajyotan/ap4r/script…
copy file from $GEM_HOME/gems/ap4r-0.3.7/fresh_rakefile to /home/hamajyotan/ap4r/Rakefile…

[/home/hamajyotan/ap4r] has successfully set up!

$
```

Create $HOME/ap4r/config/queues_notargets.cfg as follows

Prevent ap4r from dispatching messages without permission

```
---
store:
  type: disk
drb:
  host:
  port: 6438
  acl: allow 127.0.0.1 allow ::1 allow 10.0.0.0/8
dispatchers:
  -
    targets: notargets
    threads: 1
#carriers:
#-
#  source_uri: druby://another.host.local:6438
#  threads: 1  
```

##### Start ap4r

---

```
$ cd ~/ap4r/

$ ruby ​​script /mongrel_ap4r start -A config/queues_notargets.cfg
---
===
===
** Starting AP4R Handler with config/queues_notargets.cfg
Loaded queues configuration from: /home/hamajyotan/ap4r/config/queues_notargets.cfg
Using message store: disk
Accepting requests at: druby://localhost:6438
about to start dispatchers with config
---
-threads: 1
  targets: notargets

start dispatcher: targets = #<ReliableMsg::MultiQueue:0x2b89a7d39e90>, index = 0)
 dispatch targets are: notargets;
 queue manager has forked dispatchers
 ** Signals ready. TERM => stop. USR2 => restart. INT => stop (no restart).
 ** Mongrel available at 0.0.0.0:7438
 ** Use CTRL-C to stop.
 ** Mongrel start up process completed.  
```

##### Preparing a configuration file for reliable-msg-agent

---

Work in a separate window from the console that started ap4r. Below, assuming that the working directory of reliable-msg-agnet is $HOME/reliable-msg-agent/
Copy the necessary files from the resources/ directory under the gem installation directory

```
$ cp $GEM_HOME/gems/reliable-msg-agent-0.1.0/resources/agent.conf ~/reliable-msg-agent/
$ cp $GEM_HOME/gems/reliable-msg-agent-0.1.0/resources/examples/ap4r-dispatch-agent.rb ~/reliable-msg-agent/
```

##### Add settings to agent.conf

---

Tell Config the path of the agent definition file.

```
$ echo agent:/home/hamajyotan/reliable-msg-agent/ap4r-dispatch-agent.rb >> /home/hamajyotan/reliable-msg-agent/agent.conf
```

Check the configuration

```
---
logger: "Proc.new {|file| l = Logger.new(file); l.level = Logger::DEBUG; l }"

consumers:
  -
    source_uri: druby://localhost:6438
    every: 1.0
    target: queue.agent
    threads: 1

agent: /home/hamajyotan/reliable-msg-agent/ap4r-dispatch-agent.rb
```

Rewrite the config a little.

- modify_rules
  
  - url
    
    - Dispatch destination url Rewrite  http://localhost to http://localhost:9292

```
---
logger: "Proc.new {|file| l = Logger.new(file); l.level = Logger::DEBUG; l }"
consumers:
 -
 source_uri: druby://localhost:6438
 every: 1.0
 target: queue.agent
 threads: 1
 modify_rules:
 url: "Proc.new {|url| url.port = 9292; url }"
agent: /home/hamajyotan/reliable-msg-agent/ap4r-dispatch-agent.rb
```

##### Check the definition of the agent #call method here

---

```ruby
# frozen_string_literal: true

# this script is evaluated by the context of ReliableMsg::Agnet::Agent class.

require 'yaml'
require 'ap4r'

#
# The method of processing the message is defined.
#
# if the evaluation result is nil or false,
# it is considered that it failes.
#
# === Args
#
# +msg+ :: fetched message from reliable-msg queue.
# +conf+ :: consumer configurations.
# +options+ :: the options (it is still unused.)
#
def call msg, conf, _options = {}
  # The following codes use the mechanism of sending the message by ap4r.
  dispatcher = Ap4r::Dispatchers.new nil, [], @logger

  @logger.debug { "dispatcher get message \n#{msg.to_yaml}" }
  response = dispatcher.send(:get_dispather_instance,
                             msg.headers[:dispatch_mode],
                             msg,
                             conf).call
  @logger.debug { "dispatcher get response \n#{response.to_yaml}" }
end
```

A part of ap4r 's implementation is embedded in the configuration.
This enables message dispatch similar to what is implemented in ap4r . *Confirmed with ap4r 0.3.7

##### Starting reliable-msg-agent

---

```
$ reliable-msg-agent start -c /home/hamajyotan/reliable-msg-agent/agent.conf
*** Starting ReliableMsg-Agent…
I, [2011-04-12T01:22:28.678494 # 9696] INFO- : *** reliable-msg agent service starting…
I, [2011-04-12T01:22:28.678822 # 9696] INFO- : --- starting workers.
I, [2011-04-12T01:22:28.680012 # 9696] INFO- : *** reliable-msg agent service started.
```

##### Prepare a suitable web server

---

Work in a separate window.
Anything is acceptable as long as

- Listen on port 9292 (because it was set in the config first)

- Returns 200 for the status code and true (including the string) in the response body

This time make it appropriate with rack

```
$ gem install rack --no-ri --no-rdoc
```

Write rack configuration file appropriately
$HOME/stub.ru

```ruby
#
# $HOME/stub.ru
#
require 'rubygems'
require 'rack'

class Stub
  def call env
    [200, { "Content-Type" => "text/plain" }, ["true"]]
  end
end
run Stub.new
```

Start web server with rack

```
$ rackup $HOME/stub.ru
```

##### Put a message to ap4r

---

Work in a separate window.
You can put using ap4r rails plugin instead of

```bash
$ irb -rubygems -r reliable-msg
irb(main):001:0> q = ReliableMsg::Queue.new 'queue.agent'
=> #<ReliableMsg::Queue:0x2ac0e926f7a8 @queue="queue.agent">
irb(main):001:0> q.put '', { dispatch_mode: HTTP,
irb(main):002:0> target_method: :POST,
irb(main):003:0> target_url: 'http://localhost/',
irb(main):004:0> queue: 'queue.agent',
irb(main):005:0> delivery: :once }
=> "2f5e6c80-4688-012e-8954-f9a630fcd34e"
irb(main):006:0> exit
$
```

##### Take a look at the console that started reliable-msg-agent

---

1. Service startup

2. Get message

3. url rewrite http://localhost/ -> http://localhost:9292

4. Successful access to http://localhost:9292

A series of logs are output

```
$ reliable-msg-agent start -c ./agent.conf
*** Starting ReliableMsg-Agent…
*** reliable-msg agent service starting…
--- starting workers.
*** reliable-msg agent service started.
message fetched-<2f5e6c80-4688-012e-8954-f9a630fcd34e>
dispatcher get message
--- !ruby​/object:ReliableMsg::Message
headers:
  : dispatch_mode: :HTTP
  : target_url: http://localhost/
  : created: 1302539965
  : expires:
  : queue: queue.agent
  : delivery: :once
  : id:2f5e6c80-4688-012e-8954-f9a630fcd34e
  : target_method: :POST
  : priority: 0
  : max_deliveries: 5
id: 2f5e6c80-4688-012e-8954-f9a630fcd34e
object: ""
Ap4r::Dispatcher after modification
--- !ruby​​/object:ReliableMsg::Message
headers:
  : dispatch_mode: :HTTP
  : target_url: http://localhost:9292/
  : created: 1302539965
  : expires:
  : queue: queue.agent
  : delivery: :once
  : id: 2f5e6c80-4688-012e-8954-f9a630fcd34e
  : target_method: :POST
  : priority: 0
  : max_deliveries: 5
  id: 2f5e6c80-4688-012e-8954-f9a630fcd34e
 object: ""

response status [200 OK]
dispatcher get response
--- !ruby​​/object:Net::HTTPOK
body: "true"
body_exist: true
code: "200"
header:
  content-type:
  -text/plain
  connection:
  -close
  date:
  -Mon, 11 Apr 2011 16:39:25 GMT
  transfer-encoding:
  -chunked
http_version: "1.1"
message: OK
read: true
socket:
```

##### Look at the console that started stub.ru (web server)

---

It seems that there was access

```
$ rackup $HOME/stub.ru
127.0.0.1--[12/Apr/2011 01:39:25] "POST/HTTP/1.1" 200-0.0023
```

##### Explain the contents in picture

---

1. push-msg.sh puts a message to ap4r

2. reliable-msg-agent that circulates around ap4r gets the message

3. (Optional) Rewrite: target_url in message header
   
   1. http://localhost => http://localhost: 9292

4. reliable-msg-agent accesses http://localhost:9292 according to the dispatch rules of ap4r

![[Added] http timeout](20110412005120.png)

Since ap4r dispatchers function is described in the agent, config consumers can write the same configuration as ap4r dispatchers.
Experiment with http timeout implemented in Ap4r::Dispachers.

##### Added settings related to http timeout

---

Added http timeout settings to reliable-msg-agent config file
If processing is not completed within 3 seconds, it will be regarded as failure
$HOME/reliable-msg-agent/agent.conf

```
---
logger: "Proc.new {|file| l = Logger.new(file); l.level = Logger::DEBUG; l }"
consumers:
  -
    source_uri: druby://localhost:6438
    every: 1.0
    target: queue.agent
    threads: 1
    modify_rules:
      url: "Proc.new {|url| url.port = 9292; url}"
    http:
      timeout: 3

agent : /home/hamajyotan/reliable-msg-agent/ap4r-dispatch-agent.rb
```

##### Let stub.ru take 10 seconds

---

```ruby
#
# $HOME/stub.ru
#
require 'rubygems'
require 'rack'

class Stub
  def call env
    sleep 10
    [200, { "Content-Type" => "text/plain" }, ["true"]]
  end
end
run Stub.new
```

##### Put a message with the above settings

---

Agent processing has timed out
The following logs are output with reliable-msg-agent

```
#
# Halfway omitted
#
message fetched-<52222a00-4692-012e-8f7a-f9afb181b61 6>
dispatcher get message
--- !ruby​​/object:ReliableMsg::Message
headers:
 : dispatch_mode: :HTTP
 : target_url: http://localhost/test/index.html
 : created: 1302544318
 : expires:
 : queue: queue.agent
 : delivery: :once
 : id: 52222a00-4692-012e-8f7a-f9afb181b616
 : target_method: :POST
 : priority: 0
 : max_deliveries: 5
id: 52222a00-4692-8f7a-f9afb181b616
object: ""

Ap4r :: Dispatcher after modification
--- !ruby​​/object:ReliableMsg::Message
headers:
 : dispatch_mode: :HTTP
 : target_url: http://localhost:9292/test/index.html
 : created: 1302544318
 : expires:
 : queue: queue.agent
 : delivery: :once
 : id: 52222a00-4692-012e-8f7a-f9afb181b616
 : target_method: :POST
 : priority: 0
 : max_deliveries: 5
id: 52222a00-4692-012e-8f7a-f9afb181b616
object: ""

set HTTP read timeout to 3s
error in fetch-msg / agent-proc: execution expired
/home/hamajyotan/.rvm/rubies/ruby-1.8.7-p302/lib/ruby/1.8/timeout.rb:64: in `rbuf_fill'
/home/hamajyotan/.rvm/rubies/ruby-1.8.7-p302/lib/ruby/1.8/net/protocol.rb:134:in `rbuf_fill'
/home/hamajyotan/.rvm/rubies/ruby-1.8.7-p302/lib/ruby/1.8/net/protocol.rb: 116: in ` readuntil'
/home/hamajyotan/.rvm/rubies/ruby-1.8.7-p302/lib/ruby/1.8/net/protocol.rb:126:in `readline'
/home/hamajyotan/.rvm/rubies/ruby-1.8.7-p302/lib/ruby/1.8/net/http.rb:2028: in `read_status_line 
#

# Halfway omitted

#
msg-agent:75: in `send'
/home/hamajyotan/.rvm/gems/ruby-1.8.7-p302/gems/reliable-msg-agent-0.1.0/bin/reliable-msg-agent:75
/home/hamajyotan/.rvm/gems/ruby-1.8.7-p302/bin/reliable-msg-agent:19: in `load'
/home/hamajyotan/.rvm/gems/ruby-1.8.7-p302/bin/reliable-msg-agent:19
```
