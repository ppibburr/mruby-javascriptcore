Gtk.init
w=Gtk::Window.new
w.resize(400,400)
w.add v=WebKit::WebView.new

v.load_html_string "hello mruby",""

v.signal_connect "load-finished" do |wv,f|
  cptr = WebKit::WebFrame.wrap(f).get_global_context
  c = JS::GlobalContext.new(:pointer=>cptr)
  g = c.get_global_object
  g[:alert].call("hello MRUBY!")
  g[:document][:body][:innerText] = "Wrote by MRuby!!"
end

w.show_all

Gtk.main
