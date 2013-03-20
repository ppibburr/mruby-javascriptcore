# -File- ./JSPropertyNameArrayRef.rb
#

module JavaScriptCore
  class JSPropertyNameArray < JSCBind::Object
    this = class << self;self;end

    add_function(libname, :JSPropertyNameArrayRetain, [:JSPropertyNameArrayRef], {:object=>{:name=>:JSPropertyNameArray,:namespace=>:JavaScriptCore}}).attach(self)
    add_function(libname, :JSPropertyNameArrayRelease, [:JSPropertyNameArrayRef], :void).attach(self)
    add_function(libname, :JSPropertyNameArrayGetCount, [:JSPropertyNameArrayRef], :size_t).attach(self)
    add_function(libname, :JSPropertyNameArrayGetNameAtIndex, [:JSPropertyNameArrayRef, :size_t], {:object=>{:name=>:JSString,:namespace=>:JavaScriptCore}}).attach(self)
  end
end

#
