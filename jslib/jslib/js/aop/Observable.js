// Observable.js Copyright 2006 Edward Kmett. All Rights Reserved
#ifndef INCLUDED_JS_AOP_OBSERVABLE
#define INCLUDED_JS_AOP_OBSERVABLE

// modify the prototype searching for set methods
#include "js/native/Platform.js" // const
#include "js/aop/Aspect.js"		 // js.aop.Aspet
#include "js/dom/Event.js"		 // js.dom.Event

(function(){
	// @aspect Observable
	// @param p the prototype to which we will add onchange event support.
	const trigger = js.dom.Event.trigger,
		o = js.aop.Observable = function(m,e) { 
			this.event = e;
			this.match = m||new RegExp("^set");
		}, 
		p = o.prototype = new js.aop.Aspect;
	// @method onchange
	// @summary triggers onchange handlers associated with the object by default.
	// overridable in subclasses to change this behavior.
	p.handler = function(o,m) { trigger(o,this.event); };
	p.weave = function(o) {
		this.pointcut(o,this.match).after(this.handler);
		return o;
	};
})();

#endif // vim:ts=4
