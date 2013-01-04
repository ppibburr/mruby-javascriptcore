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
  sh "cp src/lib_path.rb tmp/0.rb"
  sh "cp src/mrubyjscore.rb tmp/1.rb"
  sh "cp #{file} tmp/2.rb"
  sh "cd tools; rake compile[#{n=File.basename(args[:script]).split(".")[0]}_run,#{Dir.getwd}/tmp/,true];cp #{n}_run #{Dir.getwd}/" 
  puts "You can now execute ./#{name}"
end

desc "runs the test script in ./test/"
task :test do
  file = File.expand_path("./test/test.rb")
  Rake::Task["compile"].invoke("#{file}")
  sh "./test_run"
end

task :clean do
  `cd tools;rake clean`
  `rm -rf tmp`
  `rm *_run`
end

task :"example-webview" do

  wk = File.open("../mruby-webkitgtk/src/webkitgtk.rb").read
  example = File.open("./example/example_webview.rb").read
  File.open("./example/webview_temp.rb","w") do |f|
    f.puts wk
    f.puts example
  end
  file = File.expand_path("./example/webview_temp.rb")
  Rake::Task["compile"].invoke("#{file}")
  sh "rm example/webview_temp.rb"
  sh "./webview_temp_run"
end
