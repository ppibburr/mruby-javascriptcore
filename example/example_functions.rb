ctx = JS.make_context()

gobj = ctx.get_global_object

gobj[:puts] = Proc.new do |str|
  puts "Hello #{str}! I'm Mruby"
end


JS.execute_script(ctx,"puts('JavaScript');")

JS.execute_script(ctx,"function hello(str) { return(\"Hello, \"+str+\"! I'm JavaScript\");};")

fun = gobj[:hello]
puts fun.call("MRuby")

