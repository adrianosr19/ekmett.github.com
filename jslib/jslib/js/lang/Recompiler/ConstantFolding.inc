// Constant Folding 

function partial_fold(t,p,i) { 
	if (mt[t.t]) { 
		return t.visit(partial_fold)||true; 
	} else { 
		if (t.visit(partial_fold)) return true;
		else {
			var r = fold(t,p,i);
			switch (typeof(r)) { // TODO rebuild these.
			case "undefined": (p[i] = new Token(JS_LANG_TOKEN_LIT,"undefined")).h = js.handlers.literal_h; break;
			case "object": (p[i] = new Token(JS_LANG_TOKEN_LIT,r?r.toSource():"null")).h = js.handlers.literal_h; break;
			case "boolean": (p[i] = new Token(r?"true":"false")).h = js.handlers.boolean_h; break;
			default: (p[i] = new Token(JS_LANG_TOKEN_LIT,r.toSource())).h = js.handlers.literal_h;
			}
			p[i].value = r;
			return false;
		}
	}
};

function fold(t) { 
	// Todo: allow most Math functions to fold, and consider Array and Object literal support.
	if (cb[t.t]) { 
		var l = fold(t.l);
		var r = fold(t.r);
		switch (t.t) { 
			case "||":return l||r; 
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
	} else if (cu[t.t]) { 
		var expr = fold(t.expr);
		switch (t.t) { 
			case "(": return expr; 
			case "+": return +expr; 
			case "-": return -expr; 
			case "~": return ~expr; 
			case "!": return !expr;
			case "typeof": return typeof expr; 
			case "void": return undefined;
		}
	} else {
		switch (t.t) { 
			case JS_LANG_TOKEN_LIT: return eval(t.v); 
			case "true": return true; 
			case "false": return false; 
			case "null": return null;
			case "?": return fold(fold(t.l)?t.r.l:t.r.r);
		}
	}
	js.panic("Unexpected token "+ t.t + " while constant folding");
}
