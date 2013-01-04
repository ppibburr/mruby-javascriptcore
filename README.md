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

Usage
--------------

1. Clone the repo
2. `cd mruby-javascriptcore`
3. `export MRUBY_PATH=/path/to/mruby`
4. `export JSCORE_PATH=/path/to/jscore # optionaly edit JSCORE_PATH constant in ./src/lib_path.rb (at the top), ie,
                                         /usr/lib/libwebkitgtk-1.0.so.0`
5. `rake test; rake clean # optional, currently 2 assertions should fail`
6. `rake compile[/path/to/your/script.rb] # an executable is created, file basename minus extension, appended with _run`
7. `./script_run # change 'script' to match your file, copy/mv script_run to wherever` 
8. `# rake clean # clean up and do another one`


License
-

MIT
