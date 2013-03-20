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
