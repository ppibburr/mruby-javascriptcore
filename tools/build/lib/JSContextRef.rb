# -File- ./JSContextRef.rb
#

module JavaScriptCore
  class JSContext < JSCBind::Object
    this = class << self;self;end

    add_function(libname, :JSContextGetGlobalObject, [:JSContextRef], {:object=>{:name=>:JSObject,:namespace=>:JavaScriptCore}}).attach(self)
    add_function(libname, :JSContextGetGroup, [:JSContextRef], {:object=>{:name=>:JSContextGroup,:namespace=>:JavaScriptCore}}).attach(self)
  end
end

#
