#include "js/util/DisjointSet.js"

print("1..3");
var s = new js.util.DisjointSet;
var v = new Array;
for (var i=0;i<32;++i) { v[i] = s.alloc(); }
for (var i=0;i<31;i+=2) s.union(v[i],v[i+1]);
for (var i=0;i<29;i+=4) s.union(v[i],v[i+2]);
for (var i=0;i<26;i+=8) s.union(v[i],v[i+4]);

print(s.find(10)==8?"ok 1":"not ok 1");
print(s.find(20)==16?"ok 2":"not ok 2");
print(s.find(30)==24?"ok 3":"not ok 3");
print("END");
