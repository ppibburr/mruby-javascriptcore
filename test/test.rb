$assertions = []
def assertions
  $assertions
end

def assert v,m
  assertions << a=v==true
  puts "assertion failed, #{m}" if !a
end

def assert_false v
  assert !v,"expected to be false"
end

def assert_value_is_null v
  assert v.is_null,"expected to be null"
end

def assert_value_is_bool v
  assert v.is_boolean,"expected to be boolean"
end

def assert_value_is_number v
  assert v.is_number,"expected to be number"
end

def assert_value_is_object v
  assert v.is_object,"expected to be object"
end

def assert_value_is_string v
  assert v.is_string,"expected to be string"
end

def assert_object_is_function o
  assert o.is_function,"expected to be object"
end

def assert_object_is_array o
  assert o.is_array,"expected to be array"
end

def assert_equal a,b
  assert a==b,"expected to be equal"
end

c = JS::GlobalContext.new(nil)

# tests of internals
# normal usage is not invoked using the internals

v = JS::Value.make_number(c,1)
assert_value_is_number(v)
assert_false v.is_boolean
assert_false v.is_string
assert_false v.is_object
assert_false v.is_null

assert_equal v.to_ruby,1.0

v = JS::Value.make_boolean(c,true)
assert_value_is_bool(v)
assert_false v.is_number
assert_false v.is_string
assert_false v.is_object
assert_false v.is_null

assert v.to_ruby,"expected true"
assert_equal v.to_ruby,true

v = JS::Value.make_boolean(c,false)
assert_value_is_bool(v)
assert_false v.to_ruby

v = JS::Value.make_string(c,"string")
assert_value_is_string(v)
assert_false v.is_boolean
assert_false v.is_number
assert_false v.is_object
assert_false v.is_null

assert_equal v.to_ruby,"string"

o = JS::Object.make(c)
assert_value_is_object(JS::Value.from_ruby(c,o))

v=JS::Value.make_string(c,"foo")
assert_value_is_string v;
assert_equal v.to_string_copy,"foo"


# Tests of intended usage of the exposed API
# These are more commonly used

g = c.get_global_object
assert_value_is_object JS::Value.from_ruby(c,g)

# properties set Proc's become objects that are functions
g[:foo]=Proc.new do |*o| 1 end
assert_object_is_function g[:foo]
assert_equal g[:foo].call(),1.0

g[:bool] = true
assert g[:bool],"expected true"
assert_equal g[:bool],true

g[:bool2] = false
assert_false g[:bool2]

g[:float] = 1.0
assert_equal g[:float],1.0

# Properties set to Hash's becom objects
g[:object]={:foo=>4}
assert g[:object].is_a?(JS::Object),"expected to be object"
assert_equal g[:object][:foo],4.0

assert false,"expected object to be array"
assert false,"expected object property to be string"


class M
  def bar
    3
  end
end

# Properties set to objects other than String,Numeric,Array,Hash,Proc, become a RubyObject
# RubyObjects expose the object to JS-land
# Methods of (ruby)objects are exposed as functions on the (js)object
g[:t] = M.new
assert_equal g[:t][:bar].call,3
assert_equal JS.execute_script(c,"this.t.bar();").to_ruby,3

# An object created from a Hash, has Proc values turned into functions
g[:q] = {
  :foo=>Proc.new do
    true
  end
}

assert z=g[:q][:foo].call,"expected true"
assert_equal z,true

g["string"] = "foo"
assert_equal g["string"],"foo"

puts "#{assertions.length} assertions:"
passed = assertions.find_all() do |a| a end.length
failed = assertions.find_all() do |a| !a end.length
puts "#{passed} passed"
puts "#{failed} failed"
