# File: /home/ppibburr/git/mruby-javascriptcore/tmp/0.rb
JSCORE_PATH = '/usr/lib/libjavascriptcoregtk-3.0.so.0'
# File: /home/ppibburr/git/mruby-javascriptcore/tmp/1.rb


class Float
  def ffi_ptr
    CFunc::Double.new(CFunc::Float.new(self))
  end
end

class Integer
  def ffi_ptr
    CFunc::UInt32.new(self)
  end
end


class Hash
  def each_pair &b
    each do |k,v|
      b.call k,v
    end
  end
end


module FFI

 class Wrapped
   attr_reader :ffi_ptr
   def self.prefix pre=nil
     if pre
       @prefix = pre
     else
       @prefix
     end
   end
   
   def self.method_missing m,*o,&b
       add_function m
       send m,*o,&b
   rescue
     super
   end   
   
   def self.add_constructor n
     @constructor = n.to_s
     self::Lib.attach_function self.prefix+"_"+n.to_s
   end
   
   def self.constructor
     @constructor
   end
   
   class << self
     alias :new_ :new
   end
   
   def self.new *o,&b
     add_constructor "new"
     new_ *o,&b
   end
   
   def add_function m
   p m
     self::Lib.attach_function self.prefix+"_"+m.to_s
     class << self;self;end.class_eval do
       define_method m do |*o,&b|
         self::Lib.send(self.prefix+"_"+m.to_s,*o,&b)
       end
     end   
   end
   
   def self.add_instance_method n
     self::Lib.attach_function self.prefix+"_"+n.to_s
     this=self
     define_method n do |*o,&b|
       self.class::Lib.send(this.prefix+"_"+n.to_s,self,*o,&b)
     end
   end
  
   def method_missing m,*o,&b
     self.class.add_instance_method m.to_s
     send m,*o,&b
    rescue
      super
   end  
   
   def initialize *o
     @ffi_ptr = self.class::Lib.send(self.class.prefix.to_s+"_"+self.class.constructor.to_s,*o).addr
   end
 end
 
 module Lib
  def self.extended q

  end
  
  def get_dlopen
    dlh = CFunc::call(CFunc::Pointer, "dlopen", nil, nil)
    open_ptr = CFunc::call(CFunc::Pointer, "dlsym", dlh, "dlopen")
  end
  
  def initialize
    get_dlopen()
  end
  
  def get_library_handle_for lib
    CFunc::call(CFunc::Pointer, get_dlopen(),lib,true )
  end


  def ffi_lib lib
    @library = get_library_handle_for lib
  end
  
  def call_func name,types,*o
  p types
    types = [[],nil] if types.length == 0
    name=name.to_s
    ptr = CFunc::call(CFunc::Pointer, "dlsym", @library, name)
    p ptr
    p name,:moof
    p o
    p [:fun_call,name]
    p o
    f=CFunc::FunctionPointer.new(ptr)
    p [:func_ptr,f]
    p [:result_type,f.result_type = find_type(types.last)]
    ta=[]
    types[0].each do |t|
    ta << find_type(t)
      p [:get_type,t,ta.last]
      
    end
    f.arguments_type=ta
    p ta#;exit
    r=f.call(*o)
    p r
    if types.last == :bool
      r.value == 1
    else
      r.value
    end
  end
  def typedef *o
    @@types[o[1]] = q=find_type(o[0])

  end
  @@callbacks = {}
  def find_type t
    @@types[t] || (@@callbacks[t] ? CFunc::Closure : CFunc::Pointer)
  end
  def callback sym,params,result
    pa = []
    params.each do |prm|
      pa << find_type(prm)
    end
    @@callbacks[sym] = CFunc::Closure.new(find_type(result), pa) do |*o|
      o
    end
  end
  @@types = {
    :int=>CFunc::Int,
    :uint=>CFunc::UInt32,
    :bool=>CFunc::Int,
    :string=>CFunc::Pointer,
    :pointer=>CFunc::Pointer,
    :void=>CFunc::Void,
    :double=>CFunc::Float,
    :size_t=>CFunc::Int
  }
  def attach_function name,*types
    this = self
    
    class << self;self;end.class_eval do
      define_method name do |*o,&b|
        if b;exit
          o << b
        end
        o.each_with_index do |q,i|
          if q.respond_to?(:ffi_ptr)
            o[i] = q.ffi_ptr
          elsif o.is_a?(Proc)
            exit
          end
        end

        this.call_func(name,types,*o)
      end
    end
  end
 end
end

class FFI::AutoPointer
  def to_ffi_value
    @ffi_ptr.addr
  end

end

module Builder
  def prefix n=nil
    @prefix = n if n
    @prefix
  end
  
  def add_function n
    r=self::Lib.attach_function q=@prefix+"_"+n.to_s
   # p q
    class << self;self;end.class_eval do
      define_method n do |*o|
      p q
        self::Lib.send(q,*o)
      end
    end
    r
  end
  
  def method_missing m,*o,&b
    add_function m.to_s
    send m,*o,&b
  rescue => e
    p e
    super
  end
  
  def load_class sym,sc=FFI::Wrapped
    const_set sym,c=Class.new(sc)
    
    this = self
    
    c.class_eval do
      const_set :Lib,this::Lib
    end
  end
end
module FFI;module Lib
  def types
    @@types
  end
end;end
module FFI
  class AutoPointer
    attr_accessor :ffi_ptr
    def initialize h
     @ffi_ptr = h
    end
  end
   class Struct < CFunc::Struct
   def self.every(a,i)
     b=[]
     q=a.clone
     d=[]
     c=0
     until q.empty?
       for n in 0..i-1
         d << q.shift
       end
       p d[1] = JS::Lib.find_type(d[1])
       b.push *d.reverse
       d=[]
       p JS::Lib.types
     end
     p b
     b
   end
   def self.layout *o
     define *every(o,2)
   end
 end
end

#       base_object.rb
             
#		(The MIT License)
#
#        Copyright 2011 Matt Mesanko <tulnor@linuxwaves.com>
#
#		Permission is hereby granted, free of charge, to any person obtaining
#		a copy of this software and associated documentation files (the
#		'Software'), to deal in the Software without restriction, including
#		without limitation the rights to use, copy, modify, merge, publish,
#		distribute, sublicense, and/or sell copies of the Software, and to
#		permit persons to whom the Software is furnished to do so, subject to
#		the following conditions:
#
#		The above copyright notice and this permission notice shall be
#		included in all copies or substantial portions of the Software.
#
#		THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
#		EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#		MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#		IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#		CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#		TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#		SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 

module JS
  class BaseObject < FFI::AutoPointer
    OBJECTS = {}
      attr_accessor :pointer
	  def self.release ptr
		# puts "#{ptr} released"
		if is_a?(JS::Object)
		  OBJECTS.delete(ptr.address)
		  nil
		elsif is_a?(JS::PropertyNameArray)
		  puts "name array"
		end
	  end
	  
	  def self.is_wrapped?(ptr)
		  OBJECTS[ptr.addr]
	  end
	  
	  def initialize(ptr)
		@pointer = ptr
		super
		if self.is_a?(JS::Object)
		  OBJECTS[ptr.addr] = self
		end
	  end
	  
	  def to_ptr
		@pointer
	  end
	end
end

def check_use ptr
  nil
end
    
    

#       Object.rb
             
#		(The MIT License)
#
#        Copyright 2011 Matt Mesanko <tulnor@linuxwaves.com>
#
#		Permission is hereby granted, free of charge, to any person obtaining
#		a copy of this software and associated documentation files (the
#		'Software'), to deal in the Software without restriction, including
#		without limitation the rights to use, copy, modify, merge, publish,
#		distribute, sublicense, and/or sell copies of the Software, and to
#		permit persons to whom the Software is furnished to do so, subject to
#		the following conditions:
#
#		The above copyright notice and this permission notice shall be
#		included in all copies or substantial portions of the Software.
#
#		THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
#		EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#		MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#		IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#		CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#		TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#		SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 
module JS
  module Lib
    class Object < JS::BaseObject

      # Creates a JavaScript object.
      #
      # @param [:JSContextRef] ctx The execution context to use.
      # @param [:JSClassRef] jsClass The JSClass to assign to the object. Pass NULL to use the default object class.
      # @param [:pointer] data A void* to set as the object's private data. Pass NULL to specify no private data.
      # @return A JSObject with the given class and private data.
      def self.make(ctx,jsClass,data)
        JS::Lib.JSObjectMake(ctx,jsClass,data)
      end

      # Convenience method for creating a JavaScript function with a given callback as its implementation.
      #
      # @param [:JSContextRef] ctx The execution context to use.
      # @param [:JSStringRef] name A JSString containing the function's name. This will be used when converting the function to string. Pass NULL to create an anonymous function.
      # @param [:JSObjectCallAsFunctionCallback] callAsFunction The JSObjectCallAsFunctionCallback to invoke when the function is called.
      # @return A JSObject that is a function. The object's prototype will be the default function prototype.
      def self.make_function_with_callback(ctx,name,callAsFunction)
        JS::Lib.JSObjectMakeFunctionWithCallback(ctx,name,callAsFunction)
      end

      # Convenience method for creating a JavaScript constructor.
      #
      # @param [:JSContextRef] ctx The execution context to use.
      # @param [:JSClassRef] jsClass A JSClass that is the class your constructor will assign to the objects its constructs. jsClass will be used to set the constructor's .prototype property, and to evaluate 'instanceof' expressions. Pass NULL to use the default object class.
      # @param [:pointer] callAsConstructor A JSObjectCallAsConstructorCallback to invoke when your constructor is used in a 'new' expression. Pass NULL to use the default object constructor.
      # @return A JSObject that is a constructor. The object's prototype will be the default object prototype.
      def self.make_constructor(ctx,jsClass,callAsConstructor)
        JS::Lib.JSObjectMakeConstructor(ctx,jsClass,callAsConstructor)
      end

      # Creates a JavaScript Array object.
      #
      # @param [:JSContextRef] ctx The execution context to use.
      # @param [:size_t] argumentCount An integer count of the number of arguments in arguments.
      # @param [:JSValueRef] arguments A JSValue array of data to populate the Array with. Pass NULL if argumentCount is 0.
      # @param [:pointer] exception A pointer to a JSValueRef in which to store an exception, if any. Pass NULL if you do not care to store an exception.
      # @return A JSObject that is an Array.
      def self.make_array(ctx,argumentCount,arguments,exception)
        JS::Lib.JSObjectMakeArray(ctx,argumentCount,arguments,exception)
      end

      # Creates a function with a given script as its body.
      #
      # @param [:JSContextRef] ctx The execution context to use.
      # @param [:JSStringRef] name A JSString containing the function's name. This will be used when converting the function to string. Pass NULL to create an anonymous function.
      # @param [:unsigned] parameterCount An integer count of the number of parameter names in parameterNames.
      # @param [:JSStringRef] parameterNames A JSString array containing the names of the function's parameters. Pass NULL if parameterCount is 0.
      # @param [:JSStringRef] body A JSString containing the script to use as the function's body.
      # @param [:JSStringRef] sourceURL A JSString containing a URL for the script's source file. This is only used when reporting exceptions. Pass NULL if you do not care to include source file information in exceptions.
      # @param [:int] startingLineNumber An integer value specifying the script's starting line number in the file located at sourceURL. This is only used when reporting exceptions.
      # @param [:pointer] exception A pointer to a JSValueRef in which to store a syntax error exception, if any. Pass NULL if you do not care to store a syntax error exception.
      # @return A JSObject that is a function, or NULL if either body or parameterNames contains a syntax error. The object's prototype will be the default function prototype.
      def self.make_function(ctx,name,parameterCount,parameterNames,body,sourceURL,startingLineNumber,exception)
        JS::Lib.JSObjectMakeFunction(ctx,name,parameterCount,parameterNames,body,sourceURL,startingLineNumber,exception)
      end

      # Gets an object's prototype.
      #
      # @param [:JSContextRef] ctx  The execution context to use.
      # @param [:JSObjectRef] object A JSObject whose prototype you want to get.
      # @return A JSValue that is the object's prototype.
      def get_prototype(ctx,object)
        JS::Lib.JSObjectGetPrototype(ctx,object)
      end

      # Sets an object's prototype.
      #
      # @param [:JSContextRef] ctx  The execution context to use.
      # @param [:JSObjectRef] object The JSObject whose prototype you want to set.
      # @param [:JSValueRef] value A JSValue to set as the object's prototype.
      def set_prototype(ctx,object,value)
        p :fffggg
        JS::Lib.JSObjectSetPrototype(ctx,object,value)
        p :ggghhhh
      end

      # Tests whether an object has a given property.
      #
      # @param [:JSObjectRef] object The JSObject to test.
      # @param [:JSStringRef] propertyName A JSString containing the property's name.
      # @return true if the object has a property whose name matches propertyName, otherwise false.
      def has_property(ctx,object,propertyName)
        JS::Lib.JSObjectHasProperty(ctx,object,propertyName)
      end

      # Gets a property from an object.
      #
      # @param [:JSContextRef] ctx The execution context to use.
      # @param [:JSObjectRef] object The JSObject whose property you want to get.
      # @param [:JSStringRef] propertyName A JSString containing the property's name.
      # @param [:pointer] exception A pointer to a JSValueRef in which to store an exception, if any. Pass NULL if you do not care to store an exception.
      # @return The property's value if object has the property, otherwise the undefined value.
      def get_property(ctx,object,propertyName,exception)
        JS::Lib.JSObjectGetProperty(ctx,object,propertyName,exception)
      end

      # Sets a property on an object.
      #
      # @param [:JSContextRef] ctx The execution context to use.
      # @param [:JSObjectRef] object The JSObject whose property you want to set.
      # @param [:JSStringRef] propertyName A JSString containing the property's name.
      # @param [:JSValueRef] value A JSValue to use as the property's value.
      # @param [:pointer] exception A pointer to a JSValueRef in which to store an exception, if any. Pass NULL if you do not care to store an exception.
      # @param [:pointer] attributes A logically ORed set of JSPropertyAttributes to give to the property.
      def set_property(ctx,object,propertyName,value,attributes,exception)
              p :fffggg
        JS::Lib.JSObjectSetProperty(ctx,object,propertyName,value,attributes,exception)
                p :fffgggrrrr
      end

      # Deletes a property from an object.
      #
      # @param [:JSContextRef] ctx The execution context to use.
      # @param [:JSObjectRef] object The JSObject whose property you want to delete.
      # @param [:JSStringRef] propertyName A JSString containing the property's name.
      # @param [:pointer] exception A pointer to a JSValueRef in which to store an exception, if any. Pass NULL if you do not care to store an exception.
      # @return true if the delete operation succeeds, otherwise false (for example, if the property has the kJSPropertyAttributeDontDelete attribute set).
      def delete_property(ctx,object,propertyName,exception)
        JS::Lib.JSObjectDeleteProperty(ctx,object,propertyName,exception)
      end

      # Gets a property from an object by numeric index.
      #
      # @param [:JSContextRef] ctx The execution context to use.
      # @param [:JSObjectRef] object The JSObject whose property you want to get.
      # @param [:unsigned] propertyIndex An integer value that is the property's name.
      # @param [:pointer] exception A pointer to a JSValueRef in which to store an exception, if any. Pass NULL if you do not care to store an exception.
      # @return The property's value if object has the property, otherwise the undefined value.
      def get_property_at_index(ctx,object,propertyIndex,exception)
        JS::Lib.JSObjectGetPropertyAtIndex(ctx,object,propertyIndex,exception)
      end

      # Sets a property on an object by numeric index.
      #
      # @param [:JSContextRef] ctx The execution context to use.
      # @param [:JSObjectRef] object The JSObject whose property you want to set.
      # @param [:unsigned] propertyIndex The property's name as a number.
      # @param [:JSValueRef] value A JSValue to use as the property's value.
      # @param [:pointer] exception A pointer to a JSValueRef in which to store an exception, if any. Pass NULL if you do not care to store an exception.
      def set_property_at_index(ctx,object,propertyIndex,value,exception)
        JS::Lib.JSObjectSetPropertyAtIndex(ctx,object,propertyIndex,value,exception)
      end

      # Gets an object's private data.
      #
      # @param [:JSObjectRef] object A JSObject whose private data you want to get.
      # @return A void* that is the object's private data, if the object has private data, otherwise NULL.
      def get_private(object)
        JS::Lib.JSObjectGetPrivate(object)
      end

      # Sets a pointer to private data on an object.
      #
      # @param [:JSObjectRef] object The JSObject whose private data you want to set.
      # @param [:pointer] data A void* to set as the object's private data.
      # @return true if object can store private data, otherwise false.
      def set_private(object,data)
        JS::Lib.JSObjectSetPrivate(object,data)
      end

      # Tests whether an object can be called as a function.
      #
      # @param [:JSContextRef] ctx  The execution context to use.
      # @param [:JSObjectRef] object The JSObject to test.
      # @return true if the object can be called as a function, otherwise false.
      def is_function(ctx,object)
        JS::Lib.JSObjectIsFunction(ctx,object)
      end

      # Calls an object as a function.
      #
      # @param [:JSContextRef] ctx The execution context to use.
      # @param [:JSObjectRef] object The JSObject to call as a function.
      # @param [:JSObjectRef] thisObject The object to use as "this," or NULL to use the global object as "this."
      # @param [:size_t] argumentCount An integer count of the number of arguments in arguments.
      # @param [:JSValueRef] arguments A JSValue array of arguments to pass to the function. Pass NULL if argumentCount is 0.
      # @param [:pointer] exception A pointer to a JSValueRef in which to store an exception, if any. Pass NULL if you do not care to store an exception.
      # @return The JSValue that results from calling object as a function, or NULL if an exception is thrown or object is not a function.
      def call_as_function(ctx,object,thisObject,argumentCount,arguments,exception)
        JS::Lib.JSObjectCallAsFunction(ctx,object,thisObject,argumentCount,arguments,exception)
      end

      # Tests whether an object can be called as a constructor.
      #
      # @param [:JSContextRef] ctx  The execution context to use.
      # @param [:JSObjectRef] object The JSObject to test.
      # @return true if the object can be called as a constructor, otherwise false.
      def is_constructor(ctx,object)
        JS::Lib.JSObjectIsConstructor(ctx,object)
      end

      # Calls an object as a constructor.
      #
      # @param [:JSContextRef] ctx The execution context to use.
      # @param [:JSObjectRef] object The JSObject to call as a constructor.
      # @param [:size_t] argumentCount An integer count of the number of arguments in arguments.
      # @param [:JSValueRef] arguments A JSValue array of arguments to pass to the constructor. Pass NULL if argumentCount is 0.
      # @param [:pointer] exception A pointer to a JSValueRef in which to store an exception, if any. Pass NULL if you do not care to store an exception.
      # @return The JSObject that results from calling object as a constructor, or NULL if an exception is thrown or object is not a constructor.
      def call_as_constructor(ctx,object,argumentCount,arguments,exception)
        JS::Lib.JSObjectCallAsConstructor(ctx,object,argumentCount,arguments,exception)
      end

      # Gets the names of an object's enumerable properties.
      #
      # @param [:JSContextRef] ctx The execution context to use.
      # @param [:JSObjectRef] object The object whose property names you want to get.
      # @return A JSPropertyNameArray containing the names object's enumerable properties. Ownership follows the Create Rule.
      def copy_property_names(ctx,object)
        JS::Lib.JSObjectCopyPropertyNames(ctx,object)
      end
    end
  end
end

#       Value.rb
             
#		(The MIT License)
#
#        Copyright 2011 Matt Mesanko <tulnor@linuxwaves.com>
#
#		Permission is hereby granted, free of charge, to any person obtaining
#		a copy of this software and associated documentation files (the
#		'Software'), to deal in the Software without restriction, including
#		without limitation the rights to use, copy, modify, merge, publish,
#		distribute, sublicense, and/or sell copies of the Software, and to
#		permit persons to whom the Software is furnished to do so, subject to
#		the following conditions:
#
#		The above copyright notice and this permission notice shall be
#		included in all copies or substantial portions of the Software.
#
#		THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
#		EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#		MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#		IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#		CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#		TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#		SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 

#       Context.rb
             
#		(The MIT License)
#
#        Copyright 2011 Matt Mesanko <tulnor@linuxwaves.com>
#
#		Permission is hereby granted, free of charge, to any person obtaining
#		a copy of this software and associated documentation files (the
#		'Software'), to deal in the Software without restriction, including
#		without limitation the rights to use, copy, modify, merge, publish,
#		distribute, sublicense, and/or sell copies of the Software, and to
#		permit persons to whom the Software is furnished to do so, subject to
#		the following conditions:
#
#		The above copyright notice and this permission notice shall be
#		included in all copies or substantial portions of the Software.
#
#		THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
#		EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#		MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#		IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#		CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#		TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#		SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 
module JS
  module Lib
    class Context < JS::BaseObject

      # Gets the global object of a JavaScript execution context.
      #
      # @param [:JSContextRef] ctx The JSContext whose global object you want to get.
      # @return ctx's global object.
      def get_global_object(ctx)
        JS::Lib.JSContextGetGlobalObject(ctx)
      end

      # Gets the context group to which a JavaScript execution context belongs.
      #
      # @param [:JSContextRef] ctx The JSContext whose group you want to get.
      # @return ctx's group.
      def get_group(ctx)
        JS::Lib.JSContextGetGroup(ctx)
      end
    end
  end
end

#       GlobalContext.rb
             
#		(The MIT License)
#
#        Copyright 2011 Matt Mesanko <tulnor@linuxwaves.com>
#
#		Permission is hereby granted, free of charge, to any person obtaining
#		a copy of this software and associated documentation files (the
#		'Software'), to deal in the Software without restriction, including
#		without limitation the rights to use, copy, modify, merge, publish,
#		distribute, sublicense, and/or sell copies of the Software, and to
#		permit persons to whom the Software is furnished to do so, subject to
#		the following conditions:
#
#		The above copyright notice and this permission notice shall be
#		included in all copies or substantial portions of the Software.
#
#		THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
#		EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#		MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#		IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#		CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#		TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#		SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 
module JS
  module Lib
    class GlobalContext < JS::BaseObject

      # Creates a global JavaScript execution context.
      #
      # @param [:JSClassRef] globalObjectClass The class to use when creating the global object. Pass
      # @return A JSGlobalContext with a global object of class globalObjectClass.
      def self.create(globalObjectClass)
        p globalObjectClass
        JS::Lib.JSGlobalContextCreate(globalObjectClass)
      end

      # Creates a global JavaScript execution context in the context group provided.
      #
      # @param [:JSClassRef] globalObjectClass The class to use when creating the global object. Pass
      # @param [:JSContextGroupRef] group The context group to use. The created global context retains the group.
      # @return A JSGlobalContext with a global object of class globalObjectClass and a context
      def self.create_in_group(group,globalObjectClass)
        JS::Lib.JSGlobalContextCreateInGroup(group,globalObjectClass)
      end

      # Retains a global JavaScript execution context.
      #
      # @param [:JSGlobalContextRef] ctx The JSGlobalContext to retain.
      # @return A JSGlobalContext that is the same as ctx.
      def retain(ctx)
        JS::Lib.JSGlobalContextRetain(ctx)
      end

      # Releases a global JavaScript execution context.
      #
      # @param [:JSGlobalContextRef] ctx The JSGlobalContext to release.
      def release(ctx)
        JS::Lib.JSGlobalContextRelease(ctx)
      end
    end
  end
end

#       ContextGroup.rb
             
#		(The MIT License)
#
#        Copyright 2011 Matt Mesanko <tulnor@linuxwaves.com>
#
#		Permission is hereby granted, free of charge, to any person obtaining
#		a copy of this software and associated documentation files (the
#		'Software'), to deal in the Software without restriction, including
#		without limitation the rights to use, copy, modify, merge, publish,
#		distribute, sublicense, and/or sell copies of the Software, and to
#		permit persons to whom the Software is furnished to do so, subject to
#		the following conditions:
#
#		The above copyright notice and this permission notice shall be
#		included in all copies or substantial portions of the Software.
#
#		THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
#		EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#		MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#		IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#		CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#		TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#		SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 
module JS
  module Lib
    class ContextGroup < JS::BaseObject

      # Creates a JavaScript context group.
      #
      # @return The created JSContextGroup.
      def self.create()
        JS::Lib.JSContextGroupCreate()
      end

      # Retains a JavaScript context group.
      #
      # @param [:JSContextGroupRef] group The JSContextGroup to retain.
      # @return A JSContextGroup that is the same as group.
      def retain(group)
        JS::Lib.JSContextGroupRetain(group)
      end
    end
  end
end

#       Value.rb
             
#		(The MIT License)
#
#        Copyright 2011 Matt Mesanko <tulnor@linuxwaves.com>
#
#		Permission is hereby granted, free of charge, to any person obtaining
#		a copy of this software and associated documentation files (the
#		'Software'), to deal in the Software without restriction, including
#		without limitation the rights to use, copy, modify, merge, publish,
#		distribute, sublicense, and/or sell copies of the Software, and to
#		permit persons to whom the Software is furnished to do so, subject to
#		the following conditions:
#
#		The above copyright notice and this permission notice shall be
#		included in all copies or substantial portions of the Software.
#
#		THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
#		EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#		MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#		IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#		CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#		TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#		SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 
module JS
  module Lib
    class Value < JS::BaseObject

      #       Creates a JavaScript value of the undefined type.
      #
      # @param [:JSContextRef] ctx  The execution context to use.
      # @return         The unique undefined value.
      def self.make_undefined(ctx)
        JS::Lib.JSValueMakeUndefined(ctx)
      end

      #       Creates a JavaScript value of the null type.
      #
      # @param [:JSContextRef] ctx  The execution context to use.
      # @return         The unique null value.
      def self.make_null(ctx)
        JS::Lib.JSValueMakeNull(ctx)
      end

      #       Creates a JavaScript value of the boolean type.
      #
      # @param [:JSContextRef] ctx  The execution context to use.
      # @param [:bool] boolean  The bool to assign to the newly created JSValue.
      # @return         A JSValue of the boolean type, representing the value of boolean.
      def self.make_boolean(ctx,boolean)
      p boolean;
        JS::Lib.JSValueMakeBoolean(ctx,boolean)
      end

      #       Creates a JavaScript value of the number type.
      #
      # @param [:JSContextRef] ctx  The execution context to use.
      # @param [:double] number   The double to assign to the newly created JSValue.
      # @return         A JSValue of the number type, representing the value of number.
      def self.make_number(ctx,number)

       r=  JS::Lib.JSValueMakeNumber(ctx,CFunc::Double.new(number))
      

       r
      end

      #       Creates a JavaScript value of the string type.
      #
      # @param [:JSContextRef] ctx  The execution context to use.
      # @param [:JSStringRef] string   The JSString to assign to the newly created JSValue. The
      # @return         A JSValue of the string type, representing the value of string.
      def self.make_string(ctx,string)
        JS::Lib.JSValueMakeString(ctx,string)
      end

      #       Returns a JavaScript value's type.
      #
      # @param [:JSContextRef] ctx  The execution context to use.
      # @param [:JSValueRef] value    The JSValue whose type you want to obtain.
      # @return         A value of type JSType that identifies value's type.
      def get_type(ctx,value)
        JS::Lib.JSValueGetType(ctx,value)
      end

      #       Tests whether a JavaScript value's type is the undefined type.
      #
      # @param [:JSContextRef] ctx  The execution context to use.
      # @param [:JSValueRef] value    The JSValue to test.
      # @return         true if value's type is the undefined type, otherwise false.
      def is_undefined(ctx,value)
        JS::Lib.JSValueIsUndefined(ctx,value)
      end

      #       Tests whether a JavaScript value's type is the null type.
      #
      # @param [:JSContextRef] ctx  The execution context to use.
      # @param [:JSValueRef] value    The JSValue to test.
      # @return         true if value's type is the null type, otherwise false.
      def is_null(ctx,value)
        JS::Lib.JSValueIsNull(ctx,value)
      end

      #       Tests whether a JavaScript value's type is the boolean type.
      #
      # @param [:JSContextRef] ctx  The execution context to use.
      # @param [:JSValueRef] value    The JSValue to test.
      # @return         true if value's type is the boolean type, otherwise false.
      def is_boolean(ctx,value)
        JS::Lib.JSValueIsBoolean(ctx,value)
      end

      #       Tests whether a JavaScript value's type is the number type.
      #
      # @param [:JSContextRef] ctx  The execution context to use.
      # @param [:JSValueRef] value    The JSValue to test.
      # @return         true if value's type is the number type, otherwise false.
      def is_number(ctx,value)
        JS::Lib.JSValueIsNumber(ctx,value)
      end

      #       Tests whether a JavaScript value's type is the string type.
      #
      # @param [:JSContextRef] ctx  The execution context to use.
      # @param [:JSValueRef] value    The JSValue to test.
      # @return         true if value's type is the string type, otherwise false.
      def is_string(ctx,value)
        JS::Lib.JSValueIsString(ctx,value)
      end

      #       Tests whether a JavaScript value's type is the object type.
      #
      # @param [:JSContextRef] ctx  The execution context to use.
      # @param [:JSValueRef] value    The JSValue to test.
      # @return         true if value's type is the object type, otherwise false.
      def is_object(ctx,value)
        JS::Lib.JSValueIsObject(ctx,value)
      end

      # Tests whether a JavaScript value is an object with a given class in its class chain.
      #
      # @param [:JSContextRef] ctx The execution context to use.
      # @param [:JSValueRef] value The JSValue to test.
      # @param [:JSClassRef] jsClass The JSClass to test against.
      # @return true if value is an object and has jsClass in its class chain, otherwise false.
      def is_object_of_class(ctx,value,jsClass)
        JS::Lib.JSValueIsObjectOfClass(ctx,value,jsClass)
      end

      # Tests whether two JavaScript values are equal, as compared by the JS == operator.
      #
      # @param [:JSContextRef] ctx The execution context to use.
      # @param [:JSValueRef] a The first value to test.
      # @param [:JSValueRef] b The second value to test.
      # @param [:pointer] exception A pointer to a JSValueRef in which to store an exception, if any. Pass NULL if you do not care to store an exception.
      # @return true if the two values are equal, false if they are not equal or an exception is thrown.
      def is_equal(ctx,a,b,exception)
        JS::Lib.JSValueIsEqual(ctx,a,b,exception)
      end

      #       Tests whether two JavaScript values are strict equal, as compared by the JS === operator.
      #
      # @param [:JSContextRef] ctx  The execution context to use.
      # @param [:JSValueRef] a        The first value to test.
      # @param [:JSValueRef] b        The second value to test.
      # @return         true if the two values are strict equal, otherwise false.
      def is_strict_equal(ctx,a,b)
        JS::Lib.JSValueIsStrictEqual(ctx,a,b)
      end

      # Tests whether a JavaScript value is an object constructed by a given constructor, as compared by the JS instanceof operator.
      #
      # @param [:JSContextRef] ctx The execution context to use.
      # @param [:JSValueRef] value The JSValue to test.
      # @param [:JSObjectRef] constructor The constructor to test against.
      # @param [:pointer] exception A pointer to a JSValueRef in which to store an exception, if any. Pass NULL if you do not care to store an exception.
      # @return true if value is an object constructed by constructor, as compared by the JS instanceof operator, otherwise false.
      def is_instance_of_constructor(ctx,value,constructor,exception)
        JS::Lib.JSValueIsInstanceOfConstructor(ctx,value,constructor,exception)
      end

      #       Converts a JavaScript value to boolean and returns the resulting boolean.
      #
      # @param [:JSContextRef] ctx  The execution context to use.
      # @param [:JSValueRef] value    The JSValue to convert.
      # @return         The boolean result of conversion.
      def to_boolean(ctx,value)
        JS::Lib.JSValueToBoolean(ctx,value)
      end

      #       Converts a JavaScript value to number and returns the resulting number.
      #
      # @param [:JSContextRef] ctx  The execution context to use.
      # @param [:JSValueRef] value    The JSValue to convert.
      # @param [:pointer] exception A pointer to a JSValueRef in which to store an exception, if any. Pass NULL if you do not care to store an exception.
      # @return         The numeric result of conversion, or NaN if an exception is thrown.
      def to_number(ctx,value,exception)
        JS::Lib.JSValueToNumber(ctx,value,exception)
      end

      #       Converts a JavaScript value to string and copies the result into a JavaScript string.
      #
      # @param [:JSContextRef] ctx  The execution context to use.
      # @param [:JSValueRef] value    The JSValue to convert.
      # @param [:pointer] exception A pointer to a JSValueRef in which to store an exception, if any. Pass NULL if you do not care to store an exception.
      # @return         A JSString with the result of conversion, or NULL if an exception is thrown. Ownership follows the Create Rule.
      def to_string_copy(ctx,value,exception)
        JS::Lib.JSValueToStringCopy(ctx,value,exception)
      end

      # Converts a JavaScript value to object and returns the resulting object.
      #
      # @param [:JSContextRef] ctx  The execution context to use.
      # @param [:JSValueRef] value    The JSValue to convert.
      # @param [:pointer] exception A pointer to a JSValueRef in which to store an exception, if any. Pass NULL if you do not care to store an exception.
      # @return         The JSObject result of conversion, or NULL if an exception is thrown.
      def to_object(ctx,value,exception)
        JS::Lib.JSValueToObject(ctx,value,exception)
      end

      # Protects a JavaScript value from garbage collection.
      #
      # @param [:JSContextRef] ctx The execution context to use.
      # @param [:JSValueRef] value The JSValue to protect.
      def protect(ctx,value)
        JS::Lib.JSValueProtect(ctx,value)
      end

      #       Unprotects a JavaScript value from garbage collection.
      #
      # @param [:JSContextRef] ctx      The execution context to use.
      # @param [:JSValueRef] value    The JSValue to unprotect.
      def unprotect(ctx,value)
        JS::Lib.JSValueUnprotect(ctx,value)
      end
    end
  end
end

#       String.rb
             
#		(The MIT License)
#
#        Copyright 2011 Matt Mesanko <tulnor@linuxwaves.com>
#
#		Permission is hereby granted, free of charge, to any person obtaining
#		a copy of this software and associated documentation files (the
#		'Software'), to deal in the Software without restriction, including
#		without limitation the rights to use, copy, modify, merge, publish,
#		distribute, sublicense, and/or sell copies of the Software, and to
#		permit persons to whom the Software is furnished to do so, subject to
#		the following conditions:
#
#		The above copyright notice and this permission notice shall be
#		included in all copies or substantial portions of the Software.
#
#		THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
#		EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#		MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#		IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#		CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#		TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#		SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 
module JS
  module Lib
    class String < JS::BaseObject

      #         Creates a JavaScript string from a buffer of Unicode characters.
      #
      # @param [:pointer] chars      The buffer of Unicode characters to copy into the new JSString.
      # @param [:size_t] numChars   The number of characters to copy from the buffer pointed to by chars.
      # @return           A JSString containing chars. Ownership follows the Create Rule.
      def self.create_with_characters(chars,numChars)
        JS::Lib.JSStringCreateWithCharacters(chars,numChars)
      end

      #         Creates a JavaScript string from a null-terminated UTF8 string.
      #
      # @param [:pointer] string     The null-terminated UTF8 string to copy into the new JSString.
      # @return           A JSString containing string. Ownership follows the Create Rule.
      def self.create_with_utf8cstring(string)
        JS::Lib.JSStringCreateWithUTF8CString(string)
      end

      #         Retains a JavaScript string.
      #
      # @param [:JSStringRef] string     The JSString to retain.
      # @return           A JSString that is the same as string.
      def retain(string)
        JS::Lib.JSStringRetain(string)
      end

      #         Releases a JavaScript string.
      #
      # @param [:JSStringRef] string     The JSString to release.
      def release(string)
        JS::Lib.JSStringRelease(string)
      end

      #         Returns the number of Unicode characters in a JavaScript string.
      #
      # @param [:JSStringRef] string     The JSString whose length (in Unicode characters) you want to know.
      # @return           The number of Unicode characters stored in string.
      def get_length(string)
        JS::Lib.JSStringGetLength(string)
      end


      def get_characters_ptr(string)
        JS::Lib.JSStringGetCharactersPtr(string)
      end

      # Returns the maximum number of bytes a JavaScript string will
      #
      # @param [:JSStringRef] string The JSString whose maximum converted size (in bytes) you
      # @return The maximum number of bytes that could be required to convert string into a
      def get_maximum_utf8cstring_size(string)
        JS::Lib.JSStringGetMaximumUTF8CStringSize(string)
      end

      # Converts a JavaScript string into a null-terminated UTF8 string,
      #
      # @param [:JSStringRef] string The source JSString.
      # @param [:pointer] buffer The destination byte buffer into which to copy a null-terminated
      # @param [:size_t] bufferSize The size of the external buffer in bytes.
      # @return The number of bytes written into buffer (including the null-terminator byte).
      def get_utf8cstring(string,buffer,bufferSize)

        JS::Lib.JSStringGetUTF8CString(string,buffer,CFunc::Int.new(bufferSize))
      end

      #     Tests whether two JavaScript strings match.
      #
      # @param [:JSStringRef] a      The first JSString to test.
      # @param [:JSStringRef] b      The second JSString to test.
      # @return       true if the two strings match, otherwise false.
      def is_equal(a,b)
        JS::Lib.JSStringIsEqual(a,b)
      end

      #     Tests whether a JavaScript string matches a null-terminated UTF8 string.
      #
      # @param [:JSStringRef] a      The JSString to test.
      # @param [:pointer] b      The null-terminated UTF8 string to test.
      # @return       true if the two strings match, otherwise false.
      def is_equal_to_utf8cstring(a,b)
        JS::Lib.JSStringIsEqualToUTF8CString(a,b)
      end
    end
  end
end

#       PropertyNameArray.rb
             
#		(The MIT License)
#
#        Copyright 2011 Matt Mesanko <tulnor@linuxwaves.com>
#
#		Permission is hereby granted, free of charge, to any person obtaining
#		a copy of this software and associated documentation files (the
#		'Software'), to deal in the Software without restriction, including
#		without limitation the rights to use, copy, modify, merge, publish,
#		distribute, sublicense, and/or sell copies of the Software, and to
#		permit persons to whom the Software is furnished to do so, subject to
#		the following conditions:
#
#		The above copyright notice and this permission notice shall be
#		included in all copies or substantial portions of the Software.
#
#		THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
#		EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#		MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#		IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#		CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#		TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#		SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 
module JS
  module Lib
    class PropertyNameArray < JS::BaseObject

      # Retains a JavaScript property name array.
      #
      # @param [:JSPropertyNameArrayRef] array The JSPropertyNameArray to retain.
      # @return A JSPropertyNameArray that is the same as array.
      def retain(array)
        JS::Lib.JSPropertyNameArrayRetain(array)
      end

      # Releases a JavaScript property name array.
      #
      # @param [:JSPropertyNameArrayRef] array The JSPropetyNameArray to release.
      def release(array)
        JS::Lib.JSPropertyNameArrayRelease(array)
      end

      # Gets a count of the number of items in a JavaScript property name array.
      #
      # @param [:JSPropertyNameArrayRef] array The array from which to retrieve the count.
      # @return An integer count of the number of names in array.
      def get_count(array)
        JS::Lib.JSPropertyNameArrayGetCount(array)
      end

      # Gets a property name at a given index in a JavaScript property name array.
      #
      # @param [:JSPropertyNameArrayRef] array The array from which to retrieve the property name.
      # @param [:size_t] index The index of the property name to retrieve.
      # @return A JSStringRef containing the property name.
      def get_name_at_index(array,index)
        JS::Lib.JSPropertyNameArrayGetNameAtIndex(array,index)
      end
    end
  end
end
if __FILE__ == $0
def require(t)
  File.open("../../mrubyjscore.rb","a") do |f|
    f.puts File.open(t+".rb").read
  end
end

    require "#{File.dirname(__FILE__)}/base_object"
    require File.join(File.dirname(__FILE__),'Object')
    require File.join(File.dirname(__FILE__),'Value')
    require File.join(File.dirname(__FILE__),'Context')
    require File.join(File.dirname(__FILE__),'GlobalContext')
    require File.join(File.dirname(__FILE__),'ContextGroup')
    require File.join(File.dirname(__FILE__),'Value')
    require File.join(File.dirname(__FILE__),'String')
    require File.join(File.dirname(__FILE__),'PropertyNameArray')
end
    if __FILE__ == $0
      exit
    end
#       lib.rb
             
#		(The MIT License)
#
#        Copyright 2011 Matt Mesanko <tulnor@linuxwaves.com>
#
#		Permission is hereby granted, free of charge, to any person obtaining
#		a copy of this software and associated documentation files (the
#		'Software'), to deal in the Software without restriction, including
#		without limitation the rights to use, copy, modify, merge, publish,
#		distribute, sublicense, and/or sell copies of the Software, and to
#		permit persons to whom the Software is furnished to do so, subject to
#		the following conditions:
#
#		The above copyright notice and this permission notice shall be
#		included in all copies or substantial portions of the Software.
#
#		THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
#		EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#		MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#		IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#		CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#		TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#		SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 


module JS
  module Lib
    extend FFI::Lib

    ffi_lib JSCORE_PATH
    typedef :pointer,:JSClassRef
    typedef :pointer,:JSObjectRef
    typedef :pointer,:JSStringRef
    typedef :pointer,:JSValueRef
    typedef :pointer,:JSPropertyNameArrayRef
    typedef :pointer,:JSGlobalContextRef
    #typedef :pointer,:JSContextGroupRef
    #typedef :pointer,:JSContextRef
    #typedef :uint,:unsigned


    callback :JSObjectCallAsFunctionCallback,[:JSContextRef,:JSObjectRef,:JSObjectRef,:size_t,:pointer,:JSValueRef],:JSValueRef

    attach_function :JSEvaluateScript,[:JSContextRef,:JSStringRef,:JSObjectRef,:JSStringRef,:int,:JSValueRef],:JSValueRef
    attach_function :JSCheckScriptSyntax,[:JSContextRef,:JSStringRef,:JSStringRef,:int,:JSValueRef],:bool

    attach_function :JSObjectMake,[:JSContextRef,:JSClassRef,:pointer],:JSObjectRef
    attach_function :JSObjectMakeFunctionWithCallback,[:JSContextRef,:JSStringRef,:JSObjectCallAsFunctionCallback],:JSObjectRef
    attach_function :JSObjectMakeConstructor,[:JSContextRef,:JSClassRef,:pointer],:JSObjectRef
    attach_function :JSObjectMakeArray,[:JSContextRef,:size_t,:JSValueRef,:pointer],:JSObjectRef
    attach_function :JSObjectMakeFunction,[:JSContextRef,:JSStringRef,:unsigned,:JSStringRef,:JSStringRef,:JSStringRef,:int,:pointer],:JSObjectRef
    attach_function :JSObjectGetPrototype,[:JSContextRef,:JSObjectRef],:JSValueRef
    attach_function :JSObjectSetPrototype,[:JSContextRef,:JSObjectRef,:JSValueRef],:void
    attach_function :JSObjectHasProperty,[:JSContextRef,:JSObjectRef,:JSStringRef],:bool
    attach_function :JSObjectGetProperty,[:JSContextRef,:JSObjectRef,:JSStringRef,:pointer],:JSValueRef
    attach_function :JSObjectSetProperty,[:JSContextRef,:JSObjectRef,:JSStringRef,:JSValueRef,:pointer,:pointer],:void
    attach_function :JSObjectDeleteProperty,[:JSContextRef,:JSObjectRef,:JSStringRef,:pointer],:bool
    attach_function :JSObjectGetPropertyAtIndex,[:JSContextRef,:JSObjectRef,:unsigned,:pointer],:JSValueRef
    attach_function :JSObjectSetPropertyAtIndex,[:JSContextRef,:JSObjectRef,:unsigned,:JSValueRef,:pointer],:void
    attach_function :JSObjectGetPrivate,[:JSObjectRef],:pointer
    attach_function :JSObjectSetPrivate,[:JSObjectRef,:pointer],:bool
    attach_function :JSObjectIsFunction,[:JSContextRef,:JSObjectRef],:bool
    attach_function :JSObjectCallAsFunction,[:JSContextRef,:JSObjectRef,:JSObjectRef,:size_t,:JSValueRef,:pointer],:JSValueRef
    attach_function :JSObjectIsConstructor,[:JSContextRef,:JSObjectRef],:bool
    attach_function :JSObjectCallAsConstructor,[:JSContextRef,:JSObjectRef,:size_t,:JSValueRef,:pointer],:JSObjectRef
    attach_function :JSObjectCopyPropertyNames,[:JSContextRef,:JSObjectRef],:JSPropertyNameArrayRef

    attach_function :JSContextGetGlobalObject,[:JSContextRef],:JSObjectRef
    attach_function :JSContextGetGroup,[:JSContextRef],:JSContextGroupRef
    attach_function :JSGlobalContextCreate,[:JSClassRef],:JSGlobalContextRef
    attach_function :JSGlobalContextCreateInGroup,[:JSContextGroupRef,:JSClassRef],:JSGlobalContextRef
    attach_function :JSGlobalContextRetain,[:JSGlobalContextRef],:JSGlobalContextRef
    attach_function :JSGlobalContextRelease,[:JSGlobalContextRef],:void
    attach_function :JSContextGroupCreate,[],:JSContextGroupRef
    attach_function :JSContextGroupRetain,[:JSContextGroupRef],:JSContextGroupRef

    attach_function :JSValueMakeUndefined,[:JSContextRef],:JSValueRef
    attach_function :JSValueMakeNull,[:JSContextRef],:JSValueRef
    attach_function :JSValueMakeBoolean,[:JSContextRef,:bool],:JSValueRef
    attach_function :JSValueMakeNumber,[:JSContextRef,:double],:JSValueRef
    attach_function :JSValueMakeString,[:JSContextRef,:JSStringRef],:JSValueRef
    attach_function :JSValueGetType,[:JSContextRef,:JSValueRef],:int
    attach_function :JSValueIsUndefined,[:JSContextRef,:JSValueRef],:bool
    attach_function :JSValueIsNull,[:JSContextRef,:JSValueRef],:bool
    attach_function :JSValueIsBoolean,[:JSContextRef,:JSValueRef],:bool
    attach_function :JSValueIsNumber,[:JSContextRef,:JSValueRef],:bool
    attach_function :JSValueIsString,[:JSContextRef,:JSValueRef],:bool
    attach_function :JSValueIsObject,[:JSContextRef,:JSValueRef],:bool
    attach_function :JSValueIsObjectOfClass,[:JSContextRef,:JSValueRef,:JSClassRef],:bool
    attach_function :JSValueIsEqual,[:JSContextRef,:JSValueRef,:JSValueRef,:pointer],:bool
    attach_function :JSValueIsStrictEqual,[:JSContextRef,:JSValueRef,:JSValueRef],:bool
    attach_function :JSValueIsInstanceOfConstructor,[:JSContextRef,:JSValueRef,:JSObjectRef,:pointer],:bool
    attach_function :JSValueToBoolean,[:JSContextRef,:JSValueRef],:bool
    attach_function :JSValueToNumber,[:JSContextRef,:JSValueRef,:pointer],:double
    attach_function :JSValueToStringCopy,[:JSContextRef,:JSValueRef,:pointer],:JSStringRef
    attach_function :JSValueToObject,[:JSContextRef,:JSValueRef,:pointer],:JSObjectRef
    attach_function :JSValueProtect,[:JSContextRef,:JSValueRef],:void
    attach_function :JSValueUnprotect,[:JSContextRef,:JSValueRef],:void

    attach_function :JSStringCreateWithCharacters,[:pointer,:size_t],:JSStringRef
    attach_function :JSStringCreateWithUTF8CString,[:pointer],:JSStringRef
    attach_function :JSStringRetain,[:JSStringRef],:JSStringRef
    attach_function :JSStringRelease,[:JSStringRef],:void
    attach_function :JSStringGetLength,[:JSStringRef],:size_t
    attach_function :JSStringGetCharactersPtr,[:JSStringRef],:pointer
    attach_function :JSStringGetMaximumUTF8CStringSize,[:JSStringRef],:size_t
    attach_function :JSStringGetUTF8CString,[:JSStringRef,:pointer,:size_t],:void
    attach_function :JSStringIsEqual,[:JSStringRef,:JSStringRef],:bool
    attach_function :JSStringIsEqualToUTF8CString,[:JSStringRef,:pointer],:bool
    attach_function :JSPropertyNameArrayRetain,[:JSPropertyNameArrayRef],:JSPropertyNameArrayRef
    attach_function :JSPropertyNameArrayRelease,[:JSPropertyNameArrayRef],:void
    attach_function :JSPropertyNameArrayGetCount,[:JSPropertyNameArrayRef],:size_t
    attach_function :JSPropertyNameArrayGetNameAtIndex,[:JSPropertyNameArrayRef,:size_t],:JSStringRef
    attach_function :JSGarbageCollect,[:JSContextRef],:void
  end
end

#       Object.rb
             
#		(The MIT License)
#
#        Copyright 2011 Matt Mesanko <tulnor@linuxwaves.com>
#
#		Permission is hereby granted, free of charge, to any person obtaining
#		a copy of this software and associated documentation files (the
#		'Software'), to deal in the Software without restriction, including
#		without limitation the rights to use, copy, modify, merge, publish,
#		distribute, sublicense, and/or sell copies of the Software, and to
#		permit persons to whom the Software is furnished to do so, subject to
#		the following conditions:
#
#		The above copyright notice and this permission notice shall be
#		included in all copies or substantial portions of the Software.
#
#		THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
#		EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#		MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#		IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#		CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#		TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#		SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 
module JS
  class Object < JS::Lib::Object

    class << self
      alias :real_new :new
    end  
      
    def self.new *o
      if o[0].is_a? Hash and o[0][:pointer] and o.length == 1
        real_new o[0][:pointer]
      else
        return JS::Object.make(*o)
      end
    end
      

  attr_accessor :context
  
  def self.from_pointer_with_context(ctx,ptr)
    res = self.new(:pointer=>ptr)
    res.context = ctx
    res
  end
    

    # Creates a JavaScript object.
    #
    # @param [JS::Context] ctx The execution context to use.
    # @param [JSClassRef] jsClass The JS::Class to assign to the object. Pass nil to use the default object class.
    # @param [FFI::Pointer] data A void* to set as the object's private data. Pass nil to specify no private data.
    # @return [JS::Object] A JS::Object with the given class and private data.
    def self.make(ctx,jsClass = nil,data = nil)
      res = super(ctx,jsClass,data)
      wrap = self.new(:pointer=>res)
      wrap.context = ctx
      return wrap
    end

    # Convenience method for creating a JavaScript function with a given callback as its implementation.
    #
    # @param [JS::Context] ctx The execution context to use.
    # @param [JS::String] name A JS::String containing the function's name. This will be used when converting the function to string. Pass nil to create an anonymous function.
    # @param [Proc] callAsFunction The JS::ObjectCallAsFunctionCallback to invoke when the function is called.
    # @return [JS::Object] A JS::Object that is a function. The object's prototype will be the default function prototype.
    def self.make_function_with_callback(ctx,name = nil,&callAsFunction_)
      name = JS::String.create_with_utf8cstring(name)
      callAsFunction = CFunc::Closure.new(CFunc::Pointer,[CFunc::Pointer,CFunc::Pointer,CFunc::Pointer,CFunc::Pointer(CFunc::Int),CFunc::Pointer(CFunc::CArray),CFunc::Pointer]) do |*o|
     
        JS::CallBack.new(callAsFunction_).call(*o)
      end
      res = super(ctx,name,callAsFunction)
      wrap = self.new(:pointer=>res)
      wrap.context = ctx
      return wrap
    end

    # Convenience method for creating a JavaScript constructor.
    #
    # @param [JS::Context] ctx The execution context to use.
    # @param [JSClassRef] jsClass A JS::Class that is the class your constructor will assign to the objects its constructs. jsClass will be used to set the constructor's .prototype property, and to evaluate 'instanceof' expressions. Pass nil to use the default object class.
    # @param [FFI::Pointer] callAsConstructor A JS::ObjectCallAsConstructorCallback to invoke when your constructor is used in a 'new' expression. Pass nil to use the default object constructor.
    # @return [JS::Object] A JS::Object that is a constructor. The object's prototype will be the default object prototype.
    def self.make_constructor(ctx,jsClass = nil,callAsConstructor = nil)
      res = super(ctx,jsClass,callAsConstructor)
      wrap = self.new(:pointer=>res)
      wrap.context = ctx
      return wrap
    end

    # Creates a JavaScript Array object.
    #
    # @param [JS::Context] ctx The execution context to use.
    # @param [Integer] argumentCount An integer count of the number of arguments in arguments.
    # @param [Array] arguments An Array of JS::Value's of data to populate the Array with. Pass nil if argumentCount is 0.
    # @param [FFI::Pointer] exception A pointer to a JS::ValueRef in which to store an exception, if any. Pass nil if you do not care to store an exception.
    # @return [JS::Object] A JS::Object that is an Array.
    def self.make_array(ctx,argumentCount,arguments,exception = nil)
      res = super(ctx,argumentCount,arguments,exception)
      wrap = self.new(:pointer=>res)
      wrap.context = ctx
      return wrap
    end

    # Creates a function with a given script as its body.
    #
    # @param [JS::Context] ctx The execution context to use.
    # @param [JS::String] name A JS::String containing the function's name. This will be used when converting the function to string. Pass nil to create an anonymous function.
    # @param [Integer] parameterCount An integer count of the number of parameter names in parameterNames.
    # @param [Array] parameterNames An Array of JS::String's containing the names of the function's parameters. Pass nil if parameterCount is 0.
    # @param [JS::String] body A JS::String containing the script to use as the function's body.
    # @param [JS::String] sourceURL A JS::String containing a URL for the script's source file. This is only used when reporting exceptions. Pass nil if you do not care to include source file information in exceptions.
    # @param [Integer] startingLineNumber An integer value specifying the script's starting line number in the file located at sourceURL. This is only used when reporting exceptions.
    # @param [FFI::Pointer] exception A pointer to a JS::ValueRef in which to store a syntax error exception, if any. Pass nil if you do not care to store a syntax error exception.
    # @return [JS::Object] A JS::Object that is a function, or NULL if either body or parameterNames contains a syntax error. The object's prototype will be the default function prototype.
    def self.make_function(ctx,name,parameterCount,parameterNames,body,sourceURL,startingLineNumber,exception = nil)
      name = JS::String.create_with_utf8cstring(name)
      body = JS::String.create_with_utf8cstring(body)
      sourceURL = JS::String.create_with_utf8cstring(sourceURL)
      parameterNames = JS.create_pointer_of_array(JS::String,parameterNames)
      res = super(ctx,name,parameterCount,parameterNames,body,sourceURL,startingLineNumber,exception)
      wrap = self.new(:pointer=>res)
      wrap.context = ctx
      return wrap
    end

    # Gets an object's prototype.
    #
    # @return [JS::Value] A JS::Value that is the object's prototype.
    def get_prototype()
      res = super(context,self)

    
      val_ref = JS::Value.from_pointer_with_context(context,res)
      ret = val_ref.to_ruby
      if ret.is_a?(JS::Value)
        return JS::BaseObject.is_wrapped?(res) || check_use(ret) || is_self(ret) || ret
      else
        return JS::BaseObject.is_wrapped?(res) || check_use(ret) || ret
      end
    
        
    end

    # Sets an object's prototype.
    #
    # @param [JS::Value] value A JS::Value to set as the object's prototype.
    def set_prototype(value)
      value = JS::Value.from_ruby(context,value)
      res = super(context,self,value)
      return res
    end

    # Tests whether an object has a given property.
    #
    # @param [JS::String] propertyName A JS::String containing the property's name.
    # @return [boolean] true if the object has a property whose name matches propertyName, otherwise false.
    def has_property(propertyName)
      propertyName = JS::String.create_with_utf8cstring(propertyName)
      res = super(context,self,propertyName)
      return res
    end

    # Gets a property from an object.
    #
    # @param [JS::String] propertyName A JS::String containing the property's name.
    # @param [FFI::Pointer] exception A pointer to a JS::ValueRef in which to store an exception, if any. Pass nil if you do not care to store an exception.
    # @return [JS::Value] The property's value if object has the property, otherwise the undefined value.
    def get_property(propertyName,exception = nil)
      propertyName = JS::String.create_with_utf8cstring(propertyName)
      res = super(context,self,propertyName,exception)

    
      val_ref = JS::Value.from_pointer_with_context(context,res)
      p :ert
      p ret = val_ref.to_ruby
      p :rwert
      if ret.is_a?(JS::Value)
        return JS::BaseObject.is_wrapped?(res) || check_use(ret) || is_self(ret) || ret
      else
        return JS::BaseObject.is_wrapped?(res) || check_use(ret) || ret
      end
    
        
    end

    # Sets a property on an object.
    #
    # @param [JS::String] propertyName A JS::String containing the property's name.
    # @param [JS::Value] value A JS::Value to use as the property's value.
    # @param [FFI::Pointer] exception A pointer to a JS::ValueRef in which to store an exception, if any. Pass nil if you do not care to store an exception.
    # @param [FFI::Pointer] attributes A logically ORed set of JSPropertyAttributes to give to the property.
    def set_property(propertyName,value,attributes = nil,exception = nil)
    bool = propertyName == "string"
            propertyName_ = JS::Lib::String.create_with_utf8cstring(propertyName)
         

      value_ = JS::Value.from_ruby(context,value)

      p value_.is_string
      p value_.to_string_copy if bool
     # exit if bool
      res = super(context,self,propertyName_,value_,attributes,exception)
      return res
    end

    # Deletes a property from an object.
    #
    # @param [JS::String] propertyName A JS::String containing the property's name.
    # @param [FFI::Pointer] exception A pointer to a JS::ValueRef in which to store an exception, if any. Pass nil if you do not care to store an exception.
    # @return [boolean] true if the delete operation succeeds, otherwise false (for example, if the property has the kJSPropertyAttributeDontDelete attribute set).
    def delete_property(propertyName,exception = nil)
      propertyName = JS::String.create_with_utf8cstring(propertyName)
      res = super(context,self,propertyName,exception)
      return res
    end

    # Gets a property from an object by numeric index.
    #
    # @param [Integer] propertyIndex An integer value that is the property's name.
    # @param [FFI::Pointer] exception A pointer to a JS::ValueRef in which to store an exception, if any. Pass nil if you do not care to store an exception.
    # @return [JS::Value] The property's value if object has the property, otherwise the undefined value.
    def get_property_at_index(propertyIndex,exception = nil)
      res = super(context,self,propertyIndex,exception)

    
      val_ref = JS::Value.from_pointer_with_context(context,res)
      ret = val_ref.to_ruby
      if ret.is_a?(JS::Value)
        return JS::BaseObject.is_wrapped?(res) || check_use(ret) || is_self(ret) || ret
      else
        return JS::BaseObject.is_wrapped?(res) || check_use(ret) || ret
      end
    
        
    end

    # Sets a property on an object by numeric index.
    #
    # @param [Integer] propertyIndex The property's name as a number.
    # @param [JS::Value] value A JS::Value to use as the property's value.
    # @param [FFI::Pointer] exception A pointer to a JS::ValueRef in which to store an exception, if any. Pass nil if you do not care to store an exception.
    def set_property_at_index(propertyIndex,value,exception = nil)

      res = super(context,self,propertyIndex,value,exception)
      return res
    end

    # Gets an object's private data.
    #
    # @return [FFI::Pointer] A void* that is the object's private data, if the object has private data, otherwise NULL.
    def get_private()
      res = super(self)
      return res
    end

    # Sets a pointer to private data on an object.
    #
    # @param [FFI::Pointer] data A void* to set as the object's private data.
    # @return [boolean] true if object can store private data, otherwise false.
    def set_private(data)
      res = super(self,data)
      return res
    end

    # Tests whether an object can be called as a function.
    #
    # @return [boolean] true if the object can be called as a function, otherwise false.
    def is_function()
      res = super(context,self)
      return res
    end

    # @note A convienience method is at JS::Object#call
    # @see Object#call
    # Calls an object as a function.
    #
    # @param [JS::Object] thisObject The object to use as "this," or nil to use the global object as "this."
    # @param [Array] arguments An Array of JS::Value's of arguments to pass to the function. Pass nil if argumentCount is 0.
    # @param [FFI::Pointer] exception A pointer to a JS::ValueRef in which to store an exception, if any. Pass nil if you do not care to store an exception.
    # @return [JS::Value] The JS::Value that results from calling object as a function, or NULL if an exception is thrown or object is not a function.
    def call_as_function(thisObject = nil,argumentCount = 0,arguments = nil,exception = nil)
      thisObject = JS::Object.from_ruby(context,thisObject)

      arguments = JS.create_pointer_of_array(JS::Value,arguments,context)
     p context,self,thisObject,argumentCount,arguments,exception;
      res = super(context,self,thisObject,argumentCount,arguments,exception)

    
      val_ref = JS::Value.from_pointer_with_context(context,res)
      ret = val_ref.to_ruby
      if ret.is_a?(JS::Value)
        return JS::BaseObject.is_wrapped?(res) || check_use(ret) || is_self(ret) || ret
      else
        return JS::BaseObject.is_wrapped?(res) || check_use(ret) || ret
      end
    
        
    end

    # Tests whether an object can be called as a constructor.
    #
    # @return [boolean] true if the object can be called as a constructor, otherwise false.
    def is_constructor()
      res = super(context,self)
      return res
    end

    # Calls an object as a constructor.
    #
    # @param [Array] arguments An Array of JS::Value's of arguments to pass to the constructor. Pass nil if argumentCount is 0.
    # @param [FFI::Pointer] exception A pointer to a JS::ValueRef in which to store an exception, if any. Pass nil if you do not care to store an exception.
    # @return [JS::Object] The JS::Object that results from calling object as a constructor, or NULL if an exception is thrown or object is not a constructor.
    def call_as_constructor(argumentCount = 0,arguments = nil,exception = nil)
      arguments = JS.create_pointer_of_array(JS::Value,arguments,context)
      res = super(context,self,argumentCount,arguments,exception)
      return JS::BaseObject.is_wrapped?(res) || JS::Object.from_pointer_with_context(context,res)
    end

    # Gets the names of an object's enumerable properties.
    #
    # @return [JS::PropertyNameArray] A JS::PropertyNameArray containing the names object's enumerable properties. Ownership follows the Create Rule.
    def copy_property_names()
      res = super(context,self)
      return JS::PropertyNameArray.new(res)
    end
  end
end

#       Value.rb
             
#		(The MIT License)
#
#        Copyright 2011 Matt Mesanko <tulnor@linuxwaves.com>
#
#		Permission is hereby granted, free of charge, to any person obtaining
#		a copy of this software and associated documentation files (the
#		'Software'), to deal in the Software without restriction, including
#		without limitation the rights to use, copy, modify, merge, publish,
#		distribute, sublicense, and/or sell copies of the Software, and to
#		permit persons to whom the Software is furnished to do so, subject to
#		the following conditions:
#
#		The above copyright notice and this permission notice shall be
#		included in all copies or substantial portions of the Software.
#
#		THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
#		EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#		MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#		IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#		CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#		TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#		SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 

#       Context.rb
             
#		(The MIT License)
#
#        Copyright 2011 Matt Mesanko <tulnor@linuxwaves.com>
#
#		Permission is hereby granted, free of charge, to any person obtaining
#		a copy of this software and associated documentation files (the
#		'Software'), to deal in the Software without restriction, including
#		without limitation the rights to use, copy, modify, merge, publish,
#		distribute, sublicense, and/or sell copies of the Software, and to
#		permit persons to whom the Software is furnished to do so, subject to
#		the following conditions:
#
#		The above copyright notice and this permission notice shall be
#		included in all copies or substantial portions of the Software.
#
#		THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
#		EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#		MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#		IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#		CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#		TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#		SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 
module JS
  module Context

    # Gets the global object of a JavaScript execution context.
    #
    # @return [JS::Object] ctx's global object.
    def get_global_object()
      res = JS::Lib.JSContextGetGlobalObject(self)
      context = self
      return JS::BaseObject.is_wrapped?(res) || JS::Object.from_pointer_with_context(context,res)
    end

    # Gets the context group to which a JavaScript execution context belongs.
    #
    # @return [JS::ContextGroup] ctx's group.
    def get_group()
      res = JS::Lib.JSContextGetGroup(self)
    end
  end
end

#       GlobalContext.rb
             
#		(The MIT License)
#
#        Copyright 2011 Matt Mesanko <tulnor@linuxwaves.com>
#
#		Permission is hereby granted, free of charge, to any person obtaining
#		a copy of this software and associated documentation files (the
#		'Software'), to deal in the Software without restriction, including
#		without limitation the rights to use, copy, modify, merge, publish,
#		distribute, sublicense, and/or sell copies of the Software, and to
#		permit persons to whom the Software is furnished to do so, subject to
#		the following conditions:
#
#		The above copyright notice and this permission notice shall be
#		included in all copies or substantial portions of the Software.
#
#		THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
#		EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#		MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#		IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#		CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#		TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#		SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 
module JS
  class GlobalContext < JS::Lib::GlobalContext
    include JS::Context

    class << self
      alias :real_new :new
    end  
      
    def self.new *o
      if o[0].is_a? Hash and o[0][:pointer] and o.length == 1
        real_new o[0][:pointer]
      else
        return JS::GlobalContext.create(*o)
      end
    end
      

    # Creates a global JavaScript execution context.
    #
    # @param [JSClassRef] globalObjectClass The class to use when creating the global object. Pass
    # @return [JS::GlobalContext] A JS::GlobalContext with a global object of class globalObjectClass.
    def self.create(globalObjectClass)
      res = super(globalObjectClass)
      wrap = self.new(:pointer=>res)
      return wrap
    end

    # Creates a global JavaScript execution context in the context group provided.
    #
    # @param [JSClassRef] globalObjectClass The class to use when creating the global object. Pass
    # @param [JS::ContextGroup] group The context group to use. The created global context retains the group.
    # @return [JS::GlobalContext] A JS::GlobalContext with a global object of class globalObjectClass and a context
    def self.create_in_group(group,globalObjectClass)
      res = super(group,globalObjectClass)
      wrap = self.new(:pointer=>res)
      return wrap
    end

    # Retains a global JavaScript execution context.
    #
    # @return [JS::GlobalContext] A JS::GlobalContext that is the same as ctx.
    def retain()
      res = super(self)
    end

    # Releases a global JavaScript execution context.
    #
    def release()
      res = super(self)
      return res
    end
  end
end

#       ContextGroup.rb
             
#		(The MIT License)
#
#        Copyright 2011 Matt Mesanko <tulnor@linuxwaves.com>
#
#		Permission is hereby granted, free of charge, to any person obtaining
#		a copy of this software and associated documentation files (the
#		'Software'), to deal in the Software without restriction, including
#		without limitation the rights to use, copy, modify, merge, publish,
#		distribute, sublicense, and/or sell copies of the Software, and to
#		permit persons to whom the Software is furnished to do so, subject to
#		the following conditions:
#
#		The above copyright notice and this permission notice shall be
#		included in all copies or substantial portions of the Software.
#
#		THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
#		EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#		MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#		IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#		CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#		TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#		SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 
module JS
  class ContextGroup < JS::Lib::ContextGroup

    class << self
      alias :real_new :new
    end  
      
    def self.new *o
      if o[0].is_a? Hash and o[0][:pointer] and o.length == 1
        real_new o[0][:pointer]
      else
        return JS::ContextGroup.create(*o)
      end
    end
      

    # Creates a JavaScript context group.
    #
    # @return [JS::ContextGroup] The created JS::ContextGroup.
    def self.create()
      res = super()
      wrap = self.new(:pointer=>res)
      return wrap
    end

    # Retains a JavaScript context group.
    #
    # @return [JS::ContextGroup] A JS::ContextGroup that is the same as group.
    def retain()
      res = super(self)
    end
  end
end

#       Value.rb
             
#		(The MIT License)
#
#        Copyright 2011 Matt Mesanko <tulnor@linuxwaves.com>
#
#		Permission is hereby granted, free of charge, to any person obtaining
#		a copy of this software and associated documentation files (the
#		'Software'), to deal in the Software without restriction, including
#		without limitation the rights to use, copy, modify, merge, publish,
#		distribute, sublicense, and/or sell copies of the Software, and to
#		permit persons to whom the Software is furnished to do so, subject to
#		the following conditions:
#
#		The above copyright notice and this permission notice shall be
#		included in all copies or substantial portions of the Software.
#
#		THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
#		EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#		MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#		IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#		CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#		TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#		SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 
module JS
  class Value < JS::Lib::Value

    class << self
      alias :real_new :new
    end  
      
    def self.new *o
      if o[0].is_a? Hash and o[0][:pointer] and o.length == 1
        real_new o[0][:pointer]
      else
        return JS::Value.make_undefined(*o)
      end
    end
      

  attr_accessor :context
  
  def self.from_pointer_with_context(ctx,ptr)
    res = self.new(:pointer=>ptr)
    res.context = ctx
    res
  end
    

    #       Creates a JavaScript value of the undefined type.
    #
    # @param [JS::Context] ctx  The execution context to use.
    # @return [JS::Value]         The unique undefined value.
    def self.make_undefined(ctx)
      res = super(ctx)
      wrap = self.new(:pointer=>res)
      wrap.context = ctx
      return wrap
    end

    #       Creates a JavaScript value of the null type.
    #
    # @param [JS::Context] ctx  The execution context to use.
    # @return [JS::Value]         The unique null value.
    def self.make_null(ctx)
      res = super(ctx)
      wrap = self.new(:pointer=>res)
      wrap.context = ctx
      return wrap
    end
    
    def self.make_number ctx,val
      res = super(ctx,val)
      wrap = self.new(:pointer=>res)
      wrap.context = ctx
      return wrap
    end

    #       Creates a JavaScript value of the boolean type.
    #
    # @param [JS::Context] ctx  The execution context to use.
    # @param [boolean] boolean  The bool to assign to the newly created JS::Value.
    # @return [JS::Value]         A JS::Value of the boolean type, representing the value of boolean.
    def self.make_boolean(ctx,boolean)
      res = super(ctx,boolean)
      wrap = self.new(:pointer=>res)
      wrap.context = ctx
      return wrap
    end



    #       Creates a JavaScript value of the string type.
    #
    # @param [JS::Context] ctx  The execution context to use.
    # @param [JS::String] string   The JS::String to assign to the newly created JS::Value. The
    # @return [JS::Value]         A JS::Value of the string type, representing the value of string.
    def self.make_string(ctx,string)
      string = JS::String.create_with_utf8cstring(string)
      res = super(ctx,string)
      wrap = self.new(:pointer=>res)
      wrap.context = ctx
      return wrap
    end

    #       Returns a JavaScript value's type.
    #
    # @return [FFI::Pointer]         A value of type JSType that identifies value's type.
    def get_type()
      res = super(context,self)
      return res
    end

    #       Tests whether a JavaScript value's type is the undefined type.
    #
    # @return [boolean]         true if value's type is the undefined type, otherwise false.
    def is_undefined()
      res = super(context,self)
      
    end

    #       Tests whether a JavaScript value's type is the null type.
    #
    # @return [boolean]         true if value's type is the null type, otherwise false.
    def is_null()
      res = super(context,self)
      

    end

    #       Tests whether a JavaScript value's type is the boolean type.
    #
    # @return [boolean]         true if value's type is the boolean type, otherwise false.
    def is_boolean()
      res = super(context,self)
      
      return res
    end

    #       Tests whether a JavaScript value's type is the number type.
    #
    # @return [boolean]         true if value's type is the number type, otherwise false.
    def is_number()
      res = super(context,self)
      
      return res || get_type == 3
    end

    #       Tests whether a JavaScript value's type is the string type.
    #
    # @return [boolean]         true if value's type is the string type, otherwise false.
    def is_string()
      res = super(context,self)
      
      return res || get_type == 4
    end

    #       Tests whether a JavaScript value's type is the object type.
    #
    # @return [boolean]         true if value's type is the object type, otherwise false.
    def is_object()
      res = super(context,self)
     
      return res
    end

    # Tests whether a JavaScript value is an object with a given class in its class chain.
    #
    # @param [JSClassRef] jsClass The JS::Class to test against.
    # @return [boolean] true if value is an object and has jsClass in its class chain, otherwise false.
    def is_object_of_class(jsClass)
      res = super(context,self,jsClass)
      
      return res
    end

    # Tests whether two JavaScript values are equal, as compared by the JS == operator.
    #
    # @param [JS::Value] b The second value to test.
    # @param [FFI::Pointer] exception A pointer to a JS::ValueRef in which to store an exception, if any. Pass nil if you do not care to store an exception.
    # @return [boolean] true if the two values are equal, false if they are not equal or an exception is thrown.
    def is_equal(b,exception = nil)
      b = JS::Value.from_ruby(context,b)
      res = super(context,self,b,exception)
     
      return res
    end

    #       Tests whether two JavaScript values are strict equal, as compared by the JS === operator.
    #
    # @param [JS::Value] b        The second value to test.
    # @return [boolean]         true if the two values are strict equal, otherwise false.
    def is_strict_equal(b)
      b = JS::Value.from_ruby(context,b)
      res = super(context,self,b)
      return res
    end

    # Tests whether a JavaScript value is an object constructed by a given constructor, as compared by the JS instanceof operator.
    #
    # @param [JS::Object] constructor The constructor to test against.
    # @param [FFI::Pointer] exception A pointer to a JS::ValueRef in which to store an exception, if any. Pass nil if you do not care to store an exception.
    # @return [boolean] true if value is an object constructed by constructor, as compared by the JS instanceof operator, otherwise false.
    def is_instance_of_constructor(constructor,exception = nil)
      constructor = JS::Object.from_ruby(context,constructor)
      res = super(context,self,constructor,exception)
      return res
    end

    #       Converts a JavaScript value to boolean and returns the resulting boolean.
    #
    # @return [boolean]         The boolean result of conversion.
    def to_boolean()
      res = super(context,self)
      return res
    end

    #       Converts a JavaScript value to number and returns the resulting number.
    #
    # @param [FFI::Pointer] exception A pointer to a JS::ValueRef in which to store an exception, if any. Pass nil if you do not care to store an exception.
    # @return [Float]         The numeric result of conversion, or NaN if an exception is thrown.
    def to_number(exception = nil)
      res = super(context,self,exception)
      return res
    end

    #       Converts a JavaScript value to string and copies the result into a JavaScript string.
    #
    # @param [FFI::Pointer] exception A pointer to a JS::ValueRef in which to store an exception, if any. Pass nil if you do not care to store an exception.
    # @return [JS::String]         A JS::String with the result of conversion, or NULL if an exception is thrown. Ownership follows the Create Rule.
    def to_string_copy(exception = nil)
      res = super(context,self,exception)
      return JS.read_string(res)
    end

    # Converts a JavaScript value to object and returns the resulting object.
    #
    # @param [FFI::Pointer] exception A pointer to a JS::ValueRef in which to store an exception, if any. Pass nil if you do not care to store an exception.
    # @return [JS::Object]         The JS::Object result of conversion, or NULL if an exception is thrown.
    def to_object(exception = nil)
      res = super(context,self,exception)
      return JS::BaseObject.is_wrapped?(res) || JS::Object.from_pointer_with_context(context,res)
    end

    # Protects a JavaScript value from garbage collection.
    #
    def protect()
      res = super(context,self)
      return res
    end

    #       Unprotects a JavaScript value from garbage collection.
    #
    def unprotect()
      res = super(context,self)
      return res
    end
  end
end

#       String.rb
             
#		(The MIT License)
#
#        Copyright 2011 Matt Mesanko <tulnor@linuxwaves.com>
#
#		Permission is hereby granted, free of charge, to any person obtaining
#		a copy of this software and associated documentation files (the
#		'Software'), to deal in the Software without restriction, including
#		without limitation the rights to use, copy, modify, merge, publish,
#		distribute, sublicense, and/or sell copies of the Software, and to
#		permit persons to whom the Software is furnished to do so, subject to
#		the following conditions:
#
#		The above copyright notice and this permission notice shall be
#		included in all copies or substantial portions of the Software.
#
#		THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
#		EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#		MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#		IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#		CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#		TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#		SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 
module JS
  class String < JS::Lib::String

    class << self
      alias :real_new :new
    end  
      
    def self.new *o
      if o[0].is_a? Hash and o[0][:pointer] and o.length == 1
        real_new o[0][:pointer]
      else
        return JS::String.create_with_utf8cstring(*o)
      end
    end
      

    #         Creates a JavaScript string from a buffer of Unicode characters.
    #
    # @param [FFI::Pointer] chars      The buffer of Unicode characters to copy into the new JS::String.
    # @param [Integer] numChars   The number of characters to copy from the buffer pointed to by chars.
    # @return [JS::String]           A JS::String containing chars. Ownership follows the Create Rule.
    def self.create_with_characters(chars,numChars)
      res = super(chars,numChars)
      wrap = self.new(:pointer=>res)
      return wrap
    end

    #         Creates a JavaScript string from a null-terminated UTF8 string.
    #
    # @param [FFI::Pointer] string     The null-terminated UTF8 string to copy into the new JS::String.
    # @return [JS::String]           A JS::String containing string. Ownership follows the Create Rule.
    def self.create_with_utf8cstring(string)
      res = super(string)
      wrap = self.new(:pointer=>res)
      return wrap
    end

    #         Retains a JavaScript string.
    #
    # @return [JS::String]           A JS::String that is the same as string.
    def retain()
      res = super(self)
      return JS.read_string(res)
    end

    #         Releases a JavaScript string.
    #
    def release()
      res = super(self)
      return res
    end

    #         Returns the number of Unicode characters in a JavaScript string.
    #
    # @return [Integer]           The number of Unicode characters stored in string.
    def get_length()
      res = super(self)
      return res
    end


    def get_characters_ptr()
      res = super(self)
      return res
    end

    # Returns the maximum number of bytes a JavaScript string will
    #
    # @return [Integer] The maximum number of bytes that could be required to convert string into a
    def get_maximum_utf8cstring_size()
      res = super(self)
      return res
    end

    # Converts a JavaScript string into a null-terminated UTF8 string,
    #
    # @param [FFI::Pointer] buffer The destination byte buffer into which to copy a null-terminated
    # @param [Integer] bufferSize The size of the external buffer in bytes.
    # @return [Integer] The number of bytes written into buffer (including the null-terminator byte).
    def get_utf8cstring(buffer,bufferSize)
      
      res = super(self,buffer,bufferSize)
   
      return res
    end
    
    def to_s
      size = get_length

      a = CFunc::Pointer.malloc(size+1)
   
      get_utf8cstring a, size+1

      a.to_s
    end

    #     Tests whether two JavaScript strings match.
    #
    # @param [JS::String] b      The second JS::String to test.
    # @return [boolean]       true if the two strings match, otherwise false.
    def is_equal(b)
      b = JS::String.create_with_utf8cstring(b)
      res = super(self,b)
      return res
    end

    #     Tests whether a JavaScript string matches a null-terminated UTF8 string.
    #
    # @param [FFI::Pointer] b      The null-terminated UTF8 string to test.
    # @return [boolean]       true if the two strings match, otherwise false.
    def is_equal_to_utf8cstring(b)
      res = super(self,b)
      return res
    end
  end
end

#       PropertyNameArray.rb
             
#		(The MIT License)
#
#        Copyright 2011 Matt Mesanko <tulnor@linuxwaves.com>
#
#		Permission is hereby granted, free of charge, to any person obtaining
#		a copy of this software and associated documentation files (the
#		'Software'), to deal in the Software without restriction, including
#		without limitation the rights to use, copy, modify, merge, publish,
#		distribute, sublicense, and/or sell copies of the Software, and to
#		permit persons to whom the Software is furnished to do so, subject to
#		the following conditions:
#
#		The above copyright notice and this permission notice shall be
#		included in all copies or substantial portions of the Software.
#
#		THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
#		EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#		MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#		IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#		CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#		TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#		SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 
module JS
  class PropertyNameArray < JS::Lib::PropertyNameArray

    # Retains a JavaScript property name array.
    #
    # @return [JS::PropertyNameArray] A JS::PropertyNameArray that is the same as array.
    def retain()
      res = super(self)
      return JS::PropertyNameArray.new(res)
    end

    # Releases a JavaScript property name array.
    #
    def release()
      res = super(self)
      return res
    end

    # Gets a count of the number of items in a JavaScript property name array.
    #
    # @return [Integer] An integer count of the number of names in array.
    def get_count()
      res = super(self)
      return res
    end

    # Gets a property name at a given index in a JavaScript property name array.
    #
    # @param [Integer] index The index of the property name to retrieve.
    # @return [JS::String] A JS::StringRef containing the property name.
    def get_name_at_index(index)
      res = super(self,index)
      return JS.read_string(res)
    end
  end
end

#       js_hard_code.rb
             
#		(The MIT License)
#
#        Copyright 2011 Matt Mesanko <tulnor@linuxwaves.com>
#
#		Permission is hereby granted, free of charge, to any person obtaining
#		a copy of this software and associated documentation files (the
#		'Software'), to deal in the Software without restriction, including
#		without limitation the rights to use, copy, modify, merge, publish,
#		distribute, sublicense, and/or sell copies of the Software, and to
#		permit persons to whom the Software is furnished to do so, subject to
#		the following conditions:
#
#		The above copyright notice and this permission notice shall be
#		included in all copies or substantial portions of the Software.
#
#		THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
#		EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#		MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#		IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#		CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#		TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#		SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 

class JS::Value
  class ConversionError < ArgumentError
  end
  
  def to_ruby

    if is_null
      nil
    elsif is_undefined
      :undefined
    elsif is_number
      r = to_number
      r
    elsif is_string
      to_string_copy
    elsif is_object
      JS::Lib.JSValueProtect(context,self)
      o=to_object
     
    elsif is_boolean
     
       r=to_boolean
      
    elsif nil == pointer
      nil
    else
      raise ConversionError.new("#{pointer.addr.to_s} is of type ")
    end 
  end
  
  def self.from_ruby ctx,rv = :undefined,&b
    if rv.is_a?(JS::Lib::Value)
      rv
    else
      if rv.is_a?(JS::Lib::String);
        s = rv
        JS::Lib::Value.make_string(ctx,s.to_s)
      elsif rv.class.to_s == "String"
        make_string(ctx,rv)
      elsif rv.is_a?(Integer)
       
       r =  make_number(ctx,CFunc::Double.new(CFunc::Float.new(rv)))
        r
      elsif rv.is_a?(Float)
       
       r =  make_number(ctx,rv)
      
        r
      elsif rv.is_a?(JS::Lib::Object)
        res = JS.execute_script(ctx,"this;",rv)
      elsif rv.is_a?(Hash) || rv.is_a?(Array)
        from_ruby(ctx,JS::Object.new(ctx,rv))
      elsif b || rv.is_a?(Proc)
        from_ruby(ctx,JS::Object.new(ctx,rv,&b))
      elsif rv == :undefined
        make_undefined ctx
      elsif rv == true || rv == false
    
         r=make_boolean(ctx,rv)
        r
      elsif rv == nil and !b
        make_null ctx
      #elsif rv.is_a? FFI::Pointer
       # JS::Object.from_pointer_with_context ctx,rv
      else
        #raise ConversionError.new("cant make value from #{rv.class}.")
        from_ruby(ctx,JS::RubyObject.new(ctx,rv))
      end
    end
  end
end

def JS.read_string(str,rel=true)
  str = JS::String.new(:pointer=>str)
  val = str.to_s
  str.release if rel
  return val
rescue ArgumentError => e
  puts "FIX ** WARNING ** FIX"
  puts "  change :string type to :pointer in ffi function :JSStringGetUTF8CString"
  raise e
end

class JS::Object
  class << self
    alias :non_ruby_new :new
  end
  
  def self.new *o,&b
    res = nil
    if o.length == 2 or (o.length == 1 && (!o[0].is_a?(Hash) || !o[0].has_key?(:pointer)))
      res = from_ruby *o,&b
    else
      res = non_ruby_new *o
    end
    
    return res
  end
  
  def self.from_ruby ctx,rv=nil,&b
    res = nil
    if !rv and !b
      res = self.make(ctx)
    elsif rv.is_a?(JS::Lib::Object)
      return rv
    # make object with properties of hash
    elsif rv.is_a?(Hash)
      res = self.new ctx
      res.context = ctx
      rv.each_pair do |prop,v|
        res[prop.to_sym] = v
      end
    # make array from ruby array
    elsif rv.is_a?(Array)
      res = self.make_array(ctx,CFunc::Int.new(rv.length),JS.rb_ary2jsvalueref_ary(ctx,rv))
   # elsif rv.is_a?(Method)
   #   res = self.make_function_with_callback ctx,'' do |*o|
   #     rv.call(*o)
   #   end
    elsif rv.is_a?(Proc)
      res = self.make_function_with_callback ctx,'', &rv
    elsif b;
      res = self.make_function_with_callback ctx,'',&b
    else
      return nil
    end
    res.context = ctx
    return res
  end
  def store_function n,a=nil
    a ||= n
    @stored_funcs||={}
    @stored_funcs[n] = self[n]
    class << self
      self
    end.class_eval do
      define_method a do |*o,&b|
        func = @stored_funcs[n]
        func.this = self
        func.call *o,&b
      end
    end
  end
  def [] k
    if k.is_a?(Float) and k == k.to_i
      k = k.to_i
    end
    if !k.is_a?(Integer)
      k=k.to_sym
    end
    raise unless k.is_a?(Symbol) or k.is_a?(String) or k.is_a?(Integer)
    k = k.to_s
    
    if k.is_a?(Integer)
      prop = get_property_at_index(k)
    else
      prop = get_property(k)
    end
    
    if prop.is_a?(JS::Object) && prop.is_function
      class << prop
        attr_accessor :this
      end
      prop.this = self
    end
    prop
  end
  
  def []= k,v
    if k.is_a?(Float) and k == k.to_i
      k = k.to_i
    end
    
    raise unless k.is_a?(Symbol) or k.is_a?(String) or k.is_a?(Integer)
    k = k.to_s
    p v
    #exit if k=="string"
    set_property(k,v)

  end
  
  def properties
    ary = []
    for i in 1..(a=copy_property_names).get_count
      ary << a.get_name_at_index(CFunc::Int.new(i-1))
    end
    #JS::Lib.JSPropertyNameArrayRelease(a)
    ary
  end

  def functions
    ary = []
    properties.each do |prop|
      ary << prop if self[prop].is_a?(JS::Object) and self[prop].is_function
    end
    ary
  end
  PROCS = {}
  def call *args,&b
    raise('Can not call JS::Object (JS::Object#=>is_function returned false') if !is_function
    @this ||= nil
    if b
      args << JS::Object.new(context,&b)
    end
    
    call_as_function @this,CFunc::Int.new(args.length),args
  end
  
  def self.is_array(context,obj)
    return nil if !context.is_a?(JS::Lib::GlobalContext)
    p o=JS::OBJECT(context).to_ruby
    o[:toString].call(o) == "[object Array]"
  end
  def self.is_node_list(context,obj)
    return nil if !context.is_a?(JS::Lib::GlobalContext)
    JS::OBJECT(context).prototype['toString']['call'].call(obj) == "[object NodeList]"
  end
end

module JS 
  class << self
    [:Object,:Array,:String,:RegExp].each do |t|
      define_method("#{t.to_s.upcase}") do |ctx|
        JS.execute_script(ctx,"#{t};")
      end
    end
  end
end




class JS::CallBack < Proc
  PROCS = {}
  class << self
    alias :real_new :new
  end
  GC.start
  def self.new block
    PROCS[block] ||= true
    r=real_new do |*o|
      ctx,function,this = o[0], o[1], o[2]
      varargs = []

      for i in 0..CFunc::Int.get(o[3].addr)-1
        ptr = o[4][i].value;

        varargs <<  y=JS::Value.from_pointer_with_context(ctx,ptr)

      end


      this = JS::Object.from_pointer_with_context(ctx,this) if this.is_a?(CFunc::Pointer)

v=varargs.map do |v| v.to_ruby end;
r = block.call(this,*v);

      JS::Value.from_ruby(ctx,r).ffi_ptr
    end
    PROCS[r] = true
    r
  end
end

module JS
  def self.rb_ary2jsvalueref_ary(ctx,ary)
    return nil if ary.empty?
    vary = ary.map do |v| n=JS::Value.from_ruby(ctx,v);p v;p n.is_number;p ary;n end
        
    $a=(jv_ary = CFunc::Pointer[vary.length]).addr
    vary.each_with_index do |q,i|
     # p q;exit
      jv_ary[i].value = q.ffi_ptr
 
    end
    jv_ary  
  end

  def self.create_pointer_of_array type,ary,*dat
    r = nil
    if type == JS::Value
        r=self.rb_ary2jsvalueref_ary(dat[0],ary)
    elsif type == JS::String
        r=self.string_ary2jsstringref_ary(ary)
    end
    r
  end

  def self.string_ary2jsstringref_ary(r)
    vary = ary.map do |v| JS::String.create_with_utf8cstring(v) end
    jv_ary = CFunc::Pointer[vary.length]
    vary.each_with_index do |q,i|
      jv_ary[i].value = q
    end
    jv_ary 
  end
  
  def self.execute_script(ctx,str,this=nil)
    str_ref = JS::String.create_with_utf8cstring(str)
    if JS::Lib.JSCheckScriptSyntax(ctx,str_ref,nil,0,nil)
      val = JS::Lib.JSEvaluateScript(ctx,str_ref,this,nil,0,nil)
    else
      raise "Script Syntax Error\n#{str_ref.to_s}"
    end
    str_ref.release
    JS::Value.from_pointer_with_context(ctx,val)#.to_ruby
  end
  
  def self.param_needs_context? a
    a.is_a?(Array) || a.is_a?(Hash) or a.is_a?(Method) or a.is_a?(Proc)
  end
end

module JS
  class Object
    include Enumerable
    # jruby needs this
    def length
      self[:length]
    end
    def each
      if JS::Object.is_array(context,self)
        for i in 0..length-1
          yield self[i] if block_given?
        end      
      elsif  JS::Object.is_node_list(context,self)
        for i in 0..length-1
          yield self[i] if block_given?
        end 
      else
        properties.each do |n|
          yield(n) if block_given?
        end        
      end
    end
  
    def to_str
      inspect
    end
  
    def each_pair
      each do |n| yield(n,self[n]) end
    end
  end
end

#       js_class_definition.rb
             
#		(The MIT License)
#
#        Copyright 2011 Matt Mesanko <tulnor@linuxwaves.com>
#
#		Permission is hereby granted, free of charge, to any person obtaining
#		a copy of this software and associated documentation files (the
#		'Software'), to deal in the Software without restriction, including
#		without limitation the rights to use, copy, modify, merge, publish,
#		distribute, sublicense, and/or sell copies of the Software, and to
#		permit persons to whom the Software is furnished to do so, subject to
#		the following conditions:
#
#		The above copyright notice and this permission notice shall be
#		included in all copies or substantial portions of the Software.
#
#		THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
#		EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#		MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#		IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
#		CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
#		TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
#		SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# 


module JS
  module Lib
    typedef :pointer,:JSClassAttributes
    typedef :pointer,:JSPropertyNameAccumulatorRef
    typedef :int,:JSType
    p JS::Lib.find_type(:JSClassAtributes)    
    callback :JSObjectGetPropertyCallback,[:JSContextRef,:JSObjectRef,:JSStringRef,:pointer],:JSValueRef
    callback :JSObjectSetPropertyCallback,[:JSContextRef,:JSObjectRef,:JSStringRef,:JSValueRef,:pointer],:bool
    callback :JSObjectHasPropertyCallback,[:JSContextRef,:JSObjectRef,:JSStringRef],:bool
    callback :JSObjectDeletePropertyCallback,[:JSContextRef,:JSObjectRef,:JSStringRef,:pointer],:bool
    callback :JSObjectCallAsConstructorCallback,[:JSContextRef,:JSObjectRef,:pointer,:pointer],:JSValueRef
    callback :JSObjectHasInstanceCallback,[:JSContextRef,:JSObjectRef,:JSValueRef,:pointer],:bool
    callback :JSObjectConvertToTypeCallback,[:JSContextRef,:JSObjectRef,:JSType,:pointer],:JSValueRef
    callback :JSObjectCallAsConstructorCallback,[:JSContextRef,:JSObjectRef,:size_t,:pointer,:pointer],:JSObjectRef
    callback :JSObjectInitializeCallback,[:JSContextRef,:JSObjectRef,:pointer,:pointer],:JSValueRef
    callback :JSObjectFinalizeCallback,[:JSObjectRef],:void
    callback :JSObjectGetPropertyNamesCallback,[:JSContextRef,:JSObjectRef,:JSPropertyNameAccumulatorRef],:void

    attach_function :JSClassCreate,[:pointer],:pointer

    class JSClassDefinition < FFI::Struct
      layout :version,:int,
      :attributes,:JSClassAttributes,
      :className,:pointer,
      :parentClass,:JSClassRef,
      :staticValues,:pointer,
      :staticFunctions,:pointer,
      :initialize,:JSObjectInitializeCallback,
      :finalize,:JSObjectFinalizeCallback,
      :hasProperty,:JSObjectHasPropertyCallback,
      :getProperty,:JSObjectGetPropertyCallback,
      :setProperty,:JSObjectSetPropertyCallback,
      :deleteProperty,:JSObjectDeletePropertyCallback,
      :getPropertyNames,:JSObjectGetPropertyNamesCallback,
      :callAsFunction,:JSObjectCallAsFunctionCallback,
      :callAsConstructor,:JSObjectCallAsConstructorCallback,
      :hasInstance,:JSObjectHasInstanceCallback,
      :convertToType,:JSObjectConvertToTypeCallback
     
    end
  end
end


class JS::RubyObject < JS::Object
  class << self
    alias :ro_new :new
  end
  
  def self.new(ctx,object=Object)
    res = ro_new(:pointer=>JS::Lib::JSObjectMake(ctx,CLASS,nil))
    res.context = ctx
    PTRS[res.pointer.inspect.split("=")[1]]=res
    res.object = object
    res
  end
end





class JS::RubyObject < JS::Object
  PTRS = {}
  PROCS = {}
  def self.find_object o
    PTRS[o.inspect.split("=")[1]]
  end
  CLASS_DEF = JS::Lib::JSClassDefinition.new()
  n1=Proc.new do |ctx,obj,name,err|
    if (n=JS.read_string(name,false)) == "object_get_property"
      nil
    else
      o = JS::RubyObject.find_object(obj)
      o.object_get_property(n)
    end
  end  
  CLASS_DEF[:getProperty] = pr = CFunc::Closure.new(CFunc::Pointer,[CFunc::Pointer,CFunc::Pointer,CFunc::Pointer,CFunc::Pointer]) do |*o|
    n1.call(*o)
  end
  PROCS[pr] = true
  
  # IMPORTANT: set definition fields before creating class
  CLASS = JS::Lib.JSClassCreate(CLASS_DEF.addr)
  p CLASS[9]
  attr_accessor :object
  
  def object_has_property? n
    if object.respond_to?(n)
      true
    elsif object.private_methods.index(n.to_sym)
      true
    elsif object.respond_to?(:constants)
      !!object.constants.index(n.to_sym)
    else
      nil
    end   
  end
  def js_send this,*o,&b
    send *o,&b
  end
  def object_get_property n
    return nil if !object_has_property?(n)
    m = nil
    
    if object.respond_to?(n) or object.private_methods.index(n.to_sym)
      m =Proc.new do |*o|
        object.send(n,*o)
      end
    elsif object.respond_to?(:constants)
      m = object.const_get n.to_sym
    end
    
    o = nil
    
    if m.respond_to?(:call)
      o = JS::Object.new(context) do |*a|
        this = a.shift
        closure = nil
        if a.last.is_a?(JS::Object) and a.last.is_function
          closure = a.pop
          closure.context = context
        end
        q=m.call(*a) do |*args|
          closure.call(*args) if closure
        end
        JS::Value.from_ruby(context,q)
      end
    else
      o = m
    end

    v = JS::Value.from_ruby(context,o)#.to_ptr
    v.to_ptr
  end
end





# File: /home/ppibburr/git/mruby-javascriptcore/tmp/2.rb
module GObject
  module Lib
    extend FFI::Lib
    ffi_lib "/usr/lib/i386-linux-gnu/libgobject-2.0.so"
    callback :GCallback,[:pointer,:pointer],:pointer
    attach_function :g_signal_connect_data,[:pointer,:pointer,:GCallback,:pointer,:pointer],:int
  end
 
  module Object
    def signal_connect s,&b
      closure = CFunc::Closure.new(CFunc::Void,[CFunc::Pointer,CFunc::Pointer,CFunc::Pointer]) do |*o|
        b.call *o
      end
      GObject::Lib.g_signal_connect_data self,s,closure,nil
    end
  end
end

module Gtk
  module Lib
    extend FFI::Lib
    ffi_lib "/usr/lib/i386-linux-gnu/libgtk-3.so.0"
    
    attach_function :gtk_window_new,[:uint],:pointer
    attach_function :gtk_container_add,[:pointer,:pointer],:void
    attach_function :gtk_widget_show_all,[:pointer],:void
    attach_function :gtk_init,[:pointer,:pointer],:void
    attach_function :gtk_main,[],:void
    attach_function :gtk_main_quit,[],:void
    attach_function :gtk_window_set_title,[:pointer,:pointer],:void
  end

  def self.init
    Gtk::Lib.gtk_init nil,nil
  end

  def self.main
    Gtk::Lib.gtk_main
  end
  
  def self.main_quit
    Gtk::Lib.main_quit
  end
 
  module Widget
    def show_all
      Gtk::Lib.gtk_widget_show_all(self)
    end
  end
  
  module Container
    def add v
      Gtk::Lib.gtk_container_add(self,v)
    end
  end

  class Window < FFI::AutoPointer
    include GObject::Object
    include Gtk::Widget    
    include Gtk::Container    
    def initialize t="mruby webkit"
      super Gtk::Lib.gtk_window_new(0)
      set_title t
    end
    
    def set_title t
      Gtk::Lib.gtk_window_set_title(self,t)
    end
  end
end

module WebKit
  module Lib
    extend FFI::Lib
    ffi_lib "/usr/lib/libwebkitgtk-3.0.so"
    
    attach_function :webkit_web_view_new,[],:pointer
    attach_function :webkit_web_view_open,[:pointer],:void
    attach_function :webkit_web_view_load_html_string,[:pointer,:pointer,:pointer],:void
    attach_function :webkit_web_frame_get_global_context,[:pointer],:pointer
  end
  
  class WebView < FFI::AutoPointer
    include GObject::Object
    include Gtk::Widget
    def initialize
      super WebKit::Lib.webkit_web_view_new
    end
    
    def open url
      WebKit::Lib.webkit_web_view_open(self,url)
    end  
  
    def load_html_string data,url
      WebKit::Lib.webkit_web_view_load_html_string(self,data,url)
    end       
  end
  
  class WebFrame < FFI::AutoPointer
    include GObject::Object
    def self.wrap ptr
      new(ptr)
    end
    
    def get_global_context
      WebKit::Lib.webkit_web_frame_get_global_context(self)
    end
  end
end
  
Gtk.init
w=Gtk::Window.new
w.add v=WebKit::WebView.new

v.load_html_string "hello mruby",""

v.signal_connect "load-finished" do |wv,f|
  cptr = WebKit::WebFrame.wrap(f).get_global_context
  c = JS::GlobalContext.new(:pointer=>cptr)
  g = c.get_global_object
  g[:alert].call("hello MRUBY!")
  g[:document][:body][:innerText] = "Wrote by MRuby!!"
end

w.show_all

Gtk.main
