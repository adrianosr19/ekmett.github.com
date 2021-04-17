#include "js/test/Simple.js"
#include "js/util/Heap.js"

plan(9);
var h = new js.util.Heap(null,[1,3,2,1,3,4,1,8,38]);
ok(h.pop()==1);
ok(h.pop()==1);
ok(h.pop()==1);
ok(h.pop()==2);
ok(h.pop()==3);
ok(h.pop()==3);
ok(h.pop()==4);
ok(h.pop()==8);
ok(h.pop()==38);
