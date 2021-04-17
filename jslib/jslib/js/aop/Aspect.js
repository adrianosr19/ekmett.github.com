// Aspect.js Copyright 2006 Edward Kmett. All Rights Reserved
#ifndef INCLUDED_JS_AOP_ASPECT
#define INCLUDED_JS_AOP_ASPECT

#include "js/native/Platform.js"
#include "js/aop.js"
#include "js/test/Assert.js"

(function(){
	// @class js.aop.Aspect
	// @constructor
	const ao=js.aop,a=ao.Aspect=function(){},p=a.prototype={
		// @method pointcut
		// @param o the object or prototype to cut
		// @param m can be either the string of a method name
		//		    or a function/RegExp that operates on method names.
		// @returns a new js.aop.PointCut
		pointcut: function(o,m) {
			return new ao.PointCut(this,o,m);
		}
	};

	var guid = 0;
	//@class js.aop.PointCut
	//@constructor 
	//@param a an aspect which serves as a this pointer for each method.
	//@param o an object or prototype to cut.
	//@param m either a method name or function/RegExp that takes method names.
	const c=ao.PointCut=function(a,o,m){
		assert(a!=null);
		assert(o!=null);
		assert(typeof(m)=="string"||typeof(m)=="function");
		this.aspect  = a; //@property aspect
		this.object  = o; //@property object
		this.rule    = m; //@property rule
	},q=c.prototype={
		before: function(f) { 
			return this.each(function(o,m,a,h){
				return function () { 
					f.call(a,this,m,arguments);
					return h.apply(this,arguments);
				}
			});
		},
		//@method after_return
		//@summary attaches advice that runs after a method exits and safely returns a result
		//@param f the advice function f is passed (o,m,result) and this is set to this.aspect.
		//		 f must return or throw an appropriate result.
		// 		 an identity function is function f(o,m,result) { return result; } 
		after_return : function(f) {
			return this.each(function(o,m,a,h){
				return function() { 
					return f.call(a,this,m,h.apply(this,arguments))
				}
			});
		},
		//@method after_throw
		//@summary attaches after advice that runs only if an exception is thrown. 
		//@param f the advice function f is passed (o,m,exception) and this is set to this.aspect
		//		 f must return or throw an appropriate result.
		//		 the identity function is function f(o,m,exception) { throw exception; } 
		after_throw : function(f) { 
			return this.each(function(o,m,a,h){
				return function() {
					try { 
						return h.apply(this,arguments);
					} catch (e) {
						return f.call(a,this,m,e)
					}
				};
			});
		},

		//@method after
		//@summary attaches generic after advice
		//@param f the advice function f is passed (o,m) and its result is ignored.
		//	     the identity function is function f(o,m) {}
		after: function(f) { 
			return this.each(function(o,m,a,h){
				return function() { 
					try { 
						return h.apply(this,arguments);
					} finally {
						f.call(a,this,m);
					}
				}
			});
		},
		//@method around
		//@summary attaches around advice to the function
		//@param f the advice function f is passed (o,m,proceed,arguments);
		//		to invoke the original function it should call proceed.apply(o,arguments);
		//		the identity function is function f(o,m,proceed,a) { return proceed.apply(o,a); }
		around : function(f) { 
			return this.each(function(o,m,a,h){
				return function() {
					f.call(a,this,m,h,arguments);
				};
			});
		},
		//@method each
		//@summary is a utility function used to iterate across everything visited by a pointcut.
		each : function(f) { 
			var a=this.aspect,h,r,g=this.guid,o=this.object,m=this.rule;
			switch(typeof(m)) {
			case "string": // wildcards?
				if (typeof(o[m])=="function") {
					o[m] = f.call(this,o,m,a,o[m]);
				}
				break;
			case "function": // functions and regexps
				for (var i in o)
					if (typeof(o[i])=="function" && m(i)) {
						o[i] = f.call(this,o,i,a,o[i]);
					}
			};
			return this;
		}
		// todo: guard(f) to create a sub-pointcut that tests if f is true before executing advice
		// todo: make a method remove a pointcut
		// todo: modify the pointcut interface to accept a generic iterator interface
		// todo: better new forwarding.
	}
})(); 

#endif // vim:ts=4
