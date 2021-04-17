#include "js/lang/Interpreter.js"

function plus1(x) { return x+1; } 
function construct(x) { 
	this.x = x; 
}

var ok = {
	"expr" : { 
		"1+2" : 3,
		"12+23" : 35,
		"(1*2/4)" : 0.5,
		"(function(g){return 12 instanceof g;})(Number)" : false,
		"(function(g){return 12 instanceof g;})(Boolean)" : false,
		"(function(g,j){j=12;for (var i=g;i>0;i--) j*=i; return j })(5)" : 1440,
		"(function(g,j){for (var i=g;i>0;i--) j*=i; return j })(5)" : NaN,
		"typeof(12)" : "number",
		"new construct instanceof construct" : true
	},
	"eval" : { 
		"function t_1(){}" : undefined,
	}
};
var thrown = {
	"throw new construct(12);" : construct,
	"(function crash(){ throw new construct(crash) })()" : construct,
	"function crash(){break};" : js.lang.Parser.SyntaxError,
	"for(var i=0;i<12;++i){if(i>10)throw new construct;}" : construct
};
var $failed = function(){};

var tests = 0;
for (var i in ok) {
	for (var j in ok[i]) { 
		tests++;
	}
}
for (var i in thrown) tests++;

var $ = new js.lang.Interpreter();

print("1.."+tests);
var test = 0;
for (var i in ok) { 
	for (var j in ok[i]) { 
		var caught=0,r=$failed;
		try { r = $[i](j); } catch (e) { caught = e; }
		if (caught) print("not ok "+(++test)+" # Exception: " + caught);
		else if (r == ok[i][j] || typeof(ok[i][j])=="undefined" || (isNaN(ok[i][j])&&isNaN(r))) {
			print("ok "+(++test));
		} else { 
			print("not ok "+(++test)+" # Expected " + ok[i][j] + ", but received " + r + " from "+ j);
		}
	}
}
for (var i in thrown) {
	var caught = 0, r=undefined, expects = thrown[i];
	try { 
		r = $.eval(i);
	} catch (e) { 
		caught = e;
	}
	if (caught) { 
		if (__instanceof__(caught,expects)) print("ok "+(++test));
		else print("not ok "+(++test)+" # Expected Exception "+expects +", but received " + caught); 
	} else print("not ok "+(++test)+" # Unexpected completion with "+r+" from "+i);
}
print("END")

// vim:ts=4
