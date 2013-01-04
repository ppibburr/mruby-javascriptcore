mruby-javascriptcore
=========

A Library to bridge mruby and javascript. (libjavascriptcore, tested with libjavascriptcoregtk) - OR -
                                          (libwebkit, tested with libwebkitgtk-1.0 and 3.0)

  - exposes javascript api
  - exposes ruby api to javascript
  - works without a WebView
  - works in a WebView



Version
-

0.0.1

Requirements
-----------

MRuby must be compiled with MRBGEMS active:

* [mruby-cfunc] - A MRBGEM, based on libffi
* [libjavascriptcore] - tested with libjavascriptcoregtk-1.0 and 3.0, - OR -
* [libwebkit] - tested with libwebkitgtk-1.0 and 3.0

Synopsis
--------------
    rake -D
      rake compile[script]
                    compiles the library with your script
    		        script, path to your file

      rake compile-webkit[file]
                    exposes a minimal interface to Gtk, WebKit, to your script

      rake example-webview
                    compile and run the ./example/example_webview.rb example

      rake test
                    runs the test script in ./test/


Usage
--------------
    # Clone the repo
    cd mruby-javascriptcore
    export MRUBY_PATH=/path/to/mruby
    export JSCORE_PATH=/path/to/jscore # optionaly edit JSCORE_PATH constant 
                                       # in ./src/lib_path.rb 
                                       # ie, /usr/lib/libjavascriptcoregtk-1.0.so.0 
                                       # or /usr/lib/libwebkitgtk-1.0.so.0
    # if using rake task 'compile-webkit'
    # you need to export the paths to where webkitgtk can find gobject, gtk and
    #  webkit, see ./tools/mruby-webkitgtk/README.md
    rake test; rake clean # optional, currently 2 assertions should fail
    rake compile[/path/to/your/script.rb] # an executable is created,
                                          # file basename minus extension
                                          # appended with _run
    ./script_run # execute. change 'script' to match your file
    # copy/mv script_run to wherever
    # rake clean # clean up and do another one

Example
-------------
```ruby
Gtk.init
w=Gtk::Window.new
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
```
License
-

MIT
