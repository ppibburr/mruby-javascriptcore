# -File- ./javascriptcore.rb
#

module JavaScriptCore
    def self.libname()
      unless @libname
        gir = GirBind.gir
        gir.require("JSCore")
        @libname = gir.shared_library("JSCore").split(",").last
        if !@libname.index("lib")
          @libname = "lib#{@libname}.so"
        end
      end
      @libname
    end
end

#
