GirBind.bind(:Gtk)

class JS::JSValue
  alias :_to_ruby_ :to_ruby
  def to_ruby
    if is_object and (o=to_object(nil)).is_array
      o.extend(JS::ObjectIsArray)
      return o.to_a
    end
    
    _to_ruby_
  end
end

script = GLib.file_get_contents("jsGtk.js")[1]

ctx = JS::make_context

gobj = ctx.get_global_object

gobj[:gtk] = Gtk

gobj[:gtkMain] = Proc.new do
  Gtk.main
end

gobj[:gtkMainQuit] = Proc.new do |*o|
  p 9
  GLib.timeout_add 200,300 do
    Gtk.main_quit;
  end
  next(nil)
end

gobj[:gtkInit] = Proc.new do |cnt,ary|
  Gtk.init cnt,ary
end

gobj[:connect] = Proc.new do |v,n,&b|
  v.signal_connect(n,&b)
end


ctx.execute script

