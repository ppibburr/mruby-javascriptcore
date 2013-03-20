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
end

module JS::ObjectIsFunction
  attr_accessor :this
  def call_as_function this,*o,&b
    vary = o.map do |v| JS::JSValue.from_ruby(context,v) end
    jary = CFunc::Pointer[vary.length]
    vary.each_with_index do |v,i|
      jary[i].value = v.to_ptr
    end

    super(this,vary.length,jary,nil).to_ruby
  end
    
  def call(*o,&b)
    call_as_function this,*o,&b
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
    if is_function
      extend JS::ObjectIsFunction
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
