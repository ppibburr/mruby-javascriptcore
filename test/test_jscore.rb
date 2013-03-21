ctx = JS::JSGlobalContext.create(nil)
gobj = ctx.get_global_object

obj = JS::JSObject.new(ctx,a=[1,2,3])
p a == [obj[0],obj[1],obj[2]]

obj = JS::JSObject.new(ctx) do |*o|
  puts "i was passed: #{o.join(", ")}"
end

p obj.call("foo")

obj = JS::JSObject.new(ctx,{:bar=>"quux"})
p obj[:bar]

fun = Proc.new do |a,b|
  a+b
end

gobj["add"] = fun

p gobj[:add].call(1,2)
p JS.execute_script(ctx,"add(1,2);")
p JS.execute_script(ctx,"this.add(1,2);",gobj)
p ctx.execute("add(1,2);")
p ctx.execute("this.bar;",obj)


class Baz
  def bar x,y,fun=nil
    sum = x+y
    if fun
      return fun.call(sum)
    end
    return sum
  end
end

baz = Baz.new

q = 0

test =Y= JS::RObject.make(ctx,baz) 

p test[:bar].call(1,2) == 3

foo = test[:bar].call(1,2) do |i|
  next(i*2)
end
p foo == 6

50.times do |i|
  q += ctx.execute('this.bar(1,2,function(a) { return a*2; });',test)
end

p q == 300
