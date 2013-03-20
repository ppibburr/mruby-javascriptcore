# -File- ./JSGlobalContextRef.rb
#

module JavaScriptCore
  class JSGlobalContext < JavaScriptCore::JSContext
    this = class << self;self;end

    add_function(libname, :JSGlobalContextCreate, [:JSClassRef], {:object=>{:name=>:JSGlobalContext,:namespace=>:JavaScriptCore}}).attach(this)
    add_function(libname, :JSGlobalContextCreateInGroup, [:JSContextGroupRef, :JSClassRef], {:object=>{:name=>:JSGlobalContext,:namespace=>:JavaScriptCore}}).attach(this)
    add_function(libname, :JSGlobalContextRetain, [:JSGlobalContextRef], {:object=>{:name=>:JSGlobalContext,:namespace=>:JavaScriptCore}}).attach(self)
    add_function(libname, :JSGlobalContextRelease, [:JSGlobalContextRef], :void).attach(self)
  end
end

#
