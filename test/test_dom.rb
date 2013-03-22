GirBind.ensure(:WebKit)

module WebKit
  load_class(:WebFrame) do
    f = FFIBind::Function.add_function(WebKit.ffi_lib,"webkit_web_frame_get_global_context",[:pointer],:pointer)
  
    define_method :get_global_context do
      ptr = f.invoke(self)
      ctx = JS::JSGlobalContext.wrap(ptr)
      next ctx
    end
  end
end

module JS
  module JS::Object
    def is_node_list
		if context.execute("this instanceof NodeList;",self) == true
		  return true
		end
		return false
    end
    
    def self.use_method_missing
      return true if @_use_method_missing_
      @_use_method_missing_ = true
        define_method :method_missing do |m,*o,&b|
        m = m.to_s
        if m[m.length-1] == "="
          raise "Too many arguments" if o.length > 1 
          next self[m[0..m.length-2]] = o[0]
        else
          f = self[m]
          if f.is_a?(JS::JSObject) and f.is_function
            next f.call(*o,&b)
          end
        
          next f
        end
        
        return true
      end
    end
  end
  
  module JS::ObjectIsNodeList
    include Enumerable
    def each
      for i in 0..self[:length]-1
        yield self[:item].call(i)
      end
    end
  end
  
  class JS::JSValue
    alias :__to_ruby__ :to_ruby
    def to_ruby
      if is_object and (o=to_object(nil)).is_node_list
        o.extend JS::ObjectIsNodeList
        return o
      end

      return __to_ruby__
    end
  end
end

def assert(msg="",&b)
  raise "assertion: #{msg} failed." unless b.call()
  true
end

JS::Object.use_method_missing

Gtk.init 0,[]

w = Gtk::Window.new(:toplevel)
v = WebKit::WebView.new()

w.add v

gobj = nil

v.signal_connect("load-committed") do |view,frame|
  ctx = frame.get_global_context
  gobj = ctx.get_global_object
  
  gobj[:getContent] = Proc.new do
    "Some content from mruby."
  end
end

v.signal_connect("load-finished") do |view,frame|
  ctx = frame.get_global_context
  assert("JSContext# from load-finished and load-started are the same") do
    ctx.get_global_object == gobj
  end
  
  list = gobj[:document][:getElementsByTagName].call("div")

  assert "NodeList is JS::ObjectIsNodeList" do
    list.is_a?(JS::ObjectIsNodeList) && list.is_node_list && assert("the list can become array") do
      list.to_a.length == 2
    end
  end
 
  assert "The NodeList is of length 2" do 
    list[:length] == 2
  end
  
  assert "Elements in list are of 'div'" do
    list[0][:tagName] == "DIV" and list[1][:tagName] == "DIV"
  end
  
  assert "The divs have proper content. Showing that the global object had getContent applied" do
    colors = [:red,:green]
    c = 0
    !list.map do |e|
      e[:style][:backgroundColor] = colors[c]
      c += 1
      e[:innerText] == "Some content from mruby."
    end.index(false)
  end
  
  ele = list[0][:cloneNode].call(true)
  gobj[:document][:body][:appendChild].call(ele)
  
  assert "The list has been ammended" do
    list[:length] == 3
  end
  
  assert "Ammended element has color red" do
    list[2][:style][:backgroundColor] == "red"
  end
  
  assert "The script set onReady and calling it returns 'true'" do
    if fun=gobj[:onReady]
      next fun.call == true
    end
  end
  
  assert "JS::Object#method_mmissing work properly" do
    begin
      assert "method_missing returned property" do 
        gobj.document.is_a?(JS::JSObject)
      end
      assert "method_missing invokes functions" do
        gobj.onReady == true
      end    
      next(true)
    rescue
      next(false)
    end
  end
  
  Gtk.main_quit
end

w.signal_connect("delete-event") do
  Gtk.main_quit
end

html = <<EOH
  <html>
    <body>
      <div></div>
      <div></div>
      <script>
        var nl=document.getElementsByTagName('div');
        nl[0].innerText=getContent(); // getContent defined by ruby in load-committed
        nl[1].innerText=getContent();
        
        onReady = function() {
          return(true);
        }; // will be called from mruby in on-finished
      </script>
    </body>
  </html>
EOH

v.load_html_string(html,"")
w.show_all

Gtk.main
