function Context() { 
	this.$tail = this.$return = "(function(){return null;})";
	this.add_scope(null) 
}
Context.prototype = { 
	add_scope : function(parent) { 
		this.scope = function() {
			this.parent = parent;
			this.add_scope(this);
		};
		this.scope.prototype = this;
	},
	set_break : function(label,node){ 
		this["break_"+label] = node;
	},
	set_continues : function(labels,node) {
		for (var i=0,l=labels.length;i<l;++i) { 
			this["continue_"+labels[i]] = node;
		}
		this["continue_"] = node;
	},

	state: function(i) { return "{"+this.$state+"="+i.find()+";break "+this.$goto+"}" },
	state_var: function(i,v) { return "{"+this.$state+"="+i.find()+";"+this.$var+"="+v+"break "+this.$goto_var+"}" },
	
	duff_function: function(t) { 
		var ctx = this.duff_device();
		ctx.$this = new CToken();
		ctx.$arguments = new CToken();
		ctx.$tail = ctx.$return = new CToken();
		t.ctx = this;
		t.body_string = recompile(t.body,t,"body",ctx);
		t.toString = duff_function_toString;
		return t;
	},
	duff_script : function(t) { 
		var ctx = this.duff_device();
		ctx.$this = new CToken();
		ctx.$arguments = new CToken();
		t.body_string = recompile(t.body,t,"body",ctx);
		t.toString = duff_script_toString;
		return t;
	},

	duff_device: function(t) {
		var ctx = this.scope();
		var $device = ctx.$device = new CToken();
		var $state = ctx.$state = new CToken();
		var $var = ctx.$var = new CToken();
		var $goto = ctx.$goto = new CToken();
		var $goto_var = ctx.$goto_var = new CToken();
		ctx.duff_prologue= 
			"(function "+$device+"("+$state+","+$var+"){"+
			"if (appel_h-=2<0)return appel(this,arguments);"+
			$goto_var+": with("+$var+")"+$goto+":do{switch("+$state+"){case 0:";

		ctx.duff_epilogue= "}}while(1);})(0,{})";
		return ctx;
	}
};

function duff_function_toString() { 
	var $ = this.ctx;
	return "function "+(t.name||"")+"("+t.a +") {"+
	   "var "+$.$this+"=this,"+$.$arguments+"=arguments,"+$.$return+"=arguments[--arguments.length];return "+
		$.duff_prologue+
		this.body_string+
		$.duff_epilogue+
	"}";
};

function duff_script_toString() { 
	var $ = this.ctx;
	return "var "+$.$this+"=this,"+$.$arguments+"=arguments;"+
		$.duff_prologue+
		this.body_string+
		$.duff_epilogue+
	";";
};

