# -File- ./JSObjectRef.rb
#

module JavaScriptCore
  class JSObject < JSCBind::ObjectWithContext
    this = class << self;self;end
    FFI::TYPES[:unsigned]=CFunc::UInt32
    add_function(libname, :JSObjectMake, [:JSContextRef, :JSClassRef, :void], {:object=>{:name=>:JSObject,:namespace=>:JavaScriptCore}}).attach(this)
    add_function(libname, :JSObjectMakeFunctionWithCallback, [:JSContextRef, :JSStringRef, {:callback=>:JSObjectCallAsFunctionCallback}], {:object=>{:name=>:JSObject,:namespace=>:JavaScriptCore}}).attach(this)
    add_function(libname, :JSObjectMakeConstructor, [:JSContextRef, :JSClassRef, :JSObjectCallAsConstructorCallback], {:object=>{:name=>:JSObject,:namespace=>:JavaScriptCore}}).attach(this)
    add_function(libname, :JSObjectMakeArray, [:JSContextRef, :size_t, :JSValueRef, :JSValueRef], {:object=>{:name=>:JSObject,:namespace=>:JavaScriptCore}}).attach(this)
    add_function(libname, :JSObjectMakeDate, [:JSContextRef, :size_t, :JSValueRef, :JSValueRef], {:object=>{:name=>:JSObject,:namespace=>:JavaScriptCore}}).attach(this)
    add_function(libname, :JSObjectMakeError, [:JSContextRef, :size_t, :JSValueRef, :JSValueRef], {:object=>{:name=>:JSObject,:namespace=>:JavaScriptCore}}).attach(this)
    add_function(libname, :JSObjectMakeRegExp, [:JSContextRef, :size_t, :JSValueRef, :JSValueRef], {:object=>{:name=>:JSObject,:namespace=>:JavaScriptCore}}).attach(this)
    add_function(libname, :JSObjectMakeFunction, [:JSContextRef, :JSStringRef, :unsigned, :JSStringRef, :JSStringRef, :JSStringRef, :int, :JSValueRef], {:object=>{:name=>:JSObject,:namespace=>:JavaScriptCore}}).attach(this)
    add_function(libname, :JSObjectGetPrototype, [:JSContextRef, :JSObjectRef], {:object=>{:name=>:JSValue,:namespace=>:JavaScriptCore}}).attach(self)
    add_function(libname, :JSObjectSetPrototype, [:JSContextRef, :JSObjectRef, :JSValueRef], :void).attach(self)
    add_function(libname, :JSObjectHasProperty, [:JSContextRef, :JSObjectRef, :JSStringRef], :bool).attach(self)
    add_function(libname, :JSObjectGetProperty, [:JSContextRef, :JSObjectRef, :JSStringRef, :JSValueRef], {:object=>{:name=>:JSValue,:namespace=>:JavaScriptCore}}).attach(self)
    add_function(libname, :JSObjectSetProperty, [:JSContextRef, :JSObjectRef, :JSStringRef, :JSValueRef, :JSPropertyAttributes, :JSValueRef], :void).attach(self)
    add_function(libname, :JSObjectDeleteProperty, [:JSContextRef, :JSObjectRef, :JSStringRef, :JSValueRef], :bool).attach(self)
    add_function(libname, :JSObjectGetPropertyAtIndex, [:JSContextRef, :JSObjectRef, :unsigned, :JSValueRef], {:object=>{:name=>:JSValue,:namespace=>:JavaScriptCore}}).attach(self)
    add_function(libname, :JSObjectSetPropertyAtIndex, [:JSContextRef, :JSObjectRef, :unsigned, :JSValueRef, :JSValueRef], :void).attach(self)
    add_function(libname, :JSObjectGetPrivate, [:JSObjectRef], :void).attach(self)
    add_function(libname, :JSObjectSetPrivate, [:JSObjectRef, :void], :bool).attach(self)
    add_function(libname, :JSObjectIsFunction, [:JSContextRef, :JSObjectRef], :bool).attach(self)
    add_function(libname, :JSObjectCallAsFunction, [:JSContextRef, :JSObjectRef, :JSObjectRef, :size_t, :JSValueRef, :JSValueRef], {:object=>{:name=>:JSValue,:namespace=>:JavaScriptCore}}).attach(self)
    add_function(libname, :JSObjectIsConstructor, [:JSContextRef, :JSObjectRef], :bool).attach(self)
    add_function(libname, :JSObjectCallAsConstructor, [:JSContextRef, :JSObjectRef, :size_t, :JSValueRef, :JSValueRef], {:object=>{:name=>:JSObject,:namespace=>:JavaScriptCore}}).attach(self)
    add_function(libname, :JSObjectCopyPropertyNames, [:JSContextRef, :JSObjectRef], {:object=>{:name=>:JSPropertyNameArray,:namespace=>:JavaScriptCore}}).attach(self)
  end
end

#
