// Original code by Dean Edwards. Modified by Edward Kmett Mon Jun 19 18:15:23 EDT 2006
#ifndef INCLUDED_JS_DOM_READY
#define INCLUDED_JS_DOM_READY

#ifndef PLATFORM_BROWSER
#ifndef MAKEDEPEND
#error "js.dom.Ready needs a browser to run"
#endif
#endif

#include "js/native/Platform.js"
#include "js/dom"
#include "js/dom/Event.js"

(function(){
	var ready = false;
	const d=js.dom,e=d.Event,r=js.dom.Ready = { 
		listen : function(f) { 
			e.listen(window,"ready",f); 
		},
		init : function() { 
			if (ready) return;
			ready = true;
			e.trigger(window,"ready");
		}
	};
	if (document.addEventListener) document.addEventListener("DOMContentLoaded", r.init, false);
	/*@cc_on @*/
	/*@if (@_win32)
		document.write("<script defer id="__id_onready" src='javascript:void(0)'><"+"/script">");
		var script = document.getElementById("__ie_onload");
		script.onreadystatechange = function() {
    			if (this.readyState == "complete") {
        			r.init(); 
    			}
		};
	/*@end @*/
	if (new RegExp("WebKit","i").test(navigator.userAgent)) { // sniff
	    var _timer = window.setInterval(function() {
		if (new RegExp("loaded|complete").test(document.readyState)) {
		    window.clearInterval(_timer);
		    delete _timer;
		    r.init(); // call the onload handler
		}
	    }, 10);
	}
	e.listen(window,"load",r.init);
})()

#endif
