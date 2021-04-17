// Original by Dean Edwards. http://dean.edwards.name/
// Modified by Edward Kmett. Mon Jun 19 17:58:20 EDT 2006
// This file is in the public domain.
#ifndef INCLUDED_JS_DOM_EVENT
#define INCLUDED_JS_DOM_EVENT

#include "js/native/Platform.js"
#include "js/dom.js"

(function(){
	var guid = 1;
		
	function ha(ev) { // handleEvent
		var r = true,s,h=[];
		ev= ev|| fi(window.event);
		for ( var i in this.events[ev.type] )
			h[h.length] = this.events[ev.type][i];
		for ( var i = 0; i < h.length; i++ ) {
			try {
				if ( h[i].constructor == Function ) {
					s = h[i].call(this,ev);
				} else if (handle in h[i]) {
					s = h[i].handle(ev);
				} else s = null;
				if (s === false) {
					ev.preventDefault();
					ev.stopPropagation();
					r = false;
				}
			} catch(e){}
		}
		return r;
	};
	function fi(e) { // fixEvent
		e.preventDefault = fi.preventDefault;
		e.stopPropagation = fi.stopPropagation;
		return event;
	};
	fi.preventDefault = function() {
		this.returnValue = false;
	};
	fi.stopPropagation = function() {
		this.cancelBubble = true;
	};
	// @namespace js.dom.Event
	js.dom.Event= {
		// @method listen
		// @param e the element or object to listen to
		// @param t the type of even to listen for
		// @param f the function or handler to assign to the event.
		listen : function(e,t,f) { // element type handler
			if (typeof(e)=="array" && !e["on"+t]){
				for (var i=0;i<e.length;++i) add(e[i],t,f);
				return;
			}
			if ( e.location ) e = window; //? could break general usage
			if (!f.$$guid) f.$$guid = guid++;
			if (!e.events) e.events = {};
			const h = e.events[t];
			if (!h) {
				h = e.events[t] = {};
				if (e["on" + t]) h[0] = e["on" + t];
			}
			h[f.$$guid] = f;
			e["on" + t] = ha;
		},
		remove : function(e,t,f) { // element type handler
			if (typeof(e)=="array" && !e["on"+t]){
				for (var i=0;i<e.length;++i) remove(e[i],t,f);
				return;
			}
			if (e.events) {
				if (t && e.events[t]) 
					if ( f ) __delete__(e.events[t],f.$$guid);
					else for ( var i in e.events[t] ) __delete__(e.events[t],i);
				else for ( var i in e.events ) removeEvent( e, i );
			}
		},
		trigger : function(e,t,d) { // element type data
			if (typeof(e)=="array" && !e["on"+t]) {
				for (var i=0;i<e.length;++i) trigger(e[i],t,d);
				return;
			}
			d= d|| { type: t };
			if (e && e["on" + t]) e["on" + t].call(e,d);
		}

	};
})();
#endif // vim:ts=4
