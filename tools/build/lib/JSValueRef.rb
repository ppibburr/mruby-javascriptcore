# -File- ./JSValueRef.rb
#

module JavaScriptCore
  class JSValue < JSCBind::ObjectWithContext
    this = class << self;self;end

    add_function(libname, :JSValueGetType, [:JSContextRef, :JSValueRef], :JSType).attach(self)
    add_function(libname, :JSValueIsUndefined, [:JSContextRef, :JSValueRef], :bool).attach(self)
    add_function(libname, :JSValueIsNull, [:JSContextRef, :JSValueRef], :bool).attach(self)
    add_function(libname, :JSValueIsBoolean, [:JSContextRef, :JSValueRef], :bool).attach(self)
    add_function(libname, :JSValueIsNumber, [:JSContextRef, :JSValueRef], :bool).attach(self)
    add_function(libname, :JSValueIsString, [:JSContextRef, :JSValueRef], :bool).attach(self)
    add_function(libname, :JSValueIsObject, [:JSContextRef, :JSValueRef], :bool).attach(self)
    add_function(libname, :JSValueIsObjectOfClass, [:JSContextRef, :JSValueRef, :JSClassRef], :bool).attach(self)
    add_function(libname, :JSValueIsEqual, [:JSContextRef, :JSValueRef, :JSValueRef, :JSValueRef], :bool).attach(self)
    add_function(libname, :JSValueIsStrictEqual, [:JSContextRef, :JSValueRef, :JSValueRef], :bool).attach(self)
    add_function(libname, :JSValueIsInstanceOfConstructor, [:JSContextRef, :JSValueRef, :JSObjectRef, :JSValueRef], :bool).attach(self)
    add_function(libname, :JSValueMakeUndefined, [:JSContextRef], {:object=>{:name=>:JSValue,:namespace=>:JavaScriptCore}}).attach(this)
    add_function(libname, :JSValueMakeNull, [:JSContextRef], {:object=>{:name=>:JSValue,:namespace=>:JavaScriptCore}}).attach(this)
    add_function(libname, :JSValueMakeBoolean, [:JSContextRef, :bool], {:object=>{:name=>:JSValue,:namespace=>:JavaScriptCore}}).attach(this)
    add_function(libname, :JSValueMakeNumber, [:JSContextRef, :double], {:object=>{:name=>:JSValue,:namespace=>:JavaScriptCore}}).attach(this)
    add_function(libname, :JSValueMakeString, [:JSContextRef, :JSStringRef], {:object=>{:name=>:JSValue,:namespace=>:JavaScriptCore}}).attach(this)
    add_function(libname, :JSValueMakeFromJSONString, [:JSContextRef, :JSStringRef], {:object=>{:name=>:JSValue,:namespace=>:JavaScriptCore}}).attach(this)
    add_function(libname, :JSValueCreateJSONString, [:JSContextRef, :JSValueRef, :unsigned, :JSValueRef], {:object=>{:name=>:JSValue,:namespace=>:JavaScriptCore}}).attach(this)
    add_function(libname, :JSValueToBoolean, [:JSContextRef, :JSValueRef], :bool).attach(self)
    add_function(libname, :JSValueToNumber, [:JSContextRef, :JSValueRef, :JSValueRef], :double).attach(self)
    add_function(libname, :JSValueToStringCopy, [:JSContextRef, :JSValueRef, :JSValueRef], {:object=>{:name=>:JSString,:namespace=>:JavaScriptCore}}).attach(self)
    add_function(libname, :JSValueToObject, [:JSContextRef, :JSValueRef, :JSValueRef], {:object=>{:name=>:JSObject,:namespace=>:JavaScriptCore}}).attach(self)
    add_function(libname, :JSValueProtect, [:JSContextRef, :JSValueRef], :void).attach(self)
    add_function(libname, :JSValueUnprotect, [:JSContextRef, :JSValueRef], :void).attach(self)
  end
end

#
