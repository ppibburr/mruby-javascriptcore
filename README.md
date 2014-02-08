About
===
Bindings to JavaScriptCore from WebKitGTK  
Uses mruby-rubyffi-compat to create bindings  

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
* [mruby-rubyffi-compat](https://github.com/ppibburr/mruby-rubyffi-compat) (GEM implementating a substantial subset of ruby-ffi)

Example
===
```ruby
# Create a Context
cx = JS.context
p cx
# get the Context's global object
jo = cx.getGlobalObject

# set "a" to "f"
jo[:a] = "f"
jo[:a] #=> "f"

# set "b" to 3.45
jo[:b] = 3.45
jo[:b] #=> 3.45

# set "c" to a function (adds arg1 and arg2)
jo[:c] = Proc.new do |ctx_, this, *o|
  o[0] + o[1]
end

# call a function
jo[:c].call(1,2) #=> 3

# create a Object from a Hash
jo[:d] = {
  :foo  => 3, # Number
  :bar  => Proc.new do |ctx_, this, *args| puts "Called with #{args.length}, args." end, # function
  :quux => [1,2,3] # Array
}

# properties as methods
jo.d.foo
jo.d.quux[2]
jo.d.bar.call(1, 2, "foo")

# Prove JS can reach us
JS.execute(cx, "function moof() {return 5;};this.bar(1,2,3,4,5,6);", jo.d)

# And that we can reach JS
jo.moof.call()
```
