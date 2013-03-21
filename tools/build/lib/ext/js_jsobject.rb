# -File- ./ext/js_jsobject.rb
#

module JS::Object
  def execute str
    return JS::execute_script(context,str,self)
  end

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
    q = v.to_ruby
    if q.is_a?(JSObject) and q.is_function
      q.this = self
    end
    return q
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
  
  def is_array
    if context.execute("Array.isArray(this);",self)
      return true
    end
    return false
  end
end

module JS::ObjectIsArray
  include Enumerable
  def each
    l = self.get_property(:length)-1
    for i in 0..l
      yield get_property(i)
    end
  end
  
  def length
    self[:length]
  end
end


module JS::ObjectIsFunction
  attr_accessor :this
  
  def call_as_function this,*o,&b
    len = o.length
    
    if b
      len += 1
    end
    
    jary = JS.ruby_ary2js_ary(context,o)
    
    if b
      v = JS::JSValue.from_ruby(context,&b).to_ptr
      jary[o.length].value = v 
    end

    err = JSValue.make_null(context)

    q = super(this,len,jary,err).to_ruby
  
    if eo=err.to_ruby
      raise eo[:message]
    end
  
    return q
  end
    
  def call(*o,&b)
    return call_as_function this,*o,&b
  end
end

class JS::JSObject
  o = ::Object.new
  o.extend FFI::Library
  
  o.callback(:JSObjectCallAsFunctionCallback,[:pointer,:pointer,:pointer,:pointer,:pointer,:pointer],:pointer)
  
  o.typedef :int,:JSType
  
  o.callback :JSObjectGetPropertyCallback,[:JSContextRef,:JSObjectRef,:JSStringRef,:pointer],:JSValueRef
  o.callback :JSObjectSetPropertyCallback,[:JSContextRef,:JSObjectRef,:JSStringRef,:JSValueRef,:pointer],:bool
  o.callback :JSObjectHasPropertyCallback,[:JSContextRef,:JSObjectRef,:JSStringRef],:bool
  o.callback :JSObjectDeletePropertyCallback,[:JSContextRef,:JSObjectRef,:JSStringRef,:pointer],:bool
  o.callback :JSObjectCallAsConstructorCallback,[:JSContextRef,:JSObjectRef,:pointer,:pointer],:JSValueRef
  o.callback :JSObjectHasInstanceCallback,[:JSContextRef,:JSObjectRef,:JSValueRef,:pointer],:bool
  o.callback :JSObjectConvertToTypeCallback,[:JSContextRef,:JSObjectRef,:JSType,:pointer],:JSValueRef
  o.callback :JSObjectCallAsConstructorCallback,[:JSContextRef,:JSObjectRef,:size_t,:pointer,:pointer],:JSObjectRef
  o.callback :JSObjectInitializeCallback,[:JSContextRef,:JSObjectRef,:pointer,:pointer],:JSValueRef
  o.callback :JSObjectFinalizeCallback,[:JSObjectRef],:void
  o.callback :JSObjectGetPropertyNamesCallback,[:JSContextRef,:JSObjectRef,:JSPropertyNameAccumulatorRef],:void  
  
  CALLBACKS = []

  class << self
    alias :_make_ :make
    def make ctx,cls = nil, q = nil
      ins = _make_ ctx,cls,q
      
      return ins
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
        
        if a.last.is_a?(JS::JSObject) and a.last.is_function
          closure = a.pop
        end
        
        if closure
          next((JS::JSValue.from_ruby(ctx,b.call(*a) do |*oo,&bb|
            next closure.call(*oo,&bb)
          end)).to_ptr)
        else
          next JS::JSValue.from_ruby(ctx,b.call(*a)).to_ptr
        end
      end
    end  
  end
  
  def initialize *o
    super
    extend JS::Object
    if is_function
      extend JS::ObjectIsFunction
    end
    
    addr = CFunc::UInt16.get(to_ptr.addr)
    
    if ruby=RObject::OBJECT_STORE[addr]
      extend RObject
      self.ruby = ruby
    end
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
