function flatten(head,roots,ctx) {
	(roots = roots || []).push(head)
	var n,output=[];
	while (n = q.pop()) {
		output.push(n);
		// switch on n's type.
		if (n.length == 1) {
			// check if the next node is already placed.
			if (!n[0].placed) {
				n[0].placed = 1;
				Node.union(n.index,n[0].index);
				n.next = n[0];
			}
		}
		n.length;
	}
}


function recompile(t,p,i,d) {
	switch (t.t) {
	case "function": d.duff_function(t);
	case JS_LANG_TOKEN_SCRIPT:   d.duff_script(t);
	case JS_LANG_TOKEN_STMTS:
		for (var i=0;i<t.length;++i) {
			t[i].fg = new Stmt(t[i]);
		};
		for (var i=0;i<t.length-1;++i) {
			t[i].fg.tail.edge(t[i+1].fg.head);
		}
		return flatten(t[i].fg.head,0,d);
	default:
		js.panic("Unable to recompile token "+ t.t + " directly. Try wrapping in a script or function");
	}
};

function cps_ident(s) {return s.match(/_$/)}
function cps_arg_string(a,v) { a.push(v); var r = a.toString(); a.pop(v); return r }
function appel_prologue(c){return(c<=1?"if(--appel_h":"if(appel_h-="+(c>500?500:c))+"<0)return appel(this,arguments);"}

function Node() { this.index = Node.set.alloc(); }
Node.set = new Set();
Node.index = 0;
var np = Node.prototype = new Array;
np.edge = [].push;
np.find = function() { return Node.set.find(this.index); } 

var fgnull = { edge: function(){}, is_null: 1 }

function expand_cps(t,p,i,d) { 
}

function Expr(t,ctx) { 
	var sentinel={};
	if (!partial_fold(t,sentinel,"value")) { 
		this.value = sentinel.value.value;
		this.is_constant = true;
		this.tail = this.head = new Node();
	} else { 
		// now we need to recursively expand cps calls
		ctx.$head = this.head = new Node();
		expand_cps(t,sentinel,"value",ctx);
		this.tail = ctx.$head;
		this.value = sentinel.value || t;
	}
}

function Cond(t,ctx) { 
	var expr = new Expr(t);
	this.head = expr.head;
	
	if (expr.is_constant) { 
		if (expr.value) { 
			expr.tail.edge(this.t = new Node());
			this.f = fgnull;
		} else { 
			expr.tail.edge(this.f = new Node());
			this.t = fgnull;
		} 
	} else {
		this.t = new Node();
		this.f = new Node();
		var body = new Action(t,ctx,this.f,function(){"if ("+expr+") "+ctx.state(this.t)},[this.t,this.f])};
		expr.tail.edge(body.head);
		expr.on_false(this.f = new Node());
		this.f = fgnull;
	} else { 
		expr.on_true(this.t = new Node());
		expr.on_false(this.f = new Node());
	}
}

function Stmt(t,ctx,labels) { 
	switch (t.t) {
	case "if":
		var cond = new Cond(t.cond,ctx);
		var thn = new Stmt(t.thn,ctx);
		var tail = this.tail = new Node();
		cond.t.edge(thn.head);
		thn.tail.edge(tail);
		if (t.els) { 
			els = new Stmt(t.els,ctx);
			cond.f.edge(els.head);
			els.tail.edge(tail);
		} else { 
			cond.f.edge(tail);
			thn.tail.edge(tail);
		}
		this.head=cond.head;
		break;
	case JS_LANG_TOKEN_LBL:
		var tail = this.tail = new Node();
		var subctx = ctx.scope();
		subctx.set_break(t.label,tail)
		(labels=labels||[]).push(t.label);
		var stmt = new Stmt(t.stmt,ctx,labels);
		stmt.tail.edge(tail);
		this.head=stmt.head;
		break;
	case "while":
		var cond = new Cond(t.cond,ctx);
		var tail = this.tail = new Node();
		var subctx = ctx.scope();
		subctx.set_break("",tail);
		if (labels) subctx.set_continues(labels,cond.head);
		var loop = new Stmt(t.loop,subctx);
		cond.t.edge(loop.head);
		cond.f.edge(tail);
		loop.tail.edge(this.head = cond.head);
		break;
	case "do":
		var subctx = ctx.scope();
		subctx.set_break("",this.tail = new Node());
		if (labels) subctx.set_continues(labels,this.head = new Node());
		var loop = new Stmt(t.stmt,subctx);
		this.head.edge(loop.head);
		var cond = new Cond(t.cond,ctx);
		loop.tail.edge(cond.head);
		cond.t.edge(loop.head);
		conf.f.edge(this.tail);
		break;
	case ";":
		this.head = this.tail = new Node();
		break;
	case "return":
		var expr = new Expr(t.expr,ctx,ctx.$return);
		this.head = expr.head;
		this.tail = fgnull;
		break;
	case "throw":
		var expr = new Expr(t.expr,ctx,ctx.$throw);
		this.head = expr.head; 
		this.tail = fgnull;
		break;
	case "break":
		(this.head = new Node()).edge(ctx.get_break(t.label));
		this.tail = fgnull;
		break;
	case "continue":
		(this.head = new Node()).edge(ctx.get_continue(t.label));
		this.tail = fgnull;
		break;
	case JS_LANG_TOKEN_STMT:
		// Expr.call(this,t.expr); break; 
		var r = new Expr(t.expr);
		this.head = r.head; this.tail = r.tail;
		break;
	case "with":
	case "var":
	case "function":
	case "switch":
	case "for":
	case "try":
	default: js.panic("Unimplemented statement token:" + t.t);
	};
}

// vim:ts=4
