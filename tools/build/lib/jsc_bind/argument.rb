# -File- ./jsc_bind/argument.rb
#

module JSCBind
  module Argument
    def make_pointer v
      if type == :JSStringRef
        if v.is_a?(CFunc::Pointer)
          return v
        else
          str = JS::JSString.create_with_utf8_cstring(v)
          return str.to_ptr
        end
      else
        super
      end
    end
  end
end

#
