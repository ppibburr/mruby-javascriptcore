GirBind.bind(:GObject)

ctx = JS.make_context()

gobj = ctx.get_global_object

gobj[:rubyProperty] = "A String"

gobj[:rubyAdd] = Proc.new do |*o|
  sum = 0
  
  o.each do |i|
    sum += i
  end
  
  next(sum)
end

gobj[:rubyFunctionWithClosure] = Proc.new do |ary,fun|
  fun.call(ary)
  next(true);
end

script = GLib.file_get_contents("./call_ruby.js")[1]

jary = ctx.execute(script)

p jary[0]
p jary[1]
p jary[2]
p jary[3]

script = GLib.file_get_contents("./library.js")[1]

ctx.execute(script)

p gobj[:jsAdd].call(1,2)
p gobj[:jsProperty]

class Bar
  def foo
    78
  end
end

bar = Bar.new

result = gobj[:jsFunctionWithClosure].call(bar) do |obj|
  obj.to_s
end

p result[0]
p result[1]
