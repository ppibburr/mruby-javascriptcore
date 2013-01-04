

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
