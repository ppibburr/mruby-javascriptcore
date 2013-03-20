ctx = JS::JSGlobalContext.create(nil)
gobj = ctx.get_global_object

gobj[:puts] = K = Proc.new do |str|
  puts "Hello #{str}! I'm Mruby"
end

JS.execute_script(ctx,"puts('JavaScript');")

JS.execute_script(ctx,"function hello(str) { return(\"Hello, \"+str+\"! I'm JavaScript\");};")

puts gobj[:hello].call_as_function("MRuby")
