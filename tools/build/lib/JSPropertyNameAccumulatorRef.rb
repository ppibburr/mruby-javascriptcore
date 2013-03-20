# -File- ./JSPropertyNameAccumulatorRef.rb
#

module JavaScriptCore
  class JSPropertyNameAccumulator < JSCBind::Object
    this = class << self;self;end

    add_function(libname, :JSPropertyNameAccumulatorAddName, [:JSPropertyNameAccumulatorRef, :JSStringRef], :void).attach(self)
  end
end

#
