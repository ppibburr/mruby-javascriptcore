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
