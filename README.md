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

Requirements
===
* [mruby](https://github.com/mruby/mruby)
* [mruby-girffi](https://github.com/ppibburr/mruby-girffi) (GEM)

build_config.rb
===
```ruby
MRuby::Build.new do |conf|
  # load specific toolchain settings
  toolchain :gcc

  # Use standard Math module
  conf.gem 'mrbgems/mruby-math'

  # Use standard Time class
  conf.gem 'mrbgems/mruby-time'

  # Use standard Struct class
  conf.gem 'mrbgems/mruby-struct'

  # Use standard Kernel#sprintf method
  conf.gem 'mrbgems/mruby-sprintf'

  # Generate binaries
   conf.bins = %w(mrbc mruby mirb)

  # Provides c function invocation / symbols
  conf.gem :git => 'https://github.com/mobiruby/mruby-cfunc.git', :branch => 'master', :options => '-v'

  # adds Class#allocate
  conf.gem :git => 'https://github.com/ppibburr/mruby-allocate.git', :branch => 'master', :options => '-v'

  # handles mapping from GObjectIntrospection and dsl mapping
  conf.gem :git => 'https://github.com/ppibburr/mruby-girffi', :branch => 'master', :options => '-v'
  
  # bindings to javascript
  conf.gem :git => 'https://github.com/ppibburr/mruby-javascriptcore', :branch => 'master', :options => '-v'  
end
```

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
