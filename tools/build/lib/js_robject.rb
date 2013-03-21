# -File- ./js_robject.rb
#

module JS  
  module RObject
    OBJECT_STORE = {}
  
	  CLASS_DEF = JSClassDefinition.new
	  CLASS_DEF[:version] = 0
	  
	  CLASS_DEF[:getProperty] = RObjectGetProperty = CFunc::Closure.new(CFunc::Pointer,[CFunc::Pointer,CFunc::Pointer,CFunc::Pointer,CFunc::Pointer]) do |ctx,obj,name,err|
      ctx = JSContext.wrap(ctx)
      str = JSString.wrap(name)
      name = str.to_s
      addr = CFunc::UInt16.get(obj.addr)

      undefined = JSValue.make_undefined(ctx)

      if (ruby = OBJECT_STORE[addr])
        if ruby.respond_to?(name.to_sym)
          result = JSValue.from_ruby ctx do |*o,&b|
            ruby.send(name,*o,&b)
          end
        end
      end
      
      if result
        next result.to_ptr
      else
        next undefined.to_ptr
      end
    end
    
	  RObjectClass = JSClass.create(CLASS_DEF.addr.value)  
	  
    def self.make(ctx,v=Object)
      ins = JSObject.make(ctx,RObjectClass,nil)
     
      ins.extend self
      ins.mapped = {}
      ins.ruby = v
      
      addr = CFunc::UInt16.get(ins.to_ptr.addr)
      
      OBJECT_STORE[addr] = v
      
      ins.set_context ctx
      
      return ins
    end
    
    
    attr_accessor :mapped,:ruby
  end
end
