#include "js/test/Simple.js"
#include "js/aop/Observable.js"

plan(2);

var changed_aspect = new js.aop.Observable(/^set/,"change");

function Tester() { 

};
Tester.prototype = { 
	set_foo : function(t) { this.foo = t; } 
};
changed_aspect.weave(Tester.prototype);
var t = new Tester;
t.set_foo();
js.dom.Event.listen(t,"change",function(){ ok(1); });
js.dom.Event.trigger(t,"change");
t.set_foo();
