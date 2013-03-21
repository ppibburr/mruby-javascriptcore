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

script = GLib.file_get_contents("./script.js")[1]

ctx.execute(script)
