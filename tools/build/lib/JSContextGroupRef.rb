# -File- ./JSContextGroupRef.rb
#

module JavaScriptCore
  class JSContextGroup < JSCBind::Object
    this = class << self;self;end

    add_function(libname, :JSContextGroupCreate, [], {:object=>{:name=>:JSContextGroup,:namespace=>:JavaScriptCore}}).attach(this)
    add_function(libname, :JSContextGroupRetain, [:JSContextGroupRef], {:object=>{:name=>:JSContextGroup,:namespace=>:JavaScriptCore}}).attach(self)
    add_function(libname, :JSContextGroupRelease, [:JSContextGroupRef], :void).attach(self)
  end
end

#
