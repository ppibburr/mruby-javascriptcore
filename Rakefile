desc "compiles the library with your script\n\t\t        script, path to your file\n\n"
task :compile, :script do |t,args|
  file = File.expand_path(args[:script])
  name = File.basename(file).split(".")[0]
  Dir.mkdir("tmp") unless File.exist?('tmp')
  if jp = ENV['JSCORE_PATH']
    File.open("src/lib_path.rb","w") do |f|
      f.puts "JSCORE_PATH = '#{jp}'"
    end
  end
  
  sh "cp tools/mruby-ffi/src/ffi.rb tmp/0.rb"  
  sh "cp src/lib_path.rb tmp/1.rb"
  sh "cp src/mrubyjscore.rb tmp/2.rb"
  sh "cp #{file} tmp/3.rb"
  sh "cd tools/mruby-rake; rake compile[#{n=File.basename(args[:script]).split(".")[0]}_run,#{Dir.getwd}/tmp/,true];cp #{n}_run #{Dir.getwd}/" 
end

desc "runs the test script in ./test/"
task :test do
  file = File.expand_path("./test/test.rb")
  Rake::Task["compile"].invoke("#{file}")
  sh "./test_run"
end

task :clean do
  `cd tools/mruby-rake;rake clean`
  `rm -rf tmp`
  `rm *_run`
end

desc "compile and run the ./example/example_webview.rb example"
task :"example-webview" do
  Rake::Task['compile-webkit'].invoke("./example/example_webview.rb")
  `./example_webview_run`
  `rm example_webview_run`
end

Dir.mkdir('out') unless File.exist?('out')

desc "exposes a minimal interface to Gtk, WebKit, to your script"
task :"compile-webkit",:file do |t,args|
  `cd tools/mruby-webkitgtk;rake configure`
  wk = File.open("tools/mruby-webkitgtk/src/webkitgtk.rb").read
  example = File.open("#{args[:file]}").read
  File.open("out/#{File.basename(args[:file])}","w") do |f|
    f.puts File.open("tools/mruby-webkitgtk/src/lib_gobject_path.rb").read
    f.puts File.open("tools/mruby-webkitgtk/src/lib_gtk_path.rb").read
    f.puts File.open("tools/mruby-webkitgtk/src/lib_webkit_path.rb").read        
    f.puts wk
    f.puts example
  end
  file = File.expand_path("./out/#{File.basename(args[:file])}")
  Rake::Task["compile"].invoke("#{file}")
  `rm out/#{File.basename(args[:file])}`
end
