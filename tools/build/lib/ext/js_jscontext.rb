# -File- ./ext/js_jscontext.rb
#

class JS::JSContext
  def execute str,this = nil
    return JS::execute_script(self,str,this)
  end
end

#
