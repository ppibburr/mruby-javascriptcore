# -File- ./ext/js_jsclassdefinition.rb
#

module JS
    class JSClassDefinition < CFunc::Struct
      define CFunc::Int, :version,
      CFunc::Pointer, :attributes,
      CFunc::Pointer, :className,
      CFunc::Pointer, :parentClass,
      CFunc::Pointer, :staticValues,
      CFunc::Pointer, :staticFunctions,
      CFunc::Pointer, :initialize,
      CFunc::Pointer, :finalize,
      CFunc::Pointer, :hasProperty,
      CFunc::Pointer, :getProperty,
      CFunc::Pointer, :setProperty,
      CFunc::Pointer, :deleteProperty,
      CFunc::Pointer, :getPropertyNames,
      CFunc::Pointer, :callAsFunction, 
      CFunc::Pointer, :callAsConstructor, 
      CFunc::Pointer, :hasInstance,
      CFunc::Pointer, :convertToType		
    end		
end

#
