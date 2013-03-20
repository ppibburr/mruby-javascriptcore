#
# -File- ./javascriptcore.rb
#

module JavaScriptCore
    def self.libname()
      unless @libname
        gir = GirBind.gir
        gir.require("JSCore")
        @libname = gir.shared_library("JSCore").split(",").last
        if !@libname.index("lib")
          @libname = "lib#{@libname}.so"
        end
      end
      @libname
    end
end

#
# -File- ./jsc_bind/argument.rb
#

module JSCBind
  module Argument
    def make_pointer v
      if type == :JSStringRef
        if v.is_a?(CFunc::Pointer)
          return v
        else
          str = JS::JSString.create_with_utf8_cstring(v)
          return str.to_ptr
        end
      else
        super
      end
    end
  end
end

#
# -File- ./jsc_bind/function.rb
#

module JSCBind
  class Function < FFIBind::Function
    def attach where
      this = self
      q=where.to_s.split("::").last
      
      if q.index(">")
        q = q[0..q.length-2]
      end
      
      name = @name.to_s.split(q).last
      
      l = nil
      c = nil
      idxa = []
      
      for i in 0..name.length-1
        pl = l
        pc = c
        l = name[i] if name[i].downcase == name[i]
        c = name[i] if name[i].downcase != name[i] and l
        if l and c
          idxa << i-1
          l = nil
          c = nil
          pl = nil
          pc = nil
        end        
      end
      
      c = 0
      idxa.each do |i|
        f=name[0..i+c]
        l=name[i+c+1..name.length-1]
        name = f+"_"+l
        c+=1
      end
      
      where.define_method name.downcase do |*o,&b|
        aa = where.ancestors
        if aa.index(JSCBind::ObjectWithContext)
          if this.arguments[0].type == :JSContextRef
            o = [context,self].push(*o)
          end
        elsif aa.index(JSCBind::Object)
          o = [self].push(*o)
        end
   
        result = this.invoke(*o,&b)
        if result.is_a?(JSCBind::ObjectWithContext)
          if !result.context
            result.set_context(o[0])
          end
        end
        next result
      end
    end
  end
end  
  
#
# -File- ./jsc_bind/object.rb
#  
  
module JSCBind  
  class Object < FFIBind::ObjectBase 
    def self.libname()
      unless @libname
        gir = GirBind.gir
        gir.require("JSCore")
        @libname = gir.shared_library("JSCore").split(",").last
        if !@libname.index("lib")
          @libname = "lib#{@libname}.so"
        end
      end
      @libname
    end   
  
    def self.add_function(*o)
      o[1] = o[1].to_s
      obj = nil
      if o.last.is_a? Hash
        obj = o.last
        o[o.length-1] = :pointer
      end
      
      f = JSCBind::Function.add_function(*o)
      f.arguments.each do |a|
        a.extend JSCBind::Argument
      end
      if obj
        f.return_type.type = :object
        f.return_type.object = obj[:object]
      end
      
      return f
    end
  end
end

#
# -file- ./jsc_bind/object_with_context.rb
#

module JSCBind
  class ObjectWithContext < self::Object
    attr_accessor :context
    def set_context(ctx)
      if !ctx.is_a?(JavaScriptCore::JSContext)
        ctx = JavaScriptCore::JSContext.wrap(ctx)
      end
      
      @context = ctx
    end
  end
end

#
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
# -File- ./JSPropertyNameAccumulatorRef.rb
#

module JavaScriptCore
  class JSPropertyNameAccumulator < JSCBind::Object
    this = class << self;self;end

    add_function(libname, :JSPropertyNameAccumulatorAddName, [:JSPropertyNameAccumulatorRef, :JSStringRef], :void).attach(self)
  end
end

#
# -File- ./js.rb
#

JS=JavaScriptCore

module JS
  f = JSCBind::Function.add_function libname,:JSEvaluateScript,[:JSContextRef,:JSStringRef,:JSObjectRef,:JSStringRef,:int,:JSValueRef],:JSValueRef
  this = class << self;self;end
  f.attach(this)
  f1 = JSCBind::Function.add_function libname,:JSCheckScriptSyntax,[:JSContextRef,:JSStringRef,:JSStringRef,:int,:JSValueRef],:bool
  f1.attach(this)

  def self.execute_script(ctx,str,this=nil)
    str = JSString.create_with_utf8_cstring(str)
    if jscheck_script_syntax(ctx,str,nil,0,nil)
      v=JSValue.wrap(jsevaluate_script(ctx,str,this,nil,0,nil))
      v.context = ctx
      return v.to_ruby
    end
  end
end

#
# -File- ./ext/js_jsobject.rb
#

module JS::Object
  def set_property prop,v
    raise "must specify name" unless prop
    v = JSValue.from_ruby(context,v)
    if prop.is_a?(Integer)
      return set_property_at_index(prop,v)
    end
    prop = prop.to_s
    return super(prop,v,nil,nil)
  end
  
  def get_property prop
    raise "must specify name" unless prop  
    if prop.is_a?(Integer)
      v = get_property_at_index(prop)
    else
      prop = prop.to_s
      v = super prop,nil
    end
    return v.to_ruby
  end
  
  def set_property_at_index i,v
    super(i,v,nil);
  end
  
  def get_property_at_index i
    super(i,nil)
  end  
  
  def [] k
    return get_property(k)
  end
  
  def []= k,v
    return set_property(k,v)
  end  
  
  def to_value
    str = JSString.create_with_utf8_cstring("this;")
    v = JS::jsevaluate_script(context,str,self,nil,0,nil)
    v = JS::JSValue.wrap(v)
    v.set_context(context)
    return v
  end
  
  def call_as_function *o,&b
    vary = o.map do |v| JS::JSValue.from_ruby(context,v) end
    jary = CFunc::Pointer[vary.length]
    vary.each_with_index do |v,i|
      jary[i].value = v.to_ptr
    end

    super(nil,vary.length,jary,nil).to_ruby
  end
end

class JS::JSObject
  o = ::Object.new
  o.extend FFI::Library
  o.callback(:JSObjectCallAsFunctionCallback,[:pointer,:pointer,:pointer,:pointer,:pointer,:pointer],:pointer)

  CALLBACKS = []
  class << self
    alias :_make_ :make
    def make ctx,cls = nil, q = nil
      _make_ ctx,cls,q
    end  

    alias :_make_function_with_callback_ :make_function_with_callback
    def make_function_with_callback ctx,name = nil, &b
      _make_function_with_callback_ ctx,name do |*o|
        ctx = JS::JSContext.wrap(o[0])
        this = JS::JSObject.wrap(o[2])
        this.set_context(ctx)
        len = CFunc::UInt32.refer(o[3].addr).value
        
        ca = CFunc::CArray(CFunc::Pointer).refer(o[4].addr)
        a = []
        
        for i in 0..len-1
          ptr = ca[i].value
          
          v = JS::JSValue.wrap(ptr)
          v.set_context(ctx)
          
          a << v.to_ruby
        end
        
        JS::JSValue.from_ruby(ctx,b.call(*a)).to_ptr
      end
    end  
  end
  def initialize *o
    super
    extend JS::Object
  end
  
  def self.new ctx,v=nil,&b
    if b
      return make_function_with_callback(ctx,&b)
    elsif v.is_a?(Array) or v.is_a?(Hash)
      return JS::JSValue.from_ruby(ctx,v).to_ruby
    else
      raise "JS::JSObject.new 2nd argument must be of NilClass, Hash or Array"
    end
  end
end

#
# -File- ./ext/js_jsvalue.rb
#

class JS::JSValue
  def self.from_ruby ctx,v
    if v == true or v == false
      return make_boolean(ctx,v)
    elsif v.is_a?(Numeric)
      return make_number(ctx,v.to_f)
    elsif v.is_a?(::String)
      return make_string(ctx,v)
    elsif v.is_a?(Hash)
      obj = JSObject.make(ctx)
      v.each_key do |k|
        obj.set_property(k.to_s,v[k])
      end
      return obj.to_value
    elsif v.is_a?(Array)
      obj = JSObject.make(ctx)
      v.each_with_index do |q,i|
        obj[i] = q
      end
      return obj.to_value
    elsif v.is_a?(Symbol)
      return make_string(ctx,v.to_s)
    elsif v.is_a?(JS::JSObject)
      return v.to_value
    elsif v.is_a? Proc
      obj = JS::JSObject.make_function_with_callback(ctx,&v)
      return obj.to_value
    elsif v == nil
      return make_undefined(ctx)
    end
  end
  
  def to_ruby
    if is_object
      self.protect
      return to_object nil
    elsif is_number
      n = to_number nil
      if n.floor == n
        return n.floor
      else
        return n
      end
    elsif is_string
      return to_string_copy(nil).to_s
    elsif is_boolean
      return to_boolean
    elsif is_undefined
      return nil
    elsif is_null
      return nil
    
      raise "JS::Value#to_ruby Conversion Error"
    end
  end
end

#
# -File- ./ext/js_jsstring.rb
#

module JS::String
  def get_utf8_cstring
    ptr = CFunc::Pointer.malloc(12)
    super(ptr,get_length+1)
    return ptr.to_s
  end
  
  def to_s
    get_utf8_cstring
  end
end

class JS::JSString
  def initialize *o
    super
    extend JS::String
  end
end

