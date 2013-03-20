About
===
Bindings to JavaScriptCore from WebKitGTK  
Uses mruby-girffi to create bindings  

Provides a bridge between mruby and javascriptcore runtimes  
Properly converting values between the two

Features
===
* Execute javascript code
* Ruby can call javascript functions, access objects
* JavaScript can call ruby methods, access objects
* can provide full DOM access when used with WebKit bindings ala mruby-girffi
* Ruby Array's become JavaScript Objects
* Ruby Hash's become JavaScript Objects
* Ruby Proc's become JavaScript functions

Example
===
```ruby
ctx = JS::JSGlobalContext.create(nil)
gobj = ctx.get_global_object

gobj[:puts] = Proc.new do |str|
  puts "Hello #{str}! I'm Mruby"
end

JS.execute_script(ctx,"puts('JavaScript');")

JS.execute_script(ctx,"function hello(str) { return(\"Hello, \"+str+\"! I'm JavaScript\");};")

puts gobj[:hello].call_as_function("MRuby")
```

```sh
$ mruby example.rb
Hello JavaScript! I'm Mruby
Hello, MRuby! I'm JavaScript
```
