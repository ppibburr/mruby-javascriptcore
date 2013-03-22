GirBind.bind(:Gtk)

JS::JSValue.set_return_array_objects_as_array()

script = GLib.file_get_contents("jsGtk.js")[1]

ctx = JS::make_context

gobj = ctx.get_global_object

gobj[:gtk] = Gtk

gobj[:gtkMain] = Proc.new do
  Gtk.main
end

gobj[:gtkMainQuit] = Proc.new do |*o|
    Gtk.main_quit;
end

gobj[:gtkInit] = Proc.new do |cnt,ary|
  Gtk.init cnt,ary
end

gobj[:connect] = Proc.new do |v,n,&b|
  v.signal_connect(n,&b)
end


ctx.execute script

