# -File- ./ext/js_jsstring.rb
#

module JS::String
  def get_utf8_cstring
    ptr = CFunc::Pointer.malloc(get_length+1)
    super(ptr,get_length+1)
    return ptr.to_s
  end
  
  def to_s
    get_utf8_cstring
  end
end

class JS::JSString
  def initialize *o
    super
    extend JS::String
  end
end

#
