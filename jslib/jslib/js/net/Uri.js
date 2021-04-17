// js.net.Uri (C) 2006 Edward Kmett. All Rights Reserved

#ifndef INCLUDED_JS_NET_URI
#define INCLUDED_JS_NET_URI

#include "js/net.js"

(function(){
#ifdef BUILD_URI_REGEXPS
	function t(y,x)	{return x+"(?:"+y+x+")"}
	function s(m,x) {return "(?:"+m+"("+x+"*))?"}
    function r(x)	{return '['+x+'a-zA-Z0-9$\\-_@.&!*"\'(),]'}
	function j(d,x)	{return '(?:('+x+')'+d+')?'}
	function y(x) 	{return '^'+x+'$'}
	const 
		h = "[0-9a-fA-F]", 
		i = '%'+h+h,									// hex
		e = function(x) {return '(?:'+x+'|'+i+')'}, 	// allow escape characters
		x = e(r('+')),									// xpalpha (slightly overpermissive)
		v = "[A-Za-z\-_.+]",							// alphanum2
		f = s("#",x),									// #fragment
		q = s("\\\?",e(r('+='))),						// ?query#fragment
		path = new RegExp("^("+e(r('+/'))+"*)"+q+'$'),	// path?query#fragment
		z = s(":",'[0-9]'),								// [:port]
		o = '('+x+'+)'+z,								// host[:port]
		sa = '('+j('@','('+v+"*)"+s(':',v))+o+')',		// [user[:passwd]@]host[:port] (server authority)
		ra = '(?:[^\\s\\u0000-\\u00ff]|'+i+'|'+r('@:')+')*', // registry authority
		auth = new RegExp('(?://('+sa+'|'+ra+'))'),		// any authority
		sc = '(?:[uU][rR][lLiI]:)?'+j(':',r('')+'+'),	// [url:][scheme:]
		ssp = new RegExp(sc+'([^#]*)'+f);
#else
	const 
		e="%[0-9a-fA-F][0-9a-fA-F]",
		path = new RegExp("^((?:[+\\/a-zA-Z0-9$\\-_@.&!*'"+'"'+"(),]|"+e+")*)(?:\\?((?:[+=a-zA-Z0-9$\\-_@.&!*'"+'"'+"(),]|"+e+")*))?$"),
		auth = new RegExp("(?:\\/\\/(((?:(([A-Za-z-_.+]*)(?::([A-Za-z-_.+]*))?)@)?((?:[+a-zA-Z0-9$\\-_@.&!*\"'(),]|"+e+")+)(?::([0-9]*))?)|(?:[^\\s\\u0000-\\u00ff]|"+e+"|[@:a-zA-Z0-9$\\-_@.&!*\"'(),])*))"),
		ssp = new RegExp("(?:[uU][rR][lLiI]:)?(?:([a-zA-Z0-9$\\-_@.&!*\"'(),]+):)?([^#]*)(?:#((?:[+a-zA-Z0-9$\\-_@.&!*\"'(),]|"+e+")*))?");
#endif
	function def(x){ return typeof(x) != "undefined"; }
	const
		n=js.net, 
		u=n.Uri=function(s) {
			out: {
				var a = arguments;
				switch(a.length) { 
				case 0:
					this.ssp='';
					break;
				case 1: // string
					var m = ssp.exec(s);
					if (!m) throw new URIError();
					this.fragment = m[3];
					this.ssp=m[2];
					this.scheme=m[1];
					break;
				case 2: // scheme ssp
				case 3: // scheme ssp fragment
					this.scheme = a[0];
					this.ssp = a[1];
					this.fragment = a[2];
					break;
				case 4: // scheme authority path query
				case 5: // scheme authority path query fragment
					this.scheme = a[0];
					if (a[3][0] != '/' && (a[1]||a[0])) throw new URIError();
					this.ssp = (def(a[1])?"//"+a[1]:"")+ a[2] + a[3]?"?"+a[3]:""
					this.fragment = a[4];
					break;
				case 6: // scheme userinfo host port path query
				case 7: // scheme userinfo host port path query fragment
					this.absolute = def(this.scheme = a[0]);
					var u = (this.userinfo = a[1]).split(':');
					this.server_authority = true;
					//this.opaque = false; 
					this.user = u[0];
					this.pass = u[1];
					this.host = a[2];
					this.port = a[3]||-1;
					this.authority=(a[1]?a[1]+'@':"")+host+(port!=-1?':'+port:"");
					this.path = a[4];
					this.query = a[5];
					this.fragment = a[6];
					break out;
				default:
					throw new URIError();
				}
				this.opaque = (this.absolute = def(this.scheme)) && this.ssp[0] != '/';
				if (this.absolute) this.scheme = decodeURIComponent(this.scheme);
	
				if (!this.opaque) {
					var s = this.ssp,n;
					if (this.absolute && (n=auth.exec(s))) { 
						this.authority=n[1];
						this.server_authority = def(n[2]);
						this.userinfo =n[3];
						this.user 	  =n[4];
						this.pass 	  =n[5];
						this.host 	  =decodeURIComponent(n[6]);
						this.port     =parseInt(n[7])||-1;
						s=s.slice(n[0].length);
					}
					if (n=path.exec(s)) { 
						this.file=n[0];
						this.path=n[1];
						this.query=n[2];
					}
				}
			} // out
		}; // constructor
	u.prototype = {
		clone: function() { 
			var r = new u;
			for (var i in this) { 
				r[i] = this[i];
			}
			return r;
			
		},
		opaque: false,
		scheme: null,
		relativize: function(that) { 
			if(this.opaque 
			|| that.opaque 
			|| this.scheme != that.scheme 
			|| this.authority != that.authority) return that;
			// Todo
			// if this.path is a prefix of that.path
			// return a relative uri that contains just the tail of that path
			// and its query and fragment
			return that;
		},
		resolve : function(that) {
			if (typeof(that)=="string") that = new Uri(that);
			if (this.opaque||that.absolute) return that;
			// Todo
			return that;
		},
		normalize : function() {
			var r = this.clone();
			if (def(r.path)) {
				var s = r.path.split("/"),t=[];
				for (var i=0,l=s.length;i<l;++i) {
					if (s[i] == '..' && t.length && t[t.length-1] != '' & t[t.length-1] != '..') { 
						t.pop();
						continue;
					}
					if (s[i] != '.') t.push(s[i]);
				}
				r.path = t.join('/');
			}
			return r;
		},
		
		toString: function() { 
			var r = '';
			if (this.scheme) r += encodeURIComponent(this.scheme)+':';
			if (this.opaque) r += this.ssp;
			else { 
				if (this.authority) {
					r += '//';
					if (this.server_authority) { 
						if (this.userinfo) { 
							if (this.user) r+= this.user;
							if (this.pass) r+= ':'+this.pass;
							r += '@';
						}
						r += encodeURIComponent(this.host);
						if (this.port>=0) { 
							r += ':'+this.port
						}
					} else { 
						r += this.authority;
					}
				}
				if (this.path) r += this.path;
				if (this.query) r += '?'+this.query
			}
			if (this.fragment) r += '#'+this.fragment;
			return r;
		}
	};
})();
#endif // vim:ts=4
