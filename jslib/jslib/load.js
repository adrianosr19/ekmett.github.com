#include "js/net/Uri.js"
function load(f){
	Http.sync(f,function(b){ 
		eval(b);
	},function(e) {
		throw e;
	}
}
