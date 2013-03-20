# -File- ./JSClassRef.rb
#

module JavaScriptCore
  class JSClass < JSCBind::Object
    this = class << self;self;end

    add_function(libname, :JSClassCreate, [:JSClassDefinition], {:object=>{:name=>:JSClass,:namespace=>:JavaScriptCore}}).attach(this)
    add_function(libname, :JSClassRetain, [:JSClassRef], {:object=>{:name=>:JSClass,:namespace=>:JavaScriptCore}}).attach(self)
    add_function(libname, :JSClassRelease, [:JSClassRef], :void).attach(self)
  end
end

#
