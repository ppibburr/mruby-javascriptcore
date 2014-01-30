module JS
  def self.context
    JavaScriptCore::GlobalContext.create(nil)
  end
  
  def self.execute(ctx, str, this=nil)
    jstr = JavaScriptCore::String.createWithUTF8CString(str)
    JavaScriptCore::evaluateScript(ctx, jstr, this, nil, 0, nil)  
  end

  module HasContext
    def method! name, args, ret=:void, &b
      invoke = (Proc.new do |symbol, *o| 
        o = [context].push(*o)
        self.class.namespace.clib.send(symbol, *o)
      end)

      function(name, [JavaScriptCore::Context].push(*args), ret, nil, invoke, &b)
    end
    
    def self.extended q
      q.class_eval do
        attr_accessor :context
      end
    end
  end
  
  module String
    def self.get_string jstr
      buff = FFI::MemoryPointer.new(:pointer)
      l=jstr.getLength
      jstr.getUTF8CString(buff,l+1)
    end
  end
  
  module Value
    def self.from_ruby ctx, v
      if v.is_a?(JavaScriptCore::Object)
        return JS::Object.to_value(v)
      elsif v.is_a?(JavaScriptCore::Value)
        return v
      end
    
      if v.is_a?(Integer)
        JavaScriptCore::Value::makeNumber(ctx, v.to_f)
      elsif v.is_a?(Float)
        JavaScriptCore::Value::makeNumber(ctx, v)
      elsif v.is_a?(::String)
        jstr = JavaScriptCore::String.createWithUTF8CString(v)
        JavaScriptCore::Value::makeString(ctx, jstr)
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
      
      JS::String.get_string(jstr)
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
      setProperty(jstr, jv, 0, nil)
    end
    
    def [] k
      jstr = JavaScriptCore::String.createWithUTF8CString(k.to_s)
      jv = getProperty(jstr, nil)
      JS::Value.to_ruby(jv)
    end 
    
    def call this=nil, *o
      jva = FFI::MemoryPointer.new(:pointer, o.length)
      jva.write_array_of_pointer(o.map do |q|
        JS::Value.from_ruby(context, q).to_ptr
      end)
      JS::Value.to_ruby callAsFunction(this, o.length, jva, nil)
    end
    
    def self.to_value(o, ctx=nil)
      ctx = o.context ? o.context : ctx
      
      raise "Value does not have context set and no context passed." unless ctx
      
      o.context ||= ctx    
    
      jstr = JavaScriptCore::String.createWithUTF8CString("this;")
      JavaScriptCore::evaluateScript(ctx, jstr, o, nil, 0, nil)  
    end
    
    def self.from_ruby ctx, o
      if o.is_a?(Hash)
        jo = JavaScriptCore::Object.make(ctx, nil, nil)
        
        o.keys.each do |k|
          jo[k] = o[k]
        end
        
        return jo
        
      elsif o.is_a?(::Array)
        o = o.map do |q|
          JS::Value.from_ruby(ctx, q)
        end
      
        jva = FFI::MemoryPointer.new(:pointer, o.length)
        jva.write_array_of_pointer(o)
        return jo = JavaScriptCore::Object.makeArray(ctx, o.length, jva, nil)
      
      elsif o.is_a?(Proc)
        return jo = JavaScriptCore::Object.makeFunctionWithCallback(ctx, nil) do |ctx_, fun, this, len, args, e|
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

FFI::Helper.namespace :JavaScriptCore, "libjavascriptcoregtk-3.0.so.0" do
  const_set :ValueType, c=Class.new
  
  [:undefined, :null, :boolean, :number, :string, :object].each_with_index do |n,i|
    c.const_set n.to_s.upcase, i
  end


  clib.typedef :uint, :JSClassAttributes
  clib.typedef :uint, :JSPropertyAttributes  
  clib.enum :JSType, :undefined, :null, :boolean, :number, :string, :object

  object(:Class, :JSClassRef)
  object :Object, :JSObjectRef
  object(:Value, :JSValueRef)

  interface :Context, :JSContextRef do
    function_symbol do |name|
      name[0] = name[0].capitalize    
      :"JSContext#{name}"
    end
    
    function(:getGlobalObject, [] , JavaScriptCore::Object) do |result, *o|
      result.context = o[0]
      next(result)
    end
  end

  clib.callback :JSObjectInitializeCallback, [], :void
  clib.callback :JSObjectCallAsFunctionCallback, [:JSContextRef, :JSObjectRef, :JSObjectRef, :size_t, :pointer, :pointer], :JSValueRef 
  
  object :String, :JSStringRef do
    function_symbol do |name|
      name[0] = name[0].capitalize    
      :"JSString#{name}"
    end  
  
    constructor :createWithUTF8CString, :string
    
    function(:getMaximumUTF8CStringSize, [], :int)
    function(:getLength,[], :int)
    
    function(:getUTF8CString, [:pointer, :size_t], :size_t) do |result, *o|
      o[1].read_string
    end
    
    
    define_method :max_strlen do
      getMaximumUTF8CStringSize
    end
  end   
  
  JavaScriptCore::Value.describe do
    extend JS::HasContext
    include JS::Value
    
    
    function_symbol do |name|
      name[0] = name[0].capitalize    
      :"JSValue#{name}"
    end  
  
    constructor :makeBoolean, JavaScriptCore::Context, :bool do |result, *o|
      result.context = o[0]
      next result
    end

    constructor :makeNumber, JavaScriptCore::Context, :double do |result, *o|
      result.context = o[0]
      next result
    end
    
    constructor :makeString, JavaScriptCore::Context, JavaScriptCore::String  do |result, *o|
      result.context = o[0]
      next result
    end    
    
    constructor :makeNull, JavaScriptCore::Context do |result, *o|
      result.context = o[0]
      next result
    end    
    
    constructor :makeUndefined, JavaScriptCore::Context do |result, *o|
      result.context = o[0]
      next result
    end    
            
    method!(:toBoolean, [], :bool)
    method!(:toNumber, [], :double)
    method!(:toStringCopy, [], JavaScriptCore::String)
    
    method!(:toObject, [], JavaScriptCore::Object) do |result, *o|
      result.context = context
      next(result)
    end
        
    method!(:getType, [], :int)
  end
  
  struct(:ClassDef, :JSClassDef,
                    :version => :int,
                    :attributes => :uint,
                    :className => :string,
                    :parentClass => :pointer,
                    :staticValues => :pointer,
                    :staticFunctions => :pointer,
                    :initialize => :pointer,
                    :finalize => :pointer,
                    :hasProperty => :pointer,
                    :getProperty => :pointer,
                    :setProperty => :pointer,
                    :deleteProperty => :pointer,
                    :getPropertyNames => :pointer,
                    :callAsFunction => :pointer,
                    :callAsConstructor => :pointer,
                    :hasInstance => :pointer,
                    :convertToType => :pointer)

  JavaScriptCore::Class.describe do |klass|
    function_symbol do |name|
      name[0] = name[0].capitalize    
      :"JSClass#{name}"
    end
      
    constructor(:create, JavaScriptCore::ClassDef)
  end

  object :GlobalContext, :JSGlobalContextRef do |klass|
    include JavaScriptCore::Context
  
    function_symbol do |name|
      name[0] = name[0].capitalize    
      :"JSGlobalContext#{name}"
    end  
  
    constructor(:create, JavaScriptCore::Class)
  end  
  
  JavaScriptCore::Object.describe do
    function_symbol do |name|
      name[0] = name[0].capitalize
      :"JSObject#{name}"
    end
    
    extend JS::HasContext
    include JS::Object
    
    constructor(:make, JavaScriptCore::GlobalContext, JavaScriptCore::Class, :pointer) do |result, ctx, *o|
      result.context= ctx
      next(result)
    end
    
    constructor :makeFunctionWithCallback, JavaScriptCore::GlobalContext, JavaScriptCore::String, {:callback=>:JSObjectCallAsFunctionCallback} do |result, ctx, *o|
      result.context = ctx
      next(result)
    end
    
    constructor :makeArray, JavaScriptCore::GlobalContext, :size_t, :pointer, :pointer do |result, ctx, *o|
      result.context = ctx
      next result
    end
    
    method!(:setProperty, [JavaScriptCore::String, JavaScriptCore::Value, :JSPropertyAttributes, :pointer])
    method!(:getProperty, [JavaScriptCore::String, :pointer], JavaScriptCore::Value) do |result, *o|
      result.context= context
      next result
    end  
    
    method! :callAsFunction, [JavaScriptCore::Object, :size_t, :pointer, :pointer], JavaScriptCore::Value do |result, *o|
      result.context = context
      next result
    end
  end
  
  function_symbol do |name|
    name[0] = name[0].upcase
    :"JS#{name}"
  end
  
  function(:evaluateScript, [self::Context, self::String, self::Object, self::String, :int, :pointer], self::Value, :class) do |result, ctx, *o|
    result.context = ctx
    next(result)
  end
end

# Create a Context
cx = JS.context

# get the Context's global object
jo = cx.getGlobalObject

# set "a" to "f"
jo[:a] = "f"
jo[:a] #=> "f"

# set "b" to 3.45
jo[:b] = 3.45
jo[:b] #=> 3.45

# set "c" to a function (adds arg1 and arg2)
jo[:c] = Proc.new do |ctx_, this, *o|
  o[0] + o[1]
end

# call a function
jo[:c].call(nil,1,2) #=> 3

# create a Object from a Hash
jo[:d] = {
  :foo  => 3, # Number
  :bar  => Proc.new do |ctx_, this, *args| puts "Called with #{args.length}, args." end, # function
  :quux => [1,2,3] # Array
}

# properties as methods
jo.d.foo
jo.d.quux[2]
jo.d.bar.call(nil, 1, 2, "foo")

# Prove JS can reach us
JS.execute(cx, "function moof() {return 5;};this.bar(1,2,3,4,5,6);", jo.d)

# And that we can reach JS
p jo.moof.call()
