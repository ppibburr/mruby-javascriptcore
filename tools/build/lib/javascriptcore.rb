# -File- ./javascriptcore.rb
#

module JavaScriptCore
    def self.libname()
      unless @libname
        gir = GirBind.gir
        gir.require("WebKit")
        @libname = gir.shared_library("WebKit").split(",").first
        if !@libname.index("lib")
          @libname = "lib#{@libname}.so"
        end
      end
      @libname
    end
end

#
