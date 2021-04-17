function CToken() { this.id = CToken.set.alloc(); };
CToken.set = new Set();
CToken.id = 0;
CToken.prototype.toString = function() { return "$$"+CToken.set.find(this.id).toString(36).toUpperCase(); };
CToken.prototype.visit = function() { };
