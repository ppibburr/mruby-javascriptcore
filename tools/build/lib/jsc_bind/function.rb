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
