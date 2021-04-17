// Javascript Parser (C) 2006 Edward Kmett. All Rights Reserved.
#ifndef INCLUDED_JS_LANG_PARSER
#define INCLUDED_JS_LANG_PARSER

// Todo: Implement a recovery model, like a real compiler.

#include "js/native/Platform.js" 		// __*__
#include "js/lang.js"
#include "js/lang/Token.js" 			// js.lang.Token

//<options>
#define PARSE_LINE_DIRECTIVES // slightly slower
#define PARSE_WITH_WARNINGS // requires print()
#define PARSE_WITH_VERBOSE_ERRORS
//</options>

#ifdef PARSE_WITH_WARNINGS
#define PARSE_PROGRESS // see bottom of this file
#endif

#ifdef PARSE_WITH_VERBOSE_ERRORS
#define PARSE_PROGRESS // see bottom of this file
#endif



(function (){ 
	var jl = js.lang, jlt=jl.Token, jlta=jlt.Array, z=jlt.handlers;

	function ops(i){
		return{JS_LANG_TOKEN_EOF:-1,'in':i,',':1,'=':2,'+=':2,'-=':2,'*=':2,'/=':2,'%=':2,'<<=':2,'>>=':2,'>>>=':2,'&=':2,'^=':2,'|=':2,'?':3,'||':4,'&&':5,'|':6,'^':7,'&':8,'==':9,'!=':9,'===':9,'!==':9,'instanceof':10,'<':10,'<=':10,'>':10,'>=':10,'<<':11,'>>':11,'>>>':11,'+':12,'-':12,'*':13,'/':13,'%':13}
	}

	var prec = ops(6), noin = ops(-1),
		bkw = z.$binary_kw,
		oh = { "in":bkw, "instanceof": bkw }, 
		scan_lbl = {7:1,";":1,"{":1,"}":1},
		skip_lit = {3:1,4:1,")":1,"}":1,"]":1,".":1,"this":1},

		skip = new RegExp('^(?:\\s+|\\/(?:\\*(?:.|\\n)*?\\*\\/|\\/.*))+'),
		lit = new RegExp('(?:^(?:\\d+\\.\\d*(?:[eE][-+]?\\d+)?|^\\d+(?:\\.\\d*)?[eE][-+]?\\d+|^\\.\\d+(?:[eE][-+]?\\d+)?|(?:"(?:[^\\\\"]|\\\\.)*"|'+"'"+'(?:[^\\\\'+"'"+']|\\\\.)*'+"'"+')|0[xX][\\da-fA-F]+|^0[0-7]*|^\\d+|\\/(?:(?:\\\\.|[^\\\\\\/])+)\\/(?:[egim]*)))'),
		op= new RegExp('^(?:\\|[\\|=]?|\\&[\\&=]?|\\^=?|=(?:==?)?|!(?:==?)?|<(?:(?:<=?|=))?|>(?:(?:>(?:(?:>=?|=))?|=))?|\\+[\\+=]?|\\-[\\-=]?|\\*=?|\\/=?|%=?|[?,\\:~.()\\[\\]{};])'),
		kw= new RegExp('^(?:break|c(?:a(?:se|tch)|on(?:st|tinue))|d(?:e(?:fault|lete)|o)|else|f(?:alse|inally|or|unction)|i(?:n(?:stanceof)?|f)|n(?:ew|ull)|return|switch|t(?:h(?:is|row)|r(?:ue:y)|ypeof)|v(?:ar|oid)|w(?:hile|ith))$'),
		lbl = new RegExp('^(\\w+)(?:\\s+|\\/(?:\\*(?:.|\\n)*?\\*\\/|\\/.*))+:'), 
		id = new RegExp('^[\\w$_]+'), newlines = new RegExp('\\n','g');

#ifdef PARSE_LINE_DIRECTIVES
		atline = new RegExp('^(?:\\n|.)*(?://@line|#)\\s+(\\d+)(?:\\s+"([^"]*)")?(?:\\s\\d+)*\n((?:\\n|.)*)$'),
#endif
		stmt_consumes = {";":1,"{":1,"const":1,"var":1,"if":1,"do":1,"while":1,"for":1,"continue":1,"break":1,"return":1,"with":1,"switch":1,"throw":1,"try":1,5:1},
		qh = {"++":z.$post,"--":z.$post},ph={},
		ins = {"}":1,6:1,"else":1,"while":1}, // else/while from Netscape's ECMA 4 proposal.
		ao = '= += -= *= /= %= <<= >>= >>>= &= ^= |='.split(" "), 

	ph["delete"]=ph["void"]=ph["typeof"]=z.$pre_kw;
	ph["++"]=ph["--"]=ph["+"]=ph["-"]=ph["~"]=ph["!"]=z.$pre;
	for (var i=0;i<ao.length;++i) oh[ao[i]]=z.$binary_rl;

	var jlp = jl.Parser = function(s,f) { 
		this.src = s;
		this.file = f||"eval";
		this.line = 1;
		this.lpos = this.pos = 0;
		this.lbls = {};
		this.next = new jlt(JS_LANG_TOKEN_START);
		this.consume();
	}, 
#ifdef PARSE_WITH_VERBOSE_ERRORS // still in var decl
	jlps = jlp.SyntaxError = function(e,p,o) { 
		this.e=e; this.parser=p; this.o=o;
	};
	jlps.prototype.toString = function() { 
		return this.parser.progress(this.e,this.o);
	}; 
#else // still in var decl
	jlps = jlp.SyntaxError = function(e,l) { this.e=e;this.l=l },
	jlps.prototype.toString = function() { return this.l +":"+this.e; }
#endif

	var P = jlp.InternalError = function(m) { this.m = m; };
	P.prototype.toString = function(){ return this.m; }; 
	function panic(m) { __throw__(new P(m)); } 

	jlp.prototype = {  
		clone: function() { 
			var r  = new jlp(this.src,this.file);
			r.line =this.line;
			r.pos  = this.pos;
			r.lpos = this.lpos;
			r.lbls = this.lbls;
			r.next = this.next;
			return r;
		},
#ifndef PARSE_WITH_WARNINGS
		warn: function(e) { print(this.progress(e,this.lpos)) }, 
#endif
#ifdef PARSE_WITH_VERBOSE_ERRORS
		err: function(e) { __throw__(new jlp.SyntaxError(e,this,this.lpos)) },
#else 
		err: function(e) { __throw__(new jlp.SyntaxError(e,this.line)) },
#endif
		match: function(t){return this.next.t==t?this.consume():null},
		expect: function() { 
			for (var i=0,a=arguments,l=a.length;i<l;++i) { 
				var n=this.next,t=n.t;
				if (t==a[i]) this.consume();
				else if (a[i]!=";") this.err("Expected "+a[i]+ " but found "+n.type());
				else if (!n.nl && !ins[n.t]) this.err("Illegal ';' insertion required at "+n.t);
			}
		},
		consume: function() { 
			var r = this.next, 
				l = this.line,
				s = this.src.slice(this.pos), 
				m = skip.exec(s), 
#ifdef PARSE_LINE_DIRECTIVES
				m2,
#endif
				token;
			if (m) {
				s = this.src.slice(this.pos+=m[0].length);
#ifdef PARSE_LINE_DIRECTIVES
				if (m2=m[0].match(atline)) {
					this.line = parseInt(m2[1]);
					if (m2[2]) this.file = m2[2];
					if (m=m2[3].match(newlines)) this.line+=m.length;
				} else 
#endif
				if (m=m[0].match(newlines)) this.line+=m.length;
			}
			this.lpos = this.pos;
			if (!s) {
				this.next=new jlt(JS_LANG_TOKEN_EOF);
				return r;
			} else if (scan_lbl[r.t] && (m = lbl.exec(s)) && m[1] != "default") { 
				if (s=m[0].match(newlines)) this.line+=s.length;
				token = new jlt(JS_LANG_TOKEN_LABEL,m[1]); 
				token.name = m[1]; 
			} else { 
					if ((!skip_lit[r.t]) && (m = lit.exec(s))) {
						token = new jlt(JS_LANG_TOKEN_LITERAL,m[0]);
						token.h = z.$lit;
					} else if (m = op.exec(s)) token = new jlt(m[0]);
					else if (m = id.exec(s)) { 
						token = new jlt(kw.exec(m[0]) ? m[0] : JS_LANG_TOKEN_IDENT,m[0]); 
						token.h = z.$id;
					} else this.err("Unknown lexical item");
			}
			var p = this.pos;
			this.pos += m[0].length;
			if (l != this.line) token.nl = 1;
			this.next=token;
			return r;
		},
		id: function() { return this.match(JS_LANG_TOKEN_IDENT); },
		func: function() {
			var l = this.lbls;
			this.lbls = {};
			var r = this.match("function");
			var a = this.consume();
			if (a.t == JS_LANG_TOKEN_IDENT) { r.name = a; a = this.consume()} 
			if (a.t != "(") this.err("Expected (");
			r.a = this.tie("id",",");
			this.expect(")","{");
			r.b = this.statements();
			this.expect("}");
			r.h = z.$func;
			this.lbls = l;
			return r;
		},
		star: function(f,h) {
			var r = new jlta(h||z.$star),s;
			while ((s=this[f]()) != null) r.push(s);
			return r;
		},
		tie: function(f,c,p) { 
			var s, r = new jlta(z.$tie);
			while (s = this[f](p)) { 
				r.push(s);
				if (!this.match(c)) break;
			}
			return r;
		},
		args: function() {
			if (this.match("(")) { 
				var r = this.tie("aexpr",",");
				this.expect(")");
				return r;
			} else return null;
		},
		aexpr: function() { return this.expr(2); },
		uexpr: function() {
			var a = this.next,h;
			if (h=ph[a.t]) { 
				a.h=h;
				this.consume();
				a.expr = this.uexpr();
			} else { 
				var r = this.mexpr(false,true);
				if (!r) return null;
				a=this.next;
				if (h=qh[a.t]) {
					a.h=h;
					this.consume();
					a.expr = r;
				} else return r;
			}
			return a;
		},
		expr: function (m,p) { return this.op(this.uexpr(),m||1,p||prec) },
		op: function(lhs,min,prec) { 
			var m = this.next.t, p = prec[m];
			if (typeof(p)=="undefined") return lhs;
			while (p>=min) { 
				var op = this.consume(), rhs = (m == '?') ? this.hookrhs() : this.uexpr();
				if (!rhs || rhs.t == JS_LANG_TOKEN_EOF) this.err("Expected operand after '"+op.type()+"'");
				var n = this.next.t, q = prec[n];
				if (typeof(q)=="undefined") return this.reduce(lhs,op,rhs);
				while (q>p || (q==p && n==2)) {
					rhs = this.op(rhs,q,prec);
					n = this.next.t;
					q = prec[n];
					if (typeof(q)=="undefined") return this.reduce(lhs,op,rhs);
				}
				lhs = this.reduce(lhs,op,rhs);
				p = q; m = n;
			}
			return lhs;
		},
		reduce: function(lhs,op,rhs) { 
			op.l = lhs; 
			op.r = rhs; 
			op.h = oh[op.t] || z.$binary;
			return op; 
		},
		hookrhs: function() { 
			var l = this.aexpr(), h=this.match(":");
			if (!h) this.err("Expected :");
			h.l = l;
			h.r = this.aexpr();
			h.h = z.$binary;
			return h 
		},
		mexpr: function(reqargs,allowargs) {
			var a=this.next;
			switch (a.t) { 
			case "new": 
				this.consume();
				a.h = z.$new;
				a.f = this.mexpr(reqargs,false); 
				a.a = this.args();
				if (!a.a && reqargs) this.err("arguments expected"); 
				break;
			case "function": a = this.func(a); break;
			default: a = this.primary(); break;
			case JS_LANG_TOKEN_EOF: return null;
			};
			// left recursion
			while (a) { 
				var b = this.next;
				switch (b.t) { 
				case "[":
					this.consume();
					b.h = z.$bracket;
					b.r = this.expr();
					this.expect("]");
					b.l = a;
					a = b;
					break;
				case ".":
					this.consume();
					b.h = z.$binary;
					b.r = this.id();
					b.l = a;
					a = b;
					break;
				case "(":
					if (allowargs) {
						this.consume();
						b.t = JS_LANG_TOKEN_CALL;
						b.h = z.$call;
						b.a = this.tie("aexpr",",");
						b.f = a;
						this.expect(")");
						a=b;
						break;
					} 
				case JS_LANG_TOKEN_EOF:
				default: 
					return a;
				}
			}
			return a;
		},
		prop: function() { 
			var a = this.next;
			if (a.t == JS_LANG_TOKEN_IDENT || a.t == JS_LANG_TOKEN_LITERAL|| a.t == JS_LANG_TOKEN_LABEL) { 
				if (a.t ==  JS_LANG_TOKEN_LABEL) { // HACK!
					a.t = JS_LANG_TOKEN_IDENT;	 
					this.next = new jlt(":");
				} else { 
					this.consume();
				}
				this.expect(":");
				a.h = z.$prop;
				a.init = this.aexpr();
				return a;
			}
			return null;
		},
		elist: function(r) { // elision disallows use of tie
			var s=0,t, r = new jlta(z.$star);
			while(1){ 
				if (t=this.match(",")){ 
					t.delim=1;
					r.push(t);
					s=0; 
				} else { 
					if (!s) { 
						var t=this.aexpr();
						if (t) { 
							r.push(t);
							s=1;
						} else return r;
					} else return r;
				}
			}
		},
		primary: function() { 
			var a = this.next;
			switch (a.t) { 
			case "(": 
				this.consume();
				a.h = z.$pexpr;
				a.expr = this.expr();
				this.expect(")");
				return a;
			case "[": 
				this.consume();
				a.t = JS_LANG_TOKEN_ARRAY;
				a.h = z.$array;
				a.b =this.elist();
				this.expect("]");
				return a; 
			case "{":
				this.consume();
				a.t = JS_LANG_TOKEN_OBJECT;
				a.h = z.$object;
				a.b = this.tie("prop",",");
				this.expect("}");
				return a;
			case "true":
			case "false":
				a.h = z.$boolean; // fall
				return this.consume();
			case "null":
				a.h = z.$null;
				return this.consume();
			case JS_LANG_TOKEN_LITERAL: // we could make __LINE__ and __FILE__ magical here
			case JS_LANG_TOKEN_IDENT: 
				return this.consume();
			case "this": 
				a.h = z.$this; 
				return this.consume();
			default: 
				return null;
			};
		},
		pexpr: function() { 
			var t = this.match("(");
			if (!t) this.err("Expected (");
			var r = this.expr();
			this.expect(")");
			t.h = z.$pexpr;
			t.expr = r;
			return t;
		},
		statements: function() { 
			var r = this.star("statement",z.$stmts); 
			r.t = JS_LANG_TOKEN_STATEMENTS;
			return r;
		},
		vdecl: function(prec) { 
			var a = this.id();
			if (this.match("=")) { 
				a.init = this.expr(2,prec);
				a.h = z.$vdecl;
			}
			return a;
		},
		statement: function(q) { 
			var a = this.next;
			if (stmt_consumes[a.t]) {
				if (q && a.t != JS_LANG_TOKEN_LABEL) 
					for (var i=0,l=q.length;i<l;++i) 
						this.lbls[q[i]]=a;
				this.consume();
			}
			switch (a.t) { 
			case ";": 
				a.h = z.$empty;
				break;
			case "{": 
				a.h = z.$block;
				a.b = this.statements(); 
				this.expect("}");
				break;
			case "const": a.is_const = 1;
			case "var": 
				a.h = z.$var;	
				a.vars = this.tie("vdecl",",");
				this.expect(";");
				break;
			case "if":
				a.h = z.$if;
				a.cond = this.pexpr();
				a.thn = this.statement();
				if (this.match("else")) a.els = this.statement();
				break;
			case "do":
				var t = this.lbls[""];
				this.lbls[""] = a;
				a.h = z.$do;
				a.loop = this.statement();
				this.expect("while");
				a.cond = this.pexpr();
				this.expect(";");
				this.lbls[""] = t;
				break;
			case "while":
				var t = this.lbls[""];
				this.lbls[""] = a;
				a.h = z.$while;
				a.cond = this.pexpr();
				a.loop = this.statement();
				this.lbls[""] = t;
				break;
			case "for":
				var t = this.lbls[""];
				this.lbls[""] = a;
				if (this.next.t == JS_LANG_TOKEN_IDENT && this.next.v == "each") { 
					a.each = "each";
					this.consume() 
				} 
				this.expect("(");
				var d = this.next,e=(d.t=="var"||d.t=="const"),b;
				if (e) {
					this.consume();
	           	b = this.tie("vdecl",",",noin);
				} else b = this.expr(2,noin);
				if (this.next.t == "in") { 
					// for [each] ([var|const] lhsexpr in expr) {}
					this.consume();
					a.r = this.expr();
					a.l = b; 
					a.v = (e) ? d.t : "";
					a.h = a.each ? z.$for_each : z.$for_in;
					a.t = a.each ? JS_LANG_TOKEN_FOREACH : JS_LANG_TOKEN_FORIN;
				} else { 
					a.h = z.$for_c;
					if (e) { 
						d.h = z.$var;
						d.vars = b;
						a.init = d;
					} else a.init = b;
					if (!this.match(";")) this.err("Expected ;");
					a.cond = this.expr();
					if (!this.match(";")) this.err("Expected ;");
					a.next = this.expr();
				}
				this.expect(")");
				a.loop = this.statement();
				this.lbls[""] = t;
				break;
			case "continue": // fall
			case "break":
				a.h = a.t == "continue"? z.$continue: z.$break;
#ifdef PARSE_WITH_WARNINGS
				if (this.next.nl) this.warn("Link-break after "+a.t);
#endif
				a.lbl = this.next.nl ? null : this.match(JS_LANG_TOKEN_IDENT);
				if (!(a.target = this.lbls[a.lbl?a.lbl.v:""])) this.err("Unknown label "+a.lbl);
				this.expect(";");
				break;
			case "return":
				a.h = z.$return;
#ifdef PARSE_WITH_WARNINGS
				if (this.next.nl) this.warn("Line-break after return");
#endif
				a.expr = this.next.nl ? null : this.expr(); 
				this.expect(";");
				break;
			case "with":
				a.h = z.$with;
				a.expr = this.pexpr();
				a.stmt = this.statement();
				break;
			case "switch":
				var t = this.lbls[""];
				this.lbls[""] = a;
				a.h = z.$switch;
				a.expr = this.pexpr();
				this.expect("{");
				a.cases = this.star("switch_case");
				this.expect("}");
				this.lbls[""] = t;
				break;
			case "throw":
				a.h = z.$throw;
#ifdef PARSE_WITH_WARNINGS
				if (this.next.nl) this.warn("Line-break after throw");
#endif
				a.expr = this.next.nl? null : this.expr();
				this.expect(";");
				break;
			case "try":
				a.h = z.$try;
				this.expect("{");
				a.b = this.statements();
				this.expect("}");
				if (this.match("catch")) { 
					this.expect("(");
					a.cvar = this.expect(JS_LANG_TOKEN_IDENT);
					this.expect(")","{");
					a.c = this.statements();
					this.expect("}");
				}
				if (this.match("finally")) { 
					this.expect("{");
					a.f = this.statements();
					this.expect("}");
				}
				break;
			case "]":case "catch":case "finally": 
				this.err("Unexpected "+this.t);
			case "case":case "default":case "}":case ")": case JS_LANG_TOKEN_EOF: 
				return null; 
			case "function":
				var f = this.func();
				f.is_decl = true;
			case JS_LANG_TOKEN_IDENT:
				// skim to see if the next token is a : if not fall through to expr
				var c = this.clone();
				c.expect(JS_LANG_TOKEN_IDENT);
				if (c.match(":")) { 
					// this is a label.
					this.expect(JS_LANG_TOKEN_IDENT,":")
					q=q||[];
					q.push(a);
					a.t = JS_LANG_TOKEN_LABEL
					a.h = z.$lbl;
					a.stmt = this.statement(q);
					break;
				}
			default:
				a = this.expr();
				if (!a) return null;
				var b = new jlt(JS_LANG_TOKEN_STATEMENT);
				b.expr=a;
				b.h=z.$expr_stmt;
				a=b;
				this.expect(";");
				return a;
			};
			if (q && a.t != JS_LANG_TOKEN_LABEL)
				for (var i=0,l=q.length;i<l;++i) 
					__delete__(this.lbls,q[i]);
			return a;
		},
		switch_case:function() {
			var a = this.next;
			switch (a.t) { 
			case "case": 
				this.consume();
				a.h = z.$case;
				a.expr = this.expr();
				break;
			case "default":
				this.consume();
				a.h = z.$default;
				break;
				return a;
			default: 
				return null;
			}
			this.expect(":");
			a.stmts = this.statements();
			return a;
		},
		eof: function(o) { 
			if (this.next.t != JS_LANG_TOKEN_EOF) this.err("Expected EOF");
			return o;
		},
		parse: function() { 
			return this.eof(this.statements()); 
		}
	};
	jl.parse = function(x) { // facade
		switch (typeof(x)) { 
		case "object": s = x.toSource(); f = "expr"; break;
		case "array": s = x.toSource(); f = "expr"; break;
		case "function": s = x.toSource(); f = "expr"; break;
		case "string": s = x; f = "statements"; break;
		default: print(x+":"+typeof(x));return null;
		};
		var p = new jlp(s);
		return p.eof(p[f]());
	};
})();

#ifdef PARSE_PROGRESS
#include "js/lang/Parser/progress.js"
#endif

#endif // INCLUDED_JS_LANG_PARSER vim:ts=4
