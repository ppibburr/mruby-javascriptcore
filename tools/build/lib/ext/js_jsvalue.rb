# -File- ./ext/js_jsvalue.rb
#

class JS::JSValue
  def self.from_ruby ctx,v
    if v == true or v == false
      return make_boolean(ctx,v)
    elsif v.is_a?(Numeric)
      return make_number(ctx,v.to_f)
    elsif v.is_a?(::String)
      return make_string(ctx,v)
    elsif v.is_a?(Hash)
      obj = JSObject.make(ctx)
      v.each_key do |k|
        obj.set_property(k.to_s,v[k])
      end
      return obj.to_value
    elsif v.is_a?(Array)
      obj = JSObject.make(ctx)
      v.each_with_index do |q,i|
        obj[i] = q
      end
      return obj.to_value
    elsif v.is_a?(Symbol)
      return make_string(ctx,v.to_s)
    elsif v.is_a?(JS::JSObject)
      return v.to_value
    elsif v.is_a? Proc
      obj = JS::JSObject.make_function_with_callback(ctx,&v)
      return obj.to_value
    elsif v == nil
      return make_undefined(ctx)
    end
  end
  
  def to_ruby
    if is_object
      self.protect
      return to_object nil
    elsif is_number
      n = to_number nil
      if n.floor == n
        return n.floor
      else
        return n
      end
    elsif is_string
      return to_string_copy(nil).to_s
    elsif is_boolean
      return to_boolean
    elsif is_undefined
      return nil
    elsif is_null
      return nil
    
      raise "JS::Value#to_ruby Conversion Error"
    end
  end
end

#
