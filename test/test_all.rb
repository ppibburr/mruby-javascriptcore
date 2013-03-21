def assert bool, msg = nil
  raise "Assertion #{msg} failed." unless bool
end

ctx = JS.make_context
gobj = ctx.get_global_object

def value(ctx,v)
  JS::JSValue.from_ruby(ctx,v)
end

# Tests of JSValue conversions

assert value(ctx,nil).is_undefined
assert value(ctx,"foo").is_string

assert (bool=value(ctx,false)).is_boolean
assert bool.to_ruby==false

assert (bool=value(ctx,true)).is_boolean
assert bool.to_ruby == true

assert (n=value(ctx,1)).is_number
assert n.to_ruby == 1

assert (n=value(ctx,1.0)).is_number
assert n.to_ruby == 1

assert (n=value(ctx,1.4)).is_number
assert n.to_ruby == 1.4

assert (obj=value(ctx,{:foo=>"bar"})).is_object
assert obj.to_ruby.is_a?(JS::JSObject)

assert (fun=value(ctx,Proc.new do end)).is_object
assert fun.to_ruby.is_a?(JS::ObjectIsFunction)
assert fun.to_ruby.is_function

assert (ary=value(ctx,[1,2])).is_object
assert ary.to_ruby.is_array

class Foo
  def bar *o,&b
    assert o.length == 2
    assert !!b 
    assert b.call("hello","world") == "helloworld"
    return o[0]+o[1]  
  end
end

foo = Foo.new
assert (rov=value(ctx,foo)).is_object
assert rov.to_ruby == foo
assert (ro=rov.to_object(nil)).is_a? JS::RObject
assert fun=ro[:bar]
assert fun.is_a?(JS::JSObject)
assert fun.is_a?(JS::ObjectIsFunction)
assert fun.is_function

#########################
#
# * Tests of Functions *
#
#########################

gobj[:rubyFunction] = Proc.new do |*o|
  assert o.length == 2
  next o[0] + o[1]
end

assert (rf=gobj[:rubyFunction]).is_a?(JS::JSObject)
assert rf.is_function
assert rf.is_a?(JS::ObjectIsFunction)
assert rf.call(1,2) == 3

assert((f=ctx.execute('rubyFunction;')).is_a?(JS::JSObject))
assert f.is_function
assert f.call(1,2) == 3
assert ctx.execute("rubyFunction(1,2);") == 3

# When last argument to function call is_function
# functions get block
gobj[:rubyFunction2] = Proc.new do |*o,&b|
  assert o.length == 2
  assert !!b
  assert b.call("hello","world") == "helloworld"
  next o[0] + o[1]
end

assert (rf2=gobj[:rubyFunction2]).is_a?(JS::JSObject)
assert rf2.is_function
assert rf2.is_a?(JS::ObjectIsFunction)
assert(rf2.call(1,2) do |*o|
  assert o.length == 2
  next(o.join)
end == 3)

# functions of RObjects do the same
assert(fun.call(1,2) do |*o|
  assert o.length == 2
  next o.join()
end == 3)

# and it holds true for calls from javascript
assert ctx.execute("this.bar(1,2,function(a,b) { return(a+b);});",ro) == 3


######################
#
# * Tests of Arrays *
#
######################

gobj[:array] = [1,2,3,4]

ary = gobj[:array]

assert(ary.is_a?(JS::ObjectIsArray))
assert(ary.to_a == [1,2,3,4])

a = ary.map do |q| q end
assert(a == [1,2,3,4])

assert(ary[0] == 1)
assert(ary[1] == 2)
assert(ary[2] == 3)
assert(ary[3] == 4)
assert(ary.length == 4)

ctx.execute("var array2 = new Array();array2[0] = 1;array2[1] = 2;")

ary2 = gobj[:array2]

assert(ary2.is_a?(JS::ObjectIsArray))
assert(ary2.to_a == [1,2])

a = ary2.map do |q| q end
assert(a == [1,2])

assert(ary2[0] == 1)
assert(ary2[1] == 2)
assert(ary2.length == 2)

##########################
#
# * Tests of Properties *
#
##########################

gobj[:obj] = {
 :string=>"string",
 :int=>1,
 :float=>3.3,
 :bool=>true,
 :array=>[1,true,{:bar=>1},"string2"]
}

assert (obj=gobj[:obj])[:string] == "string"
assert obj[:int]==1
assert obj[:float] == 3.3
assert obj[:bool] == true
assert (a=obj[:array]).is_array
assert a[0] == 1
assert a[1] == true
assert (o=a[2]).is_a?(JS::JSObject)
assert o[:bar] == 1
assert a[3] == "string2"

gobj[:foo] = {
  :bar=>1,
  :quux=>{:moof=>[1,2]},
   :fun => Proc.new do |i|
     next i*2
   end
}

assert gobj[:foo][:bar] == 1
assert (o=gobj[:foo][:quux]).is_a?(JS::JSObject)
assert o[:moof].is_array
assert o[:moof][0] == 1
assert o[:moof][1] == 2
assert gobj[:foo][:fun].is_function
assert gobj[:foo][:fun].call(2) == 4

puts "JavaScriptCore tests: All Passed"
