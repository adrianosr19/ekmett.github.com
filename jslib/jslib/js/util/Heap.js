// Heap.js (C) 2006 Edward Kmett. All Rights Reserved
#ifndef INCLUDED_JS_UTIL_HEAP
#define INCLUDED_JS_UTIL_HEAP

#include "js/native/Platform.js"
#include "js/util.js"

(js.util.Heap = function (c,A,s){
	this.c=c||function($1,$2){return $1>$2};
	(this.A=A||[]).unshift(s);
	this.rebuild();
}).prototype = {
#ifdef DEBUG
	stringify_r:function(i,$1,$2,$3) { return i<this.A.length ?  this.stringify_r(2*i,$1+"   ",$1+",--",$1+"|  ")+ $2 + i+":"+this.A[i].toString() + "\n"+ this.stringify_r(2*i+1,$3+"|  ",$3+"`--",$3+"   ") : ""; },
	toString:function() { return this.stringify_r(1,"","",""); },
#endif
	rebuild: function(){
		for(var i=parseInt((this.A.length-1)/2);i;--i)this.heapify(i);
	},
	heapify:function(i){
		for(var A=this.A,c=this.c,n=0;i;i=n) {
			var s=A.length,l=2*i,r=l+1,t,m=(l<s&&c(A[i],A[l]))?l:i;
			n=(r<s&&c(A[m],A[r]))?r:m;
			if(n==i) break;
			t=A[i];A[i]=A[n];A[n]=t;
		}
	},
	pop:function(){ 
		var A=this.A,r=A.length;
		if (r==1) return this[0];
		else if (r==2) return A.pop();
		else {r=A[1];A[1]=A.pop();this.heapify(1);return r}
	},
	merge:function(B){
		const A=this.A,c=this.c,l=B.length,m=A.push.apply(A,B),i=m-l;
		for (var p,q,t;i<m;++i){
			p=i; 
			while(p>1){ 
			q=Math.floor(p/2);
			if(!c(A[q],A[p])) break;	
			t=A[p];A[p]=A[q];A[q]=t;p=q;
			}
		}
		return A.length;
	},
	push:function(){return this.merge(arguments);},
	top:function(){return this.A[1];},
	make_empty:function(){this.A.length=1;},
	is_empty:function(){return this.A.length==1;},
	sortd:function(r) {
		for(var i=this.A.length-1;i;--i)r.push(this.pop());
		return r;
	},
	sort:function(r){ 
		const t=this.A.slice(0);
		r=this.sortd(r||[]);
		this.A=t;
		return r;
	}
};

#endif // vim6:ts=4

