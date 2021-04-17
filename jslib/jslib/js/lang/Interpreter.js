// Javascript Interpreter (C) 2006 Edward Kmett. All Rights Reserved.
#ifndef INCLUDED_JS_LANG_INTERPRETER
#define INCLUDED_JS_LANG_INTERPRETER

// TODO: un-block-scope the contents of a try

#include "js/native/Platform.js"// __*__, HAS_EXCEPTIONS
#include "js/lang.js"
#include "js/lang/Parser.js" 	// js.lang.Parser
#include "js/lang/Token.js"	 	// js.lang.Token

(function (g) {
	var jl=js.lang;
	
	function $function(){}
	$function.prototype.toString = function() {return "function"};
	
	function $terminal(){}
	
	function $ref(){}
	$ref.prototype.toString = function() {return "reference"};
	
	function deref(x) { return x&&x.type==$ref ? x.o[x.i] : x; }
	
	var $throw = jl.WrappedException = function (x) { this.value = x };
	$throw.prototype = { type:$terminal, subtype:"throw" };
	
	function $return(x) { this.value = x }
	$return.prototype = { type:$terminal, subtype:"return" };
	
	function $break(x) { this.target = x }
	$break.prototype = { type:$terminal, subtype:"break" };
	
	function $continue(x) { this.target = x }
	$continue.prototype = { type:$terminal, subtype:"continue" };
	
	function tt(x){return x&&(x.type==$terminal)&&x.subtype}
	
	function Scope(o,p) { 
		this.o=o;
		this.p=p;	
		this.v=this;
	}
	Scope.prototype = { 
		ref: function(x){ 
			for(var s=this;s;s=s.p) if(x in s.o) return new Ref(s.o,x); 
			return new Ref(jl.Interpreter.global,x) 
		},
		let: function(x){ return new Ref(this.v.o,x) }
	};
	function With(o,p) { 
		this.o=o;
		this.p=p;
		this.v=p.v;
	}
	With.prototype=Scope.prototype;
	
	function Ref(o,i) { // horrible hack
		if (o.type==$ref) o = o.o[o.i]; 
		if (o[i]&&o[i].type==$ref) { // arguments
			this.o = o[i].o; 
			this.i = o[i].i;
		} else { 
			this.o = o; 
			this.i = i; 
		}
	}
	
	Ref.prototype = { 
		type:$ref,
		be: function(v){return this.o[this.i]=v},
		"=" :function(v){return this.o[this.i]=v},
		"+=":function(v){return this.o[this.i]+=v},
		"-=":function(v){return this.o[this.i]-=v},
		"*=":function(v){return this.o[this.i]*=v},
		"/=":function(v){return this.o[this.i]/=v},
		"%=":function(v){return this.o[this.i]%=v},
		"<<=":function(v){return this.o[this.i]<<=v},
		">>=":function(v){return this.o[this.i]>>=v},
		">>>=":function(v){return this.o[this.i]>>>=v},
		"&=":function(v){return this.o[this.i]&=v},
		"^=":function(v){return this.o[this.i]^=v},
		"|=":function(v){return this.o[this.i]|=v},
		$delete:function(v){return __delete__(this.o,this.i)},
		"++":{
			12:function(t){ return ++t.o[t.i] },
			14:function(t){ return t.o[t.i]++ },
		},
		"--":{
			12:function(t){ return --t.o[t.i] },
			14:function(t){ return t.o[t.i]-- },
		}
	};
	
	
	function literal(x) { 
		switch (x.v[0]) { 
		case "/": 
			var match = /\/(.*)\/([egim]*)/.exec(x.v); 
			return new RegExp(match[1],match[2]);
		case '"': 
		case "'": 
			return eval(x.v); // Todo: write a string parser.
		default: 
			return parseFloat(x.v);
		}
	}
	
	function try_apply(f,t,a) { 
#ifdef HAS_EXCEPTIONS
		try { 
#endif
			return f.apply(t,a); 
#ifdef HAS_EXCEPTIONS
		} catch(e) { 
			return new jl.WrappedException(e); 
		}
#endif
	};

	function try_new(f,a) { 
#ifdef HAS_EXCEPTIONS
		try { 
#endif
			switch (a.length) { 
			case 0: return new f();
			case 1: return new f(a[0]);
			case 2: return new f(a[0],a[1]);
			case 3: return new f(a[0],a[1],a[2]);
			case 4: return new f(a[0],a[1],a[2],a[3]);
			case 5: return new f(a[0],a[1],a[2],a[3],a[4]);
			case 6: return new f(a[0],a[1],a[2],a[3],a[4],a[5]);
			case 7: return new f(a[0],a[1],a[2],a[3],a[4],a[5],a[6]);
			case 8: return new f(a[0],a[1],a[2],a[3],a[4],a[5],a[6],a[7]);
			case 9: return new f(a[0],a[1],a[2],a[3],a[4],a[5],a[6],a[7],a[8]);
			case 10:return new f(a[0],a[1],a[2],a[3],a[4],a[5],a[6],a[7],a[8],a[9]);
			case 11:return new f(a[0],a[1],a[2],a[3],a[4],a[5],a[6],a[7],a[8],a[9],a[10]);
			case 12:return new f(a[0],a[1],a[2],a[3],a[4],a[5],a[6],a[7],a[8],a[9],a[10],a[11]);
			default: 
				// approximate the correct behavior
				var r = new f;
				f.apply(r,arguments);
				return r;
			}
#ifdef HAS_EXCEPTIONS
		} catch(e) { 
			return new jl.WrappedException(e);
		}
#endif
	};

	function parse(src,file,f) {
		var p = new jl.Parser(src,file),r = p[f](); 
		if (p.next.t != JS_LANG_TOKEN_EOF) p.err("Expected EOF");
		if (!r) __throw__(new jli.Error("No match"));
		return r;
	}

	jl.Token.Array.prototype.interpret = 
	jl.Token.prototype.interpret = function(x) { 
		var r = deref(_(this,x||new Scope(jl.Interpreter.global,null)));
		switch (tt(r)) {
		case "throw":	__throw__(r.value);
		case "return":	return r.value;
		}
		return r;
	};

	var jli = jl.Interpreter = function(x) { 
		this.scope = x;
	};
	jli.Error = function(e) {this.e=e};
	jli.Error.prototype.toString = function(){return this.e;} 
	jli.err = function(e){__throw__(new jli.Error(e))};
	jli.global = g;
	jli.prototype = {
		expr:function(s){ 
			var r = parse(s,"<expr>","expr")
			return r.interpret(this.x);
		}, 
		eval:function(s){ 
			var r = parse(s,"<eval>","parse");
			return r.interpret(this.x);
		},
		statement:function(s){ 
			var r = parse(s,"<statement>","statement");
			return r.interpret(this.x);
		}
	};

	jl.interpret = function(s) { return parse(s,"<eval>","parse").interpret(null); }

	
	function hash(s,r) {
		s=s.split(/ /);r=r||{};
		for (var i=0,l=s.length;i<l;++i) r[s[i]] = 1;
		return r; 
	}
	
	var pure_binary = hash("in instanceof || && | ^ & == != === !== < > <= >= << >> >>> + - * / % ,"),
		pure_unary = hash("( + - ~ ! typeof void");
	
	function _(t,x) { 
		if (!t) return null;
		if (!t.t) jli.err("Missing token type");
		if (pure_binary[t.t]) { 
			var l = deref(_(t.l,x)), r = deref(_(t.r,x));
			switch (t.t) { 
				case "instanceof": return __instanceof__(l,r); 
				case "in": return __in__(l,r);
				case "||":return l||r; 
				case ",": return l,r;
				case "&&":return l&&r; 
				case "|": return l|r; 
				case "^": return l^r; 
				case "&": return l&r;
				case "==":return l==r; 
				case "!=":return l!=r; 
				case "===":return l===r; 
				case "!==":return l!==r; 
				case "<":return l<r; 
				case ">":return l>r; 
				case "<=":return l<=r; 
				case ">=":return l>=r; 
				case "<<":return l<<r;
				case ">>":return l>>r; 
				case ">>>":return l>>>r; 
				case "+": return l+r; 
				case "-": return l-r; 
				case "*": return l*r;
				case "/": return l/r; 
				case "%": return l%r;
			}
		} else if (pure_unary[t.t]) { 
			var r = deref(_(t.expr,x));
			switch (t.t) { 
			case "(": return r; 
			case "+": return +r; 
			case "-": return -r; 
			case "~": return ~r; 
			case "!": return !r;
			case "typeof": return typeof r; 
			case "void": return r;
			}
		} else {
			switch (t.t) { 
			case "+=": case "-=": case "*=": case "/=": case "%=": case "<<=":
			case ">>=": case ">>>=": case "&=": case "^=": case "|=": case "=": 
				return _(t.l,x)[t.t](deref(_(t.r,x)));
			case "this": return x.ref("this");
			case JS_LANG_TOKEN_IDENT: return x.ref(t.v);
			case "delete": return _(t.l,x).$delete();
			case "[": return new Ref(_(t.l,x),_(t.r,x));
			case ".": return new Ref(_(t.l,x),t.r.v);
			case "?": return _(deref(_(t.l,x))?t.r.l:t.r.r,x);
			case "++": case "--": 
				var r = _(t.expr,x); 
				return r[t.t][t.h.t](r);
			case JS_LANG_TOKEN_LITERAL: return literal(t);
			case JS_LANG_TOKEN_ARRAY:
				var r = [];
				for (var i=0,l=t.b.length;i<l;++i) { 
					var s = t.b[i];
					if (s.delim) r.push(undefined);
					else { 
						r.push(deref(_(s,x)));
						++i
					}
				}
				return r;
			case JS_LANG_TOKEN_OBJECT:
				var r = {};
				for (var i=0,l=t.b.length;i<l;++i) {
					var s = t.b[i];
					r[s.t==IDENT?s.v:literal(s)]=deref(_(s.init,x));
				}
				return r;
			case "true": return true; 
			case "false": return false; 
			case "null": return null;
			case ";": return undefined;
			case JS_LANG_TOKEN_LABEL:
				var r = _(t.stmt,x); 
				return (tt(r)=="break" && r.label == t.label)? undefined : r;
			case "{": t=t.b; // fall
			case JS_LANG_TOKEN_STATEMENTS:
				var r;
				for (var i=0;i<t.length;++i) { 
					if (tt(r=_(t[i],x))) return r;
				}
				return r;
			case "with":
				var r = _(t.body,new With(deref(_(t.expr,x)),x));
				return r;
			case "if": 
				if (deref(_(t.cond,x))) { 
					return _(t.thn,x);
				} else { 
					return t.els ? _(t.els,x) : undefined;
				}
			case "break": 		return new $break(t.target);
			case "continue": 	return new $continue(t.target); 
			case "return": 		return new $return(t.expr?deref(_(t.expr,x)):undefined);
			case "throw": 		return new $throw(deref(_(t.expr,x)));

			case "const": case "var":
				for (var i=0;i<t.vars.length;++i) {
					var v = t.vars[i];
					x.v.o[v.v]=_(v.init,x);
				}
				return undefined;
			case "try":
				var y = new Scope({},x), r = _(t.b,y);
				if ((tt(r) == "throw") && t.c) { 
					var z = new Scope({},y);
					z.v[t.cvar] = r.value;
					r = _(t.c,z);
				}
				if (t.f) r = _(t.f,y);
				return r;
			case "switch":
				var v = _(t.expr,x),l=t.cases.length,i=l;
				if (t.hash) i = t.hash[v]||t.$default;
				else { 
					var d=l;
					for (var k=0;k<l;++k) { 
						var c=t.cases[k];
						if (c.t == "case") { 
							if (v == literal(_(t.expr,x))) {
								i=k; break;
							}
						} else d=k;
					}
					if (i==l) i=d;
				}
				for (;i<l;++i) {
					var r = _(t.cases[i],x),s=tt(r);
					if (s) { 
						if (s=="break" && r.target == t) return undefined;
						else return r;
					}
				}
				return undefined; 
			case "for":
				if (t.init) _(t.init,x);
			case "while": 
				loop: while (deref(_(t.cond,x))) { 
					var r = _(t.loop,x),s=tt(r);
					if (s) switch (s) {
					case "break": 
						if (r.target == t) break loop; 
						else return r;
					case "continue":
						if (r.target == t) { 
							if (t.next) _(t.next,x);
							continue loop;
						} // fall
					case "return": case "throw": return r;
					}
					if (t.next) _(t.next,x);
				} 
				return undefined;
			case "do":
				loop: do { 
					var r = _(t.loop,x), s = tt(r);
					if (s) switch (s) { 
					case "break": if (r.target == t) break loop; else return r;
					case "continue": if (r.target == t) continue loop; // fall
					default: return r;
					}
				} while (_(t.cond,x));
			case JS_LANG_TOKEN_FORIN:
				var i = t.v ? x.let(t.l) : _(t.l,x);
				loop: for (var v in deref(_(t.v,x))) { 
					i.be(v);
					var r = _(t.loop,x), s= tt(r);
					if (s) switch (s) { 
					case "break": if (r.target == t) break loop; else return r;
					case "continue": if (r.target == t) continue loop; // fall;
					default: return r;
					}
				}
				return undefined;
			case JS_LANG_TOKEN_FOREACH:
				var i = t.v ? x.let(t.l) : _(t.l,x);
				var o = deref(_(t.v,x));
				loop: for (var v in o) { 
					i.be(o[v]);
					var r = _(t.loop,x), s= tt(r);
					if (s) switch (s) { 
					case "break": if (r.target == t) break loop; else return r;
					case "continue": if (r.target == t) continue loop; // fall;
					default: return r;
					}
				}
				return undefined;
			case JS_LANG_TOKEN_STATEMENT:
				return _(t.expr,x);
			case JS_LANG_TOKEN_CALL:
				var f = _(t.f,x), a = [];
				for (var i=0,l=t.a.length;i<l;++i) a.push(deref(_(t.a[i],x)));
				var r = typeof(f)=="function"?try_apply(f,jli.global,a):try_apply(f.o[f.i],f.o,a);
				return r;
			case "new":
				var f = _(t.f,x), a = [];
				if (t.a) for (var i=0,l=t.a.length;i<l;++i) a.push(deref(_(t.a[i],x)));
				var r = typeof(f)=="function"?try_new(f,a):try_new(f.o[f.i],a);
				return r;
			case "function": // TODO: function hoisting
				var f = function(){
					var y = new Scope({},x);
					if (t.name) y.let(t.name.v).be(f);
					y.let("arguments").be(arguments);
					y.let("this").be(this);
					for (var i=0,l=t.a.length;i<l;++i) 
						y.let(t.a[i]).be(new Ref(arguments,i));
					var r = _(t.b,y), s = tt(r);
					switch (s) { 
					case "break": 
					case "continue": jli.err(s + " unhandled as of function exit");
					case "throw": __throw__(r.value);
					case "return": return r.value;
					default: return undefined;
					}
				};
				f.type = $function;
				f.__token__ = t;
				f.__context__ = x;
				f.valueOf = f.toSource = f.toString = function() { return t.toString(); };
				if (t.is_decl && t.name) x.let(t.name.v).be(f);
				return f;
			}
		}
		jli.err("Unexpected token "+t.t);
	}
})(this);
#endif // vim:ts=4
