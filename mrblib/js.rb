unless FFI.const_defined? :Closure
  class FFI::Closure < FFI::Function
    def initialize a,rt,&b
      super rt,a,&b
    end
  end
end

module JS
  def self.context
    JavaScriptCore::GlobalContext.create(nil)
  end
  
  def self.execute(ctx, str, this=nil)
    jstr = JavaScriptCore::String.createWithUTF8CString(str)
    v=JavaScriptCore::evaluateScript(ctx, jstr, this, nil, 0, nil.to_ptr) 
    jstr.release
    JS::Value.to_ruby(v)
  end
  
  module IsFunctionProperty
    attr_accessor :this
  end

  module HasContext    
    def self.extended q
      q.class_eval do
        attr_reader :context
        def context= c
          @context = c.is_a?(JavaScriptCore::Context) ? c : JavaScriptCore::GlobalContext.wrap(c)
        end
      end
    end
  end
  
  module String
    def self.get_string jstr
      l=jstr.getLength + 1    
      buff = FFI::MemoryPointer.new(:int8,l)
      jstr.getUTF8CString(buff,l)
    end
  end
  
  module Value
    def self.from_ruby ctx, v
      unless ctx.is_a?(JavaScriptCore::Context)
        ctx = JavaScriptCore::GlobalContext.wrap(ctx)
      end
    
      if v.is_a?(JavaScriptCore::Object)
        v = JS::Object.to_value(v)
        v.protect
        return v
      
      elsif v.is_a?(JavaScriptCore::Value)
        v.protect

        return v
      end
    
      if v.is_a?(Integer)
        JavaScriptCore::Value::makeNumber(ctx, v.to_f)
      
      elsif v.is_a?(Float)
        JavaScriptCore::Value::makeNumber(ctx, v)
      
      elsif v.is_a?(::String)
        jstr = JavaScriptCore::String.createWithUTF8CString(v)
        q=JavaScriptCore::Value::makeString(ctx, jstr)
        jstr.release
        return q
        
      elsif v == true
        JavaScriptCore::Value::makeBoolean(ctx, v)
      
      elsif v == false
        JavaScriptCore::Value::makeBoolean(ctx, v)
      
      elsif v.is_a?(Proc)
        from_ruby(ctx, JS::Object.from_ruby(ctx, v))
      
      elsif v.is_a?(Array)
        from_ruby(ctx, JS::Object.from_ruby(ctx, v))
      
      elsif v.is_a?(Hash)
        from_ruby(ctx, JS::Object.from_ruby(ctx, v))
      
      elsif !v
        JavaScriptCore::Value::makeNull(ctx)
      
      else
        raise "JS::Value#initialize: Cannot initialize from #{v.class}"
      end
    end
    
    def self.get_string(v, ctx = nil)
      ctx = v.context ? v.context : ctx
      
      raise "Value does not have context set and no context passed." unless ctx
      
      v.context ||= ctx
      
      jstr = v.toStringCopy
      
      r=JS::String.get_string(jstr)
      jstr.release
      return r
    end
    
    def self.to_ruby v, ctx=nil
      ctx = v.context ? v.context : ctx
      
      raise "Value does not have context set and no context passed." unless ctx
      
      v.context ||= ctx
      
      case v.getType()
      when JavaScriptCore::ValueType::UNDEFINED
        nil
      when JavaScriptCore::ValueType::NULL
        nil
      when JavaScriptCore::ValueType::BOOLEAN
        v.toBoolean
      when JavaScriptCore::ValueType::NUMBER
        v.toNumber
      when JavaScriptCore::ValueType::STRING
        get_string(v)
      when JavaScriptCore::ValueType::OBJECT
        v.toObject()
      else
        raise "Cannot covert value: #{v}"
      end
    end
  end
  
  module Object
    def []= k,v
      jstr = JavaScriptCore::String.createWithUTF8CString(k.to_s)
      jv = JS::Value.from_ruby(context, v)
      r=setProperty(jstr, jv, 0, nil.to_ptr)
      jstr.release
      return r
    end
    
    def [] k
      jstr = JavaScriptCore::String.createWithUTF8CString(k.to_s)
      jv = getProperty(jstr, nil.to_ptr)
      q=JS::Value.to_ruby(jv)
      
      if q.is_a?(JS::Object)
        q.extend JS::IsFunctionProperty
        q.this = self
      end
      
      jstr.release
      
      return q
    end
    
    def properties
      pa = copyPropertyNames
      
      a = []
      
      for i in 0..pa.getCount-1
        a << pa.getNameAtIndex(i)
      end
      
      pa.release
      
      return a
    end
    
    def each_property &b
      properties.each do |prop| yield prop end
    end
    
    def toString
      JS::execute(context, "Object.prototype.toString.call(this);",self)
    end
    
    def call *o, &b
      if b
        o << JS::Object.from_ruby(context, b)
      end
    
      jva = FFI::MemoryPointer.new(:pointer, o.length)

      jva.write_array_of_pointer(o.map do |q|
        JS::Value.from_ruby(context, q).to_ptr
      end)
      
      r=callAsFunction(@this, o.length, jva, nil.to_ptr)

      JS::Value.to_ruby r
    end
    
    def self.to_value(o, ctx=nil)
      ctx = o.context ? o.context : ctx
      
      raise "Value does not have context set and no context passed." unless ctx
      
      o.context ||= ctx    
    
      jstr = JavaScriptCore::String.createWithUTF8CString("this;")
      v=JavaScriptCore::evaluateScript(ctx, jstr, o, nil, 0, nil.to_ptr)  
      
      jstr.release
      
      return v
    end
    
    def self.from_ruby ctx, o
      if o.is_a?(Hash)
        jo = JavaScriptCore::Object.make(ctx, nil, nil.to_ptr)

        o.keys.each do |k|
          jo[k] = o[k]
        end
        
        return jo
        
      elsif o.is_a?(::Array)
        o = o.map do |q|
          v=JS::Value.from_ruby(ctx, q).to_ptr
        end

        jva = FFI::MemoryPointer.new(:pointer, o.length)
        jva.write_array_of_pointer(o)
        
        return jo = JavaScriptCore::Object.makeArray(ctx, o.length, jva, nil.to_ptr)
      
      elsif o.is_a?(Proc)
        jo = JavaScriptCore::Object.makeFunctionWithCallback(ctx, nil) do |ctx_, fun, this, len, args, e|
          ctx_ = JavaScriptCore::GlobalContext.wrap(ctx_)
          this = JavaScriptCore::Object.wrap(this)
          this.context = ctx_

          a = args.read_array_of_pointer(len).map do |q|
            q = JavaScriptCore::Value.wrap(q)
            q.context = ctx_
            q = JS::Value.to_ruby(q)
          end
          
          result = o.call(ctx_,this,*a)

          JS::Value.from_ruby(ctx_, result).to_ptr
        end

        return jo
      else
        raise "Cannot make Object from #{o.class}"
      end
    end     
    
    def method_missing m,*o,&b
      if m.to_s[m.to_s.length-1] == ("=")
        self[m.to_s.split("=")[0]] = o[0]
      else
        self[m]
      end
    end
  end
end

module JavaScriptCore
  class ValueType
    [:undefined, :null, :boolean, :number, :string, :object].each_with_index do |n,i|
      const_set n.to_s.upcase, i
    end
  end
  
  module Lib
    extend FFI::Library
    ffi_lib "libjavascriptcoregtk-3.0.so.0"


    typedef :uint, :JSClassAttributes
    typedef :uint, :JSPropertyAttributes  

    typedef :pointer, :JSObjectRef
    typedef :pointer, :JSValueRef
    typedef :pointer, :JSStringRef
    typedef :pointer, :JSClassRef
    typedef :pointer, :JSGlobalContextRef
    typedef :pointer, :JSContextRef
    typedef :pointer, :JSPropertyNameArrayRef    
    typedef :uint, :unsigned
    typedef :pointer, :JSPropertyNameAccumulatorRef
                    
    enum :JSType, [:undefined, :null, :boolean, :number, :string, :object]

    callback :JSObjectGetPropertyCallback,[:JSContextRef,:JSObjectRef,:JSStringRef,:pointer],:JSValueRef
    callback :JSObjectSetPropertyCallback,[:JSContextRef,:JSObjectRef,:JSStringRef,:JSValueRef,:pointer],:bool
    callback :JSObjectHasPropertyCallback,[:JSContextRef,:JSObjectRef,:JSStringRef],:bool
    callback :JSObjectDeletePropertyCallback,[:JSContextRef,:JSObjectRef,:JSStringRef,:pointer],:bool
    callback :JSObjectCallAsConstructorCallback,[:JSContextRef,:JSObjectRef,:pointer,:pointer],:JSValueRef
    callback :JSObjectHasInstanceCallback,[:JSContextRef,:JSObjectRef,:JSValueRef,:pointer],:bool
    callback :JSObjectConvertToTypeCallback,[:JSContextRef,:JSObjectRef,:JSType,:pointer],:JSValueRef
    callback :JSObjectCallAsConstructorCallback,[:JSContextRef,:JSObjectRef,:size_t,:pointer,:pointer],:JSObjectRef
    callback :JSObjectInitializeCallback,[:JSContextRef,:JSObjectRef,:pointer,:pointer],:JSValueRef
    callback :JSObjectFinalizeCallback,[:JSObjectRef],:void
    callback :JSObjectGetPropertyNamesCallback,[:JSContextRef,:JSObjectRef,:JSPropertyNameAccumulatorRef],:void
    callback :JSObjectInitializeCallback, [], :void
    callback :JSObjectCallAsFunctionCallback, [:JSContextRef, :JSObjectRef, :JSObjectRef, :size_t, :pointer, :pointer], :JSValueRef 
    callback :JSObjectGetPropertyCallback, [:JSContextRef, :JSObjectRef, :JSStringRef, :pointer], :JSValueRef
    
    attach_function :JSGlobalContextCreate, [:pointer], :pointer
    attach_function :JSContextGetGlobalObject, [:pointer], :pointer    
    attach_function :JSEvaluateScript, [:pointer, :pointer, :pointer, :pointer, :int ,:pointer], :pointer
    attach_function :JSStringCreateWithUTF8CString, [:string], :pointer
    
    attach_function :JSValueMakeUndefined,[:JSContextRef],:JSValueRef
    attach_function :JSValueMakeNull,[:JSContextRef],:JSValueRef
    attach_function :JSValueMakeBoolean,[:JSContextRef,:bool],:JSValueRef
    attach_function :JSValueMakeNumber,[:JSContextRef,:double],:JSValueRef
    attach_function :JSValueMakeString,[:JSContextRef,:JSStringRef],:JSValueRef
    attach_function :JSValueGetType,[:JSContextRef,:JSValueRef],:int
    attach_function :JSValueIsUndefined,[:JSContextRef,:JSValueRef],:bool
    attach_function :JSValueIsNull,[:JSContextRef,:JSValueRef],:bool
    attach_function :JSValueIsBoolean,[:JSContextRef,:JSValueRef],:bool
    attach_function :JSValueIsNumber,[:JSContextRef,:JSValueRef],:bool
    attach_function :JSValueIsString,[:JSContextRef,:JSValueRef],:bool
    attach_function :JSValueIsObject,[:JSContextRef,:JSValueRef],:bool
    attach_function :JSValueIsObjectOfClass,[:JSContextRef,:JSValueRef,:JSClassRef],:bool
    attach_function :JSValueIsEqual,[:JSContextRef,:JSValueRef,:JSValueRef,:pointer],:bool
    attach_function :JSValueIsStrictEqual,[:JSContextRef,:JSValueRef,:JSValueRef],:bool
    attach_function :JSValueIsInstanceOfConstructor,[:JSContextRef,:JSValueRef,:JSObjectRef,:pointer],:bool
    attach_function :JSValueToBoolean,[:JSContextRef,:JSValueRef],:bool
    attach_function :JSValueToNumber,[:JSContextRef,:JSValueRef,:pointer],:double
    attach_function :JSValueToStringCopy,[:JSContextRef,:JSValueRef,:pointer],:JSStringRef    
    attach_function :JSValueToObject,[:JSContextRef,:JSValueRef,:pointer],:JSObjectRef
    attach_function :JSValueProtect,[:JSContextRef,:JSValueRef],:void
    attach_function :JSValueUnprotect,[:JSContextRef,:JSValueRef],:void
    
    attach_function :JSStringCreateWithCharacters,[:pointer,:size_t],:JSStringRef
    attach_function :JSStringRetain,[:JSStringRef],:JSStringRef
    attach_function :JSStringRelease,[:JSStringRef],:void
    attach_function :JSStringGetLength,[:JSStringRef],:size_t
    attach_function :JSStringGetCharactersPtr,[:JSStringRef],:pointer
    attach_function :JSStringGetMaximumUTF8CStringSize,[:JSStringRef],:size_t
    attach_function :JSStringGetUTF8CString,[:JSStringRef,:pointer,:size_t],:void
    attach_function :JSStringIsEqual,[:JSStringRef,:JSStringRef],:bool
    attach_function :JSStringIsEqualToUTF8CString,[:JSStringRef,:pointer],:bool    
        
    attach_function :JSObjectMake,[:JSContextRef,:JSClassRef,:pointer],:JSObjectRef
    attach_function :JSObjectMakeFunctionWithCallback,[:JSContextRef,:JSStringRef,:JSObjectCallAsFunctionCallback],:JSObjectRef
    attach_function :JSObjectMakeConstructor,[:JSContextRef,:JSClassRef,:pointer],:JSObjectRef
    attach_function :JSObjectMakeArray,[:JSContextRef,:size_t,:JSValueRef,:pointer],:JSObjectRef
    attach_function :JSObjectMakeFunction,[:JSContextRef,:JSStringRef,:unsigned,:JSStringRef,:JSStringRef,:JSStringRef,:int,:pointer],:JSObjectRef
    attach_function :JSObjectGetPrototype,[:JSContextRef,:JSObjectRef],:JSValueRef
    attach_function :JSObjectSetPrototype,[:JSContextRef,:JSObjectRef,:JSValueRef],:void
    attach_function :JSObjectHasProperty,[:JSContextRef,:JSObjectRef,:JSStringRef],:bool
    attach_function :JSObjectGetProperty,[:JSContextRef,:JSObjectRef,:JSStringRef,:pointer],:JSValueRef
    attach_function :JSObjectSetProperty,[:JSContextRef,:JSObjectRef,:JSStringRef,:JSValueRef,:int,:pointer],:void
    attach_function :JSObjectDeleteProperty,[:JSContextRef,:JSObjectRef,:JSStringRef,:pointer],:bool
    attach_function :JSObjectGetPropertyAtIndex,[:JSContextRef,:JSObjectRef,:unsigned,:pointer],:JSValueRef
    attach_function :JSObjectSetPropertyAtIndex,[:JSContextRef,:JSObjectRef,:unsigned,:JSValueRef,:pointer],:void
    attach_function :JSObjectGetPrivate,[:JSObjectRef],:pointer
    attach_function :JSObjectSetPrivate,[:JSObjectRef,:pointer],:bool
    attach_function :JSObjectIsFunction,[:JSContextRef,:JSObjectRef],:bool
    attach_function :JSObjectCallAsFunction,[:JSContextRef,:JSObjectRef,:JSObjectRef,:size_t,:JSValueRef,:pointer],:JSValueRef
    attach_function :JSObjectIsConstructor,[:JSContextRef,:JSObjectRef],:bool
    attach_function :JSObjectCallAsConstructor,[:JSContextRef,:JSObjectRef,:size_t,:JSValueRef,:pointer],:JSObjectRef
    attach_function :JSObjectCopyPropertyNames,[:JSContextRef,:JSObjectRef],:JSPropertyNameArrayRef    
    
    attach_function :JSPropertyNameArrayGetCount, [:JSPropertyNameArrayRef ], :int
    attach_function :JSPropertyNameArrayGetNameAtIndex, [:JSPropertyNameArrayRef, :int ], :JSStringRef
    attach_function :JSPropertyNameArrayRelease, [:JSPropertyNameArrayRef], :void
    
    class ClassDef < FFI::Struct
      layout(:version, :int,
        :attributes,  :uint,
        :className, :pointer,
        :parentClass, :pointer,
        :staticValues, :pointer,
        :staticFunctions, :pointer,
        :initialize, :pointer,
        :finalize, :pointer,
        :hasProperty, :pointer,
        :getProperty, :JSObjectGetPropertyCallback,
        :setProperty, :pointer,
        :deleteProperty, :pointer,
        :getPropertyNames, :pointer,
        :callAsFunction, :pointer,
        :callAsConstructor, :pointer,
        :hasInstance, :pointer,
        :convertToType, :pointer)
    end     
  end

  module ObjectBaseClass
    def self.extended q
      q.class_eval do
        include ObjectBase
      end
    end
    
    def wrap ptr
      ins = allocate
      ins.instance_variable_set("@ptr", ptr)
      return ins
    end
  end
  
  module ObjectBase
    def to_ptr
      @ptr
    end
  end

  module Context
    def getGlobalObject
      ptr = JavaScriptCore::Lib::JSContextGetGlobalObject(self.to_ptr)
      result = JavaScriptCore::Object.wrap(ptr)
      
      result.context = self
      
      return result
    end
  end

  class GlobalContext
    extend ObjectBaseClass
    include Context
    
    def self.create cls=nil
      wrap(JavaScriptCore::Lib::JSGlobalContextCreate(cls.to_ptr))
    end
  end
  
  class PropertyNameArray
    extend ObjectBaseClass
    
    def getCount
      JavaScriptCore::Lib::JSPropertyNameArrayGetCount(to_ptr)
    end
    
    def getNameAtIndex idx
      ptr = JavaScriptCore::Lib::JSPropertyNameArrayGetNameAtIndex(to_ptr, idx)
      result = JavaScriptCore::String.wrap(ptr)
      return JS::String.get_string(result)
    end  
    
    def release
      JavaScriptCore::Lib::JSPropertyNameArrayRelease(to_ptr)
    end  
  end
  
  class self::String
    extend ObjectBaseClass
   
    def self.createWithUTF8CString str
      ptr = JavaScriptCore::Lib::JSStringCreateWithUTF8CString(str)
      
      result = JavaScriptCore::String.wrap(ptr)
      
      return result
    end
    
    def getMaximumUTF8CStringSize
      JavaScriptCore::Lib::JSStringGetMaximumUTF8CStringSize(self.to_ptr)
    end
    
    def getLength
      JavaScriptCore::Lib::JSStringGetLength(self.to_ptr)
    end
    
    def getUTF8CString ptr=FFI::MemoryPointer.new(:int8, getLength+1),l=getLength+1
      JavaScriptCore::Lib::JSStringGetUTF8CString(self.to_ptr, ptr, l)
      return ptr.read_string
    end
    
    def release
      JavaScriptCore::Lib::JSStringRelease(self.to_ptr)
    end
    
    
    define_method :max_strlen do
      getMaximumUTF8CStringSize
    end
  end   

  class Value
    extend JavaScriptCore::ObjectBaseClass
    extend JS::HasContext
    include JS::Value
  
    def self.makeBoolean ctx, bool
      ptr = JavaScriptCore::Lib.JSValueMakeBoolean(ctx.to_ptr, bool)
    
      result = JavaScriptCore::Value.wrap(ptr)
    
      result.context = ctx
      
      return result
    end   
    
    def self.makeNumber ctx, num
      ptr = JavaScriptCore::Lib.JSValueMakeNumber(ctx.to_ptr, num.to_f)
    
      result = JavaScriptCore::Value.wrap(ptr)

      result.context = ctx
      
      return result
    end   
    
    def self.makeString ctx, jstr
      ptr = JavaScriptCore::Lib.JSValueMakeString(ctx.to_ptr, jstr.to_ptr)
    
      result = JavaScriptCore::Value.wrap(ptr)
    
      result.context = ctx
      
      return result
    end   
    
    def self.makeNull ctx
      ptr = JavaScriptCore::Lib.JSValueMakeNull(ctx.to_ptr)
    
      result = JavaScriptCore::Value.wrap(ptr)
    
      result.context = ctx
      
      return result
    end   
    
    def self.makeUndefined ctx
      ptr = JavaScriptCore::Lib.JSValueMakeUndefined(ctx.to_ptr)
    
      result = JavaScriptCore::Value.wrap(ptr)
    
      result.context = ctx
      
      return result
    end  
            
    def protect
      JavaScriptCore::Lib.JSValueProtect(context.to_ptr, self.to_ptr)
    end 
        
    def toBoolean
      JavaScriptCore::Lib.JSValueToBoolean(context.to_ptr, self.to_ptr)
    end
    
    def toNumber err=FFI::Pointer::NULL
      JavaScriptCore::Lib.JSValueToNumber(context.to_ptr, self.to_ptr, err)
    end    
    
    def toStringCopy err=FFI::Pointer::NULL
      ptr = JavaScriptCore::Lib.JSValueToStringCopy(context.to_ptr, self.to_ptr, err)
      result = JavaScriptCore::String.wrap(ptr)
      return result
    end
    
    def toObject err=FFI::Pointer::NULL
      ptr = JavaScriptCore::Lib::JSValueToObject(context.to_ptr, self.to_ptr, err)
      result = JavaScriptCore::Object.wrap(ptr)
      result.context = context
      return(result)
    end
        
    def getType
      JavaScriptCore::Lib.JSValueGetType(context.to_ptr, self.to_ptr)
    end
  end
  
  ClassDef = self::Lib::ClassDef
  
  class self::Object
    extend ObjectBaseClass
    extend JS::HasContext
    include JS::Object
    
    def self.make ctx, cls=nil, data = FFI::Pointer::NULL
      ptr = JavaScriptCore::Lib.JSObjectMake(ctx.to_ptr, cls.to_ptr, data)
      result = wrap(ptr)
      result.context= ctx
      return(result)
    end
    
    def self.makeFunctionWithCallback ctx, name, &b
      ptr = JavaScriptCore::Lib.JSObjectMakeFunctionWithCallback(ctx.to_ptr, name.to_ptr, b)
      result = wrap(ptr)
      result.context= ctx
      return(result)
    end
    
    def self.makeArray ctx, size, ary, err=FFI::Pointer::NULL
      ptr = JavaScriptCore::Lib.JSObjectMakeArray(ctx.to_ptr, size, ary, err)
      result = wrap(ptr)
      result.context= ctx
      return(result)
    end
    
    def setProperty name, value, attr=0, err=FFI::Pointer::NULL
      JavaScriptCore::Lib.JSObjectSetProperty(context.to_ptr, self.to_ptr, name.to_ptr, value.to_ptr, attr, err)
    end
    
    def getProperty name, err=FFI::Pointer::NULL
      ptr = JavaScriptCore::Lib.JSObjectGetProperty(context.to_ptr, self.to_ptr, name.to_ptr, err)
      result = JavaScriptCore::Value.wrap(ptr)
      result.context = context
      return result
    end  
    
    def copyPropertyNames
      ptr = JavaScriptCore::Lib::JSObjectCopyPropertyNames(context.to_ptr, to_ptr)
      result = JavaScriptCore::PropertyNameArray.wrap(ptr)
      return result  
    end
    
    def callAsFunction this, argc, argv, err=FFI::Pointer::NULL
      ptr = JavaScriptCore::Lib.JSObjectCallAsFunction(context.to_ptr, self.to_ptr, this.to_ptr, argc, argv, err)
      result = JavaScriptCore::Value.wrap(ptr)
      result.context = context
      return result
    end
  end
  
  def self.evaluateScript ctx, code, this=nil, url=nil, line=0, err=FFI::Pointer::NULL
    ptr = JavaScriptCore::Lib.JSEvaluateScript(ctx.to_ptr, code.to_ptr, this.to_ptr, url.to_ptr, line, err)
    result = JavaScriptCore::Value.wrap(ptr)
    result.context = ctx
    return result
  end
  
  class self::Class
    extend ObjectBaseClass
  
    def self.create class_def
      ptr = JavaScriptCore::Lib::JSClassCreate(class_def)
      wrap(ptr)
    end
  end  
end

JavaScriptCore::Lib.attach_function :JSClassCreate, [JavaScriptCore::ClassDef], :pointer

class NilClass
  def to_ptr
    FFI::Pointer::NULL
  end
end

module JS
  module RObject
    CLASS_DEF = JavaScriptCore::ClassDef.new
    
    CLASS_DEF.class.members.each do |m|
      CLASS_DEF[m] = FFI::Pointer::NULL unless [:className, :version, :attributes, :getProperty].index m.to_sym
    end
    
    CLASS_DEF[:version] = 0

    CLASS_DEF[:getProperty] = FFI::Closure.new([:pointer,:pointer,:pointer,:pointer], :pointer) do |ctx, object, prop_name, error|
      result = nil
    
      if (ruby=ObjectMap[object.address])
        name = JS::String.get_string(JavaScriptCore::String.wrap(prop_name))

        if ruby.respond_to?(name) or ::Kernel.methods.index(name.to_sym)
          result = Proc.new do |ctx_,this,*o|         
            ruby.send name, *o
          end
        end
      end

      next JS::Value.from_ruby(JavaScriptCore::GlobalContext.wrap(ctx), result).to_ptr
    end
    
    ObjectClass = JavaScriptCore::Class.create(CLASS_DEF)

    ObjectMap = {}
    
    def self.make ctx, ruby=::Object
      o = JavaScriptCore::Object.make ctx, ObjectClass
      ObjectMap[o.to_ptr.address] = ruby
      
      return o    
    end
  end
end

def JS::Object(ctx)
  execute ctx, "Object;",  nil
end

def JS::Array(ctx)
  execute ctx, "Array;",  nil
end

def JS::String(ctx)
  execute ctx, "String;",  nil
end
  
