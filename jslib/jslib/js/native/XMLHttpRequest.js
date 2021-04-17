#ifndef INCLUDED_JS_NATIVE_XMLHTTPREQUEST
#define INCLUDED_JS_NATIVE_XMLHTTPREQUEST

#include "js/native/Platform.js"

#ifdef USE_XPCOM
if(typeof XMLHttpRequest=='undefined'&&Components&&Components.Constructor) 
	var XMLHttpRequest = new Components.Constructor("@mozilla.org/xmlextras/xmlhttprequest;1","nsIXMLHttpRequest");
#endif
#ifndef NO_ACTIVEX
if(typeof XMLHttpRequest=='undefined'&&typeof window.ActiveXObject=='function') 
	var XMLHttpRequest=navigator.userAgent.toLowerCase().indexOf('msie 5')>=0
		?function(){return new ActiveXObject("Microsoft.XMLHTTP")}
		:function(){return new ActiveXObject("Msxml2.XMLHTTP")};
#endif
#endif
