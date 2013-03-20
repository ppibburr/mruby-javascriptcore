# -File- ./JSStringRef.rb
#

module JavaScriptCore
  class JSString < JSCBind::Object
    this = class << self;self;end

    add_function(libname, :JSStringCreateWithCharacters, [:JSChar, :size_t], {:object=>{:name=>:JSString,:namespace=>:JavaScriptCore}}).attach(this)
    add_function(libname, :JSStringCreateWithUTF8CString, [:string], {:object=>{:name=>:JSString,:namespace=>:JavaScriptCore}}).attach(this)
    add_function(libname, :JSStringRetain, [:JSStringRef], {:object=>{:name=>:JSString,:namespace=>:JavaScriptCore}}).attach(self)
    add_function(libname, :JSStringRelease, [:JSStringRef], :void).attach(self)
    add_function(libname, :JSStringGetLength, [:JSStringRef], :size_t).attach(self)
    add_function(libname, :JSStringGetCharactersPtr, [:JSStringRef], :JSChar).attach(self)
    add_function(libname, :JSStringGetMaximumUTF8CStringSize, [:JSStringRef], :size_t).attach(self)
    add_function(libname, :JSStringGetUTF8CString, [:JSStringRef, :char, :size_t], :size_t).attach(self)
    add_function(libname, :JSStringIsEqual, [:JSStringRef, :JSStringRef], :bool).attach(self)
    add_function(libname, :JSStringIsEqualToUTF8CString, [:JSStringRef, :string], :bool).attach(self)
  end
end

#
