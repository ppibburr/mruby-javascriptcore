var jsProperty = "a property";

function jsAdd(a,b) {
	return(a+b);
};

function jsFunctionWithClosure(o,fun) {
    q = fun([1,2,3,4]);
    return([o.class,q]);	
}
