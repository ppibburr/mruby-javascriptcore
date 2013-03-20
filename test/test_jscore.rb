ctx = JS::JSGlobalContext.create(nil)
gobj = ctx.get_global_object

obj = JS::JSObject.new(ctx,a=[1,2,3])
p a == [obj[0],obj[1],obj[2]]

obj = JS::JSObject.new(ctx) do |*o|
  puts "i was passed: #{o.join(", ")}"
end

p obj.call_as_function("foo")

obj = JS::JSObject.new(ctx,{:bar=>3})
p obj[:bar]

fun = Proc.new do |a,b|
  a+b
end

gobj["add"] = fun

p gobj[:add].call_as_function(1,2)
p JS.execute_script(ctx,"add(1,2);")
p JS.execute_script(ctx,"this.add(1,2);",gobj)
