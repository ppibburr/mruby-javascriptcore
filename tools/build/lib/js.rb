# -File- ./js.rb
#

JS=JavaScriptCore

module JS
  class SyntaxError < RuntimeError;end

  f = JSCBind::Function.add_function libname,:JSEvaluateScript,[:JSContextRef,:JSStringRef,:JSObjectRef,:JSStringRef,:int,:JSValueRef],:JSValueRef
  this = class << self;self;end
  f.attach(this)
  f1 = JSCBind::Function.add_function libname,:JSCheckScriptSyntax,[:JSContextRef,:JSStringRef,:JSStringRef,:int,:JSValueRef],:bool
  f1.attach(this)

  def self.execute_script(ctx,str,this=nil)
    str = JSString.create_with_utf8_cstring(str)
    ec = JSValue.make_null(ctx)
    if jscheck_script_syntax(ctx,str,nil,0,ec.to_ptr.addr)
      v=JSValue.wrap(jsevaluate_script(ctx,str,this,nil,0,nil))
      v.context = ctx
      return v.to_ruby
    else
      e = ec.to_ruby
      n = e[:name]
      msg = e[:message] 
      raise SyntaxError.new("#{n}: #{msg}")
    end
  end
end

#
