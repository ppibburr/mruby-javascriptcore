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
