(function dartProgram(){function copyProperties(a,b){var s=Object.keys(a)
for(var r=0;r<s.length;r++){var q=s[r]
b[q]=a[q]}}function mixinPropertiesHard(a,b){var s=Object.keys(a)
for(var r=0;r<s.length;r++){var q=s[r]
if(!b.hasOwnProperty(q)){b[q]=a[q]}}}function mixinPropertiesEasy(a,b){Object.assign(b,a)}var z=function(){var s=function(){}
s.prototype={p:{}}
var r=new s()
if(!(Object.getPrototypeOf(r)&&Object.getPrototypeOf(r).p===s.prototype.p))return false
try{if(typeof navigator!="undefined"&&typeof navigator.userAgent=="string"&&navigator.userAgent.indexOf("Chrome/")>=0)return true
if(typeof version=="function"&&version.length==0){var q=version()
if(/^\d+\.\d+\.\d+\.\d+$/.test(q))return true}}catch(p){}return false}()
function inherit(a,b){a.prototype.constructor=a
a.prototype["$i"+a.name]=a
if(b!=null){if(z){Object.setPrototypeOf(a.prototype,b.prototype)
return}var s=Object.create(b.prototype)
copyProperties(a.prototype,s)
a.prototype=s}}function inheritMany(a,b){for(var s=0;s<b.length;s++){inherit(b[s],a)}}function mixinEasy(a,b){mixinPropertiesEasy(b.prototype,a.prototype)
a.prototype.constructor=a}function mixinHard(a,b){mixinPropertiesHard(b.prototype,a.prototype)
a.prototype.constructor=a}function lazy(a,b,c,d){var s=a
a[b]=s
a[c]=function(){if(a[b]===s){a[b]=d()}a[c]=function(){return this[b]}
return a[b]}}function lazyFinal(a,b,c,d){var s=a
a[b]=s
a[c]=function(){if(a[b]===s){var r=d()
if(a[b]!==s){B.tw(b)}a[b]=r}var q=a[b]
a[c]=function(){return q}
return q}}function makeConstList(a,b){if(b!=null)B.m(a,b)
a.$flags=7
return a}function convertToFastObject(a){function t(){}t.prototype=a
new t()
return a}function convertAllToFastObject(a){for(var s=0;s<a.length;++s){convertToFastObject(a[s])}}var y=0
function instanceTearOffGetter(a,b){var s=null
return a?function(c){if(s===null)s=B.n8(b)
return new s(c,this)}:function(){if(s===null)s=B.n8(b)
return new s(this,null)}}function staticTearOffGetter(a){var s=null
return function(){if(s===null)s=B.n8(a).prototype
return s}}var x=0
function tearOffParameters(a,b,c,d,e,f,g,h,i,j){if(typeof h=="number"){h+=x}return{co:a,iS:b,iI:c,rC:d,dV:e,cs:f,fs:g,fT:h,aI:i||0,nDA:j}}function installStaticTearOff(a,b,c,d,e,f,g,h){var s=tearOffParameters(a,true,false,c,d,e,f,g,h,false)
var r=staticTearOffGetter(s)
a[b]=r}function installInstanceTearOff(a,b,c,d,e,f,g,h,i,j){c=!!c
var s=tearOffParameters(a,false,c,d,e,f,g,h,i,!!j)
var r=instanceTearOffGetter(c,s)
a[b]=r}function setOrUpdateInterceptorsByTag(a){var s=v.interceptorsByTag
if(!s){v.interceptorsByTag=a
return}copyProperties(a,s)}function setOrUpdateLeafTags(a){var s=v.leafTags
if(!s){v.leafTags=a
return}copyProperties(a,s)}function updateTypes(a){var s=v.types
var r=s.length
s.push.apply(s,a)
return r}function updateHolder(a,b){copyProperties(b,a)
return a}var hunkHelpers=function(){var s=function(a,b,c,d,e){return function(f,g,h,i){return installInstanceTearOff(f,g,a,b,c,d,[h],i,e,false)}},r=function(a,b,c,d){return function(e,f,g,h){return installStaticTearOff(e,f,a,b,c,[g],h,d)}}
return{inherit:inherit,inheritMany:inheritMany,mixin:mixinEasy,mixinHard:mixinHard,installStaticTearOff:installStaticTearOff,installInstanceTearOff:installInstanceTearOff,_instance_0u:s(0,0,null,["$0"],0),_instance_1u:s(0,1,null,["$1"],0),_instance_2u:s(0,2,null,["$2"],0),_instance_0i:s(1,0,null,["$0"],0),_instance_1i:s(1,1,null,["$1"],0),_instance_2i:s(1,2,null,["$2"],0),_static_0:r(0,null,["$0"],0),_static_1:r(1,null,["$1"],0),_static_2:r(2,null,["$2"],0),makeConstList:makeConstList,lazy:lazy,lazyFinal:lazyFinal,updateHolder:updateHolder,convertToFastObject:convertToFastObject,updateTypes:updateTypes,setOrUpdateInterceptorsByTag:setOrUpdateInterceptorsByTag,setOrUpdateLeafTags:setOrUpdateLeafTags}}()
function initializeDeferredHunk(a){x=v.types.length
a(hunkHelpers,v,w,$)}var J={
nc(a,b,c,d){return{i:a,p:b,e:c,x:d}},
m2(a){var s,r,q,p,o,n=a[v.dispatchPropertyName]
if(n==null)if($.na==null){B.tj()
n=a[v.dispatchPropertyName]}if(n!=null){s=n.p
if(!1===s)return n.i
if(!0===s)return a
r=Object.getPrototypeOf(a)
if(s===r)return n.i
if(n.e===r)throw B.f(B.nY("Return interceptor for "+B.z(s(a,n))))}q=a.constructor
if(q==null)p=null
else{o=$.lz
if(o==null)o=$.lz=v.getIsolateTag("_$dart_js")
p=q[o]}if(p!=null)return p
p=B.to(a)
if(p!=null)return p
if(typeof a=="function")return A.jA
s=Object.getPrototypeOf(a)
if(s==null)return A.cx
if(s===Object.prototype)return A.cx
if(typeof q=="function"){o=$.lz
if(o==null)o=$.lz=v.getIsolateTag("_$dart_js")
Object.defineProperty(q,o,{value:A.bD,enumerable:false,writable:true,configurable:true})
return A.bD}return A.bD},
nJ(a,b){if(a<0||a>4294967295)throw B.f(B.aN(a,0,4294967295,"length",null))
return J.q8(new Array(a),b)},
mJ(a,b){if(a<0)throw B.f(B.bR("Length must be a non-negative integer: "+a,null))
return B.m(new Array(a),b.i("v<0>"))},
mI(a,b){if(a<0)throw B.f(B.bR("Length must be a non-negative integer: "+a,null))
return B.m(new Array(a),b.i("v<0>"))},
q8(a,b){var s=B.m(a,b.i("v<0>"))
s.$flags=1
return s},
q9(a,b){var s=t.bP
return J.pa(s.a(a),s.a(b))},
nK(a){if(a<256)switch(a){case 9:case 10:case 11:case 12:case 13:case 32:case 133:case 160:return!0
default:return!1}switch(a){case 5760:case 8192:case 8193:case 8194:case 8195:case 8196:case 8197:case 8198:case 8199:case 8200:case 8201:case 8202:case 8232:case 8233:case 8239:case 8287:case 12288:case 65279:return!0
default:return!1}},
qa(a,b){var s,r
for(s=a.length;b<s;){r=a.charCodeAt(b)
if(r!==32&&r!==13&&!J.nK(r))break;++b}return b},
qb(a,b){var s,r,q
for(s=a.length;b>0;b=r){r=b-1
if(!(r<s))return B.b(a,r)
q=a.charCodeAt(r)
if(q!==32&&q!==13&&!J.nK(q))break}return b},
cD(a){if(typeof a=="number"){if(Math.floor(a)==a)return J.e8.prototype
return J.fk.prototype}if(typeof a=="string")return J.cS.prototype
if(a==null)return J.e9.prototype
if(typeof a=="boolean")return J.e7.prototype
if(Array.isArray(a))return J.v.prototype
if(typeof a!="object"){if(typeof a=="function")return J.bd.prototype
if(typeof a=="symbol")return J.dt.prototype
if(typeof a=="bigint")return J.ds.prototype
return a}if(a instanceof B.I)return a
return J.m2(a)},
bi(a){if(typeof a=="string")return J.cS.prototype
if(a==null)return a
if(Array.isArray(a))return J.v.prototype
if(typeof a!="object"){if(typeof a=="function")return J.bd.prototype
if(typeof a=="symbol")return J.dt.prototype
if(typeof a=="bigint")return J.ds.prototype
return a}if(a instanceof B.I)return a
return J.m2(a)},
aV(a){if(a==null)return a
if(Array.isArray(a))return J.v.prototype
if(typeof a!="object"){if(typeof a=="function")return J.bd.prototype
if(typeof a=="symbol")return J.dt.prototype
if(typeof a=="bigint")return J.ds.prototype
return a}if(a instanceof B.I)return a
return J.m2(a)},
td(a){if(typeof a=="number")return J.cR.prototype
if(a==null)return a
if(!(a instanceof B.I))return J.d2.prototype
return a},
te(a){if(typeof a=="number")return J.cR.prototype
if(typeof a=="string")return J.cS.prototype
if(a==null)return a
if(!(a instanceof B.I))return J.d2.prototype
return a},
n9(a){if(a==null)return a
if(typeof a!="object"){if(typeof a=="function")return J.bd.prototype
if(typeof a=="symbol")return J.dt.prototype
if(typeof a=="bigint")return J.ds.prototype
return a}if(a instanceof B.I)return a
return J.m2(a)},
F(a,b){if(a==null)return b==null
if(typeof a!="object")return b!=null&&a===b
return J.cD(a).ag(a,b)},
a2(a,b){if(typeof b==="number")if(Array.isArray(a)||typeof a=="string"||B.tm(a,a[v.dispatchPropertyName]))if(b>>>0===b&&b<a.length)return a[b]
return J.bi(a).h(a,b)},
cG(a,b,c){return J.aV(a).j(a,b,c)},
bN(a,b){return J.aV(a).n(a,b)},
p5(a,b){return J.aV(a).A(a,b)},
p6(a,b){return J.aV(a).N(a,b)},
mm(a){return J.n9(a).e0(a)},
p7(a,b,c){return J.n9(a).bW(a,b,c)},
p8(a){return J.n9(a).e1(a)},
p9(a,b,c){return J.td(a).t(a,b,c)},
pa(a,b){return J.te(a).Z(a,b)},
eR(a,b){return J.bi(a).p(a,b)},
eS(a,b){return J.aV(a).V(a,b)},
pb(a,b){return J.aV(a).aO(a,b)},
hc(a){return J.aV(a).gM(a)},
bA(a){return J.cD(a).gR(a)},
mn(a){return J.bi(a).gO(a)},
nj(a){return J.bi(a).ga8(a)},
at(a){return J.aV(a).gq(a)},
bB(a){return J.bi(a).gm(a)},
pc(a){return J.cD(a).ga2(a)},
pd(a,b,c){return J.aV(a).b6(a,b,c)},
hd(a,b){return J.aV(a).X(a,b)},
pe(a,b){return J.aV(a).a1(a,b)},
pf(a,b){return J.bi(a).sm(a,b)},
pg(a,b,c,d,e){return J.aV(a).aa(a,b,c,d,e)},
dR(a,b){return J.aV(a).ah(a,b)},
nk(a){return J.aV(a).aK(a)},
au(a){return J.cD(a).v(a)},
bO(a,b){return J.aV(a).dj(a,b)},
fi:function fi(){},
e7:function e7(){},
e9:function e9(){},
ag:function ag(){},
cr:function cr(){},
fA:function fA(){},
d2:function d2(){},
bd:function bd(){},
ds:function ds(){},
dt:function dt(){},
v:function v(a){this.$ti=a},
fj:function fj(){},
kO:function kO(a){this.$ti=a},
cJ:function cJ(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
cR:function cR(){},
e8:function e8(){},
fk:function fk(){},
cS:function cS(){}},B={mK:function mK(){},
hn(a,b,c){if(t.q.b(a))return new B.ew(a,b.i("@<0>").E(c).i("ew<1,2>"))
return new B.cK(a,b.i("@<0>").E(c).i("cK<1,2>"))},
qe(a){return new B.du("Field '"+a+"' has not been initialized.")},
qd(a){return new B.du("Field '"+a+"' has already been initialized.")},
cb(a,b){a=a+b&536870911
a=a+((a&524287)<<10)&536870911
return a^a>>>6},
lb(a){a=a+((a&67108863)<<3)&536870911
a^=a>>>11
return a+((a&16383)<<15)&536870911},
h6(a,b,c){return a},
nb(a){var s,r
for(s=$.bh.length,r=0;r<s;++r)if(a===$.bh[r])return!0
return!1},
fI(a,b,c,d){B.aO(b,"start")
if(c!=null){B.aO(c,"end")
if(b>c)B.aX(B.aN(b,0,c,"start",null))}return new B.d_(a,b,c,d.i("d_<0>"))},
bt(a,b,c,d){if(t.q.b(a))return new B.bc(a,b,c.i("@<0>").E(d).i("bc<1,2>"))
return new B.c0(a,b,c.i("@<0>").E(d).i("c0<1,2>"))},
b8(a,b,c){var s="takeCount"
B.df(b,s,t.S)
B.aO(b,s)
if(t.q.b(a))return new B.e_(a,b,c.i("e_<0>"))
return new B.d0(a,b,c.i("d0<0>"))},
mU(a,b,c){var s="count"
if(t.q.b(a)){B.df(b,s,t.S)
B.aO(b,s)
return new B.dm(a,b,c.i("dm<0>"))}B.df(b,s,t.S)
B.aO(b,s)
return new B.c7(a,b,c.i("c7<0>"))},
q3(a,b,c){return new B.dl(a,b,c.i("dl<0>"))},
bI(){return new B.dA("No element")},
nH(){return new B.dA("Too few elements")},
cz:function cz(){},
dT:function dT(a,b){this.a=a
this.$ti=b},
cK:function cK(a,b){this.a=a
this.$ti=b},
ew:function ew(a,b){this.a=a
this.$ti=b},
ev:function ev(){},
ln:function ln(a,b){this.a=a
this.b=b},
aB:function aB(a,b){this.a=a
this.$ti=b},
du:function du(a){this.a=a},
dV:function dV(a){this.a=a},
l7:function l7(){},
w:function w(){},
a4:function a4(){},
d_:function d_(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.$ti=d},
c_:function c_(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
c0:function c0(a,b,c){this.a=a
this.b=b
this.$ti=c},
bc:function bc(a,b,c){this.a=a
this.b=b
this.$ti=c},
c1:function c1(a,b,c){var _=this
_.a=null
_.b=a
_.c=b
_.$ti=c},
K:function K(a,b,c){this.a=a
this.b=b
this.$ti=c},
j:function j(a,b,c){this.a=a
this.b=b
this.$ti=c},
bx:function bx(a,b,c){this.a=a
this.b=b
this.$ti=c},
d0:function d0(a,b,c){this.a=a
this.b=b
this.$ti=c},
e_:function e_(a,b,c){this.a=a
this.b=b
this.$ti=c},
eq:function eq(a,b,c){this.a=a
this.b=b
this.$ti=c},
c7:function c7(a,b,c){this.a=a
this.b=b
this.$ti=c},
dm:function dm(a,b,c){this.a=a
this.b=b
this.$ti=c},
eo:function eo(a,b,c){this.a=a
this.b=b
this.$ti=c},
e0:function e0(a){this.$ti=a},
e1:function e1(a){this.$ti=a},
b_:function b_(a,b){this.a=a
this.$ti=b},
et:function et(a,b){this.a=a
this.$ti=b},
cQ:function cQ(a,b,c){this.a=a
this.b=b
this.$ti=c},
dl:function dl(a,b,c){this.a=a
this.b=b
this.$ti=c},
e5:function e5(a,b,c){var _=this
_.a=a
_.b=b
_.c=-1
_.$ti=c},
aa:function aa(){},
bM:function bM(){},
dC:function dC(){},
la:function la(){},
eN:function eN(){},
dX(a,b,c){var s,r,q,p,o,n,m,l=B.e(a),k=B.mO(new B.aJ(a,l.i("aJ<1>")),!0,b),j=k.length,i=0
for(;;){if(!(i<j)){s=!0
break}r=k[i]
if(typeof r!="string"||"__proto__"===r){s=!1
break}++i}if(s){q={}
for(p=0,i=0;i<k.length;k.length===j||(0,B.Z)(k),++i,p=o){r=k[i]
c.a(a.h(0,r))
o=p+1
q[r]=p}n=B.mO(new B.ai(a,l.i("ai<2>")),!0,c)
m=new B.u(q,n,b.i("@<0>").E(c).i("u<1,2>"))
m.$keys=k
return m}return new B.dW(B.aw(a,b,c),b.i("@<0>").E(c).i("dW<1,2>"))},
pu(){throw B.f(B.ax("Cannot modify unmodifiable Map"))},
mq(){throw B.f(B.ax("Cannot modify constant Set"))},
oH(a){var s=v.mangledGlobalNames[a]
if(s!=null)return s
return"minified:"+a},
tm(a,b){var s
if(b!=null){s=b.x
if(s!=null)return s}return t.dX.b(a)},
z(a){var s
if(typeof a=="string")return a
if(typeof a=="number"){if(a!==0)return""+a}else if(!0===a)return"true"
else if(!1===a)return"false"
else if(a==null)return"null"
s=J.au(a)
return s},
el(a){var s,r=$.nQ
if(r==null)r=$.nQ=Symbol("identityHashCode")
s=a[r]
if(s==null){s=Math.random()*0x3fffffff|0
a[r]=s}return s},
qo(a,b){var s,r,q,p,o,n=null,m=/^\s*[+-]?((0x[a-f0-9]+)|(\d+)|([a-z0-9]+))\s*$/i.exec(a)
if(m==null)return n
if(3>=m.length)return B.b(m,3)
s=m[3]
if(b==null){if(s!=null)return parseInt(a,10)
if(m[2]!=null)return parseInt(a,16)
return n}if(b<2||b>36)throw B.f(B.aN(b,2,36,"radix",n))
if(b===10&&s!=null)return parseInt(a,10)
if(b<10||s==null){r=b<=10?47+b:86+b
q=m[1]
for(p=q.length,o=0;o<p;++o)if((q.charCodeAt(o)|32)>r)return n}return parseInt(a,b)},
fC(a){var s,r,q,p
if(a instanceof B.I)return B.b1(B.aF(a),null)
s=J.cD(a)
if(s===A.jx||s===A.jB||t.cx.b(a)){r=A.bR(a)
if(r!=="Object"&&r!=="")return r
q=a.constructor
if(typeof q=="function"){p=q.name
if(typeof p=="string"&&p!=="Object"&&p!=="")return p}}return B.b1(B.aF(a),null)},
nU(a){var s,r,q
if(a==null||typeof a=="number"||B.a5(a))return J.au(a)
if(typeof a=="string")return JSON.stringify(a)
if(a instanceof B.cl)return a.v(0)
if(a instanceof B.by)return a.dV(!0)
s=$.oX()
for(r=0;r<1;++r){q=s[r].h3(a)
if(q!=null)return q}return"Instance of '"+B.fC(a)+"'"},
qp(a,b,c){var s,r,q,p
if(c<=500&&b===0&&c===a.length)return String.fromCharCode.apply(null,a)
for(s=b,r="";s<c;s=q){q=s+500
p=q<c?q:c
r+=String.fromCharCode.apply(null,a.subarray(s,p))}return r},
aM(a){var s
if(a<=65535)return String.fromCharCode(a)
if(a<=1114111){s=a-65536
return String.fromCharCode((A.a.cW(s,10)|55296)>>>0,s&1023|56320)}throw B.f(B.aN(a,0,1114111,null,null))},
mR(a,b,c,d,e,f,g,h,i){var s,r,q,p=b-1
if(0<=a&&a<100){a+=400
p-=4800}s=A.a.D(h,1000)
g+=A.a.G(h-s,1000)
r=i?Date.UTC(a,p,c,d,e,f,g):new Date(a,p,c,d,e,f,g).valueOf()
q=!0
if(!isNaN(r))if(!(r<-864e13))if(!(r>864e13))q=r===864e13&&s!==0
if(q)return null
return r},
aY(a){if(a.date===void 0)a.date=new Date(a.a)
return a.date},
aj(a){return a.c?B.aY(a).getUTCFullYear()+0:B.aY(a).getFullYear()+0},
aU(a){return a.c?B.aY(a).getUTCMonth()+1:B.aY(a).getMonth()+1},
aT(a){return a.c?B.aY(a).getUTCDate()+0:B.aY(a).getDate()+0},
dy(a){return a.c?B.aY(a).getUTCHours()+0:B.aY(a).getHours()+0},
fB(a){return a.c?B.aY(a).getUTCMinutes()+0:B.aY(a).getMinutes()+0},
nS(a){return a.c?B.aY(a).getUTCSeconds()+0:B.aY(a).getSeconds()+0},
nR(a){return a.c?B.aY(a).getUTCMilliseconds()+0:B.aY(a).getMilliseconds()+0},
nT(a){return A.a.D((a.c?B.aY(a).getUTCDay()+0:B.aY(a).getDay()+0)+6,7)+1},
qn(a){var s=a.$thrownJsError
if(s==null)return null
return B.dN(s)},
b(a,b){if(a==null)J.bB(a)
throw B.f(B.h8(a,b))},
h8(a,b){var s,r="index"
if(!B.cC(b))return new B.br(!0,b,r,null)
s=J.bB(a)
if(b<0||b>=s)return B.kM(b,s,a,r)
return B.mS(b,r)},
t4(a,b,c){if(a>c)return B.aN(a,0,c,"start",null)
if(b!=null)if(b<a||b>c)return B.aN(b,a,c,"end",null)
return new B.br(!0,b,"end",null)},
rV(a){return new B.br(!0,a,null,null)},
f(a){return B.as(a,new Error())},
as(a,b){var s
if(a==null)a=new B.cd()
b.dartException=a
s=B.tx
if("defineProperty" in Object){Object.defineProperty(b,"message",{get:s})
b.name=""}else b.toString=s
return b},
tx(){return J.au(this.dartException)},
aX(a,b){throw B.as(a,b==null?new Error():b)},
ae(a,b,c){var s
if(b==null)b=0
if(c==null)c=0
s=Error()
B.aX(B.r8(a,b,c),s)},
r8(a,b,c){var s,r,q,p,o,n,m,l,k
if(typeof b=="string")s=b
else{r="[]=;add;removeWhere;retainWhere;removeRange;setRange;setInt8;setInt16;setInt32;setUint8;setUint16;setUint32;setFloat32;setFloat64".split(";")
q=r.length
p=b
if(p>q){c=p/q|0
p%=q}s=r[p]}o=typeof c=="string"?c:"modify;remove from;add to".split(";")[c]
n=t.j.b(a)?"list":"ByteData"
m=a.$flags|0
l="a "
if((m&4)!==0)k="constant "
else if((m&2)!==0){k="unmodifiable "
l="an "}else k=(m&1)!==0?"fixed-length ":""
return new B.es("'"+s+"': Cannot "+o+" "+l+k+n)},
Z(a){throw B.f(B.af(a))},
ce(a){var s,r,q,p,o,n
a=B.tu(a.replace(String({}),"$receiver$"))
s=a.match(/\\\$[a-zA-Z]+\\\$/g)
if(s==null)s=B.m([],t.s)
r=s.indexOf("\\$arguments\\$")
q=s.indexOf("\\$argumentsExpr\\$")
p=s.indexOf("\\$expr\\$")
o=s.indexOf("\\$method\\$")
n=s.indexOf("\\$receiver\\$")
return new B.le(a.replace(new RegExp("\\\\\\$arguments\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$argumentsExpr\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$expr\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$method\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$receiver\\\\\\$","g"),"((?:x|[^x])*)"),r,q,p,o,n)},
lf(a){return function($expr$){var $argumentsExpr$="$arguments$"
try{$expr$.$method$($argumentsExpr$)}catch(s){return s.message}}(a)},
nX(a){return function($expr$){try{$expr$.$method$}catch(s){return s.message}}(a)},
mL(a,b){var s=b==null,r=s?null:b.method
return new B.fm(a,r,s?null:b.receiver)},
b9(a){var s
if(a==null)return new B.kW(a)
if(a instanceof B.e2){s=a.a
return B.cF(a,s==null?B.dJ(s):s)}if(typeof a!=="object")return a
if("dartException" in a)return B.cF(a,a.dartException)
return B.rS(a)},
cF(a,b){if(t.fz.b(b))if(b.$thrownJsError==null)b.$thrownJsError=a
return b},
rS(a){var s,r,q,p,o,n,m,l,k,j,i,h,g
if(!("message" in a))return a
s=a.message
if("number" in a&&typeof a.number=="number"){r=a.number
q=r&65535
if((A.a.cW(r,16)&8191)===10)switch(q){case 438:return B.cF(a,B.mL(B.z(s)+" (Error "+q+")",null))
case 445:case 5007:B.z(s)
return B.cF(a,new B.ek())}}if(a instanceof TypeError){p=$.oL()
o=$.oM()
n=$.oN()
m=$.oO()
l=$.oR()
k=$.oS()
j=$.oQ()
$.oP()
i=$.oU()
h=$.oT()
g=p.aA(s)
if(g!=null)return B.cF(a,B.mL(B.M(s),g))
else{g=o.aA(s)
if(g!=null){g.method="call"
return B.cF(a,B.mL(B.M(s),g))}else if(n.aA(s)!=null||m.aA(s)!=null||l.aA(s)!=null||k.aA(s)!=null||j.aA(s)!=null||m.aA(s)!=null||i.aA(s)!=null||h.aA(s)!=null){B.M(s)
return B.cF(a,new B.ek())}}return B.cF(a,new B.fL(typeof s=="string"?s:""))}if(a instanceof RangeError){if(typeof s=="string"&&s.indexOf("call stack")!==-1)return new B.ep()
s=function(b){try{return String(b)}catch(f){}return null}(a)
return B.cF(a,new B.br(!1,null,null,typeof s=="string"?s.replace(/^RangeError:\s*/,""):s))}if(typeof InternalError=="function"&&a instanceof InternalError)if(typeof s=="string"&&s==="too much recursion")return new B.ep()
return a},
dN(a){var s
if(a instanceof B.e2)return a.b
if(a==null)return new B.eG(a)
s=a.$cachedTrace
if(s!=null)return s
s=new B.eG(a)
if(typeof a==="object")a.$cachedTrace=s
return s},
nd(a){if(a==null)return J.bA(a)
if(typeof a=="object")return B.el(a)
return J.bA(a)},
t0(a){if(typeof a=="number")return A.c.gR(a)
if(a instanceof B.h3)return B.el(a)
if(a instanceof B.by)return a.gR(a)
if(a instanceof B.la)return a.gR(0)
return B.nd(a)},
oy(a,b){var s,r,q,p=a.length
for(s=0;s<p;s=q){r=s+1
q=r+1
b.j(0,a[s],a[r])}return b},
t9(a,b){var s,r=a.length
for(s=0;s<r;++s)b.n(0,a[s])
return b},
rk(a,b,c,d,e,f){t.w.a(a)
switch(B.r(b)){case 0:return a.$0()
case 1:return a.$1(c)
case 2:return a.$2(c,d)
case 3:return a.$3(c,d,e)
case 4:return a.$4(c,d,e,f)}throw B.f(new B.lo("Unsupported number of arguments for wrapped closure"))},
h7(a,b){var s=a.$identity
if(!!s)return s
s=B.t1(a,b)
a.$identity=s
return s},
t1(a,b){var s
switch(b){case 0:s=a.$0
break
case 1:s=a.$1
break
case 2:s=a.$2
break
case 3:s=a.$3
break
case 4:s=a.$4
break
default:s=null}if(s!=null)return s.bind(a)
return function(c,d,e){return function(f,g,h,i){return e(c,d,f,g,h,i)}}(a,b,B.rk)},
pt(a2){var s,r,q,p,o,n,m,l,k,j,i=a2.co,h=a2.iS,g=a2.iI,f=a2.nDA,e=a2.aI,d=a2.fs,c=a2.cs,b=d[0],a=c[0],a0=i[b],a1=a2.fT
a1.toString
s=h?Object.create(new B.fH().constructor.prototype):Object.create(new B.dg(null,null).constructor.prototype)
s.$initialize=s.constructor
r=h?function static_tear_off(){this.$initialize()}:function tear_off(a3,a4){this.$initialize(a3,a4)}
s.constructor=r
r.prototype=s
s.$_name=b
s.$_target=a0
q=!h
if(q)p=B.nr(b,a0,g,f)
else{s.$static_name=b
p=a0}s.$S=B.pp(a1,h,g)
s[a]=p
for(o=p,n=1;n<d.length;++n){m=d[n]
if(typeof m=="string"){l=i[m]
k=m
m=l}else k=""
j=c[n]
if(j!=null){if(q)m=B.nr(k,m,g,f)
s[j]=m}if(n===e)o=m}s.$C=o
s.$R=a2.rC
s.$D=a2.dV
return r},
pp(a,b,c){if(typeof a=="number")return a
if(typeof a=="string"){if(b)throw B.f("Cannot compute signature for static tearoff.")
return function(d,e){return function(){return e(this,d)}}(a,B.pm)}throw B.f("Error in functionType of tearoff")},
pq(a,b,c,d){var s=B.np
switch(b?-1:a){case 0:return function(e,f){return function(){return f(this)[e]()}}(c,s)
case 1:return function(e,f){return function(g){return f(this)[e](g)}}(c,s)
case 2:return function(e,f){return function(g,h){return f(this)[e](g,h)}}(c,s)
case 3:return function(e,f){return function(g,h,i){return f(this)[e](g,h,i)}}(c,s)
case 4:return function(e,f){return function(g,h,i,j){return f(this)[e](g,h,i,j)}}(c,s)
case 5:return function(e,f){return function(g,h,i,j,k){return f(this)[e](g,h,i,j,k)}}(c,s)
default:return function(e,f){return function(){return e.apply(f(this),arguments)}}(d,s)}},
nr(a,b,c,d){if(c)return B.ps(a,b,d)
return B.pq(b.length,d,a,b)},
pr(a,b,c,d){var s=B.np,r=B.pn
switch(b?-1:a){case 0:throw B.f(new B.fG("Intercepted function with no arguments."))
case 1:return function(e,f,g){return function(){return f(this)[e](g(this))}}(c,r,s)
case 2:return function(e,f,g){return function(h){return f(this)[e](g(this),h)}}(c,r,s)
case 3:return function(e,f,g){return function(h,i){return f(this)[e](g(this),h,i)}}(c,r,s)
case 4:return function(e,f,g){return function(h,i,j){return f(this)[e](g(this),h,i,j)}}(c,r,s)
case 5:return function(e,f,g){return function(h,i,j,k){return f(this)[e](g(this),h,i,j,k)}}(c,r,s)
case 6:return function(e,f,g){return function(h,i,j,k,l){return f(this)[e](g(this),h,i,j,k,l)}}(c,r,s)
default:return function(e,f,g){return function(){var q=[g(this)]
Array.prototype.push.apply(q,arguments)
return e.apply(f(this),q)}}(d,r,s)}},
ps(a,b,c){var s,r
if($.nn==null)$.nn=B.nm("interceptor")
if($.no==null)$.no=B.nm("receiver")
s=b.length
r=B.pr(s,c,a,b)
return r},
n8(a){return B.pt(a)},
pm(a,b){return B.eK(v.typeUniverse,B.aF(a.a),b)},
np(a){return a.a},
pn(a){return a.b},
nm(a){var s,r,q,p=new B.dg("receiver","interceptor"),o=Object.getOwnPropertyNames(p)
o.$flags=1
s=o
for(o=s.length,r=0;r<o;++r){q=s[r]
if(p[q]===a)return q}throw B.f(B.bR("Field name "+a+" not found.",null))},
oz(a){return v.getIsolateTag(a)},
ub(a,b,c){Object.defineProperty(a,b,{value:c,enumerable:false,writable:true,configurable:true})},
to(a){var s,r,q,p,o,n=B.M($.oA.$1(a)),m=$.lY[n]
if(m!=null){Object.defineProperty(a,v.dispatchPropertyName,{value:m,enumerable:false,writable:true,configurable:true})
return m.i}s=$.m6[n]
if(s!=null)return s
r=v.interceptorsByTag[n]
if(r==null){q=B.b0($.ot.$2(a,n))
if(q!=null){m=$.lY[q]
if(m!=null){Object.defineProperty(a,v.dispatchPropertyName,{value:m,enumerable:false,writable:true,configurable:true})
return m.i}s=$.m6[q]
if(s!=null)return s
r=v.interceptorsByTag[q]
n=q}}if(r==null)return null
s=r.prototype
p=n[0]
if(p==="!"){m=B.ma(s)
$.lY[n]=m
Object.defineProperty(a,v.dispatchPropertyName,{value:m,enumerable:false,writable:true,configurable:true})
return m.i}if(p==="~"){$.m6[n]=s
return s}if(p==="-"){o=B.ma(s)
Object.defineProperty(Object.getPrototypeOf(a),v.dispatchPropertyName,{value:o,enumerable:false,writable:true,configurable:true})
return o.i}if(p==="+")return B.oC(a,s)
if(p==="*")throw B.f(B.nY(n))
if(v.leafTags[n]===true){o=B.ma(s)
Object.defineProperty(Object.getPrototypeOf(a),v.dispatchPropertyName,{value:o,enumerable:false,writable:true,configurable:true})
return o.i}else return B.oC(a,s)},
oC(a,b){var s=Object.getPrototypeOf(a)
Object.defineProperty(s,v.dispatchPropertyName,{value:J.nc(b,s,null,null),enumerable:false,writable:true,configurable:true})
return b},
ma(a){return J.nc(a,!1,null,!!a.$ibe)},
tq(a,b,c){var s=b.prototype
if(v.leafTags[a]===true)return B.ma(s)
else return J.nc(s,c,null,null)},
tj(){if(!0===$.na)return
$.na=!0
B.tk()},
tk(){var s,r,q,p,o,n,m,l
$.lY=Object.create(null)
$.m6=Object.create(null)
B.ti()
s=v.interceptorsByTag
r=Object.getOwnPropertyNames(s)
if(typeof window!="undefined"){window
q=function(){}
for(p=0;p<r.length;++p){o=r[p]
n=$.oE.$1(o)
if(n!=null){m=B.tq(o,s[o],n)
if(m!=null){Object.defineProperty(n,v.dispatchPropertyName,{value:m,enumerable:false,writable:true,configurable:true})
q.prototype=n}}}}for(p=0;p<r.length;++p){o=r[p]
if(/^[A-Za-z_]/.test(o)){l=s[o]
s["!"+o]=l
s["~"+o]=l
s["-"+o]=l
s["+"+o]=l
s["*"+o]=l}}},
ti(){var s,r,q,p,o,n,m=A.dV()
m=B.dM(A.dW,B.dM(A.dX,B.dM(A.bQ,B.dM(A.bQ,B.dM(A.dY,B.dM(A.dZ,B.dM(A.e_(A.bR),m)))))))
if(typeof dartNativeDispatchHooksTransformer!="undefined"){s=dartNativeDispatchHooksTransformer
if(typeof s=="function")s=[s]
if(Array.isArray(s))for(r=0;r<s.length;++r){q=s[r]
if(typeof q=="function")m=q(m)||m}}p=m.getTag
o=m.getUnknownTag
n=m.prototypeForTag
$.oA=new B.m3(p)
$.ot=new B.m4(o)
$.oE=new B.m5(n)},
dM(a,b){return a(b)||b},
t3(a,b){var s=b.length,r=v.rttc[""+s+";"+a]
if(r==null)return null
if(s===0)return r
if(s===r.length)return r.apply(null,b)
return r(b)},
qc(a,b,c,d,e,f){var s=b?"m":"",r=c?"":"i",q=d?"u":"",p=e?"s":"",o=function(g,h){try{return new RegExp(g,h)}catch(n){return n}}(a,s+r+q+p+f)
if(o instanceof RegExp)return o
throw B.f(B.dp("Illegal RegExp pattern ("+String(o)+")",a))},
tv(a,b,c){var s=a.indexOf(b,c)
return s>=0},
tu(a){if(/[[\]{}()*+?.\\^$|]/.test(a))return a.replace(/[[\]{}()*+?.\\^$|]/g,"\\$&")
return a},
p:function p(a,b){this.a=a
this.b=b},
J:function J(a,b){this.a=a
this.b=b},
eE:function eE(a,b,c){this.a=a
this.b=b
this.c=c},
dW:function dW(a,b){this.a=a
this.$ti=b},
di:function di(){},
ho:function ho(a,b,c){this.a=a
this.b=b
this.c=c},
u:function u(a,b,c){this.a=a
this.b=b
this.$ti=c},
d4:function d4(a,b){this.a=a
this.$ti=b},
d5:function d5(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
b7:function b7(a,b){this.a=a
this.$ti=b},
dY:function dY(){},
T:function T(a,b,c){this.a=a
this.b=b
this.$ti=c},
em:function em(){},
le:function le(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
ek:function ek(){},
fm:function fm(a,b,c){this.a=a
this.b=b
this.c=c},
fL:function fL(a){this.a=a},
kW:function kW(a){this.a=a},
e2:function e2(a,b){this.a=a
this.b=b},
eG:function eG(a){this.a=a
this.b=null},
cl:function cl(){},
eX:function eX(){},
eY:function eY(){},
fJ:function fJ(){},
fH:function fH(){},
dg:function dg(a,b){this.a=a
this.b=b},
fG:function fG(a){this.a=a},
bl:function bl(a){var _=this
_.a=0
_.f=_.e=_.d=_.c=_.b=null
_.r=0
_.$ti=a},
kP:function kP(a){this.a=a},
kQ:function kQ(a,b){var _=this
_.a=a
_.b=b
_.d=_.c=null},
aJ:function aJ(a,b){this.a=a
this.$ti=b},
ed:function ed(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.$ti=d},
ai:function ai(a,b){this.a=a
this.$ti=b},
ee:function ee(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.$ti=d},
y:function y(a,b){this.a=a
this.$ti=b},
ec:function ec(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.$ti=d},
ea:function ea(a){var _=this
_.a=0
_.f=_.e=_.d=_.c=_.b=null
_.r=0
_.$ti=a},
m3:function m3(a){this.a=a},
m4:function m4(a){this.a=a},
m5:function m5(a){this.a=a},
by:function by(){},
d7:function d7(){},
dE:function dE(){},
fl:function fl(a,b){var _=this
_.a=a
_.b=b
_.e=_.d=_.c=null},
lF:function lF(a){this.b=a},
lR(a,b,c){},
oi(a){return a},
qh(a,b,c){var s
B.lR(a,b,c)
s=new DataView(a,b)
return s},
qi(a,b,c){B.lR(a,b,c)
return c==null?new Uint8Array(a,b):new Uint8Array(a,b,c)},
ch(a,b,c){if(a>>>0!==a||a>=c)throw B.f(B.h8(b,a))},
r4(a,b,c){var s
if(!(a>>>0!==a))s=b>>>0!==b||a>b||b>c
else s=!0
if(s)throw B.f(B.t4(a,b,c))
return b},
cW:function cW(){},
ef:function ef(){},
lK:function lK(a){this.a=a},
fs:function fs(){},
aK:function aK(){},
cu:function cu(){},
bf:function bf(){},
ft:function ft(){},
fu:function fu(){},
fv:function fv(){},
fw:function fw(){},
fx:function fx(){},
eg:function eg(){},
eh:function eh(){},
ei:function ei(){},
ej:function ej(){},
eA:function eA(){},
eB:function eB(){},
eC:function eC(){},
eD:function eD(){},
mT(a,b){var s=b.c
return s==null?b.c=B.eI(a,"cO",[b.x]):s},
nV(a){var s=a.w
if(s===6||s===7)return B.nV(a.x)
return s===11||s===12},
qr(a){return a.as},
W(a){return B.lJ(v.typeUniverse,a,!1)},
d9(a1,a2,a3,a4){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0=a2.w
switch(a0){case 5:case 1:case 2:case 3:case 4:return a2
case 6:s=a2.x
r=B.d9(a1,s,a3,a4)
if(r===s)return a2
return B.o9(a1,r,!0)
case 7:s=a2.x
r=B.d9(a1,s,a3,a4)
if(r===s)return a2
return B.o8(a1,r,!0)
case 8:q=a2.y
p=B.dL(a1,q,a3,a4)
if(p===q)return a2
return B.eI(a1,a2.x,p)
case 9:o=a2.x
n=B.d9(a1,o,a3,a4)
m=a2.y
l=B.dL(a1,m,a3,a4)
if(n===o&&l===m)return a2
return B.n_(a1,n,l)
case 10:k=a2.x
j=a2.y
i=B.dL(a1,j,a3,a4)
if(i===j)return a2
return B.oa(a1,k,i)
case 11:h=a2.x
g=B.d9(a1,h,a3,a4)
f=a2.y
e=B.rO(a1,f,a3,a4)
if(g===h&&e===f)return a2
return B.o7(a1,g,e)
case 12:d=a2.y
a4+=d.length
c=B.dL(a1,d,a3,a4)
o=a2.x
n=B.d9(a1,o,a3,a4)
if(c===d&&n===o)return a2
return B.n0(a1,n,c,!0)
case 13:b=a2.x
if(b<a4)return a2
a=a3[b-a4]
if(a==null)return a2
return a
default:throw B.f(B.eV("Attempted to substitute unexpected RTI kind "+a0))}},
dL(a,b,c,d){var s,r,q,p,o=b.length,n=B.lM(o)
for(s=!1,r=0;r<o;++r){q=b[r]
p=B.d9(a,q,c,d)
if(p!==q)s=!0
n[r]=p}return s?n:b},
rP(a,b,c,d){var s,r,q,p,o,n,m=b.length,l=B.lM(m)
for(s=!1,r=0;r<m;r+=3){q=b[r]
p=b[r+1]
o=b[r+2]
n=B.d9(a,o,c,d)
if(n!==o)s=!0
l.splice(r,3,q,p,n)}return s?l:b},
rO(a,b,c,d){var s,r=b.a,q=B.dL(a,r,c,d),p=b.b,o=B.dL(a,p,c,d),n=b.c,m=B.rP(a,n,c,d)
if(q===r&&o===p&&m===n)return b
s=new B.fR()
s.a=q
s.b=o
s.c=m
return s},
m(a,b){a[v.arrayRti]=b
return a},
ov(a){var s=a.$S
if(s!=null){if(typeof s=="number")return B.tg(s)
return a.$S()}return null},
tl(a,b){var s
if(B.nV(b))if(a instanceof B.cl){s=B.ov(a)
if(s!=null)return s}return B.aF(a)},
aF(a){if(a instanceof B.I)return B.e(a)
if(Array.isArray(a))return B.q(a)
return B.n3(J.cD(a))},
q(a){var s=a[v.arrayRti],r=t.dG
if(s==null)return r
if(s.constructor!==r.constructor)return r
return s},
e(a){var s=a.$ti
return s!=null?s:B.n3(a)},
n3(a){var s=a.constructor,r=s.$ccache
if(r!=null)return r
return B.rh(a,s)},
rh(a,b){var s=a instanceof B.cl?Object.getPrototypeOf(Object.getPrototypeOf(a)).constructor:b,r=B.qW(v.typeUniverse,s.name)
b.$ccache=r
return r},
tg(a){var s,r=v.types,q=r[a]
if(typeof q=="string"){s=B.lJ(v.typeUniverse,q,!1)
r[a]=s
return s}return q},
tf(a){return B.da(B.e(a))},
n6(a){var s
if(a instanceof B.by)return B.t7(a.$r,a.cN())
s=a instanceof B.cl?B.ov(a):null
if(s!=null)return s
if(t.aJ.b(a))return J.pc(a).a
if(Array.isArray(a))return B.q(a)
return B.aF(a)},
da(a){var s=a.r
return s==null?a.r=new B.h3(a):s},
t7(a,b){var s,r,q=b,p=q.length
if(p===0)return t.aK
if(0>=p)return B.b(q,0)
s=B.eK(v.typeUniverse,B.n6(q[0]),"@<0>")
for(r=1;r<p;++r){if(!(r<q.length))return B.b(q,r)
s=B.ob(v.typeUniverse,s,B.n6(q[r]))}return B.eK(v.typeUniverse,s,a)},
bz(a){return B.da(B.lJ(v.typeUniverse,a,!1))},
rg(a){var s=this
s.b=B.rM(s)
return s.b(a)},
rM(a){var s,r,q,p,o
if(a===t.K)return B.rq
if(B.dc(a))return B.ru
s=a.w
if(s===6)return B.rc
if(s===1)return B.oo
if(s===7)return B.rl
r=B.rL(a)
if(r!=null)return r
if(s===8){q=a.x
if(a.y.every(B.dc)){a.f="$i"+q
if(q==="G")return B.ro
if(a===t.B)return B.rn
return B.rt}}else if(s===10){p=B.t3(a.x,a.y)
o=p==null?B.oo:p
return o==null?B.dJ(o):o}return B.ra},
rL(a){if(a.w===8){if(a===t.S)return B.cC
if(a===t.i||a===t.cZ)return B.rp
if(a===t.N)return B.rs
if(a===t.y)return B.a5}return null},
rf(a){var s=this,r=B.r9
if(B.dc(s))r=B.r0
else if(s===t.K)r=B.dJ
else if(B.dO(s)){r=B.rb
if(s===t.aV)r=B.og
else if(s===t.jv)r=B.b0
else if(s===t.fU)r=B.qY
else if(s===t.jh)r=B.dI
else if(s===t.jX)r=B.qZ
else if(s===t.cV)r=B.r_}else if(s===t.S)r=B.r
else if(s===t.N)r=B.M
else if(s===t.y)r=B.ab
else if(s===t.cZ)r=B.h4
else if(s===t.i)r=B.of
else if(s===t.B)r=B.oh
s.a=r
return s.a(a)},
ra(a){var s=this
if(a==null)return B.dO(s)
return B.oB(v.typeUniverse,B.tl(a,s),s)},
rc(a){if(a==null)return!0
return this.x.b(a)},
rt(a){var s,r=this
if(a==null)return B.dO(r)
s=r.f
if(a instanceof B.I)return!!a[s]
return!!J.cD(a)[s]},
ro(a){var s,r=this
if(a==null)return B.dO(r)
if(typeof a!="object")return!1
if(Array.isArray(a))return!0
s=r.f
if(a instanceof B.I)return!!a[s]
return!!J.cD(a)[s]},
rn(a){var s=this
if(a==null)return!1
if(typeof a=="object"){if(a instanceof B.I)return!!a[s.f]
return!0}if(typeof a=="function")return!0
return!1},
on(a){if(typeof a=="object"){if(a instanceof B.I)return t.B.b(a)
return!0}if(typeof a=="function")return!0
return!1},
r9(a){var s=this
if(a==null){if(B.dO(s))return a}else if(s.b(a))return a
throw B.as(B.oj(a,s),new Error())},
rb(a){var s=this
if(a==null||s.b(a))return a
throw B.as(B.oj(a,s),new Error())},
oj(a,b){return new B.dF("TypeError: "+B.o0(a,B.b1(b,null)))},
t_(a,b,c,d){if(B.oB(v.typeUniverse,a,b))return a
throw B.as(B.qO("The type argument '"+B.b1(a,null)+"' is not a subtype of the type variable bound '"+B.b1(b,null)+"' of type variable '"+c+"' in '"+d+"'."),new Error())},
o0(a,b){return B.fb(a)+": type '"+B.b1(B.n6(a),null)+"' is not a subtype of type '"+b+"'"},
qO(a){return new B.dF("TypeError: "+a)},
bo(a,b){return new B.dF("TypeError: "+B.o0(a,b))},
rl(a){var s=this
return s.x.b(a)||B.mT(v.typeUniverse,s).b(a)},
rq(a){return a!=null},
dJ(a){if(a!=null)return a
throw B.as(B.bo(a,"Object"),new Error())},
ru(a){return!0},
r0(a){return a},
oo(a){return!1},
a5(a){return!0===a||!1===a},
ab(a){if(!0===a)return!0
if(!1===a)return!1
throw B.as(B.bo(a,"bool"),new Error())},
qY(a){if(!0===a)return!0
if(!1===a)return!1
if(a==null)return a
throw B.as(B.bo(a,"bool?"),new Error())},
of(a){if(typeof a=="number")return a
throw B.as(B.bo(a,"double"),new Error())},
qZ(a){if(typeof a=="number")return a
if(a==null)return a
throw B.as(B.bo(a,"double?"),new Error())},
cC(a){return typeof a=="number"&&Math.floor(a)===a},
r(a){if(typeof a=="number"&&Math.floor(a)===a)return a
throw B.as(B.bo(a,"int"),new Error())},
og(a){if(typeof a=="number"&&Math.floor(a)===a)return a
if(a==null)return a
throw B.as(B.bo(a,"int?"),new Error())},
rp(a){return typeof a=="number"},
h4(a){if(typeof a=="number")return a
throw B.as(B.bo(a,"num"),new Error())},
dI(a){if(typeof a=="number")return a
if(a==null)return a
throw B.as(B.bo(a,"num?"),new Error())},
rs(a){return typeof a=="string"},
M(a){if(typeof a=="string")return a
throw B.as(B.bo(a,"String"),new Error())},
b0(a){if(typeof a=="string")return a
if(a==null)return a
throw B.as(B.bo(a,"String?"),new Error())},
oh(a){if(B.on(a))return a
throw B.as(B.bo(a,"JSObject"),new Error())},
r_(a){if(a==null)return a
if(B.on(a))return a
throw B.as(B.bo(a,"JSObject?"),new Error())},
or(a,b){var s,r,q
for(s="",r="",q=0;q<a.length;++q,r=", ")s+=r+B.b1(a[q],b)
return s},
rG(a,b){var s,r,q,p,o,n,m=a.x,l=a.y
if(""===m)return"("+B.or(l,b)+")"
s=l.length
r=m.split(",")
q=r.length-s
for(p="(",o="",n=0;n<s;++n,o=", "){p+=o
if(q===0)p+="{"
p+=B.b1(l[n],b)
if(q>=0)p+=" "+r[q];++q}return p+"})"},
ok(a3,a4,a5){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1=", ",a2=null
if(a5!=null){s=a5.length
if(a4==null)a4=B.m([],t.s)
else a2=a4.length
r=a4.length
for(q=s;q>0;--q)A.b.n(a4,"T"+(r+q))
for(p=t.X,o="<",n="",q=0;q<s;++q,n=a1){m=a4.length
l=m-1-q
if(!(l>=0))return B.b(a4,l)
o=o+n+a4[l]
k=a5[q]
j=k.w
if(!(j===2||j===3||j===4||j===5||k===p))o+=" extends "+B.b1(k,a4)}o+=">"}else o=""
p=a3.x
i=a3.y
h=i.a
g=h.length
f=i.b
e=f.length
d=i.c
c=d.length
b=B.b1(p,a4)
for(a="",a0="",q=0;q<g;++q,a0=a1)a+=a0+B.b1(h[q],a4)
if(e>0){a+=a0+"["
for(a0="",q=0;q<e;++q,a0=a1)a+=a0+B.b1(f[q],a4)
a+="]"}if(c>0){a+=a0+"{"
for(a0="",q=0;q<c;q+=3,a0=a1){a+=a0
if(d[q+1])a+="required "
a+=B.b1(d[q+2],a4)+" "+d[q]}a+="}"}if(a2!=null){a4.toString
a4.length=a2}return o+"("+a+") => "+b},
b1(a,b){var s,r,q,p,o,n,m,l=a.w
if(l===5)return"erased"
if(l===2)return"dynamic"
if(l===3)return"void"
if(l===1)return"Never"
if(l===4)return"any"
if(l===6){s=a.x
r=B.b1(s,b)
q=s.w
return(q===11||q===12?"("+r+")":r)+"?"}if(l===7)return"FutureOr<"+B.b1(a.x,b)+">"
if(l===8){p=B.rR(a.x)
o=a.y
return o.length>0?p+("<"+B.or(o,b)+">"):p}if(l===10)return B.rG(a,b)
if(l===11)return B.ok(a,b,null)
if(l===12)return B.ok(a.x,b,a.y)
if(l===13){n=a.x
m=b.length
n=m-1-n
if(!(n>=0&&n<m))return B.b(b,n)
return b[n]}return"?"},
rR(a){var s=v.mangledGlobalNames[a]
if(s!=null)return s
return"minified:"+a},
qX(a,b){var s=a.tR[b]
while(typeof s=="string")s=a.tR[s]
return s},
qW(a,b){var s,r,q,p,o,n=a.eT,m=n[b]
if(m==null)return B.lJ(a,b,!1)
else if(typeof m=="number"){s=m
r=B.eJ(a,5,"#")
q=B.lM(s)
for(p=0;p<s;++p)q[p]=r
o=B.eI(a,b,q)
n[b]=o
return o}else return m},
qV(a,b){return B.oc(a.tR,b)},
qU(a,b){return B.oc(a.eT,b)},
lJ(a,b,c){var s,r=a.eC,q=r.get(b)
if(q!=null)return q
s=B.o4(B.o2(a,null,b,!1))
r.set(b,s)
return s},
eK(a,b,c){var s,r,q=b.z
if(q==null)q=b.z=new Map()
s=q.get(c)
if(s!=null)return s
r=B.o4(B.o2(a,b,c,!0))
q.set(c,r)
return r},
ob(a,b,c){var s,r,q,p=b.Q
if(p==null)p=b.Q=new Map()
s=c.as
r=p.get(s)
if(r!=null)return r
q=B.n_(a,b,c.w===9?c.y:[c])
p.set(s,q)
return q},
cB(a,b){b.a=B.rf
b.b=B.rg
return b},
eJ(a,b,c){var s,r,q=a.eC.get(c)
if(q!=null)return q
s=new B.bu(null,null)
s.w=b
s.as=c
r=B.cB(a,s)
a.eC.set(c,r)
return r},
o9(a,b,c){var s,r=b.as+"?",q=a.eC.get(r)
if(q!=null)return q
s=B.qS(a,b,r,c)
a.eC.set(r,s)
return s},
qS(a,b,c,d){var s,r,q
if(d){s=b.w
r=!0
if(!B.dc(b))if(!(b===t.b||b===t.v))if(s!==6)r=s===7&&B.dO(b.x)
if(r)return b
else if(s===1)return t.b}q=new B.bu(null,null)
q.w=6
q.x=b
q.as=c
return B.cB(a,q)},
o8(a,b,c){var s,r=b.as+"/",q=a.eC.get(r)
if(q!=null)return q
s=B.qQ(a,b,r,c)
a.eC.set(r,s)
return s},
qQ(a,b,c,d){var s,r
if(d){s=b.w
if(B.dc(b)||b===t.K)return b
else if(s===1)return B.eI(a,"cO",[b])
else if(b===t.b||b===t.v)return t.gK}r=new B.bu(null,null)
r.w=7
r.x=b
r.as=c
return B.cB(a,r)},
qT(a,b){var s,r,q=""+b+"^",p=a.eC.get(q)
if(p!=null)return p
s=new B.bu(null,null)
s.w=13
s.x=b
s.as=q
r=B.cB(a,s)
a.eC.set(q,r)
return r},
eH(a){var s,r,q,p=a.length
for(s="",r="",q=0;q<p;++q,r=",")s+=r+a[q].as
return s},
qP(a){var s,r,q,p,o,n=a.length
for(s="",r="",q=0;q<n;q+=3,r=","){p=a[q]
o=a[q+1]?"!":":"
s+=r+p+o+a[q+2].as}return s},
eI(a,b,c){var s,r,q,p=b
if(c.length>0)p+="<"+B.eH(c)+">"
s=a.eC.get(p)
if(s!=null)return s
r=new B.bu(null,null)
r.w=8
r.x=b
r.y=c
if(c.length>0)r.c=c[0]
r.as=p
q=B.cB(a,r)
a.eC.set(p,q)
return q},
n_(a,b,c){var s,r,q,p,o,n
if(b.w===9){s=b.x
r=b.y.concat(c)}else{r=c
s=b}q=s.as+(";<"+B.eH(r)+">")
p=a.eC.get(q)
if(p!=null)return p
o=new B.bu(null,null)
o.w=9
o.x=s
o.y=r
o.as=q
n=B.cB(a,o)
a.eC.set(q,n)
return n},
oa(a,b,c){var s,r,q="+"+(b+"("+B.eH(c)+")"),p=a.eC.get(q)
if(p!=null)return p
s=new B.bu(null,null)
s.w=10
s.x=b
s.y=c
s.as=q
r=B.cB(a,s)
a.eC.set(q,r)
return r},
o7(a,b,c){var s,r,q,p,o,n=b.as,m=c.a,l=m.length,k=c.b,j=k.length,i=c.c,h=i.length,g="("+B.eH(m)
if(j>0){s=l>0?",":""
g+=s+"["+B.eH(k)+"]"}if(h>0){s=l>0?",":""
g+=s+"{"+B.qP(i)+"}"}r=n+(g+")")
q=a.eC.get(r)
if(q!=null)return q
p=new B.bu(null,null)
p.w=11
p.x=b
p.y=c
p.as=r
o=B.cB(a,p)
a.eC.set(r,o)
return o},
n0(a,b,c,d){var s,r=b.as+("<"+B.eH(c)+">"),q=a.eC.get(r)
if(q!=null)return q
s=B.qR(a,b,c,r,d)
a.eC.set(r,s)
return s},
qR(a,b,c,d,e){var s,r,q,p,o,n,m,l
if(e){s=c.length
r=B.lM(s)
for(q=0,p=0;p<s;++p){o=c[p]
if(o.w===1){r[p]=o;++q}}if(q>0){n=B.d9(a,b,r,0)
m=B.dL(a,c,r,0)
return B.n0(a,n,m,c!==m)}}l=new B.bu(null,null)
l.w=12
l.x=b
l.y=c
l.as=d
return B.cB(a,l)},
o2(a,b,c,d){return{u:a,e:b,r:c,s:[],p:0,n:d}},
o4(a){var s,r,q,p,o,n,m,l=a.r,k=a.s
for(s=l.length,r=0;r<s;){q=l.charCodeAt(r)
if(q>=48&&q<=57)r=B.qI(r+1,q,l,k)
else if((((q|32)>>>0)-97&65535)<26||q===95||q===36||q===124)r=B.o3(a,r,l,k,!1)
else if(q===46)r=B.o3(a,r,l,k,!0)
else{++r
switch(q){case 44:break
case 58:k.push(!1)
break
case 33:k.push(!0)
break
case 59:k.push(B.d6(a.u,a.e,k.pop()))
break
case 94:k.push(B.qT(a.u,k.pop()))
break
case 35:k.push(B.eJ(a.u,5,"#"))
break
case 64:k.push(B.eJ(a.u,2,"@"))
break
case 126:k.push(B.eJ(a.u,3,"~"))
break
case 60:k.push(a.p)
a.p=k.length
break
case 62:B.qK(a,k)
break
case 38:B.qJ(a,k)
break
case 63:p=a.u
k.push(B.o9(p,B.d6(p,a.e,k.pop()),a.n))
break
case 47:p=a.u
k.push(B.o8(p,B.d6(p,a.e,k.pop()),a.n))
break
case 40:k.push(-3)
k.push(a.p)
a.p=k.length
break
case 41:B.qH(a,k)
break
case 91:k.push(a.p)
a.p=k.length
break
case 93:o=k.splice(a.p)
B.o5(a.u,a.e,o)
a.p=k.pop()
k.push(o)
k.push(-1)
break
case 123:k.push(a.p)
a.p=k.length
break
case 125:o=k.splice(a.p)
B.qM(a.u,a.e,o)
a.p=k.pop()
k.push(o)
k.push(-2)
break
case 43:n=l.indexOf("(",r)
k.push(l.substring(r,n))
k.push(-4)
k.push(a.p)
a.p=k.length
r=n+1
break
default:throw"Bad character "+q}}}m=k.pop()
return B.d6(a.u,a.e,m)},
qI(a,b,c,d){var s,r,q=b-48
for(s=c.length;a<s;++a){r=c.charCodeAt(a)
if(!(r>=48&&r<=57))break
q=q*10+(r-48)}d.push(q)
return a},
o3(a,b,c,d,e){var s,r,q,p,o,n,m=b+1
for(s=c.length;m<s;++m){r=c.charCodeAt(m)
if(r===46){if(e)break
e=!0}else{if(!((((r|32)>>>0)-97&65535)<26||r===95||r===36||r===124))q=r>=48&&r<=57
else q=!0
if(!q)break}}p=c.substring(b,m)
if(e){s=a.u
o=a.e
if(o.w===9)o=o.x
n=B.qX(s,o.x)[p]
if(n==null)B.aX('No "'+p+'" in "'+B.qr(o)+'"')
d.push(B.eK(s,o,n))}else d.push(p)
return m},
qK(a,b){var s,r=a.u,q=B.o1(a,b),p=b.pop()
if(typeof p=="string")b.push(B.eI(r,p,q))
else{s=B.d6(r,a.e,p)
switch(s.w){case 11:b.push(B.n0(r,s,q,a.n))
break
default:b.push(B.n_(r,s,q))
break}}},
qH(a,b){var s,r,q,p=a.u,o=b.pop(),n=null,m=null
if(typeof o=="number")switch(o){case-1:n=b.pop()
break
case-2:m=b.pop()
break
default:b.push(o)
break}else b.push(o)
s=B.o1(a,b)
o=b.pop()
switch(o){case-3:o=b.pop()
if(n==null)n=p.sEA
if(m==null)m=p.sEA
r=B.d6(p,a.e,o)
q=new B.fR()
q.a=s
q.b=n
q.c=m
b.push(B.o7(p,r,q))
return
case-4:b.push(B.oa(p,b.pop(),s))
return
default:throw B.f(B.eV("Unexpected state under `()`: "+B.z(o)))}},
qJ(a,b){var s=b.pop()
if(0===s){b.push(B.eJ(a.u,1,"0&"))
return}if(1===s){b.push(B.eJ(a.u,4,"1&"))
return}throw B.f(B.eV("Unexpected extended operation "+B.z(s)))},
o1(a,b){var s=b.splice(a.p)
B.o5(a.u,a.e,s)
a.p=b.pop()
return s},
d6(a,b,c){if(typeof c=="string")return B.eI(a,c,a.sEA)
else if(typeof c=="number"){b.toString
return B.qL(a,b,c)}else return c},
o5(a,b,c){var s,r=c.length
for(s=0;s<r;++s)c[s]=B.d6(a,b,c[s])},
qM(a,b,c){var s,r=c.length
for(s=2;s<r;s+=3)c[s]=B.d6(a,b,c[s])},
qL(a,b,c){var s,r,q=b.w
if(q===9){if(c===0)return b.x
s=b.y
r=s.length
if(c<=r)return s[c-1]
c-=r
b=b.x
q=b.w}else if(c===0)return b
if(q!==8)throw B.f(B.eV("Indexed base must be an interface type"))
s=b.y
if(c<=s.length)return s[c-1]
throw B.f(B.eV("Bad index "+c+" for "+b.v(0)))},
oB(a,b,c){var s,r=b.d
if(r==null)r=b.d=new Map()
s=r.get(c)
if(s==null){s=B.ay(a,b,null,c,null)
r.set(c,s)}return s},
ay(a,b,c,d,e){var s,r,q,p,o,n,m,l,k,j,i
if(b===d)return!0
if(B.dc(d))return!0
s=b.w
if(s===4)return!0
if(B.dc(b))return!1
if(b.w===1)return!0
r=s===13
if(r)if(B.ay(a,c[b.x],c,d,e))return!0
q=d.w
p=t.b
if(b===p||b===t.v){if(q===7)return B.ay(a,b,c,d.x,e)
return d===p||d===t.v||q===6}if(d===t.K){if(s===7)return B.ay(a,b.x,c,d,e)
return s!==6}if(s===7){if(!B.ay(a,b.x,c,d,e))return!1
return B.ay(a,B.mT(a,b),c,d,e)}if(s===6)return B.ay(a,p,c,d,e)&&B.ay(a,b.x,c,d,e)
if(q===7){if(B.ay(a,b,c,d.x,e))return!0
return B.ay(a,b,c,B.mT(a,d),e)}if(q===6)return B.ay(a,b,c,p,e)||B.ay(a,b,c,d.x,e)
if(r)return!1
p=s!==11
if((!p||s===12)&&d===t.w)return!0
o=s===10
if(o&&d===t.lZ)return!0
if(q===12){if(b===t.C)return!0
if(s!==12)return!1
n=b.y
m=d.y
l=n.length
if(l!==m.length)return!1
c=c==null?n:n.concat(c)
e=e==null?m:m.concat(e)
for(k=0;k<l;++k){j=n[k]
i=m[k]
if(!B.ay(a,j,c,i,e)||!B.ay(a,i,e,j,c))return!1}return B.om(a,b.x,c,d.x,e)}if(q===11){if(b===t.C)return!0
if(p)return!1
return B.om(a,b,c,d,e)}if(s===8){if(q!==8)return!1
return B.rm(a,b,c,d,e)}if(o&&q===10)return B.rr(a,b,c,d,e)
return!1},
om(a3,a4,a5,a6,a7){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2
if(!B.ay(a3,a4.x,a5,a6.x,a7))return!1
s=a4.y
r=a6.y
q=s.a
p=r.a
o=q.length
n=p.length
if(o>n)return!1
m=n-o
l=s.b
k=r.b
j=l.length
i=k.length
if(o+j<n+i)return!1
for(h=0;h<o;++h){g=q[h]
if(!B.ay(a3,p[h],a7,g,a5))return!1}for(h=0;h<m;++h){g=l[h]
if(!B.ay(a3,p[o+h],a7,g,a5))return!1}for(h=0;h<i;++h){g=l[m+h]
if(!B.ay(a3,k[h],a7,g,a5))return!1}f=s.c
e=r.c
d=f.length
c=e.length
for(b=0,a=0;a<c;a+=3){a0=e[a]
for(;;){if(b>=d)return!1
a1=f[b]
b+=3
if(a0<a1)return!1
a2=f[b-2]
if(a1<a0){if(a2)return!1
continue}g=e[a+1]
if(a2&&!g)return!1
g=f[b-1]
if(!B.ay(a3,e[a+2],a7,g,a5))return!1
break}}while(b<d){if(f[b+1])return!1
b+=3}return!0},
rm(a,b,c,d,e){var s,r,q,p,o,n=b.x,m=d.x
while(n!==m){s=a.tR[n]
if(s==null)return!1
if(typeof s=="string"){n=s
continue}r=s[m]
if(r==null)return!1
q=r.length
p=q>0?new Array(q):v.typeUniverse.sEA
for(o=0;o<q;++o)p[o]=B.eK(a,b,r[o])
return B.oe(a,p,null,c,d.y,e)}return B.oe(a,b.y,null,c,d.y,e)},
oe(a,b,c,d,e,f){var s,r=b.length
for(s=0;s<r;++s)if(!B.ay(a,b[s],d,e[s],f))return!1
return!0},
rr(a,b,c,d,e){var s,r=b.y,q=d.y,p=r.length
if(p!==q.length)return!1
if(b.x!==d.x)return!1
for(s=0;s<p;++s)if(!B.ay(a,r[s],c,q[s],e))return!1
return!0},
dO(a){var s=a.w,r=!0
if(!(a===t.b||a===t.v))if(!B.dc(a))if(s!==6)r=s===7&&B.dO(a.x)
return r},
dc(a){var s=a.w
return s===2||s===3||s===4||s===5||a===t.X},
oc(a,b){var s,r,q=Object.keys(b),p=q.length
for(s=0;s<p;++s){r=q[s]
a[r]=b[r]}},
lM(a){return a>0?new Array(a):v.typeUniverse.sEA},
bu:function bu(a,b){var _=this
_.a=a
_.b=b
_.r=_.f=_.d=_.c=null
_.w=0
_.as=_.Q=_.z=_.y=_.x=null},
fR:function fR(){this.c=this.b=this.a=null},
h3:function h3(a){this.a=a},
fQ:function fQ(){},
dF:function dF(a){this.a=a},
qB(){var s,r,q
if(self.scheduleImmediate!=null)return B.rW()
if(self.MutationObserver!=null&&self.document!=null){s={}
r=self.document.createElement("div")
q=self.document.createElement("span")
s.a=null
new self.MutationObserver(B.h7(new B.lk(s),1)).observe(r,{childList:true})
return new B.lj(s,r,q)}else if(self.setImmediate!=null)return B.rX()
return B.rY()},
qC(a){self.scheduleImmediate(B.h7(new B.ll(t.Q.a(a)),0))},
qD(a){self.setImmediate(B.h7(new B.lm(t.Q.a(a)),0))},
qE(a){t.Q.a(a)
B.qN(0,a)},
qN(a,b){var s=new B.h2()
s.eC(a,b)
return s},
D(a){return new B.fN(new B.aC($.ar,a.i("aC<0>")),a.i("fN<0>"))},
C(a,b){a.$2(0,null)
b.b=!0
return b.a},
o(a,b){B.r1(a,b)},
B(a,b){var s,r,q=b.$ti
q.i("1/?").a(a)
s=a==null?q.c.a(a):a
if(!b.b)b.a.dw(s)
else{r=b.a
if(q.i("cO<1>").b(s))r.dB(s)
else r.dF(s)}},
A(a,b){var s=B.b9(a),r=B.dN(a),q=b.b,p=b.a
if(q)p.cG(new B.bs(s,r))
else p.dz(new B.bs(s,r))},
r1(a,b){var s,r,q=new B.lP(b),p=new B.lQ(b)
if(a instanceof B.aC)a.dU(q,p,t.z)
else{s=t.z
if(a instanceof B.aC)a.dh(q,p,s)
else{r=new B.aC($.ar,t.j_)
r.a=8
r.c=a
r.dU(q,p,s)}}},
E(a){var s=function(b,c){return function(d,e){while(true){try{b(d,e)
break}catch(r){e=r
d=c}}}}(a,1)
return $.ar.ek(new B.lW(s),t.H,t.S,t.z)},
o6(a,b,c){return 0},
mp(a){var s
if(t.fz.b(a)){s=a.gbN()
if(s!=null)return s}return A.e3},
nF(a){var s
a.a(null)
s=new B.aC($.ar,a.i("aC<0>"))
s.dw(null)
return s},
mX(a,b,c){var s,r,q,p,o={},n=o.a=a
for(s=t.j_;r=n.a,(r&4)!==0;n=a){a=s.a(n.c)
o.a=a}if(n===b){s=B.qs()
b.dz(new B.bs(new B.br(!0,n,null,"Cannot complete a future with itself"),s))
return}q=b.a&1
s=n.a=r|q
if((s&24)===0){p=t.o.a(b.c)
b.a=b.a&1|4
b.c=n
n.dM(p)
return}if(!c)if(b.c==null)n=(s&16)===0||q!==0
else n=!1
else n=!0
if(n){p=b.bS()
b.bO(o.a)
B.dD(b,p)
return}b.a^=2
B.h5(null,null,b.b,t.Q.a(new B.ls(o,b)))},
dD(a,b){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d={},c=d.a=a
for(s=t.n,r=t.o;;){q={}
p=c.a
o=(p&16)===0
n=!o
if(b==null){if(n&&(p&1)===0){m=s.a(c.c)
B.n5(m.a,m.b)}return}q.a=b
l=b.a
for(c=b;l!=null;c=l,l=k){c.a=null
B.dD(d.a,c)
q.a=l
k=l.a}p=d.a
j=p.c
q.b=n
q.c=j
if(o){i=c.c
i=(i&1)!==0||(i&15)===8}else i=!0
if(i){h=c.b.b
if(n){p=p.b===h
p=!(p||p)}else p=!1
if(p){s.a(j)
B.n5(j.a,j.b)
return}g=$.ar
if(g!==h)$.ar=h
else g=null
c=c.c
if((c&15)===8)new B.lw(q,d,n).$0()
else if(o){if((c&1)!==0)new B.lv(q,j).$0()}else if((c&2)!==0)new B.lu(d,q).$0()
if(g!=null)$.ar=g
c=q.c
if(c instanceof B.aC){p=q.a.$ti
p=p.i("cO<2>").b(c)||!p.y[1].b(c)}else p=!1
if(p){f=q.a.b
if((c.a&24)!==0){e=r.a(f.c)
f.c=null
b=f.bU(e)
f.a=c.a&30|f.a&1
f.c=c.c
d.a=c
continue}else B.mX(c,f,!0)
return}}f=q.a.b
e=r.a(f.c)
f.c=null
b=f.bU(e)
c=q.b
p=q.c
if(!c){f.$ti.c.a(p)
f.a=8
f.c=p}else{s.a(p)
f.a=f.a&1|16
f.c=p}d.a=f
c=f}},
rH(a,b){var s
if(t.ng.b(a))return b.ek(a,t.z,t.K,t.l)
s=t.mq
if(s.b(a))return s.a(a)
throw B.f(B.mo(a,"onError",u.w))},
rx(){var s,r
for(s=$.dK;s!=null;s=$.dK){$.eP=null
r=s.b
$.dK=r
if(r==null)$.eO=null
s.a.$0()}},
rN(){$.n4=!0
try{B.rx()}finally{$.eP=null
$.n4=!1
if($.dK!=null)$.nh().$1(B.ou())}},
os(a){var s=new B.fO(a),r=$.eO
if(r==null){$.dK=$.eO=s
if(!$.n4)$.nh().$1(B.ou())}else $.eO=r.b=s},
rK(a){var s,r,q,p=$.dK
if(p==null){B.os(a)
$.eP=$.eO
return}s=new B.fO(a)
r=$.eP
if(r==null){s.b=p
$.dK=$.eP=s}else{q=r.b
s.b=q
$.eP=r.b=s
if(q==null)$.eO=s}},
tO(a,b){B.h6(a,"stream",t.K)
return new B.h0(b.i("h0<0>"))},
n5(a,b){B.rK(new B.lU(a,b))},
oq(a,b,c,d,e){var s,r=$.ar
if(r===c)return d.$0()
$.ar=c
s=r
try{r=d.$0()
return r}finally{$.ar=s}},
rJ(a,b,c,d,e,f,g){var s,r=$.ar
if(r===c)return d.$1(e)
$.ar=c
s=r
try{r=d.$1(e)
return r}finally{$.ar=s}},
rI(a,b,c,d,e,f,g,h,i){var s,r=$.ar
if(r===c)return d.$2(e,f)
$.ar=c
s=r
try{r=d.$2(e,f)
return r}finally{$.ar=s}},
h5(a,b,c,d){t.Q.a(d)
if(A.ac!==c){d=c.fg(d)
d=d}B.os(d)},
lk:function lk(a){this.a=a},
lj:function lj(a,b,c){this.a=a
this.b=b
this.c=c},
ll:function ll(a){this.a=a},
lm:function lm(a){this.a=a},
h2:function h2(){this.b=null},
lI:function lI(a,b){this.a=a
this.b=b},
fN:function fN(a,b){this.a=a
this.b=!1
this.$ti=b},
lP:function lP(a){this.a=a},
lQ:function lQ(a){this.a=a},
lW:function lW(a){this.a=a},
d8:function d8(a,b){var _=this
_.a=a
_.e=_.d=_.c=_.b=null
_.$ti=b},
cA:function cA(a,b){this.a=a
this.$ti=b},
bs:function bs(a,b){this.a=a
this.b=b},
d3:function d3(a,b,c,d,e){var _=this
_.a=null
_.b=a
_.c=b
_.d=c
_.e=d
_.$ti=e},
aC:function aC(a,b){var _=this
_.a=0
_.b=a
_.c=null
_.$ti=b},
lp:function lp(a,b){this.a=a
this.b=b},
lt:function lt(a,b){this.a=a
this.b=b},
ls:function ls(a,b){this.a=a
this.b=b},
lr:function lr(a,b){this.a=a
this.b=b},
lq:function lq(a,b){this.a=a
this.b=b},
lw:function lw(a,b,c){this.a=a
this.b=b
this.c=c},
lx:function lx(a,b){this.a=a
this.b=b},
ly:function ly(a){this.a=a},
lv:function lv(a,b){this.a=a
this.b=b},
lu:function lu(a,b){this.a=a
this.b=b},
fO:function fO(a){this.a=a
this.b=null},
h0:function h0(a){this.$ti=a},
eM:function eM(){},
fX:function fX(){},
lH:function lH(a,b){this.a=a
this.b=b},
lU:function lU(a,b){this.a=a
this.b=b},
nM(a,b){return new B.bl(a.i("@<0>").E(b).i("bl<1,2>"))},
V(a,b,c){return b.i("@<0>").E(c).i("mM<1,2>").a(B.oy(a,new B.bl(b.i("@<0>").E(c).i("bl<1,2>"))))},
n(a,b){return new B.bl(a.i("@<0>").E(b).i("bl<1,2>"))},
kS(a){return new B.bn(a.i("bn<0>"))},
a1(a){return new B.bn(a.i("bn<0>"))},
dv(a,b){return b.i("nN<0>").a(B.t9(a,new B.bn(b.i("bn<0>"))))},
mY(){var s=Object.create(null)
s["<non-identifier-key>"]=s
delete s["<non-identifier-key>"]
return s},
lE(a,b,c){var s=new B.cg(a,b,c.i("cg<0>"))
s.c=a.e
return s},
nI(a,b){return B.q3(a,0,b)},
kN(a,b){var s=J.at(a)
if(s.l())return s.gu()
return null},
aw(a,b,c){var s=B.nM(b,c)
a.af(0,new B.kR(s,b,c))
return s},
bK(a,b,c){var s=B.nM(b,c)
s.A(0,a)
return s},
dw(a,b){var s,r=B.kS(b)
for(s=J.at(a);s.l();)r.n(0,b.a(s.gu()))
return r},
a3(a,b){var s=B.kS(b)
s.A(0,a)
return s},
kU(a){var s,r
if(B.nb(a))return"{...}"
s=new B.dB("")
try{r={}
A.b.n($.bh,a)
s.a+="{"
r.a=!0
a.af(0,new B.kV(r,s))
s.a+="}"}finally{if(0>=$.bh.length)return B.b($.bh,-1)
$.bh.pop()}r=s.a
return r.charCodeAt(0)==0?r:r},
bn:function bn(a){var _=this
_.a=0
_.f=_.e=_.d=_.c=_.b=null
_.r=0
_.$ti=a},
fU:function fU(a){this.a=a
this.c=this.b=null},
cg:function cg(a,b,c){var _=this
_.a=a
_.b=b
_.d=_.c=null
_.$ti=c},
kR:function kR(a,b,c){this.a=a
this.b=b
this.c=c},
H:function H(){},
S:function S(){},
kT:function kT(a){this.a=a},
kV:function kV(a,b){this.a=a
this.b=b},
ey:function ey(a,b){this.a=a
this.$ti=b},
ez:function ez(a,b,c){var _=this
_.a=a
_.b=b
_.c=null
_.$ti=c},
eL:function eL(){},
cT:function cT(){},
er:function er(){},
cw:function cw(){},
eF:function eF(){},
dG:function dG(){},
rD(a,b){var s,r,q,p=null
try{p=JSON.parse(a)}catch(r){s=B.b9(r)
q=B.dp(String(s),null)
throw B.f(q)}q=B.lS(p)
return q},
lS(a){var s
if(a==null)return null
if(typeof a!="object")return a
if(!Array.isArray(a))return new B.ex(a,Object.create(null))
for(s=0;s<a.length;++s)a[s]=B.lS(a[s])
return a},
nL(a,b,c){return new B.eb(a,b)},
r7(a){return a.H()},
qF(a,b){return new B.lB(a,[],B.t2())},
qG(a,b,c){var s,r=new B.dB(""),q=B.qF(r,b)
q.cv(a)
s=r.a
return s.charCodeAt(0)==0?s:s},
ex:function ex(a,b){this.a=a
this.b=b
this.c=null},
lA:function lA(a){this.a=a},
fT:function fT(a){this.a=a},
dh:function dh(){},
eu:function eu(a){this.a=a},
eZ:function eZ(){},
bS:function bS(){},
eb:function eb(a,b){this.a=a
this.b=b},
fo:function fo(a,b){this.a=a
this.b=b},
fn:function fn(){},
fq:function fq(a){this.b=a},
fp:function fp(a){this.a=a},
lC:function lC(){},
lD:function lD(a,b){this.a=a
this.b=b},
lB:function lB(a,b,c){this.c=a
this.a=b
this.b=c},
fM:function fM(){},
lL:function lL(a){this.b=0
this.c=a},
eQ(a,b){var s=B.qo(a,b)
if(s!=null)return s
throw B.f(B.dp(a,null))},
pP(a,b){a=B.as(a,new Error())
if(a==null)a=B.dJ(a)
a.stack=b.v(0)
throw a},
mN(a,b,c,d){var s,r=c?J.mJ(a,d):J.nJ(a,d)
if(a!==0&&b!=null)for(s=0;s<r.length;++s)r[s]=b
return r},
mO(a,b,c){var s,r=B.m([],c.i("v<0>"))
for(s=J.at(a);s.l();)A.b.n(r,c.a(s.gu()))
if(b)return r
r.$flags=1
return r},
fr(a,b,c){var s
if(b)s=B.k(a,c)
else{s=B.k(a,c)
s.$flags=1
s=s}return s},
k(a,b){var s,r
if(Array.isArray(a))return B.m(a.slice(0),b.i("v<0>"))
s=B.m([],b.i("v<0>"))
for(r=J.at(a);r.l();)A.b.n(s,r.gu())
return s},
dx(a,b,c){var s,r=J.mJ(a,c)
for(s=0;s<a;++s)A.b.j(r,s,b.$1(s))
return r},
aR(a,b){var s=B.mO(a,!1,b)
s.$flags=3
return s},
qu(a){var s
B.aO(0,"start")
s=B.qv(a,0,null)
return s},
qv(a,b,c){var s=a.length
if(b>=s)return""
return B.qp(a,b,s)},
L(a){return new B.fl(a,B.qc(a,!1,!0,!1,!1,""))},
nW(a,b,c){var s=J.at(b)
if(!s.l())return a
if(c.length===0){do a+=B.z(s.gu())
while(s.l())}else{a+=B.z(s.gu())
while(s.l())a=a+c+B.z(s.gu())}return a},
qs(){return B.dN(new Error())},
pv(a,b,c,d,e,f,g,h,i){var s=B.mR(a,b,c,d,e,f,g,h,i)
if(s==null)return null
return new B.ac(B.nt(s,h,i),h,i)},
cm(a,b,c,d,e){var s=B.mR(a,b,c,d,e,0,0,0,!1)
return new B.ac(s==null?new B.f0(a,b,c,d,e,0,0,0).$0():s,0,!1)},
cM(a,b,c,d,e){var s=B.mR(a,b,c,d,e,0,0,0,!0)
return new B.ac(s==null?new B.f0(a,b,c,d,e,0,0,0).$0():s,0,!0)},
hq(a){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c=null,b=$.oJ().a4(a)
if(b!=null){s=new B.hr()
r=b.b
if(1>=r.length)return B.b(r,1)
q=r[1]
q.toString
p=B.eQ(q,c)
if(2>=r.length)return B.b(r,2)
q=r[2]
q.toString
o=B.eQ(q,c)
if(3>=r.length)return B.b(r,3)
q=r[3]
q.toString
n=B.eQ(q,c)
if(4>=r.length)return B.b(r,4)
m=s.$1(r[4])
if(5>=r.length)return B.b(r,5)
l=s.$1(r[5])
if(6>=r.length)return B.b(r,6)
k=s.$1(r[6])
if(7>=r.length)return B.b(r,7)
j=new B.hs().$1(r[7])
i=A.a.G(j,1000)
q=r.length
if(8>=q)return B.b(r,8)
h=r[8]!=null
if(h){if(9>=q)return B.b(r,9)
g=r[9]
if(g!=null){f=g==="-"?-1:1
if(10>=q)return B.b(r,10)
q=r[10]
q.toString
e=B.eQ(q,c)
if(11>=r.length)return B.b(r,11)
l-=f*(s.$1(r[11])+60*e)}}d=B.pv(p,o,n,m,l,k,i,j%1000,h)
if(d==null)throw B.f(B.dp("Time out of range",a))
return d}else throw B.f(B.dp("Invalid date format",a))},
a9(a){var s,r
try{s=B.hq(a)
return s}catch(r){if(B.b9(r) instanceof B.aI)return null
else throw r}},
nt(a,b,c){var s="microsecond"
if(b<0||b>999)throw B.f(B.aN(b,0,999,s,null))
if(a<-864e13||a>864e13)throw B.f(B.aN(a,-864e13,864e13,"millisecondsSinceEpoch",null))
if(a===864e13&&b!==0)throw B.f(B.mo(b,s,"Time including microseconds is outside valid range"))
B.h6(c,"isUtc",t.y)
return a},
ns(a){var s=Math.abs(a),r=a<0?"-":""
if(s>=1000)return""+a
if(s>=100)return r+"0"+s
if(s>=10)return r+"00"+s
return r+"000"+s},
pw(a){var s=Math.abs(a),r=a<0?"-":"+"
if(s>=1e5)return r+s
return r+"0"+s},
hp(a){if(a>=100)return""+a
if(a>=10)return"0"+a
return"00"+a},
bT(a){if(a>=10)return""+a
return"0"+a},
ah(a,b,c,d,e,f){return new B.a_(c+1000*d+1e6*f+6e7*e+36e8*b+864e8*a)},
fb(a){if(typeof a=="number"||B.a5(a)||a==null)return J.au(a)
if(typeof a=="string")return JSON.stringify(a)
return B.nU(a)},
pQ(a,b){B.h6(a,"error",t.K)
B.h6(b,"stackTrace",t.l)
B.pP(a,b)},
eV(a){return new B.eU(a)},
bR(a,b){return new B.br(!1,null,b,a)},
mo(a,b,c){return new B.br(!0,a,b,c)},
df(a,b,c){return a},
qq(a){var s=null
return new B.dz(s,s,!1,s,s,a)},
mS(a,b){return new B.dz(null,null,!0,a,b,"Value not in range")},
aN(a,b,c,d,e){return new B.dz(b,c,!0,a,d,"Invalid value")},
l5(a,b,c){if(0>a||a>c)throw B.f(B.aN(a,0,c,"start",null))
if(b!=null){if(a>b||b>c)throw B.f(B.aN(b,a,c,"end",null))
return b}return c},
aO(a,b){if(a<0)throw B.f(B.aN(a,0,null,b,null))
return a},
kM(a,b,c,d){return new B.fh(b,!0,a,d,"Index out of range")},
ax(a){return new B.es(a)},
nY(a){return new B.fK(a)},
bv(a){return new B.dA(a)},
af(a){return new B.f_(a)},
dp(a,b){return new B.aI(a,b)},
q7(a,b,c){var s,r
if(B.nb(a)){if(b==="("&&c===")")return"(...)"
return b+"..."+c}s=B.m([],t.s)
A.b.n($.bh,a)
try{B.rv(a,s)}finally{if(0>=$.bh.length)return B.b($.bh,-1)
$.bh.pop()}r=B.nW(b,t.e7.a(s),", ")+c
return r.charCodeAt(0)==0?r:r},
mH(a,b,c){var s,r
if(B.nb(a))return b+"..."+c
s=new B.dB(b)
A.b.n($.bh,a)
try{r=s
r.a=B.nW(r.a,a,", ")}finally{if(0>=$.bh.length)return B.b($.bh,-1)
$.bh.pop()}s.a+=c
r=s.a
return r.charCodeAt(0)==0?r:r},
rv(a,b){var s,r,q,p,o,n,m,l=a.gq(a),k=0,j=0
for(;;){if(!(k<80||j<3))break
if(!l.l())return
s=B.z(l.gu())
A.b.n(b,s)
k+=s.length+2;++j}if(!l.l()){if(j<=5)return
if(0>=b.length)return B.b(b,-1)
r=b.pop()
if(0>=b.length)return B.b(b,-1)
q=b.pop()}else{p=l.gu();++j
if(!l.l()){if(j<=4){A.b.n(b,B.z(p))
return}r=B.z(p)
if(0>=b.length)return B.b(b,-1)
q=b.pop()
k+=r.length+2}else{o=l.gu();++j
for(;l.l();p=o,o=n){n=l.gu();++j
if(j>100){for(;;){if(!(k>75&&j>3))break
if(0>=b.length)return B.b(b,-1)
k-=b.pop().length+2;--j}A.b.n(b,"...")
return}}q=B.z(p)
r=B.z(o)
k+=r.length+q.length+4}}if(j>b.length+2){k+=5
m="..."}else m=null
for(;;){if(!(k>80&&b.length>3))break
if(0>=b.length)return B.b(b,-1)
k-=b.pop().length+2
if(m==null){k+=5
m="..."}}if(m!=null)A.b.n(b,m)
A.b.n(b,q)
A.b.n(b,r)},
mP(a,b,c,d){var s
if(A.at===c){s=A.a.gR(a)
b=J.bA(b)
return B.lb(B.cb(B.cb($.ha(),s),b))}if(A.at===d){s=A.a.gR(a)
b=J.bA(b)
c=J.bA(c)
return B.lb(B.cb(B.cb(B.cb($.ha(),s),b),c))}s=A.a.gR(a)
b=J.bA(b)
c=J.bA(c)
d=J.bA(d)
d=B.lb(B.cb(B.cb(B.cb(B.cb($.ha(),s),b),c),d))
return d},
qj(a){var s,r,q=$.ha()
for(s=a.length,r=0;r<a.length;a.length===s||(0,B.Z)(a),++r)q=B.cb(q,J.bA(a[r]))
return B.lb(q)},
r5(a,b){return 65536+((a&1023)<<10)+(b&1023)},
f0:function f0(a,b,c,d,e,f,g,h){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h},
ac:function ac(a,b,c){this.a=a
this.b=b
this.c=c},
hr:function hr(){},
hs:function hs(){},
a_:function a_(a){this.a=a},
fP:function fP(){},
a6:function a6(){},
eU:function eU(a){this.a=a},
cd:function cd(){},
br:function br(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
dz:function dz(a,b,c,d,e,f){var _=this
_.e=a
_.f=b
_.a=c
_.b=d
_.c=e
_.d=f},
fh:function fh(a,b,c,d,e){var _=this
_.f=a
_.a=b
_.b=c
_.c=d
_.d=e},
es:function es(a){this.a=a},
fK:function fK(a){this.a=a},
dA:function dA(a){this.a=a},
f_:function f_(a){this.a=a},
fy:function fy(){},
ep:function ep(){},
lo:function lo(a){this.a=a},
aI:function aI(a,b){this.a=a
this.b=b},
a:function a(){},
P:function P(a,b,c){this.a=a
this.b=b
this.$ti=c},
aL:function aL(){},
I:function I(){},
h1:function h1(){},
cY:function cY(a){this.a=a},
fF:function fF(a){var _=this
_.a=a
_.c=_.b=0
_.d=-1},
dB:function dB(a){this.a=a},
pT(a,b){var s,r=v.G.Promise,q=new B.j4(a)
if(typeof q=="function")B.aX(B.bR("Attempting to rewrap a JS function.",null))
s=function(c,d){return function(e,f){return c(d,e,f,arguments.length)}}(B.r3,q)
s[$.ml()]=q
return B.oh(new r(s))},
j4:function j4(a){this.a=a},
j2:function j2(a){this.a=a},
j3:function j3(a){this.a=a},
fW:function fW(){this.b=this.a=0},
fa:function fa(){},
re(a){var s,r,q,p,o="0123456789abcdef",n=a.length,m=n*2,l=new Uint8Array(m)
for(s=0,r=0;s<n;++s){q=a[s]
p=r+1
if(!(r<m))return B.b(l,r)
l[r]=o.charCodeAt(q>>>4&15)
r=p+1
if(!(p<m))return B.b(l,p)
l[p]=o.charCodeAt(q&15)}return B.qu(l)},
bU:function bU(a){this.a=a},
dj:function dj(){this.a=null},
e4:function e4(){},
fd:function fd(){},
fg:function fg(a,b){this.a=a
this.b=b},
fS:function fS(a,b){var _=this
_.a=a
_.b=b
_.c=$
_.d=!1},
mZ(a){var s=new Uint32Array(B.oi(B.m([1779033703,3144134277,1013904242,2773480762,1359893119,2600822924,528734635,1541459225],t.t))),r=new Uint32Array(64),q=new Uint8Array(64)
return new B.fZ(s,r,a,q,new Uint32Array(16))},
fY:function fY(){},
h_:function h_(){},
fZ:function fZ(a,b,c,d,e){var _=this
_.y=a
_.z=b
_.a=c
_.c=null
_.d=d
_.e=0
_.f=e
_.r=0
_.w=!1},
j6(a){var s=new B.j5(B.n(t.N,t.X))
s.ex(a)
return s},
j8(a){if(!t.f.b(a)||a.gY().N(0,new B.j9()))throw B.f(A.iO)
return B.aw(a,t.N,t.z)},
cP(a){var s,r,q,p,o
if(t.f.b(a)){s=t.N
r=a.gY().b6(0,new B.j7(),s).bJ(0)
A.b.cw(r)
s=B.n(s,t.X)
for(q=r.length,p=0;p<r.length;r.length===q||(0,B.Z)(r),++p){o=r[p]
if(a.h(0,o)!=null&&!J.F(a.h(0,o),0)&&!J.F(a.h(0,o),!1))s.j(0,o,B.cP(a.h(0,o)))}return s}if(t.j.b(a)){s=J.pd(a,B.ta(),t.X)
s=B.k(s,s.$ti.i("a4.E"))
return s}if(typeof a=="number"&&a===A.c.fX(a))return A.c.k(a)
return a},
j5:function j5(a){this.a=a},
ja:function ja(){},
jb:function jb(a,b,c){this.a=a
this.b=b
this.c=c},
j9:function j9(){},
j7:function j7(){},
U(a,b,c,d,e,f){return B.pU(a,b,c,d,e,f)},
pU(a2,a3,a4,a5,a6,a7){var s=0,r=B.D(t.P),q,p=2,o=[],n=[],m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1
var $async$U=B.E(function(a8,a9){if(a8===1){o.push(a9)
s=p}for(;;)switch(s){case 0:a=A.Lx.h(0,a2)
if(a==null||a5.gm(a5)!==a.gm(a)||!a.aO(0,a5.gai()))throw B.f(A.c6)
m=new B.lg(a5)
if(a7.h(0,"pendingAltarOperation")!=null)throw B.f(A.iW)
l=B.mG(a7,B.l8(a6,"identities").gep(),a4,B.l8(a6,"rewards"))
p=4
if(l.p3.a!=null&&l.p3.a!==a3)throw B.f(A.iX)
l.sfe(new B.jc(a3))
l.to=!0
k=null
case 7:switch(a2){case"refresh":s=9
break
case"purchase_portrait_chest":s=10
break
case"purchase_title_chest":s=11
break
case"purchase_music_chest":s=12
break
case"purchase_furniture":s=13
break
case"purchase_relic":s=14
break
case"open_chests":s=15
break
case"open_special_chests":s=16
break
case"use_relic":s=17
break
case"use_astral_lens":s=18
break
case"tag_egg":s=19
break
case"return_egg":s=20
break
case"craft_altar_relic":s=21
break
case"use_altar_relic":s=22
break
case"use_chronoshard":s=23
break
case"use_wayfinder":s=24
break
case"equip_twinstar":s=25
break
case"activate_egg":s=26
break
case"hatch_egg":s=27
break
case"name_dragon":s=28
break
case"evolve_dragon":s=29
break
case"buy_starlight_treat":s=30
break
case"release_dragon":s=31
break
case"start_adventure":s=32
break
case"dismiss_adventure":s=33
break
case"claim_adventure":s=34
break
case"abort_adventure":s=35
break
case"dismiss_trial":s=36
break
case"claim_constellation":s=37
break
case"unlock_room":s=38
break
case"build_floor":s=39
break
case"repair_floor":s=40
break
case"upgrade_ward":s=41
break
case"complete_tutorial":s=42
break
case"redeem_code":s=43
break
default:s=44
break}break
case 9:s=45
return B.o(l.bo(),$async$U)
case 45:k=!0
s=8
break
case 10:s=46
return B.o(l.cn(),$async$U)
case 46:k=a9.b
s=8
break
case 11:s=47
return B.o(l.cp(),$async$U)
case 47:k=a9.b
s=8
break
case 12:s=48
return B.o(l.cm(),$async$U)
case 48:k=a9.b
s=8
break
case 13:d=m.T("catalogId")
j=$.de().h(0,d)
if(j==null)throw B.f(A.iZ)
s=49
return B.o(l.bI(j),$async$U)
case 49:k=a9.b
s=8
break
case 14:s=50
return B.o(l.co(m.be("relic",A.ae,t._)),$async$U)
case 50:k=a9.b
s=8
break
case 15:i=m.be("tier",A.ax,t.mW)
if(i===A.l)throw B.f(A.iY)
a1=B
s=51
return B.o(l.bn(i,m.ck("count",10,1)),$async$U)
case 51:k=a1.nG(a9)
s=8
break
case 16:a1=B
s=52
return B.o(l.bH(m.T("catalogId"),m.ck("count",10,1)),$async$U)
case 52:k=a1.nG(a9)
s=8
break
case 17:s=53
return B.o(l.ct(m.be("relic",A.ae,t._),m.T("dragonId")),$async$U)
case 53:k=a9.b
s=8
break
case 18:s=54
return B.o(l.cs(m.T("eggId")),$async$U)
case 54:k=a9.b
s=8
break
case 19:s=55
return B.o(B.j_(l,m.T("eggId"),m.cZ("tagged")),$async$U)
case 55:k=!0
s=8
break
case 20:s=56
return B.o(B.iZ(l,m.T("eggId"),m.cZ("sinisterConfirmed")),$async$U)
case 56:k=a9.H()
s=8
break
case 21:s=57
return B.o(B.iV(l,m.be("relic",A.aw,t.p)),$async$U)
case 57:k=!0
s=8
break
case 22:s=58
return B.o(B.j0(l,m.be("relic",A.aw,t.p),m.T("eggId")),$async$U)
case 58:k=!0
s=8
break
case 23:s=59
return B.o(l.bL(m.ck("reductionPercent",100,1)),$async$U)
case 59:k=a9.b
s=8
break
case 24:d=m.be("kind",A.xJ,t.lV)
c=m
c=c.a.h(0,"replaceAdventureId")==null?null:c.T("replaceAdventureId")
s=60
return B.o(B.iD(l,d,c),$async$U)
case 60:k=a9.b
s=8
break
case 25:d=m
d=d.a.h(0,"dragonId")==null?null:d.T("dragonId")
s=61
return B.o(l.c_(d),$async$U)
case 61:k=a9
s=8
break
case 26:s=62
return B.o(l.bt(m.T("eggId")),$async$U)
case 62:k=a9
s=8
break
case 27:d=l
c=d.ok
c===$&&B.N()
if(c.f===A.h)d=c
else d=d.p1
d=d==null?null:d.a
a1=d===m.T("eggId")
if(a1){s=63
break}else a9=a1
s=64
break
case 63:s=65
return B.o(l.cj(),$async$U)
case 65:case 64:k=a9
s=8
break
case 28:s=66
return B.o(l.cl(m.T("dragonId"),m.dg("name",24)),$async$U)
case 66:k=a9
s=8
break
case 29:s=67
return B.o(l.c0(m.T("dragonId")),$async$U)
case 67:k=a9
s=8
break
case 30:d=l.ok
d===$&&B.N()
a1=d.a===m.T("dragonId")
if(a1){s=68
break}else a9=a1
s=69
break
case 68:s=70
return B.o(l.bX(),$async$U)
case 70:case 69:k=a9
s=8
break
case 31:s=71
return B.o(B.il(l,m.T("dragonId")),$async$U)
case 71:k=a9
s=8
break
case 32:h=$.b2().h(0,m.T("adventureId"))
if(h==null)throw B.f(A.c7)
s=72
return B.o(B.f8(l,h,m.T("dragonId")),$async$U)
case 72:k=a9.b
s=8
break
case 33:g=$.b2().h(0,m.T("adventureId"))
if(g==null)throw B.f(A.c7)
s=73
return B.o(B.ic(l,g),$async$U)
case 73:k=!0
s=8
break
case 34:s=74
return B.o(B.f6(l,m.T("runId")),$async$U)
case 74:d=a9
k=d==null?null:d.b
s=8
break
case 35:s=75
return B.o(B.f4(l,m.T("runId")),$async$U)
case 75:k=a9
s=8
break
case 36:s=76
return B.o(B.ie(l,m.T("offerId")),$async$U)
case 76:k=!0
s=8
break
case 37:s=77
return B.o(B.i9(l),$async$U)
case 77:d=a9
k=d==null?null:d.b
s=8
break
case 38:d=m.T("roomId")
f=$.dd().h(0,d)
if(f==null)throw B.f(A.j_)
s=78
return B.o(l.bK(f),$async$U)
case 78:k=a9.b
s=8
break
case 39:s=79
return B.o(B.i_(l,m.T("roomId")),$async$U)
case 79:k=a9.b
s=8
break
case 40:s=80
return B.o(B.ir(l,m.ck("index",19,0)),$async$U)
case 80:k=a9
s=8
break
case 41:s=81
return B.o(B.iC(l),$async$U)
case 81:k=a9
s=8
break
case 42:s=82
return B.o(l.bY(m.cZ("fullyViewed")),$async$U)
case 82:k=!0
s=8
break
case 43:s=83
return B.o(B.ik(l,m.dg("code",100),a3),$async$U)
case 83:k=a9
s=8
break
case 44:throw B.f(A.c6)
case 8:d=B.V(["protocol",2,"result",k,"state",B.mz(a7,l.c1())],t.N,t.z)
q=d
n=[1]
s=5
break
n.push(6)
s=5
break
case 4:p=3
a0=o.pop()
d=B.b9(a0)
if(d instanceof B.aE){e=d
d=e.a
throw B.f(new B.bj(d))}else throw a0
n.push(6)
s=5
break
case 3:n=[2]
case 5:p=2
l.bd()
s=n.pop()
break
case 6:case 1:return B.B(q,r)
case 2:return B.A(o.at(-1),r)}})
return B.C($async$U,r)},
nG(a){var s,r,q,p,o,n,m,l,k,j,i,h,g,f=null
if(a==null)s=f
else{s=a.a
r=B.m([],t.ke)
for(q=a.b,p=q.length,o=t.N,n=t.X,m=0;m<p;++m){l=q[m]
k=l.x
k=k==null?f:k.b
j=l.y
j=j==null?f:j.a
i=l.z
i=i==null?f:i.a
h=l.Q
h=h==null?f:h.a
g=l.as
g=g==null?f:g.a
r.push(B.V(["tier",l.a.b,"coins",l.b,"gems",l.c,"eggFound",l.d,"sinisterEgg",l.e,"specialEgg",l.f,"specialChestId",l.r,"specialEggId",l.w,"relicFound",k,"portraitFound",j,"titleFound",i,"musicTrackFound",h,"emoteFound",g],o,n))}s=B.V(["tier",s.b,"rewards",r],o,t.K)}return s},
jc:function jc(a){this.a=a},
bj:function bj(a){this.a=a},
lg:function lg(a){this.a=a},
lh:function lh(a,b){this.a=a
this.b=b},
li:function li(){},
pW(d1,d2,d3,d4,d5){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4=null,b5="eggAltar",b6="ownerId",b7="revision",b8="returnedIds",b9="lineageId",c0="incubatingEgg",c1="eggs",c2="eggRarityRevealedIds",c3="altarKnowledge",c4="moral",c5="moralAxisKnown",c6="stage",c7="order",c8="lawAxisKnown",c9="rarity",d0=B.L("^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$")
if(!d0.b.test(d3))throw B.f(A.j5)
if(d5.h(0,"pendingAltarOperation")!=null)throw B.f(A.j6)
s=B.j6(d5)
d0=t.P
r=d0.a(A.k.bc(A.k.a_(d5,b4),b4))
o=t.f
n=t.N
m=t.z
l=B.aw(o.a(J.a2(r,b5)),n,m)
if(l.h(0,b6)!=null&&!J.F(l.h(0,b6),d3))throw B.f(A.c8)
k=d1==null
j=k?b4:d0.a(A.k.bc(A.k.a_(d1,b4),b4))
i=j==null
h=!i
if(h&&!J.F(j.h(0,b6),d3))throw B.f(A.c8)
if(i&&l.h(0,b6)!=null)throw B.f(A.j7)
if(h){if(l.h(0,b6)==null&&B.pV(l))throw B.f(A.j0)
if(B.fc(j.h(0,b7))<B.fc(l.h(0,b7)))throw B.f(A.j8)
i=t.j
g=B.dw(i.a(j.h(0,b8)),n)
if(!J.pb(i.a(l.h(0,b8)),g.gbw(g)))throw B.f(A.j3)}i=B.bK(l,n,m)
if(h)i.A(0,j)
i.j(0,b6,d3)
h=t.j
g=B.dw(h.a(i.h(0,b8)),n)
f=d0.a(J.a2(r,"pet"))
e=h.a(J.a2(r,"sanctuaryDragons"))
d=h.a(J.a2(r,"releasedDragons"))
if(!g.p(0,f.h(0,"id"))){d0=B.k(e,m)
A.b.A(d0,d)
d0=A.b.N(d0,new B.jf(g))}else d0=!0
if(d0)throw B.f(A.j2)
c=h.a(J.a2(r,"eggStash"))
for(d0=J.aV(c),b=d0.cu(c,new B.jg(g)),a=J.at(b.a),b=new B.bx(a,b.b,b.$ti.i("bx<1>"));b.l();){a0=a.gu()
a1=J.bi(a0)
if(a1.h(a0,"specialEggId")==null){a1=B.M(a1.h(a0,b9))
a1=$.h9().h(0,a1)
a1=(a1==null?A.b.gM(A.a2):a1).ax===A.a6}else a1=!0
if(a1)throw B.f(A.j9)}d0.a1(c,new B.jh(g))
d0=t.d
b=d0.a(J.a2(r,c0))
if(g.p(0,b==null?b4:b.h(0,"id")))throw B.f(A.j1)
a2=B.aw(o.a(l.h(0,c1)),n,m)
a3=B.aw(o.a(i.h(0,c1)),n,m)
b=B.bK(a3,n,m)
a4=B.dw(h.a(J.a2(r,c2)),n)
a5=B.aw(o.a(i.h(0,"names")),n,m)
o=[f]
A.b.A(o,c)
A.b.A(o,e)
if(J.a2(r,c0)!=null)o.push(J.a2(r,c0))
h=o.length
a6=0
for(;a6<o.length;o.length===h||(0,B.Z)(o),++a6){a7=o[a6]
a=J.bi(a7)
a8=B.M(a.h(a7,"id"))
a1=d0.a(a.h(a7,c3))
a1=B.cI(B.aw(a1==null?B.n(m,m):a1,n,m))
a9=d0.a(a2.h(0,a8))
b0=a1.aJ(B.cI(B.aw(a9==null?B.n(m,m):a9,n,m)))
b1=d0.a(a3.h(0,a8))
a1=b1==null
b2=a1?b0:B.cI(B.aw(b1,n,m))
b3=b0.aJ(b2).H()
if(!a1){b3.j(0,"tagged",b2.a)
b3.j(0,"tagRevision",b2.b)}a1=!0
if(!J.F(b3.h(0,c4),!0))if(!J.F(a.h(a7,c5),!0))a1=a.h(a7,c6)==null&&J.F(a.h(a7,b9),"sinisterra")
b3.j(0,c4,a1)
b3.j(0,c7,J.F(b3.h(0,c7),!0)||J.F(a.h(a7,c8),!0))
b3.j(0,c9,J.F(b3.h(0,c9),!0)||a4.p(0,a8))
a.j(a7,c3,b3)
b.j(0,a8,b3)
if(a7.J(c6)){a.j(a7,c5,b3.h(0,c4))
a.j(a7,c8,b3.h(0,c7))
if(!J.F(a.h(a7,c6),"egg")&&a5.J(a8))a.j(a7,"name",a5.h(0,a8))}if(J.F(b3.h(0,c9),!0))a4.n(0,a8)}for(d0=B.lE(g,g.r,B.e(g).c),o=d0.$ti.c;d0.l();){n=d0.d
if(n==null)n=o.a(n)
b.X(0,n)
a4.X(0,n)}i.j(0,c1,b)
J.cG(r,b5,i)
d0=B.k(a4,B.e(a4).c)
J.cG(r,c2,d0)
q=B.mG(r,B.l8(d4,"identities").gep(),d2,B.l8(d4,"rewards"))
try{p=B.mz(r,q.c1())
d0=s.e4(B.j6(p))
o=k?b4:B.fc(d1.h(0,b7))
return new B.l4(p,d0,o)}finally{q.bd()}},
fc(a){if(!B.cC(a)||a<0)throw B.f(A.j4)
return a},
pV(a){var s=t.f
return s.a(a.h(0,"wallet")).gaZ().N(0,new B.jd())||s.a(a.h(0,"crafted")).gaZ().N(0,new B.je())},
jf:function jf(a){this.a=a},
jg:function jg(a){this.a=a},
jh:function jh(a){this.a=a},
jd:function jd(){},
je:function je(){},
l4:function l4(a,b,c){this.a=a
this.b=b
this.c=c},
b6:function b6(a){this.a=a},
q1(c5,c6,c7){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,c0,c1,c2,c3,c4=null
if(c7.h(0,"pendingAltarOperation")!=null)throw B.f(A.iL)
s=B.mG(c7,B.tc(),c5,new B.fV())
try{if(s.p3.a!=null&&s.p3.a!==c6)throw B.f(A.iI)
a6=t.bV
r=B.m([],a6)
for(a7=s.p2,a8=a7.length,a9=0;a9<a7.length;a7.length===a8||(0,B.Z)(a7),++a9){q=a7[a9]
J.bN(r,B.my(s,q,"stash",c4))}p=r
o=B.m([],a6)
n=new B.ji(c7,p,s,o)
r=s.ok
r===$&&B.N()
n.$2(r,"active")
if(s.p1!=null){r=s.p1
r.toString
n.$2(r,"nest")}for(r=s.x2,a7=r.length,a9=0;a9<r.length;r.length===a7||(0,B.Z)(r),++a9){m=r[a9]
n.$2(m,"sanctuary")}for(r=s.b1,a7=r.length,a9=0;a9<r.length;r.length===a7||(0,B.Z)(r),++a9){l=r[a9]
n.$2(l,"released")}k=s.c1()
r=s.ok
r===$&&B.N()
if(r.f===A.h)r=c4
else{r=s.ok
r===$&&B.N()
r=r.a}a7=s.ok
a7===$&&B.N()
a7=a7.d
a8=s.ok
a8===$&&B.N()
b0=t.N
b1=t.S
a8=B.V(["coins",a7,"gems",a8.e],b0,b1)
a7=t.z
j=B.bK(B.cp(k,A.p_),b0,a7)
b2=s.p3.c.H()
i=B.n(b0,b1)
for(b1=t.p,a9=0;a9<5;++a9){h=A.aw[a9]
b3=h.b
b4=s.p3.f.h(0,b1.a(h).b)
if(b4==null)b4=0
J.cG(i,b3,b4)}J.cG(j,"altar",B.V(["wallet",b2,"crafted",i,"totalReturned",s.p3.e],b0,t.K))
i=B.cp(k,A.to)
g=B.bK(B.cp(k,A.uV),b0,a7)
f=B.m([],a6)
for(b1=s.aw,b2=b1.length,a9=0;a9<b1.length;b1.length===b2||(0,B.Z)(b1),++a9){e=b1[a9]
b3=e
J.bN(f,B.V(["itemId",b3.a,"roomId",b3.b,"x",b3.c,"y",b3.d,"scale",b3.e],b0,a7))}J.cG(g,"placements",f)
f=B.cp(k,A.y0)
d=B.bK(B.cp(k,A.up),b0,a7)
c=B.m([],t.ke)
for(b1=s.a3,b2=b1.length,b3=t.X,a9=0;a9<b1.length;b1.length===b2||(0,B.Z)(b1),++a9){b=b1[a9]
b4=b.a
b5=b.b
b6=b.c
b7=b.d.am().K()
b8=b.e.am().K()
b9=b.f
c0=b.w
c1=b.x
c2=b.y
if(b.f===A.aG){c3=b.r
c3=c3==null?c4:c3.b}else c3=c4
J.bN(c,B.V(["id",b4,"adventureId",b5,"dragonId",b6,"startedAt",b7,"endsAt",b8,"status",b9.b,"participantCount",c0,"specialEventId",c1,"specialEventKey",c2,"rewardTier",c3],b0,b3))}J.cG(d,"runs",c)
a=B.bK(B.cp(k,A.p4),b0,a7)
a0=B.m([],a6)
for(c=s.ab,b1=c.length,a9=0;a9<c.length;c.length===b1||(0,B.Z)(c),++a9){a1=c[a9]
J.bN(a0,B.cp(a1.H(),A.rU))}J.cG(a,"offers",a0)
a2=B.m([],a6)
for(c=s.bk,a0=c.length,a9=0;a9<c.length;c.length===a0||(0,B.Z)(c),++a9){a3=c[a9]
J.bN(a2,B.q_(s,a3))}a4=B.m([],a6)
for(c=s.aD,a0=c.length,a9=0;a9<c.length;c.length===a0||(0,B.Z)(c),++a9){a5=c[a9]
J.bN(a4,B.cp(a5.H(),A.FI))}r=B.V(["projectionVersion",1,"activeDragonId",r,"wallet",a8,"eggs",p,"dragons",o,"inventory",j,"collection",i,"house",g,"progress",f,"adventures",d,"trials",a,"presentations",a2,"activities",a4],b0,a7)
return r}finally{s.bd()}},
my(a1,a2,a3,a4){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c=null,b=a2.a,a=B.dn(a1,b).aJ(a2.ax),a0=a.aJ(new B.aP(!1,0,a2.as||a2.b==="sinisterra",!1,!1,!1))
a=a2.Q
s=a==null
r=s?c:A.aS.h(0,a)
if(r==null)r=a2.gef()?B.oG(a2.b):c
q=a2.b
p=q==="sinisterra"
if(p)o="sinister"
else o=a2.gef()?"special":"ordinary"
n=r==null?c:r.a
m=a2.c.am().K()
l=a4==null?c:a4.am().K()
k=a3==="stash"?B.nE(a1,b):"egg_in_nest"
j=t.N
i=B.n(j,j)
for(p=!p,h=0;h<2;++h){g=A.CW[h]
f=$.h9()
e=f.h(0,q)
if(e==null)e=A.b.gM(A.a2)
d=s?c:A.aS.h(0,a)
if(d==null){if(s){f=f.h(0,q)
f=(f==null?A.b.gM(A.a2):f).cx&&p}else f=!0
f=f?B.oG(q):c}else f=d
i.j(0,g,B.pB(a1,new B.bF(g),e,f))}a=a0.f
s=a?q:c
a=a0.e||a?B.ci(q).ax.b:c
q=a0.d?a2.r.b:c
p=a0.c?a2.w.b:c
return B.V(["id",b,"location",a3,"kind",o,"specialEggId",n,"acquiredAt",m,"startedAt",l,"incubationSeconds",a2.y,"xp",a2.at,"tagged",a0.a,"returnBlockReason",k,"hints",i,"lineageId",s,"rarity",a,"lawAxis",q,"moralAxis",p],j,t.z)},
q_(a,b){var s,r,q,p=t.N,o=B.n(p,t.z)
o.j(0,"id",b.a)
s=b.b
o.j(0,"type",s.b)
o.j(0,"createdAt",b.c.am().K())
o.j(0,"sortAt",b.d.am().K())
o.j(0,"dragonId",b.e)
o.j(0,"achievementId",b.f)
o.j(0,"previousStageKey",b.r)
if(s===A.cb){p=B.n(p,t.dZ)
for(s=b.w,r=0;r<2;++r){q=A.Ir[r]
p.j(0,q,B.q0(a,s,q))}o.j(0,"trade",p)}return o},
q0(a,b,c){var s,r,q=null,p=b.h(0,c+"Kind"),o=J.cD(p)
if(o.ag(p,"egg")){s=b.h(0,c+"Data")
if(!t.P.b(s)||typeof s.h(0,"id")!="string")return q
return B.V(["kind","egg","egg",B.my(a,B.mr(s),"trade",q)],t.N,t.z)}if(o.ag(p,"chest")||o.ag(p,"relic")){r=b.h(0,c+"Key")
return typeof r=="string"?B.V(["kind",p,"catalogId",r],t.N,t.z):q}return q},
pY(a,b){var s,r,q=[a.h(0,"pet"),a.h(0,"incubatingEgg")],p=t.g,o=p.a(a.h(0,"sanctuaryDragons"))
if(o!=null)A.b.A(q,o)
p=p.a(a.h(0,"releasedDragons"))
if(p!=null)A.b.A(q,p)
p=q.length
o=t.P
s=0
for(;s<q.length;q.length===p||(0,B.Z)(q),++s){r=q[s]
if(o.b(r)&&J.F(r.h(0,"id"),b))return r}return null},
cp(a,b){var s,r,q,p=B.n(t.N,t.z)
for(s=b.length,r=0;r<s;++r){q=b[r]
p.j(0,q,a.h(0,q))}return p},
pZ(){return B.aX(B.bv("Projection cannot create identities"))},
ji:function ji(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
fV:function fV(){},
mz(a,b){var s,r,q,p,o,n,m,l="incubatingEgg",k=t.N,j=B.n(k,t.P),i=new B.jj(j)
for(s=0;s<2;++s)i.$1(a.h(0,A.GX[s]))
for(r=t.g,s=0;s<3;++s){q=r.a(a.h(0,A.bh[s]))
q=J.at(q==null?A.cl:q)
while(q.l())i.$1(q.gu())}p=new B.jk(j)
k=B.bK(a,k,t.z)
k.A(0,b)
k.j(0,"pet",p.$1(b.h(0,"pet")))
k.j(0,l,b.h(0,l)==null?null:p.$1(b.h(0,l)))
for(r=t.j,q=t.bV,s=0;s<3;++s){o=A.bh[s]
n=B.m([],q)
for(m=J.at(r.a(b.h(0,o)));m.l();)n.push(p.$1(m.gu()))
k.j(0,o,n)}return k},
jj:function jj(a){this.a=a},
jk:function jk(a){this.a=a},
tr(a,b,c,d){var s
if(a!==b)s=a.a===b.a&&new B.y(a,B.e(a).i("y<1,2>")).aO(0,new B.mb(b,c,d))
else s=!0
return s},
mb:function mb(a,b,c){this.a=a
this.b=b
this.c=c},
eW:function eW(){},
l8(a,b){var s=new B.en(A.CV)
s.ey(a,b)
return s},
en:function en(a){var _=this
_.b=_.a=$
_.c=a
_.e=_.d=0},
l9:function l9(){},
bF:function bF(a){this.a=a},
ty(a,b){var s,r=A.f.h(0,b),q=A.Ml.h(0,a)
if(q==null)q=A.Mm.h(0,a)
if(q==null)q=A.Mj.h(0,a)
if(q==null)q=A.Lw.h(0,a)
if(q==null)q=A.Lz.h(0,a)
s=q==null?A.Mk.h(0,a):q
if(s==null)s=A.Mc.h(0,a)
if(r==null)return null
if(s!=null){if(r>>>0!==r||r>=6)return B.b(s,r)
return s[r]}return B.rQ(a,b)},
rQ(a1,a2){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a=new B.lV(a1),a0=a.$1(B.L("^NEW (.+) RECORD!$"))
if(a0!=null){a=["NEUER REKORD F\xdcR "+a0+"!","\xa1NUEVO R\xc9CORD DE "+a0+"!","NOUVEAU RECORD DE "+a0+" !","NUOVO RECORD DI "+a0+"!","NOVO RECORDE DE "+a0+"!",a0+"\u306e\u65b0\u8a18\u9332\uff01"]
s=A.f.h(0,a2)
s.toString
if(!(s<6))return B.b(a,s)
return a[s]}a0=a.$1(B.L("^(\\d+) treasures revealed$"))
if(a0!=null){a=[a0+" Sch\xe4tze enth\xfcllt",a0+" tesoros revelados",a0+" tr\xe9sors r\xe9v\xe9l\xe9s",a0+" tesori rivelati",a0+" tesouros revelados",a0+"\u500b\u306e\u5b9d\u3092\u516c\u958b"]
s=A.f.h(0,a2)
s.toString
if(!(s<6))return B.b(a,s)
return a[s]}a0=a.$1(B.L("^(.+) already has a place in the house\\.$"))
if(a0!=null){a=[a0+" hat bereits einen Platz im Haus.",a0+" ya tiene un lugar en la casa.",a0+" a d\xe9j\xe0 une place dans la maison.",a0+" ha gi\xe0 un posto nella casa.",a0+" j\xe1 tem um lugar na casa.",a0+" \u306f\u3059\u3067\u306b\u5bb6\u306b\u7f6e\u304b\u308c\u3066\u3044\u307e\u3059\u3002"]
s=A.f.h(0,a2)
s.toString
if(!(s<6))return B.b(a,s)
return a[s]}a0=a.$1(B.L("^(.+) now has a place in the sanctuary\\.$"))
if(a0!=null){a=[a0+" hat nun einen Platz im Refugium.",a0+" ya tiene un lugar en el santuario.",a0+" a maintenant une place dans le sanctuaire.",a0+" ora ha un posto nel santuario.",a0+" agora tem um lugar no santu\xe1rio.",a0+" \u3092\u8056\u57df\u306b\u7f6e\u304d\u307e\u3057\u305f\u3002"]
s=A.f.h(0,a2)
s.toString
if(!(s<6))return B.b(a,s)
return a[s]}r=B.L("^(.+) is now in (.+)\\.$").a4(a1)
if(r!=null){a=r.b
s=a.length
if(1>=s)return B.b(a,1)
q=a[1]
if(2>=s)return B.b(a,2)
q=B.z(q)
a=B.z(a[2])
a=[q+" befindet sich jetzt in "+a+".",q+" ahora est\xe1 en "+a+".",q+" se trouve maintenant dans "+a+".",q+" ora si trova in "+a+".",q+" agora est\xe1 em "+a+".",q+" \u3092"+a+"\u306b\u7f6e\u304d\u307e\u3057\u305f\u3002"]
q=A.f.h(0,a2)
q.toString
if(!(q<6))return B.b(a,q)
return a[q]}p=B.L("^(.+) purchased and placed in (.+)!$").a4(a1)
if(p!=null){a=p.b
s=a.length
if(1>=s)return B.b(a,1)
q=a[1]
if(2>=s)return B.b(a,2)
q=B.z(q)
a=B.z(a[2])
a=[q+" gekauft und in "+a+" platziert!","\xa1"+q+" comprado y colocado en "+a+"!",q+" achet\xe9 et plac\xe9 dans "+a+" !",q+" acquistato e posizionato in "+a+"!",q+" comprado e posicionado em "+a+"!",q+" \u3092\u8cfc\u5165\u3057\u3066"+a+"\u306b\u914d\u7f6e\u3057\u307e\u3057\u305f\uff01"]
q=A.f.h(0,a2)
q.toString
if(!(q<6))return B.b(a,q)
return a[q]}o=B.L("^(.+) in the (.+) life stage$").a4(a1)
if(o!=null){a=o.b
s=a.length
if(1>=s)return B.b(a,1)
q=a[1]
if(2>=s)return B.b(a,2)
q=B.z(q)
a=B.z(a[2])
a=[q+" in der Lebensphase "+a,q+" en la etapa "+a,q+" au stade "+a,q+" nella fase "+a,q+" no est\xe1gio "+a,q+"\u3001"+a+"\u6bb5\u968e"]
q=A.f.h(0,a2)
q.toString
if(!(q<6))return B.b(a,q)
return a[q]}n=B.L("^(\\d+) items \xb7 (\\d+) of (\\d+) rooms built$").a4(a1)
if(n!=null){a=n.b
s=a.length
if(1>=s)return B.b(a,1)
q=a[1]
if(2>=s)return B.b(a,2)
m=a[2]
if(3>=s)return B.b(a,3)
q=B.z(q)
m=B.z(m)
a=B.z(a[3])
m=[q+" Gegenst\xe4nde \xb7 "+m+" von "+a+" R\xe4umen gebaut",q+" objetos \xb7 "+m+" de "+a+" habitaciones construidas",q+" objets \xb7 "+m+" pi\xe8ces sur "+a+" construites",q+" oggetti \xb7 "+m+" stanze su "+a+" costruite",q+" itens \xb7 "+m+" de "+a+" c\xf4modos constru\xeddos","\u30a2\u30a4\u30c6\u30e0"+q+"\u500b\u30fb"+a+"\u90e8\u5c4b\u4e2d"+m+"\u90e8\u5c4b\u3092\u5efa\u7bc9"]
a=A.f.h(0,a2)
a.toString
if(!(a<6))return B.b(m,a)
return m[a]}a0=a.$1(B.L("^(.+) placed\\. Tap elsewhere to move it\\.$"))
if(a0!=null){a=[a0+" platziert. Tippe auf eine andere Stelle, um es zu verschieben.",a0+" colocado. Toca otro lugar para moverlo.",a0+" plac\xe9. Touchez ailleurs pour le d\xe9placer.",a0+" posizionato. Tocca altrove per spostarlo.",a0+" posicionado. Toque em outro lugar para mov\xea-lo.",a0+" \u3092\u914d\u7f6e\u3057\u307e\u3057\u305f\u3002\u5225\u306e\u5834\u6240\u3092\u30bf\u30c3\u30d7\u3059\u308b\u3068\u79fb\u52d5\u3067\u304d\u307e\u3059\u3002"]
s=A.f.h(0,a2)
s.toString
if(!(s<6))return B.b(a,s)
return a[s]}a0=a.$1(B.L("^(.+) remaining$"))
if(a0!=null){a=["Noch "+a0,"Quedan "+a0,"Encore "+a0,"Mancano "+a0,"Faltam "+a0,"\u6b8b\u308a"+a0]
s=A.f.h(0,a2)
s.toString
if(!(s<6))return B.b(a,s)
return a[s]}l=B.L("^(\\d+) of (\\d+) collected$").a4(a1)
if(l!=null){a=l.b
s=a.length
if(1>=s)return B.b(a,1)
q=a[1]
if(2>=s)return B.b(a,2)
q=B.z(q)
a=B.z(a[2])
s=q+" de "+a
q=[q+" von "+a+" gesammelt",s+" coleccionados",q+" sur "+a+" collectionn\xe9s",q+" su "+a+" raccolti",s+" coletados",a+"\u500b\u4e2d"+q+"\u500b\u3092\u53ce\u96c6"]
a=A.f.h(0,a2)
a.toString
if(!(a<6))return B.b(q,a)
return q[a]}k=B.L("^(\\d+) / (\\d+) unlocked$").a4(a1)
if(k!=null){a=k.b
s=a.length
if(1>=s)return B.b(a,1)
q=a[1]
if(2>=s)return B.b(a,2)
q=B.z(q)
a=B.z(a[2])
s=q+" / "+a
a=[s+" freigeschaltet",s+" desbloqueados",s+" d\xe9bloqu\xe9s",s+" sbloccati",s+" desbloqueadas","\u89e3\u9664\u6e08\u307f "+q+" / "+a]
q=A.f.h(0,a2)
q.toString
if(!(q<6))return B.b(a,q)
return a[q]}a0=a.$1(B.L("^(\\d+) more coins needed\\.$"))
if(a0!=null){a=["Noch "+a0+" M\xfcnzen ben\xf6tigt.","Faltan "+a0+" monedas.","Il manque "+a0+" pi\xe8ces.","Servono altre "+a0+" monete.","Faltam "+a0+" moedas.","\u3042\u3068"+a0+"\u30b3\u30a4\u30f3\u5fc5\u8981\u3067\u3059\u3002"]
s=A.f.h(0,a2)
s.toString
if(!(s<6))return B.b(a,s)
return a[s]}a0=a.$1(B.L("^(\\d+) more gems needed\\.$"))
if(a0!=null){a=["Noch "+a0+" Edelsteine ben\xf6tigt.","Faltan "+a0+" gemas.","Il manque "+a0+" gemmes.","Servono altre "+a0+" gemme.","Faltam "+a0+" gemas.","\u3042\u3068"+a0+"\u30b8\u30a7\u30e0\u5fc5\u8981\u3067\u3059\u3002"]
s=A.f.h(0,a2)
s.toString
if(!(s<6))return B.b(a,s)
return a[s]}a0=a.$1(B.L("^(\\d+) items shown$"))
if(a0!=null){a=[a0+" Gegenst\xe4nde angezeigt",a0+" objetos mostrados",a0+" objets affich\xe9s",a0+" oggetti mostrati",a0+" itens exibidos",a0+"\u500b\u306e\u30a2\u30a4\u30c6\u30e0\u3092\u8868\u793a"]
s=A.f.h(0,a2)
s.toString
if(!(s<6))return B.b(a,s)
return a[s]}a0=a.$1(B.L("^(.+) is ready for decorating!$"))
if(a0!=null){a=[a0+" kann jetzt eingerichtet werden!","\xa1"+a0+" ya se puede decorar!",a0+" est pr\xeat \xe0 \xeatre d\xe9cor\xe9 !",a0+" \xe8 pronta per essere decorata!",a0+" est\xe1 pronto para decorar!",a0+" \u3092\u98fe\u308c\u308b\u3088\u3046\u306b\u306a\u308a\u307e\u3057\u305f\uff01"]
s=A.f.h(0,a2)
s.toString
if(!(s<6))return B.b(a,s)
return a[s]}a0=a.$1(B.L("^(.+) added to your rewards\\.$"))
if(a0!=null){a=[a0+" wurde deinen Belohnungen hinzugef\xfcgt.",a0+" se a\xf1adi\xf3 a tus recompensas.",a0+" a \xe9t\xe9 ajout\xe9 \xe0 tes r\xe9compenses.",a0+" \xe8 stato aggiunto alle ricompense.",a0+" foi adicionado \xe0s recompensas.",a0+" \u3092\u5831\u916c\u306b\u8ffd\u52a0\u3057\u307e\u3057\u305f\u3002"]
s=A.f.h(0,a2)
s.toString
if(!(s<6))return B.b(a,s)
return a[s]}a0=a.$1(B.L("^A (.+) has hatched!$"))
if(a0!=null){a=["Ein "+a0+" ist geschl\xfcpft!","\xa1Ha nacido un "+a0+"!","Un "+a0+" vient d\u2019\xe9clore !","\xc8 nato un "+a0+"!","Um "+a0+" nasceu!",a0+" \u304c\u5b75\u5316\u3057\u307e\u3057\u305f\uff01"]
s=A.f.h(0,a2)
s.toString
if(!(s<6))return B.b(a,s)
return a[s]}j=B.L("^(.+) evolved into (.+)\\.$").a4(a1)
if(j!=null){a=j.b
s=a.length
if(1>=s)return B.b(a,1)
q=a[1]
if(2>=s)return B.b(a,2)
q=B.z(q)
a=B.z(a[2])
a=[q+" hat sich zu "+a+" entwickelt.",q+" evolucion\xf3 a "+a+".",q+" a \xe9volu\xe9 en "+a+".",q+" si \xe8 evoluto in "+a+".",q+" evoluiu para "+a+".",q+" \u306f"+a+"\u3078\u9032\u5316\u3057\u307e\u3057\u305f\u3002"]
q=A.f.h(0,a2)
q.toString
if(!(q<6))return B.b(a,q)
return a[q]}i=B.L("^Acquired (.+) \xb7 identity fixed$").a4(a1)
if(i!=null){a=i.b
if(1>=a.length)return B.b(a,1)
a=B.z(a[1])
a=["Erhalten "+a+" \xb7 Identit\xe4t festgelegt","Obtenido "+a+" \xb7 identidad fijada","Obtenu "+a+" \xb7 identit\xe9 fix\xe9e","Ottenuto "+a+" \xb7 identit\xe0 fissata","Obtido "+a+" \xb7 identidade definida",a+"\u306b\u5165\u624b\u30fb\u4e2d\u8eab\u306f\u78ba\u5b9a\u6e08\u307f"]
s=A.f.h(0,a2)
s.toString
if(!(s<6))return B.b(a,s)
return a[s]}a0=a.$1(B.L("^Add a floor \xb7 (.+) coins$"))
if(a0!=null){a=["Etage hinzuf\xfcgen \xb7 "+a0+" M\xfcnzen","A\xf1adir piso \xb7 "+a0+" monedas","Ajouter un \xe9tage \xb7 "+a0+" pi\xe8ces","Aggiungi piano \xb7 "+a0+" monete","Adicionar andar \xb7 "+a0+" moedas","\u968e\u3092\u8ffd\u52a0\u30fb"+a0+"\u30b3\u30a4\u30f3"]
s=A.f.h(0,a2)
s.toString
if(!(s<6))return B.b(a,s)
return a[s]}a0=a.$1(B.L("^Build this room for (\\d+) star coins\\? Furniture and progress stay exactly where they are\\.$"))
if(a0!=null){a=["Diesen Raum f\xfcr "+a0+" Sternenm\xfcnzen bauen? M\xf6bel und Fortschritt bleiben genau erhalten.","\xbfConstruir esta habitaci\xf3n por "+a0+" monedas estelares? Los muebles y el progreso se conservan.","Construire cette pi\xe8ce pour "+a0+" pi\xe8ces \xe9toil\xe9es ? Les meubles et la progression sont conserv\xe9s.","Costruire questa stanza per "+a0+" monete stellari? Mobili e progressi restano invariati.","Construir este c\xf4modo por "+a0+" moedas estelares? M\xf3veis e progresso permanecem intactos.","\u30b9\u30bf\u30fc\u30b3\u30a4\u30f3"+a0+"\u679a\u3067\u3053\u306e\u90e8\u5c4b\u3092\u5efa\u3066\u307e\u3059\u304b\uff1f\u5bb6\u5177\u3068\u9032\u884c\u72b6\u6cc1\u306f\u305d\u306e\u307e\u307e\u6b8b\u308a\u307e\u3059\u3002"]
s=A.f.h(0,a2)
s.toString
if(!(s<6))return B.b(a,s)
return a[s]}a0=a.$1(B.L("^CRACK (.+)$"))
if(a0!=null){a="CRAC "+a0
a=["KNACK "+a0,a,a,"CRACK "+a0,a,"\u30d4\u30b7\u30c3 "+a0]
s=A.f.h(0,a2)
s.toString
if(!(s<6))return B.b(a,s)
return a[s]}a0=a.$1(B.L("^Claim (.+)$"))
if(a0!=null){a=[a0+" abholen","Reclamar "+a0,"R\xe9cup\xe9rer "+a0,"Riscatta "+a0,"Coletar "+a0,a0+"\u3092\u53d7\u3051\u53d6\u308b"]
s=A.f.h(0,a2)
s.toString
if(!(s<6))return B.b(a,s)
return a[s]}a0=a.$1(B.L("^Discard one (.+)\\?$"))
if(a0!=null){a=["Eine "+a0+" verwerfen?","\xbfDescartar un "+a0+"?","Jeter un "+a0+" ?","Scartare un "+a0+"?","Descartar um "+a0+"?",a0+"\u30921\u3064\u7834\u68c4\u3057\u307e\u3059\u304b\uff1f"]
s=A.f.h(0,a2)
s.toString
if(!(s<6))return B.b(a,s)
return a[s]}h=B.L("^Dragons (\\d+)$").a4(a1)
if(h!=null){a=h.b
if(1>=a.length)return B.b(a,1)
a=B.z(a[1])
a=["Drachen "+a,"Dragones "+a,"Dragons "+a,"Draghi "+a,"Drag\xf5es "+a,"\u30c9\u30e9\u30b4\u30f3 "+a]
s=A.f.h(0,a2)
s.toString
if(!(s<6))return B.b(a,s)
return a[s]}g=B.L("^Dragon families (\\d+)/42$").a4(a1)
if(g!=null){a=g.b
if(1>=a.length)return B.b(a,1)
a=B.z(a[1])
a=["Drachenfamilien "+a+"/42","Familias de dragones "+a+"/42","Familles de dragons "+a+"/42","Famiglie di draghi "+a+"/42","Fam\xedlias de drag\xf5es "+a+"/42","\u30c9\u30e9\u30b4\u30f3\u306e\u7cfb\u7d71 "+a+"/42"]
s=A.f.h(0,a2)
s.toString
if(!(s<6))return B.b(a,s)
return a[s]}f=B.L("^Dragons (\\d+)/42$").a4(a1)
if(f!=null){a=f.b
if(1>=a.length)return B.b(a,1)
a=B.z(a[1])
a=["Drachen "+a+"/42","Dragones "+a+"/42","Dragons "+a+"/42","Draghi "+a+"/42","Drag\xf5es "+a+"/42","\u30c9\u30e9\u30b4\u30f3 "+a+"/42"]
s=A.f.h(0,a2)
s.toString
if(!(s<6))return B.b(a,s)
return a[s]}a0=a.$1(B.L("^Hatches in (.+)$"))
if(a0!=null){a=["Schl\xfcpft in "+a0,"Eclosiona en "+a0,"\xc9closion dans "+a0,"Schiusa tra "+a0,"Choca em "+a0,"\u5b75\u5316\u307e\u3067"+a0]
s=A.f.h(0,a2)
s.toString
if(!(s<6))return B.b(a,s)
return a[s]}a0=a.$1(B.L("^GitHub could not be checked \\(code (\\d+)\\)\\.$"))
if(a0!=null){a=["GitHub konnte nicht gepr\xfcft werden (Code "+a0+").","No se pudo comprobar GitHub (c\xf3digo "+a0+").","Impossible de v\xe9rifier GitHub (code "+a0+").","Impossibile controllare GitHub (codice "+a0+").","N\xe3o foi poss\xedvel verificar o GitHub (c\xf3digo "+a0+").","GitHub\u3092\u78ba\u8a8d\u3067\u304d\u307e\u305b\u3093\u3067\u3057\u305f\uff08\u30b3\u30fc\u30c9"+a0+"\uff09\u3002"]
s=A.f.h(0,a2)
s.toString
if(!(s<6))return B.b(a,s)
return a[s]}e=B.L("^Level (\\d+) \xb7 (\\d+) coins$").a4(a1)
if(e!=null){a=e.b
s=a.length
if(1>=s)return B.b(a,1)
q=a[1]
if(2>=s)return B.b(a,2)
q=B.z(q)
a=B.z(a[2])
a=["Level "+q+" \xb7 "+a+" M\xfcnzen","Nivel "+q+" \xb7 "+a+" monedas","Niveau "+q+" \xb7 "+a+" pi\xe8ces","Livello "+q+" \xb7 "+a+" monete","N\xedvel "+q+" \xb7 "+a+" moedas","\u30ec\u30d9\u30eb"+q+"\u30fb"+a+"\u30b3\u30a4\u30f3"]
q=A.f.h(0,a2)
q.toString
if(!(q<6))return B.b(a,q)
return a[q]}a0=a.$1(B.L("^Next form: (.+)$"))
if(a0!=null){a=["N\xe4chste Form: "+a0,"Siguiente forma: "+a0,"Forme suivante : "+a0,"Forma successiva: "+a0,"Pr\xf3xima forma: "+a0,"\u6b21\u306e\u5f62\u614b\uff1a"+a0]
s=A.f.h(0,a2)
s.toString
if(!(s<6))return B.b(a,s)
return a[s]}d=B.L("^Pack (\\d+) of 6$").a4(a1)
if(d!=null){a=d.b
if(1>=a.length)return B.b(a,1)
a=B.z(a[1])
a=["Paket "+a+" von 6","Paquete "+a+" de 6","Lot "+a+" sur 6","Pacchetto "+a+" di 6","Pacote "+a+" de 6","\u30d1\u30c3\u30af"+a+"\uff0f6"]
s=A.f.h(0,a2)
s.toString
if(!(s<6))return B.b(a,s)
return a[s]}a0=a.$1(B.L("^(\\d+) players$"))
if(a0!=null){a=[a0+" Spieler",a0+" jugadores",a0+" joueurs",a0+" giocatori",a0+" jogadores",a0+"\u4eba\u306e\u30d7\u30ec\u30a4\u30e4\u30fc"]
s=A.f.h(0,a2)
s.toString
if(!(s<6))return B.b(a,s)
return a[s]}a0=a.$1(B.L("^Release (.+)\\?$"))
if(a0!=null){a=[a0+" freilassen?","\xbfLiberar a "+a0+"?","Lib\xe9rer "+a0+" ?","Liberare "+a0+"?","Libertar "+a0+"?",a0+"\u3092\u653e\u3057\u307e\u3059\u304b\uff1f"]
s=A.f.h(0,a2)
s.toString
if(!(s<6))return B.b(a,s)
return a[s]}a0=a.$1(B.L("^Remove (.+)\\?$"))
if(a0!=null){a=[a0+" entfernen?","\xbfQuitar "+a0+"?","Retirer "+a0+" ?","Rimuovere "+a0+"?","Remover "+a0+"?",a0+"\u3092\u53d6\u308a\u5916\u3057\u307e\u3059\u304b\uff1f"]
s=A.f.h(0,a2)
s.toString
if(!(s<6))return B.b(a,s)
return a[s]}a0=a.$1(B.L("^Selected: (.+)\\. Tap the room to place it\\.$"))
if(a0!=null){a=["Ausgew\xe4hlt: "+a0+". Tippe zum Platzieren auf den Raum.","Seleccionado: "+a0+". Toca la habitaci\xf3n para colocarlo.","S\xe9lection : "+a0+". Touchez la pi\xe8ce pour le placer.","Selezionato: "+a0+". Tocca la stanza per posizionarlo.","Selecionado: "+a0+". Toque no c\xf4modo para posicion\xe1-lo.","\u9078\u629e\u4e2d\uff1a"+a0+"\u3002\u90e8\u5c4b\u3092\u30bf\u30c3\u30d7\u3057\u3066\u914d\u7f6e\u3057\u307e\u3059\u3002"]
s=A.f.h(0,a2)
s.toString
if(!(s<6))return B.b(a,s)
return a[s]}a0=a.$1(B.L("^Talk to (.+)$"))
if(a0!=null){a=["Mit "+a0+" sprechen","Hablar con "+a0,"Parler \xe0 "+a0,"Parla con "+a0,"Falar com "+a0,a0+"\u306b\u8a71\u3057\u304b\u3051\u308b"]
s=A.f.h(0,a2)
s.toString
if(!(s<6))return B.b(a,s)
return a[s]}a0=a.$1(B.L("^(.+) has returned$"))
if(a0!=null){a=[a0+" ist zur\xfcckgekehrt",a0+" ha regresado",a0+" est de retour",a0+" \xe8 tornato",a0+" retornou",a0+" \u304c\u5e30\u9084\u3057\u307e\u3057\u305f"]
s=A.f.h(0,a2)
s.toString
if(!(s<6))return B.b(a,s)
return a[s]}a0=a.$1(B.L("^You need (\\d+) more coins\\.$"))
if(a0!=null){a=["Du brauchst noch "+a0+" M\xfcnzen.","Necesitas "+a0+" monedas m\xe1s.","Il te faut encore "+a0+" pi\xe8ces.","Ti servono altre "+a0+" monete.","Voc\xea precisa de mais "+a0+" moedas.","\u3042\u3068"+a0+"\u30b3\u30a4\u30f3\u5fc5\u8981\u3067\u3059\u3002"]
s=A.f.h(0,a2)
s.toString
if(!(s<6))return B.b(a,s)
return a[s]}a0=a.$1(B.L("^Your sanctuary reaches level (\\d+) before this room can be built\\.$"))
if(a0!=null){a=["Dein Refugium muss Level "+a0+" erreichen, bevor dieser Raum gebaut werden kann.","Tu santuario debe alcanzar el nivel "+a0+" para construir esta habitaci\xf3n.","Ton sanctuaire doit atteindre le niveau "+a0+" avant de construire cette pi\xe8ce.","Il santuario deve raggiungere il livello "+a0+" prima di costruire questa stanza.","Seu santu\xe1rio precisa alcan\xe7ar o n\xedvel "+a0+" antes de construir este c\xf4modo.","\u8056\u57df\u304c\u30ec\u30d9\u30eb"+a0+"\u306b\u306a\u308b\u3068\u3001\u3053\u306e\u90e8\u5c4b\u3092\u5efa\u3066\u3089\u308c\u307e\u3059\u3002"]
s=A.f.h(0,a2)
s.toString
if(!(s<6))return B.b(a,s)
return a[s]}c=B.L("^(\\d+) / (\\d+) roaming \xb7 maximum 3 per room$").a4(a1)
if(c!=null){a=c.b
s=a.length
if(1>=s)return B.b(a,1)
q=a[1]
q.toString
if(2>=s)return B.b(a,2)
a=a[2]
a.toString
a=q+" / "+a
a=[a+" unterwegs \xb7 maximal 3 pro Raum",a+" deambulando \xb7 m\xe1ximo 3 por habitaci\xf3n",a+" en libert\xe9 \xb7 maximum 3 par pi\xe8ce",a+" in giro \xb7 massimo 3 per stanza",a+" circulando \xb7 m\xe1ximo de 3 por c\xf4modo",a+" \u4f53\u304c\u5de1\u56de\u4e2d\u30fb1\u90e8\u5c4b\u306b\u3064\u304d\u6700\u59273\u4f53"]
q=A.f.h(0,a2)
q.toString
if(!(q<6))return B.b(a,q)
return a[q]}b=B.L("^Owned: (\\d+) \xb7 shop-bought: (\\d+) \\(untradeable\\)$").a4(a1)
if(b!=null){a=b.b
s=a.length
if(1>=s)return B.b(a,1)
q=a[1]
q.toString
if(2>=s)return B.b(a,2)
a=a[2]
a.toString
a=["Im Besitz: "+q+" \xb7 im Shop gekauft: "+a+" (nicht handelbar)","En propiedad: "+q+" \xb7 compradas en la tienda: "+a+" (no intercambiables)","Poss\xe9d\xe9es : "+q+" \xb7 achet\xe9es en boutique : "+a+" (non \xe9changeables)","Posseduti: "+q+" \xb7 acquistati nel negozio: "+a+" (non scambiabili)","Possu\xeddas: "+q+" \xb7 compradas na loja: "+a+" (n\xe3o negoci\xe1veis)","\u6240\u6301\u6570\uff1a"+q+"\u30fb\u30b7\u30e7\u30c3\u30d7\u8cfc\u5165\uff1a"+a+"\uff08\u4ea4\u63db\u4e0d\u53ef\uff09"]
q=A.f.h(0,a2)
q.toString
if(!(q<6))return B.b(a,q)
return a[q]}a0=a.$1(B.L("^(.+) added to your Inventory\\. This copy is untradeable\\.$"))
if(a0!=null){a=[a0+" wurde deinem Inventar hinzugef\xfcgt. Dieses Exemplar ist nicht handelbar.",a0+" se a\xf1adi\xf3 a tu inventario. Esta copia no se puede intercambiar.",a0+" a \xe9t\xe9 ajout\xe9 \xe0 ton inventaire. Cet exemplaire n\u2019est pas \xe9changeable.",a0+" \xe8 stato aggiunto al tuo inventario. Questa copia non \xe8 scambiabile.",a0+" foi adicionado ao seu invent\xe1rio. Esta c\xf3pia n\xe3o \xe9 negoci\xe1vel.",a0+" \u3092\u30a4\u30f3\u30d9\u30f3\u30c8\u30ea\u306b\u8ffd\u52a0\u3057\u307e\u3057\u305f\u3002\u3053\u306e\u500b\u4f53\u306f\u4ea4\u63db\u3067\u304d\u307e\u305b\u3093\u3002"]
s=A.f.h(0,a2)
s.toString
if(!(s<6))return B.b(a,s)
return a[s]}return null},
lV:function lV(a){this.a=a},
bC:function bC(a){this.a=a},
lX:function lX(){},
cH:function cH(a,b){this.a=a
this.b=b},
Q:function Q(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.f=d},
ph(a){var s,r,q,p,o,n,m,l,k,j
t.P.a(a)
s=a.h(0,"message")
r=typeof s=="string"?s:null
if(r==null)r="Something happened in the nest."
q=B.db(A.xo,a.h(0,"code"),t.lD)
p=q==null?A.aE:q
s=B.cj(a.h(0,"id"))
if(s==null)s=A.a.v(1000*Date.now())
o=a.h(0,"createdAt")
o=typeof o=="string"?o:null
o=B.a9(o==null?"":o)
if(o==null)o=new B.ac(Date.now(),0,!1)
n=B.db(A.DQ,a.h(0,"type"),t.kr)
if(n==null)n=B.pi(p)
m=a.h(0,"subject")
m=typeof m=="string"?m:null
l=a.h(0,"xp")
l=typeof l=="number"?A.c.k(l):0
k=a.h(0,"coins")
k=typeof k=="number"?A.c.k(k):0
j=a.h(0,"gems")
return new B.b3(s,r,o,n,p,m,l,k,typeof j=="number"?A.c.k(j):0)},
pi(a){var s
A:{if(A.aY===a){s=A.b6
break A}if(A.L===a){s=A.y
break A}if(A.b4===a||A.bK===a||A.b5===a||A.b_===a){s=A.ab
break A}if(A.aZ===a||A.b0===a){s=A.y
break A}if(A.bJ===a||A.aF===a||A.b1===a||A.b2===a||A.b3===a||A.aE===a){s=A.ai
break A}s=null}return s},
bP:function bP(a,b){this.a=a
this.b=b},
az:function az(a,b){this.a=a
this.b=b},
b3:function b3(a,b,c,d,e,f,g,h,i){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.x=i},
n7(a,b){var s,r,q,p,o=A.Md.h(0,a)
for(s=o.length,r=0,q=0;q<s;++q){p=o[q]
r+=p.b
if(b<r)return p.a}return A.b.gfO(o).a},
eT(a,b,c,d,e,f,g,h,i,j,k,l,m){return new B.aA(e,f,k,l,c,m,d,j,g,i,!1,!1,A.ba,null,!1)},
t8(a,b){var s,r,q,p,o,n=B.q(b),m=n.i("K<1,c>")
n=B.k(new B.K(b,n.i("c(1)").a(new B.m_(a)),m),m.i("a4.E"))
n.$flags=1
s=n
r=s.length===0?0:A.b.gM(s)
q=s.length===0?0:A.a.dr(A.b.ej(s,new B.m0()),s.length)
p=A.b.aI(b,0,new B.m1(),t.S)
n=a.b
switch(n.a){case 0:m=B.ah(0,0,0,0,0,r)
break
case 1:m=B.ah(0,0,0,0,r,0)
break
case 2:m=B.ah(0,0,0,0,r*15,0)
break
case 3:m=B.ah(0,q,0,0,0,0)
break
case 4:m=a.at?new B.a_(A.a.cq(a.ch.a*p)):A.ba
break
default:m=null}A:{if(A.q===n){n=A.iu
break A}if(A.o===n){n=A.aM
break A}if(A.z===n||A.W===n){n=A.R
break A}if(A.A===n){n=a.CW
if(n==null)n=a.r
break A}n=null}m=a.r.a-m.a
o=new B.a_(m)
return m<n.a?n:o},
pk(a){return B.pj(t.P.a(a))},
pj(a){var s,r,q,p,o,n,m,l=B.b0(a.h(0,"id"))
if(l==null)l=""
s=B.b0(a.h(0,"adventureId"))
if(s==null)s=""
r=B.b0(a.h(0,"dragonId"))
if(r==null)r=""
q=B.b0(a.h(0,"startedAt"))
q=B.a9(q==null?"":q)
if(q==null)q=new B.ac(Date.now(),0,!1)
p=B.b0(a.h(0,"endsAt"))
p=B.a9(p==null?"":p)
if(p==null)p=new B.ac(Date.now(),0,!1)
o=A.b.a7(A.mW,new B.hj(a),new B.hk())
n=new B.aB(A.ax,t.fQ)
n=n.a7(n,new B.hl(a),new B.hm())
m=B.dI(a.h(0,"participantCount"))
m=m==null?null:A.c.k(m)
if(m==null)m=1
return new B.b4(l,s,r,q,p,o,n,m,B.b0(a.h(0,"specialEventId")),B.b0(a.h(0,"specialEventKey")))},
mf(a){var s,r
for(s=0;s<6;++s){r=A.bf[s]
if(r.a===a)return r}return null},
oG(a){var s,r
for(s=A.aS.gaZ(),s=s.gq(s);s.l();){r=s.gu()
if(r.e===a)return r}return null},
bp:function bp(a,b){this.a=a
this.b=b},
bq:function bq(a,b){this.a=a
this.b=b},
aG:function aG(a,b){this.a=a
this.b=b},
dS:function dS(){},
aA:function aA(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.r=e
_.w=f
_.x=g
_.y=h
_.Q=i
_.as=j
_.at=k
_.ax=l
_.ch=m
_.CW=n
_.cy=o},
m_:function m_(a){this.a=a},
m0:function m0(){},
m1:function m1(){},
b4:function b4(a,b,c,d,e,f,g,h,i,j){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.x=i
_.y=j},
hj:function hj(a){this.a=a},
hk:function hk(){},
hl:function hl(a){this.a=a},
hm:function hm(){},
cx:function cx(a,b,c,d,e,f){var _=this
_.c=a
_.d=b
_.e=c
_.f=d
_.r=e
_.w=f},
ca:function ca(a,b,c,d,e){var _=this
_.a=a
_.e=b
_.f=c
_.w=d
_.x=e},
c9:function c9(a,b,c,d,e){var _=this
_.a=a
_.c=b
_.r=c
_.w=d
_.x=e},
c8:function c8(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.x=i
_.y=j
_.z=k
_.Q=l
_.as=m
_.cx=n
_.db=o
_.dx=p},
hg:function hg(){},
hh:function hh(){},
hf:function hf(){},
he:function he(){},
hi:function hi(){},
fe:function fe(a,b){this.a=a
this.b=b},
po(a,b){var s
switch(a.a){case 0:s="Wooden Chest"
break
case 1:s="Silver Chest"
break
case 2:s="Gold Chest"
break
case 3:s="Dragon Chest"
break
case 4:s="Mythical Chest"
break
case 5:s="Sinister Chest"
break
case 6:s="Special Chest"
break
case 7:s="Portrait Chest"
break
case 8:s="Title Chest"
break
case 9:s="Music Chest"
break
default:s=null}return s},
av:function av(a,b){this.a=a
this.b=b},
bD:function bD(a,b,c,d,e,f,g,h,i,j,k,l,m){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.x=i
_.y=j
_.z=k
_.Q=l
_.as=m},
dU:function dU(a,b){this.a=a
this.b=b},
th(a){var s=B.dy(a)*60+B.fB(a)
if(s<300)return A.ja
if(s<420)return A.jb
if(s<600)return A.jc
if(s<1020)return A.jd
if(s<1140)return A.cc
if(s<1260)return A.je
return A.jf},
bG:function bG(a,b){this.a=a
this.b=b},
f1(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p){var s=l==null?B.iH(c):l,r=!m,q=!r||h==="sinisterra"?A.D:i
r=!r||h==="sinisterra"
return new B.ao(d,h,a,c,k,s,g,q,n,A.a.t(f==null?e*60:f,60,1209600),r,o,j,p,b)},
px(a){return B.mr(t.P.a(a))},
mr(a2){var s,r,q,p,o,n,m,l,k,j,i,h,g,f=2147483647,e="spectral",d="prismatic",c="sinister",b="moralAxisKnown",a=a2.h(0,"hatchSeed"),a0=A.a.k(A.a.t(typeof a=="number"?A.c.k(a):0,0,f)),a1=a2.h(0,"lineageId")
a1=typeof a1=="string"?a1:null
a=B.cj(a2.h(0,"id"))
if(a==null)a="egg-"+a0
if(A.b.N(A.a2,new B.ht(a1))){a1.toString
s=a1}else{s=$.hb()
r=s.length
q=a0%r
if(!(q>=0&&q<r))return B.b(s,q)
q=s[q].a
s=q}r=a2.h(0,"acquiredAt")
r=typeof r=="string"?r:null
r=B.a9(r==null?"":r)
if(r==null)r=new B.ac(Date.now(),0,!1)
q=B.mw(a2)
if(!(B.a5(a2.h(0,e))&&B.ab(a2.h(0,e))))p=B.a5(a2.h(0,d))&&B.ab(a2.h(0,d))
else p=!0
o=B.db(A.J,a2.h(0,"lawAxis"),t.bK)
if(o==null){o=a0%3
if(!(o>=0&&o<3))return B.b(A.J,o)
o=A.J[o]}n=B.db(A.a1,a2.h(0,"moralAxis"),t.ms)
if(n==null){n=A.a.G(a0,3)%3
if(!(n>=0&&n<3))return B.b(A.a1,n)
n=A.a1[n]}m=B.dI(a2.h(0,"sizeFactor"))
if(m==null)m=null
m=A.c.t(m==null?1:m,0.5,1.5)
l=B.py(a2)
k=B.a5(a2.h(0,c))&&B.ab(a2.h(0,c))
j=B.cj(a2.h(0,"specialEggId"))
i=B.a5(a2.h(0,b))&&B.ab(a2.h(0,b))
h=a2.h(0,"xp")
h=A.a.k(A.a.t(typeof h=="number"?A.c.k(h):0,0,f))
g=t.d.a(a2.h(0,"altarKnowledge"))
if(g==null){g=t.z
g=B.n(g,g)}return B.f1(r,B.cI(B.aw(g,t.N,t.z)),a0,a,1008,l,o,s,n,i,p,q,k,m,j,h)},
py(a){var s,r,q=a.h(0,"incubationSeconds")
if(typeof q=="number")return A.a.t(A.c.k(q),60,1209600)
s=a.h(0,"incubationMinutes")
if(typeof s=="number")return A.a.t(A.c.k(s)*60,60,1209600)
r=a.h(0,"incubationHours")
return A.a.t(A.a.k(A.a.t(typeof r=="number"?A.c.k(r):168,0,2147483647))*6,1,20160)*60},
ao:function ao(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.x=i
_.y=j
_.z=k
_.Q=l
_.as=m
_.at=n
_.ax=o},
ht:function ht(a){this.a=a},
ow(a){var s,r
for(s=0;s<3;++s){r=A.v3[s]
if(r.a===a||r.b===a)return r}return null},
t5(a){var s=t.mA
s=B.k(new B.j(A.bj,t.bo.a(new B.lZ(a)),s),s.i("a.E"))
s.$flags=1
return s},
bV:function bV(a,b){this.a=a
this.b=b},
h:function h(a,b){this.a=a
this.e=b},
dk:function dk(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.r=d},
hu:function hu(a){this.a=a},
lZ:function lZ(a){this.a=a},
ci(a){var s=$.h9().h(0,a)
return s==null?A.b.gM(A.a2):s},
bb:function bb(a,b){this.a=a
this.b=b},
bE:function bE(a,b){this.a=a
this.b=b},
x:function x(a,b,c,d,e,f,g){var _=this
_.a=a
_.b=b
_.d=c
_.ax=d
_.ay=e
_.ch=f
_.cx=g},
mg:function mg(){},
iH(a){return((a^A.a.cW(a,16))&1)===0?A.bW:A.bX},
mw(a){var s,r,q,p,o
if(J.F(a.h(0,"sex"),"male"))return A.bW
if(J.F(a.h(0,"sex"),"female"))return A.bX
s=a.h(0,"hatchSeed")
if(typeof s=="number")return B.iH(Math.abs(A.c.k(s)))
r=a.h(0,"id")
r=B.z(r==null?"":r)
q=a.h(0,"acquiredAt")
q=B.z(q==null?"":q)
p=a.h(0,"lineageId")
for(r=new B.dV(r+"|"+q+"|"+B.z(p==null?"":p)),q=t.gS,r=new B.c_(r,r.gm(0),q.i("c_<H.E>")),q=q.i("H.E"),o=17;r.l();){p=r.d
if(p==null)p=q.a(p)
o=o*31+p&2147483647}return B.iH(o)},
dZ:function dZ(a,b){this.a=a
this.b=b},
nl(a){var s
switch(a.a){case 0:s=A.Sc
break
case 1:s=A.Sd
break
case 2:s=A.Se
break
case 3:s=A.Sb
break
case 4:s=A.Sa
break
default:s=null}return s},
pl(a){var s
switch(a.a){case 0:s="moral"
break
case 1:s="order"
break
case 2:s="rarity"
break
case 3:s="lineage"
break
case 4:s="name"
break
default:s=null}return s},
nZ(a){var s,r,q=a.h(0,"fragments")
q=typeof q=="number"?Math.max(0,A.c.k(q)):0
s=a.h(0,"essence")
s=typeof s=="number"?Math.max(0,A.c.k(s)):0
r=a.h(0,"hearts")
return new B.bg(q,s,typeof r=="number"?Math.max(0,A.c.k(r)):0)},
cI(a){var s=J.F(a.h(0,"tagged"),!0),r=a.h(0,"tagRevision")
r=typeof r=="number"?Math.max(0,A.c.k(r)):0
return new B.aP(s,r,J.F(a.h(0,"moral"),!0),J.F(a.h(0,"order"),!0),J.F(a.h(0,"rarity"),!0),J.F(a.h(0,"lineage"),!0))},
nC(a,b,c,d,e,f,g,h,i,j){var s,r=a==null?B.n(t.N,t.S):a,q=b==null?B.n(t.N,t.es):b,p=g==null?B.a1(t.N):g
if(d==null){s=t.N
s=B.n(s,s)}else s=d
return new B.f9(f,h,j,c,i,r,q,p,s,e==null?B.n(t.N,t.P):e)},
nD(a){var s,r,q,p,o,n,m,l,k,j,i=B.b0(a.h(0,"ownerId")),h=a.h(0,"revision")
h=typeof h=="number"?Math.max(0,A.c.k(h)):0
s=t.d
r=s.a(a.h(0,"wallet"))
if(r==null){r=t.z
r=B.n(r,r)}q=t.N
p=t.z
r=B.nZ(B.aw(r,q,p))
o=a.h(0,"misses")
o=A.a.t(typeof o=="number"?Math.max(0,A.c.k(o)):0,0,39)
n=a.h(0,"totalReturned")
n=typeof n=="number"?Math.max(0,A.c.k(n)):0
m=s.a(a.h(0,"crafted"))
if(m==null)m=B.n(p,p)
m=m.aX(0,new B.iI(),q,t.S)
l=s.a(a.h(0,"eggs"))
if(l==null)l=B.n(p,p)
l=l.aX(0,new B.iJ(),q,t.es)
k=t.g.a(a.h(0,"returnedIds"))
k=J.bO(k==null?[]:k,q)
k=B.a3(k,k.$ti.i("a.E"))
j=s.a(a.h(0,"names"))
if(j==null)j=B.n(p,p)
j=j.aX(0,new B.iK(),q,q)
s=s.a(a.h(0,"operations"))
if(s==null)s=B.n(p,p)
return B.nC(m,l,o,j,s.aX(0,new B.iL(),q,t.P),i,k,h,n,r)},
b5:function b5(a,b){this.a=a
this.b=b},
bg:function bg(a,b,c){this.a=a
this.b=b
this.c=c},
aP:function aP(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
f9:function f9(a,b,c,d,e,f,g,h,i,j){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.x=i
_.y=j},
iM:function iM(){},
iI:function iI(){},
iJ:function iJ(){},
iK:function iK(){},
iL:function iL(){},
aE:function aE(a){this.a=a},
pX(a){var s,r,q,p,o,n,m,l,k
t.P.a(a)
s=Date.now()
r=new B.ac(s,0,!1)
q=B.cj(a.h(0,"id"))
s=q==null?"legacy-presentation-"+1000*s:q
q=B.db(A.l9,a.h(0,"type"),t.f9)
if(q==null)q=A.aO
p=a.h(0,"createdAt")
p=typeof p=="string"?p:null
p=B.a9(p==null?"":p)
if(p==null)p=r
o=a.h(0,"sortAt")
o=typeof o=="string"?o:null
o=B.a9(o==null?"":o)
if(o==null)o=r
n=B.cj(a.h(0,"dragonId"))
m=B.cj(a.h(0,"achievementId"))
l=B.cj(a.h(0,"previousStageKey"))
k=t.f
return new B.aQ(s,q,p,o,n,m,l,k.b(a.h(0,"payload"))?B.aw(k.a(a.h(0,"payload")),t.N,t.z):A.ay)},
bY:function bY(a,b){this.a=a
this.b=b},
aQ:function aQ(a,b,c,d,e,f,g,h){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h},
r6(a,b,c){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d=null
A:{s="hearth"===a
r=s
q=d
if(r){q=A.X===b
r=q
p=b
o=!0
n=!0}else{p=d
o=!1
n=!1
r=!1}if(r){r=B.m([A.PW,A.Qh,A.OY],t.L)
break A}m=d
if(s){if(n)r=p
else{r=b
p=r
n=!0}m=A.Y===r
r=m
l=!0}else{l=!1
r=!1}if(r){r=B.m([A.Q3,A.Q1,A.PX],t.L)
break A}k=d
if(s){if(n)r=p
else{r=b
p=r
n=!0}k=A.Z===r
r=k
j=!0}else{j=!1
r=!1}if(r){r=B.m([A.Q9,A.PT,A.Q0],t.L)
break A}i=d
if(s){if(n)r=p
else{r=b
p=r
n=!0}i=A.S===r
r=i
h=!0}else{h=!1
r=!1}if(r){r=B.m([A.Qi,A.Qd,A.OX],t.L)
break A}g="garden"===a
r=g
if(r)if(o)r=q
else{if(n)r=p
else{r=b
p=r
n=!0}q=A.X===r
r=q
o=!0}else r=!1
if(r){r=B.m([A.Qp,A.Q8,A.Qk],t.L)
break A}if(g)if(l)r=m
else{if(n)r=p
else{r=b
p=r
n=!0}m=A.Y===r
r=m
l=!0}else r=!1
if(r){r=B.m([A.Qf,A.Qj,A.Qn],t.L)
break A}if(g)if(j)r=k
else{if(n)r=p
else{r=b
p=r
n=!0}k=A.Z===r
r=k
j=!0}else r=!1
if(r){r=B.m([A.PQ,A.PU,A.Q6],t.L)
break A}if(g)if(h)r=i
else{if(n)r=p
else{r=b
p=r
n=!0}i=A.S===r
r=i
h=!0}else r=!1
if(r){r=B.m([A.Q_,A.Q4,A.Qq],t.L)
break A}f="loft"===a
r=f
if(r)if(o)r=q
else{if(n)r=p
else{r=b
p=r
n=!0}q=A.X===r
r=q
o=!0}else r=!1
if(r){r=B.m([A.Qr,A.Ql,A.Qo],t.L)
break A}if(f)if(l)r=m
else{if(n)r=p
else{r=b
p=r
n=!0}m=A.Y===r
r=m
l=!0}else r=!1
if(r){r=B.m([A.Qt,A.Qe,A.Qb],t.L)
break A}if(f)if(j)r=k
else{if(n)r=p
else{r=b
p=r
n=!0}k=A.Z===r
r=k
j=!0}else r=!1
if(r){r=B.m([A.Qg,A.PZ,A.Qa],t.L)
break A}if(f)if(h)r=i
else{if(n)r=p
else{r=b
p=r
n=!0}i=A.S===r
r=i
h=!0}else r=!1
if(r){r=B.m([A.Qm,A.Qs,A.PV],t.L)
break A}if(o)r=q
else{if(n)r=p
else{r=b
p=r
n=!0}q=A.X===r
r=q}if(r){r=c.r
e=r-0.06
e=B.m([new B.J(0.22,e),new B.J(0.5,r-0.04),new B.J(0.78,e)],t.L)
r=e
break A}if(l)r=m
else{if(n)r=p
else{r=b
p=r
n=!0}m=A.Y===r
r=m}if(r){r=c.f
e=r+0.13
r=B.m([new B.J(0.78,e),new B.J(0.22,e),new B.J(0.5,r+0.1)],t.L)
break A}if(j)r=k
else{if(n)r=p
else{r=b
p=r
n=!0}k=A.Z===r
r=k}if(r){r=B.m([A.PY,A.Q2,A.Qc],t.L)
break A}if(h)r=i
else{i=A.S===(n?p:b)
r=i}if(r){r=B.m([A.Q7,A.PJ,A.Q5],t.L)
break A}r=d}return r},
bk:function bk(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.f=d
_.r=e},
bH:function bH(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
l:function l(a,b,c,d){var _=this
_.a=a
_.b=b
_.d=c
_.e=d},
nO(a){var s
switch(a.a){case 0:s="Moral Prism"
break
case 1:s="Order Compass"
break
case 2:s="Soul Mirror"
break
case 3:s="Astral Lens"
break
case 4:s="Chronoshard"
break
case 5:s="Wayfinder Sigil"
break
case 6:s="Twinstar Brooch"
break
default:s=null}return s},
qg(a){var s
A:{if(A.az===a||A.aA===a||A.aB===a||A.ak===a){s=!0
break A}if(A.a8===a||A.aC===a||A.x===a){s=!1
break A}s=null}return s},
qf(a){var s
A:{s=A.az===a||A.aA===a||A.aB===a
break A}return s},
aS:function aS(a,b){this.a=a
this.b=b},
a8:function a8(a,b){this.a=a
this.b=b},
ox(a,b,c,d){var s
if(c){if(d===A.I)s=a==="mastery"||a===b.b
else s=!1
if(s)return 400
return 350}if(d!==A.I)return 300
if(a==="mastery"||a===b.b)return 350
return 300},
rB(a,b,c,d){var s,r,q,p,o,n=B.n(t.N,t.S)
for(s=a==null,r=0;r<3;++r){q=A.K[r]
p=q.b
o=s?null:a.h(0,p)
if(o==null)o=0
n.j(0,p,A.a.k(A.a.t(o,0,B.ox(b,q,c,d))))}return n},
rC(a){var s,r,q,p,o=B.n(t.N,t.S)
for(s=A.cI.gq(A.cI),r=a==null;s.l();){q=s.gu()
p=r?null:a.h(0,q)
o.j(0,q,A.a.k(A.a.t(p==null?0:p,0,1e9)))}return o},
rz(a){var s,r,q=B.n(t.N,t.S),p=(a==null?A.bn:a).gav()
p=p.gq(p)
while(p.l()){s=p.gu()
r=s.a
if(A.am.p(0,r))q.j(0,r,A.a.k(A.a.t(s.b,0,1e9)))}return q},
rA(a){var s,r,q=B.n(t.N,t.S),p=(a==null?A.bn:a).gav()
p=p.gq(p)
while(p.l()){s=p.gu()
r=s.a
if(A.am.p(0,r))q.j(0,r,A.a.k(A.a.t(s.b,0,3)))}return q},
ry(a){var s,r,q=B.n(t.N,t.S),p=(a==null?A.bn:a).gav()
p=p.gq(p)
while(p.l()){s=p.gu()
r=s.a
if(A.am.p(0,r))q.j(0,r,A.a.k(A.a.t(s.b,0,3)))}return q},
pL(a){var s
A:{if(A.bT===a||A.bU===a||A.bV===a||A.b9===a){s=!0
break A}if(A.bS===a||A.b8===a){s=!1
break A}s=null}return s},
nP(a,b,c,d,e,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,d0,d1,d2,d3,d4,d5,d6){var s,r,q,p,o,n,m,l,k,j,i,h,g,f=B.a1(t.U)
if(b3!=null)f.A(0,b3)
s=!d0
r=!s||c0==="sinisterra"
q=!s||c0==="sinisterra"?A.D:c1
p=!s||c0==="sinisterra"?!0:c2
o=A.a.t(b6==null?b5*60:b6,60,1209600)
n=B.rB(d4,a8,!s||c0==="sinisterra",d2)
m=B.rC(d5)
l=B.rz(a5)
k=B.rA(a6)
j=B.ry(a2)
s=c6==null?B.m([],t.s):c6
if(c0==null){i=$.hb()
h=i.length
g=Math.abs(b2)%h
if(!(g>=0&&g<h))return B.b(i,g)
g=i[g].a
i=g}else i=c0
return new B.Y(b4,c3,d6,d,b1,d2,b0,c7,c9,f,r,b8,q,b9,c,p,c5,d1,o,s,a9,c8,a1,a0,b,b7,a7,e,a,d3,c4,n,m,l,k,j,a3,a4,b2,i,a8)},
qm(a){var s
for(s=8;s>=0;--s)if(a>=A.F5[s])return s+1
return 1},
qk(a){return B.mQ(t.P.a(a))},
mQ(e8){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,c0,c1,c2,c3,c4,c5,c6,c7,c8,c9="hatchSeed",d0=null,d1=2147483647,d2="needsUpdatedAt",d3="firstEgg",d4="highlightedExpertises",d5="spectral",d6="prismatic",d7="sinister",d8="lawAxisKnown",d9="moralAxisKnown",e0="personalityKnown",e1="favorite",e2="roamsTower",e3="dragonSchoolFinalizedEarly",e4=typeof e8.h(0,c9)=="number"?Math.abs(A.c.k(B.h4(e8.h(0,c9)))):1000*Date.now()%2147483647,e5=e8.h(0,"xp"),e6=A.a.k(A.a.t(typeof e5=="number"?A.c.k(e5):0,0,d1)),e7=B.db(A.JE,e8.h(0,"stage"),t.hX)
if(e6<60)s=A.h
else if(e6<280)s=A.aj
else{e5=e6<700?A.a7:A.I
s=e5}r=B.an(e8.h(0,"training"))
q=B.an(e8.h(0,"pathEnergy"))
e5=e8.h(0,"acquiredAt")
e5=typeof e5=="string"?e5:d0
if(e5==null){e5=e8.h(0,d2)
e5=typeof e5=="string"?e5:d0}p=B.a9(e5==null?"":e5)
if(p==null)p=new B.ac(Date.now(),0,!1)
e5=e8.h(0,"stageStartedAt")
e5=typeof e5=="string"?e5:d0
o=B.a9(e5==null?"":e5)
if(o==null)o=p
n=e8.h(0,"lineageId")
n=typeof n=="string"?n:d0
m=!B.a5(e8.h(0,d3))||B.ab(e8.h(0,d3))
l=e8.h(0,"evolutionPath")
l=typeof l=="string"?l:d0
A:{if("earth"===l){e5="might"
break A}if("storm"===l){e5="arcana"
break A}if("bond"===l){e5="spirit"
break A}if("might"===l||"arcana"===l||"spirit"===l||"mastery"===l){e5=l
break A}e5=d0
break A}k=B.cj(e8.h(0,"id"))
if(k==null)k="legacy-"+e4
j=e8.h(0,"name")
j=typeof j=="string"?j:d0
j=j==null?d0:A.i.a9(j)
if(j==null)j=""
i=B.mw(e8)
h=B.a1(t.U)
for(g=t.j,f=0;f<3;++f){e=A.K[f]
if(g.b(e8.h(0,d4))&&J.eR(g.a(e8.h(0,d4)),e.b))h.n(0,e)}g=e8.h(0,"coins")
g=A.a.k(A.a.t(typeof g=="number"?A.c.k(g):25,0,d1))
d=e8.h(0,"gems")
d=A.a.k(A.a.t(typeof d=="number"?A.c.k(d):3,0,d1))
c=e7==null?s:e7
if(!(B.a5(e8.h(0,d5))&&B.ab(e8.h(0,d5))))b=B.a5(e8.h(0,d6))&&B.ab(e8.h(0,d6))
else b=!0
a=B.a5(e8.h(0,d7))&&B.ab(e8.h(0,d7))
a0=B.db(A.J,e8.h(0,"lawAxis"),t.bK)
if(a0==null){a0=e4%3
if(!(a0>=0&&a0<3))return B.b(A.J,a0)
a0=A.J[a0]}a1=B.db(A.a1,e8.h(0,"moralAxis"),t.ms)
if(a1==null){a1=A.a.G(e4,3)%3
if(!(a1>=0&&a1<3))return B.b(A.a1,a1)
a1=A.a1[a1]}a2=B.a5(e8.h(0,d8))&&B.ab(e8.h(0,d8))
a3=t.d.a(e8.h(0,"altarKnowledge"))
if(a3==null){a3=t.z
a3=B.n(a3,a3)}a4=t.N
a3=B.cI(B.aw(a3,a4,t.z))
a5=B.a5(e8.h(0,d9))&&B.ab(e8.h(0,d9))
a6=B.a5(e8.h(0,e0))&&B.ab(e8.h(0,e0))
a7=B.dI(e8.h(0,"sizeFactor"))
if(a7==null)a7=d0
a7=A.c.t(a7==null?1:a7,0.5,1.5)
a8=B.ql(e8,m)
a9=t.g.a(e8.h(0,"personalityTraitIds"))
if(a9==null)a9=d0
else{a9=J.bO(a9,a4)
b0=a9.$ti
b1=b0.i("j<a.E>")
b1=B.a3(new B.j(a9,b0.i("i(a.E)").a(A.b.gbw(A.bl)),b1),b1.i("a.E"))
b1=B.b8(b1,2,B.e(b1).c)
a9=B.k(b1,B.e(b1).i("a.E"))}if(a9==null)a9=B.m([],t.s)
b0=B.a5(e8.h(0,e1))&&B.ab(e8.h(0,e1))
b1=!B.a5(e8.h(0,e2))||B.ab(e8.h(0,e2))
b2=B.cj(e8.h(0,"currentRoomId"))
if(b2==null)b2="hearth"
b3=e8.h(0,"currentFloorIndex")
b3=A.a.k(A.a.t(typeof b3=="number"?A.c.k(b3):0,0,d1))
b4=B.cj(e8.h(0,"activeAdventureId"))
b5=e8.h(0,"joy")
b5=A.a.k(A.a.t(typeof b5=="number"?A.c.k(b5):78,0,100))
b6=e8.h(0,"energy")
b6=A.a.k(A.a.t(typeof b6=="number"?A.c.k(b6):78,0,100))
b7=e8.h(0,"comfort")
b7=A.a.k(A.a.t(typeof b7=="number"?A.c.k(b7):78,0,100))
b8=e8.h(0,d2)
b8=typeof b8=="string"?b8:d0
b8=B.a9(b8==null?"":b8)
if(b8==null)b8=new B.ac(Date.now(),0,!1)
if(A.b.N(A.a2,new B.kX(n)))b9=n
else{b9=$.hb()
c0=b9.length
c1=e4%c0
if(!(c1>=0&&c1<c0))return B.b(b9,c1)
c1=b9[c1].a
b9=c1}c0=r.h(0,"might")
if(c0==null)c0=q.h(0,"earth")
c0=A.a.k(A.a.t(typeof c0=="number"?A.c.k(c0):0,0,d1))
c1=r.h(0,"arcana")
if(c1==null)c1=q.h(0,"storm")
c1=A.a.k(A.a.t(typeof c1=="number"?A.c.k(c1):0,0,d1))
c2=r.h(0,"spirit")
if(c2==null)c2=q.h(0,"bond")
c3=t.S
c2=B.V(["might",c0,"arcana",c1,"spirit",A.a.k(A.a.t(typeof c2=="number"?A.c.k(c2):0,0,d1))],a4,c3)
c1=B.n(a4,c3)
for(c0=B.an(e8.h(0,"trialHighScores")),c0=new B.y(c0,B.e(c0).i("y<1,2>")).gq(0);c0.l();){c4=c0.d
c5=c4.a
c6=c4.b
c1.j(0,c5,A.a.k(A.a.t(typeof c6=="number"?A.c.k(c6):0,0,d1)))}c0=B.n(a4,c3)
for(c5=B.an(e8.h(0,"dragonSchoolRecords")),c5=new B.y(c5,B.e(c5).i("y<1,2>")).gq(0);c5.l();){c4=c5.d
c6=c4.a
c7=c4.b
c0.j(0,c6,A.a.k(A.a.t(typeof c7=="number"?A.c.k(c7):0,0,d1)))}c5=B.n(a4,c3)
for(c6=B.an(e8.h(0,"dragonSchoolStars")),c6=new B.y(c6,B.e(c6).i("y<1,2>")).gq(0);c6.l();){c4=c6.d
c7=c4.a
c8=c4.b
c5.j(0,c7,A.a.k(A.a.t(typeof c8=="number"?A.c.k(c8):0,0,d1)))}a4=B.n(a4,c3)
for(c3=B.an(e8.h(0,"dragonSchoolAttempts")),c3=new B.y(c3,B.e(c3).i("y<1,2>")).gq(0);c3.l();){c4=c3.d
c6=c4.a
c7=c4.b
a4.j(0,c6,A.a.k(A.a.t(typeof c7=="number"?A.c.k(c7):0,0,d1)))}c3=B.a5(e8.h(0,e3))&&B.ab(e8.h(0,e3))
c6=e8.h(0,"dragonSchoolMentorLessons")
return B.nP(p,b4,a3,g,b7,b3,b2,a4,c3,A.a.k(A.a.t(typeof c6=="number"?A.c.k(c6):0,0,d1)),c0,c5,b6,e5,b0,m,d,e4,h,k,60,a8,b5,a0,a2,b9,a1,a5,j,b8,a6,a9,b,b1,i,a,a7,c,o,c2,c1,e6)},
ql(a,b){var s,r,q
if(b)return 3600
s=a.h(0,"incubationSeconds")
if(typeof s=="number")return A.a.t(A.c.k(s),60,1209600)
r=a.h(0,"incubationMinutes")
if(typeof r=="number")return A.a.t(A.c.k(r)*60,60,1209600)
q=a.h(0,"incubationHours")
return A.a.t(A.a.k(A.a.t(typeof q=="number"?A.c.k(q):168,0,2147483647))*6,1,20160)*60},
bX:function bX(a,b){this.a=a
this.b=b},
aq:function aq(a,b){this.a=a
this.b=b},
bW:function bW(a,b){this.a=a
this.b=b},
cq:function cq(a,b){this.a=a
this.b=b},
cs:function cs(a,b){this.a=a
this.b=b},
Y:function Y(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,c0,c1){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g
_.w=h
_.x=i
_.y=j
_.z=k
_.Q=l
_.as=m
_.at=n
_.ax=o
_.ay=p
_.ch=q
_.CW=r
_.cx=s
_.cy=a0
_.db=a1
_.dx=a2
_.dy=a3
_.fr=a4
_.fx=a5
_.fy=a6
_.go=a7
_.id=a8
_.k1=a9
_.k2=b0
_.k3=b1
_.k4=b2
_.ok=b3
_.p1=b4
_.p2=b5
_.p3=b6
_.p4=b7
_.R8=b8
_.RG=b9
_.rx=c0
_.ry=c1},
l0:function l0(a){this.a=a},
l_:function l_(a){this.a=a},
l1:function l1(a){this.a=a},
l3:function l3(a){this.a=a},
l2:function l2(a){this.a=a},
kY:function kY(a,b){this.a=a
this.b=b},
kZ:function kZ(a,b){this.a=a
this.b=b},
kX:function kX(a){this.a=a},
c2:function c2(a,b){this.a=a
this.b=b},
c3:function c3(a,b){this.a=a
this.c=b},
me:function me(){},
fE:function fE(a,b){this.a=a
this.b=b},
c5:function c5(a,b,c){this.a=a
this.c=b
this.d=c},
rd(a,b,c,d){var s,r,q,p,o=A.a.D(c*3+d*5,11)
if(o===0)s=A.cf
else s=o<4?A.jz:A.jy
switch(s.a){case 0:r=0
break
case 1:r=9
break
case 2:r=20
break
default:r=null}q=8+c*2+d*3+r
p=s===A.cf&&(c&1)===0?A.be:A.w
r=p===A.be?A.c.fh(q/9):q
B.ri(b)
B.rw(a,b)
return new B.ap("decor_"+a.a+"_"+b.a,a.b+" "+b.b,b.f,r*10,p)},
ri(a){var s,r=a.a
A:{if("cushion"===r||"daybed"===r){s=A.Bl
break A}if("planter"===r||"bonsai"===r){s=A.H0
break A}if("shelf"===r){s=A.Bq
break A}if("tapestry"===r){s=A.IW
break A}if("lantern"===r||"orb"===r){s=A.FO
break A}s=A.n
break A}return s},
rw(a,b){var s
if(b.f!==A.S)return A.iR
s=a.a
if(A.QZ.p(0,s))return A.iU
if(A.QG.p(0,s))return A.iS
if(A.QV.p(0,s))return A.iT
return A.iV},
bZ:function bZ(a,b){this.a=a
this.b=b},
dr:function dr(a,b){this.a=a
this.b=b},
e6:function e6(a,b){this.a=a
this.b=b},
co:function co(a,b){this.a=a
this.b=b},
e3:function e3(a,b){this.a=a
this.b=b},
ap:function ap(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.f=c
_.r=d
_.CW=e},
a7:function a7(a,b,c){this.a=a
this.b=b
this.c=c},
bm:function bm(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
tn(a){var s,r
for(s=0;s<2;++s){r=A.cj[s]
if(r.a===a)return r}return null},
bJ:function bJ(a){this.a=a},
tz(a){var s,r
if(a.length===0)return null
for(s=0;s<8;++s){r=A.cg[s]
if(r.b===a)return r}return null},
qy(a){return B.qx(t.P.a(a))},
qx(a){var s,r,q,p,o=null,n=a.h(0,"id")
n=n==null?o:J.au(n)
if(n==null)n=""
s=A.b.a7(A.cg,new B.lc(a),new B.ld())
r=a.h(0,"appearedAt")
r=r==null?o:J.au(r)
r=B.a9(r==null?"":r)
if(r==null)r=new B.ac(Date.now(),0,!1)
q=a.h(0,"specialEventKey")
q=q==null?o:J.au(q)
p=a.h(0,"startedAt")
p=p==null?o:J.au(p)
return new B.aZ(n,s,r,q,B.a9(p==null?"":p))},
nf(a,b){var s
A:{if(A.ag===a){s=A.v4
break A}if(A.an===a){s=A.A4
break A}if(A.ao===a){s=A.xu
break A}if(A.by===a||A.bz===a||A.bA===a||A.bB===a||A.bC===a){s=A.Am
break A}s=null}if(4>=s.length)return B.b(s,4)
if(b>=s[4])return A.aV
if(b>=s[3])return A.RT
if(b>=s[2])return A.RS
if(b>=s[1])return A.RR
if(b>=s[0])return A.RQ
return A.RP},
al:function al(a,b){this.a=a
this.b=b},
cc:function cc(a,b){this.a=a
this.b=b},
bw:function bw(a){this.r=a},
aZ:function aZ(a,b,c,d,e){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e},
lc:function lc(a){this.a=a},
ld:function ld(){},
dH(a,b){var s=B.fB(a)-B.fB(a)%b
return a.c?B.cM(B.aj(a),B.aU(a),B.aT(a),B.dy(a),s):B.cm(B.aj(a),B.aU(a),B.aT(a),B.dy(a),s)},
op(a,b){var s=B.cM(a,b+1,0,0,0)
return s.P(0-B.ah(A.a.D(B.nT(s),7),0,0,0,0,0).a)},
lN(a){var s=36e8,r=a.am(),q=B.op(B.aj(r),3).P(s),p=B.op(B.aj(r),10).P(s)
return!r.dd(q)&&r.dd(p)?A.c2:A.aM},
lO(a,b,c,d){var s,r,q,p,o=B.cM(a,b,c,d,0)
for(s=0;s<2;++s){r=A.Bj[s].a
q=o.P(0-r)
p=B.lN(q)
if(p.a===r)return q}throw B.f(B.bv("Invalid Europe/Amsterdam wall time: "+o.v(0)))},
ol(a){var s=a.c,r=a.d,q=a.e,p=a.f,o=B.lO(s,r,q,p),n=B.cM(s,r,q,p,0).P(a.r.a)
return new B.ak(a,a.a+":launch:"+s,o,B.lO(B.aj(n),B.aU(n),B.aT(n),B.dy(n)))},
od(a,b){var s,r,q=a.x,p=a.y,o=b<a.w
if(o)return null
o=a.z
s=B.lO(b,q,p,o)
r=B.cM(b,q,p,o,0).P(a.Q.a)
return new B.ak(a,a.a+":year:"+b,s,B.lO(B.aj(r),B.aU(r),B.aT(r),B.dy(r)))},
oF(a){var s,r,q,p,o,n,m,l,k,j,i,h=B.m([],t.oL),g=a.am(),f=B.aj(g.P(B.lN(g).a))
for(s=f-1,r=0;r<6;++r){q=A.bf[r]
p=B.ol(q)
g=a.am()
o=p.c
n=g.a
m=o.a
if(n>=m)o=n===m&&g.b<o.b
else o=!0
if(!o){o=p.d
m=o.a
if(n>=m)o=n===m&&g.b<o.b
else o=!0}else o=!1
if(o)A.b.n(h,p)
for(o=[s,f],l=0;l<2;++l){k=B.od(q,o[l])
n=!1
if(k!=null){g=a.am()
m=k.c
j=g.a
i=m.a
if(j>=i)m=j===i&&g.b<m.b
else m=!0
if(!m){n=k.d
m=n.a
if(j>=m)n=j===m&&g.b<n.b
else n=!0}}if(n)A.b.n(h,k)}}return h},
tt(a){var s,r,q,p,o,n,m,l,k,j,i,h=a.am(),g=A.a.k(A.a.t(B.aj(h.P(B.lN(h).a)),2027,9996)),f=t.oL,e=B.m([],f)
for(s=t.g8,r=t.cG,q=r.i("a.E"),p=g+2,o=0;o<6;++o){n=A.bf[o]
m=B.m([B.ol(n)],f)
for(l=g;l<=p;++l){k=B.od(n,l)
if(k!=null)A.b.n(m,k)}A.b.b_(m,new B.mc())
j=B.k(new B.j(m,s.a(new B.md(h)),r),q)
j.$flags=1
i=j
if(i.length!==0)A.b.n(e,A.b.gM(i))}return e},
f2(a,b){var s,r,q,p,o,n=B.k(B.oF(b),t.W)
a.b4.a1(0,new B.hv(b))
for(s=a.b4,s=new B.y(s,B.e(s).i("y<1,2>")).gq(0);s.l();){r=s.d
q=B.mf(r.a)
if(q==null)continue
p=r.b
o=p.P(0-36e8*q.db)
A.b.n(n,new B.ak(q,q.a+":preview:"+p.a,o,p))}return n},
f7(a){var s=0,r=B.D(t.y),q,p,o,n,m,l,k,j,i,h,g,f,e,d
var $async$f7=B.E(function(b,c){if(b===1)return B.A(c,r)
for(;;)switch(s){case 0:if(!a.dx.p(0,A.bd)){q=!1
s=1
break}p=a.b.$0()
o=new B.bF(a.z)
n=B.oF(p),m=n.length,l=!1,k=0
case 3:if(!(k<n.length)){s=5
break}j=n[k]
i=j.b
s=!a.bh.p(0,i)?6:7
break
case 6:h=$.b2().h(0,j.a.b)
g=o.I("A Special Adventure has appeared","Er is een Speciaal Avontuur verschenen")
f=h==null
e=f?null:h.c
if(e==null)e="A rare route"
f=f?null:h.d
if(f==null)f="Een zeldzame route"
s=8
return B.o(B.ff(null,o.I(e+u.S,f+" wacht tijdelijk bij Adventures."),"special-adventure-"+i,g),$async$f7)
case 8:a.bh.n(0,i)
l=!0
case 7:case 4:n.length===m||(0,B.Z)(n),++k
s=3
break
case 5:n=B.tt(p),m=n.length,k=0
case 9:if(!(k<n.length)){s=11
break}d=n[k]
h=$.b2().h(0,d.a.b)
i=o.I("A Special Adventure has appeared","Er is een Speciaal Avontuur verschenen")
g=h==null
f=g?null:h.c
if(f==null)f="A rare route"
g=g?null:h.d
if(g==null)g="Een zeldzame route"
s=12
return B.o(B.ff(d.c,o.I(f+u.S,g+" wacht tijdelijk bij Adventures."),"special-adventure-"+d.b,i),$async$f7)
case 12:case 10:n.length===m||(0,B.Z)(n),++k
s=9
break
case 11:n=a.bh
if(n.a>20){n=B.mU(n,10,B.e(n).c)
a.sfQ(B.a3(n,B.e(n).i("a.E")))
l=!0}q=l
s=1
break
case 1:return B.B(q,r)}})
return B.C($async$f7,r)},
aH(a){var s,r=B.m([],t.a),q=a.ok
q===$&&B.N()
if(q.f!==A.h)r.push(q)
q=a.x2
s=B.q(q)
A.b.A(r,new B.j(q,s.i("i(1)").a(new B.ih()),s.i("j<1>")))
return r},
nA(a){var s=a.b1,r=B.q(s),q=r.i("j<1>")
s=B.k(new B.j(s,r.i("i(1)").a(new B.ij(a)),q),q.i("a.E"))
s.$flags=1
return s},
pI(a){var s,r,q,p,o,n=B.m([],t.a),m=t.S,l=B.n(m,m)
m=B.aH(a)
s=B.q(m)
m=B.k(new B.j(m,s.i("i(1)").a(new B.ii()),s.i("j<1>")),t.x)
A.b.A(m,B.nA(a))
s=m.length
r=0
for(;r<m.length;m.length===s||(0,B.Z)(m),++r){q=m[r]
p=q.fr
if(p<0||p>=a.L.length)continue
o=l.h(0,p)
if(o==null)o=0
if(o>=3)continue
A.b.n(n,q)
l.j(0,p,o+1)}return n},
pK(a3){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2=B.m([],t.t)
for(s=0;s<a3.L.length;++s)if(!a3.aj.p(0,s))a2.push(s)
if(a2.length===0)return!1
r=B.pI(a3)
for(q=r.length,p=a3.a,o=t.S,n=t.gw,m=t.fT,l=m.i("a.E"),k=!1,j=0;j<r.length;r.length===q||(0,B.Z)(r),++j){i=r[j]
if(!i.dx||i.fx!=null)continue
if(A.b.p(a2,i.fr)){h=a3.L
g=i.fr
if(!(g>=0&&g<h.length))return B.b(h,g)
f=h[g]!==i.dy}else f=!0
if(!f&&p.S()>=0.2)continue
e=$.h9().h(0,i.rx)
if(e==null)e=A.b.gM(A.a2)
h=B.k(new B.j(a2,n.a(new B.it(r,i)),m),l)
h.$flags=1
d=h
if(d.length===0)continue
h=B.q(d)
g=h.i("i(1)")
h=h.i("j<1>")
c=B.k(new B.j(d,g.a(new B.iu(a3,e)),h),o)
A.b.A(c,new B.j(d,g.a(new B.iv(a3,e)),h))
A.b.A(c,new B.j(d,g.a(new B.iw(e,a3)),h))
h=B.k(new B.j(d,g.a(new B.ix(c)),h),h.i("a.E"))
h.$flags=1
b=h
if(c.length!==0)a=b.length===0||p.S()<0.65
else a=!1
a0=a?c:b
h=p.C(a0.length)
if(!(h>=0&&h<a0.length))return B.b(a0,h)
a1=a0[h]
if(a1!==i.fr||f){i.fr=a1
h=a3.L
if(!(a1>=0&&a1<h.length))return B.b(h,a1)
i.dy=h[a1]
k=!0}}return k},
f5(a2,a3){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1
B.hJ(a2)
s=a2.b.$0()
if(a3===A.A){r=B.m([],t.m1)
for(q=B.f2(a2,s),p=q.length,o=0;o<q.length;q.length===p||(0,B.Z)(q),++o){n=q[o]
if(!a2.bA.p(0,n.b)){m=$.b2().h(0,n.a.b)
if(m!=null&&!A.b.p(r,m))A.b.n(r,m)}}l=a2.b3
if(l!=null){q=a2.bg
q=(q==null?null:q.ac(s))===!0}else q=!1
if(q){m=$.b2().h(0,l)
if(m!=null)A.b.n(r,m)}return r}if(a3===A.W){k=s.am()
j=k.P(B.lN(k).a)
i=B.cM(B.aj(j),B.aU(j),B.aT(j),12,0).P(0-B.ah(A.a.D(B.nT(j),7),0,0,0,0,0).a)
if(j.dd(i))i=i.P(-6048e8)
h=A.a.G(A.a.G(i.au(B.cM(2020,1,5,12,0)).a,864e8),7)
q=$.ng()
p=A.a.D(Math.abs(h*17),200)
if(!(p<q.length))return B.b(q,p)
return B.m([q[p]],t.m1)}A:{q=A.q===a3
if(q){p=$.mi()
break A}if(A.o===a3){p=$.mj()
break A}if(A.z===a3){p=$.mh()
break A}if(A.W===a3||A.A===a3){p=A.cm
break A}p=null}g=a2.al.ei(a3,new B.hX())
f=J.aV(g)
f.a1(g,new B.hY(a3,a2))
e=s.a
B:{if(q){q=9e5
break B}if(A.o===a3){q=36e5
break B}q=864e5
break B}d=A.a.dr(e,q)
c=3
if(a3===A.q){b=B.dH(s,15)
a=a2.aH
if(a==null)a2.aH=b
else{a0=B.dH(a,15)
c=A.a.t(A.a.G(A.a.G(b.au(a0).a,6e7),15),0,3)
if(b.ac(a0))a2.aH=b}}else if(a3===A.o){b=B.dH(s,60)
a=a2.aC
if(a==null)a2.aC=b
else{a0=B.dH(a,60)
c=A.a.t(A.a.G(b.au(a0).a,36e8),0,3)
if(b.ac(a0))a2.aC=b}}else{a1=B.dq(s)
q=a2.b0
c=q.length===0||q!==a1?3:0
a2.b0=a1}B.pz(a2,A.a.t(c,0,3-f.gm(g)),g,d,p)
q=t.fs
q=B.k(new B.b_(f.b6(g,new B.hZ(),t.oT),q),q.i("a.E"))
q.$flags=1
return q},
iD(a,b,c){var s=0,r=B.D(t.kB),q,p,o,n,m,l,k,j,i
var $async$iD=B.E(function(d,e){if(d===1)return B.A(e,r)
for(;;)switch(s){case 0:if(a.cr(A.aC)<=0){q=A.S6
s=1
break}if(b!==A.q&&b!==A.o&&b!==A.z){q=A.S7
s=1
break}B.f5(a,b)
p=a.al.ei(b,new B.iF())
o=c==null
n=!o
if(n&&!J.eR(p,c)){q=A.S8
s=1
break}if(o&&J.bB(p)>=3){q=A.cM
s=1
break}A:{if(A.q===b){m=$.mi()
break A}if(A.o===b){m=$.mj()
break A}if(A.z===b){m=$.mh()
break A}if(A.W===b||A.A===b){m=A.cm
break A}m=null}if(n)J.hd(p,c)
l=B.q(m)
k=l.i("j<1>")
m=B.k(new B.j(m,l.i("i(1)").a(new B.iG(p,c,a)),k),k.i("a.E"))
m.$flags=1
j=m
m=j.length
if(m===0){if(n)J.bN(p,c)
q=A.cM
s=1
break}n=a.a.C(m)
if(!(n>=0&&n<m)){q=B.b(j,n)
s=1
break}i=j[n]
J.bN(p,i.a)
a.bP(A.aC)
n=i.c
o=o?"A Wayfinder Sigil discovered "+n+".":"A Wayfinder Sigil rerolled an Adventure into "+n+"."
a.ao(A.L,o,"wayfinderSigil:"+b.b,A.y)
s=3
return B.o(a.F(),$async$iD)
case 3:q=A.S5
s=1
break
case 1:return B.B(q,r)}})
return B.C($async$iD,r)},
mv(a,b){return A.b.aI(B.aH(a),0,new B.hV(b),t.S)},
ny(a0){var s,r,q,p,o,n,m,l,k,j,i,h,g,f=null,e=a0.b.$0(),d=a0.ab.length,c=B.f2(a0,e),b=B.q(c),a=new B.K(c,b.i("d(1)").a(new B.hK()),b.i("K<1,d>")).aK(0)
A.b.a1(a0.ab,new B.hL(a))
s=B.dH(e,15)
r=a0.aG
c=r==null
q=c?3:A.a.k(A.a.t(A.a.G(A.a.G(s.au(B.dH(r,15)).a,6e7),15),0,3))
p=a0.aG
if(c||s.ac(r))a0.aG=s
o=B.f2(a0,e)
c=B.q(o)
b=t.mp
b=B.k(new B.b_(new B.K(o,c.i("al?(1)").a(new B.hM()),c.i("K<1,al?>")),b),b.i("a.E"))
b.$flags=1
n=B.k(A.lQ,t.gq)
A.b.A(n,b)
b=a0.c
c=c.i("aB<1,ak?>")
m=a0.a
l=!1
for(;;){if(!(q>0&&a0.ab.length<3))break
k=m.C(n.length)
if(!(k>=0&&k<n.length))return B.b(n,k)
j=n[k]
k=A.cu.h(0,j)
i=k==null?f:k.r
if(i==null)h=f
else{k=new B.aB(o,c)
h=k.a7(k,new B.hN(i),new B.hO())}k=a0.ab
g=b.$0()
A.b.n(k,new B.aZ(g,j,s,h==null?f:h.b,f));--q
l=!0}return l||!J.F(p,a0.aG)||d!==a0.ab.length},
pH(a){var s,r,q,p,o=3-a.ab.length
if(o<=0)return
s=a.b.$0()
r=B.dH(s,15).P(9e8).P(B.ah(0,0,0,0,15*(o-1),0).a)
q=new B.bF(a.z)
p=q.I("Three Trials are ready","Drie Trials staan klaar")
B.mF(r,q.I(u.D,"Je Trial-bord is vol. Kies een draak en jaag op een nieuwe highscore."),p)},
ie(a,b){var s=0,r=B.D(t.H),q,p,o
var $async$ie=B.E(function(c,d){if(c===1)return B.A(d,r)
for(;;)switch(s){case 0:B.ny(a)
p=a.ab
o=p.length
A.b.a1(p,new B.ig(b))
if(a.ab.length===o){s=1
break}B.pH(a)
s=3
return B.o(a.F(),$async$ie)
case 3:case 1:return B.B(q,r)}})
return B.C($async$ie,r)},
nw(a,b){var s,r,q,p,o,n=864e8
B.nx(a)
s=B.cm(B.aj(b),B.aU(b),B.aT(b),0,0)
if(a.aV){r=a.ak
if(r.length===0)return!1
q=B.a9(r)
p=q==null?2:A.a.G(s.au(B.cm(B.aj(q),B.aU(q),B.aT(q),0,0)).a,n)
if(p>=0&&p<=1)return!1
a.a6.X(0,a.ak)
a.ak=""
return!0}if(a.W===0)return!1
o=B.a9(a.a0)
if(o==null){a.W=0
a.a0=""
a.a6.aB(0)
return!0}p=A.a.G(s.au(B.cm(B.aj(o),B.aU(o),B.aT(o),0,0)).a,n)
if(p<=1&&p>=0)return!1
a.W=0
a.a0=""
a.a6.aB(0)
return!0},
i9(a){var s=0,r=B.D(t.ca),q,p,o
var $async$i9=B.E(function(b,c){if(b===1)return B.A(c,r)
for(;;)switch(s){case 0:if(!a.aV){q=null
s=1
break}B.nw(a,a.b.$0())
p=a.a.S()<0.05?A.H:A.G
a.xr.aq(p,new B.ia(),new B.ib())
a.aV=!1
o=a.ak
if(o.length!==0){a.W=1
a.a0=o
a.sdi(B.dv([o],t.N))}else{a.W=0
a.a0=""
a.a6.aB(0)}a.ak=""
o=p.b
a.ao(A.L,"A seven-day Trial streak earned a "+o+" chest.",o,A.ai)
s=3
return B.o(a.F(),$async$i9)
case 3:q=p
s=1
break
case 1:return B.B(q,r)}})
return B.C($async$i9,r)},
pD(a,b){var s,r,q,p,o,n
if(!a.aV&&a.W>0&&b&&a.bl!==a.a0){s=B.a9(a.bl)
r=B.a9(a.a0)
if(s!=null&&r!=null){q=A.a.G(B.cm(B.aj(r),B.aU(r),B.aT(r),0,0).au(B.cm(B.aj(s),B.aU(s),B.aT(s),0,0)).a,864e8)
if(q>0){a.sh2(Math.max(0,a.W-q))
a.a0=a.W===0?"":B.dq(s)}}}p=B.a9(a.a0)
if(p!=null&&a.W>0)for(o=0;o<a.W;++o)a.a6.n(0,B.dq(B.cm(B.aj(p),B.aU(p),B.aT(p),0,0).P(0-864e8*o)))
n=a.ak
if(n.length!==0)a.a6.n(0,n)},
nx(a){var s,r,q,p,o=a.a6,n=B.e(o),m=n.i("j<1>")
a.sdi(B.a3(new B.j(o,n.i("i(1)").a(new B.hI()),m),m.i("a.E")))
if(a.aV){a.W=7
o=a.ak
if(o.length!==0&&!a.a6.p(0,o))a.ak=""
return}a.ak=""
if(a.W<=0){a.W=0
a.a0=""
a.a6.aB(0)
return}s=B.a9(a.a0)
if(s==null||!a.a6.p(0,a.a0)){a.W=0
a.a0=""
a.a6.aB(0)
return}r=B.a1(t.N)
for(q=0;q<a.W;){p=B.dq(B.cm(B.aj(s),B.aU(s),B.aT(s),0,0).P(0-864e8*q))
if(!a.a6.p(0,p))break
r.n(0,p);++q}a.W=q
a.sdi(r)
if(q===0)a.a0=""},
pz(a,b,c,d,e){var s,r=J.bi(c),q=d*17,p=e.length,o=0
for(;;){if(!(o<p&&b>0&&r.gm(c)<3))break
A:{s=e[A.a.D(Math.abs(q+o*37),p)].a
if(r.p(c,s))break A
r.n(c,s);--b}++o}},
nB(a,b){var s=a.aN(b),r=a.d8.h(0,b.b)
return Math.max(0,s-(r==null?0:r))},
f8(a,a0,a1){var s=0,r=B.D(t.bz),q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b
var $async$f8=B.E(function(a2,a3){if(a2===1)return B.A(a3,r)
for(;;)switch(s){case 0:b=a0.b
if(!A.b.N(B.f5(a,b),new B.iy(a0))){q=A.bN
s=1
break}p=a.ok
p===$&&B.N()
if(p.f===A.h&&a.x2.length===0){q=A.bL
s=1
break}if(b===A.W){q=A.bM
s=1
break}if(a0.cy){q=A.bM
s=1
break}o=B.aH(a)
p=new B.aB(o,B.q(o).i("aB<1,Y?>"))
n=p.a7(p,new B.iz(a1,o),new B.iA())
if(n==null){q=A.bL
s=1
break}if(n.fx!=null){q=A.dL
s=1
break}m=a.b.$0()
if(a0.ax){p=B.f2(a,m)
l=B.q(p)
k=l.i("j<1>")
p=B.k(new B.j(p,l.i("i(1)").a(new B.iB(a0,a)),k),k.i("a.E"))
p.$flags=1
j=p
if(j.length===0){q=A.bN
s=1
break}i=A.b.gM(j)
a.bA.n(0,i.b)}else i=null
h=B.t8(a0,B.m([n],t.a))
p=a.c.$0()
l=a0.a
k=n.a
g=m.P(h.a)
f=a0.Q
if(f==null)f=B.n7(b,a.a.S())
e=i==null
d=e?null:i.a.a
c=new B.b4(p,l,k,m,g,A.as,f,1,d,e?null:i.b)
n.fx=p
A.b.n(a.a3,c)
s=3
return B.o(B.hP(a,c,n),$async$f8)
case 3:p=a.al.h(0,b)
if(p!=null)J.hd(p,l)
if(b===A.q)a.aH=m
else if(b===A.o)a.aC=m
s=4
return B.o(a.F(),$async$f8)
case 4:q=A.dK
s=1
break
case 1:return B.B(q,r)}})
return B.C($async$f8,r)},
hP(a,b,c){var s=0,r=B.D(t.H),q,p
var $async$hP=B.E(function(d,e){if(d===1)return B.A(e,r)
for(;;)switch(s){case 0:q=new B.bF(a.z)
p=q.I(c.gU()+" has returned",c.gU()+" is teruggekeerd")
s=2
return B.o(B.mE(b.e,q.I(u.t,"Er staat een Adventure-beloning klaar in DragonHaven."),"adventure-"+b.a,"adventure_complete",p),$async$hP)
case 2:return B.B(null,r)}})
return B.C($async$hP,r)},
ic(a,b){var s=0,r=B.D(t.H),q,p,o,n,m
var $async$ic=B.E(function(c,d){if(c===1)return B.A(d,r)
for(;;)switch(s){case 0:n=b.b
m=n===A.q
if(!m&&n!==A.o&&n!==A.z||A.b.N(a.a3,new B.id(b))){s=1
break}p=a.al.h(0,n)
if(p!=null)J.hd(p,b.a)
o=a.b.$0()
if(m)a.aH=o
else if(n===A.o)a.aC=o
else a.b0=B.dq(o)
s=3
return B.o(a.F(),$async$ic)
case 3:case 1:return B.B(q,r)}})
return B.C($async$ic,r)},
f6(a,b){var s=0,r=B.D(t.ca),q,p,o,n,m,l,k,j,i,h,g,f,e,d,c
var $async$f6=B.E(function(a0,a1){if(a0===1)return B.A(a1,r)
for(;;)switch(s){case 0:B.hJ(a)
p=A.b.d9(a.a3,new B.i0(b))
if(p>=0){o=a.a3
if(!(p>=0&&p<o.length)){q=B.b(o,p)
s=1
break}o=o[p].f!==A.aG}else o=!0
if(o){q=null
s=1
break}o=a.a3
if(!(p>=0&&p<o.length)){q=B.b(o,p)
s=1
break}n=o[p]
m=$.b2().h(0,n.b)
if(m==null){q=null
s=1
break}o=B.aH(a)
o=new B.aB(o,B.q(o).i("aB<1,Y?>"))
l=o.a7(o,new B.i1(n),new B.i2())
if(l==null){q=null
s=1
break}k=n.r
if(k==null)k=B.n7(m.b,a.a.S())
o=n.y
o=o==null?null:A.i.p(o,":preview:")
s=o===!0?3:4
break
case 3:l.fx=null
A.b.b8(a.a3,p)
s=5
return B.o(a.F(),$async$f6)
case 5:q=k
s=1
break
case 4:j=a.dG(l,m.w)
l.dZ(m.x,m.y)
a.cL(a.b.$0())
l.fx=null
i=B.mf(n.x)
o=i==null
h=o?null:i.as.f
if(h!=null)a.y1.aq(h,new B.i3(),new B.i4())
else a.xr.aq(k,new B.i5(),new B.i6())
if(!o){for(o=i.as,g=o.e.gav(),g=g.gq(g);g.l();){f=g.gu()
l.dZ(f.a,f.b)}e=o.c
g=e.length
if(g!==0){f=a.a.C(g)
if(!(f>=0&&f<g)){q=B.b(e,f)
s=1
break}a.dH(e[f])}if(o.d&&!a.geg())a.xr.aq(A.p,new B.i7(),new B.i8())
d=o.r
if(d!=null){g=$.ni().h(0,d)
g=g!=null}else g=!1
if(g)a.az.n(0,d)
c=o.w
if(c!=null&&B.tn(c)!=null)a.c5.n(0,c)}A.b.b8(a.a3,p);++a.cb
o=m.b
if(o===A.o)++a.cc
if(o===A.W&&n.w>=4)++a.cd
if(m.as)++a.cf
a.eF(A.aY,l.gU()+" returned from "+m.c+".",m.a,A.b6,j)
a.a5()
s=6
return B.o(a.F(),$async$f6)
case 6:q=k
s=1
break
case 1:return B.B(q,r)}})
return B.C($async$f6,r)},
f4(a,b){var s=0,r=B.D(t.y),q,p,o,n,m,l,k
var $async$f4=B.E(function(c,d){if(c===1)return B.A(d,r)
for(;;)switch(s){case 0:B.hJ(a)
p=A.b.d9(a.a3,new B.hS(b))
if(p<0){q=!1
s=1
break}o=a.a3
if(!(p<o.length)){q=B.b(o,p)
s=1
break}n=o[p]
m=$.b2().h(0,n.b)
if(n.f!==A.as||m==null||m.b===A.W||m.cy){q=!1
s=1
break}o=B.aH(a)
o=new B.aB(o,B.q(o).i("aB<1,Y?>"))
l=o.a7(o,new B.hT(n),new B.hU())
o=l==null?null:l.fx
k=n.a
if(o===k)l.fx=null
A.b.b8(a.a3,p)
s=3
return B.o(B.jl("adventure-"+k),$async$f4)
case 3:s=4
return B.o(a.F(),$async$f4)
case 4:q=!0
s=1
break
case 1:return B.B(q,r)}})
return B.C($async$f4,r)},
hJ(a){var s,r,q,p,o,n,m,l,k,j,i=a.b.$0()
for(s=i.a,r=i.b,q=a.a,p=!1,o=0;n=a.a3,o<n.length;++o){m=n[o]
if(m.f===A.as){n=m.e
l=n.a
if(l<=s)n=l===s&&n.b>r
else n=!0
n=!n}else n=!1
if(n){n=m.b
k=$.b2().h(0,n)
l=m.r
if(l==null){l=k==null?null:k.Q
j=l}else j=l
if(j==null){l=k==null?null:k.b
if(l==null)l=A.o
j=B.n7(l,q.S())}l=a.a3
A.b.j(l,o,new B.b4(m.a,n,m.c,m.d,m.e,A.aG,j,m.w,m.x,m.y))
p=!0}}return p},
il(a,b){var s=0,r=B.D(t.y),q,p,o,n,m,l,k
var $async$il=B.E(function(c,d){if(c===1)return B.A(d,r)
for(;;)switch(s){case 0:m=B.aH(a)
l=new B.aB(m,B.q(m).i("aB<1,Y?>"))
k=l.a7(l,new B.im(b),new B.io())
if(k==null||k.db||k.fx!=null||m.length<=1){q=!1
s=1
break}l=k.a
p=a.ok
p===$&&B.N()
o=a.x2
if(l===p.a){n=A.b.b8(o,0)
p=a.ok
n.d=p.d
n.e=p.e
A.b.n(a.x2,p)
a.ok=n
A.b.a1(a.x2,new B.ip(k))}else A.b.a1(o,new B.iq(k))
k.db=!1
if(a.aF===l)a.aF=null
A.b.n(a.b1,k)
B.mt(a)
B.hF(a)
s=3
return B.o(a.F(),$async$il)
case 3:q=!0
s=1
break
case 1:return B.B(q,r)}})
return B.C($async$il,r)},
i_(a,b){var s=0,r=B.D(t.mV),q,p,o,n,m,l
var $async$i_=B.E(function(c,d){if(c===1)return B.A(d,r)
for(;;)switch(s){case 0:l=$.dd().h(0,b)
if(l==null||l.a==="nest"){q=A.RG
s=1
break}p=a.L
o=p.length
if(o>=20){q=A.RE
s=1
break}n=(120+o*85)*10
o=a.ok
o===$&&B.N()
m=o.d
if(m<n){q=A.RF
s=1
break}o.d=m-n
o=l.a
A.b.n(p,o)
a.aQ.n(0,o)
a.aR=o
a.a5()
s=3
return B.o(a.F(),$async$i_)
case 3:q=A.RD
s=1
break
case 1:return B.B(q,r)}})
return B.C($async$i_,r)},
ir(a,b){var s=0,r=B.D(t.y),q,p,o,n
var $async$ir=B.E(function(c,d){if(c===1)return B.A(d,r)
for(;;)switch(s){case 0:if(!a.aj.p(0,b)||b>=a.L.length){q=!1
s=1
break}p=B.pJ(a,b)
o=a.ok
o===$&&B.N()
n=o.d
if(n<p){q=!1
s=1
break}o.d=n-p
a.aj.X(0,b)
a.bz.X(0,b)
s=3
return B.o(a.F(),$async$ir)
case 3:q=!0
s=1
break
case 1:return B.B(q,r)}})
return B.C($async$ir,r)},
pJ(a,b){var s,r,q
if(b<0||b>=a.L.length)return 0
s=a.L
if(!(b>=0&&b<s.length))return B.b(s,b)
s=s[b]
r=$.dd().h(0,s)
q=a.bz.h(0,b)
if(q==null)q=0.4
s=r==null?null:r.c
return Math.max(1,A.c.cq((s==null?100:s)*q*10))},
pC(a){var s=a.b.$0(),r=a.bf,q=r.a
r.a1(0,new B.hC(s))
return a.bf.a!==q},
iC(a){var s=0,r=B.D(t.y),q,p,o,n,m
var $async$iC=B.E(function(b,c){if(b===1)return B.A(c,r)
for(;;)switch(s){case 0:m=a.by
if(m>=3||a.aj.a===0){q=!1
s=1
break}p=[0,150,400,850];++m
if(!(m>=0&&m<4)){q=B.b(p,m)
s=1
break}o=p[m]
p=a.ok
p===$&&B.N()
n=p.d
if(n<o){q=!1
s=1
break}p.d=n-o
a.by=m
s=3
return B.o(a.F(),$async$iC)
case 3:q=!0
s=1
break
case 1:return B.B(q,r)}})
return B.C($async$iC,r)},
ik(a,b,c){var s=0,r=B.D(t.N),q,p,o,n,m,l,k,j
var $async$ik=B.E(function(d,e){if(d===1)return B.A(e,r)
for(;;)switch(s){case 0:j=A.i.a9(b)
if(j.length!==0){p=B.L("^[A-Z0-9]+$")
p=!p.b.test(j)}else p=!0
if(p){q="invalid_format"
s=1
break}o=$.p2().h(0,j)
if(o==null){q="inactive"
s=1
break}n=o.d
if(n!=null&&c!==n){q="restricted"
s=1
break}case 3:switch(1){case 1:s=5
break
default:s=4
break}break
case 5:m=B.mf(o.c)
if(m==null||m.db<=0){q="inactive"
s=1
break}l=a.b.$0()
p=a.b4
k=m.a
p=p.h(0,k)
if((p==null?null:p.ac(l))===!0){q="preview_active"
s=1
break}a.b4.j(0,k,l.P(B.ah(0,m.db,0,0,0,0).a))
a.aG=null
s=6
return B.o(a.F(),$async$ik)
case 6:q="redeemed_event_preview"
s=1
break
case 4:case 1:return B.B(q,r)}})
return B.C($async$ik,r)},
pB(a,b,c,d){var s,r,q,p=c.d
A:{if("ember"===p||"solar"===p){s=b.I("The shell feels unusually warm.","De schaal voelt ongewoon warm.")
break A}if("tide"===p||"abyssal"===p){s=b.I(u.i,"Je hoort iets dat bijna op golven lijkt.")
break A}if("tempest"===p){s=b.I("A tiny spark skips across the shell.","Een piepklein vonkje danst over de schaal.")
break A}if("moon"===p||"eclipse"===p||"cosmic"===p){s=b.I(u.L,"Het ei wordt onrustig zodra de sterren verschijnen.")
break A}if("wildwood"===p||"bloom"===p||"earthlight"===p||"primordial"===p){s=b.I(u.c,"Het nest ruikt plotseling naar regen en mos.")
break A}s=b.I(u.V,"Er klinkt een vreemd muzikaal tikje van binnen.")
break A}if(!c.cx)return s
r=d==null?null:d.a
B:{if("witchlight_egg_v1"===r){q=b.I(u.A,"Een waakzame groene vlam krult rond de schaal. Dit ei voelt verbonden met een zeldzame herfstnacht.")
break B}if("starlit_evergreen_egg_v1"===r){q=b.I(u._,"Een winterster lijkt onder de schaal te ademen. Dit ei draagt de warmte van een bijzondere haard.")
break B}if("turning_year_egg_v1"===r){q=b.I(u.q,"Een verre klok antwoordt het eerste licht binnenin. Dit ei hoort bij een jaarwende.")
break B}if("rosebound_egg_v1"===r){q=b.I(u.M,"Twee zachte hartslagen klinken door de schaal. Dit ei herinnert zich een gedeelde belofte.")
break B}if("truecolor_egg_v1"===r){q=b.I(u.X,"Elke kleur schittert zonder een andere te verbergen. Dit ei voelt vreugdevol en onmiskenbaar bijzonder.")
break B}q=b.I(u.r,"Rond dit ei blijft een zachte gouden warmte hangen, alsof het een wens draagt voor iemand die echt bijzonder is.")
break B}return s+"\n\n"+q},
pE(a){var s,r,q,p,o
if(a.b1.length===0)return!1
s=a.b.$0()
r=a.b2
q=(r==null?null:r.ac(s))===!1
if(q){a.b2=null
B.nz(a,s)}p=B.dq(s)
if(a.c2!==p){a.c2=p
o=s.c?B.cM(B.aj(s),B.aU(s),B.aT(s),0,0):B.cm(B.aj(s),B.aU(s),B.aT(s),0,0)
r=a.a
a.b2=r.S()<0.1?o.P(B.ah(0,0,0,0,0,r.C(86400)).a):null
q=!0}r=a.b2
if((r==null?null:r.ac(s))===!1){a.b2=null
B.nz(a,s)
q=!0}return q},
nz(a,b){var s,r=u.z,q=u.G,p=a.b1,o=a.a.C(p.length)
if(!(o>=0&&o<p.length))return B.b(p,o)
s=p[o];++a.ce
p=a.bg
if((p==null?null:p.ac(b))!==!0)a.bg=a.b3=null
switch(B.pG(a,s).a){case 0:B.f3(a,s,A.F)
break
case 1:B.f3(a,s,A.M)
break
case 2:B.f3(a,s,A.t)
break
case 3:B.f3(a,s,A.G)
break
case 4:B.f3(a,s,A.H)
break
case 5:B.nv(a,s,b)
break
case 6:if(a.b3==null)B.nu(a,s,b,!1)
else B.nv(a,s,b)
break
case 12:if(a.b3==null)B.nu(a,s,b,!0)
else a.ae=s.f===A.I?s.gU()+r:s.gU()+q
break
case 9:B.ms(a,s,0.25,!1)
break
case 10:B.ms(a,s,0.4,!1)
break
case 11:B.ms(a,s,0.6,!0)
break
case 8:p=s.gU()
a.ae=p+q
break
case 14:p=s.gU()
a.ae=p+r
break
case 13:a.ae=s.gU()+" was spotted near the Tower, then vanished."
break
case 7:a.ae=s.gU()+" passed nearby without leaving a reward or causing harm."
break}a.a5()},
pG(a,b){var s,r,q,p,o,n=a.a.C(100)
for(s=B.pF(a,b),r=s.length,q=0;q<r;++q){p=s[q]
o=p.a
if(n<o)return p.b
n-=o}return A.ah},
f3(a,b,c){a.xr.aq(c,new B.hD(),new B.hE())
a.ae=b.gU()+" returned with a "+B.po(c,!1)+"."},
nv(a,b,c){var s,r,q=24
switch(b.f.a){case 1:break
case 2:q=48
break
case 3:q=72
break
case 0:break
default:q=null}a.bf.j(0,b.a,c.P(B.ah(0,q,0,0,0,0).a))
s=B.pA(a,b)
if(s!=null)if(b.fr===s){r=a.L
if(s>>>0!==s||s>=r.length)return B.b(r,s)
r=r[s]!==b.dy}else r=!0
else r=!1
if(r){b.fr=s
r=a.L
if(s>>>0!==s||s>=r.length)return B.b(r,s)
b.dy=r[s]}a.ae=b.gU()+" is visiting the Dragon Tower for "+B.z(q)+" hours."},
mt(a){var s,r,q,p,o,n,m=B.aH(a)
if(m.length===0)return
s=B.q(m)
r=s.i("j<1>")
q=B.k(new B.j(m,s.i("i(1)").a(new B.hA()),r),r.i("a.E"))
A.b.b_(q,new B.hB())
p=q.length===0?A.b.gM(m):A.b.gM(q)
for(s=m.length,r=p.a,o=0;o<s;++o){n=m[o]
n.db=n.a===r}},
mu(a,b,c){var s=B.aH(a),r=B.q(s)
s=B.k(new B.j(s,r.i("i(1)").a(new B.hQ()),r.i("j<1>")),t.x)
A.b.A(s,B.nA(a))
r=B.q(s)
return new B.j(s,r.i("i(1)").a(new B.hR(c,A.af,b)),r.i("j<1>")).gm(0)},
pA(a,b){var s,r,q,p,o,n=B.m([],t.t)
for(s=b.a,r=0;r<a.L.length;++r)if(!a.aj.p(0,r)&&B.mu(a,r,s)<3)n.push(r)
if(n.length===0)return null
if(A.b.p(n,b.fr)){s=a.L
q=b.fr
if(!(q>=0&&q<s.length))return B.b(s,q)
q=s[q]===b.dy
s=q}else s=!1
if(s)return b.fr
s=t.fT
s=B.k(new B.j(n,t.gw.a(new B.hy(a,b)),s),s.i("a.E"))
s.$flags=1
p=s
o=p.length===0?n:p
A.b.b_(o,new B.hz(a))
return A.b.gM(o)},
hF(a){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b
if(a.L.length===0)return!1
s=B.aH(a)
r=B.m(s.slice(0),B.q(s))
A.b.b_(r,new B.hG())
s=t.S
q=B.n(s,s)
for(p=r.length,o=t.t,n=!1,m=0,l=0;l<r.length;r.length===p||(0,B.Z)(r),++l){k=r[l]
j=!0
if(!k.dx)continue
i=a.L.length
if(m>=i*3){k.dx=!1
n=j
continue}h=k.fr
g=!1
if(h>=0)if(h<i){if(!a.aj.p(0,h)){i=a.L
if(!(h<i.length))return B.b(i,h)
if(i[h]===k.dy){i=q.h(0,h)
i=(i==null?0:i)<3}else i=g}else i=g
g=i}if(g)f=h
else{e=a.L.length
d=B.m(new Array(e),o)
for(c=0;c<e;++c)d[c]=c
i=B.q(d)
f=B.kN(new B.j(d,i.i("i(1)").a(new B.hH(a,q)),i.i("j<1>")),s)}if(f==null){k.dx=!1
n=j
continue}if(k.fr===f){i=k.dy
b=a.L
if(f>>>0!==f||f>=b.length)return B.b(b,f)
b=i!==b[f]
i=b}else i=!0
if(i)n=!0
k.fr=f
i=a.L
if(f>>>0!==f||f>=i.length)return B.b(i,f)
k.dy=i[f]
i=q.h(0,f)
q.j(0,f,(i==null?0:i)+1);++m}return n},
nu(a,b,c,d){var s,r,q,p,o
if(d){s=$.mk()
r=90+A.a.D(Math.abs(b.RG),10)
if(!(r<s.length))return B.b(s,r)
q=s[r]}else{s=$.mk()
r=0
switch(b.f.a){case 1:break
case 2:r=30
break
case 3:r=60
break
case 0:break
default:r=null}p=A.a.D(Math.abs(b.RG),30)
if(typeof r!=="number")return r.h8()
p=r+p
if(!(p<s.length))return B.b(s,p)
q=s[p]}s=q.a
a.b3=s
a.bg=c.P(1728e8)
a.ae=d?b.gU()+" left a Sinister Adventure. It is available for 48 hours.":b.gU()+" revealed a Special Adventure. It is available for 48 hours."
o=new B.bF(a.z)
r=o.I("A Special Adventure has appeared","Er is een Speciaal Avontuur verschenen")
B.ff(null,o.I(b.gU()+" revealed a rare route. It is available for 48 hours.",b.gU()+" onthulde een zeldzame route. Deze is 48 uur beschikbaar."),"returning-special-"+s+"-"+c.a,r)},
ms(a,b,c,d){var s,r,q,p,o,n,m=a.L.length,l=J.mI(m,t.S)
for(s=0;s<m;++s)l[s]=s
r=B.q(l)
q=r.i("j<1>")
r=B.k(new B.j(l,r.i("i(1)").a(new B.hw(a)),q),q.i("a.E"))
r.$flags=1
p=r
if(p.length===0){a.ae=d?b.gU()+u.z:b.gU()+u.G
return}r=[0,0.5,0.75,0.9]
q=a.by
if(!(q>=0&&q<4))return B.b(r,q)
o=r[q]
r=a.a
if(r.S()<o){a.ae="Dragon Repelled! The Dragon Ward protected the Tower from "+b.gU()+"."
return}if(b.Q===A.T)n=A.b.ej(p,new B.hx(a))
else{r=r.C(p.length)
if(!(r>=0&&r<p.length))return B.b(p,r)
n=p[r]}a.aj.n(0,n)
a.bz.j(0,n,c)
a.ae=b.gU()+" damaged floor "+(n+1)+". Repair costs "+A.c.cq(c*100)+"% of the room price."},
pF(a6,a7){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2=null,a3=a7.f,a4=a7.as,a5=a7.Q
A:{s=A.aj===a3
r=s
q=a2
p=a2
o=!1
n=a2
m=!1
l=!1
if(r){q=A.C===a4
r=q
if(r){p=A.T===a5
r=p
n=a5
o=!0
m=!0}else r=l
k=a4
j=!0
i=!0}else{r=l
k=a2
j=!1
i=!1}if(r){r=A.qa
break A}h=a2
g=!1
r=!1
if(s){if(j)l=q
else{if(i)l=k
else{l=a4
k=l
i=!0}q=A.C===l
l=q
j=!0}if(l){if(m)r=n
else{r=a5
n=r
m=!0}h=A.a_===r
r=h
g=!0}}if(r){r=A.KP
break A}f=a2
e=!1
r=!1
if(s){if(j)l=q
else{if(i)l=k
else{l=a4
k=l
i=!0}q=A.C===l
l=q
j=!0}if(l){if(m)r=n
else{r=a5
n=r
m=!0}f=A.a0===r
r=f
e=!0}}if(r){r=A.AL
break A}d=a2
r=!1
if(s){if(i)l=k
else{l=a4
k=l
i=!0}d=A.U===l
l=d
if(l)if(o)r=p
else{if(m)r=n
else{r=a5
n=r
m=!0}p=A.T===r
r=p
o=!0}c=!0}else c=!1
if(r){r=A.ve
break A}r=!1
if(s){if(c)l=d
else{if(i)l=k
else{l=a4
k=l
i=!0}d=A.U===l
l=d
c=!0}if(l)if(g)r=h
else{if(m)r=n
else{r=a5
n=r
m=!0}h=A.a_===r
r=h
g=!0}}if(r){r=A.xX
break A}r=!1
if(s){if(c)l=d
else{if(i)l=k
else{l=a4
k=l
i=!0}d=A.U===l
l=d
c=!0}if(l)if(e)r=f
else{if(m)r=n
else{r=a5
n=r
m=!0}f=A.a0===r
r=f
e=!0}}if(r){r=A.ky
break A}b=a2
r=!1
if(s){if(i)l=k
else{l=a4
k=l
i=!0}b=A.D===l
l=b
if(l)if(o)r=p
else{if(m)r=n
else{r=a5
n=r
m=!0}p=A.T===r
r=p
o=!0}a=!0}else a=!1
if(r){r=A.lp
break A}r=!1
if(s){if(a)l=b
else{if(i)l=k
else{l=a4
k=l
i=!0}b=A.D===l
l=b
a=!0}if(l)if(g)r=h
else{if(m)r=n
else{r=a5
n=r
m=!0}h=A.a_===r
r=h
g=!0}}if(r){r=A.AV
break A}r=!1
if(s){if(a)l=b
else{if(i)l=k
else{l=a4
k=l
i=!0}b=A.D===l
l=b
a=!0}if(l)if(e)r=f
else{if(m)r=n
else{r=a5
n=r
m=!0}f=A.a0===r
r=f
e=!0}}if(r){r=A.lU
break A}a0=A.a7===a3
r=a0
l=!1
if(r){if(j)r=q
else{if(i)r=k
else{r=a4
k=r
i=!0}q=A.C===r
r=q
j=!0}if(r)if(o)r=p
else{if(m)r=n
else{r=a5
n=r
m=!0}p=A.T===r
r=p
o=!0}else r=l}else r=l
if(r){r=A.BG
break A}r=!1
if(a0){if(j)l=q
else{if(i)l=k
else{l=a4
k=l
i=!0}q=A.C===l
l=q
j=!0}if(l)if(g)r=h
else{if(m)r=n
else{r=a5
n=r
m=!0}h=A.a_===r
r=h
g=!0}}if(r){r=A.Jc
break A}r=!1
if(a0){if(j)l=q
else{if(i)l=k
else{l=a4
k=l
i=!0}q=A.C===l
l=q
j=!0}if(l)if(e)r=f
else{if(m)r=n
else{r=a5
n=r
m=!0}f=A.a0===r
r=f
e=!0}}if(r){r=A.nN
break A}r=!1
if(a0){if(c)l=d
else{if(i)l=k
else{l=a4
k=l
i=!0}d=A.U===l
l=d
c=!0}if(l)if(o)r=p
else{if(m)r=n
else{r=a5
n=r
m=!0}p=A.T===r
r=p
o=!0}}if(r){r=A.t0
break A}r=!1
if(a0){if(c)l=d
else{if(i)l=k
else{l=a4
k=l
i=!0}d=A.U===l
l=d
c=!0}if(l)if(g)r=h
else{if(m)r=n
else{r=a5
n=r
m=!0}h=A.a_===r
r=h
g=!0}}if(r){r=A.GZ
break A}r=!1
if(a0){if(c)l=d
else{if(i)l=k
else{l=a4
k=l
i=!0}d=A.U===l
l=d
c=!0}if(l)if(e)r=f
else{if(m)r=n
else{r=a5
n=r
m=!0}f=A.a0===r
r=f
e=!0}}if(r){r=A.At
break A}r=!1
if(a0){if(a)l=b
else{if(i)l=k
else{l=a4
k=l
i=!0}b=A.D===l
l=b
a=!0}if(l)if(o)r=p
else{if(m)r=n
else{r=a5
n=r
m=!0}p=A.T===r
r=p
o=!0}}if(r){r=A.yC
break A}r=!1
if(a0){if(a)l=b
else{if(i)l=k
else{l=a4
k=l
i=!0}b=A.D===l
l=b
a=!0}if(l)if(g)r=h
else{if(m)r=n
else{r=a5
n=r
m=!0}h=A.a_===r
r=h
g=!0}}if(r){r=A.tx
break A}r=!1
if(a0){if(a)l=b
else{if(i)l=k
else{l=a4
k=l
i=!0}b=A.D===l
l=b
a=!0}if(l)if(e)r=f
else{if(m)r=n
else{r=a5
n=r
m=!0}f=A.a0===r
r=f
e=!0}}if(r){r=A.Iq
break A}a1=A.I===a3
r=a1
l=!1
if(r){if(j)r=q
else{if(i)r=k
else{r=a4
k=r
i=!0}q=A.C===r
r=q
j=!0}if(r)if(o)r=p
else{if(m)r=n
else{r=a5
n=r
m=!0}p=A.T===r
r=p
o=!0}else r=l}else r=l
if(r){r=A.JZ
break A}r=!1
if(a1){if(j)l=q
else{if(i)l=k
else{l=a4
k=l
i=!0}q=A.C===l
l=q
j=!0}if(l)if(g)r=h
else{if(m)r=n
else{r=a5
n=r
m=!0}h=A.a_===r
r=h
g=!0}}if(r){r=A.IL
break A}r=!1
if(a1){if(j)l=q
else{if(i)l=k
else{l=a4
k=l
i=!0}q=A.C===l
l=q}if(l)if(e)r=f
else{if(m)r=n
else{r=a5
n=r
m=!0}f=A.a0===r
r=f
e=!0}}if(r){r=A.tU
break A}r=!1
if(a1){if(c)l=d
else{if(i)l=k
else{l=a4
k=l
i=!0}d=A.U===l
l=d
c=!0}if(l)if(o)r=p
else{if(m)r=n
else{r=a5
n=r
m=!0}p=A.T===r
r=p
o=!0}}if(r){r=A.xO
break A}r=!1
if(a1){if(c)l=d
else{if(i)l=k
else{l=a4
k=l
i=!0}d=A.U===l
l=d
c=!0}if(l)if(g)r=h
else{if(m)r=n
else{r=a5
n=r
m=!0}h=A.a_===r
r=h
g=!0}}if(r){r=A.C7
break A}r=!1
if(a1){if(c)l=d
else{if(i)l=k
else{l=a4
k=l
i=!0}d=A.U===l
l=d}if(l)if(e)r=f
else{if(m)r=n
else{r=a5
n=r
m=!0}f=A.a0===r
r=f
e=!0}}if(r){r=A.zp
break A}r=!1
if(a1){if(a)l=b
else{if(i)l=k
else{l=a4
k=l
i=!0}b=A.D===l
l=b
a=!0}if(l)if(o)r=p
else{if(m)r=n
else{r=a5
n=r
m=!0}p=A.T===r
r=p}}if(r){r=A.Ji
break A}r=!1
if(a1){if(a)l=b
else{if(i)l=k
else{l=a4
k=l
i=!0}b=A.D===l
l=b
a=!0}if(l)if(g)r=h
else{if(m)r=n
else{r=a5
n=r
m=!0}h=A.a_===r
r=h}}if(r){r=A.yo
break A}r=!1
if(a1){if(a)l=b
else{b=A.D===(i?k:a4)
l=b}if(l)if(e)r=f
else{f=A.a0===(m?n:a5)
r=f}}if(r){r=A.Jn
break A}r=A.wS
break A}return r},
dn(a,b){var s,r,q,p,o=a.p3.r.h(0,b)
if(o==null)o=A.aH
for(s=a.p2,r=B.q(s),q=r.i("i(1)").a(new B.iW(b)),s=A.b.gq(s),r=new B.bx(s,q,r.i("bx<1>"));r.l();){q=s.gu()
p=o.aJ(q.ax)
o=p.aJ(new B.aP(!1,0,q.as||q.b==="sinisterra",!1,!1,!1))}s=a.ok
s===$&&B.N()
s=B.m([s],t.a)
A.b.A(s,a.x2)
r=a.p1
if(r!=null)s.push(r)
r=t.gO.a(new B.iX(b))
s=A.b.gq(s)
r=new B.bx(s,r,t.oz)
while(r.l()){q=s.gu()
o=o.aJ(q.ax).aJ(new B.aP(!1,0,q.ay,q.at,!1,!1))}return o.aJ(new B.aP(!1,0,!1,!1,a.aT.p(0,b),!1))},
nE(a,b){var s,r,q
if(a.p3.w.p(0,b))return"already_returned"
s=a.ok
s===$&&B.N()
if(!(s.f===A.h))s=a.p1
if((s==null?null:s.a)===b)return"egg_in_nest"
s=a.p2
r=B.q(s)
q=B.kN(new B.j(s,r.i("i(1)").a(new B.j1(b)),r.i("j<1>")),t.R)
if(q==null)return"egg_not_found"
if(B.ci(q.b).ax===A.a6||q.Q!=null)return"special_egg"
if(B.dn(a,b).a)return"egg_tagged"
if(a.bE.p(0,b))return"egg_reserved"
return null},
j_(a,b,c){var s=0,r=B.D(t.H)
var $async$j_=B.E(function(d,e){if(d===1)return B.A(e,r)
for(;;)switch(s){case 0:s=2
return B.o(B.cn(a,"tag",B.V(["eggId",b,"tagged",c],t.N,t.z),null),$async$j_)
case 2:return B.B(null,r)}})
return B.C($async$j_,r)},
iZ(a,b,c){var s=0,r=B.D(t.eL),q,p,o,n,m,l
var $async$iZ=B.E(function(d,e){if(d===1)return B.A(e,r)
for(;;)switch(s){case 0:p=t.N
o=t.z
n=B
m=B
l=t.f
s=3
return B.o(B.cn(a,"return",B.V(["eggId",b,"sinisterConfirmed",c],p,o),"return:"+b),$async$iZ)
case 3:q=n.nZ(m.aw(l.a(e.h(0,"reward")),p,o))
s=1
break
case 1:return B.B(q,r)}})
return B.C($async$iZ,r)},
iV(a,b){var s=0,r=B.D(t.H)
var $async$iV=B.E(function(c,d){if(c===1)return B.A(d,r)
for(;;)switch(s){case 0:s=2
return B.o(B.cn(a,"craft",B.V(["relic",b.b],t.N,t.z),null),$async$iV)
case 2:return B.B(null,r)}})
return B.C($async$iV,r)},
j0(a,b,c){var s=0,r=B.D(t.H)
var $async$j0=B.E(function(d,e){if(d===1)return B.A(e,r)
for(;;)switch(s){case 0:s=2
return B.o(B.cn(a,"reveal",B.V(["relic",b.b,"eggId",c],t.N,t.z),null),$async$j0)
case 2:return B.B(null,r)}})
return B.C($async$j0,r)},
iY(a,b,c){return B.pO(a,b,c)},
pO(a,b,c){var s=0,r=B.D(t.y),q,p=2,o=[],n,m,l,k
var $async$iY=B.E(function(d,e){if(d===1){o.push(e)
s=p}for(;;)switch(s){case 0:m=A.i.a9(c)
l=a.bZ(b)
if(l==null||l.f===A.h||A.i.a9(l.b).length===0||J.bB(m)===0||new B.cY(m).gm(0)>24||J.F(m,A.i.a9(l.b))){q=!1
s=1
break}p=4
s=7
return B.o(B.cn(a,"rename",B.V(["dragonId",b,"name",m],t.N,t.z),null),$async$iY)
case 7:q=!0
s=1
break
p=2
s=6
break
case 4:p=3
k=o.pop()
if(B.b9(k) instanceof B.aE){q=!1
s=1
break}else throw k
s=6
break
case 3:s=2
break
case 6:case 1:return B.B(q,r)
case 2:return B.A(o.at(-1),r)}})
return B.C($async$iY,r)},
cn(a,b,c,d){return B.pN(a,b,c,d)},
pN(b3,b4,b5,b6){var s=0,r=B.D(t.P),q,p=2,o=[],n=[],m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2
var $async$cn=B.E(function(b7,b8){if(b7===1){o.push(b8)
s=p}for(;;)switch(s){case 0:if(b3.ry)throw B.f(A.iA)
a1=b3.rx
m=a1==null?null:a1.$0()
if(b3.to&&m==null)throw B.f(A.bc)
a1=b3.p3.a
if(a1!=null&&!J.F(m,a1))throw B.f(A.bc)
a2=b3.x1
a1=a2==null
if(!a1)if(J.F(a2.h(0,"action"),b4)){a3=t.N
a4=t.z
a4=!B.tr(B.aw(t.f.a(a2.h(0,"payload")),a3,a4),b5,a3,a4)
a3=a4}else a3=!0
else a3=!1
if(a3)throw B.f(A.iB)
a3=B.b0(a1?null:a2.h(0,"id"))
a5=a3==null?b6:a3
l=a5==null?b3.c.$0():a5
k=B.nD(b3.p3.H())
a1=b3.p2
a3=B.q(a1)
a4=a3.i("K<1,ao>")
a6=B.k(new B.K(a1,a3.i("ao(1)").a(new B.iU()),a4),a4.i("a4.E"))
j=a6
a1=t.N
i=B.a3(b3.aT,a1)
a3=B.n(a1,t.iY)
a4=b3.ok
a4===$&&B.N()
a7=t.a
a4=B.m([a4],a7)
A.b.A(a4,b3.x2)
a8=b3.p1
if(a8!=null)a4.push(a8)
a8=a4.length
a9=0
for(;a9<a4.length;a4.length===a8||(0,B.Z)(a4),++a9){b0=a4[a9]
a3.j(0,b0.a,new B.eE(b0.ax,b0.ay,b0.at))}h=a3
a1=B.n(a1,a1)
for(a3=B.aH(b3),a4=a3.length,a9=0;a9<a3.length;a3.length===a4||(0,B.Z)(a3),++a9){b0=a3[a9]
a1.j(0,b0.a,b0.b)}g=a1
f=!1
b3.ry=!0
p=4
e=null
e=B.pM(b3,l,b4,b5)
B.mx(b3)
b3.seh(null)
s=7
return B.o(b3.F(),$async$cn)
case 7:a1=e
q=a1
n=[1]
s=5
break
n.push(6)
s=5
break
case 4:p=3
b2=o.pop()
d=B.b9(b2)
s=!f?8:9
break
case 8:b3.sfo(k)
b3.sfs(j)
b3.sfq(i)
c=B.m([b3.ok],a7)
J.p5(c,b3.x2)
a1=b3.p1
if(a1!=null)J.bN(c,a1)
c=c
a1=c.length
a9=0
for(;a9<c.length;c.length===a1||(0,B.Z)(c),++a9){b=c[a9]
a=J.a2(h,b.a)
if(a!=null){b.ax=a.a
b.ay=a.b
b.at=a.c}}for(c=B.aH(b3),a1=c.length,a9=0;a9<c.length;c.length===a1||(0,B.Z)(c),++a9){a0=c[a9]
a3=J.a2(g,a0.a)
if(a3==null)a3=a0.b
a0.b=a3}s=d instanceof B.aE&&d.a!=="altar_unavailable"?10:11
break
case 10:b3.seh(null)
s=12
return B.o(b3.dQ(),$async$cn)
case 12:case 11:case 9:throw b2
n.push(6)
s=5
break
case 3:n=[2]
case 5:p=2
b3.ry=!1
s=n.pop()
break
case 6:case 1:return B.B(q,r)
case 2:return B.A(o.at(-1),r)}})
return B.C($async$cn,r)},
pM(a,b,c,d){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e=a.p3.y.h(0,b)
if(e!=null)return e
s=B.b0(d.h(0,"eggId"))
if(s==null)s=""
r=B.dn(a,s)
q=t.N
p=t.z
o=B.V(["action",c],q,p)
switch(c){case"tag":if(!A.b.N(a.p2,new B.iP(s))){n=a.ok
n===$&&B.N()
if(!(n.f===A.h))n=a.p1
n=(n==null?null:n.a)!==s}else n=!1
if(n)throw B.f(A.c3)
n=a.p3
p=B.bK(r.H(),q,p)
p.j(0,"tagged",J.F(d.h(0,"tagged"),!0))
q=a.b.$0()
p.j(0,"tagRevision",Math.max(1000*q.a+q.b,r.b+1))
n.r.j(0,s,B.cI(p))
break
case"return":m=B.nE(a,s)
if(m!=null)throw B.f(new B.aE(m))
q=A.b.fz(a.p2,new B.iQ(s)).b==="sinisterra"
if(q&&!J.F(d.h(0,"sinisterConfirmed"),!0))throw B.f(A.iG)
p=a.a
n=a.p3.d
l=p.S()
if(q)k=3+A.c.fA(l*3)
else k=l<0.25?1:0
p=p.S()
j=p<(q?0.1:0.02)||n>=39
q=q?25:5
p=j?1:0
n=a.p3
i=n.c
n.c=new B.bg(i.a+q,i.b+k,i.c+p)
n.d=p>0?0:n.d+1;++n.e
n.w.n(0,s)
o.j(0,"reward",new B.bg(q,k,p).H())
break
case"craft":h=B.kN(new B.j(A.aw,t.gY.a(new B.iR(d)),t.g1),t.p)
if(h==null)throw B.f(A.c4)
q=a.p3
p=q.c
n=B.nl(h)
i=p.a
if(!(i>=n.a&&p.b>=n.b&&p.c>=n.c))throw B.f(A.iD)
n=B.nl(h)
q.c=new B.bg(i-n.a,p.b-n.b,p.c-n.c)
q.f.j(0,h.b,q.bx(h)+1)
break
case"reveal":h=B.kN(new B.j(A.aw,t.gY.a(new B.iS(d)),t.g1),t.p)
if(h==null||h===A.aI)throw B.f(A.c4)
if(!A.b.N(a.p2,new B.iT(s))){n=a.ok
n===$&&B.N()
if(!(n.f===A.h))n=a.p1
n=(n==null?null:n.a)!==s}else n=!1
if(n)throw B.f(A.c3)
if(r.fN(h))throw B.f(A.iz)
if(a.bE.p(0,s))throw B.f(A.iC)
if(a.p3.bx(h)<=0)throw B.f(A.c5)
n=a.p3
n.f.j(0,h.b,n.bx(h)-1)
n=a.p3
p=B.bK(r.H(),q,p)
p.j(0,B.pl(h),!0)
if(h===A.bO)p.j(0,"rarity",!0)
n.r.j(0,s,B.cI(p))
break
case"rename":q=B.b0(d.h(0,"dragonId"))
g=a.bZ(q==null?"":q)
q=B.b0(d.h(0,"name"))
f=A.i.a9(q==null?"":q)
q=!0
if(g!=null)if(g.f!==A.h)if(f.length!==0)if(new B.cY(f).gm(0)<=24){q=A.i.a9(g.b)
q=q.length===0||q===f}if(q)throw B.f(A.iF)
if(a.p3.bx(A.aI)<=0)throw B.f(A.c5)
q=a.p3
q.f.j(0,"nameweaversQuill",q.bx(A.aI)-1)
a.p3.x.j(0,g.a,f)
break
case"donate":throw B.f(A.bc)
default:throw B.f(A.iE)}q=a.p3;++q.b
q.y.j(0,b,o)
return o},
mx(a){var s,r,q,p,o,n,m,l
A.b.a1(a.p2,new B.iN(a))
s=a.p3
r=a.p1
r=r==null?null:r.a
if(s.w.p(0,r))a.p1=null
for(s=a.p2,r=s.length,q=0;q<s.length;s.length===r||(0,B.Z)(s),++q){p=s[q]
p.ax=B.dn(a,p.a)}s=a.ok
s===$&&B.N()
s=B.m([s],t.a)
A.b.A(s,a.x2)
r=a.p1
if(r!=null)s.push(r)
r=s.length
q=0
for(;q<s.length;s.length===r||(0,B.Z)(s),++q){o=s[q]
n=o.a
m=o.ax=B.dn(a,n)
o.ay=A.B.ad(o.ay,m.c)
o.at=A.B.ad(o.at,m.d)
if(o.f!==A.h&&a.p3.x.J(n)){n=a.p3.x.h(0,n)
n.toString
o.b=n}}s=a.p2
r=B.q(s)
s=B.k(new B.K(s,r.i("d(1)").a(new B.iO()),r.i("K<1,d>")),t.N)
r=a.ok
n=r.f===A.h
if((n?r:a.p1)!=null)s.push((n?r:a.p1).a)
r=s.length
q=0
for(;q<s.length;s.length===r||(0,B.Z)(s),++q){l=s[q]
if(B.dn(a,l).e)a.aT.n(0,l)}},
n1(a){var s=a>=0.5?1:-1
return 1+0.5*s*Math.pow(Math.abs(2*a-1),2)},
q2(a6,a7,a8,a9,b0){var s,r,q,p,o,n,m,l,k,j,i,h,g,f=null,e=B.nF(t.H),d=t.N,c=B.dv(["reverie"],d),b=B.dv(["reverie"],d),a=B.dw(A.bi,t.eE),a0=B.m([],t.f_),a1=B.nC(f,f,0,f,f,f,f,0,0,A.S9),a2=t.a,a3=B.m([],a2),a4=t.S,a5=B.n(t.mW,a4)
for(s=0;s<10;++s)a5.j(0,A.ax[s],0)
r=t._
q=B.n(r,a4)
for(s=0;s<7;++s)q.j(0,A.ae[s],0)
r=B.n(r,a4)
for(s=0;s<7;++s)r.j(0,A.ae[s],0)
p=B.m([],t.t)
o=B.m([],t.f1)
n=B.m([],t.gT)
m=B.m([],t.iM)
l=t.s
k=B.V([A.q,B.m([],l),A.o,B.m([],l),A.z,B.m([],l)],t.lV,t.bF)
l=B.m(["hearth"],l)
a2=B.m([],a2)
j=t.h
i=B.dv(["nest"],d)
h=B.m([],t.hJ)
g=B.m([],t.iT)
return new B.jm(b0,a6,a7,!1,e,A.cd,c,b,B.a1(d),a,a0,a1,a3,a5,B.n(d,a4),q,r,B.a1(d),B.a1(d),B.a1(d),B.a1(d),B.a1(d),B.a1(d),B.a1(d),B.a1(d),p,B.a1(d),B.a1(d),B.a1(d),o,n,m,B.a1(d),B.n(d,a4),B.a1(d),B.a1(d),B.a1(d),B.a1(d),B.n(d,a4),B.n(d,a4),k,l,a2,B.a1(a4),B.n(a4,t.i),B.n(d,j),B.n(d,j),B.a1(d),B.a1(d),B.n(d,j),B.a1(d),B.n(d,a4),B.a1(d),B.n(t.iI,d),i,h,g)},
mG(a,b,c,d){var s,r,q,p,o=!0
if(J.F(a.h(0,"schemaVersion"),54)){s=t.f
if(s.b(a.h(0,"pet"))){o=s.a(a.h(0,"pet"))
o=o.gO(o)}}if(o)throw B.f(A.iJ)
r=B.j6(a)
q=B.q2(new B.jn(c),b,!1,!1,d)
q.f3(a)
B.mx(q)
p=B.j6(B.mz(a,q.c1()))
if(A.k.a_(B.cP(r.a),null)!==A.k.a_(B.cP(p.a),null)){q.bd()
throw B.f(B.dp("Canonical game state requires reconciliation: "+r.e4(p).aW(0,", "),null))}return q},
dq(a){return A.i.b7(A.a.v(B.aj(a)),4,"0")+"-"+A.i.b7(A.a.v(B.aU(a)),2,"0")+"-"+A.i.b7(A.a.v(B.aT(a)),2,"0")},
aD:function aD(a,b){this.a=a
this.b=b},
bQ:function bQ(a,b){this.a=a
this.b=b},
cy:function cy(a,b){this.a=a
this.b=b},
ak:function ak(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
mc:function mc(){},
md:function md(a){this.a=a},
hv:function hv(a){this.a=a},
ih:function ih(){},
ij:function ij(a){this.a=a},
ii:function ii(){},
it:function it(a,b){this.a=a
this.b=b},
is:function is(a,b){this.a=a
this.b=b},
iu:function iu(a,b){this.a=a
this.b=b},
iv:function iv(a,b){this.a=a
this.b=b},
iw:function iw(a,b){this.a=a
this.b=b},
ix:function ix(a){this.a=a},
hX:function hX(){},
hY:function hY(a,b){this.a=a
this.b=b},
hW:function hW(a){this.a=a},
hZ:function hZ(){},
iF:function iF(){},
iG:function iG(a,b,c){this.a=a
this.b=b
this.c=c},
iE:function iE(a){this.a=a},
hV:function hV(a){this.a=a},
hK:function hK(){},
hL:function hL(a){this.a=a},
hM:function hM(){},
hN:function hN(a){this.a=a},
hO:function hO(){},
ig:function ig(a){this.a=a},
ia:function ia(){},
ib:function ib(){},
hI:function hI(){},
iy:function iy(a){this.a=a},
iz:function iz(a,b){this.a=a
this.b=b},
iA:function iA(){},
iB:function iB(a,b){this.a=a
this.b=b},
id:function id(a){this.a=a},
i0:function i0(a){this.a=a},
i1:function i1(a){this.a=a},
i2:function i2(){},
i3:function i3(){},
i4:function i4(){},
i5:function i5(){},
i6:function i6(){},
i7:function i7(){},
i8:function i8(){},
hS:function hS(a){this.a=a},
hT:function hT(a){this.a=a},
hU:function hU(){},
im:function im(a){this.a=a},
io:function io(){},
ip:function ip(a){this.a=a},
iq:function iq(a){this.a=a},
hC:function hC(a){this.a=a},
hD:function hD(){},
hE:function hE(){},
hA:function hA(){},
hB:function hB(){},
hQ:function hQ(){},
hR:function hR(a,b,c){this.a=a
this.b=b
this.c=c},
hy:function hy(a,b){this.a=a
this.b=b},
hz:function hz(a){this.a=a},
hG:function hG(){},
hH:function hH(a,b){this.a=a
this.b=b},
hw:function hw(a){this.a=a},
hx:function hx(a){this.a=a},
iW:function iW(a){this.a=a},
iX:function iX(a){this.a=a},
j1:function j1(a){this.a=a},
iU:function iU(){},
iP:function iP(a){this.a=a},
iQ:function iQ(a){this.a=a},
iR:function iR(a){this.a=a},
iS:function iS(a){this.a=a},
iT:function iT(a){this.a=a},
iN:function iN(a){this.a=a},
iO:function iO(){},
c4:function c4(a,b){this.a=a
this.b=b},
ct:function ct(a,b){this.a=a
this.b=b},
cV:function cV(a,b){this.a=a
this.b=b},
ck:function ck(a,b){this.a=a
this.b=b},
cL:function cL(a,b){this.a=a
this.b=b},
cf:function cf(a,b){this.a=a
this.b=b},
cX:function cX(a,b){this.a=a
this.b=b},
d1:function d1(a,b){this.a=a
this.b=b},
cU:function cU(a,b){this.a=a
this.b=b},
cv:function cv(a,b){this.a=a
this.b=b},
jm:function jm(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,d0,d1,d2,d3,d4,d5,d6,d7){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.f=e
_.r=null
_.w=0
_.z="en"
_.Q=""
_.as=!1
_.at=!0
_.ax=f
_.ay=g
_.ch=h
_.CW=!1
_.cx=!0
_.cy=i
_.db=!0
_.dx=j
_.dy=!1
_.fr="gallery"
_.fx="acquiredAt"
_.fy=!0
_.go="tiles"
_.id="acquiredAt"
_.k1=!0
_.k3=_.k2=!1
_.ok=$
_.p1=null
_.p2=k
_.p3=l
_.rx=null
_.to=_.ry=!1
_.x1=null
_.x2=m
_.xr=n
_.y1=o
_.y2=p
_.aS=q
_.aE=r
_.c3=null
_.az=s
_.c4=null
_.d2=!1
_.c5=a0
_.d3=null
_.d4=a1
_.d5=null
_.e9=a2
_.bB=a3
_.ea=a4
_.aT=a5
_.bi=a6
_.bC=!1
_.aF=null
_.ap=a7
_.bD=a8
_.bj=a9
_.bk=b0
_.cg=_.cf=_.ce=_.cd=_.cc=_.cb=_.d7=_.ca=_.c9=_.aU=_.c8=_.c7=_.d6=_.c6=0
_.a3=b1
_.ab=b2
_.aG=null
_.W=0
_.bl=_.a0=""
_.a6=b3
_.aV=!1
_.ak=""
_.eb=b4
_.ec=b5
_.ed=b6
_.ee=b7
_.bE=b8
_.d8=b9
_.ci=c0
_.al=c1
_.aC=_.aH=null
_.b0=""
_.L=c2
_.b1=c3
_.by=0
_.aj=c4
_.bz=c5
_.bf=c6
_.e6=c7
_.c2=""
_.bg=_.b3=_.ae=_.b2=null
_.bA=c8
_.bh=c9
_.b4=d0
_.e7=d1
_.e8=d2
_.b5=d3
_.aP=d4
_.aQ=d5
_.aR="nest"
_.aw=d6
_.aD=d7},
jn:function jn(a){this.a=a},
jD:function jD(){},
jB:function jB(a){this.a=a},
jC:function jC(){},
jE:function jE(){},
jF:function jF(a){this.a=a},
jQ:function jQ(){},
jT:function jT(){},
jU:function jU(){},
jV:function jV(){},
jW:function jW(){},
jX:function jX(){},
jY:function jY(){},
jZ:function jZ(){},
jG:function jG(){},
jH:function jH(){},
jI:function jI(){},
jJ:function jJ(){},
jK:function jK(){},
jL:function jL(){},
jM:function jM(){},
jN:function jN(a){this.a=a},
jO:function jO(){},
jP:function jP(){},
jR:function jR(){},
jS:function jS(){},
kd:function kd(){},
kH:function kH(a){this.a=a},
kI:function kI(){},
kv:function kv(a){this.a=a},
ke:function ke(a){this.a=a},
kf:function kf(a){this.a=a},
kw:function kw(a){this.a=a},
kc:function kc(){},
kb:function kb(a){this.a=a},
kj:function kj(a){this.a=a},
kk:function kk(){},
kB:function kB(){},
kC:function kC(){},
kD:function kD(){},
kE:function kE(){},
ky:function ky(){},
kz:function kz(){},
kl:function kl(a){this.a=a},
jr:function jr(){},
js:function js(){},
jt:function jt(){},
ju:function ju(){},
kK:function kK(a){this.a=a},
kL:function kL(){},
kJ:function kJ(a){this.a=a},
jA:function jA(a){this.a=a},
ki:function ki(){},
kh:function kh(){},
kg:function kg(a){this.a=a},
kx:function kx(a){this.a=a},
k1:function k1(a){this.a=a},
jx:function jx(a){this.a=a},
jy:function jy(){},
jw:function jw(a){this.a=a},
jz:function jz(a){this.a=a},
jv:function jv(a){this.a=a},
k0:function k0(a){this.a=a},
jq:function jq(){},
ka:function ka(a){this.a=a},
k3:function k3(){},
k2:function k2(a){this.a=a},
k4:function k4(){},
k5:function k5(){},
k6:function k6(){},
k7:function k7(){},
k8:function k8(){},
k9:function k9(){},
kA:function kA(a){this.a=a},
kF:function kF(){},
kG:function kG(){},
k_:function k_(a){this.a=a},
jo:function jo(a){this.a=a},
jp:function jp(a){this.a=a},
km:function km(){},
kn:function kn(){},
ko:function ko(){},
kp:function kp(){},
kq:function kq(){},
kr:function kr(){},
ks:function ks(){},
kt:function kt(){},
ku:function ku(){},
tp(){var s=v.G
s.dragonhavenGameCommand=B.n2(new B.m7())
s.dragonhavenPrepareGameImport=B.n2(new B.m8())
s.dragonhavenProjectGame=B.n2(new B.m9())},
rF(a){var s,r,q=t.P,p=q.a(A.k.bc(a,null))
try{q=q.a(J.a2(p,"state"))
s=B.M(J.a2(p,"ownerId"))
q=A.k.a_(B.q1(B.hq(B.M(J.a2(p,"now"))),s,q),null)
return q}catch(r){if(B.b9(r) instanceof B.aI){q=t.N
return A.k.a_(B.V(["error","game_state_reconciliation_required"],q,q),null)}else throw r}},
rE(a){var s,r,q,p,o=null,n=t.P,m=n.a(A.k.bc(a,o))
try{q=B.M(J.a2(m,"ownerId"))
n=n.a(J.a2(m,"source"))
s=B.pW(t.dZ.a(J.a2(m,"authoritativeAltar")),B.hq(B.M(J.a2(m,"now"))),q,B.M(J.a2(m,"secretSeed")),n)
n=s.a
q=s.b
q=B.k(q,B.e(q).c)
A.b.cw(q)
n=A.k.a_(B.V(["protocol",2,"state",n,"changed_asset_kinds",q,"altar_revision",s.c],t.N,t.X),o)
return n}catch(p){n=B.b9(p)
if(n instanceof B.b6){r=n
n=t.N
return A.k.a_(B.V(["error",r.a],n,n),o)}else if(n instanceof B.aI){n=t.N
return A.k.a_(B.V(["error","game_import_reconciliation_required"],n,n),o)}else throw p}},
lT(a){var s=0,r=B.D(t.N),q,p=2,o=[],n,m,l,k,j,i,h,g,f,e,d
var $async$lT=B.E(function(b,c){if(b===1){o.push(c)
s=p}for(;;)switch(s){case 0:g=t.P
f=g.a(A.k.bc(a,null))
p=4
m=g.a(J.a2(f,"state"))
l=B.M(J.a2(f,"action"))
g=g.a(J.a2(f,"payload"))
k=B.M(J.a2(f,"secretSeed"))
j=B.hq(B.M(J.a2(f,"now")))
d=A.k
s=7
return B.o(B.U(l,B.M(J.a2(f,"keeperId")),j,g,k,m),$async$lT)
case 7:i=d.a_(c,null)
q=i
s=1
break
p=2
s=6
break
case 4:p=3
e=o.pop()
g=B.b9(e)
if(g instanceof B.bj){n=g
g=t.N
q=A.k.a_(B.V(["error",n.a],g,g),null)
s=1
break}else if(g instanceof B.aI){g=t.N
q=A.k.a_(B.V(["error","game_state_reconciliation_required"],g,g),null)
s=1
break}else throw e
s=6
break
case 3:s=2
break
case 6:case 1:return B.B(q,r)
case 2:return B.A(o.at(-1),r)}})
return B.C($async$lT,r)},
m7:function m7(){},
m8:function m8(){},
m9:function m9(){},
tw(a){throw B.as(new B.du("Field '"+a+"' has been assigned during initialization."),new Error())},
N(){throw B.as(B.qe(""),new Error())},
ne(){throw B.as(B.qd(""),new Error())},
n2(a){var s
if(typeof a=="function")throw B.f(B.bR("Attempting to rewrap a JS function.",null))
s=function(b,c){return function(d){return b(c,d,arguments.length)}}(B.r2,a)
s[$.ml()]=a
return s},
r2(a,b,c){t.w.a(a)
if(B.r(c)>=1)return a.$1(b)
return a.$0()},
r3(a,b,c,d){t.w.a(a)
B.r(d)
if(d>=2)return a.$2(b,c)
if(d===1)return a.$1(b)
return a.$0()},
rZ(a,b,c){var s,r
if(b==null)return c.a(new a())
if(b instanceof Array)switch(b.length){case 0:return c.a(new a())
case 1:return c.a(new a(b[0]))
case 2:return c.a(new a(b[0],b[1]))
case 3:return c.a(new a(b[0],b[1],b[2]))
case 4:return c.a(new a(b[0],b[1],b[2],b[3]))}s=[null]
A.b.A(s,b)
r=a.bind.apply(a,s)
String(r)
return c.a(new r())},
mA(a,b,c){var s=0,r=B.D(t.H)
var $async$mA=B.E(function(d,e){if(d===1)return B.A(e,r)
for(;;)switch(s){case 0:return B.B(null,r)}})
return B.C($async$mA,r)},
jl(a){var s=0,r=B.D(t.H)
var $async$jl=B.E(function(b,c){if(b===1)return B.A(c,r)
for(;;)switch(s){case 0:return B.B(null,r)}})
return B.C($async$jl,r)},
mE(a,b,c,d,e){var s=0,r=B.D(t.H)
var $async$mE=B.E(function(f,g){if(f===1)return B.A(g,r)
for(;;)switch(s){case 0:return B.B(null,r)}})
return B.C($async$mE,r)},
mC(a,b,c,d){var s=0,r=B.D(t.H)
var $async$mC=B.E(function(e,f){if(e===1)return B.A(f,r)
for(;;)switch(s){case 0:return B.B(null,r)}})
return B.C($async$mC,r)},
mB(a,b,c){var s=0,r=B.D(t.H)
var $async$mB=B.E(function(d,e){if(d===1)return B.A(e,r)
for(;;)switch(s){case 0:return B.B(null,r)}})
return B.C($async$mB,r)},
mD(a,b,c){var s=0,r=B.D(t.H)
var $async$mD=B.E(function(d,e){if(d===1)return B.A(e,r)
for(;;)switch(s){case 0:return B.B(null,r)}})
return B.C($async$mD,r)},
mF(a,b,c){var s=0,r=B.D(t.H)
var $async$mF=B.E(function(d,e){if(d===1)return B.A(e,r)
for(;;)switch(s){case 0:return B.B(null,r)}})
return B.C($async$mF,r)},
ff(a,b,c,d){var s=0,r=B.D(t.H)
var $async$ff=B.E(function(e,f){if(e===1)return B.A(f,r)
for(;;)switch(s){case 0:return B.B(null,r)}})
return B.C($async$ff,r)},
db(a,b,c){var s,r,q
if(typeof b!="string")return null
for(s=a.length,r=0;r<s;++r){q=a[r]
if(q.b===b)return q}return null},
cj(a){var s=typeof a=="string"?a:null,r=s==null?null:A.i.a9(s)
return r==null||r.length===0?null:r},
an(a){var s,r,q=t.N,p=t.z
if(t.f.b(a)){q=B.n(q,p)
for(p=a.gav(),p=p.gq(p);p.l();){s=p.gu()
r=s.a
if(typeof r=="string")q.j(0,r,s.b)}}else q=B.n(q,p)
return q},
cE(a){return new B.cA(B.ts(a),t.k5)},
ts(a){return function(){var s=a
var r=0,q=2,p=[],o,n,m
return function $async$cE(b,c,d){if(c===1){p.push(d)
r=q}for(;;)switch(r){case 0:if(!t.j.b(s)){r=1
break}o=J.at(s),n=t.f
case 3:if(!o.l()){r=4
break}m=o.gu()
r=n.b(m)?5:6
break
case 5:r=7
return b.b=B.an(m),1
case 7:case 6:r=3
break
case 4:case 1:return 0
case 2:return b.c=p.at(-1),3}}}},
am(a){var s=t.N
if(t.j.b(a)){s=J.bO(a,s)
s=B.a3(s,s.$ti.i("a.E"))}else s=B.a1(s)
return s}},A={}
var w=[B,J,A]
var $={}
B.mK.prototype={}
J.fi.prototype={
ag(a,b){return a===b},
gR(a){return B.el(a)},
v(a){return"Instance of '"+B.fC(a)+"'"},
ga2(a){return B.da(B.n3(this))}}
J.e7.prototype={
v(a){return String(a)},
ad(a,b){return b||a},
gR(a){return a?519018:218159},
ga2(a){return B.da(t.y)},
$ia0:1,
$ii:1}
J.e9.prototype={
ag(a,b){return null==b},
v(a){return"null"},
gR(a){return 0},
$ia0:1}
J.ag.prototype={$iad:1}
J.cr.prototype={
gR(a){return 0},
v(a){return String(a)}}
J.fA.prototype={}
J.d2.prototype={}
J.bd.prototype={
v(a){var s=a[$.oI()]
if(s==null)s=a[$.ml()]
if(s==null)return this.ew(a)
return"JavaScript function for "+J.au(s)},
$icN:1}
J.ds.prototype={
gR(a){return 0},
v(a){return String(a)}}
J.dt.prototype={
gR(a){return 0},
v(a){return String(a)}}
J.v.prototype={
n(a,b){B.q(a).c.a(b)
a.$flags&1&&B.ae(a,29)
a.push(b)},
b8(a,b){a.$flags&1&&B.ae(a,"removeAt",1)
if(b<0||b>=a.length)throw B.f(B.mS(b,null))
return a.splice(b,1)[0]},
da(a,b,c){var s
B.q(a).c.a(c)
a.$flags&1&&B.ae(a,"insert",2)
s=a.length
if(b>s)throw B.f(B.mS(b,null))
a.splice(b,0,c)},
X(a,b){var s
a.$flags&1&&B.ae(a,"remove",1)
for(s=0;s<a.length;++s)if(J.F(a[s],b)){a.splice(s,1)
return!0}return!1},
a1(a,b){B.q(a).i("i(1)").a(b)
a.$flags&1&&B.ae(a,16)
this.f1(a,b,!0)},
f1(a,b,c){var s,r,q,p,o
B.q(a).i("i(1)").a(b)
s=[]
r=a.length
for(q=0;q<r;++q){p=a[q]
if(!b.$1(p))s.push(p)
if(a.length!==r)throw B.f(B.af(a))}o=s.length
if(o===r)return
this.sm(a,o)
for(q=0;q<s.length;++q)a[q]=s[q]},
cu(a,b){var s=B.q(a)
return new B.j(a,s.i("i(1)").a(b),s.i("j<1>"))},
A(a,b){var s
B.q(a).i("a<1>").a(b)
a.$flags&1&&B.ae(a,"addAll",2)
if(Array.isArray(b)){this.eG(a,b)
return}for(s=J.at(b);s.l();)a.push(s.gu())},
eG(a,b){var s,r
t.dG.a(b)
s=b.length
if(s===0)return
if(a===b)throw B.f(B.af(a))
for(r=0;r<s;++r)a.push(b[r])},
aB(a){a.$flags&1&&B.ae(a,"clear","clear")
a.length=0},
b6(a,b,c){var s=B.q(a)
return new B.K(a,s.E(c).i("1(2)").a(b),s.i("@<1>").E(c).i("K<1,2>"))},
aW(a,b){var s,r=B.mN(a.length,"",!1,t.N)
for(s=0;s<a.length;++s)this.j(r,s,B.z(a[s]))
return r.join(b)},
ah(a,b){return B.fI(a,b,null,B.q(a).c)},
ej(a,b){var s,r,q
B.q(a).i("1(1,1)").a(b)
s=a.length
if(s===0)throw B.f(B.bI())
if(0>=s)return B.b(a,0)
r=a[0]
for(q=1;q<s;++q){r=b.$2(r,a[q])
if(s!==a.length)throw B.f(B.af(a))}return r},
aI(a,b,c,d){var s,r,q
d.a(b)
B.q(a).E(d).i("1(1,2)").a(c)
s=a.length
for(r=b,q=0;q<s;++q){r=c.$2(r,a[q])
if(a.length!==s)throw B.f(B.af(a))}return r},
a7(a,b,c){var s,r,q,p=B.q(a)
p.i("i(1)").a(b)
p.i("1()?").a(c)
s=a.length
for(r=0;r<s;++r){q=a[r]
if(b.$1(q))return q
if(a.length!==s)throw B.f(B.af(a))}if(c!=null)return c.$0()
throw B.f(B.bI())},
fz(a,b){return this.a7(a,b,null)},
V(a,b){if(!(b>=0&&b<a.length))return B.b(a,b)
return a[b]},
gM(a){if(a.length>0)return a[0]
throw B.f(B.bI())},
gfO(a){var s=a.length
if(s>0)return a[s-1]
throw B.f(B.bI())},
aa(a,b,c,d,e){var s,r,q,p
B.q(a).i("a<1>").a(d)
a.$flags&2&&B.ae(a,5)
B.l5(b,c,a.length)
s=c-b
if(s===0)return
B.aO(e,"skipCount")
r=B.e(d)
r=B.hn(J.dR(d.a,e),r.c,r.y[1])
r=B.k(r,B.e(r).i("a.E"))
r.$flags=1
q=r
if(s>q.length)throw B.f(B.nH())
if(0<b)for(p=s-1;p>=0;--p){if(!(p>=0&&p<q.length))return B.b(q,p)
a[b+p]=q[p]}else for(p=0;p<s;++p){if(!(p>=0&&p<q.length))return B.b(q,p)
a[b+p]=q[p]}},
N(a,b){var s,r
B.q(a).i("i(1)").a(b)
s=a.length
for(r=0;r<s;++r){if(b.$1(a[r]))return!0
if(a.length!==s)throw B.f(B.af(a))}return!1},
aO(a,b){var s,r
B.q(a).i("i(1)").a(b)
s=a.length
for(r=0;r<s;++r){if(!b.$1(a[r]))return!1
if(a.length!==s)throw B.f(B.af(a))}return!0},
b_(a,b){var s,r,q,p,o,n=B.q(a)
n.i("c(1,1)?").a(b)
a.$flags&2&&B.ae(a,"sort")
s=a.length
if(s<2)return
if(b==null)b=J.rj()
if(s===2){r=a[0]
q=a[1]
n=b.$2(r,q)
if(typeof n!=="number")return n.hb()
if(n>0){a[0]=q
a[1]=r}return}p=0
if(n.c.b(null))for(o=0;o<a.length;++o)if(a[o]===void 0){a[o]=null;++p}a.sort(B.h7(b,2))
if(p>0)this.f2(a,p)},
cw(a){return this.b_(a,null)},
f2(a,b){var s,r=a.length
for(;s=r-1,r>0;r=s)if(a[s]===null){a[s]=void 0;--b
if(b===0)break}},
fE(a,b){var s,r=a.length
if(0>=r)return-1
for(s=0;s<r;++s){if(!(s<a.length))return B.b(a,s)
if(J.F(a[s],b))return s}return-1},
p(a,b){var s
for(s=0;s<a.length;++s)if(J.F(a[s],b))return!0
return!1},
gO(a){return a.length===0},
ga8(a){return a.length!==0},
v(a){return B.mH(a,"[","]")},
aK(a){return B.dw(a,B.q(a).c)},
gq(a){return new J.cJ(a,a.length,B.q(a).i("cJ<1>"))},
gR(a){return B.el(a)},
gm(a){return a.length},
sm(a,b){a.$flags&1&&B.ae(a,"set length","change the length of")
if(b<0)throw B.f(B.aN(b,0,null,"newLength",null))
if(b>a.length)B.q(a).c.a(null)
a.length=b},
h(a,b){B.r(b)
if(!(b>=0&&b<a.length))throw B.f(B.h8(a,b))
return a[b]},
j(a,b,c){B.r(b)
B.q(a).c.a(c)
a.$flags&2&&B.ae(a)
if(!(b>=0&&b<a.length))throw B.f(B.h8(a,b))
a[b]=c},
dj(a,b){return new B.b_(a,b.i("b_<0>"))},
d9(a,b){var s
B.q(a).i("i(1)").a(b)
if(0>=a.length)return-1
for(s=0;s<a.length;++s)if(b.$1(a[s]))return s
return-1},
$iw:1,
$ia:1,
$iG:1}
J.fj.prototype={
h3(a){var s,r,q
if(!Array.isArray(a))return null
s=a.$flags|0
if((s&4)!==0)r="const, "
else if((s&2)!==0)r="unmodifiable, "
else r=(s&1)!==0?"fixed, ":""
q="Instance of '"+B.fC(a)+"'"
if(r==="")return q
return q+" ("+r+"length: "+a.length+")"}}
J.kO.prototype={}
J.cJ.prototype={
gu(){var s=this.d
return s==null?this.$ti.c.a(s):s},
l(){var s,r=this,q=r.a,p=q.length
if(r.b!==p){q=B.Z(q)
throw B.f(q)}s=r.c
if(s>=p){r.d=null
return!1}r.d=q[s]
r.c=s+1
return!0},
$iX:1}
J.cR.prototype={
Z(a,b){var s
B.h4(b)
if(a<b)return-1
else if(a>b)return 1
else if(a===b){if(a===0){s=this.gde(b)
if(this.gde(a)===s)return 0
if(this.gde(a))return-1
return 1}return 0}else if(isNaN(a)){if(isNaN(b))return 0
return 1}else return-1},
gde(a){return a===0?1/a<0:a<0},
k(a){var s
if(a>=-2147483648&&a<=2147483647)return a|0
if(isFinite(a)){s=a<0?Math.ceil(a):Math.floor(a)
return s+0}throw B.f(B.ax(""+a+".toInt()"))},
fh(a){var s,r
if(a>=0){if(a<=2147483647){s=a|0
return a===s?s:s+1}}else if(a>=-2147483648)return a|0
r=Math.ceil(a)
if(isFinite(r))return r
throw B.f(B.ax(""+a+".ceil()"))},
fA(a){var s,r
if(a>=0){if(a<=2147483647)return a|0}else if(a>=-2147483648){s=a|0
return a===s?s:s-1}r=Math.floor(a)
if(isFinite(r))return r
throw B.f(B.ax(""+a+".floor()"))},
cq(a){if(a>0){if(a!==1/0)return Math.round(a)}else if(a>-1/0)return 0-Math.round(0-a)
throw B.f(B.ax(""+a+".round()"))},
fX(a){if(a<0)return-Math.round(-a)
else return Math.round(a)},
t(a,b,c){if(this.Z(b,c)>0)throw B.f(B.rV(b))
if(this.Z(a,b)<0)return b
if(this.Z(a,c)>0)return c
return a},
h0(a,b){var s,r,q,p,o
if(b<2||b>36)throw B.f(B.aN(b,2,36,"radix",null))
s=a.toString(b)
r=s.length
q=r-1
if(!(q>=0))return B.b(s,q)
if(s.charCodeAt(q)!==41)return s
p=/^([\da-z]+)(?:\.([\da-z]+))?\(e\+(\d+)\)$/.exec(s)
if(p==null)B.aX(B.ax("Unexpected toString result: "+s))
r=p.length
if(1>=r)return B.b(p,1)
s=p[1]
if(3>=r)return B.b(p,3)
o=+p[3]
r=p[2]
if(r!=null){s+=r
o-=r.length}return s+A.i.dk("0",o)},
v(a){if(a===0&&1/a<0)return"-0.0"
else return""+a},
gR(a){var s,r,q,p,o=a|0
if(a===o)return o&536870911
s=Math.abs(a)
r=Math.log(s)/0.6931471805599453|0
q=Math.pow(2,r)
p=s<1?s/q:q/s
return((p*9007199254740992|0)+(p*3542243181176521|0))*599197+r*1259&536870911},
D(a,b){var s=a%b
if(s===0)return 0
if(s>0)return s
return s+b},
dr(a,b){if((a|0)===a)if(b>=1||b<-1)return a/b|0
return this.dT(a,b)},
G(a,b){return(a|0)===a?a/b|0:this.dT(a,b)},
dT(a,b){var s=a/b
if(s>=-2147483648&&s<=2147483647)return s|0
if(s>0){if(s!==1/0)return Math.floor(s)}else if(s>-1/0)return Math.ceil(s)
throw B.f(B.ax("Result of truncating division is "+B.z(s)+": "+B.z(a)+" ~/ "+b))},
cW(a,b){var s
if(a>0)s=this.f8(a,b)
else{s=b>31?31:b
s=a>>s>>>0}return s},
f8(a,b){return b>31?0:a>>>b},
ga2(a){return B.da(t.cZ)},
$iba:1,
$iR:1,
$iaW:1}
J.e8.prototype={
ga2(a){return B.da(t.S)},
$ia0:1,
$ic:1}
J.fk.prototype={
ga2(a){return B.da(t.i)},
$ia0:1}
J.cS.prototype={
cz(a,b){var s=b.length
if(s>a.length)return!1
return b===a.substring(0,s)},
an(a,b,c){return a.substring(b,B.l5(b,c,a.length))},
eu(a,b){return this.an(a,b,null)},
a9(a){var s,r,q,p=a.trim(),o=p.length
if(o===0)return p
if(0>=o)return B.b(p,0)
if(p.charCodeAt(0)===133){s=J.qa(p,1)
if(s===o)return""}else s=0
r=o-1
if(!(r>=0))return B.b(p,r)
q=p.charCodeAt(r)===133?J.qb(p,r):o
if(s===0&&q===o)return p
return p.substring(s,q)},
dk(a,b){var s,r
if(0>=b)return""
if(b===1||a.length===0)return a
if(b!==b>>>0)throw B.f(A.e0)
for(s=a,r="";;){if((b&1)===1)r=s+r
b=b>>>1
if(b===0)break
s+=s}return r},
b7(a,b,c){var s=b-a.length
if(s<=0)return a
return this.dk(c,s)+a},
p(a,b){return B.tv(a,b,0)},
Z(a,b){var s
B.M(b)
if(a===b)s=0
else s=a<b?-1:1
return s},
v(a){return a},
gR(a){var s,r,q
for(s=a.length,r=0,q=0;q<s;++q){r=r+a.charCodeAt(q)&536870911
r=r+((r&524287)<<10)&536870911
r^=r>>6}r=r+((r&67108863)<<3)&536870911
r^=r>>11
return r+((r&16383)<<15)&536870911},
ga2(a){return B.da(t.N)},
gm(a){return a.length},
h(a,b){B.r(b)
if(!(b.ha(0,0)&&b.hc(0,a.length)))throw B.f(B.h8(a,b))
return a[b]},
$ia0:1,
$iba:1,
$ifz:1,
$id:1}
B.cz.prototype={
gq(a){return new B.dT(J.at(this.gar()),B.e(this).i("dT<1,2>"))},
gm(a){return J.bB(this.gar())},
gO(a){return J.mn(this.gar())},
ga8(a){return J.nj(this.gar())},
ah(a,b){var s=B.e(this)
return B.hn(J.dR(this.gar(),b),s.c,s.y[1])},
V(a,b){return B.e(this).y[1].a(J.eS(this.gar(),b))},
gM(a){return B.e(this).y[1].a(J.hc(this.gar()))},
p(a,b){return J.eR(this.gar(),b)},
v(a){return J.au(this.gar())}}
B.dT.prototype={
l(){return this.a.l()},
gu(){return this.$ti.y[1].a(this.a.gu())},
$iX:1}
B.cK.prototype={
gar(){return this.a}}
B.ew.prototype={$iw:1}
B.ev.prototype={
h(a,b){return this.$ti.y[1].a(J.a2(this.a,B.r(b)))},
j(a,b,c){var s=this.$ti
J.cG(this.a,B.r(b),s.c.a(s.y[1].a(c)))},
sm(a,b){J.pf(this.a,b)},
n(a,b){var s=this.$ti
J.bN(this.a,s.c.a(s.y[1].a(b)))},
X(a,b){return J.hd(this.a,b)},
a1(a,b){J.pe(this.a,new B.ln(this,this.$ti.i("i(2)").a(b)))},
aa(a,b,c,d,e){var s=this.$ti
J.pg(this.a,b,c,B.hn(s.i("a<2>").a(d),s.y[1],s.c),e)},
b9(a,b,c,d){return this.aa(0,b,c,d,0)},
$iw:1,
$iG:1}
B.ln.prototype={
$1(a){var s=this.a.$ti
return this.b.$1(s.y[1].a(s.c.a(a)))},
$S(){return this.a.$ti.i("i(1)")}}
B.aB.prototype={
gar(){return this.a}}
B.du.prototype={
v(a){return"LateInitializationError: "+this.a}}
B.dV.prototype={
gm(a){return this.a.length},
h(a,b){var s
B.r(b)
s=this.a
if(!(b>=0&&b<s.length))return B.b(s,b)
return s.charCodeAt(b)}}
B.l7.prototype={}
B.w.prototype={}
B.a4.prototype={
gq(a){var s=this
return new B.c_(s,s.gm(s),B.e(s).i("c_<a4.E>"))},
gO(a){return this.gm(this)===0},
gM(a){if(this.gm(this)===0)throw B.f(B.bI())
return this.V(0,0)},
p(a,b){var s,r=this,q=r.gm(r)
for(s=0;s<q;++s){if(J.F(r.V(0,s),b))return!0
if(q!==r.gm(r))throw B.f(B.af(r))}return!1},
N(a,b){var s,r,q=this
B.e(q).i("i(a4.E)").a(b)
s=q.gm(q)
for(r=0;r<s;++r){if(b.$1(q.V(0,r)))return!0
if(s!==q.gm(q))throw B.f(B.af(q))}return!1},
fL(a){var s,r,q=this,p=q.gm(q)
for(s=0,r="";s<p;++s){r+=B.z(q.V(0,s))
if(p!==q.gm(q))throw B.f(B.af(q))}return r.charCodeAt(0)==0?r:r},
b6(a,b,c){var s=B.e(this)
return new B.K(this,s.E(c).i("1(a4.E)").a(b),s.i("@<a4.E>").E(c).i("K<1,2>"))},
ah(a,b){return B.fI(this,b,null,B.e(this).i("a4.E"))},
bp(a,b){var s=B.e(this).i("a4.E")
if(b)s=B.k(this,s)
else{s=B.k(this,s)
s.$flags=1
s=s}return s},
bJ(a){return this.bp(0,!0)},
aK(a){var s,r=this,q=B.kS(B.e(r).i("a4.E"))
for(s=0;s<r.gm(r);++s)q.n(0,r.V(0,s))
return q}}
B.d_.prototype={
ez(a,b,c,d){var s,r=this.b
B.aO(r,"start")
s=this.c
if(s!=null){B.aO(s,"end")
if(r>s)throw B.f(B.aN(r,0,s,"start",null))}},
geQ(){var s=J.bB(this.a),r=this.c
if(r==null||r>s)return s
return r},
gf9(){var s=J.bB(this.a),r=this.b
if(r>s)return s
return r},
gm(a){var s,r=J.bB(this.a),q=this.b
if(q>=r)return 0
s=this.c
if(s==null||s>=r)return r-q
return s-q},
V(a,b){var s=this,r=s.gf9()+b
if(b<0||r>=s.geQ())throw B.f(B.kM(b,s.gm(0),s,"index"))
return J.eS(s.a,r)},
ah(a,b){var s,r,q=this
B.aO(b,"count")
s=q.b+b
r=q.c
if(r!=null&&s>=r)return new B.e0(q.$ti.i("e0<1>"))
return B.fI(q.a,s,r,q.$ti.c)},
bp(a,b){var s,r,q,p=this,o=p.b,n=p.a,m=J.bi(n),l=m.gm(n),k=p.c
if(k!=null&&k<l)l=k
s=l-o
if(s<=0){n=p.$ti.c
return b?J.mJ(0,n):J.nJ(0,n)}r=B.mN(s,m.V(n,o),b,p.$ti.c)
for(q=1;q<s;++q){A.b.j(r,q,m.V(n,o+q))
if(m.gm(n)<l)throw B.f(B.af(p))}return r},
bJ(a){return this.bp(0,!0)}}
B.c_.prototype={
gu(){var s=this.d
return s==null?this.$ti.c.a(s):s},
l(){var s,r=this,q=r.a,p=J.bi(q),o=p.gm(q)
if(r.b!==o)throw B.f(B.af(q))
s=r.c
if(s>=o){r.d=null
return!1}r.d=p.V(q,s);++r.c
return!0},
$iX:1}
B.c0.prototype={
gq(a){return new B.c1(J.at(this.a),this.b,B.e(this).i("c1<1,2>"))},
gm(a){return J.bB(this.a)},
gO(a){return J.mn(this.a)},
gM(a){return this.b.$1(J.hc(this.a))},
V(a,b){return this.b.$1(J.eS(this.a,b))}}
B.bc.prototype={$iw:1}
B.c1.prototype={
l(){var s=this,r=s.b
if(r.l()){s.a=s.c.$1(r.gu())
return!0}s.a=null
return!1},
gu(){var s=this.a
return s==null?this.$ti.y[1].a(s):s},
$iX:1}
B.K.prototype={
gm(a){return J.bB(this.a)},
V(a,b){return this.b.$1(J.eS(this.a,b))}}
B.j.prototype={
gq(a){return new B.bx(J.at(this.a),this.b,this.$ti.i("bx<1>"))}}
B.bx.prototype={
l(){var s,r
for(s=this.a,r=this.b;s.l();)if(r.$1(s.gu()))return!0
return!1},
gu(){return this.a.gu()},
$iX:1}
B.d0.prototype={
gq(a){var s=this.a
return new B.eq(s.gq(s),this.b,B.e(this).i("eq<1>"))}}
B.e_.prototype={
gm(a){var s=this.a,r=s.gm(s)
s=this.b
if(r>s)return s
return r},
$iw:1}
B.eq.prototype={
l(){if(--this.b>=0)return this.a.l()
this.b=-1
return!1},
gu(){if(this.b<0){this.$ti.c.a(null)
return null}return this.a.gu()},
$iX:1}
B.c7.prototype={
ah(a,b){B.df(b,"count",t.S)
B.aO(b,"count")
return new B.c7(this.a,this.b+b,B.e(this).i("c7<1>"))},
gq(a){var s=this.a
return new B.eo(s.gq(s),this.b,B.e(this).i("eo<1>"))}}
B.dm.prototype={
gm(a){var s=this.a,r=s.gm(s)-this.b
if(r>=0)return r
return 0},
ah(a,b){B.df(b,"count",t.S)
B.aO(b,"count")
return new B.dm(this.a,this.b+b,this.$ti)},
$iw:1}
B.eo.prototype={
l(){var s,r
for(s=this.a,r=0;r<this.b;++r)s.l()
this.b=0
return s.l()},
gu(){return this.a.gu()},
$iX:1}
B.e0.prototype={
gq(a){return A.dT},
gO(a){return!0},
gm(a){return 0},
gM(a){throw B.f(B.bI())},
V(a,b){throw B.f(B.aN(b,0,0,"index",null))},
p(a,b){return!1},
ah(a,b){B.aO(b,"count")
return this}}
B.e1.prototype={
l(){return!1},
gu(){throw B.f(B.bI())},
$iX:1}
B.b_.prototype={
gq(a){return new B.et(J.at(this.a),this.$ti.i("et<1>"))}}
B.et.prototype={
l(){var s,r
for(s=this.a,r=this.$ti.c;s.l();)if(r.b(s.gu()))return!0
return!1},
gu(){return this.$ti.c.a(this.a.gu())},
$iX:1}
B.cQ.prototype={
gm(a){return J.bB(this.a)},
gO(a){return J.mn(this.a)},
ga8(a){return J.nj(this.a)},
gM(a){return new B.p(this.b,J.hc(this.a))},
V(a,b){return new B.p(b+this.b,J.eS(this.a,b))},
p(a,b){var s,r,q=null,p=null,o=!1,n=b.a
if(B.cC(n)){B.r(n)
s=b.b
o=n>=this.b
p=s
q=n}if(o){if(typeof q!=="number")return q.es()
o=J.dR(this.a,q-this.b)
r=o.gq(o)
return r.l()&&J.F(r.gu(),p)}return!1},
ah(a,b){B.df(b,"count",t.S)
B.aO(b,"count")
return new B.cQ(J.dR(this.a,b),b+this.b,B.e(this).i("cQ<1>"))},
gq(a){return new B.e5(J.at(this.a),this.b,B.e(this).i("e5<1>"))}}
B.dl.prototype={
p(a,b){var s,r,q,p=null,o=null,n=!1,m=b.a
if(B.cC(m)){B.r(m)
s=b.b
n=m>=this.b
o=s
p=m}if(n){if(typeof p!=="number")return p.es()
r=p-this.b
n=this.a
q=J.bi(n)
return r<q.gm(n)&&J.F(q.V(n,r),o)}return!1},
ah(a,b){B.df(b,"count",t.S)
B.aO(b,"count")
return new B.dl(J.dR(this.a,b),this.b+b,this.$ti)},
$iw:1}
B.e5.prototype={
l(){if(++this.c>=0&&this.a.l())return!0
this.c=-2
return!1},
gu(){var s=this.c
return s>=0?new B.p(this.b+s,this.a.gu()):B.aX(B.bI())},
$iX:1}
B.aa.prototype={
sm(a,b){throw B.f(B.ax("Cannot change the length of a fixed-length list"))},
n(a,b){B.aF(a).i("aa.E").a(b)
throw B.f(B.ax("Cannot add to a fixed-length list"))},
X(a,b){throw B.f(B.ax("Cannot remove from a fixed-length list"))},
a1(a,b){B.aF(a).i("i(aa.E)").a(b)
throw B.f(B.ax("Cannot remove from a fixed-length list"))}}
B.bM.prototype={
j(a,b,c){B.r(b)
B.e(this).i("bM.E").a(c)
throw B.f(B.ax("Cannot modify an unmodifiable list"))},
sm(a,b){throw B.f(B.ax("Cannot change the length of an unmodifiable list"))},
n(a,b){B.e(this).i("bM.E").a(b)
throw B.f(B.ax("Cannot add to an unmodifiable list"))},
X(a,b){throw B.f(B.ax("Cannot remove from an unmodifiable list"))},
a1(a,b){B.e(this).i("i(bM.E)").a(b)
throw B.f(B.ax("Cannot remove from an unmodifiable list"))},
aa(a,b,c,d,e){B.e(this).i("a<bM.E>").a(d)
throw B.f(B.ax("Cannot modify an unmodifiable list"))},
b9(a,b,c,d){return this.aa(0,b,c,d,0)}}
B.dC.prototype={}
B.la.prototype={}
B.eN.prototype={}
B.p.prototype={$r:"+(1,2)",$s:1}
B.J.prototype={$r:"+x,y(1,2)",$s:2}
B.eE.prototype={$r:"+(1,2,3)",$s:3}
B.dW.prototype={}
B.di.prototype={
gO(a){return this.gm(this)===0},
v(a){return B.kU(this)},
j(a,b,c){var s=B.e(this)
s.c.a(b)
s.y[1].a(c)
B.pu()},
gav(){return new B.cA(this.fw(),B.e(this).i("cA<P<1,2>>"))},
fw(){var s=this
return function(){var r=0,q=1,p=[],o,n,m,l,k
return function $async$gav(a,b,c){if(b===1){p.push(c)
r=q}for(;;)switch(r){case 0:o=s.gY(),o=o.gq(o),n=B.e(s),m=n.y[1],n=n.i("P<1,2>")
case 2:if(!o.l()){r=3
break}l=o.gu()
k=s.h(0,l)
r=4
return a.b=new B.P(l,k==null?m.a(k):k,n),1
case 4:r=2
break
case 3:return 0
case 1:return a.c=p.at(-1),3}}}},
aX(a,b,c,d){var s=B.n(c,d)
this.af(0,new B.ho(this,B.e(this).E(c).E(d).i("P<1,2>(3,4)").a(b),s))
return s},
$it:1}
B.ho.prototype={
$2(a,b){var s=B.e(this.a),r=this.b.$2(s.c.a(a),s.y[1].a(b))
this.c.j(0,r.a,r.b)},
$S(){return B.e(this.a).i("~(1,2)")}}
B.u.prototype={
gm(a){return this.b.length},
gdJ(){var s=this.$keys
if(s==null){s=Object.keys(this.a)
this.$keys=s}return s},
J(a){if(typeof a!="string")return!1
if("__proto__"===a)return!1
return this.a.hasOwnProperty(a)},
h(a,b){if(!this.J(b))return null
return this.b[this.a[b]]},
af(a,b){var s,r,q,p
this.$ti.i("~(1,2)").a(b)
s=this.gdJ()
r=this.b
for(q=s.length,p=0;p<q;++p)b.$2(s[p],r[p])},
gY(){return new B.d4(this.gdJ(),this.$ti.i("d4<1>"))},
gaZ(){return new B.d4(this.b,this.$ti.i("d4<2>"))}}
B.d4.prototype={
gm(a){return this.a.length},
gO(a){return 0===this.a.length},
ga8(a){return 0!==this.a.length},
gq(a){var s=this.a
return new B.d5(s,s.length,this.$ti.i("d5<1>"))}}
B.d5.prototype={
gu(){var s=this.d
return s==null?this.$ti.c.a(s):s},
l(){var s=this,r=s.c
if(r>=s.b){s.d=null
return!1}s.d=s.a[r]
s.c=r+1
return!0},
$iX:1}
B.b7.prototype={
bb(){var s=this,r=s.$map
if(r==null){r=new B.ea(s.$ti.i("ea<1,2>"))
B.oy(s.a,r)
s.$map=r}return r},
J(a){return this.bb().J(a)},
h(a,b){return this.bb().h(0,b)},
af(a,b){this.$ti.i("~(1,2)").a(b)
this.bb().af(0,b)},
gY(){var s=this.bb()
return new B.aJ(s,B.e(s).i("aJ<1>"))},
gaZ(){var s=this.bb()
return new B.ai(s,B.e(s).i("ai<2>"))},
gm(a){return this.bb().a}}
B.dY.prototype={
n(a,b){B.e(this).c.a(b)
B.mq()},
X(a,b){B.mq()},
el(a){B.mq()}}
B.T.prototype={
gm(a){return this.b},
gO(a){return this.b===0},
ga8(a){return this.b!==0},
gq(a){var s,r=this,q=r.$keys
if(q==null){q=Object.keys(r.a)
r.$keys=q}s=q
return new B.d5(s,s.length,r.$ti.i("d5<1>"))},
p(a,b){if(typeof b!="string")return!1
if("__proto__"===b)return!1
return this.a.hasOwnProperty(b)},
aK(a){return B.a3(this,this.$ti.c)}}
B.em.prototype={}
B.le.prototype={
aA(a){var s,r,q=this,p=new RegExp(q.a).exec(a)
if(p==null)return null
s=Object.create(null)
r=q.b
if(r!==-1)s.arguments=p[r+1]
r=q.c
if(r!==-1)s.argumentsExpr=p[r+1]
r=q.d
if(r!==-1)s.expr=p[r+1]
r=q.e
if(r!==-1)s.method=p[r+1]
r=q.f
if(r!==-1)s.receiver=p[r+1]
return s}}
B.ek.prototype={
v(a){return"Null check operator used on a null value"}}
B.fm.prototype={
v(a){var s,r=this,q="NoSuchMethodError: method not found: '",p=r.b
if(p==null)return"NoSuchMethodError: "+r.a
s=r.c
if(s==null)return q+p+"' ("+r.a+")"
return q+p+"' on '"+s+"' ("+r.a+")"}}
B.fL.prototype={
v(a){var s=this.a
return s.length===0?"Error":"Error: "+s}}
B.kW.prototype={
v(a){return"Throw of null ('"+(this.a===null?"null":"undefined")+"' from JavaScript)"}}
B.e2.prototype={}
B.eG.prototype={
v(a){var s,r=this.b
if(r!=null)return r
r=this.a
s=r!==null&&typeof r==="object"?r.stack:null
return this.b=s==null?"":s},
$ibL:1}
B.cl.prototype={
v(a){var s=this.constructor,r=s==null?null:s.name
return"Closure '"+B.oH(r==null?"unknown":r)+"'"},
$icN:1,
gh9(){return this},
$C:"$1",
$R:1,
$D:null}
B.eX.prototype={$C:"$0",$R:0}
B.eY.prototype={$C:"$2",$R:2}
B.fJ.prototype={}
B.fH.prototype={
v(a){var s=this.$static_name
if(s==null)return"Closure of unknown static method"
return"Closure '"+B.oH(s)+"'"}}
B.dg.prototype={
ag(a,b){if(b==null)return!1
if(this===b)return!0
if(!(b instanceof B.dg))return!1
return this.$_target===b.$_target&&this.a===b.a},
gR(a){return(B.nd(this.a)^B.el(this.$_target))>>>0},
v(a){return"Closure '"+this.$_name+"' of "+("Instance of '"+B.fC(this.a)+"'")}}
B.fG.prototype={
v(a){return"RuntimeError: "+this.a}}
B.bl.prototype={
gm(a){return this.a},
gO(a){return this.a===0},
ga8(a){return this.a!==0},
gY(){return new B.aJ(this,B.e(this).i("aJ<1>"))},
gaZ(){return new B.ai(this,B.e(this).i("ai<2>"))},
gav(){return new B.y(this,B.e(this).i("y<1,2>"))},
J(a){var s,r
if(typeof a=="string"){s=this.b
if(s==null)return!1
return s[a]!=null}else if(typeof a=="number"&&(a&0x3fffffff)===a){r=this.c
if(r==null)return!1
return r[a]!=null}else return this.fF(a)},
fF(a){var s=this.d
if(s==null)return!1
return this.bG(s[this.bF(a)],a)>=0},
A(a,b){B.e(this).i("t<1,2>").a(b).af(0,new B.kP(this))},
h(a,b){var s,r,q,p,o=null
if(typeof b=="string"){s=this.b
if(s==null)return o
r=s[b]
q=r==null?o:r.b
return q}else if(typeof b=="number"&&(b&0x3fffffff)===b){p=this.c
if(p==null)return o
r=p[b]
q=r==null?o:r.b
return q}else return this.fG(b)},
fG(a){var s,r,q=this.d
if(q==null)return null
s=q[this.bF(a)]
r=this.bG(s,a)
if(r<0)return null
return s[r].b},
j(a,b,c){var s,r,q=this,p=B.e(q)
p.c.a(b)
p.y[1].a(c)
if(typeof b=="string"){s=q.b
q.dv(s==null?q.b=q.cP():s,b,c)}else if(typeof b=="number"&&(b&0x3fffffff)===b){r=q.c
q.dv(r==null?q.c=q.cP():r,b,c)}else q.fI(b,c)},
fI(a,b){var s,r,q,p,o=this,n=B.e(o)
n.c.a(a)
n.y[1].a(b)
s=o.d
if(s==null)s=o.d=o.cP()
r=o.bF(a)
q=s[r]
if(q==null)s[r]=[o.cQ(a,b)]
else{p=o.bG(q,a)
if(p>=0)q[p].b=b
else q.push(o.cQ(a,b))}},
ei(a,b){var s,r,q=this,p=B.e(q)
p.c.a(a)
p.i("2()").a(b)
if(q.J(a)){s=q.h(0,a)
return s==null?p.y[1].a(s):s}r=b.$0()
q.j(0,a,r)
return r},
X(a,b){var s=this
if(typeof b=="string")return s.ds(s.b,b)
else if(typeof b=="number"&&(b&0x3fffffff)===b)return s.ds(s.c,b)
else return s.fH(b)},
fH(a){var s,r,q,p,o=this,n=o.d
if(n==null)return null
s=o.bF(a)
r=n[s]
q=o.bG(r,a)
if(q<0)return null
p=r.splice(q,1)[0]
o.dt(p)
if(r.length===0)delete n[s]
return p.b},
aB(a){var s=this
if(s.a>0){s.b=s.c=s.d=s.e=s.f=null
s.a=0
s.cO()}},
af(a,b){var s,r,q=this
B.e(q).i("~(1,2)").a(b)
s=q.e
r=q.r
while(s!=null){b.$2(s.a,s.b)
if(r!==q.r)throw B.f(B.af(q))
s=s.c}},
dv(a,b,c){var s,r=B.e(this)
r.c.a(b)
r.y[1].a(c)
s=a[b]
if(s==null)a[b]=this.cQ(b,c)
else s.b=c},
ds(a,b){var s
if(a==null)return null
s=a[b]
if(s==null)return null
this.dt(s)
delete a[b]
return s.b},
cO(){this.r=this.r+1&1073741823},
cQ(a,b){var s=this,r=B.e(s),q=new B.kQ(r.c.a(a),r.y[1].a(b))
if(s.e==null)s.e=s.f=q
else{r=s.f
r.toString
q.d=r
s.f=r.c=q}++s.a
s.cO()
return q},
dt(a){var s=this,r=a.d,q=a.c
if(r==null)s.e=q
else r.c=q
if(q==null)s.f=r
else q.d=r;--s.a
s.cO()},
bF(a){return J.bA(a)&1073741823},
bG(a,b){var s,r
if(a==null)return-1
s=a.length
for(r=0;r<s;++r)if(J.F(a[r].a,b))return r
return-1},
v(a){return B.kU(this)},
cP(){var s=Object.create(null)
s["<non-identifier-key>"]=s
delete s["<non-identifier-key>"]
return s},
$imM:1}
B.kP.prototype={
$2(a,b){var s=this.a,r=B.e(s)
s.j(0,r.c.a(a),r.y[1].a(b))},
$S(){return B.e(this.a).i("~(1,2)")}}
B.kQ.prototype={}
B.aJ.prototype={
gm(a){return this.a.a},
gO(a){return this.a.a===0},
gq(a){var s=this.a
return new B.ed(s,s.r,s.e,this.$ti.i("ed<1>"))},
p(a,b){return this.a.J(b)}}
B.ed.prototype={
gu(){return this.d},
l(){var s,r=this,q=r.a
if(r.b!==q.r)throw B.f(B.af(q))
s=r.c
if(s==null){r.d=null
return!1}else{r.d=s.a
r.c=s.c
return!0}},
$iX:1}
B.ai.prototype={
gm(a){return this.a.a},
gO(a){return this.a.a===0},
gq(a){var s=this.a
return new B.ee(s,s.r,s.e,this.$ti.i("ee<1>"))}}
B.ee.prototype={
gu(){return this.d},
l(){var s,r=this,q=r.a
if(r.b!==q.r)throw B.f(B.af(q))
s=r.c
if(s==null){r.d=null
return!1}else{r.d=s.b
r.c=s.c
return!0}},
$iX:1}
B.y.prototype={
gm(a){return this.a.a},
gO(a){return this.a.a===0},
gq(a){var s=this.a
return new B.ec(s,s.r,s.e,this.$ti.i("ec<1,2>"))}}
B.ec.prototype={
gu(){var s=this.d
s.toString
return s},
l(){var s,r=this,q=r.a
if(r.b!==q.r)throw B.f(B.af(q))
s=r.c
if(s==null){r.d=null
return!1}else{r.d=new B.P(s.a,s.b,r.$ti.i("P<1,2>"))
r.c=s.c
return!0}},
$iX:1}
B.ea.prototype={
bF(a){return B.t0(a)&1073741823},
bG(a,b){var s,r
if(a==null)return-1
s=a.length
for(r=0;r<s;++r)if(J.F(a[r].a,b))return r
return-1}}
B.m3.prototype={
$1(a){return this.a(a)},
$S:26}
B.m4.prototype={
$2(a,b){return this.a(a,b)},
$S:61}
B.m5.prototype={
$1(a){return this.a(B.M(a))},
$S:28}
B.by.prototype={
v(a){return this.dV(!1)},
dV(a){var s,r,q,p,o,n=this.eR(),m=this.cN(),l=(a?"Record ":"")+"("
for(s=n.length,r="",q=0;q<s;++q,r=", "){l+=r
p=n[q]
if(typeof p=="string")l=l+p+": "
if(!(q<m.length))return B.b(m,q)
o=m[q]
l=a?l+B.nU(o):l+B.z(o)}l+=")"
return l.charCodeAt(0)==0?l:l},
eR(){var s,r=this.$s
while($.lG.length<=r)A.b.n($.lG,null)
s=$.lG[r]
if(s==null){s=this.eN()
A.b.j($.lG,r,s)}return s},
eN(){var s,r,q,p=this.$r,o=p.indexOf("("),n=p.substring(1,o),m=p.substring(o),l=m==="()"?0:m.replace(/[^,]/g,"").length+1,k=t.K,j=J.mI(l,k)
for(s=0;s<l;++s)j[s]=s
if(n!==""){r=n.split(",")
s=r.length
for(q=l;s>0;){--q;--s
A.b.j(j,q,r[s])}}return B.aR(j,k)}}
B.d7.prototype={
cN(){return[this.a,this.b]},
ag(a,b){if(b==null)return!1
return b instanceof B.d7&&this.$s===b.$s&&J.F(this.a,b.a)&&J.F(this.b,b.b)},
gR(a){return B.mP(this.$s,this.a,this.b,A.at)}}
B.dE.prototype={
cN(){return[this.a,this.b,this.c]},
ag(a,b){var s=this
if(b==null)return!1
return b instanceof B.dE&&s.$s===b.$s&&J.F(s.a,b.a)&&J.F(s.b,b.b)&&J.F(s.c,b.c)},
gR(a){var s=this
return B.mP(s.$s,s.a,s.b,s.c)}}
B.fl.prototype={
v(a){return"RegExp/"+this.a+"/"+this.b.flags},
a4(a){var s=this.b.exec(a)
if(s==null)return null
return new B.lF(s)},
$ifz:1,
$il6:1}
B.lF.prototype={
h(a,b){var s
B.r(b)
s=this.b
if(!(b<s.length))return B.b(s,b)
return s[b]}}
B.cW.prototype={
ga2(a){return A.RU},
cY(a,b,c){B.lR(a,b,c)
return c==null?new Uint8Array(a,b):new Uint8Array(a,b,c)},
e1(a){return this.cY(a,0,null)},
bW(a,b,c){var s
B.lR(a,b,c)
s=new DataView(a,b)
return s},
e0(a){return this.bW(a,0,null)},
$ia0:1,
$icW:1}
B.ef.prototype={
gbu(a){if(((a.$flags|0)&2)!==0)return new B.lK(a.buffer)
else return a.buffer},
eV(a,b,c,d){var s=B.aN(b,0,c,d,null)
throw B.f(s)},
dC(a,b,c,d){if(b>>>0!==b||b>c)this.eV(a,b,c,d)}}
B.lK.prototype={
cY(a,b,c){var s=B.qi(this.a,b,c)
s.$flags=3
return s},
e1(a){return this.cY(0,0,null)},
bW(a,b,c){var s=B.qh(this.a,b,c)
s.$flags=3
return s},
e0(a){return this.bW(0,0,null)}}
B.fs.prototype={
ga2(a){return A.RV},
$ia0:1,
$inq:1}
B.aK.prototype={
gm(a){return a.length},
dR(a,b,c,d,e){var s,r,q=a.length
this.dC(a,b,q,"start")
this.dC(a,c,q,"end")
if(b>c)throw B.f(B.aN(b,0,c,null,null))
s=c-b
if(e<0)throw B.f(B.bR(e,null))
r=d.length
if(r-e<s)throw B.f(B.bv("Not enough elements"))
if(e!==0||r!==s)d=d.subarray(e,e+s)
a.set(d,b)},
$ibe:1}
B.cu.prototype={
h(a,b){B.r(b)
B.ch(b,a,a.length)
return a[b]},
j(a,b,c){B.r(b)
B.of(c)
a.$flags&2&&B.ae(a)
B.ch(b,a,a.length)
a[b]=c},
aa(a,b,c,d,e){t.id.a(d)
a.$flags&2&&B.ae(a,5)
if(t.dQ.b(d)){this.dR(a,b,c,d,e)
return}this.dq(a,b,c,d,e)},
b9(a,b,c,d){return this.aa(a,b,c,d,0)},
$iw:1,
$ia:1,
$iG:1}
B.bf.prototype={
j(a,b,c){B.r(b)
B.r(c)
a.$flags&2&&B.ae(a)
B.ch(b,a,a.length)
a[b]=c},
aa(a,b,c,d,e){t.fm.a(d)
a.$flags&2&&B.ae(a,5)
if(t.aj.b(d)){this.dR(a,b,c,d,e)
return}this.dq(a,b,c,d,e)},
b9(a,b,c,d){return this.aa(a,b,c,d,0)},
$iw:1,
$ia:1,
$iG:1}
B.ft.prototype={
ga2(a){return A.RW},
$ia0:1}
B.fu.prototype={
ga2(a){return A.RX},
$ia0:1}
B.fv.prototype={
ga2(a){return A.RY},
h(a,b){B.r(b)
B.ch(b,a,a.length)
return a[b]},
$ia0:1}
B.fw.prototype={
ga2(a){return A.RZ},
h(a,b){B.r(b)
B.ch(b,a,a.length)
return a[b]},
$ia0:1}
B.fx.prototype={
ga2(a){return A.S_},
h(a,b){B.r(b)
B.ch(b,a,a.length)
return a[b]},
$ia0:1}
B.eg.prototype={
ga2(a){return A.S1},
h(a,b){B.r(b)
B.ch(b,a,a.length)
return a[b]},
$ia0:1}
B.eh.prototype={
ga2(a){return A.S2},
h(a,b){B.r(b)
B.ch(b,a,a.length)
return a[b]},
$ia0:1,
$imV:1}
B.ei.prototype={
ga2(a){return A.S3},
gm(a){return a.length},
h(a,b){B.r(b)
B.ch(b,a,a.length)
return a[b]},
$ia0:1}
B.ej.prototype={
ga2(a){return A.S4},
gm(a){return a.length},
h(a,b){B.r(b)
B.ch(b,a,a.length)
return a[b]},
$ia0:1,
$imW:1}
B.eA.prototype={}
B.eB.prototype={}
B.eC.prototype={}
B.eD.prototype={}
B.bu.prototype={
i(a){return B.eK(v.typeUniverse,this,a)},
E(a){return B.ob(v.typeUniverse,this,a)}}
B.fR.prototype={}
B.h3.prototype={
v(a){return B.b1(this.a,null)}}
B.fQ.prototype={
v(a){return this.a}}
B.dF.prototype={$icd:1}
B.lk.prototype={
$1(a){var s=this.a,r=s.a
s.a=null
r.$0()},
$S:38}
B.lj.prototype={
$1(a){var s,r
this.a.a=t.Q.a(a)
s=this.b
r=this.c
s.firstChild?s.removeChild(r):s.appendChild(r)},
$S:88}
B.ll.prototype={
$0(){this.a.$0()},
$S:2}
B.lm.prototype={
$0(){this.a.$0()},
$S:2}
B.h2.prototype={
eC(a,b){if(self.setTimeout!=null)this.b=self.setTimeout(B.h7(new B.lI(this,b),0),a)
else throw B.f(B.ax("`setTimeout()` not found."))},
$iqw:1}
B.lI.prototype={
$0(){this.a.b=null
this.b.$0()},
$S:1}
B.fN.prototype={}
B.lP.prototype={
$1(a){return this.a.$2(0,a)},
$S:62}
B.lQ.prototype={
$2(a,b){this.a.$2(1,new B.e2(a,t.l.a(b)))},
$S:66}
B.lW.prototype={
$2(a,b){this.a(B.r(a),b)},
$S:96}
B.d8.prototype={
gu(){var s=this.b
return s==null?this.$ti.c.a(s):s},
f4(a,b){var s,r,q
a=B.r(a)
b=b
s=this.a
for(;;)try{r=s(this,a,b)
return r}catch(q){b=q
a=1}},
l(){var s,r,q,p,o=this,n=null,m=0
for(;;){s=o.d
if(s!=null)try{if(s.l()){o.b=s.gu()
return!0}else o.d=null}catch(r){n=r
m=1
o.d=null}q=o.f4(m,n)
if(1===q)return!0
if(0===q){o.b=null
p=o.e
if(p==null||p.length===0){o.a=B.o6
return!1}if(0>=p.length)return B.b(p,-1)
o.a=p.pop()
m=0
n=null
continue}if(2===q){m=0
n=null
continue}if(3===q){n=o.c
o.c=null
p=o.e
if(p==null||p.length===0){o.b=null
o.a=B.o6
throw n
return!1}if(0>=p.length)return B.b(p,-1)
o.a=p.pop()
m=1
continue}throw B.f(B.bv("sync*"))}return!1},
hd(a){var s,r,q=this
if(a instanceof B.cA){s=a.a()
r=q.e
if(r==null)r=q.e=[]
A.b.n(r,q.a)
q.a=s
return 2}else{q.d=J.at(a)
return 2}},
$iX:1}
B.cA.prototype={
gq(a){return new B.d8(this.a(),this.$ti.i("d8<1>"))}}
B.bs.prototype={
v(a){return B.z(this.a)},
$ia6:1,
gbN(){return this.b}}
B.d3.prototype={
fP(a){if((this.c&15)!==6)return!0
return this.b.b.df(t.iW.a(this.d),a.a,t.y,t.K)},
fB(a){var s,r=this,q=r.e,p=null,o=t.z,n=t.K,m=a.a,l=r.b.b
if(t.ng.b(q))p=l.fZ(q,m,a.b,o,n,t.l)
else p=l.df(t.mq.a(q),m,o,n)
try{o=r.$ti.i("2/").a(p)
return o}catch(s){if(t.do.b(B.b9(s))){if((r.c&1)!==0)throw B.f(B.bR("The error handler of Future.then must return a value of the returned future's type","onError"))
throw B.f(B.bR("The error handler of Future.catchError must return a value of the future's type","onError"))}else throw s}}}
B.aC.prototype={
dh(a,b,c){var s,r,q=this.$ti
q.E(c).i("1/(2)").a(a)
s=$.ar
if(s===A.ac){if(!t.ng.b(b)&&!t.mq.b(b))throw B.f(B.mo(b,"onError",u.w))}else{c.i("@<0/>").E(q.c).i("1(2)").a(a)
b=B.rH(b,s)}r=new B.aC(s,c.i("aC<0>"))
this.cC(new B.d3(r,3,a,b,q.i("@<1>").E(c).i("d3<1,2>")))
return r},
dU(a,b,c){var s,r=this.$ti
r.E(c).i("1/(2)").a(a)
s=new B.aC($.ar,c.i("aC<0>"))
this.cC(new B.d3(s,19,a,b,r.i("@<1>").E(c).i("d3<1,2>")))
return s},
f7(a){this.a=this.a&1|16
this.c=a},
bO(a){this.a=a.a&30|this.a&1
this.c=a.c},
cC(a){var s,r=this,q=r.a
if(q<=3){a.a=t.o.a(r.c)
r.c=a}else{if((q&4)!==0){s=t.j_.a(r.c)
if((s.a&24)===0){s.cC(a)
return}r.bO(s)}B.h5(null,null,r.b,t.Q.a(new B.lp(r,a)))}},
dM(a){var s,r,q,p,o,n,m=this,l={}
l.a=a
if(a==null)return
s=m.a
if(s<=3){r=t.o.a(m.c)
m.c=a
if(r!=null){q=a.a
for(p=a;q!=null;p=q,q=o)o=q.a
p.a=r}}else{if((s&4)!==0){n=t.j_.a(m.c)
if((n.a&24)===0){n.dM(a)
return}m.bO(n)}l.a=m.bU(a)
B.h5(null,null,m.b,t.Q.a(new B.lt(l,m)))}},
bS(){var s=t.o.a(this.c)
this.c=null
return this.bU(s)},
bU(a){var s,r,q
for(s=a,r=null;s!=null;r=s,s=q){q=s.a
s.a=r}return r},
dF(a){var s,r=this
r.$ti.c.a(a)
s=r.bS()
r.a=8
r.c=a
B.dD(r,s)},
eM(a){var s,r,q=this
if((a.a&16)!==0){s=q.b===a.b
s=!(s||s)}else s=!1
if(s)return
r=q.bS()
q.bO(a)
B.dD(q,r)},
cG(a){var s=this.bS()
this.f7(a)
B.dD(this,s)},
dw(a){var s=this.$ti
s.i("1/").a(a)
if(s.i("cO<1>").b(a)){this.dB(a)
return}this.eI(a)},
eI(a){var s=this
s.$ti.c.a(a)
s.a^=2
B.h5(null,null,s.b,t.Q.a(new B.lr(s,a)))},
dB(a){B.mX(this.$ti.i("cO<1>").a(a),this,!1)
return},
dz(a){this.a^=2
B.h5(null,null,this.b,t.Q.a(new B.lq(this,a)))},
$icO:1}
B.lp.prototype={
$0(){B.dD(this.a,this.b)},
$S:1}
B.lt.prototype={
$0(){B.dD(this.b,this.a.a)},
$S:1}
B.ls.prototype={
$0(){B.mX(this.a.a,this.b,!0)},
$S:1}
B.lr.prototype={
$0(){this.a.dF(this.b)},
$S:1}
B.lq.prototype={
$0(){this.a.cG(this.b)},
$S:1}
B.lw.prototype={
$0(){var s,r,q,p,o,n,m,l,k=this,j=null
try{q=k.a.a
j=q.b.b.fY(t.mY.a(q.d),t.z)}catch(p){s=B.b9(p)
r=B.dN(p)
if(k.c&&t.n.a(k.b.a.c).a===s){q=k.a
q.c=t.n.a(k.b.a.c)}else{q=s
o=r
if(o==null)o=B.mp(q)
n=k.a
n.c=new B.bs(q,o)
q=n}q.b=!0
return}if(j instanceof B.aC&&(j.a&24)!==0){if((j.a&16)!==0){q=k.a
q.c=t.n.a(j.c)
q.b=!0}return}if(j instanceof B.aC){m=k.b.a
l=new B.aC(m.b,m.$ti)
j.dh(new B.lx(l,m),new B.ly(l),t.H)
q=k.a
q.c=l
q.b=!1}},
$S:1}
B.lx.prototype={
$1(a){this.a.eM(this.b)},
$S:38}
B.ly.prototype={
$2(a,b){B.dJ(a)
t.l.a(b)
this.a.cG(new B.bs(a,b))},
$S:48}
B.lv.prototype={
$0(){var s,r,q,p,o,n,m,l
try{q=this.a
p=q.a
o=p.$ti
n=o.c
m=n.a(this.b)
q.c=p.b.b.df(o.i("2/(1)").a(p.d),m,o.i("2/"),n)}catch(l){s=B.b9(l)
r=B.dN(l)
q=s
p=r
if(p==null)p=B.mp(q)
o=this.a
o.c=new B.bs(q,p)
o.b=!0}},
$S:1}
B.lu.prototype={
$0(){var s,r,q,p,o,n,m,l=this
try{s=t.n.a(l.a.a.c)
p=l.b
if(p.a.fP(s)&&p.a.e!=null){p.c=p.a.fB(s)
p.b=!1}}catch(o){r=B.b9(o)
q=B.dN(o)
p=t.n.a(l.a.a.c)
if(p.a===r){n=l.b
n.c=p
p=n}else{p=r
n=q
if(n==null)n=B.mp(p)
m=l.b
m.c=new B.bs(p,n)
p=m}p.b=!0}},
$S:1}
B.fO.prototype={}
B.h0.prototype={}
B.eM.prototype={$io_:1}
B.fX.prototype={
h_(a){var s,r,q
t.Q.a(a)
try{if(A.ac===$.ar){a.$0()
return}B.oq(null,null,this,a,t.H)}catch(q){s=B.b9(q)
r=B.dN(q)
B.n5(B.dJ(s),t.l.a(r))}},
fg(a){return new B.lH(this,t.Q.a(a))},
h(a,b){return null},
fY(a,b){b.i("0()").a(a)
if($.ar===A.ac)return a.$0()
return B.oq(null,null,this,a,b)},
df(a,b,c,d){c.i("@<0>").E(d).i("1(2)").a(a)
d.a(b)
if($.ar===A.ac)return a.$1(b)
return B.rJ(null,null,this,a,b,c,d)},
fZ(a,b,c,d,e,f){d.i("@<0>").E(e).E(f).i("1(2,3)").a(a)
e.a(b)
f.a(c)
if($.ar===A.ac)return a.$2(b,c)
return B.rI(null,null,this,a,b,c,d,e,f)},
ek(a,b,c,d){return b.i("@<0>").E(c).E(d).i("1(2,3)").a(a)}}
B.lH.prototype={
$0(){return this.a.h_(this.b)},
$S:1}
B.lU.prototype={
$0(){B.pQ(this.a,this.b)},
$S:1}
B.bn.prototype={
eW(){return new B.bn(B.e(this).i("bn<1>"))},
gq(a){var s=this,r=new B.cg(s,s.r,B.e(s).i("cg<1>"))
r.c=s.e
return r},
gm(a){return this.a},
gO(a){return this.a===0},
ga8(a){return this.a!==0},
p(a,b){var s,r
if(typeof b=="string"&&b!=="__proto__"){s=this.b
if(s==null)return!1
return t.nF.a(s[b])!=null}else if(typeof b=="number"&&(b&1073741823)===b){r=this.c
if(r==null)return!1
return t.nF.a(r[b])!=null}else return this.eO(b)},
eO(a){var s=this.d
if(s==null)return!1
return this.cM(s[this.cH(a)],a)>=0},
gM(a){var s=this.e
if(s==null)throw B.f(B.bv("No elements"))
return B.e(this).c.a(s.a)},
n(a,b){var s,r,q=this
B.e(q).c.a(b)
if(typeof b=="string"&&b!=="__proto__"){s=q.b
return q.dE(s==null?q.b=B.mY():s,b)}else if(typeof b=="number"&&(b&1073741823)===b){r=q.c
return q.dE(r==null?q.c=B.mY():r,b)}else return q.eD(b)},
eD(a){var s,r,q,p=this
B.e(p).c.a(a)
s=p.d
if(s==null)s=p.d=B.mY()
r=p.cH(a)
q=s[r]
if(q==null)s[r]=[p.cF(a)]
else{if(p.cM(q,a)>=0)return!1
q.push(p.cF(a))}return!0},
X(a,b){var s=this
if(typeof b=="string"&&b!=="__proto__")return s.dN(s.b,b)
else if(typeof b=="number"&&(b&1073741823)===b)return s.dN(s.c,b)
else return s.f0(b)},
f0(a){var s,r,q,p,o=this,n=o.d
if(n==null)return!1
s=o.cH(a)
r=n[s]
q=o.cM(r,a)
if(q<0)return!1
p=r.splice(q,1)[0]
if(0===r.length)delete n[s]
o.dX(p)
return!0},
eU(a,b){var s,r,q,p,o,n=this,m=B.e(n)
m.i("i(1)").a(a)
s=n.e
for(m=m.c;s!=null;s=q){r=m.a(s.a)
q=s.b
p=n.r
o=a.$1(r)
if(p!==n.r)throw B.f(B.af(n))
if(!0===o)n.X(0,r)}},
aB(a){var s=this
if(s.a>0){s.b=s.c=s.d=s.e=s.f=null
s.a=0
s.cE()}},
dE(a,b){B.e(this).c.a(b)
if(t.nF.a(a[b])!=null)return!1
a[b]=this.cF(b)
return!0},
dN(a,b){var s
if(a==null)return!1
s=t.nF.a(a[b])
if(s==null)return!1
this.dX(s)
delete a[b]
return!0},
cE(){this.r=this.r+1&1073741823},
cF(a){var s,r=this,q=new B.fU(B.e(r).c.a(a))
if(r.e==null)r.e=r.f=q
else{s=r.f
s.toString
q.c=s
r.f=s.b=q}++r.a
r.cE()
return q},
dX(a){var s=this,r=a.c,q=a.b
if(r==null)s.e=q
else r.b=q
if(q==null)s.f=r
else q.c=r;--s.a
s.cE()},
cH(a){return J.bA(a)&1073741823},
cM(a,b){var s,r
if(a==null)return-1
s=a.length
for(r=0;r<s;++r)if(J.F(a[r].a,b))return r
return-1},
$inN:1}
B.fU.prototype={}
B.cg.prototype={
gu(){var s=this.d
return s==null?this.$ti.c.a(s):s},
l(){var s=this,r=s.c,q=s.a
if(s.b!==q.r)throw B.f(B.af(q))
else if(r==null){s.d=null
return!1}else{s.d=s.$ti.i("1?").a(r.a)
s.c=r.b
return!0}},
$iX:1}
B.kR.prototype={
$2(a,b){this.a.j(0,this.b.a(a),this.c.a(b))},
$S:49}
B.H.prototype={
gq(a){return new B.c_(a,this.gm(a),B.aF(a).i("c_<H.E>"))},
V(a,b){return this.h(a,b)},
gO(a){return this.gm(a)===0},
ga8(a){return!this.gO(a)},
gM(a){if(this.gm(a)===0)throw B.f(B.bI())
return this.h(a,0)},
p(a,b){var s,r=this.gm(a)
for(s=0;s<r;++s){if(J.F(this.h(a,s),b))return!0
if(r!==this.gm(a))throw B.f(B.af(a))}return!1},
aO(a,b){var s,r
B.aF(a).i("i(H.E)").a(b)
s=this.gm(a)
for(r=0;r<s;++r){if(!b.$1(this.h(a,r)))return!1
if(s!==this.gm(a))throw B.f(B.af(a))}return!0},
N(a,b){var s,r
B.aF(a).i("i(H.E)").a(b)
s=this.gm(a)
for(r=0;r<s;++r){if(b.$1(this.h(a,r)))return!0
if(s!==this.gm(a))throw B.f(B.af(a))}return!1},
a7(a,b,c){var s,r,q,p=B.aF(a)
p.i("i(H.E)").a(b)
p.i("H.E()?").a(c)
s=this.gm(a)
for(r=0;r<s;++r){q=this.h(a,r)
if(b.$1(q))return q
if(s!==this.gm(a))throw B.f(B.af(a))}p=c.$0()
return p},
cu(a,b){var s=B.aF(a)
return new B.j(a,s.i("i(H.E)").a(b),s.i("j<H.E>"))},
dj(a,b){return new B.b_(a,b.i("b_<0>"))},
b6(a,b,c){var s=B.aF(a)
return new B.K(a,s.E(c).i("1(H.E)").a(b),s.i("@<H.E>").E(c).i("K<1,2>"))},
ah(a,b){return B.fI(a,b,null,B.aF(a).i("H.E"))},
aK(a){var s,r=B.kS(B.aF(a).i("H.E"))
for(s=0;s<this.gm(a);++s)r.n(0,this.h(a,s))
return r},
n(a,b){var s
B.aF(a).i("H.E").a(b)
s=this.gm(a)
this.sm(a,s+1)
this.j(a,s,b)},
X(a,b){var s
for(s=0;s<this.gm(a);++s)if(J.F(this.h(a,s),b)){this.eL(a,s,s+1)
return!0}return!1},
eL(a,b,c){var s,r=this,q=r.gm(a),p=c-b
for(s=c;s<q;++s)r.j(a,s-p,r.h(a,s))
r.sm(a,q-p)},
a1(a,b){this.eT(a,B.aF(a).i("i(H.E)").a(b),!1)},
eT(a,b,c){var s,r,q,p,o=this,n=B.aF(a)
n.i("i(H.E)").a(b)
s=B.m([],n.i("v<H.E>"))
r=o.gm(a)
for(q=0;q<r;++q){p=o.h(a,q)
if(J.F(b.$1(p),!1))A.b.n(s,p)
if(r!==o.gm(a))throw B.f(B.af(a))}if(s.length!==o.gm(a)){o.b9(a,0,s.length,s)
o.sm(a,s.length)}},
aa(a,b,c,d,e){var s,r,q,p,o
B.aF(a).i("a<H.E>").a(d)
B.l5(b,c,this.gm(a))
s=c-b
if(s===0)return
B.aO(e,"skipCount")
if(t.j.b(d)){r=e
q=d}else{q=J.dR(d,e).bp(0,!1)
r=0}p=J.bi(q)
if(r+s>p.gm(q))throw B.f(B.nH())
if(r<b)for(o=s-1;o>=0;--o)this.j(a,b+o,p.h(q,r+o))
else for(o=0;o<s;++o)this.j(a,b+o,p.h(q,r+o))},
b9(a,b,c,d){return this.aa(a,b,c,d,0)},
v(a){return B.mH(a,"[","]")},
$iw:1,
$ia:1,
$iG:1}
B.S.prototype={
af(a,b){var s,r,q,p=B.e(this)
p.i("~(S.K,S.V)").a(b)
for(s=this.gY(),s=s.gq(s),p=p.i("S.V");s.l();){r=s.gu()
q=this.h(0,r)
b.$2(r,q==null?p.a(q):q)}},
aq(a,b,c){var s,r=this,q=B.e(r)
q.i("S.K").a(a)
q.i("S.V(S.V)").a(b)
q.i("S.V()?").a(c)
if(r.J(a)){s=r.h(0,a)
q=b.$1(s==null?q.i("S.V").a(s):s)
r.j(0,a,q)
return q}q=c.$0()
r.j(0,a,q)
return q},
gav(){return this.gY().b6(0,new B.kT(this),B.e(this).i("P<S.K,S.V>"))},
aX(a,b,c,d){var s,r,q,p,o,n=B.e(this)
n.E(c).E(d).i("P<1,2>(S.K,S.V)").a(b)
s=B.n(c,d)
for(r=this.gY(),r=r.gq(r),n=n.i("S.V");r.l();){q=r.gu()
p=this.h(0,q)
o=b.$2(q,p==null?n.a(p):p)
s.j(0,o.a,o.b)}return s},
a1(a,b){var s,r,q,p,o,n=this,m=B.e(n)
m.i("i(S.K,S.V)").a(b)
s=B.m([],m.i("v<S.K>"))
for(r=n.gY(),r=r.gq(r),m=m.i("S.V");r.l();){q=r.gu()
p=n.h(0,q)
if(b.$2(q,p==null?m.a(p):p))A.b.n(s,q)}for(m=s.length,o=0;o<s.length;s.length===m||(0,B.Z)(s),++o)n.X(0,s[o])},
J(a){return this.gY().p(0,a)},
gm(a){var s=this.gY()
return s.gm(s)},
gO(a){var s=this.gY()
return s.gO(s)},
ga8(a){var s=this.gY()
return!s.gO(s)},
gaZ(){return new B.ey(this,B.e(this).i("ey<S.K,S.V>"))},
v(a){return B.kU(this)},
$it:1}
B.kT.prototype={
$1(a){var s=this.a,r=B.e(s)
r.i("S.K").a(a)
s=s.h(0,a)
if(s==null)s=r.i("S.V").a(s)
return new B.P(a,s,r.i("P<S.K,S.V>"))},
$S(){return B.e(this.a).i("P<S.K,S.V>(S.K)")}}
B.kV.prototype={
$2(a,b){var s,r=this.a
if(!r.a)this.b.a+=", "
r.a=!1
r=this.b
s=B.z(a)
r.a=(r.a+=s)+": "
s=B.z(b)
r.a+=s},
$S:31}
B.ey.prototype={
gm(a){var s=this.a
return s.gm(s)},
gO(a){var s=this.a
return s.gO(s)},
ga8(a){var s=this.a
return s.ga8(s)},
gM(a){var s=this.a,r=s.gY()
r=s.h(0,r.gM(r))
return r==null?this.$ti.y[1].a(r):r},
gq(a){var s=this.a,r=s.gY()
return new B.ez(r.gq(r),s,this.$ti.i("ez<1,2>"))}}
B.ez.prototype={
l(){var s=this,r=s.a
if(r.l()){s.c=s.b.h(0,r.gu())
return!0}s.c=null
return!1},
gu(){var s=this.c
return s==null?this.$ti.y[1].a(s):s},
$iX:1}
B.eL.prototype={
j(a,b,c){var s=this.$ti
s.c.a(b)
s.y[1].a(c)
throw B.f(B.ax("Cannot modify unmodifiable map"))}}
B.cT.prototype={
h(a,b){return this.a.h(0,b)},
j(a,b,c){var s=this.$ti
this.a.j(0,s.c.a(b),s.y[1].a(c))},
J(a){return this.a.J(a)},
af(a,b){this.a.af(0,this.$ti.i("~(1,2)").a(b))},
gO(a){return this.a.a===0},
gm(a){return this.a.a},
gY(){var s=this.a
return new B.aJ(s,B.e(s).i("aJ<1>"))},
v(a){return B.kU(this.a)},
gaZ(){var s=this.a
return new B.ai(s,B.e(s).i("ai<2>"))},
gav(){var s=this.a
return new B.y(s,B.e(s).i("y<1,2>"))},
aX(a,b,c,d){return this.a.aX(0,this.$ti.E(c).E(d).i("P<1,2>(3,4)").a(b),c,d)},
$it:1}
B.er.prototype={}
B.cw.prototype={
gO(a){return this.gm(this)===0},
ga8(a){return this.gm(this)!==0},
A(a,b){var s
B.e(this).i("a<1>").a(b)
for(s=b.gq(b);s.l();)this.n(0,s.gu())},
el(a){var s
for(s=J.at(a);s.l();)this.X(0,s.gu())},
em(a){var s,r=this.aK(0)
for(s=a.gq(a);s.l();)r.X(0,s.gu())
this.el(r)},
v(a){return B.mH(this,"{","}")},
aI(a,b,c,d){var s,r
d.a(b)
B.e(this).E(d).i("1(1,2)").a(c)
for(s=this.gq(this),r=b;s.l();)r=c.$2(r,s.gu())
return r},
aO(a,b){var s
B.e(this).i("i(1)").a(b)
for(s=this.gq(this);s.l();)if(!b.$1(s.gu()))return!1
return!0},
aW(a,b){var s,r,q=this.gq(this)
if(!q.l())return""
s=J.au(q.gu())
if(!q.l())return s
if(b.length===0){r=s
do r+=B.z(q.gu())
while(q.l())}else{r=s
do r=r+b+B.z(q.gu())
while(q.l())}return r.charCodeAt(0)==0?r:r},
ah(a,b){return B.mU(this,b,B.e(this).c)},
gM(a){var s=this.gq(this)
if(!s.l())throw B.f(B.bI())
return s.gu()},
V(a,b){var s,r
B.aO(b,"index")
s=this.gq(this)
for(r=b;s.l();){if(r===0)return s.gu();--r}throw B.f(B.kM(b,b-r,this,"index"))},
$iw:1,
$ia:1,
$icZ:1}
B.eF.prototype={
aK(a){var s=this.eW()
s.A(0,this)
return s}}
B.dG.prototype={}
B.ex.prototype={
h(a,b){var s,r=this.b
if(r==null)return this.c.h(0,b)
else if(typeof b!="string")return null
else{s=r[b]
return typeof s=="undefined"?this.eZ(b):s}},
gm(a){return this.b==null?this.c.a:this.ba().length},
gO(a){return this.gm(0)===0},
ga8(a){return this.gm(0)>0},
gY(){if(this.b==null){var s=this.c
return new B.aJ(s,B.e(s).i("aJ<1>"))}return new B.fT(this)},
gaZ(){var s,r=this
if(r.b==null){s=r.c
return new B.ai(s,B.e(s).i("ai<2>"))}return B.bt(r.ba(),new B.lA(r),t.N,t.z)},
j(a,b,c){var s,r,q=this
B.M(b)
if(q.b==null)q.c.j(0,b,c)
else if(q.J(b)){s=q.b
s[b]=c
r=q.a
if(r==null?s!=null:r!==s)r[b]=null}else q.dY().j(0,b,c)},
J(a){if(this.b==null)return this.c.J(a)
if(typeof a!="string")return!1
return Object.prototype.hasOwnProperty.call(this.a,a)},
X(a,b){if(this.b!=null&&!this.J(b))return null
return this.dY().X(0,b)},
af(a,b){var s,r,q,p,o=this
t.lc.a(b)
if(o.b==null)return o.c.af(0,b)
s=o.ba()
for(r=0;r<s.length;++r){q=s[r]
p=o.b[q]
if(typeof p=="undefined"){p=B.lS(o.a[q])
o.b[q]=p}b.$2(q,p)
if(s!==o.c)throw B.f(B.af(o))}},
ba(){var s=t.g.a(this.c)
if(s==null)s=this.c=B.m(Object.keys(this.a),t.s)
return s},
dY(){var s,r,q,p,o,n=this
if(n.b==null)return n.c
s=B.n(t.N,t.z)
r=n.ba()
for(q=0;p=r.length,q<p;++q){o=r[q]
s.j(0,o,n.h(0,o))}if(p===0)A.b.n(r,"")
else A.b.aB(r)
n.a=n.b=null
return n.c=s},
eZ(a){var s
if(!Object.prototype.hasOwnProperty.call(this.a,a))return null
s=B.lS(this.a[a])
return this.b[a]=s}}
B.lA.prototype={
$1(a){return this.a.h(0,B.M(a))},
$S:28}
B.fT.prototype={
gm(a){return this.a.gm(0)},
V(a,b){var s=this.a
if(s.b==null)s=s.gY().V(0,b)
else{s=s.ba()
if(!(b>=0&&b<s.length))return B.b(s,b)
s=s[b]}return s},
gq(a){var s=this.a
if(s.b==null){s=s.gY()
s=s.gq(s)}else{s=s.ba()
s=new J.cJ(s,s.length,B.q(s).i("cJ<1>"))}return s},
p(a,b){return this.a.J(b)}}
B.dh.prototype={$ic6:1}
B.eu.prototype={}
B.eZ.prototype={}
B.bS.prototype={}
B.eb.prototype={
v(a){var s=B.fb(this.a)
return(this.b!=null?"Converting object to an encodable object failed:":"Converting object did not return an encodable object:")+" "+s}}
B.fo.prototype={
v(a){return"Cyclic error in JSON stringify"}}
B.fn.prototype={
bc(a,b){var s=B.rD(a,this.gfk().a)
return s},
a_(a,b){var s=B.qG(a,this.gfu().b,null)
return s},
gfu(){return A.jD},
gfk(){return A.jC}}
B.fq.prototype={}
B.fp.prototype={}
B.lC.prototype={
er(a){var s,r,q,p,o,n,m=a.length
for(s=this.c,r=0,q=0;q<m;++q){p=a.charCodeAt(q)
if(p>92){if(p>=55296){o=p&64512
if(o===55296){n=q+1
n=!(n<m&&(a.charCodeAt(n)&64512)===56320)}else n=!1
if(!n)if(o===56320){o=q-1
o=!(o>=0&&(a.charCodeAt(o)&64512)===55296)}else o=!1
else o=!0
if(o){if(q>r)s.a+=A.i.an(a,r,q)
r=q+1
o=B.aM(92)
s.a+=o
o=B.aM(117)
s.a+=o
o=B.aM(100)
s.a+=o
o=p>>>8&15
o=B.aM(o<10?48+o:87+o)
s.a+=o
o=p>>>4&15
o=B.aM(o<10?48+o:87+o)
s.a+=o
o=p&15
o=B.aM(o<10?48+o:87+o)
s.a+=o}}continue}if(p<32){if(q>r)s.a+=A.i.an(a,r,q)
r=q+1
o=B.aM(92)
s.a+=o
switch(p){case 8:o=B.aM(98)
s.a+=o
break
case 9:o=B.aM(116)
s.a+=o
break
case 10:o=B.aM(110)
s.a+=o
break
case 12:o=B.aM(102)
s.a+=o
break
case 13:o=B.aM(114)
s.a+=o
break
default:o=B.aM(117)
s.a+=o
o=B.aM(48)
s.a=(s.a+=o)+o
o=p>>>4&15
o=B.aM(o<10?48+o:87+o)
s.a+=o
o=p&15
o=B.aM(o<10?48+o:87+o)
s.a+=o
break}}else if(p===34||p===92){if(q>r)s.a+=A.i.an(a,r,q)
r=q+1
o=B.aM(92)
s.a+=o
o=B.aM(p)
s.a+=o}}if(r===0)s.a+=a
else if(r<m)s.a+=A.i.an(a,r,m)},
cD(a){var s,r,q,p
for(s=this.a,r=s.length,q=0;q<r;++q){p=s[q]
if(a==null?p==null:a===p)throw B.f(new B.fo(a,null))}A.b.n(s,a)},
cv(a){var s,r,q,p,o=this
if(o.eq(a))return
o.cD(a)
try{s=o.b.$1(a)
if(!o.eq(s)){q=B.nL(a,null,o.gdK())
throw B.f(q)}q=o.a
if(0>=q.length)return B.b(q,-1)
q.pop()}catch(p){r=B.b9(p)
q=B.nL(a,r,o.gdK())
throw B.f(q)}},
eq(a){var s,r,q=this
if(typeof a=="number"){if(!isFinite(a))return!1
q.c.a+=A.c.v(a)
return!0}else if(a===!0){q.c.a+="true"
return!0}else if(a===!1){q.c.a+="false"
return!0}else if(a==null){q.c.a+="null"
return!0}else if(typeof a=="string"){s=q.c
s.a+='"'
q.er(a)
s.a+='"'
return!0}else if(t.j.b(a)){q.cD(a)
q.h6(a)
s=q.a
if(0>=s.length)return B.b(s,-1)
s.pop()
return!0}else if(t.f.b(a)){q.cD(a)
r=q.h7(a)
s=q.a
if(0>=s.length)return B.b(s,-1)
s.pop()
return r}else return!1},
h6(a){var s,r,q=this.c
q.a+="["
s=J.bi(a)
if(s.ga8(a)){this.cv(s.h(a,0))
for(r=1;r<s.gm(a);++r){q.a+=","
this.cv(s.h(a,r))}}q.a+="]"},
h7(a){var s,r,q,p,o,n,m=this,l={}
if(a.gO(a)){m.c.a+="{}"
return!0}s=a.gm(a)*2
r=B.mN(s,null,!1,t.X)
q=l.a=0
l.b=!0
a.af(0,new B.lD(l,r))
if(!l.b)return!1
p=m.c
p.a+="{"
for(o='"';q<s;q+=2,o=',"'){p.a+=o
m.er(B.M(r[q]))
p.a+='":'
n=q+1
if(!(n<s))return B.b(r,n)
m.cv(r[n])}p.a+="}"
return!0}}
B.lD.prototype={
$2(a,b){var s,r
if(typeof a!="string")this.a.b=!1
s=this.b
r=this.a
A.b.j(s,r.a++,a)
A.b.j(s,r.a++,b)},
$S:31}
B.lB.prototype={
gdK(){var s=this.c.a
return s.charCodeAt(0)==0?s:s}}
B.fM.prototype={
fj(a){var s,r,q,p,o=a.length,n=B.l5(0,null,o)
if(n===0)return new Uint8Array(0)
s=n*3
r=new Uint8Array(s)
q=new B.lL(r)
if(q.eS(a,0,n)!==n){p=n-1
if(!(p>=0&&p<o))return B.b(a,p)
q.cX()}return new Uint8Array(r.subarray(0,B.r4(0,q.b,s)))}}
B.lL.prototype={
cX(){var s,r=this,q=r.c,p=r.b,o=r.b=p+1
q.$flags&2&&B.ae(q)
s=q.length
if(!(p<s))return B.b(q,p)
q[p]=239
p=r.b=o+1
if(!(o<s))return B.b(q,o)
q[o]=191
r.b=p+1
if(!(p<s))return B.b(q,p)
q[p]=189},
fa(a,b){var s,r,q,p,o,n=this
if((b&64512)===56320){s=65536+((a&1023)<<10)|b&1023
r=n.c
q=n.b
p=n.b=q+1
r.$flags&2&&B.ae(r)
o=r.length
if(!(q<o))return B.b(r,q)
r[q]=s>>>18|240
q=n.b=p+1
if(!(p<o))return B.b(r,p)
r[p]=s>>>12&63|128
p=n.b=q+1
if(!(q<o))return B.b(r,q)
r[q]=s>>>6&63|128
n.b=p+1
if(!(p<o))return B.b(r,p)
r[p]=s&63|128
return!0}else{n.cX()
return!1}},
eS(a,b,c){var s,r,q,p,o,n,m,l,k=this
if(b!==c){s=c-1
if(!(s>=0&&s<a.length))return B.b(a,s)
s=(a.charCodeAt(s)&64512)===55296}else s=!1
if(s)--c
for(s=k.c,r=s.$flags|0,q=s.length,p=a.length,o=b;o<c;++o){if(!(o<p))return B.b(a,o)
n=a.charCodeAt(o)
if(n<=127){m=k.b
if(m>=q)break
k.b=m+1
r&2&&B.ae(s)
s[m]=n}else{m=n&64512
if(m===55296){if(k.b+4>q)break
m=o+1
if(!(m<p))return B.b(a,m)
if(k.fa(n,a.charCodeAt(m)))o=m}else if(m===56320){if(k.b+3>q)break
k.cX()}else if(n<=2047){m=k.b
l=m+1
if(l>=q)break
k.b=l
r&2&&B.ae(s)
if(!(m<q))return B.b(s,m)
s[m]=n>>>6|192
k.b=l+1
s[l]=n&63|128}else{m=k.b
if(m+2>=q)break
l=k.b=m+1
r&2&&B.ae(s)
if(!(m<q))return B.b(s,m)
s[m]=n>>>12|224
m=k.b=l+1
if(!(l<q))return B.b(s,l)
s[l]=n>>>6&63|128
k.b=m+1
if(!(m<q))return B.b(s,m)
s[m]=n&63|128}}}return o}}
B.f0.prototype={
$0(){var s=this
return B.aX(B.bR("("+s.a+", "+s.b+", "+s.c+", "+s.d+", "+s.e+", "+s.f+", "+s.r+", "+s.w+")",null))},
$S:32}
B.ac.prototype={
P(a){var s=1000,r=A.a.D(a,s),q=A.a.G(a-r,s),p=this.b+r,o=A.a.D(p,s),n=this.c
return new B.ac(B.nt(this.a+A.a.G(p-o,s)+q,o,n),o,n)},
au(a){return B.ah(0,0,this.b-a.b,this.a-a.a,0,0)},
ag(a,b){if(b==null)return!1
return b instanceof B.ac&&this.a===b.a&&this.b===b.b&&this.c===b.c},
gR(a){return B.mP(this.a,this.b,A.at,A.at)},
dd(a){var s=this.a,r=a.a
if(s>=r)s=s===r&&this.b<a.b
else s=!0
return s},
ac(a){var s=this.a,r=a.a
if(s<=r)s=s===r&&this.b>a.b
else s=!0
return s},
Z(a,b){var s
t.h.a(b)
s=A.a.Z(this.a,b.a)
if(s!==0)return s
return A.a.Z(this.b,b.b)},
am(){var s=this
if(s.c)return s
return new B.ac(s.a,s.b,!0)},
v(a){var s=this,r=B.ns(B.aj(s)),q=B.bT(B.aU(s)),p=B.bT(B.aT(s)),o=B.bT(B.dy(s)),n=B.bT(B.fB(s)),m=B.bT(B.nS(s)),l=B.hp(B.nR(s)),k=s.b,j=k===0?"":B.hp(k)
k=r+"-"+q
if(s.c)return k+"-"+p+" "+o+":"+n+":"+m+"."+l+j+"Z"
else return k+"-"+p+" "+o+":"+n+":"+m+"."+l+j},
K(){var s=this,r=B.aj(s)>=-9999&&B.aj(s)<=9999?B.ns(B.aj(s)):B.pw(B.aj(s)),q=B.bT(B.aU(s)),p=B.bT(B.aT(s)),o=B.bT(B.dy(s)),n=B.bT(B.fB(s)),m=B.bT(B.nS(s)),l=B.hp(B.nR(s)),k=s.b,j=k===0?"":B.hp(k)
k=r+"-"+q
if(s.c)return k+"-"+p+"T"+o+":"+n+":"+m+"."+l+j+"Z"
else return k+"-"+p+"T"+o+":"+n+":"+m+"."+l+j},
$iba:1}
B.hr.prototype={
$1(a){if(a==null)return 0
return B.eQ(a,null)},
$S:34}
B.hs.prototype={
$1(a){var s,r,q
if(a==null)return 0
for(s=a.length,r=0,q=0;q<6;++q){r*=10
if(q<s){if(!(q<s))return B.b(a,q)
r+=a.charCodeAt(q)^48}}return r},
$S:34}
B.a_.prototype={
ag(a,b){if(b==null)return!1
return b instanceof B.a_&&this.a===b.a},
gR(a){return A.a.gR(this.a)},
Z(a,b){return A.a.Z(this.a,t.jS.a(b).a)},
v(a){var s,r,q,p,o,n=this.a,m=A.a.G(n,36e8),l=n%36e8
if(n<0){m=0-m
n=0-l
s="-"}else{n=l
s=""}r=A.a.G(n,6e7)
n%=6e7
q=r<10?"0":""
p=A.a.G(n,1e6)
o=p<10?"0":""
return s+m+":"+q+r+":"+o+p+"."+A.i.b7(A.a.v(n%1e6),6,"0")},
$iba:1}
B.fP.prototype={
v(a){return this.B()},
$iO:1}
B.a6.prototype={
gbN(){return B.qn(this)}}
B.eU.prototype={
v(a){var s=this.a
if(s!=null)return"Assertion failed: "+B.fb(s)
return"Assertion failed"}}
B.cd.prototype={}
B.br.prototype={
gcK(){return"Invalid argument"+(!this.a?"(s)":"")},
gcJ(){return""},
v(a){var s=this,r=s.c,q=r==null?"":" ("+r+")",p=s.d,o=p==null?"":": "+B.z(p),n=s.gcK()+q+o
if(!s.a)return n
return n+s.gcJ()+": "+B.fb(s.gdc())},
gdc(){return this.b}}
B.dz.prototype={
gdc(){return B.dI(this.b)},
gcK(){return"RangeError"},
gcJ(){var s,r=this.e,q=this.f
if(r==null)s=q!=null?": Not less than or equal to "+B.z(q):""
else if(q==null)s=": Not greater than or equal to "+B.z(r)
else if(q>r)s=": Not in inclusive range "+B.z(r)+".."+B.z(q)
else s=q<r?": Valid value range is empty":": Only valid value is "+B.z(r)
return s}}
B.fh.prototype={
gdc(){return B.r(this.b)},
gcK(){return"RangeError"},
gcJ(){if(B.r(this.b)<0)return": index must not be negative"
var s=this.f
if(s===0)return": no indices are valid"
return": index should be less than "+s},
gm(a){return this.f}}
B.es.prototype={
v(a){return"Unsupported operation: "+this.a}}
B.fK.prototype={
v(a){return"UnimplementedError: "+this.a}}
B.dA.prototype={
v(a){return"Bad state: "+this.a}}
B.f_.prototype={
v(a){var s=this.a
if(s==null)return"Concurrent modification during iteration."
return"Concurrent modification during iteration: "+B.fb(s)+"."}}
B.fy.prototype={
v(a){return"Out of Memory"},
gbN(){return null},
$ia6:1}
B.ep.prototype={
v(a){return"Stack Overflow"},
gbN(){return null},
$ia6:1}
B.lo.prototype={
v(a){return"Exception: "+this.a}}
B.aI.prototype={
v(a){var s=this.a,r=""!==s?"FormatException: "+s:"FormatException",q=this.b
if(typeof q=="string"){if(q.length>78)q=A.i.an(q,0,75)+"..."
return r+"\n"+q}else return r}}
B.a.prototype={
b6(a,b,c){var s=B.e(this)
return B.bt(this,s.E(c).i("1(a.E)").a(b),s.i("a.E"),c)},
cu(a,b){var s=B.e(this)
return new B.j(this,s.i("i(a.E)").a(b),s.i("j<a.E>"))},
dj(a,b){return new B.b_(this,b.i("b_<0>"))},
p(a,b){var s
for(s=this.gq(this);s.l();)if(J.F(s.gu(),b))return!0
return!1},
aI(a,b,c,d){var s,r
d.a(b)
B.e(this).E(d).i("1(1,a.E)").a(c)
for(s=this.gq(this),r=b;s.l();)r=c.$2(r,s.gu())
return r},
aO(a,b){var s
B.e(this).i("i(a.E)").a(b)
for(s=this.gq(this);s.l();)if(!b.$1(s.gu()))return!1
return!0},
N(a,b){var s
B.e(this).i("i(a.E)").a(b)
for(s=this.gq(this);s.l();)if(b.$1(s.gu()))return!0
return!1},
bp(a,b){var s=B.e(this).i("a.E")
if(b)s=B.k(this,s)
else{s=B.k(this,s)
s.$flags=1
s=s}return s},
bJ(a){return this.bp(0,!0)},
aK(a){return B.a3(this,B.e(this).i("a.E"))},
gm(a){var s,r=this.gq(this)
for(s=0;r.l();)++s
return s},
gO(a){return!this.gq(this).l()},
ga8(a){return!this.gO(this)},
ah(a,b){return B.mU(this,b,B.e(this).i("a.E"))},
gM(a){var s=this.gq(this)
if(!s.l())throw B.f(B.bI())
return s.gu()},
a7(a,b,c){var s,r=B.e(this)
r.i("i(a.E)").a(b)
r.i("a.E()?").a(c)
for(r=this.gq(this);r.l();){s=r.gu()
if(b.$1(s))return s}r=c.$0()
return r},
V(a,b){var s,r
B.aO(b,"index")
s=this.gq(this)
for(r=b;s.l();){if(r===0)return s.gu();--r}throw B.f(B.kM(b,b-r,this,"index"))},
v(a){return B.q7(this,"(",")")}}
B.P.prototype={
v(a){return"MapEntry("+B.z(this.a)+": "+B.z(this.b)+")"}}
B.aL.prototype={
gR(a){return B.I.prototype.gR.call(this,0)},
v(a){return"null"}}
B.I.prototype={$iI:1,
ag(a,b){return this===b},
gR(a){return B.el(this)},
v(a){return"Instance of '"+B.fC(this)+"'"},
ga2(a){return B.tf(this)},
toString(){return this.v(this)}}
B.h1.prototype={
v(a){return""},
$ibL:1}
B.cY.prototype={
gq(a){return new B.fF(this.a)}}
B.fF.prototype={
gu(){return this.d},
l(){var s,r,q,p=this,o=p.b=p.c,n=p.a,m=n.length
if(o===m){p.d=-1
return!1}if(!(o<m))return B.b(n,o)
s=n.charCodeAt(o)
r=o+1
if((s&64512)===55296&&r<m){if(!(r<m))return B.b(n,r)
q=n.charCodeAt(r)
if((q&64512)===56320){p.c=r+1
p.d=B.r5(s,q)
return!0}}p.c=r
p.d=s
return!0},
$iX:1}
B.dB.prototype={
gm(a){return this.a.length},
v(a){var s=this.a
return s.charCodeAt(0)==0?s:s},
$iqt:1}
B.j4.prototype={
$2(a,b){var s=t.C
this.a.dh(new B.j2(s.a(a)),new B.j3(s.a(b)),t.X)},
$S:63}
B.j2.prototype={
$1(a){var s=this.a
s.call(s,a)
return a},
$S:37}
B.j3.prototype={
$2(a,b){var s,r,q,p
B.dJ(a)
t.l.a(b)
s=t.C.a(v.G.Error)
r=B.rZ(s,["Dart exception thrown from converted Future. Use the properties 'error' to fetch the boxed error and 'stack' to recover the stack trace."],t.B)
if(t.d9.b(a))B.aX("Attempting to box non-Dart object.")
q={}
q[$.oV()]=a
r.error=q
r.stack=b.v(0)
p=this.a
p.call(p,r)
return r},
$S:55}
B.fW.prototype={
eB(a){var s,r,q,p,o,n,m,l=this,k=4294967296,j=a<0?-1:0
do{s=a>>>0
a=A.a.G(a-s,k)
r=a>>>0
a=A.a.G(a-r,k)
q=(~s>>>0)+(s<<21>>>0)
p=q>>>0
r=(~r>>>0)+((r<<21|s>>>11)>>>0)+A.a.G(q-p,k)>>>0
q=((p^(p>>>24|r<<8))>>>0)*265
s=q>>>0
r=((r^r>>>24)>>>0)*265+A.a.G(q-s,k)>>>0
q=((s^(s>>>14|r<<18))>>>0)*21
s=q>>>0
r=((r^r>>>14)>>>0)*21+A.a.G(q-s,k)>>>0
s=(s^(s>>>28|r<<4))>>>0
r=(r^r>>>28)>>>0
q=(s<<31>>>0)+s
p=q>>>0
o=A.a.G(q-p,k)
q=l.a*1037
n=l.a=q>>>0
m=l.b*1037+A.a.G(q-n,k)>>>0
l.b=m
n=(n^p)>>>0
l.a=n
o=(m^r+((r<<31|s>>>1)>>>0)+o>>>0)>>>0
l.b=o}while(a!==j)
if(o===0&&n===0)l.a=23063
l.aM()
l.aM()
l.aM()
l.aM()},
aM(){var s=this,r=s.a,q=4294901760*r,p=q>>>0,o=55905*r,n=o>>>0,m=n+p+s.b
r=m>>>0
s.a=r
s.b=A.a.G(o-n+(q-p)+(m-r),4294967296)>>>0},
C(a){var s,r,q,p=this
if(a<=0||a>4294967296)throw B.f(B.qq("max must be in range 0 < max \u2264 2^32, was "+a))
s=a-1
if((a&s)>>>0===0){p.aM()
return(p.a&s)>>>0}do{p.aM()
r=p.a
q=r%a}while(r-q+a>=4294967296)
return q},
S(){var s,r=this
r.aM()
s=r.a
r.aM()
return((s&67108863)*134217728+(r.a&134217727))/9007199254740992},
$ifD:1}
B.fa.prototype={}
B.bU.prototype={
ag(a,b){var s,r,q,p,o,n,m
if(b==null)return!1
if(b instanceof B.bU){s=this.a
r=b.a
q=s.length
p=r.length
if(q!==p)return!1
for(o=0,n=0;n<q;++n){m=s[n]
if(!(n<p))return B.b(r,n)
o|=m^r[n]}return o===0}return!1},
gR(a){return B.qj(this.a)},
v(a){return B.re(this.a)}}
B.dj.prototype={$ic6:1}
B.e4.prototype={}
B.fd.prototype={
n(a,b){var s=this
t.I.a(b)
if(s.w)throw B.f(B.bv("Hash.add() called after close()."))
s.r=s.r+b.length
s.du(b)},
du(a){var s,r,q,p,o,n,m,l,k,j,i=this
t.I.a(a)
s=i.e
r=i.d
q=r.length
if(i.c==null)i.c=J.mm(A.al.gbu(r))
for(p=i.f,o=p.$flags|0,n=p.length,m=0;;s=0){l=s+a.length-m
if(l<q){A.al.aa(r,s,l,a,m)
i.e=l
return}A.al.aa(r,s,q,a,m)
m+=q-s
k=0
do{j=i.c.getUint32(k*4,!1)
o&2&&B.ae(p)
if(!(k<n))return B.b(p,k)
p[k]=j;++k}while(k<n)
i.h4(p)}},
bv(){var s,r,q,p,o,n,m,l=this
if(l.w)return
l.w=!0
s=l.r
if(s>1125899906842623)B.aX(B.ax("Hashing is unsupported for messages with more than 2^53 bits."))
r=l.d.byteLength
r=((s+1+8+r-1&-r)>>>0)-s
q=new Uint8Array(r)
if(0>=r)return B.b(q,0)
q[0]=128
p=s*8
o=r-8
n=J.mm(A.al.gbu(q))
m=A.a.G(p,4294967296)
n.$flags&2&&B.ae(n,11)
n.setUint32(o,m,!1)
n.setUint32(o+4,p>>>0,!1)
l.du(q)
s=l.a
r=l.eK()
if(s.a!=null)B.aX(B.bv("add may only be called once."))
s.a=new B.bU(r)},
eK(){var s,r,q,p,o,n,m
if(A.bP===$.oK())return J.p8(A.NT.gbu(this.y))
s=this.y
r=s.byteLength
q=new Uint8Array(r)
p=J.mm(A.al.gbu(q))
for(r=s.length,o=p.$flags|0,n=0;n<r;++n){m=s[n]
o&2&&B.ae(p,11)
p.setUint32(n*4,m,!1)}return q},
$ic6:1}
B.fg.prototype={}
B.fS.prototype={
eA(a,b,c){var s,r,q,p,o=this,n=B.mZ(t.bL.a(o.b))
o.c!==$&&B.ne()
o.c=new B.eu(n)
s=c.length
r=new Uint8Array(s)
for(q=0;q<s;++q){p=c[q]
if(!(q<s))return B.b(r,q)
r[q]=92^p}t.I.a(r)
o.a.a.n(0,r)
for(q=0;q<s;++q){p=c[q]
if(!(q<s))return B.b(r,q)
r[q]=54^p}n.n(0,r)},
bv(){var s,r=this
if(r.d)return
r.d=!0
s=r.c
s===$&&B.N()
s.a.bv()
s=r.a.a
s.n(0,t.I.a(r.b.a.a))
s.bv()}}
B.fY.prototype={}
B.h_.prototype={
h4(a0){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a
for(s=this.z,r=a0.length,q=s.$flags|0,p=0;p<16;++p){if(!(p<r))return B.b(a0,p)
o=a0[p]
q&2&&B.ae(s)
s[p]=o}for(p=16;p<64;++p){r=s[p-2]
o=s[p-7]
n=s[p-15]
m=s[p-16]
q&2&&B.ae(s)
s[p]=((((r>>>17|r<<15)^(r>>>19|r<<13)^r>>>10)>>>0)+o>>>0)+((((n>>>7|n<<25)^(n>>>18|n<<14)^n>>>3)>>>0)+m>>>0)>>>0}r=this.y
q=r.length
if(0>=q)return B.b(r,0)
l=r[0]
if(1>=q)return B.b(r,1)
k=r[1]
if(2>=q)return B.b(r,2)
j=r[2]
if(3>=q)return B.b(r,3)
i=r[3]
if(4>=q)return B.b(r,4)
h=r[4]
if(5>=q)return B.b(r,5)
g=r[5]
if(6>=q)return B.b(r,6)
f=r[6]
if(7>=q)return B.b(r,7)
e=r[7]
for(d=l,p=0;p<64;++p,e=f,f=g,g=h,h=b,i=j,j=k,k=d,d=a){c=(e+(((h>>>6|h<<26)^(h>>>11|h<<21)^(h>>>25|h<<7))>>>0)>>>0)+(((h&g^~h&f)>>>0)+(A.rh[p]+s[p]>>>0)>>>0)>>>0
b=i+c>>>0
a=c+((((d>>>2|d<<30)^(d>>>13|d<<19)^(d>>>22|d<<10))>>>0)+((d&k^d&j^k&j)>>>0)>>>0)>>>0}r.$flags&2&&B.ae(r)
r[0]=d+l>>>0
r[1]=k+r[1]>>>0
r[2]=j+r[2]>>>0
r[3]=i+r[3]>>>0
r[4]=h+r[4]>>>0
r[5]=g+r[5]>>>0
r[6]=f+r[6]>>>0
r[7]=e+r[7]>>>0}}
B.fZ.prototype={}
B.j5.prototype={
ex(a){var s,r,q,p,o,n,m,l,k,j,i,h,g,f=this,e="incubatingEgg",d=B.j8(a.h(0,"pet")),c=t.N,b=t.z
f.cI("wallet",B.V(["coins",d.h(0,"coins"),"gems",d.h(0,"gems")],c,b))
for(s=0;s<4;++s){r=A.nC[s]
f.cI(r,B.j8(a.h(0,r)))}for(q=f.a,p=t.j,s=0;s<21;++s){r=A.x1[s]
o=a.h(0,r)
if(!p.b(o)||J.p6(o,new B.ja()))throw B.f(B.dp("Invalid canonical collection: "+r,null))
for(n=J.nk(o),m=B.e(n),l=new B.cg(n,n.r,m.i("cg<1>")),l.c=n.e,m=m.c;l.l();){k=l.d
q.j(0,A.k.a_([r,k==null?m.a(k):k],null),1)}}j=a.h(0,"chronoshardReductions")
if(!p.b(j))throw B.f(A.iH)
for(n=J.at(j),m=t.hf;n.l();){i=n.gu()
if(!B.cC(i)||i<10||i>90)throw B.f(A.iK)
r=A.k.a_(B.m(["chronoshard",i],m),null)
l=B.og(q.h(0,r))
q.j(0,r,(l==null?0:l)+1)}h=new B.jb(f,B.a1(c),a)
h.$2(d,J.F(d.h(0,"stage"),"egg")?"nest":"dragon")
if(a.h(0,e)!=null)h.$2(a.h(0,e),"nest")
for(s=0;s<3;++s){r=A.bh[s]
o=a.h(0,r)
if(!p.b(o))throw B.f(A.iQ)
for(n=J.at(o),m="sanctuaryDragons"===r,l="eggStash"===r;n.l();){k=n.gu()
A:{if(l){g="egg"
break A}if(m){g="dragon"
break A}g="released_dragon"
break A}h.$2(k,g)}}for(s=0;s<16;++s){r=A.Hl[s]
q.j(0,r,B.cP(a.h(0,r)))}c=B.n(c,b)
for(b=a.gav(),b=b.gq(b);b.l();){q=b.gu()
p=q.a
if(A.i.cz(p,"total"))c.j(0,p,q.b)}f.cI("progression",c)},
cI(a,b){var s,r,q,p,o
t.P.a(b)
for(s=new B.y(b,B.e(b).i("y<1,2>")).gq(0),r=this.a,q=t.s;s.l();){p=s.d
o=p.b
if(!B.cC(o)||o<0||o>9007199254740991)throw B.f(A.iM)
if(o!==0)r.j(0,A.k.a_(B.m([a,p.a],q),null),o)}},
e4(a){var s,r,q,p,o,n=t.N,m=B.a1(n)
for(s=this.a,n=B.a3(new B.aJ(s,B.e(s).i("aJ<1>")),n),r=a.a,n.A(0,new B.aJ(r,B.e(r).i("aJ<1>"))),n=B.lE(n,n.r,B.e(n).c),q=n.$ti.c,p=t.j;n.l();){o=n.d
if(o==null)o=q.a(o)
if(A.k.a_(B.cP(s.h(0,o)),null)!==A.k.a_(B.cP(r.h(0,o)),null))m.n(0,A.i.cz(o,"[")?B.M(J.hc(p.a(A.k.bc(o,null)))):o)}return m}}
B.ja.prototype={
$1(a){return typeof a!="string"},
$S:9}
B.jb.prototype={
$2(a,b){var s,r,q,p,o,n,m,l,k,j="highlightedExpertises",i="altarKnowledge",h="spectral",g="incubationSeconds",f="incubationMinutes",e=B.j8(a),d=e.h(0,"id")
if(typeof d=="string"){s=d.length
s=s===0||s>100||!this.b.n(0,d)}else s=!0
if(s)throw B.f(A.iP)
s=t.N
r=t.z
q=B.n(s,r)
q.j(0,"sex",B.mw(e).b)
p=b==="egg"
if(!p){o=t.g.a(e.h(0,j))
o=J.nk(o==null?[]:o)
o=B.k(o,B.e(o).c)
A.b.cw(o)
q.j(0,j,o)}for(n=0;n<24;++n){m=A.wJ[n]
if(e.J(m))q.j(0,m,e.h(0,m))}o=e.h(0,i)
l=B.j8(o==null?B.n(s,r):o)
s=B.bK(l,s,r)
r=!0
if(!J.F(l.h(0,"moral"),!0))if(!J.F(e.h(0,"moralAxisKnown"),!0))r=p&&J.F(e.h(0,"lineageId"),"sinisterra")
s.j(0,"moral",r)
s.j(0,"order",J.F(l.h(0,"order"),!0)||J.F(e.h(0,"lawAxisKnown"),!0))
s.j(0,"rarity",J.F(l.h(0,"rarity"),!0)||J.eR(t.j.a(this.c.h(0,"eggRarityRevealedIds")),d))
q.j(0,i,s)
q.j(0,h,J.F(e.h(0,h),!0)||J.F(e.h(0,"prismatic"),!0))
s=e.h(0,g)
if(s==null)s=B.cC(e.h(0,f))?B.r(e.h(0,f))*60:null
q.j(0,g,s)
for(n=0;n<3;++n){m=A.tf[n]
if(e.h(0,m)!=null){k=B.a9(J.au(e.h(0,m)))
if(k==null)throw B.f(A.iN)
q.j(0,m,1000*k.a+k.b)}}this.a.a.j(0,A.k.a_(B.m([b,d],t.s),null),B.cP(q))},
$S:76}
B.j9.prototype={
$1(a){return typeof a!="string"},
$S:9}
B.j7.prototype={
$1(a){return J.au(a)},
$S:86}
B.jc.prototype={
$0(){return this.a},
$S:20}
B.bj.prototype={
v(a){return"GameCommandException("+this.a+")"}}
B.lg.prototype={
dg(a,b){var s=this.a.h(0,a),r=!0
if(typeof s=="string")if(A.i.a9(s).length!==0)if(new B.cY(s).gm(0)<=b){r=B.L("[\\x00-\\x1f\\x7f]")
r=r.b.test(s)}if(r)throw B.f(A.aN)
return s},
T(a){return this.dg(a,200)},
ck(a,b,c){var s=this.a.h(0,a)
if(!B.cC(s)||s<c||s>b)throw B.f(A.aN)
return s},
cZ(a){var s=this.a.h(0,a)
if(!B.a5(s))throw B.f(A.aN)
return s},
be(a,b,c){B.t_(c,t.aT,"T","enumValue")
return A.b.a7(c.i("G<0>").a(b),new B.lh(this.T(a),c),new B.li())}}
B.lh.prototype={
$1(a){return this.b.a(a).b===this.a},
$S(){return this.b.i("i(0)")}}
B.li.prototype={
$0(){return B.aX(A.aN)},
$S:32}
B.jf.prototype={
$1(a){return this.a.p(0,J.a2(a,"id"))},
$S:9}
B.jg.prototype={
$1(a){return this.a.p(0,J.a2(a,"id"))},
$S:9}
B.jh.prototype={
$1(a){return this.a.p(0,J.a2(a,"id"))},
$S:9}
B.jd.prototype={
$1(a){return B.fc(a)>0},
$S:9}
B.je.prototype={
$1(a){return B.fc(a)>0},
$S:9}
B.l4.prototype={}
B.b6.prototype={
v(a){return"GameImportException("+this.a+")"}}
B.ji.prototype={
$2(a,b){var s,r,q,p,o,n,m,l=this,k=null,j=l.c,i=a.a
if(a.f===A.h){s=B.pY(l.a,i)
r=a.w
q=a.gdm()
p=s
p=B.b0(p==null?k:J.a2(p,"specialEggId"))
o=a.ay
n=a.c
A.b.n(l.b,B.my(j,B.f1(a.k1,a.ax,a.RG,i,1008,a.cx,a.Q,a.rx,a.as,o,r,q,a.z,a.CW,p,n),"nest",a.k2))}else{m=B.dn(j,i)
j=t.N
i=B.bK(B.cp(a.H(),A.nI),j,t.z)
i.j(0,"location",b)
i.j(0,"lawAxis",m.d||a.at?a.Q.b:k)
i.j(0,"moralAxis",m.c||a.ay?a.as.b:k)
if(a.ch)j=B.k(a.cy,j)
else j=k
i.j(0,"personalityTraitIds",j)
i.j(0,"leadingPath",a.gbm())
j=a.ry
i.j(0,"activeEvolutionPath",j==null?a.gbm():j)
A.b.n(l.d,i)}},
$S:89}
B.fV.prototype={
S(){return B.aX(B.bv("Projection cannot roll rewards"))},
C(a){return B.aX(B.bv("Projection cannot roll rewards"))},
$ifD:1}
B.jj.prototype={
$1(a){if(t.f.b(a)&&typeof a.h(0,"id")=="string")this.a.j(0,B.M(a.h(0,"id")),B.aw(a,t.N,t.z))},
$S:104}
B.jk.prototype={
$1(a){var s=t.N,r=t.z,q=B.aw(t.f.a(a),s,r)
r=B.n(s,r)
s=this.a.h(0,q.h(0,"id"))
if(s!=null)r.A(0,s)
r.A(0,q)
return r},
$S:53}
B.mb.prototype={
$1(a){var s,r
this.b.i("@<0>").E(this.c).i("P<1,2>").a(a)
s=this.a
r=a.a
return s.J(r)&&J.F(s.h(0,r),a.b)},
$S(){return this.b.i("@<0>").E(this.c).i("i(P<1,2>)")}}
B.eW.prototype={
bd(){}}
B.en.prototype={
ey(a,b){var s,r,q,p,o,n,m=this,l=B.L("^[0-9a-f]{64}$")
if(!l.b.test(a)||!A.QP.p(0,b))throw B.f(B.bR("Invalid server entropy",null))
l=B.m([],t.t)
for(s=a.length,r=0;r<s;r=q){q=r+2
l.push(B.eQ(A.i.an(a,r,q),16))}s=new Uint8Array(64)
if(l.length>64){t.I.a(l)
p=new B.dj()
o=B.mZ(t.bL.a(p))
o.n(0,l)
o.bv()
n=p.a.a}else n=l
A.al.b9(s,0,n.length,n)
m.a!==$&&B.ne()
m.a=new B.fg(A.e2,s)
m.b!==$&&B.ne()
m.b="dragonhaven/economy/v1/"+b+"/"},
br(){var s,r,q,p=this,o=p.d,n=p.c
if(o===n.length){o=p.a
o===$&&B.N()
n=p.b
n===$&&B.N()
n=t.I.a(A.e1.fj(n+p.e++))
s=new B.dj()
t.bL.a(s)
r=new B.fS(new B.eu(B.mZ(s)),new B.dj())
r.eA(s,o.a,o.b)
if(r.d)B.aX(B.bv("HMAC is closed"))
o=r.c
o===$&&B.N()
o.a.n(0,n)
r.bv()
n=p.c=s.a.a
o=p.d=0
q=n
n=o
o=q}else{q=n
n=o
o=q}p.d=n+1
if(!(n<o.length))return B.b(o,n)
return o[n]},
bV(){var s=this
return s.br()*16777216+s.br()*65536+s.br()*256+s.br()},
C(a){var s,r
if(a<1||a>4294967296)throw B.f(B.aN(a,1,4294967296,null,null))
s=4294967296-4294967296%a
r=this.bV()
while(r>=s)r=this.bV()
return r%a},
S(){return(A.a.G(this.bV(),64)*134217728+A.a.G(this.bV(),32))/9007199254740992},
h5(){var s,r,q,p=J.mI(16,t.S)
for(s=0;s<16;++s)p[s]=this.br()
A.b.j(p,6,p[6]&15|64)
A.b.j(p,8,p[8]&63|128)
r=B.q(p)
q=new B.K(p,r.i("d(1)").a(new B.l9()),r.i("K<1,d>")).fL(0)
return A.i.an(q,0,8)+"-"+A.i.an(q,8,12)+"-"+A.i.an(q,12,16)+"-"+A.i.an(q,16,20)+"-"+A.i.eu(q,20)},
$ifD:1}
B.l9.prototype={
$1(a){return A.i.b7(A.a.h0(B.r(a),16),2,"0")},
$S:54}
B.bF.prototype={
I(a,b){var s=this.a
if(s==="en")return a
if(s==="nl")return b
s=B.ty(a,s)
return s==null?a:s},
fc(a){var s,r=this.a
if(r==="en")return a.b
if(r==="nl")return a.c
s=A.LA.h(0,a.a)
if(s==null)r=null
else{r=s.h(0,r)
r=r==null?null:r[0]}return r==null?a.b:r},
fT(a){var s,r=this,q="Hatchling",p="Wyrmling",o="Ascended"
A:{if("moonEgg"===a){s=r.I("Egg","Ei")
break A}if("spark"===a){s=r.I(q,q)
break A}if("nestDragon"===a){s=r.I(p,p)
break A}s=r.I(o,o)
break A}return s}}
B.lV.prototype={
$2(a,b){var s=a.a4(this.a)
if(s==null)s=null
else{s=s.b
if(!(b<s.length))return B.b(s,b)
s=s[b]}return s},
$1(a){return this.$2(a,1)},
$S:56}
B.bC.prototype={}
B.lX.prototype={
$1(a){var s=A.i.b7(A.a.v(a+1),3,"0")
A.a.G(a,20)
A.a.D(a,20)
return new B.bC("title_"+s)},
$S:70}
B.cH.prototype={
B(){return"AchievementCategory."+this.b}}
B.Q.prototype={}
B.bP.prototype={
B(){return"ActivityType."+this.b}}
B.az.prototype={
B(){return"ActivityCode."+this.b}}
B.b3.prototype={
H(){var s=this
return B.V(["id",s.a,"message",s.b,"createdAt",s.c.K(),"type",s.d.b,"code",s.e.b,"subject",s.f,"xp",s.r,"coins",s.w,"gems",s.x],t.N,t.z)}}
B.bp.prototype={
B(){return"AdventureKind."+this.b}}
B.bq.prototype={
B(){return"AdventureRunStatus."+this.b}}
B.aG.prototype={}
B.dS.prototype={}
B.aA.prototype={}
B.m_.prototype={
$1(a){return t.x.a(a).aL(this.a.x)},
$S:93}
B.m0.prototype={
$2(a,b){return B.r(a)+B.r(b)},
$S:15}
B.m1.prototype={
$2(a,b){B.r(a)
t.x.a(b)
return a+b.aL(A.a9)+b.aL(A.a5)+b.aL(A.a3)},
$S:27}
B.b4.prototype={
H(){var s=this,r=s.d.K(),q=s.e.K(),p=s.r
p=p==null?null:p.b
return B.V(["id",s.a,"adventureId",s.b,"dragonId",s.c,"startedAt",r,"endsAt",q,"status",s.f.b,"rewardTier",p,"participantCount",s.w,"specialEventId",s.x,"specialEventKey",s.y],t.N,t.z)}}
B.hj.prototype={
$1(a){return t.dm.a(a).b===this.a.h(0,"status")},
$S:57}
B.hk.prototype={
$0(){return A.as},
$S:58}
B.hl.prototype={
$1(a){var s,r
t.ca.a(a)
s=a==null?null:a.b
r=this.a.h(0,"rewardTier")
return s==null?r==null:s===r},
$S:59}
B.hm.prototype={
$0(){return null},
$S:2}
B.cx.prototype={}
B.ca.prototype={}
B.c9.prototype={}
B.c8.prototype={}
B.hg.prototype={
$1(a){var s,r=A.a.D(a,14),q=A.a.D(a,15),p=A.cr[q],o=A.a.D(a*11,20),n=A.aQ[o]
q=A.co[q]
o=A.aP[o]
r=B.ah(0,0,0,0,2+r,0)
s=A.a.D(a,8)
return B.eT("A tiny tower outing with a modest wooden reward.","Een klein torenuitstapje met een bescheiden houten beloning.",r,A.K[A.a.D(a,3)],"mini_"+(a+1),A.q,A.F,A.aJ,!1,1+A.a.D(a,2),p+" near the "+n,q+" bij "+o,4+s)},
$S:11}
B.hh.prototype={
$1(a){var s,r,q,p=A.a.t(2+A.a.D(a,5),3,6),o=A.a.D(a,15),n=A.cr[o],m=A.a.D(a,20),l=A.aQ[m]
o=A.co[o]
m=A.aP[m]
s=B.ah(0,p,0,0,0,0)
r=A.a.D(a,13)
q=A.a.D(a,3)
return B.eT("A focused expedition with one curious detour.","Een gerichte expeditie met \xe9\xe9n nieuwsgierige omweg.",s,A.K[q],"short_"+(a+1),A.o,null,A.aJ,!1,4+p+q,n+" the "+l,o+" "+m,35+p*18+r)},
$S:11}
B.hf.prototype={
$1(a){var s,r,q=3+A.a.D(a,4),p=a+1,o=A.a.D(a*7,20),n=A.aQ[o]
o=A.aP[o]
s=B.ah(q,0,0,0,0,0)
r=A.a.D(a,41)
return B.eT("A careful multi-day journey through changing skies.","Een zorgvuldige meerdaagse reis door veranderende hemels.",s,A.K[p%3],"long_"+p,A.z,null,A.aJ,!1,35+q*11+A.a.D(a,7),n+" Expedition",o+"-expeditie",260+q*150+r)},
$S:11}
B.he.prototype={
$1(a){var s,r,q,p,o=A.a.D(a,4),n=3+o,m=A.a.D(a,3),l=A.K[(a+2)%3],k=A.a.D(a*3,20),j=A.aQ[k]
k=A.aP[k]
s=""+(2+m)
r=B.ah(n,0,0,0,0,0)
q=A.a.D(a,59)
p=A.a.D(a,9)
if(o===0)A.a.D(a,20)
if(m===0)A.a.D(a,150)
return B.eT("A cooperative discovery for "+s+" dragon keepers.","Een gezamenlijke ontdekking voor "+s+" drakenhoeders.",r,l,"group_"+(a+1),A.W,null,new B.dS(),!1,52+n*13+p,"Concord of "+j,"Verbond van "+k,360+n*175+q)},
$S:11}
B.hi.prototype={
$1(a){var s=a>=90,r=8+A.a.D(a*7,113),q=s?"The Crooked Shadow":"A Strange Invitation",p=s?"De Kromme Schaduw":"Een Vreemde Uitnodiging",o=s?"A released dragon left a dangerous-looking map. Following it is optional.":"A one-off trail with a fully known reward.",n=s?"Een vrijgelaten draak liet een gevaarlijk ogende kaart achter. Volgen is optioneel.":"Een eenmalig spoor met een volledig bekende beloning.",m=B.ah(0,r,0,0,0,0),l=A.K[A.a.D(a,3)],k=A.a.G(r,4),j=s?A.a4:A.ax[A.a.D(a,5)]
return B.eT(o,n,m,l,"special_"+(a+1),A.A,j,A.aJ,s,25+k,q,p,180+r*5)},
$S:11}
B.fe.prototype={
B(){return"HavenMusicStyle."+this.b}}
B.av.prototype={
B(){return"ChestTier."+this.b}}
B.bD.prototype={}
B.dU.prototype={}
B.bG.prototype={
B(){return"HavenDayPhase."+this.b}}
B.ao.prototype={
gef(){if(this.Q==null){var s=this.b
s=B.ci(s).cx&&s!=="sinisterra"}else s=!0
return s},
H(){var s=this,r=s.e,q=s.y
return B.V(["id",s.a,"lineageId",s.b,"acquiredAt",s.c.K(),"hatchSeed",s.d,"prismatic",r,"sex",s.f.b,"spectral",r,"lawAxis",s.r.b,"moralAxis",s.w.b,"sizeFactor",s.x,"incubationMinutes",A.a.G(q+59,60),"incubationSeconds",q,"sinister",s.z,"specialEggId",s.Q,"moralAxisKnown",s.as,"xp",s.at,"altarKnowledge",s.ax.H()],t.N,t.z)}}
B.ht.prototype={
$1(a){return t.Y.a(a).a===this.a},
$S:12}
B.bV.prototype={
B(){return"DragonEmoteSource."+this.b}}
B.h.prototype={}
B.dk.prototype={
gft(){var s=t.mA
s=B.k(new B.j(A.bj,t.bo.a(new B.hu(this)),s),s.i("a.E"))
s.$flags=1
return s}}
B.hu.prototype={
$1(a){return t.F.a(a).e===this.a.r},
$S:19}
B.lZ.prototype={
$1(a){return t.F.a(a).e===this.a},
$S:19}
B.bb.prototype={
B(){return"DragonTrait."+this.b}}
B.bE.prototype={
B(){return"DragonRarity."+this.b}}
B.x.prototype={}
B.mg.prototype={
$1(a){return!t.Y.a(a).cx},
$S:12}
B.dZ.prototype={
B(){return"DragonSex."+this.b}}
B.b5.prototype={
B(){return"AltarRelic."+this.b}}
B.bg.prototype={
H(){return B.V(["fragments",this.a,"essence",this.b,"hearts",this.c],t.N,t.z)}}
B.aP.prototype={
fN(a){var s,r=this
switch(a.a){case 0:s=r.c
break
case 1:s=r.d
break
case 2:s=r.e
break
case 3:s=r.f
break
case 4:s=!1
break
default:s=null}return s},
aJ(a){var s,r,q,p=this,o=a.b,n=p.b
if(o>n)s=a.a
else if(o===n)s=p.a||a.a
else s=p.a
o=Math.max(n,o)
n=p.c||a.c
r=p.d||a.d
q=p.e||a.e
return new B.aP(s,o,n,r,q,p.f||a.f)},
H(){var s=this
return B.V(["tagged",s.a,"tagRevision",s.b,"moral",s.c,"order",s.d,"rarity",s.e,"lineage",s.f],t.N,t.z)}}
B.f9.prototype={
bx(a){var s=this.f.h(0,a.b)
return s==null?0:s},
H(){var s=this,r=s.b,q=s.c.H(),p=s.d,o=s.e,n=t.N,m=s.r.aX(0,new B.iM(),n,t.P),l=s.w
l=B.k(l,B.e(l).c)
return B.V(["ownerId",s.a,"revision",r,"wallet",q,"misses",p,"totalReturned",o,"crafted",s.f,"eggs",m,"returnedIds",l,"names",s.x,"operations",s.y],n,t.z)}}
B.iM.prototype={
$2(a,b){return new B.P(B.M(a),t.es.a(b).H(),t.fH)},
$S:68}
B.iI.prototype={
$2(a,b){var s=J.au(a),r=typeof b=="number"?Math.max(0,A.c.k(b)):0
return new B.P(s,r,t.jA)},
$S:67}
B.iJ.prototype={
$2(a,b){return new B.P(J.au(a),B.cI(B.aw(t.f.a(b),t.N,t.z)),t.k2)},
$S:75}
B.iK.prototype={
$2(a,b){return new B.P(J.au(a),J.au(b),t.gc)},
$S:79}
B.iL.prototype={
$2(a,b){return new B.P(J.au(a),B.aw(t.f.a(b),t.N,t.z),t.fH)},
$S:80}
B.aE.prototype={
v(a){return this.a}}
B.bY.prototype={
B(){return"GamePresentationType."+this.b}}
B.aQ.prototype={
H(){var s=this
return B.V(["id",s.a,"type",s.b.b,"createdAt",s.c.K(),"sortAt",s.d.K(),"dragonId",s.e,"achievementId",s.f,"previousStageKey",s.r,"payload",s.w],t.N,t.z)}}
B.bk.prototype={}
B.bH.prototype={
H(){var s=this
return B.V(["itemId",s.a,"roomId",s.b,"x",s.c,"y",s.d,"scale",s.e],t.N,t.z)}}
B.l.prototype={}
B.aS.prototype={
B(){return"MysticRelic."+this.b}}
B.a8.prototype={
B(){return"HavenNotificationCategory."+this.b}}
B.bX.prototype={
B(){return"DragonStage."+this.b}}
B.aq.prototype={
B(){return"TrainingFocus."+this.b}}
B.bW.prototype={
B(){return"DragonSchoolOutcome."+this.b}}
B.cq.prototype={
B(){return"LawAxis."+this.b}}
B.cs.prototype={
B(){return"MoralAxis."+this.b}}
B.Y.prototype={
gdm(){var s=this.x
return s==null?B.iH(this.RG):s},
gU(){var s,r,q,p=this
if(p.f===A.h){s=p.rx
r=s==="sinisterra"
if(r)s="Sinister Egg"
else{q=!1
if(B.ci(s).cx)s=!(p.f===A.h&&r)
else s=q
s=s?"Special Egg":"Mysterious Egg"}}else{s=A.i.a9(p.b)
if(s.length===0)s=B.ci(p.rx).b}return s},
gdn(){switch(this.f.a){case 0:var s="moonEgg"
break
case 1:s="spark"
break
case 2:s="nestDragon"
break
case 3:s="homeGuardian"
break
default:s=null}return s},
aL(a){var s=this.k4.h(0,t.U.a(a).b)
return s==null?0:s},
dl(a){var s=this.p3.h(0,a)
return s==null?0:s},
ge5(){return A.am.aI(0,0,new B.l0(this),t.S)},
gfn(){return A.a.t(A.am.aI(0,0,new B.l_(this),t.S),0,30)},
gfC(){return A.am.aO(0,new B.l1(this))},
gd0(){var s,r,q=this
if(q.gfn()<30)s=q.p4&&q.gfC()&&q.ge5()>=15
else s=!0
if(!s)return A.bS
r=q.ge5()
A:{if(r>=30){s=A.b9
break A}if(r>=27){s=A.bV
break A}if(r>=21){s=A.bU
break A}if(r>=15){s=A.bT
break A}s=A.b8
break A}return s},
gen(){return A.b.aI(A.K,0,new B.l3(this),t.S)},
gfD(){var s,r
if(this.f!==A.a7)return!1
s=t.f0
r=B.k(new B.K(A.K,t.hT.a(this.gh1()),s),s.i("a4.E"))
return B.dw(r,B.q(r).c).a===1},
gbm(){if(this.gen()===0)return"unknown"
var s=B.m(A.K.slice(0),t.mU)
A.b.b_(s,new B.l2(this))
return A.b.gM(s).b},
e_(a){var s=this.k2
return a.ac(s)?a.au(s):A.ba},
d_(a){var s,r=this,q=r.f
A:{if(A.aj===q){s=r.c>=350
break A}if(A.a7===q){s=r.c>=1950&&r.gen()>=300
break A}s=!1
break A}return s},
ff(a){var s,r,q,p=this
if(p.f===A.h||!a.ac(p.k3))return!1
s=p.k3
r=A.a.G(A.a.G(a.au(s).a,36e8),8)
if(r<=0)return!1
q=r*2
p.fy=Math.max(25,p.fy-q)
p.go=Math.max(20,p.go-q)
p.id=Math.max(30,p.id-r)
p.k3=s.P(B.ah(0,r*8,0,0,0,0).a)
return!0},
dZ(a,b){var s,r,q=this
if(b<=0)return
s=q.f
r=B.ox(q.ry,a,q.z,s)
q.k4.aq(a.b,new B.kY(b,r),new B.kZ(b,r))},
dO(){var s,r,q,p,o,n=this.cy
if(n.length!==0)return
s=new B.fW()
s.eB((this.RG^5904329)>>>0)
r=s.S()<0.25?2:1
while(n.length<r){q=s.C(24)
if(!(q>=0&&q<24))return B.b(A.bl,q)
p=A.bl[q]
if(A.b.p(n,p))continue
o=A.Me.h(0,p)
if(o!=null&&A.b.p(n,o))continue
A.b.n(n,p)}},
H(){var s,r,q,p=this,o=p.b,n=p.c,m=p.d,l=p.e,k=p.f,j=p.w,i=p.gdm(),h=B.m([],t.s)
for(s=p.y,r=0;r<3;++r){q=A.K[r]
if(s.p(0,q))h.push(q.b)}s=p.cx
return B.V(["id",p.a,"name",o,"xp",n,"coins",m,"gems",l,"stage",k.b,"firstEgg",p.r,"prismatic",j,"sex",i.b,"highlightedExpertises",h,"spectral",p.w,"sinister",p.z,"lawAxis",p.Q.b,"moralAxis",p.as.b,"lawAxisKnown",p.at,"altarKnowledge",p.ax.H(),"moralAxisKnown",p.ay,"personalityKnown",p.ch,"sizeFactor",p.CW,"incubationMinutes",A.a.G(s+59,60),"incubationSeconds",s,"personalityTraitIds",p.cy,"favorite",p.db,"roamsTower",p.dx,"currentRoomId",p.dy,"currentFloorIndex",p.fr,"activeAdventureId",p.fx,"joy",p.fy,"energy",p.go,"comfort",p.id,"acquiredAt",p.k1.K(),"stageStartedAt",p.k2.K(),"needsUpdatedAt",p.k3.K(),"training",p.k4,"trialHighScores",p.ok,"dragonSchoolRecords",p.p1,"dragonSchoolStars",p.p2,"dragonSchoolAttempts",p.p3,"dragonSchoolFinalizedEarly",p.p4,"dragonSchoolMentorLessons",p.R8,"hatchSeed",p.RG,"lineageId",p.rx,"evolutionPath",p.ry],t.N,t.z)},
sfM(a){this.fy=B.r(a)},
sfv(a){this.go=B.r(a)},
sfi(a){this.id=B.r(a)}}
B.l0.prototype={
$2(a,b){var s
B.r(a)
s=this.a.p2.h(0,B.M(b))
return a+A.a.t(s==null?0:s,0,3)},
$S:29}
B.l_.prototype={
$2(a,b){return B.r(a)+A.a.t(this.a.dl(B.M(b)),0,3)},
$S:29}
B.l1.prototype={
$1(a){return this.a.dl(B.M(a))>0},
$S:6}
B.l3.prototype={
$2(a,b){return B.r(a)+this.a.aL(t.U.a(b))},
$S:46}
B.l2.prototype={
$2(a,b){var s,r=t.U
r.a(a)
r.a(b)
r=this.a
s=A.a.Z(r.aL(b),r.aL(a))
if(s!==0)return s
r=r.RG
return A.a.Z((r+a.a*97)%997,(r+b.a*97)%997)},
$S:47}
B.kY.prototype={
$1(a){return A.a.k(A.a.t(B.r(a)+this.a,0,this.b))},
$S:3}
B.kZ.prototype={
$0(){return A.a.k(A.a.t(this.a,0,this.b))},
$S:4}
B.kX.prototype={
$1(a){return t.Y.a(a).a===this.a},
$S:12}
B.c2.prototype={
B(){return"PortraitRarity."+this.b}}
B.c3.prototype={}
B.me.prototype={
$1(a){var s,r=a+1
A:{if(r<=88){s=A.cy
break A}if(r<=93){s=A.OD
break A}if(r<=96){s=A.OE
break A}if(r<=98){s=A.cz
break A}if(99===r){s=A.OF
break A}s=A.OG
break A}return new B.c3("portrait_"+A.i.b7(A.a.v(r),3,"0"),s)},
$S:50}
B.fE.prototype={
B(){return"RedeemRewardType."+this.b}}
B.c5.prototype={}
B.bZ.prototype={
B(){return"ItemSlot."+this.b}}
B.dr.prototype={
B(){return"ItemRarity."+this.b}}
B.e6.prototype={
B(){return"ItemCurrency."+this.b}}
B.co.prototype={
B(){return"FurnitureLightType."+this.b}}
B.e3.prototype={
B(){return"FurnitureNightActivation."+this.b}}
B.ap.prototype={}
B.a7.prototype={}
B.bm.prototype={}
B.bJ.prototype={}
B.al.prototype={
B(){return"TrialKind."+this.b}}
B.cc.prototype={
B(){return"TrialGrade."+this.b}}
B.bw.prototype={}
B.aZ.prototype={
H(){var s=this,r=s.c.K(),q=s.e
q=q==null?null:q.K()
return B.V(["id",s.a,"kind",s.b.b,"appearedAt",r,"specialEventKey",s.d,"startedAt",q],t.N,t.z)}}
B.lc.prototype={
$1(a){return t.gq.a(a).b===this.a.h(0,"kind")},
$S:51}
B.ld.prototype={
$0(){return A.ag},
$S:52}
B.aD.prototype={
B(){return"_ReturnOutcome."+this.b}}
B.bQ.prototype={
B(){return"AdventureStartResult."+this.b}}
B.cy.prototype={
B(){return"TowerBuildResult."+this.b}}
B.ak.prototype={}
B.mc.prototype={
$2(a,b){var s=t.W
return s.a(a).c.Z(0,s.a(b).c)},
$S:45}
B.md.prototype={
$1(a){return t.W.a(a).c.ac(this.a)},
$S:30}
B.hv.prototype={
$2(a,b){B.M(a)
return!t.h.a(b).ac(this.a)},
$S:24}
B.ih.prototype={
$1(a){return t.x.a(a).f!==A.h},
$S:0}
B.ij.prototype={
$1(a){var s,r
t.x.a(a)
s=this.a
r=s.bf.h(0,a.a)
return(r==null?null:r.ac(s.b.$0()))===!0},
$S:0}
B.ii.prototype={
$1(a){return t.x.a(a).dx},
$S:0}
B.it.prototype={
$1(a){var s=this.a,r=B.q(s)
return new B.j(s,r.i("i(1)").a(new B.is(this.b,B.r(a))),r.i("j<1>")).gm(0)<3},
$S:5}
B.is.prototype={
$1(a){t.x.a(a)
return a.a!==this.a.a&&a.fr===this.b},
$S:0}
B.iu.prototype={
$1(a){var s
B.r(a)
s=this.a.L
if(!(a>=0&&a<s.length))return B.b(s,a)
return s[a]===this.b.ay},
$S:5}
B.iv.prototype={
$1(a){var s
B.r(a)
s=this.a.L
if(!(a>=0&&a<s.length))return B.b(s,a)
return s[a]===this.b.ay},
$S:5}
B.iw.prototype={
$1(a){var s
B.r(a)
s=this.b.L
if(!(a>=0&&a<s.length))return B.b(s,a)
return A.b.p(this.a.ch,s[a])},
$S:5}
B.ix.prototype={
$1(a){return!A.b.p(this.a,B.r(a))},
$S:5}
B.hX.prototype={
$0(){return B.m([],t.s)},
$S:33}
B.hY.prototype={
$1(a){var s
B.M(a)
s=$.b2().h(0,a)
s=s==null?null:s.b
return s!==this.a||A.b.N(this.b.a3,new B.hW(a))},
$S:6}
B.hW.prototype={
$1(a){return t.k.a(a).b===this.a},
$S:10}
B.hZ.prototype={
$1(a){B.M(a)
return $.b2().h(0,a)},
$S:60}
B.iF.prototype={
$0(){return B.m([],t.s)},
$S:33}
B.iG.prototype={
$1(a){var s
t.G.a(a)
s=a.a
return!J.eR(this.a,s)&&s!==this.b&&!A.b.N(this.c.a3,new B.iE(a))},
$S:35}
B.iE.prototype={
$1(a){return t.k.a(a).b===this.a.a},
$S:10}
B.hV.prototype={
$2(a,b){var s
B.r(a)
s=t.x.a(b).ok.h(0,this.a.b)
if(s==null)s=0
return Math.max(a,s)},
$S:27}
B.hK.prototype={
$1(a){return t.W.a(a).b},
$S:36}
B.hL.prototype={
$1(a){t.e.a(a)
return A.cu.h(0,a.b).r!=null&&a.e==null&&!this.a.p(0,a.d)},
$S:21}
B.hM.prototype={
$1(a){return B.tz(t.W.a(a).a.cx)},
$S:64}
B.hN.prototype={
$1(a){var s
t.ga.a(a)
s=a==null?null:a.a.a
return s===this.a},
$S:65}
B.hO.prototype={
$0(){return null},
$S:2}
B.ig.prototype={
$1(a){return t.e.a(a).a===this.a},
$S:21}
B.ia.prototype={
$1(a){return B.r(a)+1},
$S:3}
B.ib.prototype={
$0(){return 1},
$S:4}
B.hI.prototype={
$1(a){var s
B.M(a)
s=B.a9(a)
return s!=null&&B.dq(s)===a},
$S:6}
B.iy.prototype={
$1(a){return t.G.a(a).a===this.a.a},
$S:35}
B.iz.prototype={
$1(a){var s
t.m.a(a)
s=a==null?null:a.a
return s===this.a},
$S:13}
B.iA.prototype={
$0(){return null},
$S:2}
B.iB.prototype={
$1(a){t.W.a(a)
return a.a.b===this.a.a&&!this.b.bA.p(0,a.b)},
$S:30}
B.id.prototype={
$1(a){return t.k.a(a).b===this.a.a},
$S:10}
B.i0.prototype={
$1(a){return t.k.a(a).a===this.a},
$S:10}
B.i1.prototype={
$1(a){var s
t.m.a(a)
s=a==null?null:a.a
return s===this.a.c},
$S:13}
B.i2.prototype={
$0(){return null},
$S:2}
B.i3.prototype={
$1(a){return B.r(a)+1},
$S:3}
B.i4.prototype={
$0(){return 1},
$S:4}
B.i5.prototype={
$1(a){return B.r(a)+1},
$S:3}
B.i6.prototype={
$0(){return 1},
$S:4}
B.i7.prototype={
$1(a){return B.r(a)+1},
$S:3}
B.i8.prototype={
$0(){return 1},
$S:4}
B.hS.prototype={
$1(a){return t.k.a(a).a===this.a},
$S:10}
B.hT.prototype={
$1(a){var s
t.m.a(a)
s=a==null?null:a.a
return s===this.a.c},
$S:13}
B.hU.prototype={
$0(){return null},
$S:2}
B.im.prototype={
$1(a){var s
t.m.a(a)
s=a==null?null:a.a
return s===this.a},
$S:13}
B.io.prototype={
$0(){return null},
$S:2}
B.ip.prototype={
$1(a){return t.x.a(a).a===this.a.a},
$S:0}
B.iq.prototype={
$1(a){return t.x.a(a).a===this.a.a},
$S:0}
B.hC.prototype={
$2(a,b){B.M(a)
return!t.h.a(b).ac(this.a)},
$S:24}
B.hD.prototype={
$1(a){return B.r(a)+1},
$S:3}
B.hE.prototype={
$0(){return 1},
$S:4}
B.hA.prototype={
$1(a){return t.x.a(a).db},
$S:0}
B.hB.prototype={
$2(a,b){var s=t.x
return s.a(a).k1.Z(0,s.a(b).k1)},
$S:22}
B.hQ.prototype={
$1(a){return t.x.a(a).dx},
$S:0}
B.hR.prototype={
$1(a){var s
t.x.a(a)
s=a.a
return s!==this.a&&!this.b.p(0,s)&&a.fr===this.c},
$S:0}
B.hy.prototype={
$1(a){var s,r
B.r(a)
s=this.a.L
if(!(a>=0&&a<s.length))return B.b(s,a)
r=s[a]
s=this.b.rx
return r===B.ci(s).ay||A.b.p(B.ci(s).ch,r)},
$S:5}
B.hz.prototype={
$2(a,b){var s
B.r(a)
B.r(b)
s=this.a
return A.a.Z(B.mu(s,a,null),B.mu(s,b,null))},
$S:15}
B.hG.prototype={
$2(a,b){var s=t.x
s.a(a)
s.a(b)
s=a.db
if(s!==b.db)return s?-1:1
return a.k1.Z(0,b.k1)},
$S:22}
B.hH.prototype={
$1(a){var s
B.r(a)
if(!this.a.aj.p(0,a)){s=this.b.h(0,a)
s=(s==null?0:s)<3}else s=!1
return s},
$S:5}
B.hw.prototype={
$1(a){B.r(a)
return!this.a.aj.p(0,a)},
$S:5}
B.hx.prototype={
$2(a,b){var s,r,q
B.r(a)
B.r(b)
s=this.a
r=s.L
if(!(a>=0&&a<r.length))return B.b(r,a)
r=r[a]
q=$.dd()
r=q.h(0,r)
r=r==null?null:r.c
if(r==null)r=0
s=s.L
if(!(b>=0&&b<s.length))return B.b(s,b)
s=q.h(0,s[b])
s=s==null?null:s.c
return r>=(s==null?0:s)?a:b},
$S:15}
B.iW.prototype={
$1(a){return t.R.a(a).a===this.a},
$S:8}
B.iX.prototype={
$1(a){return t.x.a(a).a===this.a},
$S:0}
B.j1.prototype={
$1(a){return t.R.a(a).a===this.a},
$S:8}
B.iU.prototype={
$1(a){return B.mr(t.R.a(a).H())},
$S:69}
B.iP.prototype={
$1(a){return t.R.a(a).a===this.a},
$S:8}
B.iQ.prototype={
$1(a){return t.R.a(a).a===this.a},
$S:8}
B.iR.prototype={
$1(a){return t.p.a(a).b===this.a.h(0,"relic")},
$S:39}
B.iS.prototype={
$1(a){return t.p.a(a).b===this.a.h(0,"relic")},
$S:39}
B.iT.prototype={
$1(a){return t.R.a(a).a===this.a},
$S:8}
B.iN.prototype={
$1(a){t.R.a(a)
return this.a.p3.w.p(0,a.a)},
$S:8}
B.iO.prototype={
$1(a){return t.R.a(a).a},
$S:71}
B.c4.prototype={
B(){return"PurchaseResult."+this.b}}
B.ct.prototype={
B(){return"MysticRelicUseResult."+this.b}}
B.cV.prototype={
B(){return"MysticRelicPurchaseResult."+this.b}}
B.ck.prototype={
B(){return"AstralLensUseResult."+this.b}}
B.cL.prototype={
B(){return"ChronoshardUseResult."+this.b}}
B.cf.prototype={
B(){return"WayfinderSigilUseResult."+this.b}}
B.cX.prototype={
B(){return"PortraitChestPurchaseResult."+this.b}}
B.d1.prototype={
B(){return"TitleChestPurchaseResult."+this.b}}
B.cU.prototype={
B(){return"MusicChestPurchaseResult."+this.b}}
B.cv.prototype={
B(){return"RoomUnlockResult."+this.b}}
B.jm.prototype={
f3(f7){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,c0,c1,c2,c3,c4,c5,c6,c7,c8=this,c9=null,d0="pendingAltarOperation",d1="onboardingComplete",d2="musicEnabled",d3="enabledMusicTrackIds",d4="jukeboxShuffle",d5="jukeboxRepeat",d6="soundEffectsEnabled",d7="achievementsCompact",d8="myDragonsViewMode",d9="myDragonsSortMode",e0="acquiredAt",e1="myDragonsSortDescending",e2="eggInventoryViewMode",e3="eggInventorySortMode",e4="eggInventorySortDescending",e5="tutorialCompleted",e6="tutorialFullyViewed",e7=2147483647,e8="chronoshardReductions",e9="supporterPackOwned",f0="selectedBadgeId",f1="selectedFrameId",f2="dragon_school_dropout",f3="trialStreakRewardReady",f4="nest",f5="frame_supporter_founder",f6="badge_supporter_founder"
t.P.a(f7)
s=t.d.a(f7.h(0,"eggAltar"))
if(s==null){s=t.z
s=B.n(s,s)}r=t.N
q=t.z
c8.p3=B.nD(B.aw(s,r,q))
s=t.f
c8.x1=s.b(f7.h(0,d0))?B.aw(s.a(f7.h(0,d0)),r,q):c9
p=f7.h(0,"languageCode")
p=typeof p=="string"?p:c9
if(A.QT.p(0,p)){p.toString
s=p}else s="en"
c8.z=s
s=f7.h(0,"accountName")
s=typeof s=="string"?s:c9
s=s==null?c9:A.i.a9(s)
c8.Q=s==null?"":s
c8.as=!B.a5(f7.h(0,d1))||B.ab(f7.h(0,d1))
c8.at=!B.a5(f7.h(0,d2))||B.ab(f7.h(0,d2))
c8.ax=A.cd
s=B.am(f7.h(0,"ownedMusicTrackIds"))
q=B.e(s)
o=q.i("j<1>")
o=c8.ay=B.a3(new B.j(s,q.i("i(1)").a($.p1().gai()),o),o.i("a.E"))
if(o.a===0)o.n(0,"reverie")
if(f7.J(d3)){s=B.am(f7.h(0,d3))
q=c8.ay
o=B.e(s)
n=o.i("j<1>")
n=B.a3(new B.j(s,o.i("i(1)").a(q.gbw(q)),n),n.i("a.E"))
s=n}else s=B.dv(["reverie"],r)
c8.ch=s
c8.CW=B.a5(f7.h(0,d4))&&B.ab(f7.h(0,d4))
c8.cx=!B.a5(f7.h(0,d5))||B.ab(f7.h(0,d5))
s=B.am(f7.h(0,"disabledSeasonalMusicTrackIds"))
q=B.e(s)
o=q.i("j<1>")
c8.cy=B.a3(new B.j(s,q.i("i(1)").a($.p3().gai()),o),o.i("a.E"))
c8.db=!B.a5(f7.h(0,d6))||B.ab(f7.h(0,d6))
m=f7.h(0,"enabledNotificationCategories")
s=t.j
if(s.b(m)){q=J.bO(m,r)
o=q.$ti
n=t.fC
n=B.a3(new B.b_(B.bt(q,o.i("a8?(a.E)").a(new B.jD()),o.i("a.E"),t.nB),n),n.i("a.E"))
q=n}else q=B.dw(A.bi,t.eE)
c8.dx=q
q=B.dI(f7.h(0,"notificationSettingsVersion"))
l=q==null?c9:A.c.k(q)
if(l==null)l=0
if(l<2)c8.dx.n(0,A.bd)
if(l<3)c8.dx.n(0,A.ce)
c8.dy=B.a5(f7.h(0,d7))&&B.ab(f7.h(0,d7))
q=f7.h(0,d8)
if(A.QW.p(0,typeof q=="string"?q:c9)){q=f7.h(0,d8)
q=typeof q=="string"?q:c9
q.toString}else q="gallery"
c8.fr=q
q=f7.h(0,d9)
if(A.QL.p(0,typeof q=="string"?q:c9)){q=f7.h(0,d9)
q=typeof q=="string"?q:c9
q.toString}else q=e0
c8.fx=q
c8.fy=!B.a5(f7.h(0,e1))||B.ab(f7.h(0,e1))
q=f7.h(0,e2)
if(A.QK.p(0,typeof q=="string"?q:c9)){q=f7.h(0,e2)
q=typeof q=="string"?q:c9
q.toString}else q="tiles"
c8.go=q
q=f7.h(0,e3)
if(A.QN.p(0,typeof q=="string"?q:c9)){q=f7.h(0,e3)
q=typeof q=="string"?q:c9
q.toString}else q=e0
c8.id=q
c8.k1=!B.a5(f7.h(0,e4))||B.ab(f7.h(0,e4))
c8.ok=B.mQ(B.an(f7.h(0,"pet")))
c8.k2=B.a5(f7.h(0,e5))?B.ab(f7.h(0,e5)):c8.ok.f!==A.h
c8.k3=B.a5(f7.h(0,e6))&&B.ab(f7.h(0,e6))
k=B.an(f7.h(0,"incubatingEgg"))
q=k.a===0?c9:B.mQ(k)
c8.p1=q
if((q==null?c9:q.f===A.h)!==!0)c8.p1=null
q=B.cE(f7.h(0,"eggStash"))
o=q.$ti
o=B.bt(q,o.i("ao(a.E)").a(B.t6()),o.i("a.E"),t.R)
q=B.k(o,B.e(o).i("a.E"))
c8.p2=q
q=B.a1(r)
o=c8.ok
if(o.f===A.h)q.n(0,o.a)
o=c8.p1
if((o==null?c9:o.f===A.h)===!0)q.n(0,o.a)
for(o=c8.p2,n=o.length,j=0;j<o.length;o.length===n||(0,B.Z)(o),++j)q.n(0,o[j].a)
o=B.am(f7.h(0,"eggRarityRevealedIds"))
n=B.e(o)
i=n.i("j<1>")
c8.aT=B.a3(new B.j(o,n.i("i(1)").a(q.gbw(q)),i),i.i("a.E"))
i=B.cE(f7.h(0,"sanctuaryDragons"))
q=t.x
n=i.$ti
n=B.bt(i,n.i("Y(a.E)").a(B.oD()),n.i("a.E"),q)
i=B.e(n)
o=i.i("j<a.E>")
o=B.k(new B.j(n,i.i("i(a.E)").a(new B.jE()),o),o.i("a.E"))
c8.x2=o
n=c8.ok
if(n.f===A.h&&!n.r&&o.length!==0){c8.p1=n
h=A.b.b8(o,0)
o=c8.ok
h.d=o.d
h.e=o.e
o=c8.p1
o.e=o.d=0
c8.ok=h
o=h}else o=n
if(o.f===A.h&&o.r)c8.p1=null
g=B.an(f7.h(0,"chestInventory"))
o=t.S
n=B.n(t.mW,o)
for(j=0;j<10;++j){f=A.ax[j]
i=g.h(0,f.b)
if(i==null)A:{if(A.F===f){i=g.h(0,"woodland")
break A}if(A.M===f){i=g.h(0,"moonsteel")
break A}if(A.t===f){i=g.h(0,"celestial")
break A}i=c9
break A}n.j(0,f,A.a.k(A.a.t(typeof i=="number"?A.c.k(i):0,0,e7)))}c8.xr=n
n=B.n(r,o)
for(i=B.an(f7.h(0,"specialChestInventory")),i=new B.y(i,B.e(i).i("y<1,2>")).gq(0);i.l();){e=i.d
d=e.a
if(A.bo.J(d)){c=e.b
c=A.a.k(A.a.t(typeof c=="number"?A.c.k(c):0,0,e7))>0}else c=!1
if(c){c=e.b
n.j(0,d,A.a.k(A.a.t(typeof c=="number"?A.c.k(c):0,0,e7)))}}c8.y1=n
b=c8.xr.h(0,A.l)
if(b==null)b=0
if(b>0&&c8.y1.a===0){c8.y1.j(0,"golden_wings_chest_v1",b)
c8.xr.j(0,A.l,0)}a=B.an(f7.h(0,"relicInventory"))
n=t._
i=B.n(n,o)
for(j=0;j<7;++j){a0=A.ae[j]
d=a.h(0,a0.b)
i.j(0,a0,A.a.k(A.a.t(typeof d=="number"?A.c.k(d):0,0,e7)))}c8.y2=i
a1=B.an(f7.h(0,"untradeableRelicInventory"))
n=B.n(n,o)
for(j=0;j<7;++j){a0=A.ae[j]
i=c8.y2.h(0,a0)
if(i==null)i=0
d=a1.h(0,a0.b)
n.j(0,a0,Math.min(i,A.a.k(A.a.t(typeof d=="number"?A.c.k(d):0,0,e7))))}c8.aS=n
n=J.F(f7.h(0,"twinstarBroochEverObtained"),!0)||c8.aY(A.x)>0
c8.bC=n
i=c8.y2
if(n){i.j(0,A.x,1)
c8.aS.j(0,A.x,1)
a2=f7.h(0,"twinstarBroochDragonId")
a2=typeof a2=="string"?a2:c9
c8.aF=A.b.N(B.aH(c8),new B.jF(a2))?a2:c9}else{i.j(0,A.x,0)
c8.aS.j(0,A.x,0)
c8.aF=null}s=s.b(f7.h(0,e8))?s.a(f7.h(0,e8)):A.cl
n=t.cZ
s=J.bO(s,n)
i=s.$ti
i=B.bt(s,i.i("c(a.E)").a(new B.jQ()),i.i("a.E"),o)
i=B.b8(i,c8.aY(A.a8),B.e(i).i("a.E"))
a3=B.k(i,B.e(i).i("a.E"))
s=c8.a
for(;;){i=a3.length
d=c8.y2.h(0,A.a8)
if(!(i<(d==null?0:d)))break
A.b.n(a3,10+s.C(81))}c8.bi=a3
i=B.am(f7.h(0,"ownedPortraitIds"))
d=B.e(i)
c=d.i("j<1>")
c8.aE=B.a3(new B.j(i,d.i("i(1)").a(new B.jT()),c),c.i("a.E"))
a4=f7.h(0,"selectedPortraitId")
a4=typeof a4=="string"?a4:c9
i=c8.aE.p(0,a4)?a4:c9
c8.c3=i
d=c8.aE
if(d.a===0){i=$.dQ()
d=B.q(i)
c=d.i("j<1>")
i=B.k(new B.j(i,d.i("i(1)").a(new B.jU()),c),c.i("a.E"))
i.$flags=1
a5=i
i=a5.length
d=s.C(i)
if(!(d>=0&&d<i))return B.b(a5,d)
d=a5[d].a
c8.aE.n(0,d)
c8.c3=d}else if(i==null)c8.c3=d.gM(0)
i=B.am(f7.h(0,"ownedTitleIds"))
d=B.e(i)
c=d.i("j<1>")
c8.az=B.a3(new B.j(i,d.i("i(1)").a(new B.jV()),c),c.i("a.E"))
a6=f7.h(0,"selectedTitleId")
a6=typeof a6=="string"?a6:c9
i=c8.az.p(0,a6)?a6:c9
c8.c4=i
d=c8.az
if(d.a===0){i=$.dP()
d=i.length
s=s.C(d)
if(!(s>=0&&s<d))return B.b(i,s)
s=i[s].a
c8.az.n(0,s)
c8.c4=s}else if(i==null)c8.c4=d.gM(0)
c8.d2=B.a5(f7.h(0,e9))&&B.ab(f7.h(0,e9))
a7=f7.J(f0)
s=B.am(f7.h(0,"ownedBadgeIds"))
s.em(new B.K(A.cj,t.nq.a(new B.jW()),t.oM))
c8.c5=s
if(s.p(0,f7.h(0,f0))){s=f7.h(0,f0)
s=typeof s=="string"?s:c9}else s=c9
c8.d3=s
a8=f7.J(f1)
s=B.am(f7.h(0,"ownedFrameIds"))
s.em(B.dv([f5],t.X))
c8.d4=s
if(s.p(0,f7.h(0,f1))){s=f7.h(0,f1)
s=typeof s=="string"?s:c9}else s=c9
c8.d5=s
s=B.am(f7.h(0,"appliedVerifiedPurchaseIds"))
s=B.b8(s,100,B.e(s).c)
c8.e9=B.a3(s,B.e(s).i("a.E"))
s=B.am(f7.h(0,"ownedDragonEmoteIds"))
i=B.e(s)
d=i.i("j<1>")
c8.bB=B.a3(new B.j(s,i.i("i(1)").a($.p0().gai()),d),d.i("a.E"))
d=B.am(f7.h(0,"ownedDragonEmotePackIds"))
i=B.e(d)
s=i.i("j<1>")
s=c8.ea=B.a3(new B.j(d,i.i("i(1)").a(new B.jX()),s),s.i("a.E"))
for(s=B.lE(s,s.r,B.e(s).c),i=s.$ti.c;s.l();){d=s.d
if(d==null)d=i.a(d)
c=c8.bB
d=B.ow(d).gft()
a9=B.q(d)
c.A(0,new B.K(d,a9.i("d(1)").a(new B.jY()),a9.i("K<1,d>")))}c8.ap=B.am(f7.h(0,"discoveredForms"))
c8.bD=B.am(f7.h(0,"prismaticForms"))
c8.bj=B.am(f7.h(0,"achievements"))
s=t.A
i=B.n(r,s)
for(d=B.cE(f7.h(0,"pendingPresentations")),c=d.$ti,s=B.bt(d,c.i("aQ(a.E)").a(B.tb()),c.i("a.E"),s),c=B.e(s),s=new B.c1(J.at(s.a),s.b,c.i("c1<1,2>")),c=c.y[1];s.l();){d=s.a
if(d==null)d=c.a(d)
i.j(0,d.a,d)}s=i.$ti.i("ai<2>")
s=B.b8(new B.ai(i,s),100,s.i("a.E"))
s=B.k(s,B.e(s).i("a.E"))
c8.bk=s
s=f7.h(0,"totalHatched")
i=c8.ok.f===A.h?0:1
c8.c6=A.a.k(A.a.t(typeof s=="number"?A.c.k(s):i,0,e7))
s=f7.h(0,"totalNamed")
i=A.i.a9(c8.ok.b).length===0?0:1
c8.d6=A.a.k(A.a.t(typeof s=="number"?A.c.k(s):i,0,e7))
s=f7.h(0,"totalWyrmling")
i=c8.ok.f.a>=2?1:0
c8.c7=A.a.k(A.a.t(typeof s=="number"?A.c.k(s):i,0,e7))
s=f7.h(0,"totalAscended")
i=c8.ok.f===A.I?1:0
c8.c8=A.a.k(A.a.t(typeof s=="number"?A.c.k(s):i,0,e7))
s=f7.h(0,"totalChestsOpened")
c8.aU=A.a.k(A.a.t(typeof s=="number"?A.c.k(s):0,0,e7))
s=f7.h(0,"totalPortraitChestsOpened")
c8.c9=A.a.k(A.a.t(typeof s=="number"?A.c.k(s):0,0,e7))
s=f7.h(0,"totalTitleChestsOpened")
c8.ca=A.a.k(A.a.t(typeof s=="number"?A.c.k(s):0,0,e7))
s=f7.h(0,"totalMusicChestsOpened")
c8.d7=A.a.k(A.a.t(typeof s=="number"?A.c.k(s):0,0,e7))
s=f7.h(0,"totalAdventuresCompleted")
c8.cb=A.a.k(A.a.t(typeof s=="number"?A.c.k(s):0,0,e7))
s=f7.h(0,"totalShortAdventuresCompleted")
c8.cc=A.a.k(A.a.t(typeof s=="number"?A.c.k(s):0,0,e7))
s=f7.h(0,"totalGroupFourCompleted")
c8.cd=A.a.k(A.a.t(typeof s=="number"?A.c.k(s):0,0,e7))
s=f7.h(0,"totalReleasedReturns")
c8.ce=A.a.k(A.a.t(typeof s=="number"?A.c.k(s):0,0,e7))
s=f7.h(0,"totalSinisterAdventuresCompleted")
c8.cf=A.a.k(A.a.t(typeof s=="number"?A.c.k(s):0,0,e7))
s=f7.h(0,"favoriteChanges")
c8.cg=A.a.k(A.a.t(typeof s=="number"?A.c.k(s):0,0,e7))
s=B.am(f7.h(0,"appliedOnlineGroupRewardIds"))
s=B.b8(s,500,B.e(s).c)
c8.ec=B.a3(s,B.e(s).i("a.E"))
s=B.am(f7.h(0,"appliedOnlineTradeIds"))
s=B.b8(s,500,B.e(s).c)
c8.ed=B.a3(s,B.e(s).i("a.E"))
s=B.am(f7.h(0,"appliedOnlineSeasonalPairRewardIds"))
s=B.b8(s,100,B.e(s).c)
c8.ee=B.a3(s,B.e(s).i("a.E"))
c8.bE=B.am(f7.h(0,"reservedOnlineTradeEggIds"))
b0=B.an(f7.h(0,"reservedOnlineTradeChests"))
s=B.n(r,o)
for(i=new B.y(b0,B.e(b0).i("y<1,2>")).gq(0);i.l();){e=i.d
d=e.a
c=e.b
s.j(0,d,A.a.k(A.a.t(typeof c=="number"?A.c.k(c):0,0,e7)))}s.a1(0,new B.jZ())
c8.d8=s
b1=B.an(f7.h(0,"reservedOnlineTradeRelics"))
s=B.n(r,o)
for(i=new B.y(b1,B.e(b1).i("y<1,2>")).gq(0);i.l();){e=i.d
d=e.a
c=e.b
s.j(0,d,A.a.k(A.a.t(typeof c=="number"?A.c.k(c):0,0,e7)))}s.a1(0,new B.jG())
c8.ci=s
s=f7.h(0,"schemaVersion")
b2=A.a.k(A.a.t(typeof s=="number"?A.c.k(s):0,0,e7))
if(b2<32&&c8.cg===0)c8.bj.X(0,"not_picking_favorites")
if(b2<49&&c8.bj.p(0,f2)&&!A.b.N(c8.bk,new B.jH())){b3=c8.b.$0()
c8.bR(new B.aQ("achievement-dragon_school_dropout",A.aO,b3,b3,c9,f2,c9,A.ay))}s=B.cE(f7.h(0,"adventureRuns"))
i=s.$ti
i=B.bt(s,i.i("b4(a.E)").a(B.rU()),i.i("a.E"),t.k)
s=B.e(i)
d=s.i("j<a.E>")
s=B.k(new B.j(i,s.i("i(a.E)").a(new B.jI()),d),d.i("a.E"))
c8.a3=s
s=B.cE(f7.h(0,"trialOffers"))
i=s.$ti
i=B.bt(s,i.i("aZ(a.E)").a(B.tA()),i.i("a.E"),t.e)
s=B.e(i)
d=s.i("j<a.E>")
d=B.b8(new B.j(i,s.i("i(a.E)").a(new B.jJ()),d),3,d.i("a.E"))
s=B.k(d,B.e(d).i("a.E"))
c8.ab=s
s=f7.h(0,"trialRefilledAt")
s=typeof s=="string"?s:c9
c8.aG=B.a9(s==null?"":s)
s=f7.h(0,"trialStreakCount")
c8.W=A.a.t(A.a.k(A.a.t(typeof s=="number"?A.c.k(s):0,0,e7)),0,7)
s=f7.h(0,"trialStreakLastDayKey")
s=typeof s=="string"?s:c9
c8.a0=s==null?"":s
c8.aV=B.a5(f7.h(0,f3))&&B.ab(f7.h(0,f3))
s=f7.h(0,"trialStreakCarryDayKey")
s=typeof s=="string"?s:c9
c8.ak=s==null?"":s
s=f7.h(0,"trialStreakLastCompletionDayKey")
s=typeof s=="string"?s:c9
c8.bl=s==null?"":s
c8.a6=B.am(f7.h(0,"trialStreakCreditedDayKeys"))
s=c8.bl.length===0
if(s){i=c8.ak
c8.bl=i.length!==0?i:c8.a0}if(c8.aV)c8.W=7
if(c8.W===0)c8.a0=""
if(b2<51)B.pD(c8,!s)
B.nx(c8)
s=B.n(r,o)
for(i=B.an(f7.h(0,"dragonSchoolRecords")),i=new B.y(i,B.e(i).i("y<1,2>")).gq(0);i.l();){e=i.d
d=e.a
if(A.i.a9(d).length!==0){c=e.b
s.j(0,d,A.a.k(A.a.t(typeof c=="number"?A.c.k(c):0,0,e7)))}}c8.eb=s
b4=B.an(f7.h(0,"adventureOptionIds"))
s=t.g
i=s.a(b4.h(0,"mini"))
if(i==null)i=c9
else{i=J.bO(i,r)
d=i.$ti
c=d.i("j<a.E>")
c=B.b8(new B.j(i,d.i("i(a.E)").a($.b2().gai()),c),3,c.i("a.E"))
i=B.k(c,B.e(c).i("a.E"))}if(i==null)i=B.m([],t.s)
d=s.a(b4.h(0,"short"))
if(d==null)d=c9
else{d=J.bO(d,r)
c=d.$ti
a9=c.i("j<a.E>")
a9=B.b8(new B.j(d,c.i("i(a.E)").a($.b2().gai()),a9),3,a9.i("a.E"))
d=B.k(a9,B.e(a9).i("a.E"))}if(d==null)d=B.m([],t.s)
c=s.a(b4.h(0,"long"))
if(c==null)c=c9
else{c=J.bO(c,r)
a9=c.$ti
b5=a9.i("j<a.E>")
b5=B.b8(new B.j(c,a9.i("i(a.E)").a($.b2().gai()),b5),3,b5.i("a.E"))
c=B.k(b5,B.e(b5).i("a.E"))}c8.al=B.V([A.q,i,A.o,d,A.z,c==null?B.m([],t.s):c],t.lV,t.bF)
i=f7.h(0,"miniAdventureRefilledAt")
i=typeof i=="string"?i:c9
c8.aH=B.a9(i==null?"":i)
i=f7.h(0,"shortAdventureRefilledAt")
i=typeof i=="string"?i:c9
c8.aC=B.a9(i==null?"":i)
i=f7.h(0,"longAdventureRefillDay")
i=typeof i=="string"?i:c9
c8.b0=i==null?"":i
i=s.a(f7.h(0,"towerFloorRoomIds"))
if(i==null)i=c9
else{i=J.bO(i,r)
d=i.$ti
c=d.i("j<a.E>")
c=B.b8(new B.j(i,d.i("i(a.E)").a(new B.jK()),c),20,c.i("a.E"))
i=B.k(c,B.e(c).i("a.E"))}if(i==null)i=B.m([],t.s)
c8.L=i
if(i.length===0)c8.L=B.m(["hearth"],t.s)
i=B.cE(f7.h(0,"releasedDragons"))
d=i.$ti
q=B.bt(i,d.i("Y(a.E)").a(B.oD()),d.i("a.E"),q)
d=B.e(q)
i=d.i("j<a.E>")
q=B.k(new B.j(q,d.i("i(a.E)").a(new B.jL()),i),i.i("a.E"))
c8.b1=q
q=f7.h(0,"dragonWardLevel")
c8.by=A.a.k(A.a.t(A.a.k(A.a.t(typeof q=="number"?A.c.k(q):0,0,e7)),0,3))
s=s.a(f7.h(0,"damagedTowerFloors"))
if(s==null)s=c9
else{s=J.bO(s,n)
q=s.$ti
q=B.bt(s,q.i("c(a.E)").a(new B.jM()),q.i("a.E"),o)
s=B.e(q)
n=s.i("j<a.E>")
n=B.a3(new B.j(q,s.i("i(a.E)").a(new B.jN(c8)),n),n.i("a.E"))
s=n}c8.aj=s==null?B.a1(o):s
b6=B.an(f7.h(0,"damagedTowerRepairFactors"))
s=B.n(o,t.i)
for(q=c8.aj,q=B.lE(q,q.r,B.e(q).c),n=q.$ti.c;q.l();){i=q.d
if(i==null)i=n.a(i)
d=B.dI(b6.h(0,B.z(i)))
d=d==null?c9:A.c.t(d,0.25,0.6)
s.j(0,i,d==null?0.4:d)}c8.bz=s
s=t.h
q=B.n(r,s)
for(n=B.an(f7.h(0,"returningVisitors")),n=new B.y(n,B.e(n).i("y<1,2>")).gq(0);n.l();){e=n.d
b7=B.a9(J.au(e.b))
if(b7!=null)q.j(0,e.a,b7)}c8.bf=q
q=B.n(r,s)
for(n=B.an(f7.h(0,"rareInteractionAt")),n=new B.y(n,B.e(n).i("y<1,2>")).gq(0);n.l();){e=n.d
b8=B.a9(J.au(e.b))
if(b8!=null)q.j(0,e.a,b8)}c8.e6=q
q=f7.h(0,"lastReturningDayKey")
q=typeof q=="string"?q:c9
c8.c2=q==null?"":q
q=f7.h(0,"scheduledReturningAt")
q=typeof q=="string"?q:c9
c8.b2=B.a9(q==null?"":q)
q=f7.h(0,"latestReturningEvent")
c8.ae=typeof q=="string"?q:c9
q=f7.h(0,"returningSpecialAdventureId")
c8.b3=typeof q=="string"?q:c9
q=f7.h(0,"returningSpecialAvailableUntil")
q=typeof q=="string"?q:c9
c8.bg=B.a9(q==null?"":q)
q=B.am(f7.h(0,"startedSeasonalSpecialEventKeys"))
q=B.b8(q,50,B.e(q).c)
c8.bA=B.a3(q,B.e(q).i("a.E"))
q=B.am(f7.h(0,"notifiedSeasonalSpecialEventKeys"))
q=B.b8(q,50,B.e(q).c)
c8.bh=B.a3(q,B.e(q).i("a.E"))
c8.b4=B.n(r,s)
for(s=B.an(f7.h(0,"seasonalEventPreviewExpiresAt")),s=new B.y(s,B.e(s).i("y<1,2>")).gq(0);s.l();){e=s.d
b9=B.a9(J.au(e.b))
q=e.a
if(B.mf(q)!=null&&b9!=null)c8.b4.j(0,q,b9)}s=B.am(f7.h(0,"appliedSeasonalPrizeIds"))
s=B.b8(s,100,B.e(s).c)
c8.e7=B.a3(s,B.e(s).i("a.E"))
o=B.n(r,o)
for(s=B.an(f7.h(0,"seasonalPodiumEmoteWinCounts")),s=new B.y(s,B.e(s).i("y<1,2>")).gq(0);s.l();){e=s.d
q=e.a
n=e.b
o.j(0,q,A.a.t(typeof n=="number"?A.c.k(n):0,0,999))}c8.e8=o
s=B.am(f7.h(0,"ownedItemIds"))
q=B.e(s)
o=q.i("j<1>")
c8.b5=B.a3(new B.j(s,q.i("i(1)").a(new B.jO()),o),o.i("a.E"))
c0=B.an(f7.h(0,"equippedItemIds"))
c8.aP=B.n(t.iI,r)
for(j=0;j<4;++j){c1=A.lu[j]
c2=c0.h(0,c1.b)
c2=typeof c2=="string"?c2:c9
c3=c2==null?c9:$.de().h(0,c2)
if(c3!=null&&c3.f===c1){s=c8.b5
q=c3.a
s.n(0,q)
c8.aP.j(0,c1,q)}}s=B.dv(["nest"],r)
s.A(0,B.am(f7.h(0,"unlockedRoomIds")))
s.eU(s.$ti.i("i(1)").a(new B.jP()),!0)
c8.aQ=s
s=f7.h(0,"activeRoomId")
c4=typeof s=="string"?s:c9
if(c4==null)c4=f4
c8.aR=c8.aQ.p(0,c4)?c4:f4
c5=B.n(r,t.E)
for(s=B.cE(f7.h(0,"housePlacements")),q=s.$ti,s=new B.d8(s.a(),q.i("d8<1>")),q=q.c;s.l();){o=s.b
if(o==null)o=q.a(o)
n=o.h(0,"itemId")
n=typeof n=="string"?n:c9
if(n==null)n=""
i=o.h(0,"roomId")
i=typeof i=="string"?i:c9
if(i==null)i=f4
c6=o.h(0,"x")
c6=typeof c6=="number"?c6:0.5
d=A.c.t(isFinite(c6)?c6:0.5,0.04,0.96)
c6=o.h(0,"y")
c6=typeof c6=="number"?c6:0.7
c=A.c.t(isFinite(c6)?c6:0.7,0.04,0.96)
c6=o.h(0,"scale")
c6=typeof c6=="number"?c6:1
o=A.c.t(isFinite(c6)?c6:1,0.65,1.35)
if($.de().h(0,n)==null||!c8.aQ.p(0,i))continue
c8.b5.n(0,n)
c5.j(0,n,new B.bH(n,i,d,c,o))}s=c5.$ti.i("ai<2>")
s=B.k(new B.ai(c5,s),s.i("a.E"))
c8.aw=s
if(c8.d2){c8.aE.n(0,"portrait_supporter_founder")
c8.az.n(0,"title_supporter_founder")
c8.c5.n(0,f6)
c8.d4.n(0,f5)
c8.b5.A(0,new B.K(A.cq,t.jW.a(new B.jR()),t.oo))
if(!a7)c8.d3=f6
if(!a8)c8.d5=f5}if(c8.aw.length===0&&c8.aP.a!==0){s=c8.aP
q=B.e(s).i("ai<2>")
s=B.k(new B.ai(s,q),q.i("a.E"))
q=s.length
j=0
for(;j<s.length;s.length===q||(0,B.Z)(s),++j){c7=s[j]
c3=$.de().h(0,c7)
if(c3!=null)c8.dA(c3,f4)}}else c8.f_()
s=t.iV
r=B.n(r,s)
for(q=B.cE(f7.h(0,"activities")),o=q.$ti,s=B.bt(q,o.i("b3(a.E)").a(B.rT()),o.i("a.E"),s),o=B.e(s),s=new B.c1(J.at(s.a),s.b,o.i("c1<1,2>")),o=o.y[1];s.l();){q=s.a
if(q==null)q=o.a(q)
r.j(0,q.a,q)}s=r.$ti.i("ai<2>")
q=s.i("j<a.E>")
s=B.k(new B.j(new B.ai(r,s),s.i("i(a.E)").a(new B.jS()),q),q.i("a.E"))
c8.aD=s
c8.dW()
B.mt(c8)
B.hF(c8)},
aN(a){var s,r
if(a===A.l){s=this.y1
s=new B.ai(s,B.e(s).i("ai<2>")).aI(0,0,new B.kd(),t.S)
r=this.xr.h(0,a)
s+=r==null?0:r}else{s=this.xr.h(0,a)
if(s==null)s=0}return s},
bM(a){var s=this.y1.h(0,a)
return s==null?0:s},
fR(a){var s,r=this,q=B.nB(r,a)
A:{if(A.u===a){s=Math.min(q,Math.max(0,$.dQ().length-r.ge2()))
break A}if(A.v===a){s=Math.min(q,Math.max(0,$.dP().length-r.ge3()))
break A}if(A.p===a){s=Math.min(q,Math.max(0,80-r.ay.a))
break A}s=q
break A}return s},
aY(a){var s=this.y2.h(0,a)
return s==null?0:s},
eo(a){var s=this.aS.h(0,a)
return s==null?0:s},
fW(a){var s=this.ci,r=B.e(s).i("y<1,2>")
return new B.j(new B.y(s,r),r.i("i(a.E)").a(new B.kH(a)),r.i("j<a.E>")).aI(0,0,new B.kI(),t.S)},
cr(a){return Math.max(0,this.aY(a)-this.fW(a))},
fJ(a){var s=this.bi,r=B.q(s),q=new B.j(s,r.i("i(1)").a(new B.kv(a)),r.i("j<1>")).gm(0),p=this.ci.h(0,"chronoshard:"+a)
return q<=(p==null?0:p)},
ge2(){var s=$.dQ(),r=B.q(s)
return new B.j(s,r.i("i(1)").a(new B.ke(this)),r.i("j<1>")).gm(0)},
ge3(){var s=$.dP(),r=B.q(s)
return new B.j(s,r.i("i(1)").a(new B.kf(this)),r.i("j<1>")).gm(0)},
gfS(){var s=t.d2
s=B.k(new B.j(A.bg,t.ae.a(new B.kw(this)),s),s.i("a.E"))
s.$flags=1
return s},
gfd(){var s=B.aR(B.f2(this,this.b.$0()),t.W),r=B.q(s),q=t.d2
s=B.k(new B.j(A.ct,t.ae.a(new B.kb(new B.K(s,r.i("d(1)").a(new B.kc()),r.i("K<1,d>")).aK(0))),q),q.i("a.E"))
s.$flags=1
return s},
geg(){return this.ay.a+this.aN(A.p)>=80},
gd1(){var s,r,q=B.k(this.gfd(),t.r)
A.b.A(q,this.gfS())
s=B.q(q)
r=s.i("c0<1,d>")
q=B.k(new B.c0(new B.j(q,s.i("i(1)").a(new B.kj(this)),s.i("j<1>")),s.i("d(1)").a(new B.kk()),r),r.i("a.E"))
q.$flags=1
return q},
dS(){var s=this.gd1(),r=this.CW
return B.mA(this.cx,r,s)},
cn(){var s=0,r=B.D(t.b6),q,p=this,o,n
var $async$cn=B.E(function(a,b){if(a===1)return B.A(b,r)
for(;;)switch(s){case 0:if(p.ge2()+p.aN(A.u)>=$.dQ().length){q=A.OC
s=1
break}o=p.ok
o===$&&B.N()
n=o.e
if(n<100){q=A.OB
s=1
break}o.e=n-100
p.xr.aq(A.u,new B.kB(),new B.kC())
p.cA(A.b5,-100,"A Portrait Chest was purchased.","portrait",A.ab)
s=3
return B.o(p.F(),$async$cn)
case 3:q=A.OA
s=1
break
case 1:return B.B(q,r)}})
return B.C($async$cn,r)},
cp(){var s=0,r=B.D(t.bQ),q,p=this,o,n
var $async$cp=B.E(function(a,b){if(a===1)return B.A(b,r)
for(;;)switch(s){case 0:if(p.ge3()+p.aN(A.v)>=$.dP().length){q=A.RC
s=1
break}o=p.ok
o===$&&B.N()
n=o.d
if(n<100){q=A.RB
s=1
break}o.d=n-100
p.xr.aq(A.v,new B.kD(),new B.kE())
p.eE(A.b_,-100,"A Title Chest was purchased.","title",A.ab)
s=3
return B.o(p.F(),$async$cp)
case 3:q=A.RA
s=1
break
case 1:return B.B(q,r)}})
return B.C($async$cp,r)},
cm(){var s=0,r=B.D(t.bx),q,p=this,o,n
var $async$cm=B.E(function(a,b){if(a===1)return B.A(b,r)
for(;;)switch(s){case 0:if(p.geg()){q=A.Mp
s=1
break}o=p.ok
o===$&&B.N()
n=o.e
if(n<250){q=A.Mo
s=1
break}o.e=n-250
p.xr.aq(A.p,new B.ky(),new B.kz())
p.cA(A.L,-250,"A Music Chest was purchased.","music",A.ab)
s=3
return B.o(p.F(),$async$cm)
case 3:q=A.Mn
s=1
break
case 1:return B.B(q,r)}})
return B.C($async$cm,r)},
dG(a,b){var s=A.a.k(A.a.t(b,0,1e8)),r=this.aY(A.x)>0&&this.aF===a.a?s*2:s
a.c+=r
return r},
c_(a){var s=0,r=B.D(t.y),q,p=this,o,n,m
var $async$c_=B.E(function(b,c){if(b===1)return B.A(c,r)
for(;;)switch(s){case 0:if(p.aY(A.x)<=0){q=!1
s=1
break}o=a==null
if(!o&&!A.b.N(B.aH(p),new B.kl(a))){q=!1
s=1
break}if(p.aF==a){q=!0
s=1
break}n=p.aF=a
m=o?"The Twinstar Brooch was unequipped.":"The Twinstar Brooch was equipped."
p.ao(A.L,m,"twinstarBrooch:"+(o?"none":n),A.y)
s=3
return B.o(p.F(),$async$c_)
case 3:q=!0
s=1
break
case 1:return B.B(q,r)}})
return B.C($async$c_,r)},
fK(a,b){var s
A:{if(A.az===a){s=b.ay
break A}if(A.aA===a){s=b.at
break A}if(A.aB===a){s=b.ch
break A}if(A.x===a){s=this.aY(A.x)>0&&this.aF===b.a
break A}if(A.ak===a||A.a8===a||A.aC===a){s=!1
break A}s=null}return s},
dI(a,b){var s,r,q=this
if(a===A.x){if(q.bC)return
q.bC=!0
q.y2.j(0,a,1)
q.aS.j(0,a,1)
return}q.y2.aq(a,new B.jr(),new B.js())
if(b)q.aS.aq(a,new B.jt(),new B.ju())
if(a===A.a8){s=q.bi
r=q.a.C(81)
A.b.n(s,J.p9(10+r,10,90))}},
dH(a){return this.dI(a,!1)},
bP(a){var s=this
if(a===A.x||s.aY(a)<=0)return
s.y2.j(0,a,s.aY(a)-1)
if(s.eo(a)>0)s.aS.j(0,a,s.eo(a)-1)},
ct(a,b){var s=0,r=B.D(t.f5),q,p=this,o,n
var $async$ct=B.E(function(c,d){if(c===1)return B.A(d,r)
for(;;)A:switch(s){case 0:if(p.cr(a)<=0){q=A.NQ
s=1
break}o=B.aH(p)
o=new B.aB(o,B.q(o).i("aB<1,Y?>"))
n=o.a7(o,new B.kK(b),new B.kL())
if(n==null){q=A.NR
s=1
break}if(p.fK(a,n)){q=A.bp
s=1
break}if(!B.qf(a)){q=A.bp
s=1
break}p.bP(a)
switch(a.a){case 0:n.ay=!0
break
case 1:n.at=!0
break
case 2:n.dO()
n.ch=!0
break
case 3:case 4:case 5:case 6:q=A.bp
s=1
break A}p.ao(A.L,B.nO(a)+" revealed something about "+n.gU()+".",a.b+":"+n.a,A.y)
s=3
return B.o(p.F(),$async$ct)
case 3:q=A.NP
s=1
break
case 1:return B.B(q,r)}})
return B.C($async$ct,r)},
co(a){var s=0,r=B.D(t.fg),q,p=this,o,n
var $async$co=B.E(function(b,c){if(b===1)return B.A(c,r)
for(;;)switch(s){case 0:if(!B.qg(a)){q=A.NO
s=1
break}o=p.ok
o===$&&B.N()
n=o.e
if(n<500){q=A.NN
s=1
break}o.e=n-500
p.dI(a,!0)
p.cA(A.L,-500,"A "+B.nO(a)+" was purchased for 500 gems.",a.b,A.ab)
s=3
return B.o(p.F(),$async$co)
case 3:q=A.NM
s=1
break
case 1:return B.B(q,r)}})
return B.C($async$co,r)},
cs(a){var s=0,r=B.D(t.pd),q,p=this,o
var $async$cs=B.E(function(b,c){if(b===1)return B.A(c,r)
for(;;)switch(s){case 0:if(p.cr(A.ak)<=0){q=A.dQ
s=1
break}o=p.ok
o===$&&B.N()
if(!(o.f===A.h))o=p.p1
if(!((o==null?null:o.a)===a||A.b.N(p.p2,new B.kJ(a)))){q=A.dR
s=1
break}if(p.aT.p(0,a)){q=A.dS
s=1
break}p.bP(A.ak)
p.aT.n(0,a)
p.ao(A.L,"An Astral Lens revealed an egg rarity.","astralLens:"+a,A.y)
s=3
return B.o(p.F(),$async$cs)
case 3:q=A.dP
s=1
break
case 1:return B.B(q,r)}})
return B.C($async$cs,r)},
bL(a){var s=0,r=B.D(t.e_),q,p=this,o,n,m,l,k
var $async$bL=B.E(function(b,c){if(b===1)return B.A(c,r)
for(;;)switch(s){case 0:k=A.b.fE(p.bi,a)
if(k<0||p.cr(A.a8)<=0||p.fJ(a)){q=A.e5
s=1
break}o=p.ok
o===$&&B.N()
if(o.f===A.h)n=o
else n=p.p1
if(n==null||n.f!==A.h){q=A.e6
s=1
break}m=p.b.$0()
o=n.k2
l=n.cx
o=o.P(B.ah(0,0,0,0,0,l).a).au(m).a
if(o>1e6){o=A.a.G(o,1000)
n.k2=m.P(B.ah(0,0,0,Math.max(1000,o-A.c.cq(o*a/100)),0,0).a).P(0-B.ah(0,0,0,0,0,l).a)}A.b.b8(p.bi,k)
p.bP(A.a8)
o=""+a
p.ao(A.L,"A Chronoshard shortened the remaining incubation by "+o+"%.","chronoshard:"+o,A.y)
s=3
return B.o(p.bT(),$async$bL)
case 3:s=4
return B.o(p.F(),$async$bL)
case 4:q=A.e4
s=1
break
case 1:return B.B(q,r)}})
return B.C($async$bL,r)},
fp(a){var s,r,q
A:{if(A.F===a){s=0.01
break A}if(A.M===a){s=0.04
break A}if(A.t===a){s=0.12
break A}if(A.G===a||A.H===a||A.a4===a){s=1
break A}if(A.l===a||A.u===a||A.v===a||A.p===a){s=0
break A}s=null}r=a===A.F||a===A.M||a===A.t
if(this.p2.length===0){q=this.ok
q===$&&B.N()
if(!(q.f===A.h))q=this.p1
q=q==null}else q=!1
return q&&r?s*3:s},
bZ(a){var s,r,q,p=this.ok
p===$&&B.N()
if(p.a===a)return p
p=this.p1
if((p==null?null:p.a)===a)return p
for(p=this.x2,s=p.length,r=0;r<s;++r){q=p[r]
if(q.a===a)return q}return null},
bR(a){if(A.b.N(this.bk,new B.jA(a)))return
A.b.n(this.bk,a)},
gfm(){var s=this.ap,r=B.e(s),q=r.i("bc<1,d>")
return B.a3(new B.bc(s,r.i("d(1)").a(new B.ki()),q),q.i("a.E")).a},
gfl(){var s=this.ap,r=B.e(s),q=r.i("bc<1,d>")
return new B.j(A.a2,t.hU.a(new B.kg(B.a3(new B.bc(s,r.i("d(1)").a(new B.kh()),q),q.i("a.E")))),t.dx).gm(0)},
fU(a){var s=this.aw,r=B.q(s),q=r.i("j<1>")
s=B.k(new B.j(s,r.i("i(1)").a(new B.kx(a)),q),q.i("a.E"))
return s},
bY(a){var s=0,r=B.D(t.H),q,p=this,o
var $async$bY=B.E(function(b,c){if(b===1)return B.A(c,r)
for(;;)switch(s){case 0:o=!p.k2
if(o)p.k2=!0
if(a&&!p.k3){p.k3=!0
o=p.a5()||o}if(!o){s=1
break}s=3
return B.o(p.F(),$async$bY)
case 3:case 1:return B.B(q,r)}})
return B.C($async$bY,r)},
bH(a,b){var s=0,r=B.D(t.h8),q,p=this,o,n,m
var $async$bH=B.E(function(c,d){if(c===1)return B.A(d,r)
for(;;)switch(s){case 0:if(b<=0||p.bM(a)<b){q=null
s=1
break}o=B.m([],t.ge)
n=0
case 3:if(!(n<b)){s=5
break}s=6
return B.o(p.bQ(!1,a),$async$bH)
case 6:m=d
if(m==null){q=null
s=1
break}A.b.n(o,m)
case 4:++n
s=3
break
case 5:s=7
return B.o(p.F(),$async$bH)
case 7:q=new B.dU(A.l,B.aR(o,t.aQ))
s=1
break
case 1:return B.B(q,r)}})
return B.C($async$bH,r)},
dP(a,b){var s,r,q=this,p=B.t5(a),o=B.q(p),n=o.i("j<1>")
p=B.k(new B.j(p,o.i("i(1)").a(new B.k1(q)),n),n.i("a.E"))
p.$flags=1
s=p
if(s.length===0||q.a.S()>=b)return null
p=q.a.C(s.length)
if(!(p>=0&&p<s.length))return B.b(s,p)
r=s[p]
q.bB.n(0,r.a)
return r},
dD(a){var s
A:{if(A.F===a){s=0.005
break A}if(A.M===a){s=0.01
break A}if(A.t===a){s=0.02
break A}if(A.G===a){s=0.04
break A}if(A.H===a){s=0.08
break A}if(A.a4===a){s=0.12
break A}if(A.l===a){s=0.1
break A}if(A.u===a||A.v===a||A.p===a){s=0
break A}s=null}return s},
bn(a,b){var s=0,r=B.D(t.h8),q,p=this,o,n,m
var $async$bn=B.E(function(c,d){if(c===1)return B.A(d,r)
for(;;)switch(s){case 0:if(b<=0||p.fR(a)<b){q=null
s=1
break}o=B.m([],t.ge)
n=0
case 3:if(!(n<b)){s=5
break}s=6
return B.o(p.cR(a,!1),$async$bn)
case 6:m=d
if(m==null){q=null
s=1
break}A.b.n(o,m)
case 4:++n
s=3
break
case 5:s=a===A.p?7:8
break
case 7:s=9
return B.o(p.dS(),$async$bn)
case 9:case 8:s=10
return B.o(p.F(),$async$bn)
case 10:q=new B.dU(a,B.aR(o,t.aQ))
s=1
break
case 1:return B.B(q,r)}})
return B.C($async$bn,r)},
cR(a,b){var s=0,r=B.D(t.c),q,p=this,o,n,m,l,k,j,i,h
var $async$cR=B.E(function(c,d){if(c===1)return B.A(d,r)
for(;;)switch(s){case 0:if(B.nB(p,a)<=0){q=null
s=1
break}if(a===A.u){q=p.cT(!1)
s=1
break}if(a===A.v){q=p.cU(!1)
s=1
break}if(a===A.p){q=p.cS(!1)
s=1
break}if(a===A.l){q=p.eX(!1)
s=1
break}p.xr.j(0,a,p.aN(a)-1)
A:{o=A.F===a
if(o){n=20+p.a.C(21)
break A}if(A.M===a){n=45+p.a.C(36)
break A}if(A.t===a){n=90+p.a.C(71)
break A}if(A.G===a){n=180+p.a.C(121)
break A}if(A.H===a||A.a4===a){n=400+p.a.C(251)
break A}if(A.l===a){n=269
break A}if(A.u===a||A.v===a||A.p===a){n=0
break A}n=null}B:{m=0
if(o){o=m
break B}if(A.M===a){o=p.a
o=o.S()<0.5?1+o.C(2):0
break B}if(A.t===a){o=p.a
o=o.S()<0.72?2+o.C(3):0
break B}if(A.G===a){o=p.a
o=o.S()<0.9?4+o.C(4):0
break B}if(A.H===a||A.a4===a){o=8+p.a.C(6)
break B}if(A.l===a){o=10
break B}if(A.u===a||A.v===a||A.p===a){o=m
break B}o=null}l=p.fp(a)
k=p.a.S()<l
j=p.f6(a)
i=p.dP(A.d,p.dD(a))
m=p.ok
m===$&&B.N()
m.d+=n
m.e+=o;++p.aU
if(k){h=p.eP(a)
A.b.n(p.p2,h)}else h=null
if(j!=null)p.dH(j)
m=a.b
p.cB(A.aF,n,o,m+" chest opened.",m,A.y)
p.a5()
m=h==null?null:h.z
q=new B.bD(a,n,o,k,m===!0,!1,null,null,j,null,null,null,i)
s=1
break
case 1:return B.B(q,r)}})
return B.C($async$cR,r)},
bQ(a,a0){var s=0,r=B.D(t.c),q,p=this,o,n,m,l,k,j,i,h,g,f,e,d,c,b
var $async$bQ=B.E(function(a1,a2){if(a1===1)return B.A(a2,r)
for(;;)switch(s){case 0:if(a0==null||p.bM(a0)<=0){o=A.bo.gY()
n=B.hn(o,B.e(o).i("a.E"),t.jv).a7(0,new B.jx(p),new B.jy())}else n=a0
if(n==null){m=p.xr.h(0,A.l)
if(m==null)m=0
if(m<=0){q=null
s=1
break}p.xr.j(0,A.l,m-1)
n="golden_wings_chest_v1"}else{p.y1.j(0,n,p.bM(n)-1)
if(p.y1.h(0,n)===0)p.y1.X(0,n)}l=A.bo.h(0,n)
if(l==null){q=null
s=1
break}o=p.p2
k=l.x
j=A.aS.h(0,k)
if(j==null)j=A.cL
i=p.c.$0()
h=p.b.$0()
g=p.a
f=g.C(2147483648)
e=g.S()
d=g.C(3)
if(!(d>=0&&d<3)){q=B.b(A.J,d)
s=1
break}d=A.J[d]
c=j.w
if(c==null){c=g.C(3)
if(!(c>=0&&c<3)){q=B.b(A.a1,c)
s=1
break}c=A.a1[c]}g=B.n1(g.S())
A.b.n(o,B.f1(h,A.aH,f,i,1008,A.a.G(j.f.a,1e6),d,j.e,c,j.x,e<0.05,null,!1,g,j.a,0))
g=p.ok
g===$&&B.N()
e=g.d
c=l.r
g.d=e+c
e=g.e
d=l.w
g.e=e+d;++p.aU
b=p.dP(A.d,p.dD(A.l))
p.cB(A.aF,c,d,l.c+" revealed a one-of-a-kind egg.","special",A.y)
p.a5()
q=new B.bD(A.l,c,d,!0,!1,!0,l.a,k,null,null,null,null,b)
s=1
break
case 1:return B.B(q,r)}})
return B.C($async$bQ,r)},
eX(a){return this.bQ(a,null)},
cT(a){var s=0,r=B.D(t.c),q,p=this,o,n,m,l,k
var $async$cT=B.E(function(b,c){if(b===1)return B.A(c,r)
for(;;)switch(s){case 0:m=$.dQ()
l=B.q(m)
k=l.i("j<1>")
m=B.k(new B.j(m,l.i("i(1)").a(new B.jw(p)),k),k.i("a.E"))
m.$flags=1
o=m
m=o.length
if(m===0){q=null
s=1
break}m=p.a.C(m)
if(!(m>=0&&m<o.length)){q=B.b(o,m)
s=1
break}n=o[m]
p.xr.j(0,A.u,p.aN(A.u)-1)
p.aE.n(0,n.a);++p.aU;++p.c9
p.ao(A.aZ,"A new account portrait was revealed.","portrait",A.y)
p.a5()
q=new B.bD(A.u,0,0,!1,!1,!1,null,null,null,n,null,null,null)
s=1
break
case 1:return B.B(q,r)}})
return B.C($async$cT,r)},
cU(a){var s=0,r=B.D(t.c),q,p=this,o,n,m,l,k
var $async$cU=B.E(function(b,c){if(b===1)return B.A(c,r)
for(;;)switch(s){case 0:m=$.dP()
l=B.q(m)
k=l.i("j<1>")
m=B.k(new B.j(m,l.i("i(1)").a(new B.jz(p)),k),k.i("a.E"))
m.$flags=1
o=m
m=o.length
if(m===0){q=null
s=1
break}m=p.a.C(m)
if(!(m>=0&&m<o.length)){q=B.b(o,m)
s=1
break}n=o[m]
p.xr.j(0,A.v,p.aN(A.v)-1)
p.az.n(0,n.a);++p.aU;++p.ca
p.ao(A.b0,"A new account title was revealed.","title",A.y)
p.a5()
q=new B.bD(A.v,0,0,!1,!1,!1,null,null,null,null,n,null,null)
s=1
break
case 1:return B.B(q,r)}})
return B.C($async$cU,r)},
cS(a){var s=0,r=B.D(t.c),q,p=this,o,n,m
var $async$cS=B.E(function(b,c){if(b===1)return B.A(c,r)
for(;;)switch(s){case 0:m=t.d2
m=B.k(new B.j(A.bg,t.ae.a(new B.jv(p)),m),m.i("a.E"))
m.$flags=1
o=m
m=o.length
if(m===0){q=null
s=1
break}m=p.a.C(m)
if(!(m>=0&&m<o.length)){q=B.b(o,m)
s=1
break}n=o[m]
p.xr.j(0,A.p,p.aN(A.p)-1)
m=n.a
p.ay.n(0,m)
p.ch.n(0,m);++p.aU;++p.d7
p.ao(A.L,n.b+" was added to the Jukebox.",m,A.y)
q=new B.bD(A.p,0,0,!1,!1,!1,null,null,null,null,null,n,null)
s=1
break
case 1:return B.B(q,r)}})
return B.C($async$cS,r)},
fV(a){var s
A:{s=0
if(A.F===a||A.M===a)break A
if(A.t===a){s=0.01
break A}if(A.G===a){s=0.02
break A}if(A.H===a){s=0.04
break A}if(A.a4===a){s=1
break A}if(A.l===a||A.u===a||A.v===a||A.p===a)break A
s=null}return s},
f6(a){var s,r,q=this.fV(a),p=this.a
if(p.S()>=q)return null
s=t.cO
s=B.k(new B.j(A.ae,t.gl.a(new B.k0(this)),s),s.i("a.E"))
s.$flags=1
r=s
p=p.C(r.length)
if(!(p>=0&&p<r.length))return B.b(r,p)
return r[p]},
cj(){var s=0,r=B.D(t.y),q,p=this,o,n,m,l,k
var $async$cj=B.E(function(a,b){if(a===1)return B.A(b,r)
for(;;)switch(s){case 0:l=p.b.$0()
k=p.ok
k===$&&B.N()
if(k.f===A.h)o=k
else o=p.p1
if(o!=null)k=!(o.f===A.h&&o.e_(l).a>=B.ah(0,0,0,0,0,o.cx).a)
else k=!0
if(k){q=!1
s=1
break}n=o.a
m=o.k1
p.r=null
B.jl("egg-"+n)
p.eH(o,l)
if(!(o.f===A.h&&o.e_(l).a>=B.ah(0,0,0,0,0,o.cx).a))B.aX(B.bv("This egg is not ready to hatch."))
o.f=A.aj
o.k2=l
o.b=""
o.fy=90
o.go=88
o.id=90
o.k3=l
o.dO()
k=p.ok
if(o!==k){o.d=k.d
o.e=k.e
A.b.da(p.x2,0,k)
p.ok=o
p.p1=null}B.mt(p)
B.hF(p);++p.c6
p.cV(p.ok)
p.ao(A.b1,"A "+B.ci(p.ok.rx).b+" hatched in a burst of starlight.",p.ok.rx,A.ai)
p.bR(new B.aQ("hatch-"+n,A.c9,l,m,n,null,null,A.ay))
p.a5()
s=3
return B.o(p.F(),$async$cj)
case 3:q=!0
s=1
break
case 1:return B.B(q,r)}})
return B.C($async$cj,r)},
eH(a,b){if(a.w||B.th(b)!==A.cc)return
if(this.a.C(19)===0)a.w=!0},
cl(a,b){var s=0,r=B.D(t.y),q,p=this,o,n
var $async$cl=B.E(function(c,d){if(c===1)return B.A(d,r)
for(;;)switch(s){case 0:o=A.i.a9(b)
n=p.bZ(a)
if(n==null||n.f===A.h||o.length===0||new B.cY(o).gm(0)>24){q=!1
s=1
break}if(A.i.a9(n.b).length!==0){q=B.iY(p,a,o)
s=1
break}n.b=o;++p.d6
p.a5()
s=3
return B.o(p.F(),$async$cl)
case 3:q=!0
s=1
break
case 1:return B.B(q,r)}})
return B.C($async$cl,r)},
c0(a){var s=0,r=B.D(t.y),q,p=this,o,n
var $async$c0=B.E(function(b,c){if(b===1)return B.A(c,r)
for(;;)switch(s){case 0:o=p.b.$0()
n=p.bZ(a)
if(n==null||!n.d_(o)){q=!1
s=1
break}p.eY(n,o)
p.a5()
s=3
return B.o(p.F(),$async$c0)
case 3:q=!0
s=1
break
case 1:return B.B(q,r)}})
return B.C($async$c0,r)},
cL(a){var s,r,q,p,o,n=B.aH(this),m=B.m(n.slice(0),B.q(n))
A.b.b_(m,new B.jq())
for(n=m.length,s=!1,r=0,q=0;q<m.length;m.length===n||(0,B.Z)(m),++q){p=m[q]
for(;p.d_(a);r=o,s=!0){o=r+1
this.dL(p,a,r)}}return s},
dL(a,b,c){var s,r,q,p,o,n=this,m=a.gdn()
if(!a.d_(b))B.aX(B.bv("This dragon is not ready to evolve."))
s=a.f
if(s===A.aj)s=a.f=A.a7
else if(s===A.a7){if(a.gfD())s="mastery"
else s=a.gbm()==="unknown"?"spirit":a.gbm()
a.ry=s
a.f=A.I
s=A.I}a.k2=b
if(s===A.a7)++n.c7
if(s===A.I)++n.c8
n.cV(a)
n.ao(A.b2,a.gU()+" reached the "+a.f.b+" form.",a.rx,A.ai)
s=a.a
r="evolution-"+s+"-"
n.bR(new B.aQ(r+a.f.b,A.ca,b.P(B.ah(0,0,c,0,0,0).a),a.k1,s,null,m,A.ay))
q=new B.bF(n.z)
p=q.fT(a.gdn())
s=a.f
o=q.I("New evolution!","Nieuwe evolutie!")
B.mD(q.I(a.gU()+" evolved into "+p+".",a.gU()+" is ge\xebvolueerd naar "+p+"."),r+s.b,o)},
eY(a,b){return this.dL(a,b,0)},
bX(){var s=0,r=B.D(t.y),q,p=this,o,n
var $async$bX=B.E(function(a,b){if(a===1)return B.A(b,r)
for(;;)switch(s){case 0:n=p.ok
n===$&&B.N()
o=n.e
if(o<3||n.f===A.h){q=!1
s=1
break}n.e=o-3
p.dG(n,25)
n=p.ok
n.sfM(Math.min(100,n.fy+12))
n=p.ok
n.sfv(Math.min(100,n.go+12))
n=p.ok
n.sfi(Math.min(100,n.id+12))
p.cL(p.b.$0())
p.a5()
s=3
return B.o(p.F(),$async$bX)
case 3:q=!0
s=1
break
case 1:return B.B(q,r)}})
return B.C($async$bX,r)},
bt(a){var s=0,r=B.D(t.y),q,p=this,o,n,m,l,k,j,i
var $async$bt=B.E(function(b,c){if(b===1)return B.A(c,r)
for(;;)switch(s){case 0:if(p.ry||p.x1!=null||p.p3.w.p(0,a)){q=!1
s=1
break}if(p.bE.p(0,a)){q=!1
s=1
break}o=A.b.d9(p.p2,new B.ka(a))
if(o>=0){n=p.ok
n===$&&B.N()
n=n.f===A.h||p.p1!=null}else n=!0
if(n){q=!1
s=1
break}m=A.b.b8(p.p2,o)
n=t.dq.a(p.b.$0())
l=m.b
k=n==null?new B.ac(Date.now(),0,!1):n
j=l==="sinisterra"||m.as
i=m.ax
p.p1=B.nP(m.c,null,i,0,78,0,"hearth",null,!1,0,null,null,78,null,!1,!1,0,m.d,null,m.a,60,m.y,78,m.r,i.d,l,m.w,j,"",n,!1,null,m.e,!0,m.f,m.z,m.x,A.h,k,null,null,m.at)
B.mx(p)
k=p.p1
k.toString
p.a5()
s=3
return B.o(p.F(),$async$bt)
case 3:s=4
return B.o(p.bs(k),$async$bt)
case 4:q=!0
s=1
break
case 1:return B.B(q,r)}})
return B.C($async$bt,r)},
bT(){var s=0,r=B.D(t.H),q,p=this,o,n
var $async$bT=B.E(function(a,b){if(a===1)return B.A(b,r)
for(;;)switch(s){case 0:if(!p.as){s=1
break}o=p.ok
o===$&&B.N()
if(o.f===A.h)n=o
else n=p.p1
if(n==null){s=1
break}s=3
return B.o(p.bs(n),$async$bT)
case 3:case 1:return B.B(q,r)}})
return B.C($async$bT,r)},
bs(a){var s=0,r=B.D(t.H),q=this,p,o,n,m,l
var $async$bs=B.E(function(b,c){if(b===1)return B.A(c,r)
for(;;)switch(s){case 0:o=new B.bF(q.z)
n=a.f===A.h
m=n&&a.rx==="sinisterra"
l=!1
if(n){n=a.rx
if(B.ci(n).cx)n=!(a.f===A.h&&n==="sinisterra")
else n=l}else n=l
if(m)p=o.I("Sinister Egg","Sinister Ei")
else p=n?o.I("Special Egg","Speciaal Ei"):o.I("Mysterious Egg","Mysterieus Ei")
n=a.k2.P(B.ah(0,0,0,0,0,a.cx).a)
m=o.I("Your "+p+" is ready","Je "+p+" is klaar")
s=2
return B.o(B.mC(n,o.I(u.T,"Iets binnenin wil uitkomen in het Daknest."),"egg-"+a.a,m),$async$bs)
case 2:return B.B(null,r)}})
return B.C($async$bs,r)},
fb(a){var s,r,q,p=this
A:{if("hello_little_one"===a){s=p.c6
break A}if("guided_tour"===a){s=p.k3?1:0
break A}if("first_flight"===a){s=p.cc
break A}if("chest_expectations"===a){s=p.aU
break A}if("profile_picture_perfect"===a){s=p.c9
break A}if("highly_titled"===a){s=p.ca
break A}if("room_to_roost"===a||"halfway_clouds"===a||"sky_ceiling"===a){s=p.L.length
break A}if("feed_furniture"===a){s=p.aw.length
break A}if("book_wyrm"===a||"well_read_scaled"===a){s=p.gfl()
break A}if("scale_every_tale"===a){s=p.gfm()
break A}if("growing_pains"===a){s=p.c7
break A}if("not_picking_favorites"===a){s=p.cg
break A}if("ascension_day"===a){s=p.c8
break A}if("something_spectral"===a){s=p.bD.a===0?0:1
break A}if("frequent_flyer"===a||"are_we_there_yet"===a){s=p.cb
break A}if("full_party"===a){s=p.cd
break A}if("triple_expertise"===a){s=p.ok
s===$&&B.N()
s=B.m([s],t.a)
A.b.A(s,p.x2)
s=A.b.N(s,new B.k3())?1:0
break A}if("hidden_mastery"===a){s=p.ok
s===$&&B.N()
s=B.m([s],t.a)
A.b.A(s,p.x2)
s=A.b.N(s,new B.k4())?1:0
break A}if("came_crawling_back"===a){s=p.ce
break A}if("ghost_writer"===a){s=p.bD
r=B.e(s)
q=r.i("bc<1,d>")
q=B.a3(new B.bc(s,r.i("d(1)").a(new B.k5()),q),q.i("a.E")).a
s=q
break A}if("myth_made_real"===a){s=p.ok
s===$&&B.N()
s=B.m([s],t.a)
A.b.A(s,p.x2)
s=A.b.N(s,new B.k6())?1:0
break A}if("trial_might_s_plus"===a){s=B.nf(A.an,B.mv(p,A.an))===A.aV?1:0
break A}if("trial_spirit_s_plus"===a){s=B.nf(A.ag,B.mv(p,A.ag))===A.aV?1:0
break A}if("trial_arcana_s_plus"===a){s=B.nf(A.ao,B.mv(p,A.ao))===A.aV?1:0
break A}if("probably_fine"===a){s=p.cf
break A}if("winner_chicken_dinner"===a){s=p.ap.p(0,"cluckatrice:hatchling")?1:0
break A}if("warden_of_the_witchlight"===a){s=p.ap.p(0,"gloamgourd:hatchling")?1:0
break A}if("star_in_every_hearth"===a){s=p.ap.p(0,"hollyfrost:hatchling")?1:0
break A}if("first_light_first_flight"===a){s=p.ap.p(0,"dawnchime:hatchling")?1:0
break A}if("two_hearts_one_flight"===a){s=p.ap.p(0,"rosevow:hatchling")?1:0
break A}if("every_color_takes_flight"===a){s=p.ap.p(0,"spectrumplume:hatchling")?1:0
break A}if("academy_graduate"===a){s=A.b.N(B.aH(p),new B.k7())?1:0
break A}if("dragon_school_dropout"===a){s=A.b.N(B.aH(p),new B.k8())?1:0
break A}if("dragon_school_valedictorian"===a){s=A.b.N(B.aH(p),new B.k9())?1:0
break A}s=0
break A}return s},
bI(a){var s=0,r=B.D(t.jl),q,p=this,o,n,m,l,k
var $async$bI=B.E(function(b,c){if(b===1)return B.A(c,r)
for(;;)switch(s){case 0:if(A.b.N(p.aw,new B.kA(a))){q=A.OM
s=1
break}o=a.a
s=p.b5.p(0,o)?3:4
break
case 3:p.eJ(a)
p.a5()
s=5
return B.o(p.F(),$async$bI)
case 5:q=A.OJ
s=1
break
case 4:n=a.CW
m=n===A.w
if(m){l=p.ok
l===$&&B.N()
l=l.d<a.r}else l=!1
if(l){q=A.OK
s=1
break}n=n===A.be
if(n){l=p.ok
l===$&&B.N()
l=l.e<a.r}else l=!1
if(l){q=A.OL
s=1
break}l=p.ok
k=a.r
if(m){l===$&&B.N()
l.d-=k}else{l===$&&B.N()
l.e-=k}p.b5.n(0,o)
m=m?-k:0
n=n?-k:0
p.cB(A.b4,m,n,a.b+" was purchased and stored in Inventory.",o,A.ab)
s=6
return B.o(p.F(),$async$bI)
case 6:q=A.OI
s=1
break
case 1:return B.B(q,r)}})
return B.C($async$bI,r)},
bK(a){var s=0,r=B.D(t.bj),q,p=this,o,n,m,l
var $async$bK=B.E(function(b,c){if(b===1)return B.A(c,r)
for(;;)switch(s){case 0:l=a.a
s=p.aQ.p(0,l)?3:4
break
case 3:s=p.aR!==l?5:6
break
case 5:p.aR=l
s=7
return B.o(p.F(),$async$bK)
case 7:case 6:q=A.QC
s=1
break
case 4:o=p.ok
o===$&&B.N()
if(B.qm(o.c)<a.b){q=A.QB
s=1
break}o=p.ok
n=o.d
m=a.c
if(n<m){q=A.QA
s=1
break}o.d=n-m
p.aQ.n(0,l)
p.aR=l
p.a5()
s=8
return B.o(p.F(),$async$bK)
case 8:q=A.Qz
s=1
break
case 1:return B.B(q,r)}})
return B.C($async$bK,r)},
bo(){var s=0,r=B.D(t.H),q=this,p,o,n,m,l,k,j,i,h,g,f,e,d,c
var $async$bo=B.E(function(a,b){if(a===1)return B.A(b,r)
for(;;)switch(s){case 0:g=A.b.aW(q.gd1(),"|")
s=2
return B.o(B.f7(q),$async$bo)
case 2:f=b
e=t.s
d=B.m([],e)
c=q.al.h(0,A.q)
if(c!=null)A.b.A(d,c)
d.push("#")
c=q.al.h(0,A.o)
if(c!=null)A.b.A(d,c)
d.push("#")
c=q.al.h(0,A.z)
if(c!=null)A.b.A(d,c)
c=q.aH
c=c==null?null:c.K()
d.push(c==null?"":c)
c=q.aC
c=c==null?null:c.K()
d.push(c==null?"":c)
d.push(q.b0)
p=A.b.aW(d,"|")
d=q.ab
c=B.q(d)
o=t.N
d=B.k(new B.K(d,c.i("d(1)").a(new B.kF()),c.i("K<1,d>")),o)
c=q.aG
c=c==null?null:c.K()
d.push(c==null?"":c)
n=A.b.aW(d,"|")
B.f5(q,A.q)
B.f5(q,A.o)
B.f5(q,A.z)
B.ny(q)
B.aR(q.ab,t.e)
e=B.m([],e)
d=q.al.h(0,A.q)
if(d!=null)A.b.A(e,d)
e.push("#")
d=q.al.h(0,A.o)
if(d!=null)A.b.A(e,d)
e.push("#")
d=q.al.h(0,A.z)
if(d!=null)A.b.A(e,d)
d=q.aH
d=d==null?null:d.K()
e.push(d==null?"":d)
d=q.aC
d=d==null?null:d.K()
e.push(d==null?"":d)
e.push(q.b0)
m=A.b.aW(e,"|")
e=q.ab
d=B.q(e)
e=B.k(new B.K(e,d.i("d(1)").a(new B.kG()),d.i("K<1,d>")),o)
d=q.aG
d=d==null?null:d.K()
e.push(d==null?"":d)
l=A.b.aW(e,"|")
k=B.hF(q)
e=q.b
j=B.nw(q,e.$0())
d=A.B.ad(A.B.ad(f,p!==m),n!==l)
c=q.ok
c===$&&B.N()
i=A.B.ad(A.B.ad(A.B.ad(A.B.ad(A.B.ad(A.B.ad(A.B.ad(A.B.ad(A.B.ad(d,c.ff(e.$0())),q.cV(q.ok)),q.cL(e.$0())),B.hJ(q)),B.pC(q)),B.pE(q)),k),j),B.pK(q))
h=q.a5()
s=g!==A.b.aW(q.gd1(),"|")?3:4
break
case 3:s=5
return B.o(q.dS(),$async$bo)
case 5:case 4:s=i||h?6:7
break
case 6:s=8
return B.o(q.F(),$async$bo)
case 8:case 7:return B.B(null,r)}})
return B.C($async$bo,r)},
eP(a){var s,r,q,p,o,n,m,l,k=this,j=null,i=k.a,h=i.C(2147483648)
if(a===A.a4){s=i.S()
s=s<0.5}else s=!1
if(s){s=k.c.$0()
r=k.b.$0()
q=i.C(20)
p=i.C(3)
if(!(p>=0&&p<3))return B.b(A.J,p)
return B.f1(r,A.aH,h,s,1008,21966,A.J[p],"sinisterra",A.D,!1,q===0,j,!0,B.n1(i.S()),j,0)}o=k.f5(a)
n=i.S()
s=k.c.$0()
r=k.b.$0()
q=i.C(20)
p=i.C(3)
if(!(p>=0&&p<3))return B.b(A.J,p)
p=A.J[p]
m=i.C(3)
if(!(m>=0&&m<3))return B.b(A.a1,m)
m=A.a1[m]
l=B.n1(n)
return B.f1(r,A.aH,h,s,(48+i.C(289))*6,j,p,o.a,m,!1,q===0,j,!1,l,j,0)},
f5(a){var s,r,q,p,o,n=this.a,m=n.S()
A:{if(A.F===a){s=A.ci
break A}if(A.M===a){s=A.ne
break A}if(A.t===a){s=A.n7
break A}if(A.G===a){s=A.lc
break A}if(A.H===a||A.a4===a){s=A.xB
break A}if(A.l===a||A.u===a||A.v===a||A.p===a){s=A.ci
break A}s=null}r=s.length
if(0>=r)return B.b(s,0)
if(m<s[0])q=A.m
else{if(1>=r)return B.b(s,1)
if(m<s[1])q=A.Q
else{if(2>=r)return B.b(s,2)
if(m<s[2])s=A.ad
else{if(3>=r)return B.b(s,3)
if(m<s[3])s=A.aK
else{if(4>=r)return B.b(s,4)
s=m<s[4]?A.b7:A.aL}}q=s}}s=$.hb()
r=B.q(s)
p=r.i("j<1>")
o=B.k(new B.j(s,r.i("i(1)").a(new B.k_(q)),p),p.i("a.E"))
n=n.C(o.length)
if(!(n>=0&&n<o.length))return B.b(o,n)
return o[n]},
cV(a){var s,r,q,p,o,n
if(a.f===A.h)return!1
s=a.w?this.bD:this.ap
r=B.m(["hatchling"],t.s)
if(a.f.a>=2)A.b.n(r,"wyrmling")
if(a.f===A.I){q=a.ry
A.b.n(r,"ascended:"+(q==null?a.gbm():q))}for(q=r.length,p=a.rx+":",o=!1,n=0;n<r.length;r.length===q||(0,B.Z)(r),++n)o=s.n(0,p+r[n])||o
return o},
a5(){var s,r,q,p,o,n,m,l,k,j,i,h=this
for(s=h.c,r=h.b,q=!1,p=0;p<38;++p){o=A.CI[p]
n=o.a
if(h.bj.p(0,n)||h.fb(n)<o.f)continue
h.bj.n(0,n)
m=r.$0()
h.bR(new B.aQ("achievement-"+n,A.aO,m,m,null,n,null,A.ay))
l=h.z
k=new B.bF(l).fc(o)
l=A.Ly.h(0,l)
if(l==null)l="Achievement unlocked"
B.mB(k,n,l)
l=h.aD
j=s.$0()
i=r.$0()
A.b.da(l,0,new B.b3(j,"Achievement unlocked: "+o.b,i,A.ai,A.b3,n,0,0,0))
n=h.aD
if(n.length>40){l=B.q(n)
j=new B.d_(n,0,40,l.i("d_<1>"))
j.ez(n,0,40,l.c)
h.aD=j.bJ(0)}q=!0}return q},
bq(a,b,c,d,e,f,g){var s=this
A.b.da(s.aD,0,new B.b3(s.c.$0(),d,s.b.$0(),f,a,e,g,b,c))
s.dW()},
ao(a,b,c,d){return this.bq(a,0,0,b,c,d,0)},
cB(a,b,c,d,e,f){return this.bq(a,b,c,d,e,f,0)},
cA(a,b,c,d,e){return this.bq(a,0,b,c,d,e,0)},
eE(a,b,c,d,e){return this.bq(a,b,0,c,d,e,0)},
eF(a,b,c,d,e){return this.bq(a,0,0,b,c,d,e)},
dW(){var s=this.aD
if(s.length>40)this.aD=B.fI(s,0,B.h6(40,"count",t.S),B.q(s).c).bJ(0)},
dA(a,b){var s,r,q,p,o,n,m=this,l=m.aQ,k=b==null
if(l.p(0,k?m.aR:b))s=k?m.aR:b
else s="nest"
A.b.a1(m.aw,new B.jo(a))
l=m.fU(s)
k=B.q(l)
r=new B.j(l,k.i("i(1)").a(new B.jp(a)),k.i("j<1>")).gm(0)
k=m.aw
q=$.dd().h(0,s)
if(q==null)q=A.b.gM(A.cs)
p=q.a
l=a.f
o=B.r6(p,l,q)[A.a.D(r,3)]
n=a.a
A.b.n(k,new B.bH(n,p,o.a,o.b,1))
m.aP.j(0,l,n)},
eJ(a){return this.dA(a,null)},
f_(){var s,r,q,p,o
this.aP.aB(0)
for(s=this.aw,r=s.length,q=0;q<s.length;s.length===r||(0,B.Z)(s),++q){p=s[q]
o=$.de().h(0,p.a)
if(o!=null)this.aP.j(0,o.f,o.a)}},
F(){var s=0,r=B.D(t.H),q=this
var $async$F=B.E(function(a,b){if(a===1)return B.A(b,r)
for(;;)switch(s){case 0:++q.w
s=2
return B.o(q.dQ(),$async$F)
case 2:return B.B(null,r)}})
return B.C($async$F,r)},
c1(){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,d0,d1,d2,d3,d4,d5,d6,d7,d8,d9,e0,e1,e2,e3,e4,e5,e6,e7,e8,e9,f0,f1,f2,f3,f4,f5,f6,f7,f8,f9,g0,g1,g2,g3,g4,g5,g6,g7,g8,g9,h0,h1,h2,h3,h4,h5,h6,h7,h8,h9,i0,i1,i2,i3,i4,i5=this,i6=null,i7=i5.p3.H(),i8=i5.x1,i9=i5.z,j0=i5.Q,j1=i5.as,j2=i5.at,j3=i5.ax,j4=i5.ay
j4=B.k(j4,B.e(j4).c)
s=i5.ch
s=B.k(s,B.e(s).c)
r=i5.CW
q=i5.cx
p=i5.cy
p=B.k(p,B.e(p).c)
o=i5.db
n=i5.dx
m=B.e(n)
l=m.i("bc<1,d>")
n=B.k(new B.bc(n,m.i("d(1)").a(new B.km()),l),l.i("a.E"))
m=i5.dy
l=i5.fr
k=i5.fx
j=i5.fy
i=i5.go
h=i5.id
g=i5.k1
f=i5.k2
e=i5.k3
d=i5.ok
d===$&&B.N()
d=d.H()
c=i5.p1
c=c==null?i6:c.H()
b=i5.p2
a=B.q(b)
a0=a.i("K<1,t<d,@>>")
b=B.k(new B.K(b,a.i("t<d,@>(1)").a(new B.kn()),a0),a0.i("a4.E"))
a=i5.x2
a0=B.q(a)
a1=a0.i("K<1,t<d,@>>")
a=B.k(new B.K(a,a0.i("t<d,@>(1)").a(new B.ko()),a1),a1.i("a4.E"))
a0=t.N
a1=t.S
a2=B.n(a0,a1)
for(a3=i5.xr,a3=new B.y(a3,B.e(a3).i("y<1,2>")).gq(0);a3.l();){a4=a3.d
a2.j(0,a4.a.b,a4.b)}a3=i5.y1
a5=B.n(a0,a1)
for(a6=i5.y2,a6=new B.y(a6,B.e(a6).i("y<1,2>")).gq(0);a6.l();){a4=a6.d
a5.j(0,a4.a.b,a4.b)}a1=B.n(a0,a1)
for(a6=i5.aS,a6=new B.y(a6,B.e(a6).i("y<1,2>")).gq(0);a6.l();){a4=a6.d
a1.j(0,a4.a.b,a4.b)}a6=i5.bi
a7=i5.aT
a7=B.k(a7,B.e(a7).c)
a8=i5.bC
a9=i5.aF
b0=i5.aE
b0=B.k(b0,B.e(b0).c)
b1=i5.c3
b2=i5.az
b2=B.k(b2,B.e(b2).c)
b3=i5.c4
b4=i5.d2
b5=i5.c5
b5=B.k(b5,B.e(b5).c)
b6=i5.d3
b7=i5.d4
b7=B.k(b7,B.e(b7).c)
b8=i5.d5
b9=i5.e9
b9=B.k(b9,B.e(b9).c)
c0=i5.bB
c0=B.k(c0,B.e(c0).c)
c1=i5.ea
c1=B.k(c1,B.e(c1).c)
c2=i5.ap
c2=B.k(c2,B.e(c2).c)
c3=i5.bD
c3=B.k(c3,B.e(c3).c)
c4=i5.bj
c4=B.k(c4,B.e(c4).c)
c5=i5.bk
c6=B.q(c5)
c7=c6.i("K<1,t<d,@>>")
c5=B.k(new B.K(c5,c6.i("t<d,@>(1)").a(new B.kp()),c7),c7.i("a4.E"))
c6=i5.c6
c7=i5.d6
c8=i5.c7
c9=i5.c8
d0=i5.aU
d1=i5.c9
d2=i5.ca
d3=i5.d7
d4=i5.cb
d5=i5.cc
d6=i5.cd
d7=i5.ce
d8=i5.cf
d9=i5.cg
e0=i5.a3
e1=B.q(e0)
e2=e1.i("K<1,t<d,@>>")
e0=B.k(new B.K(e0,e1.i("t<d,@>(1)").a(new B.kq()),e2),e2.i("a4.E"))
e1=i5.ab
e2=B.q(e1)
e3=e2.i("K<1,t<d,@>>")
e1=B.k(new B.K(e1,e2.i("t<d,@>(1)").a(new B.kr()),e3),e3.i("a4.E"))
e2=i5.aG
e2=e2==null?i6:e2.K()
e3=i5.W
e4=i5.a0
e5=i5.bl
e6=i5.a6
e6=B.k(e6,B.e(e6).c)
e7=i5.aV
e8=i5.ak
e9=i5.eb
f0=i5.ec
f0=B.k(f0,B.e(f0).c)
f1=i5.ed
f1=B.k(f1,B.e(f1).c)
f2=i5.ee
f2=B.k(f2,B.e(f2).c)
f3=i5.bE
f3=B.k(f3,B.e(f3).c)
f4=i5.d8
f5=i5.ci
f6=B.n(a0,t.bF)
for(f7=i5.al,f7=new B.y(f7,B.e(f7).i("y<1,2>")).gq(0);f7.l();){a4=f7.d
f6.j(0,a4.a.b,a4.b)}f7=i5.aH
f7=f7==null?i6:f7.K()
f8=i5.aC
f8=f8==null?i6:f8.K()
f9=i5.b0
g0=i5.L
g1=i5.b1
g2=B.q(g1)
g3=g2.i("K<1,t<d,@>>")
g1=B.k(new B.K(g1,g2.i("t<d,@>(1)").a(new B.ks()),g3),g3.i("a4.E"))
g2=i5.by
g3=i5.aj
g3=B.k(g3,B.e(g3).c)
g4=B.n(a0,t.i)
for(g5=i5.bz,g5=new B.y(g5,B.e(g5).i("y<1,2>")).gq(0);g5.l();){a4=g5.d
g4.j(0,""+a4.a,a4.b)}g5=B.n(a0,a0)
for(g6=i5.bf,g6=new B.y(g6,B.e(g6).i("y<1,2>")).gq(0);g6.l();){a4=g6.d
g5.j(0,a4.a,a4.b.K())}g6=B.n(a0,a0)
for(g7=i5.e6,g7=new B.y(g7,B.e(g7).i("y<1,2>")).gq(0);g7.l();){a4=g7.d
g6.j(0,a4.a,a4.b.K())}g7=i5.c2
g8=i5.b2
g8=g8==null?i6:g8.K()
g9=i5.ae
h0=i5.b3
h1=i5.bg
h1=h1==null?i6:h1.K()
h2=i5.bA
h2=B.k(h2,B.e(h2).c)
h3=i5.bh
h3=B.k(h3,B.e(h3).c)
h4=B.n(a0,a0)
for(h5=i5.b4,h5=new B.y(h5,B.e(h5).i("y<1,2>")).gq(0);h5.l();){a4=h5.d
h4.j(0,a4.a,a4.b.K())}h5=i5.e7
h5=B.k(h5,B.e(h5).c)
h6=i5.e8
h7=i5.b5
h7=B.k(h7,B.e(h7).c)
h8=B.n(a0,a0)
for(h9=i5.aP,h9=new B.y(h9,B.e(h9).i("y<1,2>")).gq(0);h9.l();){a4=h9.d
h8.j(0,a4.a.b,a4.b)}h9=i5.aQ
h9=B.k(h9,B.e(h9).c)
i0=i5.aR
i1=i5.aw
i2=B.q(i1)
i3=i2.i("K<1,t<d,@>>")
i1=B.k(new B.K(i1,i2.i("t<d,@>(1)").a(new B.kt()),i3),i3.i("a4.E"))
i2=i5.aD
i3=B.q(i2)
i4=i3.i("K<1,t<d,@>>")
i2=B.k(new B.K(i2,i3.i("t<d,@>(1)").a(new B.ku()),i4),i4.i("a4.E"))
return B.V(["eggAltar",i7,"pendingAltarOperation",i8,"schemaVersion",54,"languageCode",i9,"accountName",j0,"onboardingComplete",j1,"musicEnabled",j2,"musicStyle",j3.b,"ownedMusicTrackIds",j4,"enabledMusicTrackIds",s,"jukeboxShuffle",r,"jukeboxRepeat",q,"disabledSeasonalMusicTrackIds",p,"soundEffectsEnabled",o,"enabledNotificationCategories",n,"notificationSettingsVersion",3,"achievementsCompact",m,"myDragonsViewMode",l,"myDragonsSortMode",k,"myDragonsSortDescending",j,"eggInventoryViewMode",i,"eggInventorySortMode",h,"eggInventorySortDescending",g,"tutorialCompleted",f,"tutorialFullyViewed",e,"pet",d,"incubatingEgg",c,"eggStash",b,"sanctuaryDragons",a,"chestInventory",a2,"specialChestInventory",a3,"relicInventory",a5,"untradeableRelicInventory",a1,"chronoshardReductions",a6,"eggRarityRevealedIds",a7,"twinstarBroochEverObtained",a8,"twinstarBroochDragonId",a9,"ownedPortraitIds",b0,"selectedPortraitId",b1,"ownedTitleIds",b2,"selectedTitleId",b3,"supporterPackOwned",b4,"ownedBadgeIds",b5,"selectedBadgeId",b6,"ownedFrameIds",b7,"selectedFrameId",b8,"appliedVerifiedPurchaseIds",b9,"ownedDragonEmoteIds",c0,"ownedDragonEmotePackIds",c1,"discoveredForms",c2,"prismaticForms",c3,"achievements",c4,"pendingPresentations",c5,"totalHatched",c6,"totalNamed",c7,"totalWyrmling",c8,"totalAscended",c9,"totalChestsOpened",d0,"totalPortraitChestsOpened",d1,"totalTitleChestsOpened",d2,"totalMusicChestsOpened",d3,"totalAdventuresCompleted",d4,"totalShortAdventuresCompleted",d5,"totalGroupFourCompleted",d6,"totalReleasedReturns",d7,"totalSinisterAdventuresCompleted",d8,"favoriteChanges",d9,"adventureRuns",e0,"trialOffers",e1,"trialRefilledAt",e2,"trialStreakCount",e3,"trialStreakLastDayKey",e4,"trialStreakLastCompletionDayKey",e5,"trialStreakCreditedDayKeys",e6,"trialStreakRewardReady",e7,"trialStreakCarryDayKey",e8,"dragonSchoolRecords",e9,"appliedOnlineGroupRewardIds",f0,"appliedOnlineTradeIds",f1,"appliedOnlineSeasonalPairRewardIds",f2,"reservedOnlineTradeEggIds",f3,"reservedOnlineTradeChests",f4,"reservedOnlineTradeRelics",f5,"adventureOptionIds",f6,"miniAdventureRefilledAt",f7,"shortAdventureRefilledAt",f8,"longAdventureRefillDay",f9,"towerFloorRoomIds",g0,"releasedDragons",g1,"dragonWardLevel",g2,"damagedTowerFloors",g3,"damagedTowerRepairFactors",g4,"returningVisitors",g5,"rareInteractionAt",g6,"lastReturningDayKey",g7,"scheduledReturningAt",g8,"latestReturningEvent",g9,"returningSpecialAdventureId",h0,"returningSpecialAvailableUntil",h1,"startedSeasonalSpecialEventKeys",h2,"notifiedSeasonalSpecialEventKeys",h3,"seasonalEventPreviewExpiresAt",h4,"appliedSeasonalPrizeIds",h5,"seasonalPodiumEmoteWinCounts",h6,"ownedItemIds",h7,"equippedItemIds",h8,"unlockedRoomIds",h9,"activeRoomId",i0,"housePlacements",i1,"activities",i2],a0,t.z)},
dQ(){var s=B.nF(t.H)
return s},
bd(){this.ev()},
sfs(a){this.p2=t.jE.a(a)},
sfo(a){this.p3=t.ny.a(a)},
sfe(a){this.rx=t.kv.a(a)},
seh(a){this.x1=t.dZ.a(a)},
sfq(a){this.aT=t.gi.a(a)},
sh2(a){this.W=B.r(a)},
sdi(a){this.a6=t.gi.a(a)},
sfQ(a){this.bh=t.gi.a(a)}}
B.jn.prototype={
$0(){return this.a},
$S:72}
B.jD.prototype={
$1(a){var s=new B.aB(A.bi,t.j4)
return s.a7(s,new B.jB(B.M(a)),new B.jC())},
$S:110}
B.jB.prototype={
$1(a){var s
t.nB.a(a)
s=a==null?null:a.b
return s===this.a},
$S:74}
B.jC.prototype={
$0(){return null},
$S:2}
B.jE.prototype={
$1(a){return t.x.a(a).f!==A.h},
$S:0}
B.jF.prototype={
$1(a){return t.x.a(a).a===this.a},
$S:0}
B.jQ.prototype={
$1(a){return A.a.t(A.c.k(B.h4(a)),10,90)},
$S:40}
B.jT.prototype={
$1(a){var s
B.M(a)
s=$.oW().h(0,a)
return s!=null},
$S:6}
B.jU.prototype={
$1(a){return t.J.a(a).c===A.cy},
$S:23}
B.jV.prototype={
$1(a){var s
B.M(a)
s=$.ni().h(0,a)
return s!=null},
$S:6}
B.jW.prototype={
$1(a){return t.ew.a(a).a},
$S:77}
B.jX.prototype={
$1(a){return B.ow(B.M(a))!=null},
$S:6}
B.jY.prototype={
$1(a){return t.F.a(a).a},
$S:78}
B.jZ.prototype={
$2(a,b){B.M(a)
return B.r(b)<=0},
$S:41}
B.jG.prototype={
$2(a,b){B.M(a)
return B.r(b)<=0},
$S:41}
B.jH.prototype={
$1(a){return t.A.a(a).f==="dragon_school_dropout"},
$S:42}
B.jI.prototype={
$1(a){t.k.a(a)
return $.b2().J(a.b)},
$S:10}
B.jJ.prototype={
$1(a){return t.e.a(a).a.length!==0},
$S:21}
B.jK.prototype={
$1(a){B.M(a)
return $.dd().h(0,a)!=null&&a!=="nest"},
$S:6}
B.jL.prototype={
$1(a){return t.x.a(a).f!==A.h},
$S:0}
B.jM.prototype={
$1(a){return A.c.k(B.h4(a))},
$S:40}
B.jN.prototype={
$1(a){B.r(a)
return a>=0&&a<this.a.L.length},
$S:5}
B.jO.prototype={
$1(a){B.M(a)
return $.de().h(0,a)!=null},
$S:6}
B.jP.prototype={
$1(a){B.M(a)
return $.dd().h(0,a)==null},
$S:6}
B.jR.prototype={
$1(a){return t.jx.a(a).a},
$S:109}
B.jS.prototype={
$1(a){return t.iV.a(a).e!==A.aE},
$S:82}
B.kd.prototype={
$2(a,b){return B.r(a)+B.r(b)},
$S:15}
B.kH.prototype={
$1(a){var s=t.jA.a(a).a,r=this.a.b
return s===r||A.i.cz(s,r+":")},
$S:83}
B.kI.prototype={
$2(a,b){return B.r(a)+t.jA.a(b).b},
$S:84}
B.kv.prototype={
$1(a){return B.r(a)===this.a},
$S:5}
B.ke.prototype={
$1(a){t.J.a(a)
return this.a.aE.p(0,a.a)},
$S:23}
B.kf.prototype={
$1(a){t.V.a(a)
return this.a.az.p(0,a.a)},
$S:43}
B.kw.prototype={
$1(a){t.r.a(a)
return this.a.ay.p(0,a.a)},
$S:16}
B.kc.prototype={
$1(a){return t.W.a(a).a.dx},
$S:36}
B.kb.prototype={
$1(a){return this.a.p(0,t.r.a(a).a)},
$S:16}
B.kj.prototype={
$1(a){var s,r
t.r.a(a)
s=this.a
r=a.a
return a.e!=null?!s.cy.p(0,r):s.ch.p(0,r)},
$S:16}
B.kk.prototype={
$1(a){var s
t.r.a(a)
s=a.d
return s==null?"music_"+a.a:s},
$S:87}
B.kB.prototype={
$1(a){return B.r(a)+1},
$S:3}
B.kC.prototype={
$0(){return 1},
$S:4}
B.kD.prototype={
$1(a){return B.r(a)+1},
$S:3}
B.kE.prototype={
$0(){return 1},
$S:4}
B.ky.prototype={
$1(a){return B.r(a)+1},
$S:3}
B.kz.prototype={
$0(){return 1},
$S:4}
B.kl.prototype={
$1(a){return t.x.a(a).a===this.a},
$S:0}
B.jr.prototype={
$1(a){return B.r(a)+1},
$S:3}
B.js.prototype={
$0(){return 1},
$S:4}
B.jt.prototype={
$1(a){return B.r(a)+1},
$S:3}
B.ju.prototype={
$0(){return 1},
$S:4}
B.kK.prototype={
$1(a){var s
t.m.a(a)
s=a==null?null:a.a
return s===this.a},
$S:13}
B.kL.prototype={
$0(){return null},
$S:2}
B.kJ.prototype={
$1(a){return t.R.a(a).a===this.a},
$S:8}
B.jA.prototype={
$1(a){return t.A.a(a).a===this.a.a},
$S:42}
B.ki.prototype={
$1(a){return A.b.gM(B.M(a).split(":"))},
$S:14}
B.kh.prototype={
$1(a){return A.b.gM(B.M(a).split(":"))},
$S:14}
B.kg.prototype={
$1(a){t.Y.a(a)
return a.ax===A.m&&this.a.p(0,a.a)},
$S:12}
B.kx.prototype={
$1(a){return t.E.a(a).b===this.a},
$S:17}
B.k1.prototype={
$1(a){t.F.a(a)
return!this.a.bB.p(0,a.a)},
$S:19}
B.jx.prototype={
$1(a){B.b0(a)
return a!=null&&this.a.bM(a)>0},
$S:90}
B.jy.prototype={
$0(){return null},
$S:2}
B.jw.prototype={
$1(a){t.J.a(a)
return!this.a.aE.p(0,a.a)},
$S:23}
B.jz.prototype={
$1(a){t.V.a(a)
return!this.a.az.p(0,a.a)},
$S:43}
B.jv.prototype={
$1(a){t.r.a(a)
return!this.a.ay.p(0,a.a)},
$S:16}
B.k0.prototype={
$1(a){return t._.a(a)!==A.x||!this.a.bC},
$S:91}
B.jq.prototype={
$2(a,b){var s,r=t.x
r.a(a)
r.a(b)
s=a.k1.Z(0,b.k1)
return s!==0?s:A.i.Z(a.a,b.a)},
$S:22}
B.ka.prototype={
$1(a){return t.R.a(a).a===this.a},
$S:8}
B.k3.prototype={
$1(a){return A.b.aO(A.K,new B.k2(t.x.a(a)))},
$S:0}
B.k2.prototype={
$1(a){return this.a.aL(t.U.a(a))>=300},
$S:92}
B.k4.prototype={
$1(a){var s
t.x.a(a)
if(a.f===A.I){s=a.ry
s=(s==null?a.gbm():s)==="mastery"}else s=!1
return s},
$S:0}
B.k5.prototype={
$1(a){return A.b.gM(B.M(a).split(":"))},
$S:14}
B.k6.prototype={
$1(a){return B.ci(t.x.a(a).rx).ax===A.aL},
$S:0}
B.k7.prototype={
$1(a){return B.pL(t.x.a(a).gd0())},
$S:0}
B.k8.prototype={
$1(a){return t.x.a(a).gd0()===A.b8},
$S:0}
B.k9.prototype={
$1(a){return t.x.a(a).gd0()===A.b9},
$S:0}
B.kA.prototype={
$1(a){return t.E.a(a).a===this.a.a},
$S:17}
B.kF.prototype={
$1(a){t.e.a(a)
return a.a+":"+a.b.b},
$S:44}
B.kG.prototype={
$1(a){t.e.a(a)
return a.a+":"+a.b.b},
$S:44}
B.k_.prototype={
$1(a){return t.Y.a(a).ax===this.a},
$S:12}
B.jo.prototype={
$1(a){return t.E.a(a).a===this.a.a},
$S:17}
B.jp.prototype={
$1(a){var s
t.E.a(a)
s=$.de().h(0,a.a)
s=s==null?null:s.f
return s===this.a.f},
$S:17}
B.km.prototype={
$1(a){return t.eE.a(a).b},
$S:94}
B.kn.prototype={
$1(a){return t.R.a(a).H()},
$S:95}
B.ko.prototype={
$1(a){return t.x.a(a).H()},
$S:25}
B.kp.prototype={
$1(a){return t.A.a(a).H()},
$S:97}
B.kq.prototype={
$1(a){return t.k.a(a).H()},
$S:98}
B.kr.prototype={
$1(a){return t.e.a(a).H()},
$S:99}
B.ks.prototype={
$1(a){return t.x.a(a).H()},
$S:25}
B.kt.prototype={
$1(a){return t.E.a(a).H()},
$S:100}
B.ku.prototype={
$1(a){return t.iV.a(a).H()},
$S:101}
B.m7.prototype={
$1(a){return B.pT(B.lT(B.M(a)),t.N)},
$S:102}
B.m8.prototype={
$1(a){return B.rE(B.M(a))},
$S:14}
B.m9.prototype={
$1(a){return B.rF(B.M(a))},
$S:14};(function aliases(){var s=J.cr.prototype
s.ew=s.v
s=B.H.prototype
s.dq=s.aa
s=B.eW.prototype
s.ev=s.bd})();(function installTearOffs(){var s=hunkHelpers._static_2,r=hunkHelpers._instance_1i,q=hunkHelpers._instance_1u,p=hunkHelpers._static_1,o=hunkHelpers._static_0,n=hunkHelpers._instance_0u
s(J,"rj","q9",103)
r(J.v.prototype,"gbw","p",7)
q(B.u.prototype,"gai","J",7)
q(B.b7.prototype,"gai","J",7)
q(B.bl.prototype,"gai","J",7)
p(B,"rW","qC",18)
p(B,"rX","qD",18)
p(B,"rY","qE",18)
o(B,"ou","rN",1)
r(B.bn.prototype,"gbw","p",7)
q(B.S.prototype,"gai","J",7)
q(B.cT.prototype,"gai","J",7)
p(B,"t2","r7",26)
q(B.ex.prototype,"gai","J",7)
p(B,"ta","cP",37)
o(B,"tc","pZ",20)
n(B.en.prototype,"gep","h5",20)
p(B,"rT","ph",105)
p(B,"rU","pk",106)
p(B,"t6","px",107)
p(B,"tb","pX",108)
p(B,"oD","qk",81)
q(B.Y.prototype,"gh1","aL",85)
p(B,"tA","qy",73)})();(function inheritance(){var s=hunkHelpers.mixin,r=hunkHelpers.inherit,q=hunkHelpers.inheritMany
r(B.I,null)
q(B.I,[B.mK,J.fi,B.em,J.cJ,B.a,B.dT,B.cl,B.a6,B.H,B.l7,B.c_,B.c1,B.bx,B.eq,B.eo,B.e1,B.et,B.e5,B.aa,B.bM,B.la,B.by,B.cT,B.di,B.d5,B.cw,B.le,B.kW,B.e2,B.eG,B.S,B.kQ,B.ed,B.ee,B.ec,B.fl,B.lF,B.lK,B.bu,B.fR,B.h3,B.h2,B.fN,B.d8,B.bs,B.d3,B.aC,B.fO,B.h0,B.eM,B.fU,B.cg,B.ez,B.eL,B.dh,B.eZ,B.bS,B.lC,B.lL,B.ac,B.a_,B.fP,B.fy,B.ep,B.lo,B.aI,B.P,B.aL,B.h1,B.fF,B.dB,B.fW,B.fa,B.bU,B.dj,B.fd,B.j5,B.bj,B.lg,B.l4,B.b6,B.fV,B.eW,B.en,B.bF,B.bC,B.Q,B.b3,B.aG,B.dS,B.aA,B.b4,B.cx,B.ca,B.c9,B.c8,B.bD,B.dU,B.ao,B.h,B.dk,B.x,B.bg,B.aP,B.f9,B.aE,B.aQ,B.bk,B.bH,B.l,B.Y,B.c3,B.c5,B.ap,B.a7,B.bm,B.bJ,B.bw,B.aZ,B.ak])
q(J.fi,[J.e7,J.e9,J.ag,J.ds,J.dt,J.cR,J.cS])
q(J.ag,[J.cr,J.v,B.cW,B.ef])
q(J.cr,[J.fA,J.d2,J.bd])
r(J.fj,B.em)
r(J.kO,J.v)
q(J.cR,[J.e8,J.fk])
q(B.a,[B.cz,B.w,B.c0,B.j,B.d0,B.c7,B.b_,B.cQ,B.d4,B.cA,B.cY])
q(B.cz,[B.cK,B.eN])
r(B.ew,B.cK)
r(B.ev,B.eN)
q(B.cl,[B.ln,B.eY,B.eX,B.fJ,B.m3,B.m5,B.lk,B.lj,B.lP,B.lx,B.kT,B.lA,B.hr,B.hs,B.j2,B.ja,B.j9,B.j7,B.lh,B.jf,B.jg,B.jh,B.jd,B.je,B.jj,B.jk,B.mb,B.l9,B.lV,B.lX,B.m_,B.hj,B.hl,B.hg,B.hh,B.hf,B.he,B.hi,B.ht,B.hu,B.lZ,B.mg,B.l1,B.kY,B.kX,B.me,B.lc,B.md,B.ih,B.ij,B.ii,B.it,B.is,B.iu,B.iv,B.iw,B.ix,B.hY,B.hW,B.hZ,B.iG,B.iE,B.hK,B.hL,B.hM,B.hN,B.ig,B.ia,B.hI,B.iy,B.iz,B.iB,B.id,B.i0,B.i1,B.i3,B.i5,B.i7,B.hS,B.hT,B.im,B.ip,B.iq,B.hD,B.hA,B.hQ,B.hR,B.hy,B.hH,B.hw,B.iW,B.iX,B.j1,B.iU,B.iP,B.iQ,B.iR,B.iS,B.iT,B.iN,B.iO,B.jD,B.jB,B.jE,B.jF,B.jQ,B.jT,B.jU,B.jV,B.jW,B.jX,B.jY,B.jH,B.jI,B.jJ,B.jK,B.jL,B.jM,B.jN,B.jO,B.jP,B.jR,B.jS,B.kH,B.kv,B.ke,B.kf,B.kw,B.kc,B.kb,B.kj,B.kk,B.kB,B.kD,B.ky,B.kl,B.jr,B.jt,B.kK,B.kJ,B.jA,B.ki,B.kh,B.kg,B.kx,B.k1,B.jx,B.jw,B.jz,B.jv,B.k0,B.ka,B.k3,B.k2,B.k4,B.k5,B.k6,B.k7,B.k8,B.k9,B.kA,B.kF,B.kG,B.k_,B.jo,B.jp,B.km,B.kn,B.ko,B.kp,B.kq,B.kr,B.ks,B.kt,B.ku,B.m7,B.m8,B.m9])
r(B.aB,B.ev)
q(B.a6,[B.du,B.cd,B.fm,B.fL,B.fG,B.fQ,B.eb,B.eU,B.br,B.es,B.fK,B.dA,B.f_])
r(B.dC,B.H)
r(B.dV,B.dC)
q(B.w,[B.a4,B.e0,B.aJ,B.ai,B.y,B.ey])
q(B.a4,[B.d_,B.K,B.fT])
r(B.bc,B.c0)
r(B.e_,B.d0)
r(B.dm,B.c7)
r(B.dl,B.cQ)
q(B.by,[B.d7,B.dE])
q(B.d7,[B.p,B.J])
r(B.eE,B.dE)
r(B.dG,B.cT)
r(B.er,B.dG)
r(B.dW,B.er)
q(B.eY,[B.ho,B.kP,B.m4,B.lQ,B.lW,B.ly,B.kR,B.kV,B.lD,B.j4,B.j3,B.jb,B.ji,B.m0,B.m1,B.iM,B.iI,B.iJ,B.iK,B.iL,B.l0,B.l_,B.l3,B.l2,B.mc,B.hv,B.hV,B.hC,B.hB,B.hz,B.hG,B.hx,B.jZ,B.jG,B.kd,B.kI,B.jq])
q(B.di,[B.u,B.b7])
q(B.cw,[B.dY,B.eF])
r(B.T,B.dY)
r(B.ek,B.cd)
q(B.fJ,[B.fH,B.dg])
q(B.S,[B.bl,B.ex])
r(B.ea,B.bl)
q(B.ef,[B.fs,B.aK])
q(B.aK,[B.eA,B.eC])
r(B.eB,B.eA)
r(B.cu,B.eB)
r(B.eD,B.eC)
r(B.bf,B.eD)
q(B.cu,[B.ft,B.fu])
q(B.bf,[B.fv,B.fw,B.fx,B.eg,B.eh,B.ei,B.ej])
r(B.dF,B.fQ)
q(B.eX,[B.ll,B.lm,B.lI,B.lp,B.lt,B.ls,B.lr,B.lq,B.lw,B.lv,B.lu,B.lH,B.lU,B.f0,B.jc,B.li,B.hk,B.hm,B.kZ,B.ld,B.hX,B.iF,B.hO,B.ib,B.iA,B.i2,B.i4,B.i6,B.i8,B.hU,B.io,B.hE,B.jn,B.jC,B.kC,B.kE,B.kz,B.js,B.ju,B.kL,B.jy])
r(B.fX,B.eM)
r(B.bn,B.eF)
q(B.dh,[B.eu,B.fS])
r(B.fo,B.eb)
r(B.fn,B.eZ)
q(B.bS,[B.fq,B.fp,B.fM,B.e4,B.fg])
r(B.lB,B.lC)
q(B.br,[B.dz,B.fh])
r(B.fY,B.e4)
r(B.h_,B.fd)
r(B.fZ,B.h_)
q(B.fP,[B.cH,B.bP,B.az,B.bp,B.bq,B.fe,B.av,B.bG,B.bV,B.bb,B.bE,B.dZ,B.b5,B.bY,B.aS,B.a8,B.bX,B.aq,B.bW,B.cq,B.cs,B.c2,B.fE,B.bZ,B.dr,B.e6,B.co,B.e3,B.al,B.cc,B.aD,B.bQ,B.cy,B.c4,B.ct,B.cV,B.ck,B.cL,B.cf,B.cX,B.d1,B.cU,B.cv])
r(B.jm,B.eW)
s(B.dC,B.bM)
s(B.eN,B.H)
s(B.eA,B.H)
s(B.eB,B.aa)
s(B.eC,B.H)
s(B.eD,B.aa)
s(B.dG,B.eL)})()
var v={G:typeof self!="undefined"?self:globalThis,typeUniverse:{eC:new Map(),tR:{},eT:{},tPV:{},sEA:[]},mangledGlobalNames:{c:"int",R:"double",aW:"num",d:"String",i:"bool",aL:"Null",G:"List",I:"Object",t:"Map",ad:"JSObject"},mangledNames:{},types:["i(Y)","~()","aL()","c(c)","c()","i(c)","i(d)","i(I?)","i(ao)","i(@)","i(b4)","aA(c)","i(x)","i(Y?)","d(d)","c(c,c)","i(l)","i(bH)","~(~())","i(h)","d()","i(aZ)","c(Y,Y)","i(c3)","i(d,ac)","t<d,@>(Y)","@(@)","c(c,Y)","@(d)","c(c,d)","i(ak)","~(I?,I?)","0&()","G<d>()","c(d?)","i(aA)","d(ak)","I?(I?)","aL(@)","i(b5)","c(aW)","i(d,c)","i(aQ)","i(bC)","d(aZ)","c(ak,ak)","c(c,aq)","c(aq,aq)","aL(I,bL)","~(@,@)","c3(c)","i(al)","al()","t<d,@>(I?)","d(c)","ad(I,bL)","d?(l6[c])","i(bq)","bq()","i(av?)","aA?(d)","@(@,d)","~(@)","aL(bd,bd)","al?(ak)","i(ak?)","aL(@,bL)","P<d,c>(@,@)","P<d,t<d,@>>(d,aP)","ao(ao)","bC(c)","d(ao)","ac()","aZ(t<d,@>)","i(a8?)","P<d,aP>(@,@)","~(I?,d)","d(bJ)","d(h)","P<d,d>(@,@)","P<d,t<d,@>>(@,@)","Y(t<d,@>)","i(b3)","i(P<d,c>)","c(c,P<d,c>)","c(aq)","d(@)","d(l)","aL(~())","~(Y,d)","i(d?)","i(aS)","i(aq)","c(Y)","d(a8)","t<d,@>(ao)","~(c,@)","t<d,@>(aQ)","t<d,@>(b4)","t<d,@>(aZ)","t<d,@>(bH)","t<d,@>(b3)","ad(d)","c(@,@)","~(I?)","b3(t<d,@>)","b4(t<d,@>)","ao(t<d,@>)","aQ(t<d,@>)","d(ap)","a8?(d)"],interceptorsByTag:null,leafTags:null,arrayRti:Symbol("$ti"),rttc:{"2;":(a,b)=>c=>c instanceof B.p&&a.b(c.a)&&b.b(c.b),"2;x,y":(a,b)=>c=>c instanceof B.J&&a.b(c.a)&&b.b(c.b),"3;":(a,b,c)=>d=>d instanceof B.eE&&a.b(d.a)&&b.b(d.b)&&c.b(d.c)}}
B.qV(v.typeUniverse,JSON.parse('{"bd":"cr","fA":"cr","d2":"cr","tM":"cW","e7":{"i":[],"a0":[]},"e9":{"a0":[]},"ag":{"ad":[]},"cr":{"ag":[],"ad":[]},"v":{"G":["1"],"ag":[],"w":["1"],"ad":[],"a":["1"]},"fj":{"em":[]},"kO":{"v":["1"],"G":["1"],"ag":[],"w":["1"],"ad":[],"a":["1"]},"cJ":{"X":["1"]},"cR":{"R":[],"aW":[],"ba":["aW"]},"e8":{"R":[],"c":[],"aW":[],"ba":["aW"],"a0":[]},"fk":{"R":[],"aW":[],"ba":["aW"],"a0":[]},"cS":{"d":[],"ba":["d"],"fz":[],"a0":[]},"cz":{"a":["2"]},"dT":{"X":["2"]},"cK":{"cz":["1","2"],"a":["2"],"a.E":"2"},"ew":{"cK":["1","2"],"cz":["1","2"],"w":["2"],"a":["2"],"a.E":"2"},"ev":{"H":["2"],"G":["2"],"cz":["1","2"],"w":["2"],"a":["2"]},"aB":{"ev":["1","2"],"H":["2"],"G":["2"],"cz":["1","2"],"w":["2"],"a":["2"],"H.E":"2","a.E":"2"},"du":{"a6":[]},"dV":{"H":["c"],"bM":["c"],"G":["c"],"w":["c"],"a":["c"],"H.E":"c","bM.E":"c"},"w":{"a":["1"]},"a4":{"w":["1"],"a":["1"]},"d_":{"a4":["1"],"w":["1"],"a":["1"],"a.E":"1","a4.E":"1"},"c_":{"X":["1"]},"c0":{"a":["2"],"a.E":"2"},"bc":{"c0":["1","2"],"w":["2"],"a":["2"],"a.E":"2"},"c1":{"X":["2"]},"K":{"a4":["2"],"w":["2"],"a":["2"],"a.E":"2","a4.E":"2"},"j":{"a":["1"],"a.E":"1"},"bx":{"X":["1"]},"d0":{"a":["1"],"a.E":"1"},"e_":{"d0":["1"],"w":["1"],"a":["1"],"a.E":"1"},"eq":{"X":["1"]},"c7":{"a":["1"],"a.E":"1"},"dm":{"c7":["1"],"w":["1"],"a":["1"],"a.E":"1"},"eo":{"X":["1"]},"e0":{"w":["1"],"a":["1"],"a.E":"1"},"e1":{"X":["1"]},"b_":{"a":["1"],"a.E":"1"},"et":{"X":["1"]},"cQ":{"a":["+(c,1)"],"a.E":"+(c,1)"},"dl":{"cQ":["1"],"w":["+(c,1)"],"a":["+(c,1)"],"a.E":"+(c,1)"},"e5":{"X":["+(c,1)"]},"dC":{"H":["1"],"bM":["1"],"G":["1"],"w":["1"],"a":["1"]},"p":{"d7":[],"by":[]},"J":{"d7":[],"by":[]},"eE":{"dE":[],"by":[]},"dW":{"er":["1","2"],"dG":["1","2"],"cT":["1","2"],"eL":["1","2"],"t":["1","2"]},"di":{"t":["1","2"]},"u":{"di":["1","2"],"t":["1","2"]},"d4":{"a":["1"],"a.E":"1"},"d5":{"X":["1"]},"b7":{"di":["1","2"],"t":["1","2"]},"dY":{"cw":["1"],"cZ":["1"],"w":["1"],"a":["1"]},"T":{"dY":["1"],"cw":["1"],"cZ":["1"],"w":["1"],"a":["1"]},"ek":{"cd":[],"a6":[]},"fm":{"a6":[]},"fL":{"a6":[]},"eG":{"bL":[]},"cl":{"cN":[]},"eX":{"cN":[]},"eY":{"cN":[]},"fJ":{"cN":[]},"fH":{"cN":[]},"dg":{"cN":[]},"fG":{"a6":[]},"bl":{"S":["1","2"],"mM":["1","2"],"t":["1","2"],"S.K":"1","S.V":"2"},"aJ":{"w":["1"],"a":["1"],"a.E":"1"},"ed":{"X":["1"]},"ai":{"w":["1"],"a":["1"],"a.E":"1"},"ee":{"X":["1"]},"y":{"w":["P<1,2>"],"a":["P<1,2>"],"a.E":"P<1,2>"},"ec":{"X":["P<1,2>"]},"ea":{"bl":["1","2"],"S":["1","2"],"mM":["1","2"],"t":["1","2"],"S.K":"1","S.V":"2"},"d7":{"by":[]},"dE":{"by":[]},"fl":{"l6":[],"fz":[]},"cW":{"ag":[],"ad":[],"a0":[]},"ef":{"ag":[],"ad":[]},"fs":{"ag":[],"nq":[],"ad":[],"a0":[]},"aK":{"be":["1"],"ag":[],"ad":[]},"cu":{"H":["R"],"aK":["R"],"G":["R"],"be":["R"],"ag":[],"w":["R"],"ad":[],"a":["R"],"aa":["R"]},"bf":{"H":["c"],"aK":["c"],"G":["c"],"be":["c"],"ag":[],"w":["c"],"ad":[],"a":["c"],"aa":["c"]},"ft":{"cu":[],"H":["R"],"aK":["R"],"G":["R"],"be":["R"],"ag":[],"w":["R"],"ad":[],"a":["R"],"aa":["R"],"a0":[],"H.E":"R","aa.E":"R"},"fu":{"cu":[],"H":["R"],"aK":["R"],"G":["R"],"be":["R"],"ag":[],"w":["R"],"ad":[],"a":["R"],"aa":["R"],"a0":[],"H.E":"R","aa.E":"R"},"fv":{"bf":[],"H":["c"],"aK":["c"],"G":["c"],"be":["c"],"ag":[],"w":["c"],"ad":[],"a":["c"],"aa":["c"],"a0":[],"H.E":"c","aa.E":"c"},"fw":{"bf":[],"H":["c"],"aK":["c"],"G":["c"],"be":["c"],"ag":[],"w":["c"],"ad":[],"a":["c"],"aa":["c"],"a0":[],"H.E":"c","aa.E":"c"},"fx":{"bf":[],"H":["c"],"aK":["c"],"G":["c"],"be":["c"],"ag":[],"w":["c"],"ad":[],"a":["c"],"aa":["c"],"a0":[],"H.E":"c","aa.E":"c"},"eg":{"bf":[],"H":["c"],"aK":["c"],"G":["c"],"be":["c"],"ag":[],"w":["c"],"ad":[],"a":["c"],"aa":["c"],"a0":[],"H.E":"c","aa.E":"c"},"eh":{"bf":[],"mV":[],"H":["c"],"aK":["c"],"G":["c"],"be":["c"],"ag":[],"w":["c"],"ad":[],"a":["c"],"aa":["c"],"a0":[],"H.E":"c","aa.E":"c"},"ei":{"bf":[],"H":["c"],"aK":["c"],"G":["c"],"be":["c"],"ag":[],"w":["c"],"ad":[],"a":["c"],"aa":["c"],"a0":[],"H.E":"c","aa.E":"c"},"ej":{"bf":[],"mW":[],"H":["c"],"aK":["c"],"G":["c"],"be":["c"],"ag":[],"w":["c"],"ad":[],"a":["c"],"aa":["c"],"a0":[],"H.E":"c","aa.E":"c"},"fQ":{"a6":[]},"dF":{"cd":[],"a6":[]},"h2":{"qw":[]},"d8":{"X":["1"]},"cA":{"a":["1"],"a.E":"1"},"bs":{"a6":[]},"aC":{"cO":["1"]},"eM":{"o_":[]},"fX":{"eM":[],"o_":[]},"bn":{"eF":["1"],"cw":["1"],"nN":["1"],"cZ":["1"],"w":["1"],"a":["1"]},"cg":{"X":["1"]},"H":{"G":["1"],"w":["1"],"a":["1"]},"S":{"t":["1","2"]},"ey":{"w":["2"],"a":["2"],"a.E":"2"},"ez":{"X":["2"]},"cT":{"t":["1","2"]},"er":{"dG":["1","2"],"cT":["1","2"],"eL":["1","2"],"t":["1","2"]},"cw":{"cZ":["1"],"w":["1"],"a":["1"]},"eF":{"cw":["1"],"cZ":["1"],"w":["1"],"a":["1"]},"ex":{"S":["d","@"],"t":["d","@"],"S.K":"d","S.V":"@"},"fT":{"a4":["d"],"w":["d"],"a":["d"],"a.E":"d","a4.E":"d"},"dh":{"c6":["G<c>"]},"eu":{"dh":[],"c6":["G<c>"]},"eb":{"a6":[]},"fo":{"a6":[]},"fn":{"eZ":["I?","d"]},"fq":{"bS":["I?","d"]},"fp":{"bS":["d","I?"]},"fM":{"bS":["d","G<c>"]},"ac":{"ba":["ac"]},"R":{"aW":[],"ba":["aW"]},"a_":{"ba":["a_"]},"c":{"aW":[],"ba":["aW"]},"G":{"w":["1"],"a":["1"]},"aW":{"ba":["aW"]},"l6":{"fz":[]},"cZ":{"w":["1"],"a":["1"]},"d":{"ba":["d"],"fz":[]},"fP":{"O":[]},"eU":{"a6":[]},"cd":{"a6":[]},"br":{"a6":[]},"dz":{"a6":[]},"fh":{"a6":[]},"es":{"a6":[]},"fK":{"a6":[]},"dA":{"a6":[]},"f_":{"a6":[]},"fy":{"a6":[]},"ep":{"a6":[]},"h1":{"bL":[]},"cY":{"a":["c"],"a.E":"c"},"fF":{"X":["c"]},"dB":{"qt":[]},"fW":{"fD":[]},"q6":{"G":["c"],"w":["c"],"a":["c"]},"mW":{"G":["c"],"w":["c"],"a":["c"]},"qA":{"G":["c"],"w":["c"],"a":["c"]},"q4":{"G":["c"],"w":["c"],"a":["c"]},"qz":{"G":["c"],"w":["c"],"a":["c"]},"q5":{"G":["c"],"w":["c"],"a":["c"]},"mV":{"G":["c"],"w":["c"],"a":["c"]},"pR":{"G":["R"],"w":["R"],"a":["R"]},"pS":{"G":["R"],"w":["R"],"a":["R"]},"dj":{"c6":["bU"]},"e4":{"bS":["G<c>","bU"]},"fd":{"c6":["G<c>"]},"fg":{"bS":["G<c>","bU"]},"fS":{"dh":[],"c6":["G<c>"]},"fY":{"e4":[],"bS":["G<c>","bU"]},"h_":{"c6":["G<c>"]},"fZ":{"c6":["G<c>"]},"fV":{"fD":[]},"en":{"fD":[]},"cH":{"O":[]},"bP":{"O":[]},"az":{"O":[]},"bp":{"O":[]},"bq":{"O":[]},"fe":{"O":[]},"av":{"O":[]},"bG":{"O":[]},"bV":{"O":[]},"bb":{"O":[]},"bE":{"O":[]},"dZ":{"O":[]},"b5":{"O":[]},"bY":{"O":[]},"aS":{"O":[]},"a8":{"O":[]},"bX":{"O":[]},"aq":{"O":[]},"cq":{"O":[]},"cs":{"O":[]},"bW":{"O":[]},"c2":{"O":[]},"fE":{"O":[]},"bZ":{"O":[]},"dr":{"O":[]},"e6":{"O":[]},"co":{"O":[]},"e3":{"O":[]},"al":{"O":[]},"cc":{"O":[]},"aD":{"O":[]},"bQ":{"O":[]},"cy":{"O":[]},"c4":{"O":[]},"ct":{"O":[]},"cV":{"O":[]},"ck":{"O":[]},"cL":{"O":[]},"cf":{"O":[]},"cX":{"O":[]},"d1":{"O":[]},"cU":{"O":[]},"cv":{"O":[]}}'))
B.qU(v.typeUniverse,JSON.parse('{"dC":1,"eN":2,"aK":1}'))
var u={z:" caused spectacular temporary chaos, but no possessions were lost.",G:" caused temporary mischief, but nothing was lost.",S:" is waiting in Adventures for a limited time.",q:"A distant bell answers the first light within. This egg belongs to a turning of the year.",r:"A gentle golden warmth lingers around this egg, as if it carries a wish meant for someone truly special.",V:"A strange musical tap answers from within.",A:"A watchful green flame curls around the shell. This egg feels bound to a rare autumn night.",_:"A winter star seems to breathe beneath the shell. This egg carries the warmth of a special hearth.",t:"An Adventure reward is ready in DragonHaven.",w:"Error handler must accept one Object or one Object and a StackTrace as arguments, and return a value of the returned future's type",X:"Every color glimmers without hiding another. This egg feels joyfully, unmistakably special.",T:"Something inside wants to hatch in the Rooftop Nest.",L:"The egg grows restless when the stars appear.",c:"The nest suddenly smells of rain and moss.",M:"Two quiet heartbeats echo through the shell. This egg remembers a promise shared.",i:"You hear something almost like distant waves.",D:"Your Trial board is full. Choose a dragon and chase a new high score."}
var t=(function rtii(){var s=B.W
return{V:s("bC"),lD:s("az"),iV:s("b3"),kr:s("bP"),G:s("aA"),lV:s("bp"),k:s("b4"),dm:s("bq"),bz:s("bQ"),es:s("aP"),p:s("b5"),pd:s("ck"),n:s("bs"),fQ:s("aB<av,av?>"),j4:s("aB<a8,a8?>"),aQ:s("bD"),mW:s("av"),e_:s("cL"),gS:s("dV"),bP:s("ba<@>"),p1:s("u<d,d>"),cq:s("u<d,c>"),M:s("u<d,G<d>>"),O:s("T<d>"),h:s("ac"),R:s("ao"),F:s("h"),Y:s("x"),hX:s("bX"),jS:s("a_"),q:s("w<@>"),ny:s("f9"),aT:s("O"),fz:s("a6"),w:s("cN"),A:s("aQ"),f9:s("bY"),Z:s("b7<aq,c>"),eE:s("a8"),E:s("bH"),iI:s("bZ"),id:s("a<R>"),e7:s("a<@>"),fm:s("a<c>"),iT:s("v<b3>"),D:s("v<aG>"),m1:s("v<aA>"),gT:s("v<b4>"),ge:s("v<bD>"),f_:s("v<ao>"),f1:s("v<aQ>"),hJ:s("v<bH>"),bV:s("v<t<d,@>>"),ke:s("v<t<d,I?>>"),lI:s("v<l>"),b9:s("v<aS>"),hf:s("v<I>"),a:s("v<Y>"),L:s("v<+x,y(R,R)>"),T:s("v<+(c,aD)>"),n0:s("v<ap>"),oL:s("v<ak>"),s:s("v<d>"),mU:s("v<aq>"),co:s("v<al>"),iM:s("v<aZ>"),u:s("v<R>"),dG:s("v<@>"),t:s("v<c>"),v:s("e9"),B:s("ad"),C:s("bd"),dX:s("be<@>"),d9:s("ag"),ew:s("bJ"),bK:s("cq"),jE:s("G<ao>"),bF:s("G<d>"),j:s("G<@>"),I:s("G<c>"),k2:s("P<d,aP>"),gc:s("P<d,d>"),jA:s("P<d,c>"),fH:s("P<d,t<d,@>>"),P:s("t<d,@>"),f:s("t<@,@>"),oo:s("K<ap,d>"),f0:s("K<aq,c>"),oM:s("K<bJ,I?>"),ms:s("cs"),bx:s("cU"),r:s("l"),_:s("aS"),fg:s("cV"),f5:s("ct"),dQ:s("cu"),aj:s("bf"),b:s("aL"),K:s("I"),x:s("Y"),b6:s("cX"),J:s("c3"),jl:s("c4"),lZ:s("tN"),aK:s("+()"),iY:s("+(aP,i,i)"),bj:s("cv"),gi:s("cZ<d>"),jx:s("ap"),bL:s("c6<bU>"),W:s("ak"),l:s("bL"),N:s("d"),jW:s("d(ap)"),bQ:s("d1"),mV:s("cy"),U:s("aq"),gq:s("al"),e:s("aZ"),aJ:s("a0"),do:s("cd"),cx:s("d2"),kB:s("cf"),eL:s("bg"),g1:s("j<b5>"),mA:s("j<h>"),dx:s("j<x>"),d2:s("j<l>"),cO:s("j<aS>"),cG:s("j<ak>"),fT:s("j<c>"),oz:s("bx<Y>"),fs:s("b_<aA>"),fC:s("b_<a8>"),mp:s("b_<al>"),j_:s("aC<@>"),k5:s("cA<t<d,@>>"),y:s("i"),gY:s("i(b5)"),bo:s("i(h)"),hU:s("i(x)"),ae:s("i(l)"),gl:s("i(aS)"),iW:s("i(I)"),gO:s("i(Y)"),g8:s("i(ak)"),gw:s("i(c)"),i:s("R"),z:s("@"),mY:s("@()"),mq:s("@(I)"),ng:s("@(I,bL)"),S:s("c"),hT:s("c(aq)"),oT:s("aA?"),c:s("bD?"),h8:s("dU?"),ca:s("av?"),dq:s("ac?"),gK:s("cO<aL>?"),nB:s("a8?"),cV:s("ad?"),g:s("G<@>?"),dZ:s("t<d,@>?"),d:s("t<@,@>?"),X:s("I?"),nq:s("I?(bJ)"),m:s("Y?"),ga:s("ak?"),jv:s("d?"),o:s("d3<@,@>?"),nF:s("fU?"),fU:s("i?"),jX:s("R?"),aV:s("c?"),kv:s("d?()?"),jh:s("aW?"),cZ:s("aW"),H:s("~"),Q:s("~()"),lc:s("~(d,@)")}})();(function constants(){var s=hunkHelpers.makeConstList
A.jx=J.fi.prototype
A.b=J.v.prototype
A.B=J.e7.prototype
A.a=J.e8.prototype
A.c=J.cR.prototype
A.i=J.cS.prototype
A.jA=J.bd.prototype
A.jB=J.ag.prototype
A.NS=B.eg.prototype
A.NT=B.eh.prototype
A.al=B.ej.prototype
A.cx=J.fA.prototype
A.bD=J.d2.prototype
A.cN=new B.bC("title_supporter_founder")
A.cO=new B.bC("true_colors")
A.bJ=new B.az(0,"welcome")
A.aY=new B.az(1,"activityCompleted")
A.aZ=new B.az(10,"portraitRevealed")
A.b_=new B.az(11,"titleChestPurchased")
A.b0=new B.az(12,"titleRevealed")
A.aE=new B.az(13,"legacy")
A.L=new B.az(2,"bonusFound")
A.aF=new B.az(3,"chestOpened")
A.b1=new B.az(4,"hatched")
A.b2=new B.az(5,"evolved")
A.b3=new B.az(6,"achievement")
A.b4=new B.az(7,"itemPurchased")
A.bK=new B.az(8,"itemPlaced")
A.b5=new B.az(9,"portraitChestPurchased")
A.b6=new B.bP(0,"explore")
A.y=new B.bP(1,"discovery")
A.ab=new B.bP(2,"purchase")
A.ai=new B.bP(3,"milestone")
A.A=new B.bp(4,"special")
A.bZ=new B.a_(2592e8)
A.a5=new B.aq(1,"arcana")
A.aJ=new B.dS()
A.l=new B.av(6,"special")
A.au=new B.a_(9e8)
A.R=new B.a_(864e8)
A.dE=new B.aA("special_new_year_first_dawn",A.A,"The Bell Beyond Midnight","De Klok Voorbij Middernacht",A.bZ,700,A.a5,0,A.l,!1,!0,!0,A.au,A.R,!1)
A.c_=new B.a_(3456e8)
A.a3=new B.aq(2,"spirit")
A.SQ=new B.dS()
A.dF=new B.aA("special_valentine_two_heartlights",A.A,"The Rosebound Crossing","De Rozenverbonden Oversteek",A.c_,650,A.a3,0,A.l,!1,!0,!0,A.au,A.R,!0)
A.ir=new B.a_(3024e8)
A.dG=new B.aA("special_pride_every_color",A.A,"The Aurora We Weave","De Aurora Die Wij Weven",A.ir,700,A.a3,0,A.l,!1,!0,!0,A.au,A.R,!1)
A.ix=new B.a_(864e9)
A.a9=new B.aq(0,"might")
A.aM=new B.a_(36e8)
A.dH=new B.aA("special_golden_wings_birthday",A.A,"A Wish on Golden Wings","Een Wens op Gouden Vleugels",A.ix,500,A.a9,0,A.l,!1,!0,!0,A.aM,A.R,!1)
A.dI=new B.aA("special_christmas_winter_hearth",A.A,"The Starlight Sleigh","De Sterrenlichtslee",A.c_,600,A.a3,0,A.l,!1,!0,!0,A.au,A.R,!1)
A.dJ=new B.aA("special_halloween_witchlight",A.A,"Roots Beneath the Lanterns","Wortels Onder de Lantaarns",A.bZ,500,A.a5,0,A.l,!1,!0,!0,A.au,A.R,!1)
A.q=new B.bp(0,"mini")
A.o=new B.bp(1,"short")
A.z=new B.bp(2,"long")
A.W=new B.bp(3,"group")
A.as=new B.bq(0,"running")
A.aG=new B.bq(1,"rewardReady")
A.dK=new B.bQ(0,"started")
A.bL=new B.bQ(1,"eggCannotAdventure")
A.dL=new B.bQ(2,"dragonBusy")
A.bM=new B.bQ(3,"groupNeedsFriends")
A.bN=new B.bQ(5,"unavailable")
A.aH=new B.aP(!1,0,!1,!1,!1,!1)
A.bO=new B.b5(3,"weaveOracle")
A.aI=new B.b5(4,"nameweaversQuill")
A.dP=new B.ck(0,"revealed")
A.dQ=new B.ck(1,"notOwned")
A.dR=new B.ck(2,"eggNotFound")
A.dS=new B.ck(3,"alreadyKnown")
A.dT=new B.e1(B.W("e1<0&>"))
A.bP=new B.fa()
A.dU=new B.fa()
A.bR=function getTagFallback(o) {
  var s = Object.prototype.toString.call(o);
  return s.substring(8, s.length - 1);
}
A.dV=function() {
  var toStringFunction = Object.prototype.toString;
  function getTag(o) {
    var s = toStringFunction.call(o);
    return s.substring(8, s.length - 1);
  }
  function getUnknownTag(object, tag) {
    if (/^HTML[A-Z].*Element$/.test(tag)) {
      var name = toStringFunction.call(object);
      if (name == "[object Object]") return null;
      return "HTMLElement";
    }
  }
  function getUnknownTagGenericBrowser(object, tag) {
    if (object instanceof HTMLElement) return "HTMLElement";
    return getUnknownTag(object, tag);
  }
  function prototypeForTag(tag) {
    if (typeof window == "undefined") return null;
    if (typeof window[tag] == "undefined") return null;
    var constructor = window[tag];
    if (typeof constructor != "function") return null;
    return constructor.prototype;
  }
  function discriminator(tag) { return null; }
  var isBrowser = typeof HTMLElement == "function";
  return {
    getTag: getTag,
    getUnknownTag: isBrowser ? getUnknownTagGenericBrowser : getUnknownTag,
    prototypeForTag: prototypeForTag,
    discriminator: discriminator };
}
A.e_=function(getTagFallback) {
  return function(hooks) {
    if (typeof navigator != "object") return hooks;
    var userAgent = navigator.userAgent;
    if (typeof userAgent != "string") return hooks;
    if (userAgent.indexOf("DumpRenderTree") >= 0) return hooks;
    if (userAgent.indexOf("Chrome") >= 0) {
      function confirm(p) {
        return typeof window == "object" && window[p] && window[p].name == p;
      }
      if (confirm("Window") && confirm("HTMLElement")) return hooks;
    }
    hooks.getTag = getTagFallback;
  };
}
A.dW=function(hooks) {
  if (typeof dartExperimentalFixupGetTag != "function") return hooks;
  hooks.getTag = dartExperimentalFixupGetTag(hooks.getTag);
}
A.dZ=function(hooks) {
  if (typeof navigator != "object") return hooks;
  var userAgent = navigator.userAgent;
  if (typeof userAgent != "string") return hooks;
  if (userAgent.indexOf("Firefox") == -1) return hooks;
  var getTag = hooks.getTag;
  var quickMap = {
    "BeforeUnloadEvent": "Event",
    "DataTransfer": "Clipboard",
    "GeoGeolocation": "Geolocation",
    "Location": "!Location",
    "WorkerMessageEvent": "MessageEvent",
    "XMLDocument": "!Document"};
  function getTagFirefox(o) {
    var tag = getTag(o);
    return quickMap[tag] || tag;
  }
  hooks.getTag = getTagFirefox;
}
A.dY=function(hooks) {
  if (typeof navigator != "object") return hooks;
  var userAgent = navigator.userAgent;
  if (typeof userAgent != "string") return hooks;
  if (userAgent.indexOf("Trident/") == -1) return hooks;
  var getTag = hooks.getTag;
  var quickMap = {
    "BeforeUnloadEvent": "Event",
    "DataTransfer": "Clipboard",
    "HTMLDDElement": "HTMLElement",
    "HTMLDTElement": "HTMLElement",
    "HTMLPhraseElement": "HTMLElement",
    "Position": "Geoposition"
  };
  function getTagIE(o) {
    var tag = getTag(o);
    var newTag = quickMap[tag];
    if (newTag) return newTag;
    if (tag == "Object") {
      if (window.DataView && (o instanceof window.DataView)) return "DataView";
    }
    return tag;
  }
  function prototypeForTagIE(tag) {
    var constructor = window[tag];
    if (constructor == null) return null;
    return constructor.prototype;
  }
  hooks.getTag = getTagIE;
  hooks.prototypeForTag = prototypeForTagIE;
}
A.dX=function(hooks) {
  var getTag = hooks.getTag;
  var prototypeForTag = hooks.prototypeForTag;
  function getTagFixed(o) {
    var tag = getTag(o);
    if (tag == "Document") {
      if (!!o.xmlVersion) return "!Document";
      return "!HTMLDocument";
    }
    return tag;
  }
  function prototypeForTagFixed(tag) {
    if (tag == "Document") return null;
    return prototypeForTag(tag);
  }
  hooks.getTag = getTagFixed;
  hooks.prototypeForTag = prototypeForTagFixed;
}
A.bQ=function(hooks) { return hooks; }

A.k=new B.fn()
A.e0=new B.fy()
A.at=new B.l7()
A.e1=new B.fM()
A.ac=new B.fX()
A.e2=new B.fY()
A.e3=new B.h1()
A.F=new B.av(0,"wooden")
A.M=new B.av(1,"silver")
A.t=new B.av(2,"gold")
A.G=new B.av(3,"dragon")
A.H=new B.av(4,"mythical")
A.a4=new B.av(5,"sinister")
A.u=new B.av(7,"portrait")
A.v=new B.av(8,"title")
A.p=new B.av(9,"music")
A.e4=new B.cL(0,"accelerated")
A.e5=new B.cL(1,"notOwned")
A.e6=new B.cL(2,"noEggInNest")
A.d=new B.bV(0,"chest")
A.m=new B.bE(0,"common")
A.Q=new B.bE(1,"uncommon")
A.ad=new B.bE(2,"rare")
A.aK=new B.bE(3,"veryRare")
A.b7=new B.bE(4,"legendary")
A.aL=new B.bE(5,"mythical")
A.a6=new B.bE(6,"specialEvent")
A.bS=new B.bW(0,"inTraining")
A.b8=new B.bW(1,"dropout")
A.bT=new B.bW(2,"graduate")
A.bU=new B.bW(3,"honorsGraduate")
A.bV=new B.bW(4,"highHonors")
A.b9=new B.bW(5,"valedictorian")
A.bW=new B.dZ(0,"male")
A.bX=new B.dZ(1,"female")
A.h=new B.bX(0,"egg")
A.aj=new B.bX(1,"hatchling")
A.a7=new B.bX(2,"wyrmling")
A.I=new B.bX(3,"ascended")
A.ba=new B.a_(0)
A.iu=new B.a_(6e7)
A.c2=new B.a_(72e8)
A.iz=new B.aE("already_known")
A.iA=new B.aE("altar_busy")
A.iB=new B.aE("altar_pending")
A.bc=new B.aE("altar_sign_in_required")
A.c3=new B.aE("egg_not_found")
A.iC=new B.aE("egg_reserved")
A.iD=new B.aE("insufficient_materials")
A.iE=new B.aE("invalid_action")
A.iF=new B.aE("invalid_name")
A.c4=new B.aE("invalid_relic")
A.c5=new B.aE("relic_not_owned")
A.iG=new B.aE("sinister_confirmation_required")
A.iH=new B.aI("Missing Chronoshard identities",null)
A.iI=new B.aI("Wrong Altar owner",null)
A.iJ=new B.aI("Unsupported canonical game state",null)
A.iK=new B.aI("Invalid Chronoshard identity",null)
A.iL=new B.aI("Unresolved Altar operation",null)
A.iM=new B.aI("Invalid canonical inventory count",null)
A.iN=new B.aI("Invalid game timestamp",null)
A.iO=new B.aI("Invalid canonical game object",null)
A.iP=new B.aI("Invalid or duplicate game identity",null)
A.iQ=new B.aI("Invalid game inventory",null)
A.iR=new B.co(0,"none")
A.iS=new B.co(1,"warm")
A.iT=new B.co(2,"cool")
A.iU=new B.co(3,"fire")
A.iV=new B.co(4,"arcane")
A.iW=new B.bj("game_state_reconciliation_required")
A.iX=new B.bj("game_state_owner_mismatch")
A.aN=new B.bj("invalid_argument")
A.c6=new B.bj("invalid_command")
A.iY=new B.bj("special_chest_id_required")
A.c7=new B.bj("unknown_adventure")
A.iZ=new B.bj("unknown_item")
A.j_=new B.bj("unknown_room")
A.j0=new B.b6("game_import_offline_altar_review")
A.j1=new B.b6("game_import_returned_nest_conflict")
A.j2=new B.b6("game_import_returned_dragon_conflict")
A.j3=new B.b6("game_import_return_history_conflict")
A.j4=new B.b6("game_import_altar_invalid")
A.c8=new B.b6("game_import_foreign_altar")
A.j5=new B.b6("game_import_owner_invalid")
A.j6=new B.b6("game_import_pending_altar")
A.j7=new B.b6("game_import_altar_snapshot_missing")
A.j8=new B.b6("game_import_altar_snapshot_stale")
A.j9=new B.b6("game_import_protected_return_conflict")
A.c9=new B.bY(0,"hatch")
A.ca=new B.bY(1,"evolution")
A.cb=new B.bY(2,"trade")
A.aO=new B.bY(3,"achievement")
A.ja=new B.bG(0,"deepNight")
A.jb=new B.bG(1,"dawn")
A.jc=new B.bG(2,"morning")
A.jd=new B.bG(3,"day")
A.cc=new B.bG(4,"goldenHour")
A.je=new B.bG(5,"dusk")
A.jf=new B.bG(6,"night")
A.cd=new B.fe(0,"classic")
A.bd=new B.a8(10,"specialEvents")
A.ce=new B.a8(5,"friendMessages")
A.w=new B.e6(0,"coins")
A.be=new B.e6(1,"gems")
A.jy=new B.dr(0,"common")
A.jz=new B.dr(1,"special")
A.cf=new B.dr(2,"rare")
A.X=new B.bZ(0,"bed")
A.Y=new B.bZ(1,"plant")
A.Z=new B.bZ(2,"wall")
A.S=new B.bZ(3,"light")
A.jC=new B.fp(null)
A.jD=new B.fq(null)
A.T=new B.cq(0,"lawful")
A.a_=new B.cq(1,"neutral")
A.a0=new B.cq(2,"chaotic")
A.bb=new B.a_(1728e8)
A.az=new B.aS(0,"moralPrism")
A.aA=new B.aS(1,"orderCompass")
A.aB=new B.aS(2,"soulMirror")
A.ak=new B.aS(3,"astralLens")
A.I3=s([A.az,A.aA,A.aB,A.ak],t.b9)
A.Mi=new B.b7([A.a9,25,A.a3,25,A.a5,25],t.Z)
A.Rn=new B.cx(A.I3,!0,A.Mi,"golden_wings_chest_v1",null,null)
A.T0=new B.a_(432e9)
A.Rf=new B.c8("golden_wings_birthday","special_golden_wings_birthday",2026,9,1,0,A.bb,2027,5,13,0,A.R,A.Rn,"",0,"")
A.c1=new B.a_(6912e8)
A.av=s([],t.b9)
A.Mh=new B.b7([A.a9,13,A.a3,13,A.a5,13],t.Z)
A.Rl=new B.cx(A.av,!1,A.Mh,"witchlight_chest_v1",null,null)
A.Re=new B.c8("halloween_witchlight","special_halloween_witchlight",2026,10,25,0,A.c1,2027,10,25,0,A.c1,A.Rl,"witchlightWard",48,"event_witchlight_nocturne")
A.Mf=new B.b7([A.a9,12,A.a3,12,A.a5,12],t.Z)
A.Ro=new B.cx(A.av,!1,A.Mf,"starlight_gift_chest_v1",null,null)
A.Ri=new B.c8("christmas_winter_hearth","special_christmas_winter_hearth",2026,12,25,0,A.bb,2027,12,25,0,A.bb,A.Ro,"hollyfrostGiftforge",48,"event_winter_hearth_carol")
A.bY=new B.a_(108e9)
A.cv=new B.b7([A.a9,10,A.a3,10,A.a5,10],t.Z)
A.Rm=new B.cx(A.av,!1,A.cv,"firstlight_celebration_chest_v1",null,null)
A.Rd=new B.c8("new_year_first_dawn","special_new_year_first_dawn",2026,12,31,18,A.bY,2027,12,31,18,A.bY,A.Rm,"midnightChime",48,"event_first_dawn_waltz")
A.Mg=new B.b7([A.a9,8,A.a3,8,A.a5,8],t.Z)
A.Rk=new B.cx(A.av,!1,A.Mg,"twinheart_keepsake_chest_v1",null,"heartbound_pair")
A.Rh=new B.c8("valentine_two_heartlights","special_valentine_two_heartlights",2027,2,14,0,A.R,2028,2,14,0,A.R,A.Rk,"rosevowRelay",48,"event_rosebound_romance")
A.c0=new B.a_(6048e8)
A.Rj=new B.cx(A.av,!1,A.cv,"radiant_festival_chest_v1","true_colors",null)
A.Rg=new B.c8("pride_every_color","special_pride_every_color",2027,6,1,0,A.c0,2028,6,1,0,A.c0,A.Rj,"prismaticParade",48,"event_every_color_festival")
A.bf=s([A.Rf,A.Re,A.Ri,A.Rd,A.Rh,A.Rg],B.W("v<c8>"))
A.a8=new B.aS(4,"chronoshard")
A.aC=new B.aS(5,"wayfinderSigil")
A.x=new B.aS(6,"twinstarBrooch")
A.ae=s([A.az,A.aA,A.aB,A.ak,A.a8,A.aC,A.x],t.b9)
A.E=new B.aD(5,"visit")
A.cD=new B.p(30,A.E)
A.V=new B.aD(6,"special")
A.cE=new B.p(30,A.V)
A.ah=new B.aD(7,"nothing")
A.Pr=new B.p(40,A.ah)
A.ky=s([A.cD,A.cE,A.Pr],t.T)
A.l9=s([A.c9,A.ca,A.cb,A.aO],B.W("v<bY>"))
A.lc=s([0.25,0.55,0.8,0.95,0.995],t.u)
A.aa=new B.aD(8,"mischief")
A.Pw=new B.p(45,A.aa)
A.bI=new B.aD(9,"minorDamage")
A.P9=new B.p(25,A.bI)
A.aW=new B.aD(12,"sinister")
A.bu=new B.p(20,A.aW)
A.bH=new B.aD(13,"spotted")
A.br=new B.p(10,A.bH)
A.lp=s([A.Pw,A.P9,A.bu,A.br],t.T)
A.lu=s([A.X,A.Y,A.Z,A.S],B.W("v<bZ>"))
A.ag=new B.al(0,"cavernFlight")
A.an=new B.al(1,"ruinBreaker")
A.ao=new B.al(2,"runeweaver")
A.lQ=s([A.ag,A.an,A.ao],t.co)
A.PC=new B.p(50,A.aa)
A.P4=new B.p(20,A.bI)
A.OS=new B.p(15,A.aW)
A.OT=new B.p(15,A.bH)
A.lU=s([A.PC,A.P4,A.OS,A.OT],t.T)
A.mW=s([A.as,A.aG],B.W("v<bq>"))
A.n7=s([0.5,0.8,0.94,0.99,0.999],t.u)
A.ne=s([0.65,0.9,0.98,0.997,0.9998],t.u)
A.nC=s(["chestInventory","specialChestInventory","relicInventory","untradeableRelicInventory"],t.s)
A.nI=s(["id","name","xp","stage","firstEgg","spectral","sinister","sizeFactor","favorite","sex","highlightedExpertises","roamsTower","currentRoomId","currentFloorIndex","activeAdventureId","joy","energy","comfort","acquiredAt","stageStartedAt","needsUpdatedAt","training","trialHighScores","dragonSchoolRecords","dragonSchoolStars","dragonSchoolAttempts","dragonSchoolFinalizedEarly","dragonSchoolMentorLessons","lineageId","evolutionPath"],t.s)
A.ap=new B.aD(1,"silver")
A.Po=new B.p(40,A.ap)
A.aq=new B.aD(2,"gold")
A.cC=new B.p(25,A.aq)
A.ar=new B.aD(3,"dragon")
A.PG=new B.p(5,A.ar)
A.aX=new B.aD(4,"mythical")
A.P_=new B.p(1,A.aX)
A.OQ=new B.p(14,A.E)
A.OV=new B.p(15,A.V)
A.nN=s([A.Po,A.cC,A.PG,A.P_,A.OQ,A.OV],t.T)
A.by=new B.al(3,"witchlightWard")
A.bz=new B.al(4,"hollyfrostGiftforge")
A.bA=new B.al(5,"midnightChime")
A.bB=new B.al(6,"rosevowRelay")
A.bC=new B.al(7,"prismaticParade")
A.cg=s([A.ag,A.an,A.ao,A.by,A.bz,A.bA,A.bB,A.bC],t.co)
A.p_=s(["chestInventory","specialChestInventory","relicInventory","untradeableRelicInventory","chronoshardReductions","twinstarBroochEverObtained","twinstarBroochDragonId","reservedOnlineTradeEggIds","reservedOnlineTradeChests","reservedOnlineTradeRelics"],t.s)
A.p4=s(["trialRefilledAt","trialStreakCount","trialStreakLastDayKey","trialStreakLastCompletionDayKey","trialStreakRewardReady"],t.s)
A.bE=new B.aD(0,"wooden")
A.PR=new B.p(80,A.bE)
A.OR=new B.p(15,A.ap)
A.bw=new B.p(5,A.E)
A.qa=s([A.PR,A.OR,A.bw],t.T)
A.rh=s([1116352408,1899447441,3049323471,3921009573,961987163,1508970993,2453635748,2870763221,3624381080,310598401,607225278,1426881987,1925078388,2162078206,2614888103,3248222580,3835390401,4022224774,264347078,604807628,770255983,1249150122,1555081692,1996064986,2554220882,2821834349,2952996808,3210313671,3336571891,3584528711,113926993,338241895,666307205,773529912,1294757372,1396182291,1695183700,1986661051,2177026350,2456956037,2730485921,2820302411,3259730800,3345764771,3516065817,3600352804,4094571909,275423344,430227734,506948616,659060556,883997877,958139571,1322822218,1537002063,1747873779,1955562222,2024104815,2227730452,2361852424,2428436474,2756734187,3204031479,3329325298],t.t)
A.rU=s(["id","kind","appearedAt","specialEventKey","startedAt"],t.s)
A.PL=new B.p(60,A.E)
A.bt=new B.p(10,A.ah)
A.t0=s([A.PL,A.cE,A.bt],t.T)
A.tf=s(["acquiredAt","stageStartedAt","needsUpdatedAt"],t.s)
A.to=s(["ownedPortraitIds","selectedPortraitId","ownedTitleIds","selectedTitleId","ownedMusicTrackIds","supporterPackOwned","ownedBadgeIds","selectedBadgeId","ownedFrameIds","selectedFrameId","ownedDragonEmoteIds","ownedDragonEmotePackIds","discoveredForms","prismaticForms","achievements"],t.s)
A.bF=new B.aD(10,"damage")
A.Pt=new B.p(45,A.bF)
A.P8=new B.p(25,A.aa)
A.aT=new B.p(25,A.aW)
A.aD=new B.p(5,A.bH)
A.tx=s([A.Pt,A.P8,A.aT,A.aD],t.T)
A.J=s([A.T,A.a_,A.a0],B.W("v<cq>"))
A.Pb=new B.p(30,A.ap)
A.Pe=new B.p(30,A.aq)
A.P0=new B.p(20,A.ar)
A.Px=new B.p(4,A.aX)
A.PN=new B.p(6,A.E)
A.bs=new B.p(10,A.V)
A.tU=s([A.Pb,A.Pe,A.P0,A.Px,A.PN,A.bs],t.T)
A.n=s([],t.s)
A.T2=new B.e3(0,"none")
A.R1=new B.ap("moss_cushion","Moss cushion",A.X,120,A.w)
A.R5=new B.ap("cloud_basket","Cloud basket",A.X,280,A.w)
A.R2=new B.ap("moon_fern","Moon fern",A.Y,80,A.w)
A.R4=new B.ap("star_bonsai","Star bonsai",A.Y,340,A.w)
A.Rb=new B.ap("spire_map","Spire map",A.Z,160,A.w)
A.Ra=new B.ap("moon_banner","Moon banner",A.Z,300,A.w)
A.T4=s(["magic","fireplace"],t.s)
A.T3=new B.e3(2,"duskAndNight")
A.R6=new B.ap("firefly_lamp","Firefly lamp",A.S,220,A.w)
A.FO=s(["magic"],t.s)
A.R7=new B.ap("crystal_lantern","Crystal lantern",A.S,450,A.w)
A.uc=s([A.R1,A.R5,A.R2,A.R4,A.Rb,A.Ra,A.R6,A.R7],t.n0)
A.up=s(["adventureOptionIds","miniAdventureRefilledAt","shortAdventureRefilledAt","longAdventureRefillDay"],t.s)
A.uV=s(["ownedItemIds","equippedItemIds","unlockedRoomIds","activeRoomId","towerFloorRoomIds","dragonWardLevel","damagedTowerFloors","damagedTowerRepairFactors","returningVisitors","returningSpecialAdventureId","returningSpecialAvailableUntil"],t.s)
A.N=new B.bV(3,"cozyPack")
A.hC=new B.dk("cozy_hatchlings","emote_pack_cozy_199","Cozy Hatchlings",A.N)
A.O=new B.bV(4,"infernalPack")
A.hB=new B.dk("infernal_reactions","emote_pack_infernal_199","Infernal Reactions",A.O)
A.P=new B.bV(5,"celestialPack")
A.hA=new B.dk("celestial_court","emote_pack_celestial_199","Celestial Court",A.P)
A.v3=s([A.hC,A.hB,A.hA],B.W("v<dk>"))
A.v4=s([250,600,1100,1700,2500],t.t)
A.Nb=new B.l("clair_de_lune","Clair de Lune",null,null)
A.Nf=new B.l("arabesque_1","Arabesque No. 1",null,null)
A.Mw=new B.l("reverie","R\xeaverie",null,null)
A.Na=new B.l("flaxen_hair","The Girl with the Flaxen Hair",null,null)
A.MX=new B.l("golliwoggs_cakewalk","Golliwogg's Cakewalk",null,null)
A.N7=new B.l("gymnopedie_1","Gymnop\xe9die No. 1",null,null)
A.MF=new B.l("gymnopedie_2","Gymnop\xe9die No. 2",null,null)
A.Np=new B.l("gymnopedie_3","Gymnop\xe9die No. 3",null,null)
A.NJ=new B.l("gnossienne_1","Gnossienne No. 1",null,null)
A.NI=new B.l("gnossienne_3","Gnossienne No. 3",null,null)
A.MS=new B.l("je_te_veux","Je te veux",null,null)
A.MR=new B.l("fur_elise","F\xfcr Elise",null,null)
A.MK=new B.l("moonlight_1","Moonlight Sonata \u2013 I",null,null)
A.Nw=new B.l("moonlight_3","Moonlight Sonata \u2013 III",null,null)
A.N0=new B.l("pathetique_2","Path\xe9tique Sonata \u2013 II",null,null)
A.Nl=new B.l("ode_to_joy","Ode to Joy",null,null)
A.Ne=new B.l("symphony_5_1","Symphony No. 5 \u2013 I",null,null)
A.MP=new B.l("symphony_7_2","Symphony No. 7 \u2013 II",null,null)
A.Nm=new B.l("eine_kleine_nachtmusik","Eine kleine Nachtmusik",null,null)
A.Nq=new B.l("rondo_alla_turca","Rondo Alla Turca",null,null)
A.Mt=new B.l("symphony_40_1","Symphony No. 40 \u2013 I",null,null)
A.NK=new B.l("sonata_k545_1","Piano Sonata K.545 \u2013 I",null,null)
A.Nu=new B.l("lacrimosa","Lacrimosa",null,null)
A.NB=new B.l("dies_irae","Dies Irae \u2013 Requiem",null,null)
A.Mu=new B.l("ave_verum","Ave Verum Corpus",null,null)
A.Mr=new B.l("canon_in_d","Canon in D",null,null)
A.NC=new B.l("air_g_string","Air on the G String",null,null)
A.NA=new B.l("prelude_c_major","Prelude in C Major",null,null)
A.MA=new B.l("toccata_fugue_d_minor","Toccata and Fugue in D Minor",null,null)
A.MZ=new B.l("cello_suite_1_prelude","Cello Suite No. 1 Prelude",null,null)
A.MN=new B.l("jesu_joy","Jesu, Joy of Man's Desiring",null,null)
A.Nc=new B.l("badinerie","Badinerie",null,null)
A.No=new B.l("minuet_g_major","Minuet in G Major (BWV Anh.114)",null,null)
A.N2=new B.l("spring","Spring \u2013 Four Seasons",null,null)
A.MW=new B.l("summer_presto","Summer \u2013 Presto",null,null)
A.Mz=new B.l("autumn_1","Autumn \u2013 I",null,null)
A.ML=new B.l("winter_1","Winter \u2013 I",null,null)
A.MO=new B.l("winter_2","Winter \u2013 II",null,null)
A.My=new B.l("sugar_plum","Dance of the Sugar Plum Fairy",null,null)
A.MB=new B.l("waltz_flowers","Waltz of the Flowers",null,null)
A.ND=new B.l("trepak","Trepak",null,null)
A.N6=new B.l("swan_lake_scene","Swan Lake \u2013 Scene",null,null)
A.MI=new B.l("sleeping_beauty_waltz","Sleeping Beauty Waltz",null,null)
A.NG=new B.l("1812_finale","1812 Overture \u2013 Finale",null,null)
A.N4=new B.l("mountain_king","In the Hall of the Mountain King",null,null)
A.Nx=new B.l("morning_mood","Morning Mood",null,null)
A.Mx=new B.l("anitras_dance","Anitra's Dance",null,null)
A.NF=new B.l("solveigs_song","Solveig's Song",null,null)
A.Nj=new B.l("nocturne_9_2","Nocturne Op. 9 No. 2",null,null)
A.Nv=new B.l("prelude_28_4","Prelude Op. 28 No. 4",null,null)
A.N8=new B.l("raindrop_prelude","Prelude Op. 28 No. 15 \u201cRaindrop\u201d",null,null)
A.NL=new B.l("minute_waltz","Waltz Op. 64 No. 1 \u201cMinute Waltz\u201d",null,null)
A.N_=new B.l("funeral_march","Funeral March",null,null)
A.MT=new B.l("fantaisie_impromptu","Fantaisie-Impromptu",null,null)
A.Nh=new B.l("hungarian_dance_5","Hungarian Dance No. 5",null,null)
A.Ni=new B.l("hungarian_dance_6","Hungarian Dance No. 6",null,null)
A.MQ=new B.l("lullaby","Lullaby (Wiegenlied)",null,null)
A.MG=new B.l("blue_danube","The Blue Danube",null,null)
A.Nn=new B.l("tritsch_tratsch","Tritsch-Tratsch-Polka",null,null)
A.N9=new B.l("radetzky_march","Radetzky March",null,null)
A.Mv=new B.l("can_can","Can-Can",null,null)
A.Nd=new B.l("barcarolle","Barcarolle",null,null)
A.MV=new B.l("ride_valkyries","Ride of the Valkyries",null,null)
A.NE=new B.l("bridal_chorus","Bridal Chorus",null,null)
A.MU=new B.l("bumblebee","Flight of the Bumblebee",null,null)
A.MM=new B.l("scheherazade_prince_princess","Scheherazade \u2013 Young Prince and Princess",null,null)
A.Nr=new B.l("procession_nobles","Procession of the Nobles",null,null)
A.Nt=new B.l("entertainer","The Entertainer",null,null)
A.MC=new B.l("maple_leaf_rag","Maple Leaf Rag",null,null)
A.Ng=new B.l("easy_winners","The Easy Winners",null,null)
A.Nz=new B.l("solace","Solace",null,null)
A.Nk=new B.l("elite_syncopations","Elite Syncopations",null,null)
A.ME=new B.l("greensleeves","Greensleeves",null,null)
A.MH=new B.l("scarborough_fair","Scarborough Fair",null,null)
A.Ny=new B.l("drunken_sailor","Drunken Sailor",null,null)
A.Mq=new B.l("irish_washerwoman","The Irish Washerwoman",null,null)
A.Ns=new B.l("korobeiniki","Korobeiniki",null,null)
A.N3=new B.l("house_rising_sun","House of the Rising Sun",null,null)
A.N5=new B.l("amazing_grace","Amazing Grace",null,null)
A.MY=new B.l("auld_lang_syne","Auld Lang Syne",null,null)
A.bg=s([A.Nb,A.Nf,A.Mw,A.Na,A.MX,A.N7,A.MF,A.Np,A.NJ,A.NI,A.MS,A.MR,A.MK,A.Nw,A.N0,A.Nl,A.Ne,A.MP,A.Nm,A.Nq,A.Mt,A.NK,A.Nu,A.NB,A.Mu,A.Mr,A.NC,A.NA,A.MA,A.MZ,A.MN,A.Nc,A.No,A.N2,A.MW,A.Mz,A.ML,A.MO,A.My,A.MB,A.ND,A.N6,A.MI,A.NG,A.N4,A.Nx,A.Mx,A.NF,A.Nj,A.Nv,A.N8,A.NL,A.N_,A.MT,A.Nh,A.Ni,A.MQ,A.MG,A.Nn,A.N9,A.Mv,A.Nd,A.MV,A.NE,A.MU,A.MM,A.Nr,A.Nt,A.MC,A.Ng,A.Nz,A.Nk,A.ME,A.MH,A.Ny,A.Mq,A.Ns,A.N3,A.N5,A.MY],t.lI)
A.PP=new B.p(70,A.E)
A.P2=new B.p(20,A.V)
A.ve=s([A.PP,A.P2,A.bt],t.T)
A.Sf=new B.bm("cushion","cushion","kussen","A plump resting spot woven with themed magic.","Een volle rustplek, geweven met thematische magie.",A.X)
A.Sj=new B.bm("daybed","daybed","rustbed","A roomy dragon bed for naps between adventures.","Een ruim drakenbed voor dutjes tussen avonturen.",A.X)
A.Si=new B.bm("planter","planter","plantenpot","A living accent that changes the feeling of a room.","Levend groen dat de sfeer van een kamer verandert.",A.Y)
A.Sk=new B.bm("bonsai","bonsai","bonsai","A tiny enchanted tree with a strong personality.","Een betoverd boompje met een sterke persoonlijkheid.",A.Y)
A.Sl=new B.bm("tapestry","tapestry","wandkleed","A hand-finished wall piece for a grander room.","Een handgemaakt wandstuk voor een statige kamer.",A.Z)
A.Sm=new B.bm("shelf","curio shelf","pronkkastje","A wall shelf filled with harmless little mysteries.","Een wandplank vol ongevaarlijke kleine mysteries.",A.Z)
A.Sh=new B.bm("lantern","glow lantern","gloedlantaarn","A warm magical light with its own soft color.","Een warm magisch licht met een eigen zachte kleur.",A.S)
A.Sg=new B.bm("orb","magic orb","magische bol","A floating spark of room-sized atmosphere.","Een zwevende vonk die de hele kamer sfeer geeft.",A.S)
A.vU=s([A.Sf,A.Sj,A.Si,A.Sk,A.Sl,A.Sm,A.Sh,A.Sg],B.W("v<bm>"))
A.aP=s(["Wolkenboomgaard","Fluisterru\xefnes","Maanlichtmeer","Gloedpas","Kristalholte","Zilveren Kruinen","Klokkenwoud","Sterrenvalkust","Mospoort","Verzonken Archief","Aurorarug","Lantaarnmoeras","Dondervlakte","Saffiergrot","Dageraadvallei","Komeettuin","Vergeten Klokkentoren","Dromende Duinen","Getijdenwacht","Runenmarkt"],t.s)
A.T5=new B.fE(1,"seasonalEventPreview")
A.Qu=new B.c5("HALLOWEENEVENT","halloween_witchlight",null)
A.Qw=new B.c5("CHRISTMASEVENT","christmas_winter_hearth","DH-17792DC5")
A.Qx=new B.c5("NEWYEARSEVENT","new_year_first_dawn","DH-17792DC5")
A.Qy=new B.c5("VALENTINEEVENT","valentine_two_heartlights","DH-17792DC5")
A.Qv=new B.c5("PRIDEFESTEVENT","pride_every_color","DH-17792DC5")
A.wu=s([A.Qu,A.Qw,A.Qx,A.Qy,A.Qv],B.W("v<c5>"))
A.wJ=s(["name","stage","firstEgg","lineageId","hatchSeed","sinister","lawAxis","moralAxis","lawAxisKnown","moralAxisKnown","personalityKnown","personalityTraitIds","sizeFactor","xp","training","evolutionPath","trialHighScores","dragonSchoolRecords","dragonSchoolStars","dragonSchoolAttempts","dragonSchoolFinalizedEarly","dragonSchoolMentorLessons","specialEggId","altarKnowledge"],t.s)
A.ON=new B.p(100,A.ah)
A.wS=s([A.ON],t.T)
A.C=new B.cs(0,"good")
A.U=new B.cs(1,"neutral")
A.D=new B.cs(2,"evil")
A.a1=s([A.C,A.U,A.D],B.W("v<cs>"))
A.x1=s(["ownedPortraitIds","ownedTitleIds","ownedMusicTrackIds","ownedItemIds","ownedDragonEmoteIds","ownedDragonEmotePackIds","ownedBadgeIds","ownedFrameIds","unlockedRoomIds","achievements","discoveredForms","prismaticForms","eggRarityRevealedIds","appliedVerifiedPurchaseIds","appliedOnlineGroupRewardIds","appliedOnlineTradeIds","appliedOnlineSeasonalPairRewardIds","appliedSeasonalPrizeIds","startedSeasonalSpecialEventKeys","trialStreakCreditedDayKeys","reservedOnlineTradeEggIds"],t.s)
A.xo=s([A.bJ,A.aY,A.L,A.aF,A.b1,A.b2,A.b3,A.b4,A.bK,A.b5,A.aZ,A.b_,A.b0,A.aE],B.W("v<az>"))
A.xu=s([3,6,9,12,15],t.t)
A.xB=s([0.1,0.3,0.55,0.8,0.97],t.u)
A.xJ=s([A.q,A.o,A.z,A.W,A.A],B.W("v<bp>"))
A.cG=new B.p(50,A.E)
A.cF=new B.p(40,A.V)
A.xO=s([A.cG,A.cF,A.bt],t.T)
A.bh=s(["eggStash","sanctuaryDragons","releasedDragons"],t.s)
A.P7=new B.p(25,A.V)
A.bv=new B.p(25,A.ah)
A.xX=s([A.cG,A.P7,A.bv],t.T)
A.y0=s(["tutorialCompleted","tutorialFullyViewed","totalHatched","totalNamed","totalWyrmling","totalAscended","totalChestsOpened","totalPortraitChestsOpened","totalTitleChestsOpened","totalMusicChestsOpened","totalAdventuresCompleted","totalShortAdventuresCompleted","totalGroupFourCompleted","totalReleasedReturns","totalSinisterAdventuresCompleted","favoriteChanges","dragonSchoolRecords","seasonalPodiumEmoteWinCounts"],t.s)
A.bG=new B.aD(11,"majorDamage")
A.PA=new B.p(50,A.bG)
A.OW=new B.p(15,A.aa)
A.Pc=new B.p(30,A.aW)
A.yo=s([A.PA,A.OW,A.Pc,A.aD],t.T)
A.Pz=new B.p(50,A.bF)
A.P3=new B.p(20,A.aa)
A.yC=s([A.Pz,A.P3,A.aT,A.aD],t.T)
A.ci=s([0.75,0.95,0.995,0.9995,0.99999],t.u)
A.P1=new B.p(20,A.E)
A.PB=new B.p(50,A.V)
A.Pg=new B.p(30,A.ah)
A.zp=s([A.P1,A.PB,A.Pg],t.T)
A.A4=s([900,2250,4000,6750,9000],t.t)
A.Am=s([500,1200,2000,3000,4200],t.t)
A.P6=new B.p(25,A.E)
A.Pl=new B.p(35,A.ah)
A.At=s([A.P6,A.cF,A.Pl],t.T)
A.jg=new B.a8(0,"eggReady")
A.jh=new B.a8(1,"achievements")
A.ji=new B.a8(2,"evolutions")
A.jj=new B.a8(3,"friendRequests")
A.jk=new B.a8(4,"friendAcceptances")
A.jl=new B.a8(6,"tradeRequests")
A.jm=new B.a8(7,"tradeReturns")
A.jn=new B.a8(8,"tradeCompletions")
A.jo=new B.a8(9,"trialsFull")
A.bi=s([A.jg,A.jh,A.ji,A.jj,A.jk,A.ce,A.jl,A.jm,A.jn,A.jo,A.bd],B.W("v<a8>"))
A.Py=new B.p(50,A.bE)
A.cB=new B.p(20,A.ap)
A.PF=new B.p(5,A.aq)
A.OU=new B.p(15,A.E)
A.AL=s([A.Py,A.cB,A.PF,A.OU,A.bs],t.T)
A.Ps=new B.p(40,A.aa)
A.Ph=new B.p(30,A.bI)
A.AV=s([A.Ps,A.Ph,A.bu,A.br],t.T)
A.Sn=new B.a7("aurora","Aurora","Noorderlicht")
A.Su=new B.a7("ember","Ember","Gloed")
A.SA=new B.a7("moon","Moon","Maan")
A.Sv=new B.a7("forest","Forest","Woud")
A.SC=new B.a7("ocean","Ocean","Oceaan")
A.Ss=new B.a7("crystal","Crystal","Kristal")
A.Sp=new B.a7("cloud","Cloud","Wolk")
A.SI=new B.a7("sun","Sun","Zon")
A.Sy=new B.a7("lavender","Lavender","Lavendel")
A.Sq=new B.a7("copper","Copper","Koper")
A.SG=new B.a7("starlight","Starlight","Sterlicht")
A.Sz=new B.a7("meadow","Meadow","Weide")
A.SH=new B.a7("storm","Storm","Storm")
A.So=new B.a7("cherry","Cherry","Kersenbloesem")
A.Sw=new B.a7("frost","Frost","Rijp")
A.Sx=new B.a7("honey","Honey","Honing")
A.SB=new B.a7("mushroom","Mushroom","Paddenstoel")
A.SK=new B.a7("velvet","Velvet","Fluweel")
A.SD=new B.a7("rainbow","Rainbow","Regenboog")
A.SJ=new B.a7("twilight","Twilight","Schemer")
A.Sr=new B.a7("coral","Coral","Koraal")
A.SF=new B.a7("sapphire","Sapphire","Saffier")
A.SE=new B.a7("rose","Rose","Roos")
A.St=new B.a7("dragon","Dragon","Draken")
A.B4=s([A.Sn,A.Su,A.SA,A.Sv,A.SC,A.Ss,A.Sp,A.SI,A.Sy,A.Sq,A.SG,A.Sz,A.SH,A.So,A.Sw,A.Sx,A.SB,A.SK,A.SD,A.SJ,A.Sr,A.SF,A.SE,A.St],B.W("v<a7>"))
A.ew=new B.h("chest_treasure_hello",A.d)
A.hc=new B.h("chest_coin_eyes",A.d)
A.h6=new B.h("chest_sleepy_hoard",A.d)
A.el=new B.h("chest_surprise_egg",A.d)
A.fL=new B.h("chest_lucky_gem",A.d)
A.eU=new B.h("chest_chest_peek",A.d)
A.h_=new B.h("chest_gem_tears",A.d)
A.hw=new B.h("chest_golden_laugh",A.d)
A.f1=new B.h("chest_map_confused",A.d)
A.ev=new B.h("chest_key_found",A.d)
A.fY=new B.h("chest_mimic_shock",A.d)
A.hy=new B.h("chest_coin_rain",A.d)
A.hs=new B.h("chest_tiny_hoard",A.d)
A.e9=new B.h("chest_pearl_proud",A.d)
A.eC=new B.h("chest_treasure_sleep",A.d)
A.fZ=new B.h("chest_locked_out",A.d)
A.eM=new B.h("chest_crown_try",A.d)
A.fF=new B.h("chest_dusty_sneeze",A.d)
A.hd=new B.h("chest_potion_find",A.d)
A.ex=new B.h("chest_silver_bell",A.d)
A.fV=new B.h("chest_scroll_wow",A.d)
A.ej=new B.h("chest_ruby_blush",A.d)
A.f4=new B.h("chest_sapphire_cool",A.d)
A.fp=new B.h("chest_jackpot",A.d)
A.eH=new B.h("chest_dragon_detective",A.d)
A.fi=new B.h("chest_adored",A.d)
A.fs=new B.h("chest_nervous",A.d)
A.ec=new B.h("chest_terrified",A.d)
A.fm=new B.h("chest_furious",A.d)
A.fu=new B.h("chest_sulking",A.d)
A.fq=new B.h("chest_jealous",A.d)
A.fn=new B.h("chest_guilty",A.d)
A.ea=new B.h("chest_embarrassed",A.d)
A.ft=new B.h("chest_shy",A.d)
A.eK=new B.h("chest_skeptical",A.d)
A.eB=new B.h("chest_disgusted",A.d)
A.fl=new B.h("chest_curious",A.d)
A.h4=new B.h("chest_awestruck",A.d)
A.fo=new B.h("chest_hopeful",A.d)
A.fX=new B.h("chest_relieved",A.d)
A.eu=new B.h("chest_grateful",A.d)
A.fr=new B.h("chest_lonely",A.d)
A.fC=new B.h("chest_homesick",A.d)
A.h0=new B.h("chest_protective",A.d)
A.h2=new B.h("chest_generous",A.d)
A.hz=new B.h("chest_mischievous",A.d)
A.h3=new B.h("chest_impatient",A.d)
A.hf=new B.h("chest_overwhelmed",A.d)
A.fk=new B.h("chest_content",A.d)
A.fj=new B.h("chest_bored",A.d)
A.eT=new B.h("chest_misty_eyes",A.d)
A.eN=new B.h("chest_single_tear",A.d)
A.eA=new B.h("chest_happy_tears",A.d)
A.ff=new B.h("chest_heartbroken_sob",A.d)
A.fM=new B.h("chest_dramatic_bawl",A.d)
A.e=new B.bV(1,"trial")
A.f0=new B.h("trial_s_plus_crown",A.e)
A.f3=new B.h("trial_perfect_smash",A.e)
A.eV=new B.h("trial_cavern_soar",A.e)
A.fU=new B.h("trial_rune_genius",A.e)
A.hm=new B.h("trial_focus",A.e)
A.ee=new B.h("trial_victory_roar",A.e)
A.eE=new B.h("trial_close_call",A.e)
A.f5=new B.h("trial_speed_blur",A.e)
A.eI=new B.h("trial_combo_fire",A.e)
A.hl=new B.h("trial_dizzy",A.e)
A.eF=new B.h("trial_sweating",A.e)
A.hx=new B.h("trial_might_flex",A.e)
A.fE=new B.h("trial_spirit_wings",A.e)
A.f9=new B.h("trial_arcana_orbit",A.e)
A.eW=new B.h("trial_new_record",A.e)
A.ho=new B.h("trial_retry",A.e)
A.hh=new B.h("trial_target_lock",A.e)
A.fb=new B.h("trial_flawless",A.e)
A.eP=new B.h("trial_training",A.e)
A.fJ=new B.h("trial_medal_bite",A.e)
A.eb=new B.h("trial_power_up",A.e)
A.fO=new B.h("trial_team_cheer",A.e)
A.hq=new B.h("trial_zen",A.e)
A.eG=new B.h("trial_countdown",A.e)
A.eD=new B.h("trial_champion",A.e)
A.hi=new B.h("trial_baffled",A.e)
A.hj=new B.h("trial_big_cry",A.e)
A.hk=new B.h("trial_brave",A.e)
A.ep=new B.h("trial_compassionate",A.e)
A.eh=new B.h("trial_competitive",A.e)
A.es=new B.h("trial_crestfallen",A.e)
A.eS=new B.h("trial_encouraging",A.e)
A.fa=new B.h("trial_euphoric",A.e)
A.en=new B.h("trial_exhausted",A.e)
A.fc=new B.h("trial_fearless",A.e)
A.ht=new B.h("trial_finish_relief",A.e)
A.fd=new B.h("trial_frustrated",A.e)
A.hn=new B.h("trial_humble",A.e)
A.he=new B.h("trial_overconfident",A.e)
A.eX=new B.h("trial_playful_taunt",A.e)
A.f_=new B.h("trial_proud_tears",A.e)
A.e7=new B.h("trial_resigned",A.e)
A.h1=new B.h("trial_result_shock",A.e)
A.eY=new B.h("trial_second_wind",A.e)
A.eZ=new B.h("trial_self_angry",A.e)
A.hp=new B.h("trial_serene",A.e)
A.fG=new B.h("trial_stage_fright",A.e)
A.ey=new B.h("trial_startled",A.e)
A.f7=new B.h("trial_stubborn",A.e)
A.ef=new B.h("trial_stumble_blush",A.e)
A.em=new B.h("trial_welling_up",A.e)
A.fH=new B.h("trial_frustrated_tears",A.e)
A.h5=new B.h("trial_exhausted_cry",A.e)
A.ed=new B.h("trial_victory_weep",A.e)
A.ei=new B.h("trial_meltdown",A.e)
A.r=new B.bV(2,"seasonal")
A.fe=new B.h("seasonal_halloween_gold",A.r)
A.hv=new B.h("seasonal_halloween_silver",A.r)
A.h7=new B.h("seasonal_halloween_bronze",A.r)
A.eo=new B.h("seasonal_christmas_gold",A.r)
A.h9=new B.h("seasonal_christmas_silver",A.r)
A.eg=new B.h("seasonal_christmas_bronze",A.r)
A.eJ=new B.h("seasonal_new_year_gold",A.r)
A.ez=new B.h("seasonal_new_year_silver",A.r)
A.f8=new B.h("seasonal_new_year_bronze",A.r)
A.hr=new B.h("seasonal_valentine_gold",A.r)
A.eq=new B.h("seasonal_valentine_silver",A.r)
A.fN=new B.h("seasonal_valentine_bronze",A.r)
A.eO=new B.h("seasonal_pride_gold",A.r)
A.et=new B.h("seasonal_pride_silver",A.r)
A.ha=new B.h("seasonal_pride_bronze",A.r)
A.f6=new B.h("cozy_heart_hug",A.N)
A.fw=new B.h("cozy_cocoa",A.N)
A.fv=new B.h("cozy_blanket",A.N)
A.fB=new B.h("cozy_sleepy",A.N)
A.fy=new B.h("cozy_flower",A.N)
A.fA=new B.h("cozy_shy_wave",A.N)
A.fz=new B.h("cozy_picnic",A.N)
A.fx=new B.h("cozy_cuddle",A.N)
A.h8=new B.h("cozy_happy_tears",A.N)
A.hg=new B.h("cozy_good_night",A.N)
A.er=new B.h("infernal_evil_laugh",A.O)
A.fS=new B.h("infernal_rage",A.O)
A.hb=new B.h("infernal_facepalm",A.O)
A.fg=new B.h("infernal_suspicious",A.O)
A.f2=new B.h("infernal_skull_grin",A.O)
A.fQ=new B.h("infernal_fire",A.O)
A.fR=new B.h("infernal_no",A.O)
A.fK=new B.h("infernal_chaos",A.O)
A.eL=new B.h("infernal_shocked",A.O)
A.fT=new B.h("infernal_smug",A.O)
A.fD=new B.h("celestial_royal_wave",A.P)
A.fI=new B.h("celestial_applause",A.P)
A.hu=new B.h("celestial_sparkle",A.P)
A.e8=new B.h("celestial_moon_dream",A.P)
A.eQ=new B.h("celestial_star_eyes",A.P)
A.fh=new B.h("celestial_bow",A.P)
A.fP=new B.h("celestial_celebrate",A.P)
A.eR=new B.h("celestial_wisdom",A.P)
A.fW=new B.h("celestial_salute",A.P)
A.ek=new B.h("celestial_magic",A.P)
A.bj=s([A.ew,A.hc,A.h6,A.el,A.fL,A.eU,A.h_,A.hw,A.f1,A.ev,A.fY,A.hy,A.hs,A.e9,A.eC,A.fZ,A.eM,A.fF,A.hd,A.ex,A.fV,A.ej,A.f4,A.fp,A.eH,A.fi,A.fs,A.ec,A.fm,A.fu,A.fq,A.fn,A.ea,A.ft,A.eK,A.eB,A.fl,A.h4,A.fo,A.fX,A.eu,A.fr,A.fC,A.h0,A.h2,A.hz,A.h3,A.hf,A.fk,A.fj,A.eT,A.eN,A.eA,A.ff,A.fM,A.f0,A.f3,A.eV,A.fU,A.hm,A.ee,A.eE,A.f5,A.eI,A.hl,A.eF,A.hx,A.fE,A.f9,A.eW,A.ho,A.hh,A.fb,A.eP,A.fJ,A.eb,A.fO,A.hq,A.eG,A.eD,A.hi,A.hj,A.hk,A.ep,A.eh,A.es,A.eS,A.fa,A.en,A.fc,A.ht,A.fd,A.hn,A.he,A.eX,A.f_,A.e7,A.h1,A.eY,A.eZ,A.hp,A.fG,A.ey,A.f7,A.ef,A.em,A.fH,A.h5,A.ed,A.ei,A.fe,A.hv,A.h7,A.eo,A.h9,A.eg,A.eJ,A.ez,A.f8,A.hr,A.eq,A.fN,A.eO,A.et,A.ha,A.f6,A.fw,A.fv,A.fB,A.fy,A.fA,A.fz,A.fx,A.h8,A.hg,A.er,A.fS,A.hb,A.fg,A.f2,A.fQ,A.fR,A.fK,A.eL,A.fT,A.fD,A.fI,A.hu,A.e8,A.eQ,A.fh,A.fP,A.eR,A.fW,A.ek],B.W("v<h>"))
A.Bj=s([A.c2,A.aM],B.W("v<a_>"))
A.Bl=s(["bed"],t.s)
A.Bq=s(["books","treasure"],t.s)
A.aQ=s(["Cloud Orchard","Whispering Ruins","Moonlit Mere","Ember Pass","Crystal Hollow","Silver Canopy","Clockwork Glen","Starfall Coast","Mossbound Gate","Sunken Archive","Aurora Ridge","Lantern Marsh","Thunder Mesa","Sapphire Grotto","Dawnwind Vale","Comet Garden","Forgotten Belfry","Dreaming Dunes","Tidal Observatory","Rune Market"],t.s)
A.jE=new B.bJ("badge_supporter_founder")
A.jF=new B.bJ("heartbound_pair")
A.cj=s([A.jE,A.jF],B.W("v<bJ>"))
A.PO=new B.p(70,A.ap)
A.P5=new B.p(24,A.aq)
A.OZ=new B.p(1,A.ar)
A.BG=s([A.PO,A.P5,A.OZ,A.bw],t.T)
A.Pv=new B.p(45,A.V)
A.C7=s([A.cD,A.Pv,A.bv],t.T)
A.SM=new B.cH(0,"starter")
A.di=new B.Q("hello_little_one","Hello, Little One!","Hallo, Kleintje!",1)
A.dc=new B.Q("guided_tour","A Little Less Lost","Iets Minder Verdwaald",1)
A.SN=new B.cH(1,"easy")
A.d9=new B.Q("first_flight","First Flight","Eerste Vlucht",1)
A.d0=new B.Q("chest_expectations","Chest Expectations","Kistverwachtingen",1)
A.d2=new B.Q("profile_picture_perfect","Profile Picture Perfect","Profielplaatje Perfect",1)
A.cV=new B.Q("highly_titled","Highly Titled","Hooggetiteld",1)
A.d_=new B.Q("room_to_roost","Room to Roost","Ruimte om te Rusten",2)
A.cZ=new B.Q("feed_furniture","Do Not Feed the Furniture","Voer het Meubilair Niet",1)
A.d5=new B.Q("book_wyrm","Book Wyrm","Boekenwyrm",5)
A.cR=new B.Q("growing_pains","Growing Pains","Groeipijnen",1)
A.d7=new B.Q("not_picking_favorites","Definitely Not Picking Favorites","Zeker Geen Favorieten Kiezen",1)
A.SO=new B.cH(2,"challenging")
A.dp=new B.Q("halfway_clouds","Halfway to the Clouds","Halverwege de Wolken",10)
A.dk=new B.Q("ascension_day","Ascension Day","Hemelvaartsdag",1)
A.cP=new B.Q("something_spectral","Something Spectral This Way Comes","Er Komt Iets Spectraals Aan",1)
A.dd=new B.Q("well_read_scaled","Well Read, Well Scaled","Goed Gelezen, Goed Geschubd",20)
A.cY=new B.Q("frequent_flyer","Frequent Flyer","Vaste Vlieger",50)
A.SP=new B.cH(3,"master")
A.dn=new B.Q("are_we_there_yet","Are We There Yet?","Zijn We Er Al?",1000)
A.dl=new B.Q("full_party","Full Party, Full Send","Volle Groep, Vol Erin",1)
A.dg=new B.Q("triple_expertise","Master of All Three","Meester van Alle Drie",1)
A.d4=new B.Q("hidden_mastery","Perfectly Balanced","Perfect in Balans",1)
A.d3=new B.Q("came_crawling_back","Look Who Came Crawling Back","Kijk Wie Terug Kwam Kruipen",1)
A.d1=new B.Q("sky_ceiling","The Sky Has a Ceiling After All","De Lucht Heeft Toch een Plafond",20)
A.cW=new B.Q("scale_every_tale","A Scale for Every Tale","Een Schub voor Elk Verhaal",42)
A.cU=new B.Q("ghost_writer","Ghost Writer","Spookschrijver",10)
A.dh=new B.Q("myth_made_real","Myth Made Real","Mythe Wordt Werkelijk",1)
A.cQ=new B.Q("trial_might_s_plus","Wall? What Wall?","Muur? Welke Muur?",1)
A.d6=new B.Q("trial_spirit_s_plus","Crystal-Clear Flying","Kristalhelder Gevlogen",1)
A.cS=new B.Q("trial_arcana_s_plus","Rune and Done","Rune en Klaar",1)
A.de=new B.Q("winner_chicken_dinner","Winner, Winner, Chicken Dinner","Winner, Winner, Chicken Dinner",1)
A.cX=new B.Q("warden_of_the_witchlight","Warden of the Witchlight","Wachter van het Heksenlicht",1)
A.dm=new B.Q("star_in_every_hearth","A Star in Every Hearth","Een Ster in Elke Haard",1)
A.df=new B.Q("first_light_first_flight","First Light, First Flight","Eerste Licht, Eerste Vlucht",1)
A.dj=new B.Q("two_hearts_one_flight","Two Hearts, One Flight","Twee Harten, E\xe9n Vlucht",1)
A.d8=new B.Q("every_color_takes_flight","Every Color Takes Flight","Elke Kleur Krijgt Vleugels",1)
A.db=new B.Q("probably_fine","This Is Probably Fine","Dit Komt Vast Goed",1)
A.da=new B.Q("academy_graduate","Academy Graduate","Academie-afgestudeerde",1)
A.cT=new B.Q("dragon_school_dropout","Dragon Academy Dropout","Drakenacademie-uitvaller",1)
A.dq=new B.Q("dragon_school_valedictorian","Valedictorian","Lichtingsbeste",1)
A.CI=s([A.di,A.dc,A.d9,A.d0,A.d2,A.cV,A.d_,A.cZ,A.d5,A.cR,A.d7,A.dp,A.dk,A.cP,A.dd,A.cY,A.dn,A.dl,A.dg,A.d4,A.d3,A.d1,A.cW,A.cU,A.dh,A.cQ,A.d6,A.cS,A.de,A.cX,A.dm,A.df,A.dj,A.d8,A.db,A.da,A.cT,A.dq],B.W("v<Q>"))
A.cm=s([],t.m1)
A.CV=s([],t.t)
A.cl=s([],t.dG)
A.CW=s(["en","nl"],t.s)
A.co=s(["Breng in kaart","Verken","Verzamel in","Begeleid door","Ontcijfer bij","Herstel","Observeer","Bezorg in","Doorzoek","Onderzoek","Catalogiseer","Bescherm","Volg een spoor in","Vind terug in","Bestudeer"],t.s)
A.DQ=s([A.b6,A.y,A.ab,A.ai],B.W("v<bP>"))
A.dM=new B.b5(0,"moralEcho")
A.dN=new B.b5(1,"orderSigil")
A.dO=new B.b5(2,"astralLens")
A.aw=s([A.dM,A.dN,A.dO,A.bO,A.aI],B.W("v<b5>"))
A.F5=s([0,150,350,650,1000,1450,1950,2600,3400],t.t)
A.R3=new B.ap("supporter_dragon_throne","Supporter dragon throne",A.X,0,A.w)
A.R9=new B.ap("supporter_star_tree","Supporter star tree",A.Y,0,A.w)
A.R8=new B.ap("supporter_founder_banner","Supporter founder banner",A.Z,0,A.w)
A.Rc=new B.ap("supporter_aurora_beacon","Supporter aurora beacon",A.S,0,A.w)
A.cq=s([A.R3,A.R9,A.R8,A.Rc],t.n0)
A.FI=s(["id","message","createdAt","type","code","subject","xp","coins","gems"],t.s)
A.cr=s(["Map","Scout","Gather","Escort","Decode","Restore","Observe","Deliver","Search","Survey","Catalog","Protect","Trace","Recover","Study"],t.s)
A.GX=s(["pet","incubatingEgg"],t.s)
A.Pq=new B.p(40,A.E)
A.Pk=new B.p(35,A.V)
A.GZ=s([A.Pq,A.Pk,A.bv],t.T)
A.H0=s(["plants"],t.s)
A.bl=s(["Sleepy","Nosy","Hoarder","Drama Queen","Bookworm","Food Thief","Afraid of Heights","Restless","Shy","Show-Off","Clumsy","Neat Freak","Messy","Curious","Stubborn","Cuddly","Grumpy","Easily Distracted","Night Owl","Early Bird","Splash Lover","Firebug","Attention Seeker","Startles Easily"],t.s)
A.Hl=s(["supporterPackOwned","twinstarBroochEverObtained","twinstarBroochDragonId","eggAltar","pendingAltarOperation","adventureRuns","towerFloorRoomIds","dragonWardLevel","damagedTowerFloors","damagedTowerRepairFactors","reservedOnlineTradeChests","reservedOnlineTradeRelics","trialStreakCount","trialStreakRewardReady","dragonSchoolRecords","seasonalPodiumEmoteWinCounts"],t.s)
A.ax=s([A.F,A.M,A.t,A.G,A.H,A.a4,A.l,A.u,A.v,A.p],B.W("v<av>"))
A.jp=new B.bk("nest",1,0,0.57,0.84)
A.jq=new B.bk("hearth",2,45,0.6,0.84)
A.ju=new B.bk("crystal",3,65,0.51,0.88)
A.js=new B.bk("garden",4,80,0.55,0.88)
A.jv=new B.bk("tidal_library",5,105,0.54,0.89)
A.jr=new B.bk("loft",6,130,0.59,0.86)
A.jw=new B.bk("cloud",7,165,0.55,0.89)
A.jt=new B.bk("sunforge",9,240,0.57,0.89)
A.cs=s([A.jp,A.jq,A.ju,A.js,A.jv,A.jr,A.jw,A.jt],B.W("v<bk>"))
A.Pi=new B.p(35,A.bF)
A.Pm=new B.p(35,A.aa)
A.Iq=s([A.Pi,A.Pm,A.bu,A.br],t.T)
A.Ir=s(["sent","received"],t.s)
A.Pu=new B.p(45,A.aq)
A.Pf=new B.p(30,A.ar)
A.Pn=new B.p(3,A.aX)
A.cA=new B.p(10,A.E)
A.OP=new B.p(12,A.V)
A.IL=s([A.Pu,A.Pf,A.Pn,A.cA,A.OP],t.T)
A.SR=new B.bb(0,"leafCrown")
A.i0=new B.x("mossprout","Mossprout","earthlight",A.m,"hearth",A.n,!1)
A.SS=new B.bb(1,"crystalSpines")
A.ia=new B.x("crystalwhisk","Crystalwhisk","earthlight",A.m,"hearth",A.n,!1)
A.ST=new B.bb(2,"cloudFins")
A.i8=new B.x("dustglimmer","Dustglimmer","earthlight",A.m,"hearth",A.n,!1)
A.SZ=new B.bb(8,"starCrest")
A.io=new B.x("gleamclaw","Gleamclaw","earthlight",A.m,"hearth",A.n,!1)
A.SU=new B.bb(3,"emberHorns")
A.ih=new B.x("emberbun","Emberbun","ember",A.m,"hearth",A.n,!1)
A.SY=new B.bb(7,"copperPlates")
A.ib=new B.x("copperflame","Copperflame","ember",A.m,"hearth",A.n,!1)
A.SV=new B.bb(4,"featherWings")
A.i_=new B.x("spicewing","Spicewing","ember",A.m,"hearth",A.n,!1)
A.SX=new B.bb(6,"tideFrill")
A.ic=new B.x("bubblefin","Bubblefin","tide",A.m,"hearth",A.n,!1)
A.i2=new B.x("linencloud","Linencloud","tide",A.m,"hearth",A.n,!1)
A.ig=new B.x("tidescale","Tidescale","tide",A.m,"hearth",A.n,!1)
A.i7=new B.x("clockskip","Clockskip","tempest",A.m,"hearth",A.n,!1)
A.hN=new B.x("galeear","Galeear","tempest",A.m,"hearth",A.n,!1)
A.hQ=new B.x("thunderpuff","Thunderpuff","tempest",A.m,"hearth",A.n,!1)
A.SW=new B.bb(5,"moonAntennae")
A.hF=new B.x("dreammoth","Dreammoth","moon",A.m,"hearth",A.n,!1)
A.hM=new B.x("dewhorn","Dewhorn","moon",A.m,"hearth",A.n,!1)
A.hG=new B.x("quietstar","Quietstar","moon",A.m,"hearth",A.n,!1)
A.hS=new B.x("heartwing","Heartwing","heart",A.m,"hearth",A.n,!1)
A.hV=new B.x("twinflare","Twinflare","heart",A.m,"hearth",A.n,!1)
A.T_=new B.bb(9,"rainbowRuff")
A.il=new B.x("rainbowruff","Rainbowruff","heart",A.m,"hearth",A.n,!1)
A.hI=new B.x("harmonytail","Harmonytail","heart",A.m,"hearth",A.n,!1)
A.cp=s(["hearth","loft"],t.s)
A.hY=new B.x("bramblequill","Bramblequill","wildwood",A.Q,"garden",A.cp,!1)
A.bk=s(["hearth"],t.s)
A.hL=new B.x("cinderlynx","Cinderlynx","ember",A.Q,"sunforge",A.bk,!1)
A.ck=s(["cloud"],t.s)
A.hT=new B.x("mistmantle","Mistmantle","tide",A.Q,"tidal_library",A.ck,!1)
A.IS=s(["tidal_library","loft"],t.s)
A.i6=new B.x("runehopper","Runehopper","arcane",A.Q,"crystal",A.IS,!1)
A.ip=new B.x("petaldrift","Petaldrift","bloom",A.Q,"garden",A.bk,!1)
A.Iy=s(["sunforge"],t.s)
A.id=new B.x("ironwhistle","Ironwhistle","clockwork",A.Q,"loft",A.Iy,!1)
A.bm=s(["tidal_library"],t.s)
A.hK=new B.x("frostfable","Frostfable","frost",A.Q,"crystal",A.bm,!1)
A.cn=s(["garden"],t.s)
A.hJ=new B.x("sunmuzzle","Sunmuzzle","solar",A.Q,"sunforge",A.cn,!1)
A.i1=new B.x("echofern","Echofern","wildwood",A.Q,"garden",A.bm,!1)
A.i9=new B.x("velvetvolt","Velvetvolt","tempest",A.Q,"cloud",A.cp,!1)
A.aR=s(["crystal"],t.s)
A.hX=new B.x("auroracrown","Auroracrown","aurora",A.ad,"cloud",A.aR,!1)
A.i4=new B.x("voidbloom","Voidbloom","void",A.ad,"crystal",A.ck,!1)
A.ik=new B.x("coraloracle","Coraloracle","tide",A.ad,"tidal_library",A.cn,!1)
A.ii=new B.x("meteorhide","Meteorhide","cosmic",A.ad,"sunforge",A.aR,!1)
A.ij=new B.x("temporalark","Temporalark","time",A.ad,"loft",A.bm,!1)
A.Dv=s(["garden","cloud"],t.s)
A.hD=new B.x("opalchimera","Opalchimera","prism",A.ad,"crystal",A.Dv,!1)
A.hR=new B.x("eclipseantler","Eclipseantler","eclipse",A.aK,"cloud",A.aR,!1)
A.hW=new B.x("worldroot","Worldroot","primordial",A.aK,"garden",A.bk,!1)
A.BS=s(["cloud","sunforge"],t.s)
A.hE=new B.x("seraphscale","Seraphscale","celestial",A.aK,"hearth",A.BS,!1)
A.BQ=s(["cloud","crystal"],t.s)
A.hH=new B.x("starforged","Starforged","cosmic",A.b7,"sunforge",A.BQ,!1)
A.iq=new B.x("leviathanecho","Leviathanecho","abyssal",A.b7,"tidal_library",A.aR,!1)
A.BV=s(["crystal","cloud"],t.s)
A.im=new B.x("everwyrm","Everwyrm","creation",A.aL,"hearth",A.BV,!1)
A.Iz=s(["sunforge","cloud"],t.s)
A.hZ=new B.x("sinisterra","Sinisterra","abyss",A.aL,"crystal",A.Iz,!0)
A.DT=s(["hearth","sunforge"],t.s)
A.ie=new B.x("cluckatrice","Cluckatrice","dawn",A.a6,"garden",A.DT,!0)
A.BW=s(["crystal","hearth"],t.s)
A.i5=new B.x("gloamgourd","Gloamgourd","witchlight",A.a6,"garden",A.BW,!0)
A.BR=s(["cloud","garden"],t.s)
A.i3=new B.x("hollyfrost","Hollyfrost","winterlight",A.a6,"hearth",A.BR,!0)
A.IA=s(["sunforge","hearth"],t.s)
A.hO=new B.x("dawnchime","Dawnchime","firstlight",A.a6,"cloud",A.IA,!0)
A.DS=s(["hearth","cloud"],t.s)
A.hU=new B.x("rosevow","Rosevow","heartlight",A.a6,"garden",A.DS,!0)
A.Dw=s(["garden","crystal","hearth"],t.s)
A.hP=new B.x("spectrumplume","Spectrumplume","prismatic",A.a6,"cloud",A.Dw,!0)
A.a2=s([A.i0,A.ia,A.i8,A.io,A.ih,A.ib,A.i_,A.ic,A.i2,A.ig,A.i7,A.hN,A.hQ,A.hF,A.hM,A.hG,A.hS,A.hV,A.il,A.hI,A.hY,A.hL,A.hT,A.i6,A.ip,A.id,A.hK,A.hJ,A.i1,A.i9,A.hX,A.i4,A.ik,A.ii,A.ij,A.hD,A.hR,A.hW,A.hE,A.hH,A.iq,A.im,A.hZ,A.ie,A.i5,A.i3,A.hO,A.hU,A.hP],B.W("v<x>"))
A.IW=s(["treasure"],t.s)
A.PD=new B.p(55,A.ap)
A.Pa=new B.p(2,A.ar)
A.PS=new B.p(8,A.E)
A.Jc=s([A.PD,A.cC,A.Pa,A.PS,A.bs],t.T)
A.PK=new B.p(60,A.bG)
A.OO=new B.p(10,A.aa)
A.Ji=s([A.PK,A.OO,A.aT,A.aD],t.T)
A.Pp=new B.p(40,A.bG)
A.SL=new B.aD(14,"majorMischief")
A.Pd=new B.p(30,A.SL)
A.Jn=s([A.Pp,A.Pd,A.aT,A.aD],t.T)
A.JE=s([A.h,A.aj,A.a7,A.I],B.W("v<bX>"))
A.K=s([A.a9,A.a5,A.a3],t.mU)
A.PE=new B.p(55,A.aq)
A.Pj=new B.p(35,A.ar)
A.PH=new B.p(5,A.aX)
A.JZ=s([A.PE,A.Pj,A.PH,A.bw],t.T)
A.PM=new B.p(65,A.bE)
A.PI=new B.p(5,A.V)
A.KP=s([A.PM,A.cB,A.cA,A.PI],t.T)
A.N1=new B.l("event_witchlight_nocturne","Witchlight Nocturne","music_toccata_fugue_d_minor","halloween_witchlight")
A.MD=new B.l("event_winter_hearth_carol","Winter Hearth Carol","music_greensleeves","christmas_winter_hearth")
A.MJ=new B.l("event_first_dawn_waltz","First Dawn Waltz","music_auld_lang_syne","new_year_first_dawn")
A.Ms=new B.l("event_rosebound_romance","Rosebound Romance","music_clair_de_lune","valentine_two_heartlights")
A.NH=new B.l("event_every_color_festival","Every Color Festival","music_tritsch_tratsch","pride_every_color")
A.ct=s([A.N1,A.MD,A.MJ,A.Ms,A.NH],t.lI)
A.T1=new B.a_(75e6)
A.RK=new B.bw(null)
A.RL=new B.bw(null)
A.RM=new B.bw(null)
A.RI=new B.bw("halloween_witchlight")
A.RH=new B.bw("christmas_winter_hearth")
A.RJ=new B.bw("new_year_first_dawn")
A.RO=new B.bw("valentine_two_heartlights")
A.RN=new B.bw("pride_every_color")
A.cu=new B.b7([A.ag,A.RK,A.an,A.RL,A.ao,A.RM,A.by,A.RI,A.bz,A.RH,A.bA,A.RJ,A.bB,A.RO,A.bC,A.RN],B.W("b7<al,bw>"))
A.On={"Aerie stage":0,"Aerie tended today":1,"Allow friend messages":2,"Build an Aerie together, chat and keep a shared Chronicle.":3,"care streak":4,Chat:5,"Dragon emotes":6,"Dragon emote packs":7,"Each pack contains ten exclusive chat emotes that cannot drop from chests or Trials.":8,"This pack is ready for \u20ac1.99. Purchasing becomes available after its Google Play product and secure server verification are connected.":9,"10 emotes":10,"New chat emote":11,"Unlocked emotes can be used without limits.":12,"Find emotes in chests, win them with S+ Trial scores, or collect an emote pack.":13,Chronicle:14,Conclave:15,"Conclave invitation sent.":16,"Create a Conclave":17,Decline:18,Description:19,Dissolve:20,"Dissolve Conclave":21,"Dissolve Conclave?":22,Emblem:23,"Enable friend messages in Account Info to chat.":24,"Find Keepers and build an Aerie together.":25,"Find your Conclave":26,"Found a Conclave":27,"Friends can send messages that remain available for 24 hours.":28,"Friend messages":29,"When a friend sends you a private message.":30,"New message from {name}":31,"Newest messages":32,Invitations:33,Invite:34,"Invite as friend":35,"Invite by Keeper ID":36,"Invite Keeper":37,"Invite Only":38,"Keeper actions":39,Join:40,"Join a Conclave":41,"Join a Conclave first.":42,"Join requests":43,Joining:44,Keeper:45,Keepers:46,Language:47,"Latest achievement":48,"Leave Conclave":49,"Make Keeper":50,"Make Warden":51,"Maximum Keepers":52,"Message the Conclave\u2026":53,"Message\u2026":54,Messages:55,"Messages are only available between friends.":56,"Messages remain available for 24 hours.":57,"My Keeper trial records":58,"No messages yet. Say hello!":59,"No public Conclaves yet. You can found the first one.":60,"Open Conclaves":61,"Open DragonHaven to read it.":62,"Private messages disappear after 24 hours.":63,Public:64,"Remove from Conclave":65,Request:66,"Request to Join":67,Requested:68,Share:69,"Share achievements with Conclave":70,"Tend the Aerie \xb7 +10 XP":71,"That Conclave name is already in use.":72,"Choose carefully: this unique Conclave name cannot be changed later.":73,"A Conclave name cannot be changed after it is founded.":74,"The Aerie is quiet. Start the conversation!":75,"The Aerie, chat and Chronicle will be permanently removed.":76,"The Chronicle is still empty.":77,"The Conclave":78,"This Conclave could not be found.":79,"This Conclave has reached today's Aerie contribution limit.":80,"This Conclave invitation is no longer available.":81,"This Conclave is full.":82,"This Conclave is invite only.":83,"This join request is no longer available.":84,"This Keeper is no longer in the Conclave.":85,"This Keeper is not accepting messages.":86,"Transfer Flightmaster":87,"Transfer the Flightmaster rank or dissolve the Conclave first.":88,"Trial records":89,"Unlocked achievements appear in your Conclave chat and Chronicle.":90,"Write a message between 1 and 500 characters.":91,"Write a message\u2026":92,"You already tended the Aerie today.":93,"You are already in a Conclave.":94,"You are sending messages too quickly. Try again soon.":95,"Your Conclave rank cannot do that.":96,Conclaves:97,"Find your shared Aerie":98,Refresh:99,"Up to 20 Keepers":100,"10 Aerie stages":101,"Conclave is full":102,"Request pending":103,"Request to join":104,"Join this Conclave":105,"Messages stay for 24 hours":106,"The Aerie is quiet":107,"Start the first conversation with your fellow Keepers.":108,"Achievement unlocked":109,"Show less":110,"Conclave Keepers":111,"Your rank":112,"A new Chronicle":113,"Milestones, new Keepers and shared achievements will be recorded here.":114,CHAT:115,"will show you around. You can skip now and replay this complete tour later from the three-dot menu.":116,"Friends and profiles":117,"Messages and safe trades":118,"Use CHAT on a friend card for private messages from the last 24 hours. Trade offers reserve eligible eggs, chests and Relics until the exchange completes or expires.":119,"Your Conclave":120,"Conclave is directly below the Friends overview. Join or found one, chat with up to 20 Keepers, tend the shared Aerie, share achievements and follow its Chronicle.":121,"Mini, Short and Long Adventures take progressively longer. Matching Expertise reduces their duration. Completed cards list rewards; a solo active Adventure can be aborted without rewards.":122,"Group and Special Adventures":123,"Group Adventures show their combined Expertise requirement before joining. Special Adventures appear during events, show guaranteed rewards and remain finishable when started in time.":124,"Trials and constellation":125,"Trials refill every 15 minutes, up to three waiting. Might, Arcana and Spirit each have a skill game. Play daily for the seven-day constellation; missing a day resets it.":126,"Evolution and Expertise":127,"Train Expertise through Adventures, Trials and Academy lessons. Evolution choices raise different Expertise maximums; MAX always follows the correct dragon, form and Ascension cap.":128,"Dragons and Draconomicon":129,"My Dragons has grid and compact list views, reversible sorting and combined filters for form, rarity and spectral dragons. The Draconomicon tracks every family and evolved form.":130,"Nest, rooms and Tower":131,"Incubate an egg in the Rooftop Nest and watch its timer from the Tower. Starter Eggs can be tapped to speed up. Build, decorate and reorder every room except the Rooftop Nest.":132,"The Academy unlocks with Tower level 5 at the bottom. Choose available students, earn lesson stars and Expertise, use mentors and graduate early after passing every subject.":133,"Organize Inventory":134,"Eggs and furniture have saved grid/list views, sorting and filters. Egg rows show hatch time; chests use a fixed rarity order. Trade-reserved items stay unavailable.":135,"Chests and Relics":136,"Open one chest full-screen, or ten together when possible. Relics show whether they are consumable, tradeable or equipable; an equipped XP Relic can move between dragons.":137,"Shops and currencies":138,"Browse separate Coin, Gem and Packs shops. Furniture, Relics and collection chests show their currency clearly. Optional store bundles never replace normal gameplay.":139,"Music and supporter vanity":140,"Music Chests always unlock a missing song. The Jukebox controls songs, order, Shuffle and Repeat. Packs can add separate portraits, titles, badges, frames and furniture.":141,"Account, audio and notifications":142,"Account Info manages vanity, messages, audio and Jukebox. Notification types require device permission and open the right destination. Cloud backups and restore history protect online progress.":143,"Journal, achievements and help":144,"The three-dot menu also opens Language, Achievements, the Keeper Journal and this Tutorial. The Journal records milestones; secret achievements reveal themselves only when earned.":145}
A.If=s(["Aerie-Stufe","Etapa del Aerie","Niveau de l\u2019Aerie","Fase dell\u2019Aerie","Est\xe1gio do Aerie","\u30a8\u30a2\u30ea\u30fc\u6bb5\u968e"],t.s)
A.kE=s(["Aerie heute gepflegt","Aerie cuidado hoy","Aerie entretenu aujourd\u2019hui","Aerie curato oggi","Aerie cuidado hoje","\u672c\u65e5\u306e\u30a8\u30a2\u30ea\u30fc\u624b\u5165\u308c\u5b8c\u4e86"],t.s)
A.pZ=s(["Nachrichten von Freunden erlauben","Permitir mensajes de amigos","Autoriser les messages d\u2019amis","Consenti messaggi dagli amici","Permitir mensagens de amigos","\u30d5\u30ec\u30f3\u30c9\u30e1\u30c3\u30bb\u30fc\u30b8\u3092\u8a31\u53ef"],t.s)
A.mH=s(["Baut gemeinsam ein Aerie, chattet und f\xfchrt eine gemeinsame Chronik.","Construid juntos un Aerie, chatead y conservad una Cr\xf3nica compartida.","Construisez ensemble un Aerie, discutez et tenez une Chronique commune.","Costruite insieme un Aerie, chattate e tenete una Cronaca condivisa.","Construam juntos um Aerie, conversem e mantenham uma Cr\xf4nica compartilhada.","\u4e00\u7dd2\u306b\u30a8\u30a2\u30ea\u30fc\u3092\u80b2\u3066\u3001\u4f1a\u8a71\u3057\u3001\u5171\u6709\u5e74\u4ee3\u8a18\u3092\u6b8b\u3057\u307e\u3057\u3087\u3046\u3002"],t.s)
A.qQ=s(["Pflegeserie","racha de cuidados","s\xe9rie de soins","serie di cure","sequ\xeancia de cuidados","\u304a\u4e16\u8a71\u9023\u7d9a\u65e5\u6570"],t.s)
A.Ii=s(["Chat","Chat","Discussion","Chat","Chat","\u30c1\u30e3\u30c3\u30c8"],t.s)
A.re=s(["Drachen-Emotes","Emotes de drag\xf3n","\xc9motes de dragon","Emote drago","Emotes de drag\xe3o","\u30c9\u30e9\u30b4\u30f3\u30a8\u30e2\u30fc\u30c8"],t.s)
A.nF=s(["Drachen-Emote-Pakete","Packs de emotes de drag\xf3n","Packs d\u2019\xe9motes de dragon","Pacchetti di emote drago","Pacotes de emotes de drag\xe3o","\u30c9\u30e9\u30b4\u30f3\u30a8\u30e2\u30fc\u30c8\u30d1\u30c3\u30af"],t.s)
A.nQ=s(["Jedes Paket enth\xe4lt zehn exklusive Chat-Emotes, die nicht aus Truhen oder Pr\xfcfungen stammen.","Cada pack contiene diez emotes de chat exclusivos que no aparecen en cofres ni Pruebas.","Chaque pack contient dix \xe9motes de chat exclusives, introuvables dans les coffres ou les \xc9preuves.","Ogni pacchetto contiene dieci emote chat esclusive che non si trovano nei forzieri o nelle Prove.","Cada pacote cont\xe9m dez emotes de chat exclusivos que n\xe3o aparecem em ba\xfas nem Provas.","\u5404\u30d1\u30c3\u30af\u306b\u306f\u3001\u5b9d\u7bb1\u3084\u8a66\u7df4\u304b\u3089\u306f\u5165\u624b\u3067\u304d\u306a\u3044\u9650\u5b9a\u30c1\u30e3\u30c3\u30c8\u30a8\u30e2\u30fc\u30c8\u304c10\u500b\u5165\u3063\u3066\u3044\u307e\u3059\u3002"],t.s)
A.DC=s(["Dieses Paket ist f\xfcr 1,99 \u20ac vorbereitet. Der Kauf wird verf\xfcgbar, sobald das Google-Play-Produkt und die sichere Serverpr\xfcfung verbunden sind.","Este pack est\xe1 preparado por 1,99 \u20ac. La compra estar\xe1 disponible cuando se conecten el producto de Google Play y la verificaci\xf3n segura del servidor.","Ce pack est pr\xeat au prix de 1,99 \u20ac. L\u2019achat sera disponible une fois le produit Google Play et la v\xe9rification s\xe9curis\xe9e du serveur connect\xe9s.","Questo pacchetto \xe8 pronto al prezzo di 1,99 \u20ac. L\u2019acquisto sar\xe0 disponibile dopo il collegamento del prodotto Google Play e della verifica sicura del server.","Este pacote est\xe1 preparado por \u20ac 1,99. A compra ficar\xe1 dispon\xedvel quando o produto Google Play e a verifica\xe7\xe3o segura do servidor estiverem conectados.","\u3053\u306e\u30d1\u30c3\u30af\u306f1.99\u30e6\u30fc\u30ed\u3067\u6e96\u5099\u6e08\u307f\u3067\u3059\u3002Google Play\u5546\u54c1\u3068\u5b89\u5168\u306a\u30b5\u30fc\u30d0\u30fc\u691c\u8a3c\u306e\u63a5\u7d9a\u5f8c\u306b\u8cfc\u5165\u3067\u304d\u307e\u3059\u3002"],t.s)
A.Kt=s(["10 Emotes","10 emotes","10 \xe9motes","10 emote","10 emotes","\u30a8\u30e2\u30fc\u30c810\u500b"],t.s)
A.BI=s(["Neues Chat-Emote","Nuevo emote de chat","Nouvelle \xe9mote de chat","Nuova emote chat","Novo emote de chat","\u65b0\u3057\u3044\u30c1\u30e3\u30c3\u30c8\u30a8\u30e2\u30fc\u30c8"],t.s)
A.wr=s(["Freigeschaltete Emotes k\xf6nnen unbegrenzt verwendet werden.","Los emotes desbloqueados se pueden usar sin l\xedmites.","Les \xe9motes d\xe9bloqu\xe9es peuvent \xeatre utilis\xe9es sans limite.","Le emote sbloccate possono essere usate senza limiti.","Emotes desbloqueados podem ser usados sem limites.","\u30a2\u30f3\u30ed\u30c3\u30af\u3057\u305f\u30a8\u30e2\u30fc\u30c8\u306f\u4f55\u5ea6\u3067\u3082\u4f7f\u3048\u307e\u3059\u3002"],t.s)
A.Gc=s(["Finde Emotes in Truhen, gewinne sie mit S+-Wertungen in Pr\xfcfungen oder sammle ein Emote-Paket.","Encuentra emotes en cofres, g\xe1nalos con puntuaciones S+ en Pruebas o consigue un pack de emotes.","Trouvez des \xe9motes dans les coffres, gagnez-les avec un score S+ aux \xc9preuves ou obtenez un pack d\u2019\xe9motes.","Trova emote nei forzieri, vincile con valutazioni S+ nelle Prove oppure ottieni un pacchetto di emote.","Encontre emotes em ba\xfas, ganhe-os com notas S+ nas Provas ou obtenha um pacote de emotes.","\u5b9d\u7bb1\u304b\u3089\u898b\u3064\u3051\u308b\u304b\u3001\u8a66\u7df4\u3067S+\u3092\u7372\u5f97\u3059\u308b\u304b\u3001\u30a8\u30e2\u30fc\u30c8\u30d1\u30c3\u30af\u3092\u5165\u624b\u3057\u307e\u3057\u3087\u3046\u3002"],t.s)
A.v5=s(["Chronik","Cr\xf3nica","Chronique","Cronaca","Cr\xf4nica","\u5e74\u4ee3\u8a18"],t.s)
A.zQ=s(["Konklave","C\xf3nclave","Conclave","Conclave","Conclave","\u30b3\u30f3\u30af\u30ec\u30a4\u30f4"],t.s)
A.GI=s(["Konklaven-Einladung gesendet.","Invitaci\xf3n al C\xf3nclave enviada.","Invitation au Conclave envoy\xe9e.","Invito al Conclave inviato.","Convite para o Conclave enviado.","\u30b3\u30f3\u30af\u30ec\u30a4\u30f4\u3078\u306e\u62db\u5f85\u3092\u9001\u308a\u307e\u3057\u305f\u3002"],t.s)
A.Kz=s(["Konklave gr\xfcnden","Crear un C\xf3nclave","Cr\xe9er un Conclave","Crea un Conclave","Criar um Conclave","\u30b3\u30f3\u30af\u30ec\u30a4\u30f4\u3092\u4f5c\u6210"],t.s)
A.ym=s(["Ablehnen","Rechazar","Refuser","Rifiuta","Recusar","\u8f9e\u9000"],t.s)
A.He=s(["Beschreibung","Descripci\xf3n","Description","Descrizione","Descri\xe7\xe3o","\u8aac\u660e"],t.s)
A.oU=s(["Aufl\xf6sen","Disolver","Dissoudre","Sciogli","Dissolver","\u89e3\u6563"],t.s)
A.Dk=s(["Konklave aufl\xf6sen","Disolver C\xf3nclave","Dissoudre le Conclave","Sciogli il Conclave","Dissolver Conclave","\u30b3\u30f3\u30af\u30ec\u30a4\u30f4\u3092\u89e3\u6563"],t.s)
A.F8=s(["Konklave aufl\xf6sen?","\xbfDisolver el C\xf3nclave?","Dissoudre le Conclave ?","Sciogliere il Conclave?","Dissolver o Conclave?","\u30b3\u30f3\u30af\u30ec\u30a4\u30f4\u3092\u89e3\u6563\u3057\u307e\u3059\u304b\uff1f"],t.s)
A.J8=s(["Emblem","Emblema","Embl\xe8me","Emblema","Emblema","\u7d0b\u7ae0"],t.s)
A.q7=s(["Aktiviere Nachrichten von Freunden in den Kontoinformationen, um zu chatten.","Activa los mensajes de amigos en Informaci\xf3n de la cuenta para chatear.","Activez les messages d\u2019amis dans les informations du compte pour discuter.","Attiva i messaggi dagli amici nelle informazioni account per chattare.","Ative mensagens de amigos nas informa\xe7\xf5es da conta para conversar.","\u30c1\u30e3\u30c3\u30c8\u3059\u308b\u306b\u306f\u30a2\u30ab\u30a6\u30f3\u30c8\u60c5\u5831\u3067\u30d5\u30ec\u30f3\u30c9\u30e1\u30c3\u30bb\u30fc\u30b8\u3092\u6709\u52b9\u306b\u3057\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.za=s(["Finde H\xfcter und baut gemeinsam ein Aerie.","Encuentra Guardianes y construid juntos un Aerie.","Trouvez des Gardiens et construisez ensemble un Aerie.","Trova Custodi e costruite insieme un Aerie.","Encontre Guardi\xf5es e construam juntos um Aerie.","\u30ad\u30fc\u30d1\u30fc\u3092\u898b\u3064\u3051\u3066\u3001\u4e00\u7dd2\u306b\u30a8\u30a2\u30ea\u30fc\u3092\u80b2\u3066\u307e\u3057\u3087\u3046\u3002"],t.s)
A.EE=s(["Finde deine Konklave","Encuentra tu C\xf3nclave","Trouvez votre Conclave","Trova il tuo Conclave","Encontre seu Conclave","\u30b3\u30f3\u30af\u30ec\u30a4\u30f4\u3092\u63a2\u3059"],t.s)
A.wF=s(["Konklave gr\xfcnden","Fundar un C\xf3nclave","Fonder un Conclave","Fonda un Conclave","Fundar um Conclave","\u30b3\u30f3\u30af\u30ec\u30a4\u30f4\u3092\u8a2d\u7acb"],t.s)
A.JB=s(["Freunde k\xf6nnen dir Nachrichten senden, die 24 Stunden verf\xfcgbar bleiben.","Tus amigos pueden enviarte mensajes que estar\xe1n disponibles durante 24 horas.","Vos amis peuvent vous envoyer des messages disponibles pendant 24 heures.","Gli amici possono inviarti messaggi disponibili per 24 ore.","Amigos podem enviar mensagens que ficam dispon\xedveis por 24 horas.","\u30d5\u30ec\u30f3\u30c9\u306f24\u6642\u9593\u8868\u793a\u3055\u308c\u308b\u30e1\u30c3\u30bb\u30fc\u30b8\u3092\u9001\u308c\u307e\u3059\u3002"],t.s)
A.qt=s(["Nachrichten von Freunden","Mensajes de amigos","Messages d\u2019amis","Messaggi dagli amici","Mensagens de amigos","\u30d5\u30ec\u30f3\u30c9\u30e1\u30c3\u30bb\u30fc\u30b8"],t.s)
A.mq=s(["Wenn dir ein Freund eine private Nachricht sendet.","Cuando un amigo te env\xeda un mensaje privado.","Lorsqu\u2019un ami vous envoie un message priv\xe9.","Quando un amico ti invia un messaggio privato.","Quando um amigo envia uma mensagem privada para voc\xea.","\u30d5\u30ec\u30f3\u30c9\u304b\u3089\u30d7\u30e9\u30a4\u30d9\u30fc\u30c8\u30e1\u30c3\u30bb\u30fc\u30b8\u304c\u5c4a\u3044\u305f\u3068\u304d\u3002"],t.s)
A.ES=s(["Neue Nachricht von {name}","Nuevo mensaje de {name}","Nouveau message de {name}","Nuovo messaggio da {name}","Nova mensagem de {name}","{name}\u304b\u3089\u65b0\u3057\u3044\u30e1\u30c3\u30bb\u30fc\u30b8"],t.s)
A.n0=s(["Neueste Nachrichten","Mensajes m\xe1s recientes","Messages les plus r\xe9cents","Messaggi pi\xf9 recenti","Mensagens mais recentes","\u6700\u65b0\u306e\u30e1\u30c3\u30bb\u30fc\u30b8"],t.s)
A.zr=s(["Einladungen","Invitaciones","Invitations","Inviti","Convites","\u62db\u5f85"],t.s)
A.wd=s(["Einladen","Invitar","Inviter","Invita","Convidar","\u62db\u5f85"],t.s)
A.pU=s(["Als Freund einladen","Invitar como amigo","Inviter comme ami","Invita come amico","Convidar como amigo","\u53cb\u9054\u3068\u3057\u3066\u62db\u5f85"],t.s)
A.BE=s(["\xdcber H\xfcter-ID einladen","Invitar por ID de Guardi\xe1n","Inviter par ID de Gardien","Invita tramite ID Custode","Convidar pelo ID do Guardi\xe3o","\u30ad\u30fc\u30d1\u30fcID\u3067\u62db\u5f85"],t.s)
A.tw=s(["H\xfcter einladen","Invitar Guardi\xe1n","Inviter un Gardien","Invita Custode","Convidar Guardi\xe3o","\u30ad\u30fc\u30d1\u30fc\u3092\u62db\u5f85"],t.s)
A.qe=s(["Nur auf Einladung","Solo con invitaci\xf3n","Sur invitation uniquement","Solo su invito","Somente por convite","\u62db\u5f85\u5236"],t.s)
A.Hx=s(["H\xfcteraktionen","Acciones del Guardi\xe1n","Actions du Gardien","Azioni del Custode","A\xe7\xf5es do Guardi\xe3o","\u30ad\u30fc\u30d1\u30fc\u306e\u64cd\u4f5c"],t.s)
A.Hg=s(["Beitreten","Unirse","Rejoindre","Unisciti","Entrar","\u53c2\u52a0"],t.s)
A.xL=s(["Einer Konklave beitreten","\xdanete a un C\xf3nclave","Rejoindre un Conclave","Unisciti a un Conclave","Entrar em um Conclave","\u30b3\u30f3\u30af\u30ec\u30a4\u30f4\u306b\u53c2\u52a0"],t.s)
A.Dm=s(["Tritt zuerst einer Konklave bei.","\xdanete primero a un C\xf3nclave.","Rejoignez d\u2019abord un Conclave.","Prima unisciti a un Conclave.","Entre primeiro em um Conclave.","\u5148\u306b\u30b3\u30f3\u30af\u30ec\u30a4\u30f4\u3078\u53c2\u52a0\u3057\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.Dx=s(["Beitrittsanfragen","Solicitudes de ingreso","Demandes d\u2019adh\xe9sion","Richieste di partecipazione","Pedidos de entrada","\u53c2\u52a0\u7533\u8acb"],t.s)
A.I1=s(["Beitritt","Acceso","Adh\xe9sion","Accesso","Entrada","\u53c2\u52a0\u65b9\u6cd5"],t.s)
A.on=s(["H\xfcter","Guardi\xe1n","Gardien","Custode","Guardi\xe3o","\u30ad\u30fc\u30d1\u30fc"],t.s)
A.Gb=s(["H\xfcter","Guardianes","Gardiens","Custodi","Guardi\xf5es","\u30ad\u30fc\u30d1\u30fc"],t.s)
A.H2=s(["Sprache","Idioma","Langue","Lingua","Idioma","\u8a00\u8a9e"],t.s)
A.BX=s(["Neuester Erfolg","Logro m\xe1s reciente","Dernier succ\xe8s","Ultimo obiettivo","Conquista mais recente","\u6700\u65b0\u306e\u5b9f\u7e3e"],t.s)
A.yk=s(["Konklave verlassen","Abandonar C\xf3nclave","Quitter le Conclave","Lascia il Conclave","Sair do Conclave","\u30b3\u30f3\u30af\u30ec\u30a4\u30f4\u3092\u8131\u9000"],t.s)
A.HX=s(["Zum H\xfcter machen","Convertir en Guardi\xe1n","Nommer Gardien","Nomina Custode","Tornar Guardi\xe3o","\u30ad\u30fc\u30d1\u30fc\u306b\u3059\u308b"],t.s)
A.o2=s(["Zum W\xe4chter machen","Convertir en Custodio","Nommer Intendant","Nomina Custode anziano","Tornar Supervisor","\u30a6\u30a9\u30fc\u30c7\u30f3\u306b\u3059\u308b"],t.s)
A.Ac=s(["Maximale H\xfcterzahl","M\xe1ximo de Guardianes","Nombre maximal de Gardiens","Numero massimo di Custodi","M\xe1ximo de Guardi\xf5es","\u30ad\u30fc\u30d1\u30fc\u4e0a\u9650"],t.s)
A.Ba=s(["Nachricht an die Konklave\u2026","Mensaje al C\xf3nclave\u2026","\xc9crire au Conclave\u2026","Messaggio al Conclave\u2026","Mensagem para o Conclave\u2026","\u30b3\u30f3\u30af\u30ec\u30a4\u30f4\u306b\u30e1\u30c3\u30bb\u30fc\u30b8\u2026"],t.s)
A.w6=s(["Nachricht\u2026","Mensaje\u2026","Message\u2026","Messaggio\u2026","Mensagem\u2026","\u30e1\u30c3\u30bb\u30fc\u30b8\u2026"],t.s)
A.Aa=s(["Nachrichten","Mensajes","Messages","Messaggi","Mensagens","\u30e1\u30c3\u30bb\u30fc\u30b8"],t.s)
A.EW=s(["Nachrichten sind nur zwischen Freunden verf\xfcgbar.","Los mensajes solo est\xe1n disponibles entre amigos.","Les messages ne sont disponibles qu\u2019entre amis.","I messaggi sono disponibili solo tra amici.","Mensagens s\xf3 est\xe3o dispon\xedveis entre amigos.","\u30e1\u30c3\u30bb\u30fc\u30b8\u306f\u30d5\u30ec\u30f3\u30c9\u540c\u58eb\u3067\u306e\u307f\u5229\u7528\u3067\u304d\u307e\u3059\u3002"],t.s)
A.tB=s(["Nachrichten bleiben 24 Stunden verf\xfcgbar.","Los mensajes permanecen disponibles durante 24 horas.","Les messages restent disponibles pendant 24 heures.","I messaggi restano disponibili per 24 ore.","As mensagens ficam dispon\xedveis por 24 horas.","\u30e1\u30c3\u30bb\u30fc\u30b8\u306f24\u6642\u9593\u8868\u793a\u3055\u308c\u307e\u3059\u3002"],t.s)
A.EL=s(["Meine H\xfcter-Pr\xfcfungsrekorde","Mis r\xe9cords de Pruebas de Guardi\xe1n","Mes records d\u2019\xc9preuves de Gardien","I miei record delle Prove del Custode","Meus recordes de Provas de Guardi\xe3o","\u79c1\u306e\u30ad\u30fc\u30d1\u30fc\u30c8\u30e9\u30a4\u30a2\u30eb\u8a18\u9332"],t.s)
A.vd=s(["Noch keine Nachrichten. Sag Hallo!","A\xfan no hay mensajes. \xa1Saluda!","Aucun message. Dites bonjour !","Nessun messaggio. Di\u2019 ciao!","Ainda n\xe3o h\xe1 mensagens. Diga ol\xe1!","\u307e\u3060\u30e1\u30c3\u30bb\u30fc\u30b8\u306f\u3042\u308a\u307e\u305b\u3093\u3002\u6328\u62f6\u3057\u307e\u3057\u3087\u3046\uff01"],t.s)
A.HW=s(["Noch gibt es keine \xf6ffentlichen Konklaven. Du kannst die erste gr\xfcnden.","A\xfan no hay C\xf3nclaves p\xfablicos. Puedes fundar el primero.","Il n\u2019existe encore aucun Conclave public. Vous pouvez fonder le premier.","Non ci sono ancora Conclavi pubblici. Puoi fondare il primo.","Ainda n\xe3o h\xe1 Conclaves p\xfablicos. Voc\xea pode fundar o primeiro.","\u516c\u958b\u30b3\u30f3\u30af\u30ec\u30a4\u30f4\u306f\u307e\u3060\u3042\u308a\u307e\u305b\u3093\u3002\u6700\u521d\u306e\u3072\u3068\u3064\u3092\u8a2d\u7acb\u3067\u304d\u307e\u3059\u3002"],t.s)
A.o1=s(["Offene Konklaven","C\xf3nclaves abiertos","Conclaves ouverts","Conclavi aperti","Conclaves abertos","\u516c\u958b\u30b3\u30f3\u30af\u30ec\u30a4\u30f4"],t.s)
A.nR=s(["\xd6ffne DragonHaven, um sie zu lesen.","Abre DragonHaven para leerlo.","Ouvrez DragonHaven pour le lire.","Apri DragonHaven per leggerlo.","Abra DragonHaven para ler.","\u8aad\u3080\u306b\u306fDragonHaven\u3092\u958b\u3044\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.lB=s(["Private Nachrichten verschwinden nach 24 Stunden.","Los mensajes privados desaparecen despu\xe9s de 24 horas.","Les messages priv\xe9s disparaissent apr\xe8s 24 heures.","I messaggi privati scompaiono dopo 24 ore.","As mensagens privadas desaparecem ap\xf3s 24 horas.","\u30d7\u30e9\u30a4\u30d9\u30fc\u30c8\u30e1\u30c3\u30bb\u30fc\u30b8\u306f24\u6642\u9593\u5f8c\u306b\u6d88\u3048\u307e\u3059\u3002"],t.s)
A.Co=s(["\xd6ffentlich","P\xfablico","Public","Pubblico","P\xfablico","\u516c\u958b"],t.s)
A.y4=s(["Aus der Konklave entfernen","Expulsar del C\xf3nclave","Retirer du Conclave","Rimuovi dal Conclave","Remover do Conclave","\u30b3\u30f3\u30af\u30ec\u30a4\u30f4\u304b\u3089\u9664\u540d"],t.s)
A.jX=s(["Anfragen","Solicitar","Demander","Richiedi","Solicitar","\u7533\u8acb"],t.s)
A.xD=s(["Beitritt anfragen","Solicitar ingreso","Demander \xe0 rejoindre","Richiedi di partecipare","Solicitar entrada","\u53c2\u52a0\u7533\u8acb\u5236"],t.s)
A.vG=s(["Angefragt","Solicitado","Demand\xe9","Richiesto","Solicitado","\u7533\u8acb\u6e08\u307f"],t.s)
A.lM=s(["Teilen","Compartir","Partager","Condividi","Compartilhar","\u5171\u6709"],t.s)
A.xU=s(["Erfolge mit der Konklave teilen","Compartir logros con el C\xf3nclave","Partager les succ\xe8s avec le Conclave","Condividi gli obiettivi con il Conclave","Compartilhar conquistas com o Conclave","\u5b9f\u7e3e\u3092\u30b3\u30f3\u30af\u30ec\u30a4\u30f4\u3068\u5171\u6709"],t.s)
A.p2=s(["Aerie pflegen \xb7 +10 EP","Cuidar el Aerie \xb7 +10 XP","Entretenir l\u2019Aerie \xb7 +10 XP","Cura l\u2019Aerie \xb7 +10 PE","Cuidar do Aerie \xb7 +10 XP","\u30a8\u30a2\u30ea\u30fc\u3092\u624b\u5165\u308c \xb7 XP +10"],t.s)
A.Gw=s(["Dieser Konklavenname wird bereits verwendet.","Ese nombre de C\xf3nclave ya est\xe1 en uso.","Ce nom de Conclave est d\xe9j\xe0 utilis\xe9.","Quel nome di Conclave \xe8 gi\xe0 in uso.","Esse nome de Conclave j\xe1 est\xe1 em uso.","\u305d\u306e\u30b3\u30f3\u30af\u30ec\u30a4\u30f4\u540d\u306f\u65e2\u306b\u4f7f\u308f\u308c\u3066\u3044\u307e\u3059\u3002"],t.s)
A.zo=s(["W\xe4hle sorgf\xe4ltig: Dieser einzigartige Konklavenname kann sp\xe4ter nicht ge\xe4ndert werden.","Elige con cuidado: este nombre \xfanico de C\xf3nclave no se puede cambiar despu\xe9s.","Choisissez avec soin : ce nom unique de Conclave ne pourra plus \xeatre modifi\xe9.","Scegli con cura: questo nome univoco del Conclave non potr\xe0 essere cambiato in seguito.","Escolha com cuidado: este nome \xfanico de Conclave n\xe3o poder\xe1 ser alterado depois.","\u614e\u91cd\u306b\u9078\u3093\u3067\u304f\u3060\u3055\u3044\uff1a\u3053\u306e\u30e6\u30cb\u30fc\u30af\u306a\u30b3\u30f3\u30af\u30ec\u30a4\u30f4\u540d\u306f\u5f8c\u304b\u3089\u5909\u66f4\u3067\u304d\u307e\u305b\u3093\u3002"],t.s)
A.mV=s(["Ein Konklavenname kann nach der Gr\xfcndung nicht ge\xe4ndert werden.","El nombre de un C\xf3nclave no se puede cambiar despu\xe9s de fundarlo.","Le nom d\u2019un Conclave ne peut plus \xeatre modifi\xe9 apr\xe8s sa cr\xe9ation.","Il nome di un Conclave non pu\xf2 essere cambiato dopo la fondazione.","O nome de um Conclave n\xe3o pode ser alterado depois da funda\xe7\xe3o.","\u30b3\u30f3\u30af\u30ec\u30a4\u30f4\u540d\u306f\u8a2d\u7acb\u5f8c\u306b\u5909\u66f4\u3067\u304d\u307e\u305b\u3093\u3002"],t.s)
A.ox=s(["Im Aerie ist es still. Beginne das Gespr\xe4ch!","El Aerie est\xe1 en silencio. \xa1Inicia la conversaci\xf3n!","L\u2019Aerie est silencieux. Lancez la conversation !","L\u2019Aerie \xe8 silenzioso. Inizia la conversazione!","O Aerie est\xe1 quieto. Comece a conversa!","\u30a8\u30a2\u30ea\u30fc\u306f\u9759\u304b\u3067\u3059\u3002\u4f1a\u8a71\u3092\u59cb\u3081\u307e\u3057\u3087\u3046\uff01"],t.s)
A.pP=s(["Aerie, Chat und Chronik werden dauerhaft gel\xf6scht.","El Aerie, el chat y la Cr\xf3nica se eliminar\xe1n permanentemente.","L\u2019Aerie, le chat et la Chronique seront d\xe9finitivement supprim\xe9s.","L\u2019Aerie, la chat e la Cronaca verranno eliminati definitivamente.","O Aerie, o chat e a Cr\xf4nica ser\xe3o removidos permanentemente.","\u30a8\u30a2\u30ea\u30fc\u3001\u30c1\u30e3\u30c3\u30c8\u3001\u5e74\u4ee3\u8a18\u306f\u5b8c\u5168\u306b\u524a\u9664\u3055\u308c\u307e\u3059\u3002"],t.s)
A.CA=s(["Die Chronik ist noch leer.","La Cr\xf3nica todav\xeda est\xe1 vac\xeda.","La Chronique est encore vide.","La Cronaca \xe8 ancora vuota.","A Cr\xf4nica ainda est\xe1 vazia.","\u5e74\u4ee3\u8a18\u306f\u307e\u3060\u7a7a\u3067\u3059\u3002"],t.s)
A.o0=s(["Die Konklave","El C\xf3nclave","Le Conclave","Il Conclave","O Conclave","\u30b3\u30f3\u30af\u30ec\u30a4\u30f4"],t.s)
A.oz=s(["Diese Konklave wurde nicht gefunden.","No se pudo encontrar este C\xf3nclave.","Ce Conclave est introuvable.","Impossibile trovare questo Conclave.","Este Conclave n\xe3o foi encontrado.","\u3053\u306e\u30b3\u30f3\u30af\u30ec\u30a4\u30f4\u306f\u898b\u3064\u304b\u308a\u307e\u305b\u3093\u3067\u3057\u305f\u3002"],t.s)
A.rV=s(["Diese Konklave hat das heutige Aerie-Beitragslimit erreicht.","Este C\xf3nclave alcanz\xf3 el l\xedmite diario de contribuciones al Aerie.","Ce Conclave a atteint la limite quotidienne de contributions \xe0 l\u2019Aerie.","Questo Conclave ha raggiunto il limite giornaliero di contributi all\u2019Aerie.","Este Conclave atingiu o limite di\xe1rio de contribui\xe7\xf5es ao Aerie.","\u3053\u306e\u30b3\u30f3\u30af\u30ec\u30a4\u30f4\u306f\u672c\u65e5\u306e\u30a8\u30a2\u30ea\u30fc\u8ca2\u732e\u4e0a\u9650\u306b\u9054\u3057\u307e\u3057\u305f\u3002"],t.s)
A.xe=s(["Diese Konklaven-Einladung ist nicht mehr verf\xfcgbar.","Esta invitaci\xf3n al C\xf3nclave ya no est\xe1 disponible.","Cette invitation au Conclave n\u2019est plus disponible.","Questo invito al Conclave non \xe8 pi\xf9 disponibile.","Este convite para o Conclave n\xe3o est\xe1 mais dispon\xedvel.","\u3053\u306e\u30b3\u30f3\u30af\u30ec\u30a4\u30f4\u62db\u5f85\u306f\u5229\u7528\u3067\u304d\u307e\u305b\u3093\u3002"],t.s)
A.o5=s(["Diese Konklave ist voll.","Este C\xf3nclave est\xe1 lleno.","Ce Conclave est complet.","Questo Conclave \xe8 pieno.","Este Conclave est\xe1 cheio.","\u3053\u306e\u30b3\u30f3\u30af\u30ec\u30a4\u30f4\u306f\u6e80\u54e1\u3067\u3059\u3002"],t.s)
A.Dh=s(["Dieser Konklave kann man nur per Einladung beitreten.","Este C\xf3nclave es solo por invitaci\xf3n.","Ce Conclave est accessible sur invitation uniquement.","Questo Conclave \xe8 solo su invito.","Este Conclave \xe9 somente por convite.","\u3053\u306e\u30b3\u30f3\u30af\u30ec\u30a4\u30f4\u306f\u62db\u5f85\u5236\u3067\u3059\u3002"],t.s)
A.BD=s(["Diese Beitrittsanfrage ist nicht mehr verf\xfcgbar.","Esta solicitud de ingreso ya no est\xe1 disponible.","Cette demande d\u2019adh\xe9sion n\u2019est plus disponible.","Questa richiesta di partecipazione non \xe8 pi\xf9 disponibile.","Este pedido de entrada n\xe3o est\xe1 mais dispon\xedvel.","\u3053\u306e\u53c2\u52a0\u7533\u8acb\u306f\u5229\u7528\u3067\u304d\u307e\u305b\u3093\u3002"],t.s)
A.Al=s(["Dieser H\xfcter ist nicht mehr in der Konklave.","Este Guardi\xe1n ya no est\xe1 en el C\xf3nclave.","Ce Gardien n\u2019est plus dans le Conclave.","Questo Custode non fa pi\xf9 parte del Conclave.","Este Guardi\xe3o n\xe3o est\xe1 mais no Conclave.","\u3053\u306e\u30ad\u30fc\u30d1\u30fc\u306f\u3082\u3046\u30b3\u30f3\u30af\u30ec\u30a4\u30f4\u306b\u3044\u307e\u305b\u3093\u3002"],t.s)
A.ks=s(["Dieser H\xfcter nimmt keine Nachrichten an.","Este Guardi\xe1n no acepta mensajes.","Ce Gardien n\u2019accepte pas les messages.","Questo Custode non accetta messaggi.","Este Guardi\xe3o n\xe3o aceita mensagens.","\u3053\u306e\u30ad\u30fc\u30d1\u30fc\u306f\u30e1\u30c3\u30bb\u30fc\u30b8\u3092\u53d7\u3051\u4ed8\u3051\u3066\u3044\u307e\u305b\u3093\u3002"],t.s)
A.It=s(["Flightmaster \xfcbertragen","Transferir Flightmaster","Transf\xe9rer le r\xf4le de Flightmaster","Trasferisci Flightmaster","Transferir Flightmaster","\u30d5\u30e9\u30a4\u30c8\u30de\u30b9\u30bf\u30fc\u3092\u8b72\u6e21"],t.s)
A.FU=s(["\xdcbertrage zuerst den Flightmaster-Rang oder l\xf6se die Konklave auf.","Transfiere primero el rango de Flightmaster o disuelve el C\xf3nclave.","Transf\xe9rez d\u2019abord le rang de Flightmaster ou dissolvez le Conclave.","Prima trasferisci il grado di Flightmaster o sciogli il Conclave.","Transfira primeiro o posto de Flightmaster ou dissolva o Conclave.","\u5148\u306b\u30d5\u30e9\u30a4\u30c8\u30de\u30b9\u30bf\u30fc\u306e\u5f79\u8077\u3092\u8b72\u6e21\u3059\u308b\u304b\u3001\u30b3\u30f3\u30af\u30ec\u30a4\u30f4\u3092\u89e3\u6563\u3057\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.x9=s(["Pr\xfcfungsrekorde","R\xe9cords de Pruebas","Records d\u2019\xc9preuves","Record delle Prove","Recordes de Provas","\u30c8\u30e9\u30a4\u30a2\u30eb\u8a18\u9332"],t.s)
A.Kj=s(["Freigeschaltete Erfolge erscheinen im Konklaven-Chat und in der Chronik.","Los logros desbloqueados aparecen en el chat y la Cr\xf3nica de tu C\xf3nclave.","Les succ\xe8s d\xe9bloqu\xe9s apparaissent dans le chat et la Chronique de votre Conclave.","Gli obiettivi sbloccati appaiono nella chat e nella Cronaca del Conclave.","Conquistas desbloqueadas aparecem no chat e na Cr\xf4nica do Conclave.","\u89e3\u9664\u3057\u305f\u5b9f\u7e3e\u306f\u30b3\u30f3\u30af\u30ec\u30a4\u30f4\u306e\u30c1\u30e3\u30c3\u30c8\u3068\u5e74\u4ee3\u8a18\u306b\u8868\u793a\u3055\u308c\u307e\u3059\u3002"],t.s)
A.pX=s(["Schreibe eine Nachricht mit 1 bis 500 Zeichen.","Escribe un mensaje de entre 1 y 500 caracteres.","\xc9crivez un message de 1 \xe0 500 caract\xe8res.","Scrivi un messaggio da 1 a 500 caratteri.","Escreva uma mensagem de 1 a 500 caracteres.","1\uff5e500\u6587\u5b57\u3067\u30e1\u30c3\u30bb\u30fc\u30b8\u3092\u66f8\u3044\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.lN=s(["Nachricht schreiben\u2026","Escribe un mensaje\u2026","\xc9crire un message\u2026","Scrivi un messaggio\u2026","Escreva uma mensagem\u2026","\u30e1\u30c3\u30bb\u30fc\u30b8\u3092\u66f8\u304f\u2026"],t.s)
A.Es=s(["Du hast das Aerie heute bereits gepflegt.","Ya cuidaste el Aerie hoy.","Vous avez d\xe9j\xe0 entretenu l\u2019Aerie aujourd\u2019hui.","Hai gi\xe0 curato l\u2019Aerie oggi.","Voc\xea j\xe1 cuidou do Aerie hoje.","\u4eca\u65e5\u306f\u3059\u3067\u306b\u30a8\u30a2\u30ea\u30fc\u3092\u624b\u5165\u308c\u3057\u307e\u3057\u305f\u3002"],t.s)
A.xQ=s(["Du bist bereits in einer Konklave.","Ya est\xe1s en un C\xf3nclave.","Vous \xeates d\xe9j\xe0 dans un Conclave.","Fai gi\xe0 parte di un Conclave.","Voc\xea j\xe1 est\xe1 em um Conclave.","\u3059\u3067\u306b\u30b3\u30f3\u30af\u30ec\u30a4\u30f4\u306b\u53c2\u52a0\u3057\u3066\u3044\u307e\u3059\u3002"],t.s)
A.z5=s(["Du sendest Nachrichten zu schnell. Versuche es gleich noch einmal.","Est\xe1s enviando mensajes demasiado r\xe1pido. Int\xe9ntalo de nuevo pronto.","Vous envoyez des messages trop rapidement. R\xe9essayez bient\xf4t.","Stai inviando messaggi troppo velocemente. Riprova tra poco.","Voc\xea est\xe1 enviando mensagens r\xe1pido demais. Tente novamente em breve.","\u30e1\u30c3\u30bb\u30fc\u30b8\u306e\u9001\u4fe1\u304c\u901f\u3059\u304e\u307e\u3059\u3002\u5c11\u3057\u5f85\u3063\u3066\u304b\u3089\u518d\u8a66\u884c\u3057\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.kT=s(["Dein Konklavenrang darf das nicht.","Tu rango del C\xf3nclave no puede hacer eso.","Votre rang dans le Conclave ne permet pas cette action.","Il tuo grado nel Conclave non pu\xf2 farlo.","Seu posto no Conclave n\xe3o permite isso.","\u3042\u306a\u305f\u306e\u30b3\u30f3\u30af\u30ec\u30a4\u30f4\u5f79\u8077\u3067\u306f\u5b9f\u884c\u3067\u304d\u307e\u305b\u3093\u3002"],t.s)
A.zu=s(["Konklaven","C\xf3nclaves","Conclaves","Conclavi","Conclaves","\u30b3\u30f3\u30af\u30ec\u30a4\u30f4"],t.s)
A.rn=s(["Finde dein gemeinsames Aerie","Encuentra tu Aerie compartido","Trouvez votre Aerie partag\xe9","Trova il tuo Aerie condiviso","Encontre seu Aerie compartilhado","\u5171\u6709\u30a8\u30a2\u30ea\u30fc\u3092\u898b\u3064\u3051\u3088\u3046"],t.s)
A.ot=s(["Aktualisieren","Actualizar","Actualiser","Aggiorna","Atualizar","\u66f4\u65b0"],t.s)
A.D1=s(["Bis zu 20 H\xfcter","Hasta 20 Guardianes","Jusqu\u2019\xe0 20 Gardiens","Fino a 20 Custodi","At\xe9 20 Guardi\xf5es","\u6700\u592720\u4eba\u306e\u30ad\u30fc\u30d1\u30fc"],t.s)
A.x5=s(["10 Aerie-Stufen","10 etapas del Aerie","10 niveaux d\u2019Aerie","10 fasi dell\u2019Aerie","10 est\xe1gios do Aerie","10\u6bb5\u968e\u306e\u30a8\u30a2\u30ea\u30fc"],t.s)
A.o_=s(["Die Konklave ist voll","El C\xf3nclave est\xe1 lleno","Le Conclave est complet","Il Conclave \xe8 al completo","O Conclave est\xe1 cheio","\u30b3\u30f3\u30af\u30ec\u30a4\u30f4\u306f\u6e80\u54e1\u3067\u3059"],t.s)
A.uI=s(["Anfrage ausstehend","Solicitud pendiente","Demande en attente","Richiesta in attesa","Solicita\xe7\xe3o pendente","\u7533\u8acb\u4e2d"],t.s)
A.zT=s(["Beitritt anfragen","Solicitar unirse","Demander \xe0 rejoindre","Richiedi di unirti","Solicitar entrada","\u53c2\u52a0\u3092\u7533\u8acb"],t.s)
A.Ax=s(["Dieser Konklave beitreten","Unirse a este C\xf3nclave","Rejoindre ce Conclave","Unisciti a questo Conclave","Entrar neste Conclave","\u3053\u306e\u30b3\u30f3\u30af\u30ec\u30a4\u30f4\u306b\u53c2\u52a0"],t.s)
A.z8=s(["Nachrichten bleiben 24 Stunden","Los mensajes permanecen 24 horas","Les messages restent 24 heures","I messaggi restano per 24 ore","As mensagens ficam por 24 horas","\u30e1\u30c3\u30bb\u30fc\u30b8\u306f24\u6642\u9593\u6b8b\u308a\u307e\u3059"],t.s)
A.wb=s(["Im Aerie ist es still","El Aerie est\xe1 en silencio","L\u2019Aerie est silencieux","L\u2019Aerie \xe8 silenzioso","O Aerie est\xe1 silencioso","\u30a8\u30a2\u30ea\u30fc\u306f\u9759\u304b\u3067\u3059"],t.s)
A.BH=s(["Beginne das erste Gespr\xe4ch mit deinen Mith\xfctern.","Inicia la primera conversaci\xf3n con tus compa\xf1eros Guardianes.","Lancez la premi\xe8re conversation avec les autres Gardiens.","Inizia la prima conversazione con gli altri Custodi.","Inicie a primeira conversa com os outros Guardi\xf5es.","\u4ef2\u9593\u306e\u30ad\u30fc\u30d1\u30fc\u3068\u6700\u521d\u306e\u4f1a\u8a71\u3092\u59cb\u3081\u307e\u3057\u3087\u3046\u3002"],t.s)
A.yY=s(["Erfolg freigeschaltet","Logro desbloqueado","Succ\xe8s d\xe9bloqu\xe9","Obiettivo sbloccato","Conquista desbloqueada","\u5b9f\u7e3e\u89e3\u9664"],t.s)
A.Ja=s(["Weniger anzeigen","Mostrar menos","Afficher moins","Mostra meno","Mostrar menos","\u6298\u308a\u305f\u305f\u3080"],t.s)
A.Ea=s(["Konklaven-H\xfcter","Guardianes del C\xf3nclave","Gardiens du Conclave","Custodi del Conclave","Guardi\xf5es do Conclave","\u30b3\u30f3\u30af\u30ec\u30a4\u30f4\u306e\u30ad\u30fc\u30d1\u30fc"],t.s)
A.Hp=s(["Dein Rang","Tu rango","Votre rang","Il tuo grado","Seu posto","\u3042\u306a\u305f\u306e\u5f79\u8077"],t.s)
A.Bm=s(["Eine neue Chronik","Una nueva Cr\xf3nica","Une nouvelle Chronique","Una nuova Cronaca","Uma nova Cr\xf4nica","\u65b0\u3057\u3044\u5e74\u4ee3\u8a18"],t.s)
A.AE=s(["Meilensteine, neue H\xfcter und geteilte Erfolge werden hier festgehalten.","Aqu\xed se registrar\xe1n hitos, nuevos Guardianes y logros compartidos.","Les jalons, nouveaux Gardiens et succ\xe8s partag\xe9s seront consign\xe9s ici.","Qui verranno registrati traguardi, nuovi Custodi e obiettivi condivisi.","Marcos, novos Guardi\xf5es e conquistas compartilhadas ser\xe3o registrados aqui.","\u7bc0\u76ee\u3001\u65b0\u3057\u3044\u30ad\u30fc\u30d1\u30fc\u3001\u5171\u6709\u3055\u308c\u305f\u5b9f\u7e3e\u304c\u3053\u3053\u306b\u8a18\u9332\u3055\u308c\u307e\u3059\u3002"],t.s)
A.Eh=s(["CHAT","CHAT","CHAT","CHAT","CHAT","\u30c1\u30e3\u30c3\u30c8"],t.s)
A.L5=s(["zeigt dir alles. Du kannst jetzt \xfcberspringen und diese vollst\xe4ndige F\xfchrung sp\xe4ter \xfcber das Drei-Punkte-Men\xfc erneut starten.","te ense\xf1ar\xe1 todo. Puedes saltar ahora y repetir este recorrido completo m\xe1s tarde desde el men\xfa de tres puntos.","vous fera visiter. Vous pouvez passer maintenant et relancer cette visite compl\xe8te plus tard depuis le menu \xe0 trois points.","ti far\xe0 da guida. Puoi saltare ora e ripetere pi\xf9 tardi questo tour completo dal menu con i tre puntini.","vai mostrar tudo. Voc\xea pode pular agora e repetir este tour completo mais tarde pelo menu de tr\xeas pontos.","\u304c\u6848\u5185\u3057\u307e\u3059\u3002\u4eca\u306f\u30b9\u30ad\u30c3\u30d7\u3057\u3066\u3001\u5f8c\u3067\u4e09\u70b9\u30e1\u30cb\u30e5\u30fc\u304b\u3089\u3053\u306e\u5b8c\u5168\u306a\u30c4\u30a2\u30fc\u3092\u3082\u3046\u4e00\u5ea6\u59cb\u3081\u3089\u308c\u307e\u3059\u3002"],t.s)
A.uL=s(["Freunde und Profile","Amigos y perfiles","Amis et profils","Amici e profili","Amigos e perfis","\u30d5\u30ec\u30f3\u30c9\u3068\u30d7\u30ed\u30d5\u30a3\u30fc\u30eb"],t.s)
A.px=s(["Nachrichten und sichere Tauschgesch\xe4fte","Mensajes e intercambios seguros","Messages et \xe9changes s\xe9curis\xe9s","Messaggi e scambi sicuri","Mensagens e trocas seguras","\u30e1\u30c3\u30bb\u30fc\u30b8\u3068\u5b89\u5168\u306a\u4ea4\u63db"],t.s)
A.AQ=s(["Nutze CHAT auf einer Freundeskarte f\xfcr private Nachrichten der letzten 24 Stunden. Tauschangebote reservieren geeignete Eier, Truhen und Relikte, bis der Tausch abgeschlossen ist oder abl\xe4uft.","Usa CHAT en la tarjeta de un amigo para ver mensajes privados de las \xfaltimas 24 horas. Las ofertas reservan huevos, cofres y Reliquias v\xe1lidos hasta que el intercambio se complete o caduque.","Utilisez CHAT sur la carte d\u2019un ami pour les messages priv\xe9s des derni\xe8res 24 heures. Les offres r\xe9servent les \u0153ufs, coffres et Reliques admissibles jusqu\u2019\xe0 la fin ou l\u2019expiration de l\u2019\xe9change.","Usa CHAT sulla scheda di un amico per i messaggi privati delle ultime 24 ore. Le offerte riservano uova, scrigni e Reliquie idonei finch\xe9 lo scambio non termina o scade.","Use CHAT no cart\xe3o de um amigo para mensagens privadas das \xfaltimas 24 horas. As ofertas reservam ovos, ba\xfas e Rel\xedquias v\xe1lidos at\xe9 a troca ser conclu\xedda ou expirar.","\u30d5\u30ec\u30f3\u30c9\u30ab\u30fc\u30c9\u306e\u300c\u30c1\u30e3\u30c3\u30c8\u300d\u304b\u3089\u904e\u53bb24\u6642\u9593\u306e\u500b\u5225\u30e1\u30c3\u30bb\u30fc\u30b8\u3092\u78ba\u8a8d\u3067\u304d\u307e\u3059\u3002\u4ea4\u63db\u5bfe\u8c61\u306e\u5375\u3001\u5b9d\u7bb1\u3001\u30ec\u30ea\u30c3\u30af\u306f\u3001\u4ea4\u63db\u306e\u5b8c\u4e86\u307e\u305f\u306f\u671f\u9650\u5207\u308c\u307e\u3067\u4e88\u7d04\u3055\u308c\u307e\u3059\u3002"],t.s)
A.EB=s(["Deine Konklave","Tu C\xf3nclave","Votre Conclave","Il tuo Conclave","Seu Conclave","\u3042\u306a\u305f\u306e\u30b3\u30f3\u30af\u30ec\u30a4\u30f4"],t.s)
A.u5=s(["Die Konklave befindet sich direkt unter der Freunde\xfcbersicht. Tritt einer bei oder gr\xfcnde eine, chatte mit bis zu 20 H\xfctern, pflege das gemeinsame Aerie, teile Erfolge und folge der Chronik.","El C\xf3nclave est\xe1 justo debajo del resumen de Amigos. \xdanete a uno o f\xfandalo, chatea con hasta 20 Guardianes, cuida el Aerie compartido, comparte logros y sigue su Cr\xf3nica.","Le Conclave se trouve juste sous l\u2019aper\xe7u des Amis. Rejoignez-en ou fondez-en un, discutez avec jusqu\u2019\xe0 20 Gardiens, entretenez l\u2019Aerie partag\xe9, partagez des succ\xe8s et suivez sa Chronique.","Il Conclave si trova subito sotto il riepilogo Amici. Unisciti o fondane uno, chatta con un massimo di 20 Custodi, cura l\u2019Aerie condiviso, condividi obiettivi e segui la Cronaca.","O Conclave fica logo abaixo do resumo de Amigos. Entre em um ou funde o seu, converse com at\xe9 20 Guardi\xf5es, cuide do Aerie compartilhado, compartilhe conquistas e acompanhe a Cr\xf4nica.","\u30b3\u30f3\u30af\u30ec\u30a4\u30f4\u306f\u30d5\u30ec\u30f3\u30c9\u6982\u8981\u306e\u3059\u3050\u4e0b\u306b\u3042\u308a\u307e\u3059\u3002\u53c2\u52a0\u307e\u305f\u306f\u8a2d\u7acb\u3057\u3001\u6700\u592720\u4eba\u306e\u30ad\u30fc\u30d1\u30fc\u3068\u4f1a\u8a71\u3057\u3001\u5171\u6709\u30a8\u30a2\u30ea\u30fc\u3092\u80b2\u3066\u3001\u5b9f\u7e3e\u3092\u5171\u6709\u3057\u3066\u5e74\u4ee3\u8a18\u3092\u8ffd\u3048\u307e\u3059\u3002"],t.s)
A.Gz=s(["Mini-, kurze und lange Abenteuer dauern zunehmend l\xe4nger. Passende Expertise verk\xfcrzt ihre Dauer. Abgeschlossene Karten zeigen Belohnungen; ein aktives Solo-Abenteuer kann ohne Belohnung abgebrochen werden.","Las Aventuras Mini, Cortas y Largas duran cada vez m\xe1s. La Pericia adecuada reduce su duraci\xf3n. Las tarjetas completadas muestran las recompensas; una Aventura individual activa puede abortarse sin recompensa.","Les Aventures Mini, Courtes et Longues sont de plus en plus longues. L\u2019Expertise correspondante r\xe9duit leur dur\xe9e. Les cartes termin\xe9es indiquent les r\xe9compenses ; une Aventure solo active peut \xeatre abandonn\xe9e sans r\xe9compense.","Le Avventure Mini, Brevi e Lunghe durano progressivamente di pi\xf9. La Competenza adatta ne riduce la durata. Le schede completate mostrano le ricompense; un\u2019Avventura in solitaria attiva pu\xf2 essere annullata senza ricompense.","As Aventuras Mini, Curtas e Longas duram cada vez mais. A Especialidade correspondente reduz a dura\xe7\xe3o. Os cart\xf5es conclu\xeddos mostram recompensas; uma Aventura solo ativa pode ser abortada sem recompensa.","\u30df\u30cb\u3001\u30b7\u30e7\u30fc\u30c8\u3001\u30ed\u30f3\u30b0\u306e\u5192\u967a\u306f\u9806\u306b\u9577\u304f\u306a\u308a\u307e\u3059\u3002\u5bfe\u5fdc\u3059\u308b\u5c02\u9580\u5024\u3067\u6240\u8981\u6642\u9593\u304c\u77ed\u7e2e\u3055\u308c\u307e\u3059\u3002\u5b8c\u4e86\u30ab\u30fc\u30c9\u306b\u306f\u5831\u916c\u304c\u8868\u793a\u3055\u308c\u3001\u9032\u884c\u4e2d\u306e\u30bd\u30ed\u5192\u967a\u306f\u5831\u916c\u306a\u3057\u3067\u4e2d\u6b62\u3067\u304d\u307e\u3059\u3002"],t.s)
A.pF=s(["Gruppen- und Spezialabenteuer","Aventuras de Grupo y Especiales","Aventures de Groupe et Sp\xe9ciales","Avventure di Gruppo e Speciali","Aventuras em Grupo e Especiais","\u30b0\u30eb\u30fc\u30d7\u5192\u967a\u3068\u7279\u5225\u5192\u967a"],t.s)
A.Ee=s(["Gruppenabenteuer zeigen vor dem Beitritt die erforderliche kombinierte Expertise. Spezialabenteuer erscheinen w\xe4hrend Events, zeigen garantierte Belohnungen und k\xf6nnen nach rechtzeitigem Start immer beendet werden.","Las Aventuras de Grupo muestran el requisito de Pericia combinada antes de unirse. Las Aventuras Especiales aparecen durante eventos, muestran recompensas garantizadas y pueden terminarse si se iniciaron a tiempo.","Les Aventures de Groupe affichent l\u2019Expertise combin\xe9e requise avant de rejoindre. Les Aventures Sp\xe9ciales apparaissent pendant les \xe9v\xe9nements, montrent les r\xe9compenses garanties et restent terminables si elles ont commenc\xe9 \xe0 temps.","Le Avventure di Gruppo mostrano il requisito di Competenza combinata prima di partecipare. Le Avventure Speciali compaiono durante gli eventi, mostrano ricompense garantite e possono essere concluse se iniziate in tempo.","As Aventuras em Grupo mostram o requisito combinado de Especialidade antes da entrada. Aventuras Especiais aparecem durante eventos, mostram recompensas garantidas e podem ser conclu\xeddas se iniciadas a tempo.","\u30b0\u30eb\u30fc\u30d7\u5192\u967a\u306f\u53c2\u52a0\u524d\u306b\u5408\u8a08\u5c02\u9580\u5024\u306e\u6761\u4ef6\u3092\u8868\u793a\u3057\u307e\u3059\u3002\u7279\u5225\u5192\u967a\u306f\u30a4\u30d9\u30f3\u30c8\u4e2d\u306b\u767b\u5834\u3057\u3001\u78ba\u5b9a\u5831\u916c\u3092\u793a\u3057\u3001\u671f\u9593\u5185\u306b\u958b\u59cb\u3059\u308c\u3070\u6700\u5f8c\u307e\u3067\u5b8c\u4e86\u3067\u304d\u307e\u3059\u3002"],t.s)
A.uM=s(["Pr\xfcfungen und Sternbild","Pruebas y constelaci\xf3n","\xc9preuves et constellation","Prove e costellazione","Provas e constela\xe7\xe3o","\u30c8\u30e9\u30a4\u30a2\u30eb\u3068\u661f\u5ea7"],t.s)
A.yl=s(["Pr\xfcfungen f\xfcllen sich alle 15 Minuten bis zu drei wartenden Versuchen auf. Might, Arcana und Spirit haben jeweils ein Geschicklichkeitsspiel. Spiele t\xe4glich f\xfcr das Sieben-Tage-Sternbild; ein verpasster Tag setzt es zur\xfcck.","Las Pruebas se recargan cada 15 minutos, hasta tres en espera. Might, Arcana y Spirit tienen un juego de habilidad. Juega a diario para la constelaci\xf3n de siete d\xedas; faltar un d\xeda la reinicia.","Les \xc9preuves se rechargent toutes les 15 minutes, jusqu\u2019\xe0 trois en attente. Might, Arcana et Spirit ont chacun un jeu d\u2019adresse. Jouez chaque jour pour la constellation de sept jours ; manquer un jour la r\xe9initialise.","Le Prove si ricaricano ogni 15 minuti, fino a tre in attesa. Might, Arcana e Spirit hanno ciascuno un gioco di abilit\xe0. Gioca ogni giorno per la costellazione di sette giorni; saltare un giorno la azzera.","As Provas recarregam a cada 15 minutos, com at\xe9 tr\xeas esperando. Might, Arcana e Spirit t\xeam cada um um jogo de habilidade. Jogue diariamente para a constela\xe7\xe3o de sete dias; perder um dia reinicia tudo.","\u30c8\u30e9\u30a4\u30a2\u30eb\u306f15\u5206\u3054\u3068\u306b\u88dc\u5145\u3055\u308c\u3001\u6700\u59273\u56de\u5206\u307e\u3067\u8caf\u307e\u308a\u307e\u3059\u3002Might\u3001Arcana\u3001Spirit\u306b\u306f\u305d\u308c\u305e\u308c\u6280\u80fd\u30b2\u30fc\u30e0\u304c\u3042\u308a\u307e\u3059\u30027\u65e5\u9593\u306e\u661f\u5ea7\u306b\u306f\u6bce\u65e5\u6311\u6226\u3057\u30011\u65e5\u9003\u3059\u3068\u30ea\u30bb\u30c3\u30c8\u3055\u308c\u307e\u3059\u3002"],t.s)
A.BJ=s(["Entwicklung und Expertise","Evoluci\xf3n y Pericia","\xc9volution et Expertise","Evoluzione e Competenza","Evolu\xe7\xe3o e Especialidade","\u9032\u5316\u3068\u5c02\u9580\u5024"],t.s)
A.pN=s(["Trainiere Expertise durch Abenteuer, Pr\xfcfungen und Akademielektionen. Entwicklungsentscheidungen erh\xf6hen unterschiedliche H\xf6chstwerte; MAX folgt immer dem richtigen Drachen, seiner Form und seiner Ascension-Grenze.","Entrena la Pericia mediante Aventuras, Pruebas y lecciones de la Academia. Las elecciones de evoluci\xf3n elevan distintos m\xe1ximos; MAX siempre sigue al drag\xf3n, la forma y el l\xedmite de Ascensi\xf3n correctos.","Entra\xeenez l\u2019Expertise gr\xe2ce aux Aventures, \xc9preuves et le\xe7ons de l\u2019Acad\xe9mie. Les choix d\u2019\xe9volution augmentent diff\xe9rents maximums ; MAX suit toujours le bon dragon, sa forme et sa limite d\u2019Ascension.","Allena la Competenza con Avventure, Prove e lezioni dell\u2019Accademia. Le scelte evolutive aumentano massimi diversi; MAX segue sempre il drago, la forma e il limite di Ascensione corretti.","Treine Especialidade em Aventuras, Provas e aulas da Academia. As escolhas de evolu\xe7\xe3o aumentam m\xe1ximos diferentes; MAX sempre segue o drag\xe3o, a forma e o limite de Ascens\xe3o corretos.","\u5192\u967a\u3001\u30c8\u30e9\u30a4\u30a2\u30eb\u3001\u30a2\u30ab\u30c7\u30df\u30fc\u306e\u6388\u696d\u3067\u5c02\u9580\u5024\u3092\u935b\u3048\u307e\u3059\u3002\u9032\u5316\u306e\u9078\u629e\u306b\u3088\u308a\u4e0a\u9650\u304c\u5909\u308f\u308a\u3001MAX\u306f\u5e38\u306b\u30c9\u30e9\u30b4\u30f3\u3001\u5f62\u614b\u3001\u30a2\u30bb\u30f3\u30b7\u30e7\u30f3\u306b\u5408\u3063\u305f\u6b63\u3057\u3044\u4e0a\u9650\u3067\u8868\u793a\u3055\u308c\u307e\u3059\u3002"],t.s)
A.F0=s(["Drachen und Draconomicon","Dragones y Draconomicon","Dragons et Draconomicon","Draghi e Draconomicon","Drag\xf5es e Draconomicon","\u30c9\u30e9\u30b4\u30f3\u3068\u30c9\u30e9\u30b3\u30ce\u30df\u30b3\u30f3"],t.s)
A.Bv=s(["Meine Drachen bietet Raster- und kompakte Listenansichten, umkehrbare Sortierung und kombinierte Filter f\xfcr Form, Seltenheit und Spektraldrachen. Das Draconomicon erfasst jede Familie und entwickelte Form.","Mis Dragones tiene vistas de cuadr\xedcula y lista compacta, orden reversible y filtros combinados por forma, rareza y dragones espectrales. El Draconomicon registra cada familia y forma evolucionada.","Mes Dragons propose une grille et une liste compacte, un tri inversable et des filtres combin\xe9s par forme, raret\xe9 et dragons spectraux. Le Draconomicon suit chaque famille et forme \xe9volu\xe9e.","I Miei Draghi offre griglia ed elenco compatto, ordinamento invertibile e filtri combinati per forma, rarit\xe0 e draghi spettrali. Il Draconomicon registra ogni famiglia e forma evoluta.","Meus Drag\xf5es tem visualiza\xe7\xf5es em grade e lista compacta, ordem revers\xedvel e filtros combinados por forma, raridade e drag\xf5es espectrais. O Draconomicon acompanha cada fam\xedlia e forma evolu\xedda.","\u300c\u30de\u30a4\u30c9\u30e9\u30b4\u30f3\u300d\u306b\u306f\u30b0\u30ea\u30c3\u30c9\u3068\u30b3\u30f3\u30d1\u30af\u30c8\u30ea\u30b9\u30c8\u3001\u53cd\u8ee2\u3067\u304d\u308b\u4e26\u3073\u9806\u3001\u5f62\u614b\u30fb\u30ec\u30a2\u5ea6\u30fb\u30b9\u30da\u30af\u30c8\u30e9\u30eb\u306e\u8907\u5408\u30d5\u30a3\u30eb\u30bf\u30fc\u304c\u3042\u308a\u307e\u3059\u3002\u30c9\u30e9\u30b3\u30ce\u30df\u30b3\u30f3\u306f\u5168\u3066\u306e\u7cfb\u7d71\u3068\u9032\u5316\u5f62\u614b\u3092\u8a18\u9332\u3057\u307e\u3059\u3002"],t.s)
A.EH=s(["Nest, R\xe4ume und Turm","Nido, habitaciones y Torre","Nid, pi\xe8ces et Tour","Nido, stanze e Torre","Ninho, c\xf4modos e Torre","\u5de3\u3001\u90e8\u5c4b\u3001\u30bf\u30ef\u30fc"],t.s)
A.we=s(["Br\xfcte ein Ei im Dachnest aus und beobachte seinen Timer vom Turm aus. Starter-Eier lassen sich durch Antippen beschleunigen. Baue, dekoriere und ordne alle R\xe4ume au\xdfer dem Dachnest neu.","Incuba un huevo en el Nido de la Azotea y consulta su temporizador desde la Torre. Los Huevos Iniciales se aceleran al tocarlos. Construye, decora y reordena todas las habitaciones salvo el Nido de la Azotea.","Incubez un \u0153uf dans le Nid du Toit et suivez son minuteur depuis la Tour. Touchez les \u0152ufs de D\xe9part pour les acc\xe9l\xe9rer. Construisez, d\xe9corez et r\xe9organisez toutes les pi\xe8ces sauf le Nid du Toit.","Incuba un uovo nel Nido sul Tetto e controllane il timer dalla Torre. Tocca le Uova Iniziali per accelerarle. Costruisci, decora e riordina ogni stanza tranne il Nido sul Tetto.","Incube um ovo no Ninho do Terra\xe7o e acompanhe o tempo pela Torre. Toque nos Ovos Iniciais para acelerar. Construa, decore e reordene todos os c\xf4modos, menos o Ninho do Terra\xe7o.","\u5c4b\u4e0a\u306e\u5de3\u3067\u5375\u3092\u5b75\u5316\u3055\u305b\u3001\u30bf\u30ef\u30fc\u304b\u3089\u6b8b\u308a\u6642\u9593\u3092\u78ba\u8a8d\u3067\u304d\u307e\u3059\u3002\u30b9\u30bf\u30fc\u30bf\u30fc\u30a8\u30c3\u30b0\u306f\u30bf\u30c3\u30d7\u3067\u77ed\u7e2e\u3067\u304d\u307e\u3059\u3002\u5c4b\u4e0a\u306e\u5de3\u4ee5\u5916\u306e\u90e8\u5c4b\u306f\u5efa\u7bc9\u3001\u88c5\u98fe\u3001\u4e26\u3079\u66ff\u3048\u304c\u3067\u304d\u307e\u3059\u3002"],t.s)
A.rE=s(["Die Akademie wird mit Turmstufe 5 ganz unten freigeschaltet. W\xe4hle verf\xfcgbare Sch\xfcler, verdiene Lektionssterne und Expertise, nutze Mentoren und schlie\xdfe nach Bestehen aller F\xe4cher vorzeitig ab.","La Academia se desbloquea con el nivel 5 de la Torre, al final. Elige alumnos disponibles, consigue estrellas y Pericia, usa mentores y grad\xfaate antes tras aprobar todas las materias.","L\u2019Acad\xe9mie se d\xe9bloque au niveau 5 de la Tour, tout en bas. Choisissez des \xe9l\xe8ves disponibles, gagnez des \xe9toiles et de l\u2019Expertise, utilisez des mentors et obtenez un dipl\xf4me anticip\xe9 apr\xe8s avoir r\xe9ussi chaque mati\xe8re.","L\u2019Accademia si sblocca al livello 5 della Torre, in fondo. Scegli studenti disponibili, ottieni stelle e Competenza, usa mentori e diplomati in anticipo dopo aver superato ogni materia.","A Academia \xe9 liberada no n\xedvel 5 da Torre, na parte inferior. Escolha alunos dispon\xedveis, ganhe estrelas e Especialidade, use mentores e forme-se mais cedo ap\xf3s passar em todas as mat\xe9rias.","\u30a2\u30ab\u30c7\u30df\u30fc\u306f\u30bf\u30ef\u30fc\u30ec\u30d9\u30eb5\u3067\u6700\u4e0b\u90e8\u306b\u89e3\u653e\u3055\u308c\u307e\u3059\u3002\u53c2\u52a0\u3067\u304d\u308b\u751f\u5f92\u3092\u9078\u3073\u3001\u6388\u696d\u306e\u661f\u3068\u5c02\u9580\u5024\u3092\u7372\u5f97\u3057\u3001\u30e1\u30f3\u30bf\u30fc\u3092\u4f7f\u3044\u3001\u5168\u79d1\u76ee\u306b\u5408\u683c\u3059\u308c\u3070\u65e9\u671f\u5352\u696d\u3067\u304d\u307e\u3059\u3002"],t.s)
A.xK=s(["Inventar organisieren","Organizar Inventario","Organiser l\u2019Inventaire","Organizza Inventario","Organizar Invent\xe1rio","\u30a4\u30f3\u30d9\u30f3\u30c8\u30ea\u6574\u7406"],t.s)
A.n1=s(["Eier und M\xf6bel speichern Raster-/Listenansicht, Sortierung und Filter. Eierzeilen zeigen die Brutzeit; Truhen folgen einer festen Seltenheitsreihenfolge. F\xfcr Tausch reservierte Gegenst\xe4nde bleiben nicht verf\xfcgbar.","Huevos y muebles guardan las vistas de cuadr\xedcula/lista, el orden y los filtros. Las filas de huevos muestran el tiempo de eclosi\xf3n; los cofres usan un orden fijo de rareza. Los objetos reservados para intercambio no est\xe1n disponibles.","Les \u0153ufs et meubles m\xe9morisent les vues grille/liste, le tri et les filtres. Les lignes d\u2019\u0153ufs indiquent le temps d\u2019\xe9closion ; les coffres suivent un ordre de raret\xe9 fixe. Les objets r\xe9serv\xe9s \xe0 un \xe9change restent indisponibles.","Uova e mobili salvano le viste griglia/elenco, l\u2019ordinamento e i filtri. Le righe delle uova mostrano il tempo di schiusa; gli scrigni seguono un ordine di rarit\xe0 fisso. Gli oggetti riservati per uno scambio restano indisponibili.","Ovos e m\xf3veis salvam as visualiza\xe7\xf5es em grade/lista, a ordem e os filtros. As linhas dos ovos mostram o tempo de incuba\xe7\xe3o; os ba\xfas seguem uma ordem fixa de raridade. Itens reservados para troca ficam indispon\xedveis.","\u5375\u3068\u5bb6\u5177\u3067\u306f\u30b0\u30ea\u30c3\u30c9\uff0f\u30ea\u30b9\u30c8\u3001\u4e26\u3073\u9806\u3001\u30d5\u30a3\u30eb\u30bf\u30fc\u304c\u4fdd\u5b58\u3055\u308c\u307e\u3059\u3002\u5375\u306e\u884c\u306b\u306f\u5b75\u5316\u6642\u9593\u304c\u8868\u793a\u3055\u308c\u3001\u5b9d\u7bb1\u306f\u56fa\u5b9a\u306e\u30ec\u30a2\u5ea6\u9806\u3067\u3059\u3002\u4ea4\u63db\u4e88\u7d04\u4e2d\u306e\u30a2\u30a4\u30c6\u30e0\u306f\u4f7f\u7528\u3067\u304d\u307e\u305b\u3093\u3002"],t.s)
A.vW=s(["Truhen und Relikte","Cofres y Reliquias","Coffres et Reliques","Scrigni e Reliquie","Ba\xfas e Rel\xedquias","\u5b9d\u7bb1\u3068\u30ec\u30ea\u30c3\u30af"],t.s)
A.HT=s(["\xd6ffne eine Truhe im Vollbild oder, wenn m\xf6glich, zehn zusammen. Relikte zeigen, ob sie verbrauchbar, tauschbar oder ausr\xfcstbar sind; ein ausger\xfcstetes EP-Relikt kann zwischen Drachen wechseln.","Abre un cofre a pantalla completa o diez a la vez cuando sea posible. Las Reliquias indican si son consumibles, intercambiables o equipables; una Reliquia de EXP equipada puede cambiar de drag\xf3n.","Ouvrez un coffre en plein \xe9cran, ou dix ensemble si possible. Les Reliques indiquent si elles sont consommables, \xe9changeables ou \xe9quipables ; une Relique d\u2019EXP \xe9quip\xe9e peut passer d\u2019un dragon \xe0 l\u2019autre.","Apri uno scrigno a schermo intero, oppure dieci insieme quando possibile. Le Reliquie indicano se sono consumabili, scambiabili o equipaggiabili; una Reliquia PE equipaggiata pu\xf2 passare tra i draghi.","Abra um ba\xfa em tela cheia ou dez juntos quando poss\xedvel. As Rel\xedquias mostram se s\xe3o consum\xedveis, negoci\xe1veis ou equip\xe1veis; uma Rel\xedquia de XP equipada pode mudar de drag\xe3o.","\u5b9d\u7bb1\u306f1\u500b\u3092\u5168\u753b\u9762\u3067\u3001\u53ef\u80fd\u306a\u308910\u500b\u3092\u307e\u3068\u3081\u3066\u958b\u3051\u3089\u308c\u307e\u3059\u3002\u30ec\u30ea\u30c3\u30af\u306b\u306f\u6d88\u8017\u54c1\u3001\u4ea4\u63db\u53ef\u3001\u88c5\u5099\u53ef\u304c\u8868\u793a\u3055\u308c\u3001\u88c5\u5099\u4e2d\u306eXP\u30ec\u30ea\u30c3\u30af\u306f\u30c9\u30e9\u30b4\u30f3\u9593\u3067\u4ed8\u3051\u66ff\u3048\u3089\u308c\u307e\u3059\u3002"],t.s)
A.wi=s(["Shops und W\xe4hrungen","Tiendas y monedas","Boutiques et monnaies","Negozi e valute","Lojas e moedas","\u30b7\u30e7\u30c3\u30d7\u3068\u901a\u8ca8"],t.s)
A.wE=s(["Durchsuche getrennte M\xfcnz-, Edelstein- und Paketshops. M\xf6bel, Relikte und Sammlungstruhen zeigen ihre W\xe4hrung deutlich. Optionale Shop-Pakete ersetzen niemals das normale Spiel.","Explora tiendas separadas de Monedas, Gemas y Packs. Los muebles, Reliquias y cofres de colecci\xf3n muestran claramente su moneda. Los lotes opcionales nunca sustituyen al juego normal.","Parcourez des boutiques distinctes de Pi\xe8ces, Gemmes et Packs. Les meubles, Reliques et coffres de collection indiquent clairement leur monnaie. Les lots optionnels ne remplacent jamais le jeu normal.","Esplora negozi separati di Monete, Gemme e Pacchetti. Mobili, Reliquie e scrigni da collezione mostrano chiaramente la valuta. I pacchetti opzionali non sostituiscono mai il gioco normale.","Explore lojas separadas de Moedas, Gemas e Pacotes. M\xf3veis, Rel\xedquias e ba\xfas de cole\xe7\xe3o mostram claramente a moeda. Pacotes opcionais nunca substituem a jogabilidade normal.","\u30b3\u30a4\u30f3\u3001\u30b8\u30a7\u30e0\u3001\u30d1\u30c3\u30af\u306f\u5225\u3005\u306e\u30b7\u30e7\u30c3\u30d7\u3067\u3059\u3002\u5bb6\u5177\u3001\u30ec\u30ea\u30c3\u30af\u3001\u30b3\u30ec\u30af\u30b7\u30e7\u30f3\u5b9d\u7bb1\u306b\u306f\u901a\u8ca8\u304c\u660e\u78ba\u306b\u8868\u793a\u3055\u308c\u307e\u3059\u3002\u4efb\u610f\u306e\u30b9\u30c8\u30a2\u30bb\u30c3\u30c8\u304c\u901a\u5e38\u306e\u30b2\u30fc\u30e0\u30d7\u30ec\u30a4\u3092\u7f6e\u304d\u63db\u3048\u308b\u3053\u3068\u306f\u3042\u308a\u307e\u305b\u3093\u3002"],t.s)
A.G5=s(["Musik und Supporter-Vanity","M\xfasica y cosm\xe9ticos de Supporter","Musique et apparence Supporter","Musica e vanity Supporter","M\xfasica e itens visuais de Supporter","\u97f3\u697d\u3068\u30b5\u30dd\u30fc\u30bf\u30fc\u88c5\u98fe"],t.s)
A.mQ=s(["Musiktruhen schalten immer ein fehlendes Lied frei. Die Jukebox steuert Lieder, Reihenfolge, Zufall und Wiederholung. Pakete k\xf6nnen eigene Portr\xe4ts, Titel, Abzeichen, Rahmen und M\xf6bel hinzuf\xfcgen.","Los Cofres de M\xfasica siempre desbloquean una canci\xf3n que falta. La Jukebox controla canciones, orden, Aleatorio y Repetir. Los Packs pueden a\xf1adir retratos, t\xedtulos, insignias, marcos y muebles independientes.","Les Coffres de Musique d\xe9bloquent toujours un morceau manquant. Le Jukebox g\xe8re les morceaux, l\u2019ordre, le mode al\xe9atoire et la r\xe9p\xe9tition. Les Packs peuvent ajouter des portraits, titres, badges, cadres et meubles distincts.","Gli Scrigni Musicali sbloccano sempre un brano mancante. Il Jukebox controlla brani, ordine, Riproduzione casuale e Ripeti. I Pacchetti possono aggiungere ritratti, titoli, badge, cornici e mobili separati.","Ba\xfas de M\xfasica sempre liberam uma m\xfasica que falta. A Jukebox controla m\xfasicas, ordem, Aleat\xf3rio e Repetir. Pacotes podem adicionar retratos, t\xedtulos, distintivos, molduras e m\xf3veis separados.","\u30df\u30e5\u30fc\u30b8\u30c3\u30af\u5b9d\u7bb1\u306f\u672a\u6240\u6301\u306e\u66f2\u3092\u5fc5\u305a\u89e3\u653e\u3057\u307e\u3059\u3002\u30b8\u30e5\u30fc\u30af\u30dc\u30c3\u30af\u30b9\u3067\u306f\u66f2\u3001\u9806\u756a\u3001\u30b7\u30e3\u30c3\u30d5\u30eb\u3001\u30ea\u30d4\u30fc\u30c8\u3092\u8a2d\u5b9a\u3067\u304d\u307e\u3059\u3002\u30d1\u30c3\u30af\u306b\u306f\u72ec\u7acb\u3057\u305f\u8096\u50cf\u3001\u79f0\u53f7\u3001\u30d0\u30c3\u30b8\u3001\u30d5\u30ec\u30fc\u30e0\u3001\u5bb6\u5177\u3092\u8ffd\u52a0\u3067\u304d\u307e\u3059\u3002"],t.s)
A.KB=s(["Konto, Audio und Benachrichtigungen","Cuenta, audio y notificaciones","Compte, audio et notifications","Account, audio e notifiche","Conta, \xe1udio e notifica\xe7\xf5es","\u30a2\u30ab\u30a6\u30f3\u30c8\u3001\u97f3\u58f0\u3001\u901a\u77e5"],t.s)
A.wW=s(["Kontoinformationen verwaltet Vanity, Nachrichten, Audio und Jukebox. Benachrichtigungsarten ben\xf6tigen die Ger\xe4teberechtigung und \xf6ffnen das richtige Ziel. Cloud-Back-ups und der Wiederherstellungsverlauf sch\xfctzen den Onlinefortschritt.","Informaci\xf3n de la cuenta gestiona cosm\xe9ticos, mensajes, audio y Jukebox. Los tipos de notificaci\xf3n requieren permiso del dispositivo y abren el destino correcto. Las copias en la nube y el historial de restauraci\xf3n protegen el progreso en l\xednea.","Les Informations du compte g\xe8rent l\u2019apparence, les messages, l\u2019audio et le Jukebox. Les types de notifications n\xe9cessitent l\u2019autorisation de l\u2019appareil et ouvrent la bonne destination. Les sauvegardes cloud et l\u2019historique de restauration prot\xe8gent la progression en ligne.","Informazioni account gestisce vanity, messaggi, audio e Jukebox. I tipi di notifica richiedono il permesso del dispositivo e aprono la destinazione corretta. Backup cloud e cronologia di ripristino proteggono i progressi online.","Informa\xe7\xf5es da conta gerencia itens visuais, mensagens, \xe1udio e Jukebox. Os tipos de notifica\xe7\xe3o exigem permiss\xe3o do dispositivo e abrem o destino correto. Backups na nuvem e o hist\xf3rico de restaura\xe7\xe3o protegem o progresso online.","\u30a2\u30ab\u30a6\u30f3\u30c8\u60c5\u5831\u3067\u306f\u88c5\u98fe\u3001\u30e1\u30c3\u30bb\u30fc\u30b8\u3001\u97f3\u58f0\u3001\u30b8\u30e5\u30fc\u30af\u30dc\u30c3\u30af\u30b9\u3092\u7ba1\u7406\u3057\u307e\u3059\u3002\u901a\u77e5\u306b\u306f\u7aef\u672b\u306e\u8a31\u53ef\u304c\u5fc5\u8981\u3067\u3001\u6b63\u3057\u3044\u753b\u9762\u3092\u958b\u304d\u307e\u3059\u3002\u30af\u30e9\u30a6\u30c9\u30d0\u30c3\u30af\u30a2\u30c3\u30d7\u3068\u5fa9\u5143\u5c65\u6b74\u304c\u30aa\u30f3\u30e9\u30a4\u30f3\u9032\u884c\u3092\u5b88\u308a\u307e\u3059\u3002"],t.s)
A.Ay=s(["Journal, Erfolge und Hilfe","Diario, logros y ayuda","Journal, succ\xe8s et aide","Diario, obiettivi e aiuto","Di\xe1rio, conquistas e ajuda","\u30b8\u30e3\u30fc\u30ca\u30eb\u3001\u5b9f\u7e3e\u3001\u30d8\u30eb\u30d7"],t.s)
A.mp=s(["Das Drei-Punkte-Men\xfc \xf6ffnet au\xdferdem Sprache, Erfolge, das H\xfcter-Journal und dieses Tutorial. Das Journal zeichnet Meilensteine auf; geheime Erfolge werden erst nach dem Verdienen sichtbar.","El men\xfa de tres puntos tambi\xe9n abre Idioma, Logros, el Diario del Guardi\xe1n y este Tutorial. El Diario registra hitos; los logros secretos solo se revelan al conseguirlos.","Le menu \xe0 trois points ouvre aussi Langue, Succ\xe8s, le Journal du Gardien et ce Tutoriel. Le Journal consigne les jalons ; les succ\xe8s secrets ne se r\xe9v\xe8lent qu\u2019une fois obtenus.","Il menu con i tre puntini apre anche Lingua, Obiettivi, il Diario del Custode e questo Tutorial. Il Diario registra i traguardi; gli obiettivi segreti si rivelano solo quando vengono ottenuti.","O menu de tr\xeas pontos tamb\xe9m abre Idioma, Conquistas, o Di\xe1rio do Guardi\xe3o e este Tutorial. O Di\xe1rio registra marcos; conquistas secretas s\xf3 aparecem quando s\xe3o obtidas.","\u4e09\u70b9\u30e1\u30cb\u30e5\u30fc\u304b\u3089\u8a00\u8a9e\u3001\u5b9f\u7e3e\u3001\u30ad\u30fc\u30d1\u30fc\u30b8\u30e3\u30fc\u30ca\u30eb\u3001\u3053\u306e\u30c1\u30e5\u30fc\u30c8\u30ea\u30a2\u30eb\u3092\u958b\u3051\u307e\u3059\u3002\u30b8\u30e3\u30fc\u30ca\u30eb\u306f\u7bc0\u76ee\u3092\u8a18\u9332\u3057\u3001\u79d8\u5bc6\u306e\u5b9f\u7e3e\u306f\u7372\u5f97\u3057\u305f\u6642\u3060\u3051\u660e\u3089\u304b\u306b\u306a\u308a\u307e\u3059\u3002"],t.s)
A.Lw=new B.u(A.On,[A.If,A.kE,A.pZ,A.mH,A.qQ,A.Ii,A.re,A.nF,A.nQ,A.DC,A.Kt,A.BI,A.wr,A.Gc,A.v5,A.zQ,A.GI,A.Kz,A.ym,A.He,A.oU,A.Dk,A.F8,A.J8,A.q7,A.za,A.EE,A.wF,A.JB,A.qt,A.mq,A.ES,A.n0,A.zr,A.wd,A.pU,A.BE,A.tw,A.qe,A.Hx,A.Hg,A.xL,A.Dm,A.Dx,A.I1,A.on,A.Gb,A.H2,A.BX,A.yk,A.HX,A.o2,A.Ac,A.Ba,A.w6,A.Aa,A.EW,A.tB,A.EL,A.vd,A.HW,A.o1,A.nR,A.lB,A.Co,A.y4,A.jX,A.xD,A.vG,A.lM,A.xU,A.p2,A.Gw,A.zo,A.mV,A.ox,A.pP,A.CA,A.o0,A.oz,A.rV,A.xe,A.o5,A.Dh,A.BD,A.Al,A.ks,A.It,A.FU,A.x9,A.Kj,A.pX,A.lN,A.Es,A.xQ,A.z5,A.kT,A.zu,A.rn,A.ot,A.D1,A.x5,A.o_,A.uI,A.zT,A.Ax,A.z8,A.wb,A.BH,A.yY,A.Ja,A.Ea,A.Hp,A.Bm,A.AE,A.Eh,A.L5,A.uL,A.px,A.AQ,A.EB,A.u5,A.Gz,A.pF,A.Ee,A.uM,A.yl,A.BJ,A.pN,A.F0,A.Bv,A.EH,A.we,A.rE,A.xK,A.n1,A.vW,A.HT,A.wi,A.wE,A.G5,A.mQ,A.KB,A.wW,A.Ay,A.mp],t.M)
A.NU={refresh:0,purchase_portrait_chest:1,purchase_title_chest:2,purchase_music_chest:3,purchase_furniture:4,purchase_relic:5,open_chests:6,open_special_chests:7,use_relic:8,use_astral_lens:9,tag_egg:10,return_egg:11,craft_altar_relic:12,use_altar_relic:13,use_chronoshard:14,use_wayfinder:15,equip_twinstar:16,activate_egg:17,hatch_egg:18,name_dragon:19,evolve_dragon:20,buy_starlight_treat:21,release_dragon:22,start_adventure:23,dismiss_adventure:24,claim_adventure:25,abort_adventure:26,dismiss_trial:27,claim_constellation:28,unlock_room:29,build_floor:30,repair_floor:31,upgrade_ward:32,complete_tutorial:33,redeem_code:34}
A.bq={}
A.af=new B.T(A.bq,0,t.O)
A.O8={catalogId:0}
A.QQ=new B.T(A.O8,1,t.O)
A.Or={relic:0}
A.cH=new B.T(A.Or,1,t.O)
A.Ox={tier:0,count:1}
A.QI=new B.T(A.Ox,2,t.O)
A.O9={catalogId:0,count:1}
A.QM=new B.T(A.O9,2,t.O)
A.Os={relic:0,dragonId:1}
A.QY=new B.T(A.Os,2,t.O)
A.Of={eggId:0}
A.bx=new B.T(A.Of,1,t.O)
A.Oh={eggId:0,tagged:1}
A.QO=new B.T(A.Oh,2,t.O)
A.Og={eggId:0,sinisterConfirmed:1}
A.QD=new B.T(A.Og,2,t.O)
A.Ot={relic:0,eggId:1}
A.R_=new B.T(A.Ot,2,t.O)
A.Oq={reductionPercent:0}
A.QH=new B.T(A.Oq,1,t.O)
A.Om={kind:0,replaceAdventureId:1}
A.QU=new B.T(A.Om,2,t.O)
A.Ob={dragonId:0}
A.aU=new B.T(A.Ob,1,t.O)
A.Oc={dragonId:0,name:1}
A.R0=new B.T(A.Oc,2,t.O)
A.O6={adventureId:0,dragonId:1}
A.QE=new B.T(A.O6,2,t.O)
A.O5={adventureId:0}
A.QX=new B.T(A.O5,1,t.O)
A.Ow={runId:0}
A.cJ=new B.T(A.Ow,1,t.O)
A.Oo={offerId:0}
A.QF=new B.T(A.Oo,1,t.O)
A.Ov={roomId:0}
A.cK=new B.T(A.Ov,1,t.O)
A.Ol={index:0}
A.QS=new B.T(A.Ol,1,t.O)
A.Oj={fullyViewed:0}
A.QJ=new B.T(A.Oj,1,t.O)
A.Oa={code:0}
A.QR=new B.T(A.Oa,1,t.O)
A.Lx=new B.u(A.NU,[A.af,A.af,A.af,A.af,A.QQ,A.cH,A.QI,A.QM,A.QY,A.bx,A.QO,A.QD,A.cH,A.R_,A.QH,A.QU,A.aU,A.bx,A.bx,A.R0,A.aU,A.aU,A.aU,A.QE,A.QX,A.cJ,A.cJ,A.QF,A.af,A.cK,A.cK,A.QS,A.af,A.QJ,A.QR],B.W("u<d,cZ<d>>"))
A.cw={en:0,nl:1,de:2,fr:3,es:4,pt:5,it:6,ja:7}
A.Ly=new B.u(A.cw,["Achievement unlocked","Prestatie behaald","Erfolg freigeschaltet","Succ\xe8s d\xe9bloqu\xe9","Logro desbloqueado","Conquista desbloqueada","Obiettivo sbloccato","\u5b9f\u7e3e\u89e3\u9664"],t.p1)
A.NY={"Spirit \xb7 trace the path to the lantern":0,"Start at the wisp. Keep your finger down and inside the edges.":1,"Arcana \xb7 remember the pumpkin face":2,"Remember the pumpkin face, trace the path within its edges, then shatter the curse.":3,[u.A]:4,[u._]:5,[u.q]:6,[u.M]:7,[u.X]:8,"A Heartlight invitation":9,"Your Heartlight partner is ready":10,"Rosebound Crossing completed":11,"Your shared reward is ready in Adventures.":12,"Event ranking":13,"Sign in with a verified account to enter a seasonal Trial.":14,"The event server could not start this Trial. Please try again.":15,"This seasonal Trial is no longer available.":16,"All three Expertises provide a small, capped play-assist. They never multiply your score.":17,"Shared reward ready":18,"Waiting for acceptance":19,"Invites you":20,"Both dragons are ready":21,"Waiting for the creator":22,"Rosebound Crossing":23,"Your Valentine rewards are safely claimed.":24,"The reward could not be claimed yet.":25,Friend:26,"Choose your Heartlight partner":27,"Friends and Conclave keepers are listed here. You can also invite any registered Keeper by ID.":28,"Keeper ID":29,"Send invitation":30,"Sign in with a verified account to invite your Valentine partner.":31,"Heartlight invitation sent. Your dragon is reserved while you wait.":32,"The invitation could not be sent.":33,"Exactly 2 registered Keepers, each with one available dragon.":34,"The Haven Spectrum":35,"The highlighted event music is yours during this event and disappears when it closes.":36,"The final light is sealed!":37,"Tap when the ring turns gold":38,"Arcana \xb7 remember this recipe":39,"Arcana \xb7 find the matching gift":40,"Begin Trial":41,"The server could not verify this seasonal Trial. No reward was changed.":42,"Your Trial reward is safe, but this offline score was not added to the event ranking.":43,"TEST EVENT \xb7 SIMULATED":44,"Preview only: these rewards and this score were not added to your permanent production account.":45,"The private 48-hour event preview is now active.":46,"This event preview is already active.":47,"This private preview code is not available for this Keeper ID.":48,"This event preview is not available for this Keeper.":49,"This event preview code is not active.":50,"This seasonal event is not recognized.":51,"This seasonal event is not available right now.":52,"This Trial session expired. Start a new seasonal Trial.":53,"The server could not validate this Trial score.":54,"You already completed this edition of the event adventure.":55,"One of these Keepers already has an active Valentine adventure.":56,"That dragon is no longer available for this adventure.":57,"This Valentine invitation has changed. Refresh and try again.":58,"These Valentine rewards are not ready yet.":59,"These Valentine rewards were already claimed.":60,"The Valentine reward could not be linked to your local dragon.":61,"Private test ranking":62,"World ranking \xc2\xb7 results remain visible for 5 days":63,"Rankings could not be loaded.":64,"No official score yet. Be the first light on the board!":65,"Seasonal Chronicle":66}
A.zw=s(["Spirit \xb7 folge dem Pfad zur Laterne","Spirit \xb7 sigue el sendero hasta el farol","Spirit \xb7 suis le chemin vers la lanterne","Spirit \xb7 segui il sentiero fino alla lanterna","Spirit \xb7 segue o caminho at\xe9 \xe0 lanterna","Spirit \xb7 \u30e9\u30f3\u30bf\u30f3\u307e\u3067\u9053\u3092\u306a\u305e\u308d\u3046"],t.s)
A.wK=s(["Beginne beim Irrlicht. Lass den Finger auf dem Bildschirm und bleibe innerhalb der R\xe4nder.","Empieza en la luz. Mant\xe9n el dedo en la pantalla y dentro de los bordes.","Commence au feu follet. Garde le doigt sur l\u2019\xe9cran et entre les bords.","Inizia dal fuoco fatuo. Tieni il dito sullo schermo e dentro i bordi.","Come\xe7a no fogo-f\xe1tuo. Mant\xe9m o dedo no ecr\xe3 e dentro das margens.","\u9b3c\u706b\u304b\u3089\u59cb\u3081\u3088\u3046\u3002\u6307\u3092\u753b\u9762\u304b\u3089\u96e2\u3055\u305a\u3001\u9053\u306e\u5185\u5074\u3092\u306a\u305e\u3063\u3066\u306d\u3002"],t.s)
A.vn=s(["Arcana \xb7 merke dir das K\xfcrbisgesicht","Arcana \xb7 recuerda la cara de la calabaza","Arcana \xb7 m\xe9morise le visage de la citrouille","Arcana \xb7 ricorda il volto della zucca","Arcana \xb7 memoriza a cara da ab\xf3bora","Arcana \xb7 \u30ab\u30dc\u30c1\u30e3\u306e\u9854\u3092\u899a\u3048\u3088\u3046"],t.s)
A.uf=s(["Merke dir das K\xfcrbisgesicht, folge dem Pfad innerhalb seiner R\xe4nder und zerschmettere dann den Fluch.","Recuerda la cara de la calabaza, sigue el sendero sin salir de los bordes y rompe la maldici\xf3n.","M\xe9morise le visage de la citrouille, suis le chemin entre ses bords, puis brise la mal\xe9diction.","Ricorda il volto della zucca, segui il sentiero dentro i bordi e poi spezza la maledizione.","Memoriza a cara da ab\xf3bora, segue o caminho dentro das margens e quebra a maldi\xe7\xe3o.","\u30ab\u30dc\u30c1\u30e3\u306e\u9854\u3092\u899a\u3048\u3001\u9053\u304b\u3089\u306f\u307f\u51fa\u3055\u305a\u306b\u306a\u305e\u3063\u3066\u304b\u3089\u3001\u546a\u3044\u3092\u6253\u3061\u7815\u3053\u3046\u3002"],t.s)
A.tm=s(["Eine wachsame gr\xfcne Flamme windet sich um die Schale. Dieses Ei scheint an eine seltene Herbstnacht gebunden.","Una vigilante llama verde rodea el cascar\xf3n. Este huevo parece ligado a una extra\xf1a noche de oto\xf1o.","Une flamme verte vigilante s\u2019enroule autour de la coquille. Cet \u0153uf semble li\xe9 \xe0 une rare nuit d\u2019automne.","Una vigile fiamma verde avvolge il guscio. Quest\u2019uovo sembra legato a una rara notte d\u2019autunno.","Uma chama verde vigilante envolve a casca. Este ovo parece ligado a uma rara noite de outono.","\u898b\u5b88\u308b\u3088\u3046\u306a\u7dd1\u306e\u708e\u304c\u6bbb\u3092\u5305\u3080\u3002\u3053\u306e\u5375\u306f\u3001\u3081\u3063\u305f\u306b\u306a\u3044\u79cb\u306e\u591c\u3068\u7d50\u3070\u308c\u3066\u3044\u308b\u3088\u3046\u3060\u3002"],t.s)
A.lj=s(["Unter der Schale scheint ein Winterstern zu atmen. Dieses Ei tr\xe4gt die W\xe4rme einer besonderen Feuerstelle.","Una estrella invernal parece respirar bajo el cascar\xf3n. Este huevo lleva el calor de un hogar especial.","Une \xe9toile d\u2019hiver semble respirer sous la coquille. Cet \u0153uf porte la chaleur d\u2019un foyer particulier.","Una stella d\u2019inverno sembra respirare sotto il guscio. Quest\u2019uovo custodisce il calore di un focolare speciale.","Uma estrela de inverno parece respirar sob a casca. Este ovo carrega o calor de uma lareira especial.","\u6bbb\u306e\u4e0b\u3067\u51ac\u306e\u661f\u304c\u606f\u3065\u3044\u3066\u3044\u308b\u3002\u3053\u306e\u5375\u306f\u3001\u7279\u5225\u306a\u7089\u8fba\u306e\u306c\u304f\u3082\u308a\u3092\u5bbf\u3057\u3066\u3044\u308b\u3002"],t.s)
A.ty=s(["Eine ferne Glocke antwortet dem ersten Licht im Inneren. Dieses Ei geh\xf6rt zu einer Jahreswende.","Una campana lejana responde a la primera luz de su interior. Este huevo pertenece al cambio de a\xf1o.","Une cloche lointaine r\xe9pond \xe0 la premi\xe8re lueur int\xe9rieure. Cet \u0153uf appartient au passage vers la nouvelle ann\xe9e.","Una campana lontana risponde alla prima luce al suo interno. Quest\u2019uovo appartiene al volgere dell\u2019anno.","Um sino distante responde \xe0 primeira luz em seu interior. Este ovo pertence \xe0 virada do ano.","\u9060\u304f\u306e\u9418\u304c\u5185\u306a\u308b\u6700\u521d\u306e\u5149\u306b\u5fdc\u3048\u308b\u3002\u3053\u306e\u5375\u306f\u5e74\u306e\u5909\u308f\u308a\u76ee\u306b\u751f\u307e\u308c\u305f\u3082\u306e\u3060\u3002"],t.s)
A.xM=s(["Zwei leise Herzschl\xe4ge hallen durch die Schale. Dieses Ei erinnert sich an ein gemeinsames Versprechen.","Dos latidos serenos resuenan en el cascar\xf3n. Este huevo recuerda una promesa compartida.","Deux battements paisibles r\xe9sonnent dans la coquille. Cet \u0153uf se souvient d\u2019une promesse partag\xe9e.","Due battiti quieti risuonano nel guscio. Quest\u2019uovo ricorda una promessa condivisa.","Duas batidas tranquilas ecoam pela casca. Este ovo se lembra de uma promessa compartilhada.","\u4e8c\u3064\u306e\u7a4f\u3084\u304b\u306a\u9f13\u52d5\u304c\u6bbb\u306b\u97ff\u304f\u3002\u3053\u306e\u5375\u306f\u3001\u5206\u304b\u3061\u5408\u3063\u305f\u7d04\u675f\u3092\u899a\u3048\u3066\u3044\u308b\u3002"],t.s)
A.rk=s(["Jede Farbe schimmert, ohne eine andere zu verdecken. Dieses Ei f\xfchlt sich freudig und unverkennbar besonders an.","Cada color brilla sin ocultar a los dem\xe1s. Este huevo se siente alegre e inconfundiblemente especial.","Chaque couleur scintille sans en cacher une autre. Cet \u0153uf rayonne d\u2019une joie r\xe9solument unique.","Ogni colore risplende senza nasconderne un altro. Quest\u2019uovo \xe8 gioiosamente e inconfondibilmente speciale.","Cada cor brilha sem esconder nenhuma outra. Este ovo parece alegre e inconfundivelmente especial.","\u3069\u306e\u8272\u3082\u307b\u304b\u306e\u8272\u3092\u96a0\u3055\u305a\u8f1d\u3044\u3066\u3044\u308b\u3002\u3053\u306e\u5375\u306f\u559c\u3073\u306b\u6e80\u3061\u3001\u7d1b\u308c\u3082\u306a\u304f\u7279\u5225\u3060\u3002"],t.s)
A.DF=s(["Eine Herzlicht-Einladung","Una invitaci\xf3n de Luz de Coraz\xf3n","Une invitation de C\u0153ur-lumi\xe8re","Un invito di Luce del Cuore","Um convite de Luz do Cora\xe7\xe3o","\u30cf\u30fc\u30c8\u30e9\u30a4\u30c8\u3078\u306e\u62db\u5f85"],t.s)
A.uJ=s(["Dein Herzlicht-Partner ist bereit","Tu pareja de Luz de Coraz\xf3n est\xe1 lista","Votre partenaire de C\u0153ur-lumi\xe8re est pr\xeat","Il tuo partner di Luce del Cuore \xe8 pronto","Sua parceria de Luz do Cora\xe7\xe3o est\xe1 pronta","\u30cf\u30fc\u30c8\u30e9\u30a4\u30c8\u306e\u76f8\u624b\u306e\u6e96\u5099\u304c\u3067\u304d\u307e\u3057\u305f"],t.s)
A.Cm=s(["Rosenbund-\xdcberquerung abgeschlossen","Traves\xeda del V\xednculo de Rosas completada","Travers\xe9e du Lien de Rose termin\xe9e","Traversata del Vincolo di Rose completata","Travessia do La\xe7o de Rosas conclu\xedda","\u30ed\u30fc\u30ba\u30d0\u30a6\u30f3\u30c9\u30fb\u30af\u30ed\u30c3\u30b7\u30f3\u30b0\u5b8c\u4e86"],t.s)
A.Hv=s(["Eure gemeinsame Belohnung ist unter Abenteuer bereit.","Vuestra recompensa compartida est\xe1 lista en Aventuras.","Votre r\xe9compense commune vous attend dans Aventures.","La vostra ricompensa condivisa \xe8 pronta in Avventure.","Sua recompensa compartilhada est\xe1 pronta em Aventuras.","\u5171\u6709\u5831\u916c\u3092\u300c\u30a2\u30c9\u30d9\u30f3\u30c1\u30e3\u30fc\u300d\u3067\u53d7\u3051\u53d6\u308c\u307e\u3059\u3002"],t.s)
A.w5=s(["Event-Rangliste","Clasificaci\xf3n del evento","Classement de l\u2019\xe9v\xe9nement","Classifica dell\u2019evento","Ranking do evento","\u30a4\u30d9\u30f3\u30c8\u30e9\u30f3\u30ad\u30f3\u30b0"],t.s)
A.FH=s(["Melde dich mit einem best\xe4tigten Konto an, um an einer saisonalen Pr\xfcfung teilzunehmen.","Inicia sesi\xf3n con una cuenta verificada para participar en una Prueba de temporada.","Connectez-vous avec un compte v\xe9rifi\xe9 pour participer \xe0 une \xc9preuve saisonni\xe8re.","Accedi con un account verificato per partecipare a una Prova stagionale.","Entre com uma conta verificada para participar de uma Prova sazonal.","\u30b7\u30fc\u30ba\u30f3\u30c8\u30e9\u30a4\u30a2\u30eb\u306b\u53c2\u52a0\u3059\u308b\u306b\u306f\u3001\u8a8d\u8a3c\u6e08\u307f\u30a2\u30ab\u30a6\u30f3\u30c8\u3067\u30b5\u30a4\u30f3\u30a4\u30f3\u3057\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.A3=s(["Der Event-Server konnte diese Pr\xfcfung nicht starten. Bitte versuche es erneut.","El servidor del evento no pudo iniciar esta Prueba. Int\xe9ntalo de nuevo.","Le serveur de l\u2019\xe9v\xe9nement n\u2019a pas pu lancer cette \xc9preuve. Veuillez r\xe9essayer.","Il server dell\u2019evento non ha potuto avviare questa Prova. Riprova.","O servidor do evento n\xe3o conseguiu iniciar esta Prova. Tente novamente.","\u30a4\u30d9\u30f3\u30c8\u30b5\u30fc\u30d0\u30fc\u304c\u3053\u306e\u30c8\u30e9\u30a4\u30a2\u30eb\u3092\u958b\u59cb\u3067\u304d\u307e\u305b\u3093\u3067\u3057\u305f\u3002\u3082\u3046\u4e00\u5ea6\u304a\u8a66\u3057\u304f\u3060\u3055\u3044\u3002"],t.s)
A.uk=s(["Diese saisonale Pr\xfcfung ist nicht mehr verf\xfcgbar.","Esta Prueba de temporada ya no est\xe1 disponible.","Cette \xc9preuve saisonni\xe8re n\u2019est plus disponible.","Questa Prova stagionale non \xe8 pi\xf9 disponibile.","Esta Prova sazonal n\xe3o est\xe1 mais dispon\xedvel.","\u3053\u306e\u30b7\u30fc\u30ba\u30f3\u30c8\u30e9\u30a4\u30a2\u30eb\u306f\u7d42\u4e86\u3057\u307e\u3057\u305f\u3002"],t.s)
A.tq=s(["Alle drei Expertisen bieten eine kleine, begrenzte Spielhilfe. Sie vervielfachen niemals deine Punktzahl.","Las tres Pericias ofrecen una peque\xf1a ayuda limitada. Nunca multiplican tu puntuaci\xf3n.","Les trois Expertises offrent une aide de jeu l\xe9g\xe8re et plafonn\xe9e. Elles ne multiplient jamais votre score.","Tutte e tre le Competenze offrono un piccolo aiuto limitato. Non moltiplicano mai il punteggio.","As tr\xeas Especialidades oferecem uma pequena ajuda limitada. Elas nunca multiplicam sua pontua\xe7\xe3o.","3\u3064\u306e\u5c02\u9580\u80fd\u529b\u306f\u3044\u305a\u308c\u3082\u3001\u4e0a\u9650\u4ed8\u304d\u306e\u5c0f\u3055\u306a\u88dc\u52a9\u3092\u4e0e\u3048\u307e\u3059\u3002\u30b9\u30b3\u30a2\u500d\u7387\u306b\u306f\u5f71\u97ff\u3057\u307e\u305b\u3093\u3002"],t.s)
A.vZ=s(["Gemeinsame Belohnung bereit","Recompensa compartida lista","R\xe9compense commune pr\xeate","Ricompensa condivisa pronta","Recompensa compartilhada pronta","\u5171\u6709\u5831\u916c\u306e\u6e96\u5099\u5b8c\u4e86"],t.s)
A.CO=s(["Warten auf Annahme","Esperando aceptaci\xf3n","En attente d\u2019acceptation","In attesa di accettazione","Aguardando aceita\xe7\xe3o","\u627f\u8a8d\u5f85\u3061"],t.s)
A.m0=s(["L\xe4dt dich ein","Te invita","Vous invite","Ti invita","Convida voc\xea","\u3042\u306a\u305f\u3092\u62db\u5f85\u3057\u3066\u3044\u307e\u3059"],t.s)
A.qf=s(["Beide Drachen sind bereit","Ambos dragones est\xe1n listos","Les deux dragons sont pr\xeats","Entrambi i draghi sono pronti","Os dois drag\xf5es est\xe3o prontos","2\u982d\u306e\u30c9\u30e9\u30b4\u30f3\u306e\u6e96\u5099\u304c\u3067\u304d\u307e\u3057\u305f"],t.s)
A.mu=s(["Warten auf den Ersteller","Esperando al creador","En attente du cr\xe9ateur","In attesa del creatore","Aguardando o criador","\u4f5c\u6210\u8005\u3092\u5f85\u3063\u3066\u3044\u307e\u3059"],t.s)
A.ou=s(["Rosenbund-\xdcberquerung","Traves\xeda del V\xednculo de Rosas","Travers\xe9e du Lien de Rose","Traversata del Vincolo di Rose","Travessia do La\xe7o de Rosas","\u30ed\u30fc\u30ba\u30d0\u30a6\u30f3\u30c9\u30fb\u30af\u30ed\u30c3\u30b7\u30f3\u30b0"],t.s)
A.Df=s(["Deine Valentinsbelohnungen wurden sicher abgeholt.","Tus recompensas de San Valent\xedn se han reclamado de forma segura.","Vos r\xe9compenses de la Saint-Valentin ont bien \xe9t\xe9 r\xe9cup\xe9r\xe9es.","Le tue ricompense di San Valentino sono state riscattate in sicurezza.","Suas recompensas de Dia dos Namorados foram resgatadas com seguran\xe7a.","\u30d0\u30ec\u30f3\u30bf\u30a4\u30f3\u5831\u916c\u3092\u5b89\u5168\u306b\u53d7\u3051\u53d6\u308a\u307e\u3057\u305f\u3002"],t.s)
A.JR=s(["Die Belohnung konnte noch nicht abgeholt werden.","La recompensa a\xfan no se ha podido reclamar.","La r\xe9compense n\u2019a pas encore pu \xeatre r\xe9cup\xe9r\xe9e.","Non \xe8 stato ancora possibile riscattare la ricompensa.","A recompensa ainda n\xe3o p\xf4de ser resgatada.","\u5831\u916c\u306f\u307e\u3060\u53d7\u3051\u53d6\u308c\u307e\u305b\u3093\u3002"],t.s)
A.B6=s(["Freund","Amigo","Ami","Amico","Amigo","\u30d5\u30ec\u30f3\u30c9"],t.s)
A.lg=s(["W\xe4hle deinen Herzlicht-Partner","Elige a tu pareja de Luz de Coraz\xf3n","Choisissez votre partenaire de C\u0153ur-lumi\xe8re","Scegli il tuo partner di Luce del Cuore","Escolha sua parceria de Luz do Cora\xe7\xe3o","\u30cf\u30fc\u30c8\u30e9\u30a4\u30c8\u306e\u76f8\u624b\u3092\u9078\u3076"],t.s)
A.oj=s(["Freunde und H\xfcter deiner Konklave werden hier angezeigt. Du kannst auch jeden registrierten H\xfcter per ID einladen.","Aqu\xed aparecen tus amigos y los guardianes del C\xf3nclave. Tambi\xe9n puedes invitar a cualquier Guardi\xe1n registrado por su ID.","Vos amis et les gardiens de la Conclave apparaissent ici. Vous pouvez aussi inviter tout Gardien inscrit gr\xe2ce \xe0 son identifiant.","Qui trovi amici e custodi del Conclave. Puoi anche invitare qualsiasi Custode registrato tramite ID.","Amigos e guardi\xf5es do Conclave aparecem aqui. Voc\xea tamb\xe9m pode convidar qualquer Guardi\xe3o registrado pelo ID.","\u30d5\u30ec\u30f3\u30c9\u3068\u30b3\u30f3\u30af\u30ec\u30fc\u30d6\u306e\u30ad\u30fc\u30d1\u30fc\u304c\u3053\u3053\u306b\u8868\u793a\u3055\u308c\u307e\u3059\u3002\u767b\u9332\u6e08\u307f\u30ad\u30fc\u30d1\u30fc\u306fID\u3067\u3082\u62db\u5f85\u3067\u304d\u307e\u3059\u3002"],t.s)
A.GG=s(["H\xfcter-ID","ID de Guardi\xe1n","Identifiant du Gardien","ID Custode","ID do Guardi\xe3o","\u30ad\u30fc\u30d1\u30fcID"],t.s)
A.Au=s(["Einladung senden","Enviar invitaci\xf3n","Envoyer l\u2019invitation","Invia invito","Enviar convite","\u62db\u5f85\u3092\u9001\u308b"],t.s)
A.IH=s(["Melde dich mit einem best\xe4tigten Konto an, um deinen Valentinspartner einzuladen.","Inicia sesi\xf3n con una cuenta verificada para invitar a tu pareja de San Valent\xedn.","Connectez-vous avec un compte v\xe9rifi\xe9 pour inviter votre partenaire de la Saint-Valentin.","Accedi con un account verificato per invitare il tuo partner di San Valentino.","Entre com uma conta verificada para convidar sua parceria de Dia dos Namorados.","\u30d0\u30ec\u30f3\u30bf\u30a4\u30f3\u306e\u76f8\u624b\u3092\u62db\u5f85\u3059\u308b\u306b\u306f\u3001\u8a8d\u8a3c\u6e08\u307f\u30a2\u30ab\u30a6\u30f3\u30c8\u3067\u30b5\u30a4\u30f3\u30a4\u30f3\u3057\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.qR=s(["Herzlicht-Einladung gesendet. Dein Drache bleibt w\xe4hrend des Wartens reserviert.","Invitaci\xf3n de Luz de Coraz\xf3n enviada. Tu drag\xf3n queda reservado mientras esperas.","Invitation de C\u0153ur-lumi\xe8re envoy\xe9e. Votre dragon reste r\xe9serv\xe9 pendant l\u2019attente.","Invito di Luce del Cuore inviato. Il tuo drago resta riservato durante l\u2019attesa.","Convite de Luz do Cora\xe7\xe3o enviado. Seu drag\xe3o fica reservado enquanto voc\xea aguarda.","\u30cf\u30fc\u30c8\u30e9\u30a4\u30c8\u306e\u62db\u5f85\u3092\u9001\u308a\u307e\u3057\u305f\u3002\u5f85\u6a5f\u4e2d\u306f\u30c9\u30e9\u30b4\u30f3\u304c\u4e88\u7d04\u3055\u308c\u307e\u3059\u3002"],t.s)
A.mf=s(["Die Einladung konnte nicht gesendet werden.","No se pudo enviar la invitaci\xf3n.","L\u2019invitation n\u2019a pas pu \xeatre envoy\xe9e.","Non \xe8 stato possibile inviare l\u2019invito.","N\xe3o foi poss\xedvel enviar o convite.","\u62db\u5f85\u3092\u9001\u4fe1\u3067\u304d\u307e\u305b\u3093\u3067\u3057\u305f\u3002"],t.s)
A.wD=s(["Genau 2 registrierte H\xfcter mit jeweils einem verf\xfcgbaren Drachen.","Exactamente 2 Guardianes registrados, cada uno con un drag\xf3n disponible.","Exactement 2 Gardiens inscrits, chacun avec un dragon disponible.","Esattamente 2 Custodi registrati, ciascuno con un drago disponibile.","Exatamente 2 Guardi\xf5es registrados, cada um com um drag\xe3o dispon\xedvel.","\u767b\u9332\u6e08\u307f\u30ad\u30fc\u30d1\u30fc2\u4eba\u304c\u3001\u305d\u308c\u305e\u308c\u4f7f\u7528\u53ef\u80fd\u306a\u30c9\u30e9\u30b4\u30f3\u30921\u982d\u305a\u3064\u7528\u610f\u3059\u308b\u5fc5\u8981\u304c\u3042\u308a\u307e\u3059\u3002"],t.s)
A.Hw=s(["Das Haven-Spektrum","El Espectro del Haven","Le Spectre du Haven","Lo Spettro dell\u2019Haven","O Espectro do Haven","\u30d8\u30a4\u30f4\u30f3\u30fb\u30b9\u30da\u30af\u30c8\u30e9\u30e0"],t.s)
A.mT=s(["Die hervorgehobene Eventmusik steht dir w\xe4hrend dieses Events zur Verf\xfcgung und verschwindet danach.","La m\xfasica destacada estar\xe1 disponible durante este evento y desaparecer\xe1 cuando termine.","La musique mise en \xe9vidence vous accompagne pendant cet \xe9v\xe9nement et dispara\xeet \xe0 sa fin.","La musica evidenziata \xe8 disponibile durante l\u2019evento e scompare quando termina.","A m\xfasica destacada fica dispon\xedvel durante este evento e desaparece quando ele termina.","\u5f37\u8abf\u8868\u793a\u3055\u308c\u305f\u30a4\u30d9\u30f3\u30c8\u97f3\u697d\u306f\u958b\u50ac\u4e2d\u306e\u307f\u5229\u7528\u3067\u304d\u3001\u7d42\u4e86\u3059\u308b\u3068\u6d88\u3048\u307e\u3059\u3002"],t.s)
A.z9=s(["Das letzte Licht ist versiegelt!","\xa1La \xfaltima luz est\xe1 sellada!","La derni\xe8re lumi\xe8re est scell\xe9e !","L\u2019ultima luce \xe8 sigillata!","A \xfaltima luz foi selada!","\u6700\u5f8c\u306e\u5149\u3092\u5c01\u5370\u3057\u307e\u3057\u305f\uff01"],t.s)
A.lk=s(["Tippe, wenn der Ring golden wird","Toca cuando el anillo se vuelva dorado","Touchez lorsque l\u2019anneau devient dor\xe9","Tocca quando l\u2019anello diventa dorato","Toque quando o anel ficar dourado","\u30ea\u30f3\u30b0\u304c\u91d1\u8272\u306b\u306a\u3063\u305f\u3089\u30bf\u30c3\u30d7"],t.s)
A.pd=s(["Arkane Kunde \xb7 merke dir dieses Rezept","Arcana \xb7 memoriza esta receta","Arcane \xb7 m\xe9morisez cette recette","Arcano \xb7 memorizza questa ricetta","Arcana \xb7 memorize esta receita","\u30a2\u30eb\u30ab\u30ca\u30fb\u3053\u306e\u30ec\u30b7\u30d4\u3092\u899a\u3048\u308b"],t.s)
A.wI=s(["Arkane Kunde \xb7 finde das passende Geschenk","Arcana \xb7 encuentra el regalo correspondiente","Arcane \xb7 trouvez le cadeau correspondant","Arcano \xb7 trova il regalo corrispondente","Arcana \xb7 encontre o presente correspondente","\u30a2\u30eb\u30ab\u30ca\u30fb\u540c\u3058\u8d08\u308a\u7269\u3092\u898b\u3064\u3051\u308b"],t.s)
A.HU=s(["Pr\xfcfung beginnen","Comenzar Prueba","Commencer l\u2019\xc9preuve","Inizia Prova","Iniciar Prova","\u30c8\u30e9\u30a4\u30a2\u30eb\u958b\u59cb"],t.s)
A.zN=s(["Der Server konnte diese saisonale Pr\xfcfung nicht best\xe4tigen. Keine Belohnung wurde ver\xe4ndert.","El servidor no pudo verificar esta Prueba de temporada. No se modific\xf3 ninguna recompensa.","Le serveur n\u2019a pas pu v\xe9rifier cette \xc9preuve saisonni\xe8re. Aucune r\xe9compense n\u2019a \xe9t\xe9 modifi\xe9e.","Il server non ha potuto verificare questa Prova stagionale. Nessuna ricompensa \xe8 stata modificata.","O servidor n\xe3o conseguiu verificar esta Prova sazonal. Nenhuma recompensa foi alterada.","\u30b5\u30fc\u30d0\u30fc\u304c\u30b7\u30fc\u30ba\u30f3\u30c8\u30e9\u30a4\u30a2\u30eb\u3092\u78ba\u8a8d\u3067\u304d\u307e\u305b\u3093\u3067\u3057\u305f\u3002\u5831\u916c\u306b\u5909\u66f4\u306f\u3042\u308a\u307e\u305b\u3093\u3002"],t.s)
A.Eq=s(["Deine Pr\xfcfungsbelohnung ist sicher, aber diese Offline-Punktzahl wurde nicht in die Event-Rangliste aufgenommen.","Tu recompensa de la Prueba est\xe1 a salvo, pero esta puntuaci\xf3n sin conexi\xf3n no se a\xf1adi\xf3 a la clasificaci\xf3n.","Votre r\xe9compense d\u2019\xc9preuve est pr\xe9serv\xe9e, mais ce score hors ligne n\u2019a pas \xe9t\xe9 ajout\xe9 au classement.","La ricompensa della Prova \xe8 al sicuro, ma questo punteggio offline non \xe8 stato aggiunto alla classifica.","Sua recompensa da Prova est\xe1 segura, mas esta pontua\xe7\xe3o offline n\xe3o foi adicionada ao ranking.","\u30c8\u30e9\u30a4\u30a2\u30eb\u5831\u916c\u306f\u4fdd\u6301\u3055\u308c\u307e\u3057\u305f\u304c\u3001\u30aa\u30d5\u30e9\u30a4\u30f3\u30b9\u30b3\u30a2\u306f\u30a4\u30d9\u30f3\u30c8\u30e9\u30f3\u30ad\u30f3\u30b0\u306b\u8ffd\u52a0\u3055\u308c\u307e\u305b\u3093\u3067\u3057\u305f\u3002"],t.s)
A.Bw=s(["TESTEVENT \xb7 SIMULIERT","EVENTO DE PRUEBA \xb7 SIMULADO","\xc9V\xc9NEMENT TEST \xb7 SIMUL\xc9","EVENTO DI TEST \xb7 SIMULATO","EVENTO DE TESTE \xb7 SIMULADO","\u30c6\u30b9\u30c8\u30a4\u30d9\u30f3\u30c8\u30fb\u30b7\u30df\u30e5\u30ec\u30fc\u30b7\u30e7\u30f3"],t.s)
A.wl=s(["Nur Vorschau: Diese Belohnungen und diese Punktzahl wurden deinem dauerhaften Produktionskonto nicht hinzugef\xfcgt.","Solo vista previa: estas recompensas y esta puntuaci\xf3n no se a\xf1adieron a tu cuenta permanente.","Aper\xe7u uniquement : ces r\xe9compenses et ce score n\u2019ont pas \xe9t\xe9 ajout\xe9s \xe0 votre compte permanent.","Solo anteprima: queste ricompense e questo punteggio non sono stati aggiunti al tuo account permanente.","Somente pr\xe9via: estas recompensas e esta pontua\xe7\xe3o n\xe3o foram adicionadas \xe0 sua conta permanente.","\u30d7\u30ec\u30d3\u30e5\u30fc\u306e\u307f\uff1a\u5831\u916c\u3068\u30b9\u30b3\u30a2\u306f\u672c\u756a\u30a2\u30ab\u30a6\u30f3\u30c8\u306b\u8ffd\u52a0\u3055\u308c\u3066\u3044\u307e\u305b\u3093\u3002"],t.s)
A.yZ=s(["Die private 48-Stunden-Eventvorschau ist jetzt aktiv.","La vista previa privada de 48 horas ya est\xe1 activa.","L\u2019aper\xe7u priv\xe9 de l\u2019\xe9v\xe9nement pour 48 heures est maintenant actif.","L\u2019anteprima privata dell\u2019evento di 48 ore \xe8 ora attiva.","A pr\xe9via privada de 48 horas do evento est\xe1 ativa.","48\u6642\u9593\u306e\u975e\u516c\u958b\u30a4\u30d9\u30f3\u30c8\u30d7\u30ec\u30d3\u30e5\u30fc\u304c\u6709\u52b9\u306b\u306a\u308a\u307e\u3057\u305f\u3002"],t.s)
A.rC=s(["Diese Eventvorschau ist bereits aktiv.","Esta vista previa del evento ya est\xe1 activa.","Cet aper\xe7u d\u2019\xe9v\xe9nement est d\xe9j\xe0 actif.","Questa anteprima dell\u2019evento \xe8 gi\xe0 attiva.","Esta pr\xe9via do evento j\xe1 est\xe1 ativa.","\u3053\u306e\u30a4\u30d9\u30f3\u30c8\u30d7\u30ec\u30d3\u30e5\u30fc\u306f\u3059\u3067\u306b\u6709\u52b9\u3067\u3059\u3002"],t.s)
A.os=s(["Dieser private Vorschaucode ist f\xfcr diese H\xfcter-ID nicht verf\xfcgbar.","Este c\xf3digo de vista previa privada no est\xe1 disponible para este ID de Guardi\xe1n.","Ce code d\u2019aper\xe7u priv\xe9 n\u2019est pas disponible pour cet identifiant de Gardien.","Questo codice di anteprima privata non \xe8 disponibile per questo ID Custode.","Este c\xf3digo de pr\xe9via privada n\xe3o est\xe1 dispon\xedvel para este ID de Guardi\xe3o.","\u3053\u306e\u975e\u516c\u958b\u30d7\u30ec\u30d3\u30e5\u30fc\u30b3\u30fc\u30c9\u306f\u3001\u3053\u306e\u30ad\u30fc\u30d1\u30fcID\u3067\u306f\u5229\u7528\u3067\u304d\u307e\u305b\u3093\u3002"],t.s)
A.xw=s(["Diese Eventvorschau ist f\xfcr diesen H\xfcter nicht verf\xfcgbar.","Esta vista previa no est\xe1 disponible para este Guardi\xe1n.","Cet aper\xe7u d\u2019\xe9v\xe9nement n\u2019est pas disponible pour ce Gardien.","Questa anteprima non \xe8 disponibile per questo Custode.","Esta pr\xe9via n\xe3o est\xe1 dispon\xedvel para este Guardi\xe3o.","\u3053\u306e\u30a4\u30d9\u30f3\u30c8\u30d7\u30ec\u30d3\u30e5\u30fc\u306f\u3001\u3053\u306e\u30ad\u30fc\u30d1\u30fc\u306b\u306f\u5229\u7528\u3067\u304d\u307e\u305b\u3093\u3002"],t.s)
A.Ht=s(["Dieser Eventvorschaucode ist nicht aktiv.","Este c\xf3digo de vista previa no est\xe1 activo.","Ce code d\u2019aper\xe7u d\u2019\xe9v\xe9nement n\u2019est pas actif.","Questo codice di anteprima non \xe8 attivo.","Este c\xf3digo de pr\xe9via do evento n\xe3o est\xe1 ativo.","\u3053\u306e\u30a4\u30d9\u30f3\u30c8\u30d7\u30ec\u30d3\u30e5\u30fc\u30b3\u30fc\u30c9\u306f\u7121\u52b9\u3067\u3059\u3002"],t.s)
A.qm=s(["Dieses saisonale Event wird nicht erkannt.","No se reconoce este evento de temporada.","Cet \xe9v\xe9nement saisonnier n\u2019est pas reconnu.","Questo evento stagionale non \xe8 riconosciuto.","Este evento sazonal n\xe3o foi reconhecido.","\u3053\u306e\u30b7\u30fc\u30ba\u30f3\u30a4\u30d9\u30f3\u30c8\u3092\u8a8d\u8b58\u3067\u304d\u307e\u305b\u3093\u3002"],t.s)
A.pf=s(["Dieses saisonale Event ist derzeit nicht verf\xfcgbar.","Este evento de temporada no est\xe1 disponible ahora.","Cet \xe9v\xe9nement saisonnier n\u2019est pas disponible actuellement.","Questo evento stagionale non \xe8 disponibile al momento.","Este evento sazonal n\xe3o est\xe1 dispon\xedvel agora.","\u3053\u306e\u30b7\u30fc\u30ba\u30f3\u30a4\u30d9\u30f3\u30c8\u306f\u73fe\u5728\u958b\u50ac\u3055\u308c\u3066\u3044\u307e\u305b\u3093\u3002"],t.s)
A.ux=s(["Diese Pr\xfcfungssitzung ist abgelaufen. Starte eine neue saisonale Pr\xfcfung.","Esta sesi\xf3n de Prueba ha caducado. Inicia una nueva Prueba de temporada.","Cette session d\u2019\xc9preuve a expir\xe9. Lancez une nouvelle \xc9preuve saisonni\xe8re.","Questa sessione di Prova \xe8 scaduta. Avvia una nuova Prova stagionale.","Esta sess\xe3o de Prova expirou. Inicie uma nova Prova sazonal.","\u30c8\u30e9\u30a4\u30a2\u30eb\u30bb\u30c3\u30b7\u30e7\u30f3\u306e\u6709\u52b9\u671f\u9650\u304c\u5207\u308c\u307e\u3057\u305f\u3002\u65b0\u3057\u3044\u30b7\u30fc\u30ba\u30f3\u30c8\u30e9\u30a4\u30a2\u30eb\u3092\u958b\u59cb\u3057\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.p7=s(["Der Server konnte diese Pr\xfcfungspunktzahl nicht validieren.","El servidor no pudo validar esta puntuaci\xf3n de la Prueba.","Le serveur n\u2019a pas pu valider ce score d\u2019\xc9preuve.","Il server non ha potuto convalidare questo punteggio della Prova.","O servidor n\xe3o conseguiu validar esta pontua\xe7\xe3o da Prova.","\u30b5\u30fc\u30d0\u30fc\u304c\u3053\u306e\u30c8\u30e9\u30a4\u30a2\u30eb\u30b9\u30b3\u30a2\u3092\u691c\u8a3c\u3067\u304d\u307e\u305b\u3093\u3067\u3057\u305f\u3002"],t.s)
A.qp=s(["Du hast diese Ausgabe des Eventabenteuers bereits abgeschlossen.","Ya completaste esta edici\xf3n de la Aventura del evento.","Vous avez d\xe9j\xe0 termin\xe9 cette \xe9dition de l\u2019Aventure \xe9v\xe9nementielle.","Hai gi\xe0 completato questa edizione dell\u2019Avventura evento.","Voc\xea j\xe1 concluiu esta edi\xe7\xe3o da Aventura do evento.","\u3053\u306e\u56de\u306e\u30a4\u30d9\u30f3\u30c8\u30a2\u30c9\u30d9\u30f3\u30c1\u30e3\u30fc\u306f\u3059\u3067\u306b\u5b8c\u4e86\u3057\u3066\u3044\u307e\u3059\u3002"],t.s)
A.L8=s(["Einer dieser H\xfcter hat bereits ein aktives Valentinsabenteuer.","Uno de estos Guardianes ya tiene una Aventura de San Valent\xedn activa.","L\u2019un de ces Gardiens participe d\xe9j\xe0 \xe0 une Aventure de la Saint-Valentin.","Uno di questi Custodi ha gi\xe0 un\u2019Avventura di San Valentino attiva.","Um destes Guardi\xf5es j\xe1 tem uma Aventura de Dia dos Namorados ativa.","\u3044\u305a\u308c\u304b\u306e\u30ad\u30fc\u30d1\u30fc\u304c\u3001\u3059\u3067\u306b\u30d0\u30ec\u30f3\u30bf\u30a4\u30f3\u30a2\u30c9\u30d9\u30f3\u30c1\u30e3\u30fc\u306b\u53c2\u52a0\u3057\u3066\u3044\u307e\u3059\u3002"],t.s)
A.t7=s(["Dieser Drache ist f\xfcr dieses Abenteuer nicht mehr verf\xfcgbar.","Ese drag\xf3n ya no est\xe1 disponible para esta Aventura.","Ce dragon n\u2019est plus disponible pour cette Aventure.","Quel drago non \xe8 pi\xf9 disponibile per questa Avventura.","Esse drag\xe3o n\xe3o est\xe1 mais dispon\xedvel para esta Aventura.","\u305d\u306e\u30c9\u30e9\u30b4\u30f3\u306f\u3001\u3053\u306e\u30a2\u30c9\u30d9\u30f3\u30c1\u30e3\u30fc\u3067\u306f\u5229\u7528\u3067\u304d\u306a\u304f\u306a\u308a\u307e\u3057\u305f\u3002"],t.s)
A.CB=s(["Diese Valentinseinladung hat sich ge\xe4ndert. Aktualisiere und versuche es erneut.","Esta invitaci\xf3n de San Valent\xedn ha cambiado. Actualiza e int\xe9ntalo de nuevo.","Cette invitation de la Saint-Valentin a chang\xe9. Actualisez puis r\xe9essayez.","Questo invito di San Valentino \xe8 cambiato. Aggiorna e riprova.","Este convite de Dia dos Namorados mudou. Atualize e tente novamente.","\u30d0\u30ec\u30f3\u30bf\u30a4\u30f3\u306e\u62db\u5f85\u5185\u5bb9\u304c\u5909\u308f\u308a\u307e\u3057\u305f\u3002\u66f4\u65b0\u3057\u3066\u3082\u3046\u4e00\u5ea6\u304a\u8a66\u3057\u304f\u3060\u3055\u3044\u3002"],t.s)
A.zv=s(["Diese Valentinsbelohnungen sind noch nicht bereit.","Estas recompensas de San Valent\xedn a\xfan no est\xe1n listas.","Ces r\xe9compenses de la Saint-Valentin ne sont pas encore pr\xeates.","Queste ricompense di San Valentino non sono ancora pronte.","Estas recompensas de Dia dos Namorados ainda n\xe3o est\xe3o prontas.","\u30d0\u30ec\u30f3\u30bf\u30a4\u30f3\u5831\u916c\u306f\u307e\u3060\u6e96\u5099\u3067\u304d\u3066\u3044\u307e\u305b\u3093\u3002"],t.s)
A.kZ=s(["Diese Valentinsbelohnungen wurden bereits abgeholt.","Estas recompensas de San Valent\xedn ya se reclamaron.","Ces r\xe9compenses de la Saint-Valentin ont d\xe9j\xe0 \xe9t\xe9 r\xe9cup\xe9r\xe9es.","Queste ricompense di San Valentino sono gi\xe0 state riscattate.","Estas recompensas de Dia dos Namorados j\xe1 foram resgatadas.","\u30d0\u30ec\u30f3\u30bf\u30a4\u30f3\u5831\u916c\u306f\u3059\u3067\u306b\u53d7\u3051\u53d6\u3063\u3066\u3044\u307e\u3059\u3002"],t.s)
A.EJ=s(["Die Valentinsbelohnung konnte deinem lokalen Drachen nicht zugeordnet werden.","La recompensa de San Valent\xedn no pudo vincularse a tu drag\xf3n local.","La r\xe9compense de la Saint-Valentin n\u2019a pas pu \xeatre li\xe9e \xe0 votre dragon local.","Non \xe8 stato possibile collegare la ricompensa di San Valentino al tuo drago locale.","A recompensa de Dia dos Namorados n\xe3o p\xf4de ser vinculada ao seu drag\xe3o local.","\u30d0\u30ec\u30f3\u30bf\u30a4\u30f3\u5831\u916c\u3092\u7aef\u672b\u5185\u306e\u30c9\u30e9\u30b4\u30f3\u306b\u95a2\u9023\u4ed8\u3051\u3089\u308c\u307e\u305b\u3093\u3067\u3057\u305f\u3002"],t.s)
A.H8=s(["Private Test-Rangliste","Clasificaci\xf3n de prueba privada","Classement de test priv\xe9","Classifica di test privata","Ranking de teste privado","\u975e\u516c\u958b\u30c6\u30b9\u30c8\u30e9\u30f3\u30ad\u30f3\u30b0"],t.s)
A.vm=s(["Weltrangliste \xc2\xb7 Ergebnisse bleiben 5 Tage sichtbar","Clasificaci\xf3n mundial \xc2\xb7 los resultados permanecen visibles 5 d\xedas","Classement mondial \xc2\xb7 les r\xe9sultats restent visibles pendant 5 jours","Classifica mondiale \xc2\xb7 i risultati restano visibili per 5 giorni","Ranking mundial \xc2\xb7 os resultados ficam vis\xedveis por 5 dias","\u4e16\u754c\u30e9\u30f3\u30ad\u30f3\u30b0 \xc2\xb7 \u7d50\u679c\u306f5\u65e5\u9593\u8868\u793a\u3055\u308c\u307e\u3059"],t.s)
A.tJ=s(["Ranglisten konnten nicht geladen werden.","No se pudieron cargar las clasificaciones.","Impossible de charger les classements.","Impossibile caricare le classifiche.","N\xe3o foi poss\xedvel carregar os rankings.","\u30e9\u30f3\u30ad\u30f3\u30b0\u3092\u8aad\u307f\u8fbc\u3081\u307e\u305b\u3093\u3067\u3057\u305f\u3002"],t.s)
A.n6=s(["Noch keine offizielle Punktzahl. Sei das erste Licht auf der Tafel!","A\xfan no hay puntuaciones oficiales. \xa1S\xe9 la primera luz del tablero!","Pas encore de score officiel. Soyez la premi\xe8re lumi\xe8re du classement !","Non ci sono ancora punteggi ufficiali. Sii la prima luce in classifica!","Ainda n\xe3o h\xe1 pontua\xe7\xe3o oficial. Seja a primeira luz do placar!","\u307e\u3060\u516c\u5f0f\u30b9\u30b3\u30a2\u306f\u3042\u308a\u307e\u305b\u3093\u3002\u6700\u521d\u306e\u5149\u3092\u523b\u307f\u307e\u3057\u3087\u3046\uff01"],t.s)
A.Cb=s(["Saisonchronik","Cr\xf3nica de temporada","Chronique saisonni\xe8re","Cronaca stagionale","Cr\xf4nica sazonal","\u30b7\u30fc\u30ba\u30f3\u30af\u30ed\u30cb\u30af\u30eb"],t.s)
A.Lz=new B.u(A.NY,[A.zw,A.wK,A.vn,A.uf,A.tm,A.lj,A.ty,A.xM,A.rk,A.DF,A.uJ,A.Cm,A.Hv,A.w5,A.FH,A.A3,A.uk,A.tq,A.vZ,A.CO,A.m0,A.qf,A.mu,A.ou,A.Df,A.JR,A.B6,A.lg,A.oj,A.GG,A.Au,A.IH,A.qR,A.mf,A.wD,A.Hw,A.mT,A.z9,A.lk,A.pd,A.wI,A.HU,A.zN,A.Eq,A.Bw,A.wl,A.yZ,A.rC,A.os,A.xw,A.Ht,A.qm,A.pf,A.ux,A.p7,A.qp,A.L8,A.t7,A.CB,A.zv,A.kZ,A.EJ,A.H8,A.vm,A.tJ,A.n6,A.Cb],t.M)
A.O3={hello_little_one:0,guided_tour:1,first_flight:2,chest_expectations:3,profile_picture_perfect:4,highly_titled:5,room_to_roost:6,feed_furniture:7,book_wyrm:8,growing_pains:9,not_picking_favorites:10,halfway_clouds:11,ascension_day:12,something_spectral:13,well_read_scaled:14,frequent_flyer:15,are_we_there_yet:16,full_party:17,triple_expertise:18,hidden_mastery:19,came_crawling_back:20,sky_ceiling:21,scale_every_tale:22,ghost_writer:23,myth_made_real:24,trial_might_s_plus:25,trial_spirit_s_plus:26,trial_arcana_s_plus:27,winner_chicken_dinner:28,warden_of_the_witchlight:29,star_in_every_hearth:30,first_light_first_flight:31,two_hearts_one_flight:32,every_color_takes_flight:33,probably_fine:34,academy_graduate:35,dragon_school_dropout:36,dragon_school_valedictorian:37}
A.j={de:0,es:1,fr:2,it:3,pt:4,ja:5}
A.Ec=s(["Hallo, Kleines!","Br\xfcte dein Starter-Ei aus."],t.s)
A.Et=s(["\xa1Hola, peque\xf1\xedn!","Haz eclosionar tu Huevo Inicial."],t.s)
A.vE=s(["Bonjour, petit !","Fais \xe9clore ton \u0152uf de d\xe9part."],t.s)
A.tA=s(["Ciao, piccolino!","Fai schiudere il tuo Uovo iniziale."],t.s)
A.wv=s(["Ol\xe1, pequenino!","Fa\xe7a seu Ovo Inicial chocar."],t.s)
A.KI=s(["\u3053\u3093\u306b\u3061\u306f\u3001\u3061\u3073\u3061\u3083\u3093\uff01","\u6700\u521d\u306e\u30c9\u30e9\u30b4\u30f3\u306e\u5375\u3092\u5b75\u5316\u3055\u305b\u308b\u3002"],t.s)
A.LI=new B.u(A.j,[A.Ec,A.Et,A.vE,A.tA,A.wv,A.KI],t.M)
A.BL=s(["Etwas weniger verloren","Schlie\xdfe das DragonHaven-Tutorial ab."],t.s)
A.md=s(["Un poco menos perdido","Completa el tutorial de DragonHaven."],t.s)
A.kX=s(["Un peu moins perdu","Termine le tutoriel de DragonHaven."],t.s)
A.tj=s(["Un po\u2019 meno spaesato","Completa il tutorial di DragonHaven."],t.s)
A.jG=s(["Um pouco menos perdido","Conclua o tutorial de DragonHaven."],t.s)
A.AS=s(["\u5c11\u3057\u8ff7\u308f\u306a\u304f\u306a\u3063\u305f","DragonHaven\u306e\u30c1\u30e5\u30fc\u30c8\u30ea\u30a2\u30eb\u3092\u5b8c\u4e86\u3059\u308b\u3002"],t.s)
A.LL=new B.u(A.j,[A.BL,A.md,A.kX,A.tj,A.jG,A.AS],t.M)
A.Db=s(["Erster Flug","Schlie\xdfe dein erstes kurzes Abenteuer ab."],t.s)
A.w7=s(["Primer vuelo","Completa tu primera Aventura corta."],t.s)
A.IF=s(["Premier vol","Termine ta premi\xe8re Aventure courte."],t.s)
A.yi=s(["Primo volo","Completa la tua prima Avventura breve."],t.s)
A.B8=s(["Primeiro voo","Conclua sua primeira Aventura curta."],t.s)
A.kH=s(["\u306f\u3058\u3081\u3066\u306e\u98db\u884c","\u6700\u521d\u306e\u30b7\u30e7\u30fc\u30c8\u5192\u967a\u3092\u5b8c\u4e86\u3059\u308b\u3002"],t.s)
A.LW=new B.u(A.j,[A.Db,A.w7,A.IF,A.yi,A.B8,A.kH],t.M)
A.KY=s(["Truhige Erwartungen","\xd6ffne deine erste Truhe."],t.s)
A.CN=s(["Grandes expectativas","Abre tu primer cofre."],t.s)
A.GT=s(["Coffre \xe0 grandes attentes","Ouvre ton premier coffre."],t.s)
A.EN=s(["Grandi aspettative","Apri il tuo primo forziere."],t.s)
A.Iu=s(["Grandes expectativas","Abra seu primeiro ba\xfa."],t.s)
A.vq=s(["\u7bb1\u3078\u306e\u671f\u5f85","\u6700\u521d\u306e\u5b9d\u7bb1\u3092\u958b\u3051\u308b\u3002"],t.s)
A.LC=new B.u(A.j,[A.KY,A.CN,A.GT,A.EN,A.Iu,A.vq],t.M)
A.Bb=s(["Wie f\xfcrs Portr\xe4t gemacht","\xd6ffne deine erste Portr\xe4ttruhe. Dein Konto zeigt sich von seiner besten Seite."],t.s)
A.FL=s(["Retrato perfecto","Abre tu primer Cofre de retratos. Tu cuenta encontr\xf3 su mejor perfil."],t.s)
A.Im=s(["Portrait parfait","Ouvre ton premier Coffre de portraits. Ton compte a trouv\xe9 son meilleur profil."],t.s)
A.wj=s(["Ritratto perfetto","Apri il tuo primo Forziere ritratto. Il tuo account ha trovato il lato migliore."],t.s)
A.D2=s(["Retrato perfeito","Abra seu primeiro Ba\xfa de retratos. Sua conta encontrou seu melhor \xe2ngulo."],t.s)
A.w3=s(["\u5b8c\u74a7\u306a\u30d7\u30ed\u30d5\u30a3\u30fc\u30eb","\u30dd\u30fc\u30c8\u30ec\u30fc\u30c8\u5b9d\u7bb1\u3092\u521d\u3081\u3066\u958b\u3051\u308b\u3002\u30a2\u30ab\u30a6\u30f3\u30c8\u306e\u6c7a\u3081\u9854\u304c\u898b\u3064\u304b\u3063\u305f\u3002"],t.s)
A.M_=new B.u(A.j,[A.Bb,A.FL,A.Im,A.wj,A.D2,A.w3],t.M)
A.EC=s(["Hochbetitelt","\xd6ffne deine erste Titeltruhe. Lass dir den Titel nicht zu Kopf steigen."],t.s)
A.Gg=s(["Con mucho t\xedtulo","Abre tu primer Cofre de t\xedtulos. Que no se te suba a la cabeza."],t.s)
A.E6=s(["Sacr\xe9 titre","Ouvre ton premier Coffre de titres. Ne prends pas la grosse t\xeate."],t.s)
A.z2=s(["Altisonante","Apri il tuo primo Forziere titolo. Cerca di non montarti la testa."],t.s)
A.nc=s(["Muito importante","Abra seu primeiro Ba\xfa de t\xedtulos. N\xe3o deixe o t\xedtulo subir \xe0 cabe\xe7a."],t.s)
A.ri=s(["\u80a9\u66f8\u304d\u6301\u3061","\u79f0\u53f7\u5b9d\u7bb1\u3092\u521d\u3081\u3066\u958b\u3051\u308b\u3002\u80a9\u66f8\u304d\u3067\u5049\u304f\u306a\u308a\u3059\u304e\u306a\u3044\u3088\u3046\u306b\u3002"],t.s)
A.M0=new B.u(A.j,[A.EC,A.Gg,A.E6,A.z2,A.nc,A.ri],t.M)
A.m5=s(["Platz zum Nisten","Kaufe dein erstes zus\xe4tzliches Turmgeschoss."],t.s)
A.D3=s(["Sitio para anidar","Compra tu primer piso adicional de la Torre."],t.s)
A.ER=s(["De la place pour nicher","Ach\xe8te ton premier \xe9tage suppl\xe9mentaire."],t.s)
A.L1=s(["Spazio per il nido","Compra il primo piano aggiuntivo della Torre."],t.s)
A.zR=s(["Espa\xe7o para o ninho","Compre o primeiro andar extra da Torre."],t.s)
A.tz=s(["\u5de3\u3054\u3082\u308a\u306e\u90e8\u5c4b","\u30c9\u30e9\u30b4\u30f3\u30bf\u30ef\u30fc\u306e\u8ffd\u52a0\u968e\u3092\u521d\u3081\u3066\u8cfc\u5165\u3059\u308b\u3002"],t.s)
A.LS=new B.u(A.j,[A.m5,A.D3,A.ER,A.L1,A.zR,A.tz],t.M)
A.xV=s(["Bitte nicht die M\xf6bel f\xfcttern","Platziere dein erstes M\xf6belst\xfcck."],t.s)
A.CE=s(["No alimentes los muebles","Coloca tu primer mueble."],t.s)
A.lY=s(["Ne nourrissez pas les meubles","Place ton premier meuble."],t.s)
A.Eu=s(["Non dare da mangiare ai mobili","Posiziona il tuo primo mobile."],t.s)
A.x3=s(["N\xe3o alimente os m\xf3veis","Posicione seu primeiro m\xf3vel."],t.s)
A.FK=s(["\u5bb6\u5177\u306b\u30a8\u30b5\u3092\u4e0e\u3048\u306a\u3044\u3067","\u6700\u521d\u306e\u5bb6\u5177\u3092\u914d\u7f6e\u3059\u308b\u3002"],t.s)
A.LP=new B.u(A.j,[A.xV,A.CE,A.lY,A.Eu,A.x3,A.FK],t.M)
A.qn=s(["B\xfccherwyrm","Entdecke 5 gew\xf6hnliche Drachenfamilien."],t.s)
A.Ah=s(["Gusano de libros con alas","Descubre 5 familias de dragones comunes."],t.s)
A.oT=s(["Wyrm de biblioth\xe8que","D\xe9couvre 5 familles de dragons communes."],t.s)
A.JN=s(["Drago da biblioteca","Scopri 5 famiglie di draghi comuni."],t.s)
A.lq=s(["Drag\xe3o de biblioteca","Descubra 5 fam\xedlias de drag\xf5es comuns."],t.s)
A.nY=s(["\u672c\u306e\u866b\u306a\u3089\u306c\u672c\u306e\u7adc","\u30b3\u30e2\u30f3\u306e\u30c9\u30e9\u30b4\u30f3\u4e00\u65cf\u30925\u7a2e\u767a\u898b\u3059\u308b\u3002"],t.s)
A.LX=new B.u(A.j,[A.qn,A.Ah,A.oT,A.JN,A.lq,A.nY],t.M)
A.mZ=s(["Wachstumsschmerzen","Entwickle einen Schl\xfcpfling zum Jungwyrm."],t.s)
A.zG=s(["Dolores de crecimiento","Evoluciona una cr\xeda a drag\xf3n joven."],t.s)
A.te=s(["Crise de croissance","Fais \xe9voluer un nouveau-n\xe9 en jeune wyrm."],t.s)
A.Iv=s(["Dolori della crescita","Fai evolvere un cucciolo in giovane wyrm."],t.s)
A.mU=s(["Dores do crescimento","Evolua um filhote para um jovem wyrm."],t.s)
A.Hn=s(["\u6210\u9577\u75db","\u5b75\u5316\u3057\u305f\u5e7c\u7adc\u3092\u82e5\u7adc\u3078\u9032\u5316\u3055\u305b\u308b\u3002"],t.s)
A.LQ=new B.u(A.j,[A.mZ,A.zG,A.te,A.Iv,A.mU,A.Hn],t.M)
A.yQ=s(["Ganz bestimmt keine Lieblinge","Wechsle zum ersten Mal deinen Lieblingsdrachen."],t.s)
A.jZ=s(["Aqu\xed no hay favoritos","Cambia tu drag\xf3n favorito por primera vez."],t.s)
A.vN=s(["Pas de favoritisme, promis","Change de dragon favori pour la premi\xe8re fois."],t.s)
A.Ev=s(["Nessun preferito, davvero","Cambia il tuo drago preferito per la prima volta."],t.s)
A.no=s(["Sem favoritos, claro","Mude seu drag\xe3o favorito pela primeira vez."],t.s)
A.rg=s(["\u3048\u3053\u3072\u3044\u304d\u3067\u306f\u3042\u308a\u307e\u305b\u3093","\u304a\u6c17\u306b\u5165\u308a\u306e\u30c9\u30e9\u30b4\u30f3\u3092\u521d\u3081\u3066\u5909\u66f4\u3059\u308b\u3002"],t.s)
A.M3=new B.u(A.j,[A.yQ,A.jZ,A.vN,A.Ev,A.no,A.rg],t.M)
A.qw=s(["Halbwegs zu den Wolken","Baue 10 Stockwerke im Drachenturm."],t.s)
A.Ey=s(["A medio camino de las nubes","Construye 10 pisos de la Torre."],t.s)
A.q2=s(["\xc0 mi-chemin des nuages","Construis 10 \xe9tages de la Tour."],t.s)
A.uw=s(["A met\xe0 strada dalle nuvole","Costruisci 10 piani della Torre."],t.s)
A.Bo=s(["No meio do caminho at\xe9 as nuvens","Construa 10 andares da Torre."],t.s)
A.Jp=s(["\u96f2\u307e\u3067\u3042\u3068\u534a\u5206","\u30c9\u30e9\u30b4\u30f3\u30bf\u30ef\u30fc\u309210\u968e\u307e\u3067\u5efa\u3066\u308b\u3002"],t.s)
A.LK=new B.u(A.j,[A.qw,A.Ey,A.q2,A.uw,A.Bo,A.Jp],t.M)
A.vM=s(["Tag des Aufstiegs","Entwickle deinen ersten Erhabenen Drachen."],t.s)
A.xz=s(["D\xeda de la ascensi\xf3n","Evoluciona tu primer drag\xf3n Ascendido."],t.s)
A.ET=s(["Jour de l\u2019Ascension","Fais \xe9voluer ton premier dragon Transcend\xe9."],t.s)
A.uR=s(["Giorno dell\u2019ascensione","Ottieni il tuo primo drago Asceso."],t.s)
A.lI=s(["Dia da ascens\xe3o","Evolua seu primeiro drag\xe3o Ascendido."],t.s)
A.rA=s(["\u6607\u83ef\u306e\u65e5","\u6700\u521d\u306e\u30c9\u30e9\u30b4\u30f3\u3092\u30a2\u30bb\u30f3\u30c7\u30c3\u30c9\u3078\u9032\u5316\u3055\u305b\u308b\u3002"],t.s)
A.LH=new B.u(A.j,[A.vM,A.xz,A.ET,A.uR,A.lI,A.rA],t.M)
A.Hb=s(["Etwas Spektrales naht","Entdecke deinen ersten Spektraldrachen."],t.s)
A.Lg=s(["Algo espectral se acerca","Descubre tu primer drag\xf3n Espectral."],t.s)
A.pJ=s(["Un spectre approche","D\xe9couvre ton premier dragon Spectral."],t.s)
A.rf=s(["Qualcosa di spettrale arriva","Scopri il tuo primo drago Spettrale."],t.s)
A.y9=s(["Algo espectral se aproxima","Descubra seu primeiro drag\xe3o Espectral."],t.s)
A.F2=s(["\u30b9\u30da\u30af\u30c8\u30e9\u30eb\u306a\u4f55\u304b\u304c\u6765\u308b","\u6700\u521d\u306e\u30b9\u30da\u30af\u30c8\u30e9\u30eb\u30c9\u30e9\u30b4\u30f3\u3092\u767a\u898b\u3059\u308b\u3002"],t.s)
A.LE=new B.u(A.j,[A.Hb,A.Lg,A.pJ,A.rf,A.y9,A.F2],t.M)
A.Gu=s(["Belesen und beschuppt","Entdecke 20 gew\xf6hnliche Drachenfamilien."],t.s)
A.tY=s(["Bien le\xeddo, bien escamado","Descubre las 20 familias comunes."],t.s)
A.m4=s(["Bien lu, bien \xe9cailleux","D\xe9couvre les 20 familles communes."],t.s)
A.qK=s(["Colto e ben squamato","Scopri 20 famiglie comuni."],t.s)
A.l3=s(["Bem lido, bem escamado","Descubra as 20 fam\xedlias comuns."],t.s)
A.mw=s(["\u8aad\u66f8\u5bb6\u306f\u9c57\u3082\u7acb\u6d3e","\u30b3\u30e2\u30f3\u306e\u30c9\u30e9\u30b4\u30f3\u4e00\u65cf\u309220\u7a2e\u767a\u898b\u3059\u308b\u3002"],t.s)
A.M9=new B.u(A.j,[A.Gu,A.tY,A.m4,A.qK,A.l3,A.mw],t.M)
A.nv=s(["Vielflieger","Schlie\xdfe 50 Abenteuer ab."],t.s)
A.qu=s(["Viajero frecuente","Completa 50 Aventuras."],t.s)
A.GJ=s(["Grand voyageur","Termine 50 Aventures."],t.s)
A.lK=s(["Volo frequente","Completa 50 Avventure."],t.s)
A.pt=s(["Viajante frequente","Conclua 50 Aventuras."],t.s)
A.HI=s(["\u7a7a\u306e\u5e38\u9023","\u5192\u967a\u309250\u56de\u5b8c\u4e86\u3059\u308b\u3002"],t.s)
A.LY=new B.u(A.j,[A.nv,A.qu,A.GJ,A.lK,A.pt,A.HI],t.M)
A.rj=s(["Sind wir schon da?","Schlie\xdfe 1.000 Abenteuer ab."],t.s)
A.rT=s(["\xbfYa llegamos?","Completa 1.000 Aventuras."],t.s)
A.pC=s(["On est bient\xf4t arriv\xe9s ?","Termine 1 000 Aventures."],t.s)
A.Km=s(["Siamo arrivati?","Completa 1.000 Avventure."],t.s)
A.nd=s(["J\xe1 chegamos?","Conclua 1.000 Aventuras."],t.s)
A.xd=s(["\u3082\u3046\u7740\u3044\u305f\uff1f","\u5192\u967a\u30921,000\u56de\u5b8c\u4e86\u3059\u308b\u3002"],t.s)
A.LB=new B.u(A.j,[A.rj,A.rT,A.pC,A.Km,A.nd,A.xd],t.M)
A.IX=s(["Volle Gruppe, volle Kraft","Schlie\xdfe ein Gruppenabenteuer mit 4 Teilnehmern ab."],t.s)
A.mJ=s(["Grupo completo, sin frenos","Completa una Aventura grupal con 4 participantes."],t.s)
A.GF=s(["\xc9quipe au complet","Termine une Aventure de groupe \xe0 4."],t.s)
A.Ez=s(["Gruppo pieno, avanti tutta","Completa un\u2019Avventura di gruppo con 4 partecipanti."],t.s)
A.zE=s(["Grupo completo, for\xe7a total","Conclua uma Aventura em grupo com 4 participantes."],t.s)
A.G4=s(["\u30d5\u30eb\u30d1\u30fc\u30c6\u30a3\u30fc\u3001\u5168\u901f\u524d\u9032","4\u4eba\u3067\u30b0\u30eb\u30fc\u30d7\u5192\u967a\u3092\u5b8c\u4e86\u3059\u308b\u3002"],t.s)
A.Mb=new B.u(A.j,[A.IX,A.mJ,A.GF,A.Ez,A.zE,A.G4],t.M)
A.tC=s(["Meister aller drei","Erreiche mit einem Drachen 300 St\xe4rke, 300 Arkana und 300 Geist."],t.s)
A.Fu=s(["Maestro de las tres","Alcanza 300 de Poder, 300 de Arcana y 300 de Esp\xedritu con un drag\xf3n."],t.s)
A.jR=s(["Ma\xeetre des trois","Atteins 300 en Puissance, 300 en Arcanes et 300 en Esprit avec un dragon."],t.s)
A.nr=s(["Maestro di tutte e tre","Raggiungi 300 Potenza, 300 Arcano e 300 Spirito con un drago."],t.s)
A.D0=s(["Mestre das tr\xeas","Alcance 300 de Poder, 300 de Arcano e 300 de Esp\xedrito com um drag\xe3o."],t.s)
A.nu=s(["\u4e09\u3064\u306e\u9054\u4eba","1\u4f53\u306e\u30c9\u30e9\u30b4\u30f3\u3067\u529b\u30fb\u795e\u79d8\u30fb\u7cbe\u795e\u3092\u3059\u3079\u3066300\u306b\u3059\u308b\u3002"],t.s)
A.M4=new B.u(A.j,[A.tC,A.Fu,A.jR,A.nr,A.D0,A.nu],t.M)
A.ko=s(["Perfekt im Gleichgewicht","Entwickle einen Drachen zu seiner geheimen Mastery-Form."],t.s)
A.HK=s(["Perfectamente equilibrado","Evoluciona un drag\xf3n a su forma secreta de Mastery."],t.s)
A.Jt=s(["Parfaitement \xe9quilibr\xe9","Fais \xe9voluer un dragon vers sa forme secr\xe8te de Mastery."],t.s)
A.m8=s(["Perfettamente equilibrato","Fai evolvere un drago nella sua forma segreta Mastery."],t.s)
A.v6=s(["Perfeitamente equilibrado","Evolua um drag\xe3o para sua forma secreta de Mastery."],t.s)
A.z1=s(["\u5b8c\u74a7\u306a\u5747\u8861","\u30c9\u30e9\u30b4\u30f3\u3092\u79d8\u5bc6\u306e\u30de\u30b9\u30bf\u30ea\u30fc\u5f62\u614b\u3078\u9032\u5316\u3055\u305b\u308b\u3002"],t.s)
A.M1=new B.u(A.j,[A.ko,A.HK,A.Jt,A.m8,A.v6,A.z1],t.M)
A.Cg=s(["Sieh an, wer zur\xfcckgekrochen kam","Erhalte Besuch von einem freigelassenen Drachen."],t.s)
A.n4=s(["Mira qui\xe9n volvi\xf3 arrastr\xe1ndose","Recibe la visita de un drag\xf3n liberado."],t.s)
A.w_=s(["Tiens, qui revoil\xe0","Re\xe7ois la visite d\u2019un dragon lib\xe9r\xe9."],t.s)
A.mv=s(["Guarda chi \xe8 tornato strisciando","Ricevi la visita di un drago liberato."],t.s)
A.La=s(["Olha quem voltou rastejando","Receba a visita de um drag\xe3o libertado."],t.s)
A.pa=s(["\u9019\u3044\u623b\u3063\u3066\u304d\u305f\u306e\u306f\u8ab0\uff1f","\u653e\u3057\u305f\u30c9\u30e9\u30b4\u30f3\u306e\u8a2a\u554f\u3092\u53d7\u3051\u308b\u3002"],t.s)
A.M2=new B.u(A.j,[A.Cg,A.n4,A.w_,A.mv,A.La,A.pa],t.M)
A.JQ=s(["Der Himmel hat doch eine Decke","Erreiche 20 Turmgeschosse."],t.s)
A.B2=s(["El cielo s\xed ten\xeda techo","Alcanza 20 pisos de la Torre."],t.s)
A.mh=s(["Le ciel a donc un plafond","Atteins 20 \xe9tages de la Tour."],t.s)
A.E_=s(["Il cielo ha davvero un soffitto","Raggiungi 20 piani della Torre."],t.s)
A.Gn=s(["O c\xe9u tem teto, afinal","Alcance 20 andares da Torre."],t.s)
A.yO=s(["\u7a7a\u306b\u3082\u5929\u4e95\u306f\u3042\u3063\u305f","\u30c9\u30e9\u30b4\u30f3\u30bf\u30ef\u30fc\u309220\u968e\u307e\u3067\u5efa\u3066\u308b\u3002"],t.s)
A.LV=new B.u(A.j,[A.JQ,A.B2,A.mh,A.E_,A.Gn,A.yO],t.M)
A.ov=s(["Eine Schuppe f\xfcr jede Geschichte","Entdecke 42 Drachenfamilien."],t.s)
A.pi=s(["Una escama para cada historia","Descubre las 42 familias de dragones."],t.s)
A.z6=s(["Une \xe9caille pour chaque histoire","D\xe9couvre les 42 familles de dragons."],t.s)
A.uP=s(["Una squama per ogni storia","Scopri 42 famiglie di draghi."],t.s)
A.w8=s(["Uma escama para cada hist\xf3ria","Descubra as 42 fam\xedlias de drag\xf5es."],t.s)
A.k4=s(["\u7269\u8a9e\u3054\u3068\u306b\u4e00\u679a\u306e\u9c57","\u30c9\u30e9\u30b4\u30f3\u4e00\u65cf\u309242\u7a2e\u767a\u898b\u3059\u308b\u3002"],t.s)
A.M7=new B.u(A.j,[A.ov,A.pi,A.z6,A.uP,A.w8,A.k4],t.M)
A.ls=s(["Geisterschreiber","Entdecke Spektralformen von 10 Familien."],t.s)
A.t1=s(["Escritor fantasma","Descubre formas Espectrales de 10 familias."],t.s)
A.GM=s(["N\xe8gre spectral","D\xe9couvre les formes Spectrales de 10 familles."],t.s)
A.Ld=s(["Scrittore fantasma","Scopri forme Spettrali di 10 famiglie."],t.s)
A.El=s(["Escritor fantasma","Descubra formas Espectrais de 10 fam\xedlias."],t.s)
A.De=s(["\u30b4\u30fc\u30b9\u30c8\u30e9\u30a4\u30bf\u30fc","10\u4e00\u65cf\u306e\u30b9\u30da\u30af\u30c8\u30e9\u30eb\u5f62\u614b\u3092\u767a\u898b\u3059\u308b\u3002"],t.s)
A.M6=new B.u(A.j,[A.ls,A.t1,A.GM,A.Ld,A.El,A.De],t.M)
A.Da=s(["Mythos wird Wirklichkeit","Erhalte einen Drachen aus einer mythischen Familie."],t.s)
A.lX=s(["El mito hecho realidad","Obt\xe9n un drag\xf3n de familia M\xedtica."],t.s)
A.Kw=s(["Le mythe devient r\xe9alit\xe9","Obtiens un dragon d\u2019une famille Mythique."],t.s)
A.nx=s(["Il mito diventa realt\xe0","Ottieni un drago di famiglia Mitica."],t.s)
A.Ak=s(["O mito se torna real","Obtenha um drag\xe3o de fam\xedlia M\xedtica."],t.s)
A.mF=s(["\u795e\u8a71\u304c\u73fe\u5b9f\u306b","\u30df\u30b7\u30ab\u30eb\u4e00\u65cf\u306e\u30c9\u30e9\u30b4\u30f3\u3092\u624b\u306b\u5165\u308c\u308b\u3002"],t.s)
A.LZ=new B.u(A.j,[A.Da,A.lX,A.Kw,A.nx,A.Ak,A.mF],t.M)
A.Fz=s(["Mauer? Welche Mauer?","Erreiche Rang S+ in Ruinenbrecher."],t.s)
A.r1=s(["\xbfMuro? \xbfQu\xe9 muro?","Consigue rango S+ en Romperruinas."],t.s)
A.KF=s(["Un mur ? Quel mur ?","Obtiens le rang S+ dans Briseur de ruines."],t.s)
A.Ed=s(["Muro? Quale muro?","Ottieni il grado S+ in Spezzarovine."],t.s)
A.Ik=s(["Muro? Que muro?","Alcance a classifica\xe7\xe3o S+ em Quebra-ru\xednas."],t.s)
A.td=s(["\u58c1\uff1f\u4f55\u306e\u58c1\uff1f","\u30eb\u30a4\u30f3\u30d6\u30ec\u30a4\u30ab\u30fc\u3067S+\u30e9\u30f3\u30af\u3092\u7372\u5f97\u3059\u308b\u3002"],t.s)
A.LG=new B.u(A.j,[A.Fz,A.r1,A.KF,A.Ed,A.Ik,A.td],t.M)
A.mg=s(["Kristallklarer Flug","Erreiche Rang S+ im H\xf6hlenflug."],t.s)
A.K9=s(["Vuelo cristalino","Consigue rango S+ en Vuelo cavernario."],t.s)
A.zi=s(["Vol cristallin","Obtiens le rang S+ dans Vol cavernicole."],t.s)
A.E9=s(["Volo cristallino","Ottieni il grado S+ in Volo nella caverna."],t.s)
A.y_=s(["Voo cristalino","Alcance a classifica\xe7\xe3o S+ em Voo na caverna."],t.s)
A.C6=s(["\u6c34\u6676\u306e\u3088\u3046\u306a\u98db\u884c","\u6d1e\u7a9f\u98db\u884c\u3067S+\u30e9\u30f3\u30af\u3092\u7372\u5f97\u3059\u308b\u3002"],t.s)
A.LF=new B.u(A.j,[A.mg,A.K9,A.zi,A.E9,A.y_,A.C6],t.M)
A.qv=s(["Rune erledigt","Erreiche Rang S+ in Runenweber."],t.s)
A.m9=s(["Runa resuelta","Consigue rango S+ en Tejerrunas."],t.s)
A.FS=s(["Rune accomplie","Obtiens le rang S+ dans Tisseur de runes."],t.s)
A.mL=s(["Runa compiuta","Ottieni il grado S+ in Tessirune."],t.s)
A.mk=s(["Runa conclu\xedda","Alcance a classifica\xe7\xe3o S+ em Tecel\xe3o de runas."],t.s)
A.Je=s(["\u30eb\u30fc\u30f3\u5b8c\u4e86","\u30eb\u30fc\u30f3\u30a6\u30a3\u30fc\u30d0\u30fc\u3067S+\u30e9\u30f3\u30af\u3092\u7372\u5f97\u3059\u308b\u3002"],t.s)
A.LD=new B.u(A.j,[A.qv,A.m9,A.FS,A.mL,A.mk,A.Je],t.M)
A.vO=s(["Gewinner, Gewinner, H\xfchnerdinner","Br\xfcte die geheime Cluckatrice aus einem Spezial-Ei aus."],t.s)
A.mt=s(["Ganador, ganador, cena de pollo","Haz eclosionar a la Cluckatrice secreta de un Huevo especial."],t.s)
A.qW=s(["Gagnant, gagnant, d\xeener de poulet","Fais \xe9clore la Cluckatrice secr\xe8te d\u2019un \u0152uf sp\xe9cial."],t.s)
A.pc=s(["Vincitore, vincitore, cena di pollo","Fai schiudere la Cluckatrice segreta da un Uovo speciale."],t.s)
A.kd=s(["Vencedor, vencedor, jantar de frango","Fa\xe7a a Cluckatrice secreta nascer de um Ovo especial."],t.s)
A.EF=s(["\u52dd\u8005\u306e\u30c1\u30ad\u30f3\u30c7\u30a3\u30ca\u30fc","\u30b9\u30da\u30b7\u30e3\u30eb\u30a8\u30c3\u30b0\u304b\u3089\u79d8\u5bc6\u306e\u30af\u30c3\u30ab\u30c8\u30ea\u30b9\u3092\u5b75\u5316\u3055\u305b\u308b\u3002"],t.s)
A.Ma=new B.u(A.j,[A.vO,A.mt,A.qW,A.pc,A.kd,A.EF],t.M)
A.lT=s(["W\xe4chter des Hexenlichts","Br\xfcte Gloamgourd aus einem Hexenlicht-Ei aus."],t.s)
A.pG=s(["Guardi\xe1n de la Luz de Bruja","Haz eclosionar a Gloamgourd de un Huevo de Luz de Bruja."],t.s)
A.xk=s(["Gardien de la Lueur sorci\xe8re","Fais \xe9clore Gloamgourd d\u2019un \u0152uf de Lueur sorci\xe8re."],t.s)
A.p3=s(["Custode della Luce Stregata","Fai schiudere Gloamgourd da un Uovo della Luce Stregata."],t.s)
A.kU=s(["Guardi\xe3o da Luz Feiticeira","Fa\xe7a Gloamgourd nascer de um Ovo da Luz Feiticeira."],t.s)
A.zg=s(["\u30a6\u30a3\u30c3\u30c1\u30e9\u30a4\u30c8\u306e\u5b88\u308a\u624b","\u30a6\u30a3\u30c3\u30c1\u30e9\u30a4\u30c8\u30a8\u30c3\u30b0\u304b\u3089\u30b0\u30ed\u30fc\u30e0\u30b4\u30fc\u30c9\u3092\u5b75\u5316\u3055\u305b\u308b\u3002"],t.s)
A.M8=new B.u(A.j,[A.lT,A.pG,A.xk,A.p3,A.kU,A.zg],t.M)
A.GR=s(["Ein Stern in jeder Feuerstelle","Br\xfcte Hollyfrost aus einem Sternenlicht-Tannenei aus."],t.s)
A.rv=s(["Una estrella en cada hogar","Haz eclosionar a Hollyfrost de un Huevo de Abeto Estrellado."],t.s)
A.zn=s(["Une \xe9toile dans chaque foyer","Fais \xe9clore Hollyfrost d\u2019un \u0152uf de Sapin \xe9toil\xe9."],t.s)
A.Ku=s(["Una stella in ogni focolare","Fai schiudere Hollyfrost da un Uovo di Abete Stellato."],t.s)
A.II=s(["Uma estrela em cada lareira","Fa\xe7a Hollyfrost nascer de um Ovo de Pinheiro Estrelado."],t.s)
A.zX=s(["\u3059\u3079\u3066\u306e\u7089\u8fba\u306b\u661f\u3092","\u30b9\u30bf\u30fc\u30ea\u30c3\u30c8\u30fb\u30a8\u30d0\u30fc\u30b0\u30ea\u30fc\u30f3\u30a8\u30c3\u30b0\u304b\u3089\u30db\u30ea\u30fc\u30d5\u30ed\u30b9\u30c8\u3092\u5b75\u5316\u3055\u305b\u308b\u3002"],t.s)
A.LU=new B.u(A.j,[A.GR,A.rv,A.zn,A.Ku,A.II,A.zX],t.M)
A.Gd=s(["Erstes Licht, erster Flug","Br\xfcte Dawnchime aus einem Jahreswende-Ei aus."],t.s)
A.lV=s(["Primera luz, primer vuelo","Haz eclosionar a Dawnchime de un Huevo de Fin de A\xf1o."],t.s)
A.nf=s(["Premi\xe8re lueur, premier vol","Fais \xe9clore Dawnchime d\u2019un \u0152uf du Renouveau."],t.s)
A.uE=s(["Prima luce, primo volo","Fai schiudere Dawnchime da un Uovo del Volgere dell\u2019Anno."],t.s)
A.JM=s(["Primeira luz, primeiro voo","Fa\xe7a Dawnchime nascer de um Ovo da Virada do Ano."],t.s)
A.KQ=s(["\u6700\u521d\u306e\u5149\u3001\u6700\u521d\u306e\u98db\u7fd4","\u30bf\u30fc\u30cb\u30f3\u30b0\u30a4\u30e4\u30fc\u30a8\u30c3\u30b0\u304b\u3089\u30c9\u30fc\u30f3\u30c1\u30e3\u30a4\u30e0\u3092\u5b75\u5316\u3055\u305b\u308b\u3002"],t.s)
A.LR=new B.u(A.j,[A.Gd,A.lV,A.nf,A.uE,A.JM,A.KQ],t.M)
A.k3=s(["Zwei Herzen, ein Flug","Br\xfcte Rosevow aus einem Rosenbund-Ei aus."],t.s)
A.Fi=s(["Dos corazones, un vuelo","Haz eclosionar a Rosevow de un Huevo del V\xednculo de Rosas."],t.s)
A.ts=s(["Deux c\u0153urs, un seul vol","Fais \xe9clore Rosevow d\u2019un \u0152uf du Lien de Rose."],t.s)
A.ke=s(["Due cuori, un solo volo","Fai schiudere Rosevow da un Uovo del Vincolo di Rose."],t.s)
A.EQ=s(["Dois cora\xe7\xf5es, um voo","Fa\xe7a Rosevow nascer de um Ovo do La\xe7o de Rosas."],t.s)
A.IO=s(["\u4e8c\u3064\u306e\u5fc3\u3001\u4e00\u3064\u306e\u98db\u7fd4","\u30ed\u30fc\u30ba\u30d0\u30a6\u30f3\u30c9\u30a8\u30c3\u30b0\u304b\u3089\u30ed\u30fc\u30ba\u30f4\u30a1\u30a6\u3092\u5b75\u5316\u3055\u305b\u308b\u3002"],t.s)
A.LM=new B.u(A.j,[A.k3,A.Fi,A.ts,A.ke,A.EQ,A.IO],t.M)
A.DY=s(["Jede Farbe erhebt sich","Br\xfcte Spectrumplume aus einem Echtfarben-Ei aus."],t.s)
A.oB=s(["Cada color alza el vuelo","Haz eclosionar a Spectrumplume de un Huevo de Colores Verdaderos."],t.s)
A.ud=s(["Chaque couleur prend son envol","Fais \xe9clore Spectrumplume d\u2019un \u0152uf aux Vraies Couleurs."],t.s)
A.AD=s(["Ogni colore prende il volo","Fai schiudere Spectrumplume da un Uovo dai Colori Autentici."],t.s)
A.oi=s(["Toda cor ganha asas","Fa\xe7a Spectrumplume nascer de um Ovo de Cores Verdadeiras."],t.s)
A.GY=s(["\u3059\u3079\u3066\u306e\u8272\u304c\u7fbd\u3070\u305f\u304f","\u30c8\u30a5\u30eb\u30fc\u30ab\u30e9\u30fc\u30a8\u30c3\u30b0\u304b\u3089\u30b9\u30da\u30af\u30c8\u30e9\u30e0\u30d7\u30eb\u30fc\u30e0\u3092\u5b75\u5316\u3055\u305b\u308b\u3002"],t.s)
A.LT=new B.u(A.j,[A.DY,A.oB,A.ud,A.AD,A.oi,A.GY],t.M)
A.Ip=s(["Das geht bestimmt gut","Schlie\xdfe ein finsteres Spezialabenteuer ab."],t.s)
A.Kq=s(["Seguro que todo sale bien","Completa una Aventura especial siniestra."],t.s)
A.AW=s(["\xc7a va s\xfbrement bien se passer","Termine une Aventure sp\xe9ciale sinistre."],t.s)
A.oV=s(["Andr\xe0 sicuramente tutto bene","Completa un\u2019Avventura speciale sinistra."],t.s)
A.of=s(["Provavelmente vai dar tudo certo","Conclua uma Aventura especial sinistra."],t.s)
A.GU=s(["\u305f\u3076\u3093\u5927\u4e08\u592b","\u4e0d\u5409\u306a\u30b9\u30da\u30b7\u30e3\u30eb\u5192\u967a\u3092\u5b8c\u4e86\u3059\u308b\u3002"],t.s)
A.LN=new B.u(A.j,[A.Ip,A.Kq,A.AW,A.oV,A.of,A.GU],t.M)
A.rS=s(["Akademie-Absolvent","Hilf einem Drachen, die Drachenakademie erfolgreich abzuschlie\xdfen."],t.s)
A.EV=s(["Graduado de la academia","Ayuda a un drag\xf3n a completar con \xe9xito la Academia de Dragones."],t.s)
A.tZ=s(["Dipl\xf4m\xe9 de l\u2019acad\xe9mie","Aide un dragon \xe0 terminer l\u2019Acad\xe9mie des dragons avec succ\xe8s."],t.s)
A.qb=s(["Diplomato dell\u2019accademia","Aiuta un drago a completare con successo l\u2019Accademia dei Draghi."],t.s)
A.Fr=s(["Formado na academia","Ajude um drag\xe3o a concluir a Academia de Drag\xf5es com sucesso."],t.s)
A.ma=s(["\u30a2\u30ab\u30c7\u30df\u30fc\u5352\u696d\u751f","\u30c9\u30e9\u30b4\u30f31\u982d\u304c\u30c9\u30e9\u30b4\u30f3\u30a2\u30ab\u30c7\u30df\u30fc\u3092\u7121\u4e8b\u306b\u4fee\u4e86\u3059\u308b\u306e\u3092\u52a9\u3051\u308b\u3002"],t.s)
A.M5=new B.u(A.j,[A.rS,A.EV,A.tZ,A.qb,A.Fr,A.ma],t.M)
A.HE=s(["Drachenakademie-Abbrecher","Schlie\xdfe alle 30 offiziellen Versuche ab, ohne ein Diplom zu erhalten."],t.s)
A.AX=s(["Desertor de la Academia de Dragones","Completa los 30 intentos oficiales sin obtener un diploma."],t.s)
A.nh=s(["Dragon d\xe9crocheur","Termine les 30 tentatives officielles sans obtenir de dipl\xf4me."],t.s)
A.xr=s(["Drago che ha lasciato l\u2019accademia","Completa tutti i 30 tentativi ufficiali senza ottenere un diploma."],t.s)
A.zJ=s(["Desistente da Academia de Drag\xf5es","Conclua as 30 tentativas oficiais sem obter um diploma."],t.s)
A.yL=s(["\u30c9\u30e9\u30b4\u30f3\u30a2\u30ab\u30c7\u30df\u30fc\u4e2d\u9000","\u5352\u696d\u8a3c\u66f8\u3092\u5f97\u305a\u306b\u516c\u5f0f30\u56de\u306e\u6311\u6226\u3092\u3059\u3079\u3066\u7d42\u3048\u308b\u3002"],t.s)
A.LJ=new B.u(A.j,[A.HE,A.AX,A.nh,A.xr,A.zJ,A.yL],t.M)
A.KS=s(["Jahrgangsbester","Hilf einem Drachen, die Drachenakademie mit allen 30 Sternen abzuschlie\xdfen."],t.s)
A.uQ=s(["Mejor estudiante de la promoci\xf3n","Ayuda a un drag\xf3n a terminar la Academia de Dragones con las 30 estrellas."],t.s)
A.mB=s(["Major de promotion","Aide un dragon \xe0 terminer l\u2019Acad\xe9mie des dragons avec les 30 \xe9toiles."],t.s)
A.DA=s(["Migliore del corso","Aiuta un drago a finire l\u2019Accademia dei Draghi con tutte le 30 stelle."],t.s)
A.r6=s(["Melhor da turma","Ajude um drag\xe3o a terminar a Academia de Drag\xf5es com todas as 30 estrelas."],t.s)
A.zc=s(["\u9996\u5e2d\u5352\u696d\u751f","\u30c9\u30e9\u30b4\u30f31\u982d\u304c30\u500b\u3059\u3079\u3066\u306e\u661f\u3092\u7372\u5f97\u3057\u3066\u30c9\u30e9\u30b4\u30f3\u30a2\u30ab\u30c7\u30df\u30fc\u3092\u4fee\u4e86\u3059\u308b\u306e\u3092\u52a9\u3051\u308b\u3002"],t.s)
A.LO=new B.u(A.j,[A.KS,A.uQ,A.mB,A.DA,A.r6,A.zc],t.M)
A.LA=new B.u(A.O3,[A.LI,A.LL,A.LW,A.LC,A.M_,A.M0,A.LS,A.LP,A.LX,A.LQ,A.M3,A.LK,A.LH,A.LE,A.M9,A.LY,A.LB,A.Mb,A.M4,A.M1,A.M2,A.LV,A.M7,A.M6,A.LZ,A.LG,A.LF,A.LD,A.Ma,A.M8,A.LU,A.LR,A.LM,A.LT,A.LN,A.M5,A.LJ,A.LO],B.W("u<d,t<d,G<d>>>"))
A.f=new B.u(A.j,[0,1,2,3,4,5],t.cq)
A.O2={"7-day constellation":0,"The Egg Altar":1,"Got it":2,"How the Altar works":3,"Return to the Weave":4,"Choose another egg":5,"Give an egg back to the Weave and let its magic take a new form.":6,Details:7,"Still hidden":8,"Dragon family":9,"Moral alignment":10,"Order alignment":11,Incubation:12,Acquired:13,"Place on altar":14,"Choose this egg":15,"Reveal an egg\u2019s rarity.":16,"Reveal an egg\u2019s dragon family and rarity.":17,"Rename one dragon. Consumed on use.":18,"Use relic":19,"Returning to the Weave":20,"Returning...":21,"Choose an egg and read its details before placing it on the altar. If you want to keep an egg, tag it to protect it. When you are ready, hold Return to the Weave: the egg leaves your inventory permanently and becomes materials you can use to craft relics. Special eggs, tagged eggs, eggs in the nest and eggs reserved for a trade are protected. Returning a Sinister egg asks for one extra confirmation. Open Craft to choose a relic, check its materials and make it. Use your crafted relics to learn more about an egg or give a dragon a new name.":22,"No eggs available.":23,"Name your dragon first.":24,"Untag this egg before returning it.":25,"Special eggs are always protected.":26,"The egg in the nest is protected.":27,"This egg is reserved for a trade.":28,"Not enough materials.":29,"This information is already known.":30,"Craft this relic first.":31,"Choose a different name of 1\u201324 characters.":32,"Sign in to use the Egg Altar.":33,"Finish the pending action first.":34,"The Beacon needs fewer fragments now. Refresh and try again.":35,"You are no longer a member of this Conclave.":36,"This egg is no longer available.":37,"The action could not be completed. Reconnect and retry safely.":38,"Return to the Weave \xb7 craft relics":39,"Untag egg":40,"Tag egg":41,"Tagged \xb7 untag":42,"Return a Sinister Egg?":43,"This permanently returns your Sinister Egg to the Weave. This cannot be undone.":44,"Return Sinister Egg":45,"Return rewards":46,"Every ordinary egg gives 5 Shell Fragments. Independent bonuses: 25% for 1 Draconic Essence and 2% for 1 Weaveheart. After 39 returns without a Weaveheart, the next is guaranteed. Sinister eggs always give 25 Shell Fragments and 3, 4 or 5 Draconic Essence with equal chances, plus an independent 10% chance of 1 Weaveheart. Every returned egg advances the counter once. Materials and crafted relics cannot be traded.":47,"Returns without a Weaveheart":48,Return:49,Craft:50,"Pending action":51,Retry:52,"This egg will leave your inventory permanently. Hold the button to return it to the Weave.":53,Tagged:54,Untagged:55,"Egg in the nest":56,"Reveal an egg\u2019s moral alignment.":57,"Reveal an egg\u2019s order alignment.":58,"Reveal an egg\u2019s rarity. Also found in existing drops.":59,"Reveal an egg\u2019s dragon family and rarity. Altar exclusive.":60,"Rename one dragon. Consumed on use. Altar exclusive.":61,Owned:62,"Use one relic on this egg?":63,"Consumes one Quill when the name is changed.":64,Rename:65,"Hold to Return to the Weave":66,"Returned to the Weave":67,"Skip animation":68,"Donate Shell Fragments":69,"A voluntary gift to your Conclave\u2019s cosmetic Beacon. Donations cannot be taken back.":70,Donate:71,"Tap to reconnect":72,Stage:73,"The Weave shines in your Aerie!":74,"Build a shared decoration with Shell Fragments. Milestones: 500, 2000 and 5000.":75,"Donate fragments":76,"Game over":77}
A.oN=s(["7-Tage-Konstellation","Constelaci\xf3n de 7 d\xedas","Constellation sur 7 jours","Costellazione di 7 giorni","Constela\xe7\xe3o de 7 dias","7\u65e5\u9593\u306e\u661f\u5ea7"],t.s)
A.kn=s(["Der Eieraltar","El altar de huevos","L\u2019autel des \u0153ufs","L\u2019altare delle uova","O altar dos ovos","\u5375\u306e\u796d\u58c7"],t.s)
A.Hz=s(["Verstanden","Entendido","Compris","Capito","Entendido","\u308f\u304b\u308a\u307e\u3057\u305f"],t.s)
A.lZ=s(["So funktioniert der Altar","C\xf3mo funciona el altar","Comment fonctionne l\u2019autel","Come funziona l\u2019altare","Como funciona o altar","\u796d\u58c7\u306e\u4f7f\u3044\u65b9"],t.s)
A.D_=s(["Zur Weave zur\xfcckgeben","Devolver a la Weave","Rendre \xe0 la Weave","Restituisci alla Weave","Devolver \xe0 Weave","Weave\u3078\u8fd4\u3059"],t.s)
A.Id=s(["Anderes Ei w\xe4hlen","Elegir otro huevo","Choisir un autre \u0153uf","Scegli un altro uovo","Escolher outro ovo","\u5225\u306e\u5375\u3092\u9078\u3076"],t.s)
A.z0=s(["Gib ein Ei an die Weave zur\xfcck und lass seine Magie eine neue Form annehmen.","Devuelve un huevo a la Weave y deja que su magia tome una nueva forma.","Rends un \u0153uf \xe0 la Weave et laisse sa magie prendre une nouvelle forme.","Restituisci un uovo alla Weave e lascia che la sua magia prenda una nuova forma.","Devolve um ovo \xe0 Weave e deixa a sua magia ganhar uma nova forma.","\u5375\u3092Weave\u3078\u8fd4\u3059\u3068\u3001\u305d\u306e\u9b54\u6cd5\u304c\u65b0\u3057\u3044\u5f62\u306b\u306a\u308a\u307e\u3059\u3002"],t.s)
A.yp=s(["Details","Detalles","D\xe9tails","Dettagli","Detalhes","\u8a73\u7d30"],t.s)
A.Gi=s(["Noch verborgen","A\xfan oculto","Encore cach\xe9","Ancora nascosto","Ainda oculto","\u307e\u3060\u4e0d\u660e"],t.s)
A.FX=s(["Drachenfamilie","Familia de dragones","Famille de dragons","Famiglia del drago","Fam\xedlia do drag\xe3o","\u30c9\u30e9\u30b4\u30f3\u306e\u7cfb\u7d71"],t.s)
A.qq=s(["Moralische Gesinnung","Alineamiento moral","Alignement moral","Allineamento morale","Alinhamento moral","\u5584\u60aa\u306e\u6027\u8cea"],t.s)
A.H9=s(["Ordnungsgesinnung","Alineamiento de orden","Alignement d\u2019ordre","Allineamento d\u2019ordine","Alinhamento de ordem","\u79e9\u5e8f\u306e\u6027\u8cea"],t.s)
A.DO=s(["Brutzeit","Incubaci\xf3n","Incubation","Incubazione","Incuba\xe7\xe3o","\u5b75\u5316\u6642\u9593"],t.s)
A.E7=s(["Erhalten","Obtenido","Obtenu","Ottenuto","Obtido","\u5165\u624b\u65e5"],t.s)
A.wP=s(["Auf den Altar legen","Colocar en el altar","Placer sur l\u2019autel","Metti sull\u2019altare","Colocar no altar","\u796d\u58c7\u306b\u7f6e\u304f"],t.s)
A.tl=s(["Dieses Ei w\xe4hlen","Elegir este huevo","Choisir cet \u0153uf","Scegli questo uovo","Escolher este ovo","\u3053\u306e\u5375\u3092\u9078\u3076"],t.s)
A.vz=s(["Enth\xfclle die Seltenheit eines Eis.","Revela la rareza de un huevo.","R\xe9v\xe8le la raret\xe9 d\u2019un \u0153uf.","Rivela la rarit\xe0 di un uovo.","Revela a raridade de um ovo.","\u5375\u306e\u30ec\u30a2\u5ea6\u3092\u660e\u3089\u304b\u306b\u3057\u307e\u3059\u3002"],t.s)
A.jQ=s(["Enth\xfclle Drachenfamilie und Seltenheit eines Eis.","Revela la familia y la rareza del drag\xf3n de un huevo.","R\xe9v\xe8le la famille et la raret\xe9 du dragon d\u2019un \u0153uf.","Rivela la famiglia e la rarit\xe0 del drago di un uovo.","Revela a fam\xedlia e a raridade do drag\xe3o de um ovo.","\u5375\u306e\u30c9\u30e9\u30b4\u30f3\u306e\u7cfb\u7d71\u3068\u30ec\u30a2\u5ea6\u3092\u660e\u3089\u304b\u306b\u3057\u307e\u3059\u3002"],t.s)
A.rq=s(["Benenne einen Drachen um. Wird beim Gebrauch verbraucht.","Cambia el nombre de un drag\xf3n. Se consume al usarla.","Renomme un dragon. Consomm\xe9 \xe0 l\u2019utilisation.","Rinomina un drago. Si consuma dopo l\u2019uso.","Muda o nome de um drag\xe3o. Consumido ao usar.","\u30c9\u30e9\u30b4\u30f31\u4f53\u306e\u540d\u524d\u3092\u5909\u66f4\u3057\u307e\u3059\u3002\u4f7f\u7528\u3059\u308b\u3068\u6d88\u8cbb\u3055\u308c\u307e\u3059\u3002"],t.s)
A.KE=s(["Relikt verwenden","Usar reliquia","Utiliser la relique","Usa reliquia","Usar rel\xedquia","\u30ec\u30ea\u30c3\u30af\u3092\u4f7f\u3046"],t.s)
A.JV=s(["R\xfcckkehr zur Weave","Regresando a la Weave","Retour \xe0 la Weave","Ritorno alla Weave","A regressar \xe0 Weave","Weave\u3078\u9084\u5143\u4e2d"],t.s)
A.pT=s(["Wird zur\xfcckgegeben...","Devolviendo...","Retour en cours...","Restituzione...","A devolver...","\u9084\u5143\u4e2d..."],t.s)
A.yf=s(["W\xe4hle ein Ei und lies seine Details, bevor du es auf den Altar legst. Markiere Eier, die du behalten m\xf6chtest, um sie zu sch\xfctzen. Wenn du bereit bist, halte \u201eZur Weave zur\xfcckgeben\u201c gedr\xfcckt: Das Ei verl\xe4sst dein Inventar dauerhaft und wird zu Materialien, aus denen du Relikte herstellen kannst. Spezial-Eier, markierte Eier, Eier im Nest und f\xfcr einen Tausch reservierte Eier sind gesch\xfctzt. Bei einem Sinister-Ei ist eine zus\xe4tzliche Best\xe4tigung erforderlich. \xd6ffne \u201eHerstellen\u201c, w\xe4hle ein Relikt und pr\xfcfe die ben\xf6tigten Materialien. Mit deinen hergestellten Relikten erf\xe4hrst du mehr \xfcber ein Ei oder gibst einem Drachen einen neuen Namen.","Elige un huevo y lee sus detalles antes de colocarlo en el altar. Si quieres conservarlo, etiqu\xe9talo para protegerlo. Cuando est\xe9s listo, mant\xe9n pulsado \xabDevolver a la Weave\xbb: el huevo desaparecer\xe1 de tu inventario para siempre y se convertir\xe1 en materiales para fabricar reliquias. Los huevos especiales, etiquetados, en el nido o reservados para un intercambio est\xe1n protegidos. Devolver un huevo Sinister requiere una confirmaci\xf3n adicional. Abre \xabFabricar\xbb, elige una reliquia y comprueba sus materiales. Usa tus reliquias fabricadas para saber m\xe1s sobre un huevo o cambiar el nombre de un drag\xf3n.","Choisis un \u0153uf et lis ses d\xe9tails avant de le placer sur l\u2019autel. Pour garder un \u0153uf, marque-le afin de le prot\xe9ger. Quand tu es pr\xeat, maintiens \xab Rendre \xe0 la Weave \xbb : l\u2019\u0153uf quitte d\xe9finitivement ton inventaire et devient des mat\xe9riaux pour fabriquer des reliques. Les \u0153ufs sp\xe9ciaux, marqu\xe9s, dans le nid ou r\xe9serv\xe9s \xe0 un \xe9change sont prot\xe9g\xe9s. Rendre un \u0153uf Sinister demande une confirmation suppl\xe9mentaire. Ouvre \xab Fabriquer \xbb, choisis une relique et v\xe9rifie ses mat\xe9riaux. Utilise tes reliques fabriqu\xe9es pour en apprendre davantage sur un \u0153uf ou donner un nouveau nom \xe0 un dragon.","Scegli un uovo e leggi i dettagli prima di metterlo sull\u2019altare. Se vuoi conservarlo, contrassegnalo per proteggerlo. Quando sei pronto, tieni premuto \xabRestituisci alla Weave\xbb: l\u2019uovo lascer\xe0 definitivamente l\u2019inventario e diventer\xe0 materiale per creare reliquie. Le uova speciali, contrassegnate, nel nido o riservate a uno scambio sono protette. Restituire un uovo Sinister richiede una conferma aggiuntiva. Apri \xabCrea\xbb, scegli una reliquia e controlla i materiali necessari. Usa le reliquie create per scoprire di pi\xf9 su un uovo o dare un nuovo nome a un drago.","Escolhe um ovo e l\xea os seus detalhes antes de o colocares no altar. Se o quiseres guardar, marca-o para o proteger. Quando estiveres pronto, mant\xe9m \xabDevolver \xe0 Weave\xbb premido: o ovo sai definitivamente do invent\xe1rio e transforma-se em materiais para criar rel\xedquias. Os ovos especiais, marcados, no ninho ou reservados para uma troca est\xe3o protegidos. Devolver um ovo Sinister exige uma confirma\xe7\xe3o adicional. Abre \xabCriar\xbb, escolhe uma rel\xedquia e verifica os materiais necess\xe1rios. Usa as rel\xedquias criadas para saber mais sobre um ovo ou dar um novo nome a um drag\xe3o.","\u5375\u3092\u9078\u3073\u3001\u8a73\u7d30\u3092\u78ba\u8a8d\u3057\u3066\u304b\u3089\u796d\u58c7\u306b\u7f6e\u304d\u307e\u3057\u3087\u3046\u3002\u6b8b\u3057\u3066\u304a\u304d\u305f\u3044\u5375\u306f\u30bf\u30b0\u3092\u4ed8\u3051\u3066\u4fdd\u8b77\u3067\u304d\u307e\u3059\u3002\u6e96\u5099\u304c\u3067\u304d\u305f\u3089\u300cWeave\u3078\u8fd4\u3059\u300d\u3092\u9577\u62bc\u3057\u3057\u3066\u304f\u3060\u3055\u3044\u3002\u5375\u306f\u30a4\u30f3\u30d9\u30f3\u30c8\u30ea\u304b\u3089\u6c38\u4e45\u306b\u306a\u304f\u306a\u308a\u3001\u30ec\u30ea\u30c3\u30af\u3092\u4f5c\u308b\u305f\u3081\u306e\u7d20\u6750\u306b\u306a\u308a\u307e\u3059\u3002Special\u306e\u5375\u3001\u30bf\u30b0\u4ed8\u304d\u306e\u5375\u3001\u5de3\u306b\u3042\u308b\u5375\u3001\u4ea4\u63db\u7528\u306b\u4e88\u7d04\u3055\u308c\u305f\u5375\u306f\u4fdd\u8b77\u3055\u308c\u3066\u3044\u307e\u3059\u3002Sinister\u306e\u5375\u3092\u8fd4\u3059\u306b\u306f\u8ffd\u52a0\u306e\u78ba\u8a8d\u304c\u5fc5\u8981\u3067\u3059\u3002\u300c\u4f5c\u6210\u300d\u3092\u958b\u304d\u3001\u30ec\u30ea\u30c3\u30af\u3092\u9078\u3093\u3067\u5fc5\u8981\u306a\u7d20\u6750\u3092\u78ba\u8a8d\u3057\u307e\u3057\u3087\u3046\u3002\u4f5c\u6210\u3057\u305f\u30ec\u30ea\u30c3\u30af\u3067\u5375\u306b\u3064\u3044\u3066\u8abf\u3079\u305f\u308a\u3001\u30c9\u30e9\u30b4\u30f3\u306e\u540d\u524d\u3092\u5909\u66f4\u3057\u305f\u308a\u3067\u304d\u307e\u3059\u3002"],t.s)
A.Gq=s(["Keine Eier verf\xfcgbar.","No hay huevos disponibles.","Aucun \u0153uf disponible.","Nessun uovo disponibile.","N\xe3o h\xe1 ovos dispon\xedveis.","\u5229\u7528\u3067\u304d\u308b\u5375\u304c\u3042\u308a\u307e\u305b\u3093\u3002"],t.s)
A.Bt=s(["Gib deinem Drachen zuerst einen Namen.","Dale un nombre a tu drag\xf3n primero.","Donne d\u2019abord un nom \xe0 ton dragon.","Dai prima un nome al tuo drago.","D\xe1 primeiro um nome ao teu drag\xe3o.","\u307e\u305a\u30c9\u30e9\u30b4\u30f3\u306b\u540d\u524d\u3092\u4ed8\u3051\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.Di=s(["Entferne zuerst die Markierung dieses Eis.","Quita la etiqueta del huevo antes de devolverlo.","Retire le marquage de cet \u0153uf avant de le rendre.","Rimuovi il contrassegno prima di restituire questo uovo.","Remove a marca deste ovo antes de o devolver.","\u8fd4\u3059\u524d\u306b\u3053\u306e\u5375\u306e\u30bf\u30b0\u3092\u5916\u3057\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.rs=s(["Spezial-Eier sind immer gesch\xfctzt.","Los huevos especiales siempre est\xe1n protegidos.","Les \u0153ufs sp\xe9ciaux sont toujours prot\xe9g\xe9s.","Le uova speciali sono sempre protette.","Os ovos especiais est\xe3o sempre protegidos.","\u30b9\u30da\u30b7\u30e3\u30eb\u306e\u5375\u306f\u5e38\u306b\u4fdd\u8b77\u3055\u308c\u307e\u3059\u3002"],t.s)
A.mz=s(["Das Ei im Nest ist gesch\xfctzt.","El huevo del nido est\xe1 protegido.","L\u2019\u0153uf dans le nid est prot\xe9g\xe9.","L\u2019uovo nel nido \xe8 protetto.","O ovo no ninho est\xe1 protegido.","\u5de3\u306e\u4e2d\u306e\u5375\u306f\u4fdd\u8b77\u3055\u308c\u307e\u3059\u3002"],t.s)
A.EY=s(["Dieses Ei ist f\xfcr einen Tausch reserviert.","Este huevo est\xe1 reservado para un intercambio.","Cet \u0153uf est r\xe9serv\xe9 pour un \xe9change.","Questo uovo \xe8 riservato a uno scambio.","Este ovo est\xe1 reservado para uma troca.","\u3053\u306e\u5375\u306f\u4ea4\u63db\u7528\u306b\u4e88\u7d04\u3055\u308c\u3066\u3044\u307e\u3059\u3002"],t.s)
A.pQ=s(["Nicht genug Materialien.","No hay suficientes materiales.","Mat\xe9riaux insuffisants.","Materiali insufficienti.","Materiais insuficientes.","\u7d20\u6750\u304c\u8db3\u308a\u307e\u305b\u3093\u3002"],t.s)
A.jM=s(["Diese Information ist bereits bekannt.","Esta informaci\xf3n ya se conoce.","Cette information est d\xe9j\xe0 connue.","Questa informazione \xe8 gi\xe0 nota.","Esta informa\xe7\xe3o j\xe1 \xe9 conhecida.","\u3053\u306e\u60c5\u5831\u306f\u3059\u3067\u306b\u5224\u660e\u3057\u3066\u3044\u307e\u3059\u3002"],t.s)
A.D6=s(["Stelle dieses Relikt zuerst her.","Fabrica esta reliquia primero.","Fabrique d\u2019abord cette relique.","Crea prima questa reliquia.","Cria primeiro esta rel\xedquia.","\u5148\u306b\u3053\u306e\u30ec\u30ea\u30c3\u30af\u3092\u4f5c\u6210\u3057\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.kg=s(["W\xe4hle einen anderen Namen mit 1\u201324 Zeichen.","Elige otro nombre de 1 a 24 caracteres.","Choisis un autre nom de 1 \xe0 24 caract\xe8res.","Scegli un altro nome da 1 a 24 caratteri.","Escolhe outro nome com 1 a 24 caracteres.","1\uff5e24\u6587\u5b57\u306e\u5225\u306e\u540d\u524d\u3092\u9078\u3093\u3067\u304f\u3060\u3055\u3044\u3002"],t.s)
A.GK=s(["Melde dich an, um den Egg Altar zu nutzen.","Inicia sesi\xf3n para usar el Egg Altar.","Connecte-toi pour utiliser l\u2019Egg Altar.","Accedi per usare l\u2019Egg Altar.","Inicia sess\xe3o para usar o Egg Altar.","Egg Altar\u3092\u4f7f\u3046\u306b\u306f\u30ed\u30b0\u30a4\u30f3\u3057\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.FE=s(["Schlie\xdfe zuerst die ausstehende Aktion ab.","Completa primero la acci\xf3n pendiente.","Termine d\u2019abord l\u2019action en attente.","Completa prima l\u2019azione in sospeso.","Conclui primeiro a a\xe7\xe3o pendente.","\u5148\u306b\u4fdd\u7559\u4e2d\u306e\u64cd\u4f5c\u3092\u5b8c\u4e86\u3057\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.lt=s(["Der Beacon ben\xf6tigt jetzt weniger Fragmente. Aktualisiere und versuche es erneut.","El Beacon necesita menos fragmentos ahora. Actualiza e int\xe9ntalo de nuevo.","Le Beacon a besoin de moins de fragments. Actualise et r\xe9essaie.","Ora al Beacon servono meno frammenti. Aggiorna e riprova.","O Beacon precisa agora de menos fragmentos. Atualiza e tenta novamente.","Beacon\u306b\u5fc5\u8981\u306a\u6b20\u7247\u304c\u6e1b\u308a\u307e\u3057\u305f\u3002\u66f4\u65b0\u3057\u3066\u518d\u8a66\u884c\u3057\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.Ke=s(["Du bist nicht mehr Mitglied dieses Conclaves.","Ya no perteneces a este Conclave.","Tu ne fais plus partie de ce Conclave.","Non fai pi\xf9 parte di questo Conclave.","J\xe1 n\xe3o pertences a este Conclave.","\u3053\u306eConclave\u306e\u30e1\u30f3\u30d0\u30fc\u3067\u306f\u306a\u304f\u306a\u308a\u307e\u3057\u305f\u3002"],t.s)
A.pm=s(["Dieses Ei ist nicht mehr verf\xfcgbar.","Este huevo ya no est\xe1 disponible.","Cet \u0153uf n\u2019est plus disponible.","Questo uovo non \xe8 pi\xf9 disponibile.","Este ovo j\xe1 n\xe3o est\xe1 dispon\xedvel.","\u3053\u306e\u5375\u306f\u3082\u3046\u5229\u7528\u3067\u304d\u307e\u305b\u3093\u3002"],t.s)
A.wC=s(["Die Aktion konnte nicht abgeschlossen werden. Verbinde dich erneut und versuche es sicher noch einmal.","No se pudo completar la acci\xf3n. Reconecta y vuelve a intentarlo de forma segura.","L\u2019action n\u2019a pas pu aboutir. Reconnecte-toi et r\xe9essaie sans risque.","Impossibile completare l\u2019azione. Riconnettiti e riprova in sicurezza.","N\xe3o foi poss\xedvel concluir a a\xe7\xe3o. Volta a ligar-te e tenta de novo em seguran\xe7a.","\u64cd\u4f5c\u3092\u5b8c\u4e86\u3067\u304d\u307e\u305b\u3093\u3067\u3057\u305f\u3002\u518d\u63a5\u7d9a\u3057\u3066\u5b89\u5168\u306b\u518d\u8a66\u884c\u3067\u304d\u307e\u3059\u3002"],t.s)
A.rQ=s(["Zur Weave zur\xfcckgeben \xb7 Relikte herstellen","Devolver a la Weave \xb7 fabricar reliquias","Rendre \xe0 la Weave \xb7 fabriquer des reliques","Restituisci alla Weave \xb7 crea reliquie","Devolver \xe0 Weave \xb7 criar rel\xedquias","Weave\u3078\u8fd4\u3059 \xb7 \u30ec\u30ea\u30c3\u30af\u4f5c\u6210"],t.s)
A.AP=s(["Ei-Markierung entfernen","Quitar etiqueta","Retirer le marquage","Rimuovi contrassegno","Remover marca","\u5375\u306e\u30bf\u30b0\u3092\u5916\u3059"],t.s)
A.l2=s(["Ei markieren","Etiquetar huevo","Marquer l\u2019\u0153uf","Contrassegna uovo","Marcar ovo","\u5375\u306b\u30bf\u30b0\u3092\u4ed8\u3051\u308b"],t.s)
A.IQ=s(["Markiert \xb7 entfernen","Etiquetado \xb7 quitar","Marqu\xe9 \xb7 retirer","Contrassegnato \xb7 rimuovi","Marcado \xb7 remover","\u30bf\u30b0\u4ed8\u304d \xb7 \u5916\u3059"],t.s)
A.BM=s(["Ein Sinister-Ei zur\xfcckgeben?","\xbfDevolver un huevo Sinister?","Rendre un \u0153uf Sinister ?","Restituire un uovo Sinister?","Devolver um ovo Sinister?","Sinister\u306e\u5375\u3092\u8fd4\u3057\u307e\u3059\u304b\uff1f"],t.s)
A.rl=s(["Dein Sinister-Ei kehrt endg\xfcltig zur Weave zur\xfcck. Dies kann nicht r\xfcckg\xe4ngig gemacht werden.","Tu huevo Sinister volver\xe1 definitivamente a la Weave. No se puede deshacer.","Ton \u0153uf Sinister retourne d\xe9finitivement \xe0 la Weave. Cette action est irr\xe9versible.","Il tuo uovo Sinister torna definitivamente alla Weave. Non si pu\xf2 annullare.","O teu ovo Sinister regressa definitivamente \xe0 Weave. N\xe3o \xe9 poss\xedvel anular.","Sinister\u306e\u5375\u3092\u6c38\u4e45\u306bWeave\u3078\u8fd4\u3057\u307e\u3059\u3002\u3053\u306e\u64cd\u4f5c\u306f\u53d6\u308a\u6d88\u305b\u307e\u305b\u3093\u3002"],t.s)
A.vi=s(["Sinister-Ei zur\xfcckgeben","Devolver huevo Sinister","Rendre l\u2019\u0153uf Sinister","Restituisci uovo Sinister","Devolver ovo Sinister","Sinister\u306e\u5375\u3092\u8fd4\u3059"],t.s)
A.yG=s(["R\xfcckgabe-Belohnungen","Recompensas al devolver","R\xe9compenses de retour","Ricompense della restituzione","Recompensas da devolu\xe7\xe3o","\u8fd4\u5374\u306e\u5831\u916c"],t.s)
A.uS=s(["Jedes normale Ei gibt 5 Shell Fragments. Unabh\xe4ngige Boni: 25% f\xfcr 1 Draconic Essence und 2% f\xfcr 1 Weaveheart. Nach 39 R\xfcckgaben ohne Weaveheart ist beim n\xe4chsten Ei eines garantiert. Sinister-Eier geben immer 25 Shell Fragments und mit gleicher Wahrscheinlichkeit 3, 4 oder 5 Draconic Essence, dazu unabh\xe4ngig eine Chance von 10% auf 1 Weaveheart. Jedes zur\xfcckgegebene Ei z\xe4hlt einmal. Materialien und hergestellte Relikte sind nicht tauschbar.","Cada huevo normal da 5 Shell Fragments. Bonificaciones independientes: 25% de obtener 1 Draconic Essence y 2% de obtener 1 Weaveheart. Tras 39 devoluciones sin Weaveheart, el siguiente est\xe1 garantizado. Los huevos Sinister siempre dan 25 Shell Fragments y 3, 4 o 5 Draconic Essence con igual probabilidad, m\xe1s una probabilidad independiente del 10% de obtener 1 Weaveheart. Cada huevo devuelto cuenta una vez. Los materiales y las reliquias fabricadas no se pueden intercambiar.","Chaque \u0153uf ordinaire donne 5 Shell Fragments. Bonus ind\xe9pendants : 25% pour 1 Draconic Essence et 2% pour 1 Weaveheart. Apr\xe8s 39 retours sans Weaveheart, le suivant est garanti. Les \u0153ufs Sinister donnent toujours 25 Shell Fragments et 3, 4 ou 5 Draconic Essence \xe0 chances \xe9gales, plus une chance ind\xe9pendante de 10% de recevoir 1 Weaveheart. Chaque \u0153uf rendu compte une fois. Les mat\xe9riaux et reliques fabriqu\xe9es ne sont pas \xe9changeables.","Ogni uovo normale d\xe0 5 Shell Fragments. Bonus indipendenti: 25% per 1 Draconic Essence e 2% per 1 Weaveheart. Dopo 39 restituzioni senza Weaveheart, il prossimo \xe8 garantito. Le uova Sinister danno sempre 25 Shell Fragments e 3, 4 o 5 Draconic Essence con uguale probabilit\xe0, pi\xf9 una probabilit\xe0 indipendente del 10% di ottenere 1 Weaveheart. Ogni uovo restituito conta una volta. Materiali e reliquie create non sono scambiabili.","Cada ovo normal d\xe1 5 Shell Fragments. B\xf3nus independentes: 25% para 1 Draconic Essence e 2% para 1 Weaveheart. Ap\xf3s 39 devolu\xe7\xf5es sem Weaveheart, o pr\xf3ximo \xe9 garantido. Os ovos Sinister d\xe3o sempre 25 Shell Fragments e 3, 4 ou 5 Draconic Essence com probabilidades iguais, mais uma probabilidade independente de 10% de obter 1 Weaveheart. Cada ovo devolvido conta uma vez. Materiais e rel\xedquias criadas n\xe3o podem ser trocados.","\u901a\u5e38\u306e\u5375\u304b\u3089Shell Fragments\u30925\u500b\u7372\u5f97\u3057\u307e\u3059\u3002\u72ec\u7acb\u3057\u305f\u30dc\u30fc\u30ca\u30b9\u3068\u3057\u306625%\u3067Draconic Essence\u30921\u500b\u30012%\u3067Weaveheart\u30921\u500b\u7372\u5f97\u3057\u307e\u3059\u300239\u56de\u9023\u7d9a\u3067Weaveheart\u304c\u51fa\u306a\u3051\u308c\u3070\u6b21\u306f\u78ba\u5b9a\u3067\u3059\u3002Sinister\u306e\u5375\u304b\u3089\u306f\u5fc5\u305aShell Fragments\u309225\u500b\u3068\u3001\u7b49\u78ba\u7387\u3067Draconic Essence\u30923\u500b\u30014\u500b\u3001\u307e\u305f\u306f5\u500b\u7372\u5f97\u3057\u3001\u3055\u3089\u306b\u72ec\u7acb\u3057\u305f10%\u306e\u78ba\u7387\u3067Weaveheart\u30921\u500b\u7372\u5f97\u3057\u307e\u3059\u3002\u8fd4\u3057\u305f\u53751\u500b\u306b\u3064\u304d\u30ab\u30a6\u30f3\u30bf\u30fc\u304c1\u56de\u9032\u307f\u307e\u3059\u3002\u7d20\u6750\u3068\u4f5c\u6210\u3057\u305f\u30ec\u30ea\u30c3\u30af\u306f\u4ea4\u63db\u3067\u304d\u307e\u305b\u3093\u3002"],t.s)
A.DH=s(["R\xfcckgaben ohne Weaveheart","Devoluciones sin Weaveheart","Retours sans Weaveheart","Restituzioni senza Weaveheart","Devolu\xe7\xf5es sem Weaveheart","Weaveheart\u306a\u3057\u306e\u8fd4\u5374\u56de\u6570"],t.s)
A.qh=s(["Zur\xfcckgeben","Devolver","Rendre","Restituisci","Devolver","\u8fd4\u3059"],t.s)
A.KX=s(["Herstellen","Fabricar","Fabriquer","Crea","Criar","\u4f5c\u6210"],t.s)
A.HB=s(["Ausstehende Aktion","Acci\xf3n pendiente","Action en attente","Azione in sospeso","A\xe7\xe3o pendente","\u4fdd\u7559\u4e2d\u306e\u64cd\u4f5c"],t.s)
A.pq=s(["Erneut versuchen","Reintentar","R\xe9essayer","Riprova","Tentar novamente","\u518d\u8a66\u884c"],t.s)
A.v1=s(["Dieses Ei verl\xe4sst dein Inventar endg\xfcltig. Halte die Schaltfl\xe4che gedr\xfcckt, um es zur Weave zur\xfcckzugeben.","Este huevo desaparecer\xe1 de tu inventario para siempre. Mant\xe9n pulsado el bot\xf3n para devolverlo a la Weave.","Cet \u0153uf quittera d\xe9finitivement ton inventaire. Maintiens le bouton pour le rendre \xe0 la Weave.","Questo uovo lascer\xe0 definitivamente il tuo inventario. Tieni premuto il pulsante per restituirlo alla Weave.","Este ovo sai do teu invent\xe1rio definitivamente. Mant\xe9m o bot\xe3o premido para o devolver \xe0 Weave.","\u3053\u306e\u5375\u306f\u6240\u6301\u54c1\u304b\u3089\u6c38\u4e45\u306b\u306a\u304f\u306a\u308a\u307e\u3059\u3002\u30dc\u30bf\u30f3\u3092\u9577\u62bc\u3057\u3057\u3066Weave\u3078\u8fd4\u3057\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.AF=s(["Markiert","Etiquetados","Marqu\xe9s","Contrassegnate","Marcados","\u30bf\u30b0\u4ed8\u304d"],t.s)
A.AG=s(["Unmarkiert","Sin etiqueta","Non marqu\xe9s","Non contrassegnate","Sem marca","\u30bf\u30b0\u306a\u3057"],t.s)
A.uH=s(["Ei im Nest","Huevo en el nido","\u0152uf dans le nid","Uovo nel nido","Ovo no ninho","\u5de3\u306e\u4e2d\u306e\u5375"],t.s)
A.I7=s(["Enth\xfclle die moralische Gesinnung eines Eis.","Revela la alineaci\xf3n moral de un huevo.","R\xe9v\xe8le l\u2019alignement moral d\u2019un \u0153uf.","Rivela l\u2019allineamento morale di un uovo.","Revela o alinhamento moral de um ovo.","\u5375\u306e\u9053\u5fb3\u7684\u306a\u5c5e\u6027\u3092\u660e\u3089\u304b\u306b\u3057\u307e\u3059\u3002"],t.s)
A.ru=s(["Enth\xfclle die Ordnungsgesinnung eines Eis.","Revela la alineaci\xf3n de orden de un huevo.","R\xe9v\xe8le l\u2019alignement d\u2019ordre d\u2019un \u0153uf.","Rivela l\u2019allineamento d\u2019ordine di un uovo.","Revela o alinhamento de ordem de um ovo.","\u5375\u306e\u79e9\u5e8f\u306b\u95a2\u3059\u308b\u5c5e\u6027\u3092\u660e\u3089\u304b\u306b\u3057\u307e\u3059\u3002"],t.s)
A.xR=s(["Enth\xfclle die Seltenheit eines Eis. Auch in bisherigen Drops erh\xe4ltlich.","Revela la rareza de un huevo. Tambi\xe9n aparece en los drops existentes.","R\xe9v\xe8le la raret\xe9 d\u2019un \u0153uf. \xc9galement disponible dans les r\xe9compenses existantes.","Rivela la rarit\xe0 di un uovo. Disponibile anche nei drop esistenti.","Revela a raridade de um ovo. Tamb\xe9m dispon\xedvel nos drops existentes.","\u5375\u306e\u30ec\u30a2\u5ea6\u3092\u660e\u3089\u304b\u306b\u3057\u307e\u3059\u3002\u5f93\u6765\u306e\u30c9\u30ed\u30c3\u30d7\u304b\u3089\u3082\u5165\u624b\u3067\u304d\u307e\u3059\u3002"],t.s)
A.x8=s(["Enth\xfclle Drachenfamilie und Seltenheit eines Eis. Nur am Altar erh\xe4ltlich.","Revela la familia y rareza del drag\xf3n de un huevo. Exclusiva del altar.","R\xe9v\xe8le la famille du dragon et la raret\xe9 d\u2019un \u0153uf. Exclusivit\xe9 de l\u2019autel.","Rivela la famiglia del drago e la rarit\xe0 di un uovo. Esclusiva dell\u2019altare.","Revela a fam\xedlia do drag\xe3o e a raridade de um ovo. Exclusiva do altar.","\u5375\u306e\u30c9\u30e9\u30b4\u30f3\u306e\u7a2e\u65cf\u3068\u30ec\u30a2\u5ea6\u3092\u660e\u3089\u304b\u306b\u3057\u307e\u3059\u3002\u796d\u58c7\u9650\u5b9a\u3067\u3059\u3002"],t.s)
A.GC=s(["Benenne einen Drachen um. Wird verbraucht. Nur am Altar erh\xe4ltlich.","Cambia el nombre de un drag\xf3n. Se consume al usarla. Exclusiva del altar.","Renomme un dragon. Consomm\xe9e \xe0 l\u2019utilisation. Exclusivit\xe9 de l\u2019autel.","Rinomina un drago. Si consuma con l\u2019uso. Esclusiva dell\u2019altare.","Muda o nome de um drag\xe3o. Consumida ao usar. Exclusiva do altar.","\u30c9\u30e9\u30b4\u30f31\u4f53\u306e\u540d\u524d\u3092\u5909\u66f4\u3057\u307e\u3059\u3002\u4f7f\u3046\u3068\u6d88\u8cbb\u3055\u308c\u307e\u3059\u3002\u796d\u58c7\u9650\u5b9a\u3067\u3059\u3002"],t.s)
A.Gt=s(["Im Besitz","En posesi\xf3n","En possession","Possedute","Na posse","\u6240\u6301\u6570"],t.s)
A.lW=s(["Ein Relikt f\xfcr dieses Ei verwenden?","\xbfUsar una reliquia en este huevo?","Utiliser une relique sur cet \u0153uf ?","Usare una reliquia su questo uovo?","Usar uma rel\xedquia neste ovo?","\u3053\u306e\u5375\u306b\u30ec\u30ea\u30c3\u30af\u30921\u500b\u4f7f\u3044\u307e\u3059\u304b\uff1f"],t.s)
A.qd=s(["Bei erfolgreicher Namens\xe4nderung wird eine Quill verbraucht.","Consume una Quill al cambiar el nombre.","Consomme une Quill lorsque le nom est chang\xe9.","Consuma una Quill quando il nome viene cambiato.","Consome uma Quill quando o nome \xe9 alterado.","\u540d\u524d\u3092\u5909\u66f4\u3059\u308b\u3068Quill\u30921\u500b\u6d88\u8cbb\u3057\u307e\u3059\u3002"],t.s)
A.ld=s(["Umbenennen","Renombrar","Renommer","Rinomina","Mudar nome","\u540d\u524d\u5909\u66f4"],t.s)
A.Gf=s(["Gedr\xfcckt halten, um zur Weave zur\xfcckzugeben","Mant\xe9n pulsado para devolver a la Weave","Maintiens pour rendre \xe0 la Weave","Tieni premuto per restituire alla Weave","Mant\xe9m premido para devolver \xe0 Weave","\u9577\u62bc\u3057\u3067Weave\u3078\u8fd4\u3059"],t.s)
A.tG=s(["Zur Weave zur\xfcckgegeben","Devuelto a la Weave","Rendu \xe0 la Weave","Restituito alla Weave","Devolvido \xe0 Weave","Weave\u3078\u8fd4\u3057\u307e\u3057\u305f"],t.s)
A.K6=s(["Animation \xfcberspringen","Saltar animaci\xf3n","Passer l\u2019animation","Salta animazione","Saltar anima\xe7\xe3o","\u30a2\u30cb\u30e1\u30fc\u30b7\u30e7\u30f3\u3092\u30b9\u30ad\u30c3\u30d7"],t.s)
A.vg=s(["Shell Fragments spenden","Donar Shell Fragments","Donner des Shell Fragments","Dona Shell Fragments","Doar Shell Fragments","Shell Fragments\u3092\u5bc4\u4ed8"],t.s)
A.xy=s(["Eine freiwillige Spende f\xfcr den dekorativen Beacon deines Conclaves. Spenden k\xf6nnen nicht zur\xfcckgenommen werden.","Una aportaci\xf3n voluntaria al Beacon decorativo de tu Conclave. Las donaciones no se pueden recuperar.","Un don volontaire pour le Beacon d\xe9coratif de ton Conclave. Les dons ne peuvent pas \xeatre r\xe9cup\xe9r\xe9s.","Un dono volontario al Beacon decorativo del tuo Conclave. Le donazioni non si possono recuperare.","Uma oferta volunt\xe1ria para o Beacon decorativo do teu Conclave. As doa\xe7\xf5es n\xe3o podem ser recuperadas.","Conclave\u306e\u88c5\u98fe\u7528Beacon\u3078\u306e\u4efb\u610f\u306e\u5bc4\u4ed8\u3067\u3059\u3002\u5bc4\u4ed8\u306f\u53d6\u308a\u6d88\u305b\u307e\u305b\u3093\u3002"],t.s)
A.ut=s(["Spenden","Donar","Donner","Dona","Doar","\u5bc4\u4ed8"],t.s)
A.od=s(["Zum Neuverbinden tippen","Toca para reconectar","Touche pour te reconnecter","Tocca per riconnetterti","Toca para voltar a ligar","\u30bf\u30c3\u30d7\u3057\u3066\u518d\u63a5\u7d9a"],t.s)
A.vo=s(["Stufe","Etapa","Phase","Fase","Fase","\u6bb5\u968e"],t.s)
A.yh=s(["Die Weave erstrahlt in eurer Aerie!","\xa1La Weave brilla en vuestra Aerie!","La Weave brille dans votre Aerie !","La Weave splende nella vostra Aerie!","A Weave brilha na vossa Aerie!","Aerie\u3067Weave\u304c\u8f1d\u3044\u3066\u3044\u307e\u3059\uff01"],t.s)
A.oc=s(["Baut eine gemeinsame Dekoration mit Shell Fragments. Meilensteine: 500, 2000 und 5000.","Construid una decoraci\xf3n compartida con Shell Fragments. Hitos: 500, 2000 y 5000.","Cr\xe9ez une d\xe9coration commune avec des Shell Fragments. \xc9tapes : 500, 2000 et 5000.","Costruite una decorazione condivisa con Shell Fragments. Traguardi: 500, 2000 e 5000.","Construam uma decora\xe7\xe3o partilhada com Shell Fragments. Marcos: 500, 2000 e 5000.","Shell Fragments\u3067\u5171\u6709\u306e\u88c5\u98fe\u3092\u4f5c\u308a\u307e\u3057\u3087\u3046\u3002\u76ee\u6a19\u306f500\u30012000\u30015000\u500b\u3067\u3059\u3002"],t.s)
A.KW=s(["Fragmente spenden","Donar fragmentos","Donner des fragments","Dona frammenti","Doar fragmentos","\u6b20\u7247\u3092\u5bc4\u4ed8"],t.s)
A.Ef=s(["Spiel vorbei","Fin de la partida","Partie termin\xe9e","Partita terminata","Fim do jogo","\u30b2\u30fc\u30e0\u30aa\u30fc\u30d0\u30fc"],t.s)
A.Mc=new B.u(A.O2,[A.oN,A.kn,A.Hz,A.lZ,A.D_,A.Id,A.z0,A.yp,A.Gi,A.FX,A.qq,A.H9,A.DO,A.E7,A.wP,A.tl,A.vz,A.jQ,A.rq,A.KE,A.JV,A.pT,A.yf,A.Gq,A.Bt,A.Di,A.rs,A.mz,A.EY,A.pQ,A.jM,A.D6,A.kg,A.GK,A.FE,A.lt,A.Ke,A.pm,A.wC,A.rQ,A.AP,A.l2,A.IQ,A.BM,A.rl,A.vi,A.yG,A.uS,A.DH,A.qh,A.KX,A.HB,A.pq,A.v1,A.AF,A.AG,A.uH,A.I7,A.ru,A.xR,A.x8,A.GC,A.Gt,A.lW,A.qd,A.ld,A.Gf,A.tG,A.K6,A.vg,A.xy,A.ut,A.od,A.vo,A.yh,A.oc,A.KW,A.Ef],t.M)
A.du=new B.aG(A.F,1)
A.oO=s([A.du],t.D)
A.dy=new B.aG(A.F,0.2)
A.dx=new B.aG(A.M,0.4)
A.ds=new B.aG(A.t,0.35)
A.dC=new B.aG(A.G,0.045)
A.dB=new B.aG(A.H,0.005)
A.zP=s([A.dy,A.dx,A.ds,A.dC,A.dB],t.D)
A.dr=new B.aG(A.t,0.75)
A.dz=new B.aG(A.G,0.23)
A.dt=new B.aG(A.H,0.02)
A.KA=s([A.dr,A.dz,A.dt],t.D)
A.dA=new B.aG(A.t,0.7)
A.dw=new B.aG(A.G,0.25)
A.dD=new B.aG(A.H,0.05)
A.l4=s([A.dA,A.dw,A.dD],t.D)
A.dv=new B.aG(A.t,1)
A.oP=s([A.dv],t.D)
A.Md=new B.b7([A.q,A.oO,A.o,A.zP,A.z,A.KA,A.W,A.l4,A.A,A.oP],B.W("b7<bp,G<aG>>"))
A.NV={Sleepy:0,Restless:1,Shy:2,"Show-Off":3,"Neat Freak":4,Messy:5,"Night Owl":6,"Early Bird":7}
A.Me=new B.u(A.NV,["Restless","Sleepy","Show-Off","Shy","Messy","Neat Freak","Early Bird","Night Owl"],t.p1)
A.bn=new B.u(A.bq,[],t.cq)
A.ay=new B.u(A.bq,[],B.W("u<d,@>"))
A.O1={golden_wings_egg_v1:0,witchlight_egg_v1:1,starlit_evergreen_egg_v1:2,turning_year_egg_v1:3,rosebound_egg_v1:4,truecolor_egg_v1:5}
A.iw=new B.a_(756e8)
A.cL=new B.ca("golden_wings_egg_v1","cluckatrice",A.iw,null,!1)
A.is=new B.a_(47593e6)
A.Rx=new B.ca("witchlight_egg_v1","gloamgourd",A.is,null,!1)
A.iy=new B.a_(9e10)
A.Rw=new B.ca("starlit_evergreen_egg_v1","hollyfrost",A.iy,A.C,!0)
A.Rz=new B.ca("turning_year_egg_v1","dawnchime",A.R,A.U,!0)
A.it=new B.a_(504e8)
A.Ry=new B.ca("rosebound_egg_v1","rosevow",A.it,A.C,!0)
A.iv=new B.a_(648e8)
A.Rv=new B.ca("truecolor_egg_v1","spectrumplume",A.iv,A.C,!0)
A.aS=new B.u(A.O1,[A.cL,A.Rx,A.Rw,A.Rz,A.Ry,A.Rv],B.W("u<d,ca>"))
A.Oz={"Sort eggs":0,"Descending; tap to reverse":1,"Ascending; tap to reverse":2,"View all Expertise":3,Expertise:4,"Previous step":5,Skip:6,"Protect the eggs you love":7,"Open the Conclave tab beside Friends. Join or found a group of up to 20 Keepers, chat and tend the Aerie. Donate Shell Fragments to build your shared cosmetic Weave Beacon. The red badge counts unread chat from the last 24 hours.":8,"Choose an Adventure and a dragon. Matching Expertise shortens the journey; tap the i beside a dragon\u2019s score to compare Might, Arcana and Spirit. Active Adventures show the shortest remaining journey first. Aborting a solo journey gives no rewards.":9,"Join friends in a Group Adventure: the party starts when every place is filled and the combined requirements are met. Event Adventures remain finishable if started in time. Events marked TEST are previews: their rewards do not enter your permanent inventory.":10,"Tag an egg to protect it from Return to the Weave; tap its tag again to remove protection. Filter Tagged or Untagged and sort by Received or Hatch time. Choosing an Altar egg opens its details first, so you can review what you know before selecting it.":11,"Open Altar in Inventory. Returning an egg is permanent and yields crafting materials: select an egg, review its details, then hold Return. Special eggs, tagged eggs and trade-reserved eggs are protected. Sinister eggs require a second confirmation. Craft Relics to learn about eggs, or a Nameweaver\u2019s Quill to rename one dragon.":12,"No keeper badge":13,"Choose keeper badge":14,"Every pupil gets up to three official attempts per lesson. Once every lesson is passed at least once, a pupil with 15 stars may graduate early.":15,"15 stars: Graduate \xb7 21: Honors \xb7 27: High Honors \xb7 30: Valedictorian. Early graduation requires one attempt in every lesson. Dropout is decided only after all 30 attempts.":16,"Graduate now":17,"The current report becomes final. Unused lesson attempts cannot be played afterwards.":18,"Keep training":19,"No portrait frame":20,"Choose portrait frame":21,"Founding Supporter Frame":22,Packs:23,"Special cosmetic collections. More packs can join this shop later.":24,"Keeper Journal":25,"Show this badge on your Keeper identity.":26,"Frame your portrait with supporter gold.":27,"Founding Supporter":28,"Seven-day Trial constellation":29,"Your constellation is complete!":30,"Complete a Trial every day. Miss a day and it resets to zero.":31,"Reward: 95% Dragon Chest \xb7 5% Mythical Chest":32,"Today's Trial is safely waiting as day 1 of your next streak.":33,"Requirements to start":34,"The group can only depart when every requirement below is met.":35,"Expected rewards":36,"Dragon Academy":37,"Practice makes legends":38,"Ten short lessons, no attempts or rewards\u2014just your personal bests.":39,TIME:40,"A practice round lasts 20 seconds and gives no rewards.":41,"Start lesson":42,"Lesson complete":43,"Personal best":44,"Practice again":45,"Remember\u2026":46,"Which sigil?":47,"Next scale":48,Stop:49,"Change room order":50,"Arrange your Tower":51,"Drag the rooms into your preferred top-to-bottom order.":52,"Fixed at the top":53,"Drag room":54,"10 lessons \xb7 personal records":55,"Unlocks when your Tower has 5 floors":56,"Your story, kept in ink and starlight":57,"Adventures, discoveries and milestones from your life as a Keeper.":58,days:59,moments:60,"These pages are still waiting for a story.":61,Adventures:62,Discoveries:63,Milestones:64,Today:65,Yesterday:66,Supporter:67,"Founding Supporter Pack":68,"A permanent collection of cosmetics made to thank the Keepers who help DragonHaven grow.":69,OWNED:70,"Everything included":71,"Exclusive supporter portrait":72,"Separate from Portrait Chests and never changes their odds.":73,"\u201cFounding Supporter\u201d title":74,"Separate from Title Chests and never changes their odds.":75,"Supporter badge":76,"A new identity cosmetic that clearly marks your support.":77,"Supporter portrait frame":78,"An equipable profile frame created exclusively for this pack.":79,"Complete supporter furniture set":80,"The pack is ready for \u20ac2.99. Purchasing becomes available after the Google Play product and secure server verification are connected.":81,"Pack owned":82,"\u20ac2.99 \xb7 Google Play setup required":83,"Cosmetic only: no gems, coins, power or gameplay advantage.":84,"Not enough available dragons for this lesson.":85,"Choose your pupils, earn each star once and build a personal report card for every dragon.":86,"30 stars per dragon":87,"KEEPER BEST":88,"Optional ascended mentor":89,"A mentor absorbs one mistake. The pupils receive all stars and rewards.":90,"No mentor":91,"Enter classroom":92,"Keeper Best":93,"Diploma earned!":94,Practice:95,Balance:96,"Follow the glowing path in order":97,Mentor:98," \xb7 TEAMWORK":99,"lowest expertise":100,"10 lessons \xb7 dragons, stars and records":101,"Dragon Academy Diploma":102,"Dragon Academy report card":103,stars:104,"Founding Supporter Pack unlocked. Thank you for supporting DragonHaven!":105,"You already own the Founding Supporter Pack.":106,"Academy standings":107,"Best results, fairly normalized across all lessons":108,"Complete a first lesson to enter the standings.":109,"Gold is 100 Academy points per lesson; exceptional scores can earn up to 20 bonus points.":110,attempts:111,Student:112,"Dragon Academy Dropout":113,Graduate:114,"Honors Graduate":115,"High Honors":116,Valedictorian:117,"Best kept":118,"Use next attempt":119,"All 3 attempts used":120,"Final report complete. Diploma earned!":121,"Final report complete. No diploma this time, but the story is worth recording.":122,"Not enough eligible dragons. Each pupil gets three attempts per lesson.":123,"Every pupil gets three official attempts per lesson. Their best results decide the final diploma and ranking.":124,"3 attempts per lesson":125,"15 stars: Graduate \xb7 21: Honors \xb7 27: High Honors \xb7 30: Valedictorian. Below 15 becomes Dropout.":126,"Every selected pupil has used all three attempts for this lesson.":127}
A.tc=s(["Eier sortieren","Ordenar huevos","Trier les \u0153ufs","Ordina uova","Ordenar ovos","\u5375\u3092\u4e26\u3079\u66ff\u3048\u308b"],t.s)
A.EP=s(["Absteigend; antippen zum Umkehren","Descendente; toca para invertir","D\xe9croissant ; toucher pour inverser","Decrescente; tocca per invertire","Decrescente; toca para inverter","\u964d\u9806\u30fb\u30bf\u30c3\u30d7\u3067\u9006\u9806\u306b"],t.s)
A.Bk=s(["Aufsteigend; antippen zum Umkehren","Ascendente; toca para invertir","Croissant ; toucher pour inverser","Crescente; tocca per invertire","Crescente; toca para inverter","\u6607\u9806\u30fb\u30bf\u30c3\u30d7\u3067\u9006\u9806\u306b"],t.s)
A.Ij=s(["Alle Expertisen ansehen","Ver todas las especialidades","Voir toutes les expertises","Mostra tutte le competenze","Ver todas as especialidades","\u3059\u3079\u3066\u306e\u5c02\u9580\u80fd\u529b\u3092\u898b\u308b"],t.s)
A.Kh=s(["Expertise","Especialidad","Expertise","Competenza","Especialidade","\u5c02\u9580\u80fd\u529b"],t.s)
A.ug=s(["Vorheriger Schritt","Paso anterior","\xc9tape pr\xe9c\xe9dente","Passaggio precedente","Passo anterior","\u524d\u306e\u30b9\u30c6\u30c3\u30d7"],t.s)
A.k7=s(["\xdcberspringen","Omitir","Passer","Salta","Saltar","\u30b9\u30ad\u30c3\u30d7"],t.s)
A.KG=s(["Sch\xfctze deine Lieblingseier","Protege tus huevos favoritos","Prot\xe9gez vos \u0153ufs pr\xe9f\xe9r\xe9s","Proteggi le tue uova preferite","Protege os teus ovos favoritos","\u304a\u6c17\u306b\u5165\u308a\u306e\u5375\u3092\u5b88\u308d\u3046"],t.s)
A.us=s(["\xd6ffne den Tab Conclave neben Friends. Gr\xfcnde eine Gruppe mit bis zu 20 H\xfctern oder tritt einer bei, chatte und pflege die Aerie. Spende Shell Fragments f\xfcr euer gemeinsames dekoratives Weave Beacon. Die rote Anzeige z\xe4hlt ungelesene Chatnachrichten der letzten 24 Stunden.","Abre la pesta\xf1a Conclave junto a Friends. Crea un grupo de hasta 20 Guardianes o \xfanete a uno, chatea y cuida el Aerie. Dona Shell Fragments para construir vuestro Weave Beacon decorativo. La insignia roja cuenta los mensajes sin leer de las \xfaltimas 24 horas.","Ouvrez Conclave \xe0 c\xf4t\xe9 de Friends. Cr\xe9ez ou rejoignez un groupe de 20 Gardiens maximum, discutez et entretenez l\u2019Aerie. Donnez des Shell Fragments pour construire votre Weave Beacon d\xe9coratif commun. Le badge rouge compte les messages non lus des derni\xe8res 24 heures.","Apri Conclave accanto a Friends. Crea o unisciti a un gruppo di massimo 20 Custodi, chatta e cura l\u2019Aerie. Dona Shell Fragments per costruire il Weave Beacon decorativo condiviso. Il badge rosso conta i messaggi non letti delle ultime 24 ore.","Abre Conclave ao lado de Friends. Cria ou junta-te a um grupo de at\xe9 20 Guardi\xf5es, conversa e cuida do Aerie. Doa Shell Fragments para construir o Weave Beacon decorativo do grupo. O indicador vermelho conta as mensagens n\xe3o lidas das \xfaltimas 24 horas.","Friends\u306e\u96a3\u306b\u3042\u308bConclave\u30bf\u30d6\u3092\u958b\u304d\u307e\u3059\u3002\u6700\u592720\u4eba\u306e\u30ad\u30fc\u30d1\u30fc\u306e\u30b0\u30eb\u30fc\u30d7\u306b\u53c2\u52a0\u3059\u308b\u304b\u3001\u81ea\u5206\u3067\u4f5c\u6210\u3057\u3066\u3001\u30c1\u30e3\u30c3\u30c8\u3084Aerie\u306e\u304a\u4e16\u8a71\u3092\u697d\u3057\u307f\u307e\u3057\u3087\u3046\u3002Shell Fragments\u3092\u5bc4\u4ed8\u3059\u308b\u3068\u3001\u5171\u6709\u306e\u88c5\u98feWeave Beacon\u3092\u4f5c\u308c\u307e\u3059\u3002\u8d64\u3044\u30d0\u30c3\u30b8\u306f\u904e\u53bb24\u6642\u9593\u306e\u672a\u8aad\u30e1\u30c3\u30bb\u30fc\u30b8\u6570\u3067\u3059\u3002"],t.s)
A.rt=s(["W\xe4hle ein Abenteuer und einen Drachen. Passende Expertise verk\xfcrzt die Reise. Tippe auf das i neben dem Wert, um Might, Arcana und Spirit zu vergleichen. Aktive Abenteuer stehen nach k\xfcrzester Restzeit oben. Ein abgebrochenes Soloabenteuer bringt keine Belohnung.","Elige una aventura y un drag\xf3n. La especialidad adecuada acorta el viaje; toca la i junto a la puntuaci\xf3n para comparar Might, Arcana y Spirit. Las aventuras activas muestran primero la de menor tiempo restante. Abandonar un viaje individual no da recompensas.","Choisissez une aventure et un dragon. L\u2019expertise correspondante raccourcit le voyage ; touchez le i pr\xe8s du score pour comparer Might, Arcana et Spirit. Les aventures actives au temps restant le plus court apparaissent en premier. Abandonner une aventure solo ne donne aucune r\xe9compense.","Scegli un\u2019avventura e un drago. La competenza adatta accorcia il viaggio; tocca la i accanto al punteggio per confrontare Might, Arcana e Spirit. Le avventure attive con meno tempo rimasto appaiono per prime. Interrompere un viaggio in solitaria non d\xe0 ricompense.","Escolhe uma aventura e um drag\xe3o. A especialidade adequada encurta a viagem; toca no i ao lado da pontua\xe7\xe3o para comparar Might, Arcana e Spirit. As aventuras ativas com menos tempo restante aparecem primeiro. Abandonar uma viagem a solo n\xe3o d\xe1 recompensas.","\u5192\u967a\u3068\u30c9\u30e9\u30b4\u30f3\u3092\u9078\u3073\u307e\u3059\u3002\u5bfe\u5fdc\u3059\u308b\u5c02\u9580\u80fd\u529b\u304c\u9ad8\u3044\u307b\u3069\u65c5\u304c\u77ed\u304f\u306a\u308a\u307e\u3059\u3002\u6570\u5024\u306e\u96a3\u306ei\u3092\u30bf\u30c3\u30d7\u3059\u308b\u3068Might\u3001Arcana\u3001Spirit\u3092\u6bd4\u8f03\u3067\u304d\u307e\u3059\u3002\u9032\u884c\u4e2d\u306e\u5192\u967a\u306f\u6b8b\u308a\u6642\u9593\u304c\u77ed\u3044\u9806\u306b\u8868\u793a\u3055\u308c\u307e\u3059\u3002\u30bd\u30ed\u5192\u967a\u3092\u4e2d\u6b62\u3059\u308b\u3068\u5831\u916c\u306f\u5f97\u3089\u308c\u307e\u305b\u3093\u3002"],t.s)
A.ys=s(["Gehe mit Freunden auf ein Gruppenabenteuer: Es startet, sobald alle Pl\xe4tze belegt und die gemeinsamen Anforderungen erf\xfcllt sind. Rechtzeitig gestartete Eventabenteuer k\xf6nnen sp\xe4ter beendet werden. Events mit TEST sind Vorschauen: Ihre Belohnungen werden nicht dauerhaft gespeichert.","\xdanete a tus amigos en una aventura de grupo: comienza cuando se llenan todas las plazas y se cumplen los requisitos conjuntos. Las aventuras de evento iniciadas a tiempo se pueden terminar despu\xe9s. Los eventos TEST son pruebas: sus recompensas no pasan al inventario permanente.","Partez en aventure de groupe avec vos amis : le d\xe9part a lieu lorsque toutes les places sont remplies et les conditions communes remplies. Les aventures d\u2019\xe9v\xe9nement commenc\xe9es \xe0 temps restent terminables. Les \xe9v\xe9nements TEST sont des aper\xe7us : leurs r\xe9compenses ne rejoignent pas votre inventaire permanent.","Partecipa a un\u2019avventura di gruppo con gli amici: si parte quando tutti i posti sono occupati e i requisiti complessivi sono soddisfatti. Le avventure evento iniziate in tempo restano completabili. Gli eventi TEST sono anteprime: le ricompense non entrano nell\u2019inventario permanente.","Parte numa aventura de grupo com amigos: come\xe7a quando todos os lugares est\xe3o ocupados e os requisitos conjuntos s\xe3o cumpridos. As aventuras de evento iniciadas a tempo continuam dispon\xedveis para concluir. Os eventos TEST s\xe3o demonstra\xe7\xf5es: as recompensas n\xe3o entram no invent\xe1rio permanente.","\u53cb\u9054\u3068\u30b0\u30eb\u30fc\u30d7\u5192\u967a\u306b\u53c2\u52a0\u3057\u307e\u3057\u3087\u3046\u3002\u5168\u54e1\u304c\u63c3\u3044\u3001\u5408\u8a08\u306e\u6761\u4ef6\u3092\u6e80\u305f\u3059\u3068\u51fa\u767a\u3057\u307e\u3059\u3002\u671f\u9593\u5185\u306b\u958b\u59cb\u3057\u305f\u30a4\u30d9\u30f3\u30c8\u5192\u967a\u306f\u5f8c\u304b\u3089\u3067\u3082\u5b8c\u4e86\u3067\u304d\u307e\u3059\u3002TEST\u3068\u8868\u793a\u3055\u308c\u305f\u30a4\u30d9\u30f3\u30c8\u306f\u30d7\u30ec\u30d3\u30e5\u30fc\u3067\u3059\u3002\u5831\u916c\u306f\u6c38\u4e45\u30a4\u30f3\u30d9\u30f3\u30c8\u30ea\u306b\u306f\u8ffd\u52a0\u3055\u308c\u307e\u305b\u3093\u3002"],t.s)
A.Jh=s(["Markiere ein Ei, um es vor Return to the Weave zu sch\xfctzen. Erneutes Antippen entfernt den Schutz. Filtere markierte oder unmarkierte Eier und sortiere nach Erhalt oder Brutzeit. Am Altar \xf6ffnen sich zuerst die Details, damit du bekannte Informationen vor der Auswahl pr\xfcfen kannst.","Etiqueta un huevo para protegerlo de Return to the Weave; toca la etiqueta otra vez para quitar la protecci\xf3n. Filtra los huevos etiquetados o sin etiquetar y ord\xe9nalos por recepci\xf3n o incubaci\xf3n. En el Altar se abren primero los detalles para revisar la informaci\xf3n antes de seleccionar.","Marquez un \u0153uf pour le prot\xe9ger de Return to the Weave ; touchez \xe0 nouveau sa marque pour retirer la protection. Filtrez les \u0153ufs marqu\xe9s ou non et triez par r\xe9ception ou incubation. \xc0 l\u2019Altar, les d\xe9tails s\u2019ouvrent d\u2019abord pour v\xe9rifier les informations connues avant de choisir.","Contrassegna un uovo per proteggerlo da Return to the Weave; tocca di nuovo il contrassegno per rimuovere la protezione. Filtra le uova contrassegnate o no e ordinale per ricezione o incubazione. Nell\u2019Altar si aprono prima i dettagli, per controllare le informazioni note prima di scegliere.","Marca um ovo para o proteger de Return to the Weave; toca novamente na marca para retirar a prote\xe7\xe3o. Filtra os ovos marcados ou n\xe3o marcados e ordena por rece\xe7\xe3o ou incuba\xe7\xe3o. No Altar, os detalhes abrem primeiro para reveres a informa\xe7\xe3o antes de escolher.","\u5375\u306b\u30bf\u30b0\u3092\u4ed8\u3051\u308b\u3068Return to the Weave\u304b\u3089\u4fdd\u8b77\u3067\u304d\u307e\u3059\u3002\u3082\u3046\u4e00\u5ea6\u30bf\u30b0\u3092\u30bf\u30c3\u30d7\u3059\u308b\u3068\u4fdd\u8b77\u3092\u89e3\u9664\u3057\u307e\u3059\u3002\u30bf\u30b0\u306e\u6709\u7121\u3067\u7d5e\u308a\u8fbc\u307f\u3001\u5165\u624b\u65e5\u3084\u5b75\u5316\u6642\u9593\u3067\u4e26\u3079\u66ff\u3048\u3089\u308c\u307e\u3059\u3002Altar\u3067\u306f\u9078\u629e\u524d\u306b\u8a73\u7d30\u304c\u958b\u304f\u306e\u3067\u3001\u5224\u660e\u3057\u3066\u3044\u308b\u60c5\u5831\u3092\u78ba\u8a8d\u3067\u304d\u307e\u3059\u3002"],t.s)
A.C9=s(["\xd6ffne Altar im Inventar. Ein Ei zur\xfcckzugeben ist endg\xfcltig und liefert Materialien: W\xe4hle ein Ei, pr\xfcfe seine Details und halte Return gedr\xfcckt. Special-Eier, markierte und zum Tausch reservierte Eier sind gesch\xfctzt. Sinister-Eier brauchen eine zweite Best\xe4tigung. Stelle Relikte f\xfcr Ei-Informationen her oder einen Nameweaver\u2019s Quill, um einen Drachen umzubenennen.","Abre Altar en el inventario. Devolver un huevo es permanente y da materiales: elige uno, revisa sus detalles y mant\xe9n pulsado Return. Los huevos Special, etiquetados o reservados para intercambios est\xe1n protegidos. Los Sinister requieren otra confirmaci\xf3n. Fabrica reliquias para conocer los huevos o una Nameweaver\u2019s Quill para renombrar un drag\xf3n.","Ouvrez Altar dans l\u2019inventaire. Rendre un \u0153uf est d\xe9finitif et fournit des mat\xe9riaux : choisissez-le, v\xe9rifiez ses d\xe9tails et maintenez Return. Les \u0153ufs Special, marqu\xe9s ou r\xe9serv\xe9s \xe0 un \xe9change sont prot\xe9g\xe9s. Les \u0153ufs Sinister demandent une seconde confirmation. Fabriquez des reliques pour conna\xeetre les \u0153ufs, ou une Nameweaver\u2019s Quill pour renommer un dragon.","Apri Altar nell\u2019inventario. Restituire un uovo \xe8 definitivo e fornisce materiali: sceglilo, controlla i dettagli e tieni premuto Return. Le uova Special, contrassegnate o riservate agli scambi sono protette. Le Sinister richiedono una seconda conferma. Crea reliquie per conoscere le uova o una Nameweaver\u2019s Quill per rinominare un drago.","Abre Altar no invent\xe1rio. Devolver um ovo \xe9 permanente e d\xe1 materiais: escolhe-o, consulta os detalhes e mant\xe9m Return premido. Os ovos Special, marcados ou reservados para trocas est\xe3o protegidos. Os Sinister exigem uma segunda confirma\xe7\xe3o. Cria rel\xedquias para conhecer os ovos ou uma Nameweaver\u2019s Quill para mudar o nome de um drag\xe3o.","\u30a4\u30f3\u30d9\u30f3\u30c8\u30ea\u306eAltar\u3092\u958b\u304d\u307e\u3059\u3002\u5375\u3092\u8fd4\u3059\u3068\u5143\u306b\u306f\u623b\u305b\u307e\u305b\u3093\u304c\u3001\u4f5c\u6210\u7d20\u6750\u3092\u5f97\u3089\u308c\u307e\u3059\u3002\u5375\u3092\u9078\u3073\u3001\u8a73\u7d30\u3092\u78ba\u8a8d\u3057\u3066Return\u3092\u9577\u62bc\u3057\u3057\u307e\u3059\u3002Special\u306e\u5375\u3001\u30bf\u30b0\u4ed8\u304d\u306e\u5375\u3001\u4ea4\u63db\u4e88\u7d04\u4e2d\u306e\u5375\u306f\u4fdd\u8b77\u3055\u308c\u307e\u3059\u3002Sinister\u306e\u5375\u306f\u8ffd\u52a0\u78ba\u8a8d\u304c\u5fc5\u8981\u3067\u3059\u3002\u5375\u3092\u8abf\u3079\u308b\u907a\u7269\u3084\u3001\u30c9\u30e9\u30b4\u30f31\u4f53\u306e\u540d\u524d\u3092\u5909\u3048\u308bNameweaver\u2019s Quill\u3092\u4f5c\u308c\u307e\u3059\u3002"],t.s)
A.nX=s(["Kein Keeper-Abzeichen","Sin insignia de Guardi\xe1n","Aucun badge de Gardien","Nessun distintivo del Custode","Sem emblema de Guardi\xe3o","\u30ad\u30fc\u30d1\u30fc\u306e\u30d0\u30c3\u30b8\u306a\u3057"],t.s)
A.Be=s(["Keeper-Abzeichen w\xe4hlen","Elegir insignia de Guardi\xe1n","Choisir le badge de Gardien","Scegli il distintivo del Custode","Escolher emblema de Guardi\xe3o","\u30ad\u30fc\u30d1\u30fc\u306e\u30d0\u30c3\u30b8\u3092\u9078\u3076"],t.s)
A.wL=s(["Jeder Sch\xfcler hat pro Lektion bis zu drei offizielle Versuche. Sobald jede Lektion mindestens einmal absolviert wurde, kann ein Sch\xfcler mit 15 Sternen vorzeitig abschlie\xdfen.","Cada alumno tiene hasta tres intentos oficiales por lecci\xf3n. Cuando haya realizado cada lecci\xf3n al menos una vez, podr\xe1 graduarse antes con 15 estrellas.","Chaque \xe9l\xe8ve dispose de trois tentatives officielles maximum par le\xe7on. Apr\xe8s avoir suivi chaque le\xe7on au moins une fois, il peut obtenir son dipl\xf4me plus t\xf4t avec 15 \xe9toiles.","Ogni allievo ha fino a tre tentativi ufficiali per lezione. Dopo aver svolto ogni lezione almeno una volta, pu\xf2 diplomarsi in anticipo con 15 stelle.","Cada aluno tem at\xe9 tr\xeas tentativas oficiais por aula. Depois de fazer cada aula ao menos uma vez, pode se formar mais cedo com 15 estrelas.","\u5404\u30ec\u30c3\u30b9\u30f3\u306e\u516c\u5f0f\u6311\u6226\u306f\u6700\u59273\u56de\u3067\u3059\u3002\u5168\u30ec\u30c3\u30b9\u30f3\u306b1\u56de\u4ee5\u4e0a\u6311\u6226\u3057\u3001\u661f\u309215\u500b\u7372\u5f97\u3059\u308c\u3070\u65e9\u671f\u5352\u696d\u3067\u304d\u307e\u3059\u3002"],t.s)
A.Hh=s(["15 Sterne: Abschluss \xb7 21: mit Auszeichnung \xb7 27: mit h\xf6chster Auszeichnung \xb7 30: Jahrgangsbester. F\xfcr den vorzeitigen Abschluss ist ein Versuch in jeder Lektion n\xf6tig. Ein Abbruch wird erst nach allen 30 Versuchen festgestellt.","15 estrellas: Graduado \xb7 21: Honores \xb7 27: Altos honores \xb7 30: Mejor de la promoci\xf3n. La graduaci\xf3n anticipada exige un intento en cada lecci\xf3n. El abandono solo se decide tras los 30 intentos.","15 \xe9toiles : Dipl\xf4m\xe9 \xb7 21 : Mention \xb7 27 : Haute distinction \xb7 30 : Major de promotion. Le dipl\xf4me anticip\xe9 exige une tentative dans chaque le\xe7on. L\u2019abandon n\u2019est d\xe9cid\xe9 qu\u2019apr\xe8s les 30 tentatives.","15 stelle: Diplomato \xb7 21: Lode \xb7 27: Massimi onori \xb7 30: Migliore del corso. Il diploma anticipato richiede un tentativo in ogni lezione. Il ritiro viene deciso solo dopo tutti i 30 tentativi.","15 estrelas: Formado \xb7 21: Honras \xb7 27: Altas honras \xb7 30: Melhor da turma. A formatura antecipada exige uma tentativa em cada aula. A desist\xeancia s\xf3 \xe9 decidida ap\xf3s as 30 tentativas.","\u661f15\u500b\uff1a\u5352\u696d\u30fb21\u500b\uff1a\u512a\u7b49\u30fb27\u500b\uff1a\u6700\u512a\u7b49\u30fb30\u500b\uff1a\u9996\u5e2d\u3002\u65e9\u671f\u5352\u696d\u306b\u306f\u5168\u30ec\u30c3\u30b9\u30f3\u30671\u56de\u306e\u6311\u6226\u304c\u5fc5\u8981\u3067\u3059\u3002\u4e2d\u9000\u306f30\u56de\u3059\u3079\u3066\u306e\u6311\u6226\u5f8c\u306b\u306e\u307f\u6c7a\u307e\u308a\u307e\u3059\u3002"],t.s)
A.u_=s(["Jetzt abschlie\xdfen","Graduarse ahora","Obtenir le dipl\xf4me","Diplomati ora","Formar-se agora","\u4eca\u3059\u3050\u5352\u696d"],t.s)
A.ue=s(["Das aktuelle Zeugnis wird endg\xfcltig. Ungenutzte Lektionsversuche k\xf6nnen danach nicht mehr gespielt werden.","El informe actual ser\xe1 definitivo. Los intentos de lecci\xf3n no usados ya no podr\xe1n jugarse.","Le bulletin actuel devient d\xe9finitif. Les tentatives de le\xe7on inutilis\xe9es ne pourront plus \xeatre jou\xe9es.","La pagella attuale diventa definitiva. I tentativi di lezione inutilizzati non potranno pi\xf9 essere giocati.","O boletim atual se torna definitivo. As tentativas de aula n\xe3o usadas n\xe3o poder\xe3o mais ser jogadas.","\u73fe\u5728\u306e\u6210\u7e3e\u8868\u304c\u6700\u7d42\u7d50\u679c\u306b\u306a\u308a\u307e\u3059\u3002\u672a\u4f7f\u7528\u306e\u30ec\u30c3\u30b9\u30f3\u6311\u6226\u306f\u305d\u306e\u5f8c\u30d7\u30ec\u30a4\u3067\u304d\u307e\u305b\u3093\u3002"],t.s)
A.qs=s(["Weiter trainieren","Seguir entrenando","Continuer l\u2019entra\xeenement","Continua ad allenarti","Continuar treinando","\u8a13\u7df4\u3092\u7d9a\u3051\u308b"],t.s)
A.Ko=s(["Kein Portr\xe4trahmen","Sin marco de retrato","Aucun cadre de portrait","Nessuna cornice ritratto","Sem moldura de retrato","\u30dd\u30fc\u30c8\u30ec\u30fc\u30c8\u30d5\u30ec\u30fc\u30e0\u306a\u3057"],t.s)
A.oq=s(["Portr\xe4trahmen w\xe4hlen","Elegir marco de retrato","Choisir le cadre du portrait","Scegli la cornice del ritratto","Escolher moldura do retrato","\u30dd\u30fc\u30c8\u30ec\u30fc\u30c8\u30d5\u30ec\u30fc\u30e0\u3092\u9078\u3076"],t.s)
A.Fy=s(["Gr\xfcndungssupporter-Rahmen","Marco de colaborador fundador","Cadre de soutien fondateur","Cornice del sostenitore fondatore","Moldura de apoiador fundador","\u5275\u8a2d\u30b5\u30dd\u30fc\u30bf\u30fc\u30d5\u30ec\u30fc\u30e0"],t.s)
A.xt=s(["Pakete","Paquetes","Packs","Pacchetti","Pacotes","\u30d1\u30c3\u30af"],t.s)
A.lJ=s(["Besondere Kosmetiksammlungen. Sp\xe4ter k\xf6nnen weitere Pakete in diesen Shop aufgenommen werden.","Colecciones cosm\xe9ticas especiales. M\xe1s adelante podr\xe1n a\xf1adirse m\xe1s paquetes a esta tienda.","Collections cosm\xe9tiques sp\xe9ciales. D\u2019autres packs pourront rejoindre cette boutique plus tard.","Collezioni cosmetiche speciali. In futuro potranno essere aggiunti altri pacchetti a questo negozio.","Cole\xe7\xf5es cosm\xe9ticas especiais. Mais pacotes poder\xe3o entrar nesta loja futuramente.","\u7279\u5225\u306a\u30b3\u30b9\u30e1\u30b3\u30ec\u30af\u30b7\u30e7\u30f3\u3067\u3059\u3002\u4eca\u5f8c\u3001\u3053\u306e\u30b7\u30e7\u30c3\u30d7\u306b\u5225\u306e\u30d1\u30c3\u30af\u3082\u8ffd\u52a0\u3067\u304d\u307e\u3059\u3002"],t.s)
A.qT=s(["H\xfctertagebuch","Diario del Guardi\xe1n","Journal du Gardien","Diario del Custode","Di\xe1rio do Guardi\xe3o","\u30ad\u30fc\u30d1\u30fc\u65e5\u8a8c"],t.s)
A.mo=s(["Zeige dieses Abzeichen in deinem H\xfcterprofil.","Muestra esta insignia en tu identidad de Guardi\xe1n.","Affichez ce badge sur votre identit\xe9 de Gardien.","Mostra questo distintivo sulla tua identit\xe0 di Custode.","Mostre este emblema na sua identidade de Guardi\xe3o.","\u30ad\u30fc\u30d1\u30fc\u306e\u30d7\u30ed\u30d5\u30a3\u30fc\u30eb\u306b\u3053\u306e\u30d0\u30c3\u30b8\u3092\u8868\u793a\u3057\u307e\u3059\u3002"],t.s)
A.F_=s(["Rahme dein Portr\xe4t mit Supportergold ein.","Enmarca tu retrato con el oro de los colaboradores.","Encadrez votre portrait avec l\u2019or des soutiens.","Incornicia il tuo ritratto con l\u2019oro dei sostenitori.","Emoldure seu retrato com o ouro dos apoiadores.","\u30b5\u30dd\u30fc\u30bf\u30fc\u30b4\u30fc\u30eb\u30c9\u3067\u8096\u50cf\u3092\u98fe\u308a\u307e\u3059\u3002"],t.s)
A.yJ=s(["Gr\xfcndungssupporter","Colaborador fundador","Soutien fondateur","Sostenitore fondatore","Apoiador fundador","\u5275\u8a2d\u30b5\u30dd\u30fc\u30bf\u30fc"],t.s)
A.Ca=s(["Siebent\xe4giges Pr\xfcfungssternbild","Constelaci\xf3n de Pruebas de siete d\xedas","Constellation d\u2019\xc9preuves de sept jours","Costellazione delle Prove di sette giorni","Constela\xe7\xe3o de Provas de sete dias","7\u65e5\u9593\u30c8\u30e9\u30a4\u30a2\u30eb\u661f\u5ea7"],t.s)
A.C1=s(["Dein Sternbild ist vollst\xe4ndig!","\xa1Tu constelaci\xf3n est\xe1 completa!","Votre constellation est compl\xe8te !","La tua costellazione \xe8 completa!","Sua constela\xe7\xe3o est\xe1 completa!","\u661f\u5ea7\u304c\u5b8c\u6210\u3057\u307e\u3057\u305f\uff01"],t.s)
A.pw=s(["Schlie\xdfe jeden Tag eine Pr\xfcfung ab. Verpasst du einen Tag, beginnt die Serie wieder bei null.","Completa una Prueba cada d\xeda. Si pierdes un d\xeda, la racha vuelve a cero.","Terminez une \xc9preuve chaque jour. Si vous manquez un jour, la s\xe9rie revient \xe0 z\xe9ro.","Completa una Prova ogni giorno. Se salti un giorno, la serie torna a zero.","Conclua uma Prova todos os dias. Se perder um dia, a sequ\xeancia volta a zero.","\u6bce\u65e5\u30c8\u30e9\u30a4\u30a2\u30eb\u3092\u5b8c\u4e86\u3057\u307e\u3057\u3087\u3046\u30021\u65e5\u9003\u3059\u3068\u9023\u7d9a\u8a18\u9332\u306f0\u306b\u623b\u308a\u307e\u3059\u3002"],t.s)
A.rP=s(["Belohnung: 95 % Drachenkiste \xb7 5 % Mythische Kiste","Recompensa: 95 % Cofre de drag\xf3n \xb7 5 % Cofre m\xedtico","R\xe9compense : 95 % Coffre de dragon \xb7 5 % Coffre mythique","Ricompensa: 95% Forziere del drago \xb7 5% Forziere mitico","Recompensa: 95% Ba\xfa de drag\xe3o \xb7 5% Ba\xfa m\xedtico","\u5831\u916c\uff1a\u30c9\u30e9\u30b4\u30f3\u30c1\u30a7\u30b9\u30c895%\u30fb\u30df\u30b7\u30ab\u30eb\u30c1\u30a7\u30b9\u30c85%"],t.s)
A.zZ=s(["Die heutige Pr\xfcfung wartet sicher als Tag 1 deiner n\xe4chsten Serie.","La Prueba de hoy est\xe1 guardada como d\xeda 1 de tu pr\xf3xima racha.","L\u2019\xc9preuve du jour est conserv\xe9e comme jour 1 de votre prochaine s\xe9rie.","La Prova di oggi \xe8 conservata come giorno 1 della prossima serie.","A Prova de hoje est\xe1 guardada como dia 1 da sua pr\xf3xima sequ\xeancia.","\u4eca\u65e5\u306e\u30c8\u30e9\u30a4\u30a2\u30eb\u306f\u6b21\u306e\u9023\u7d9a\u8a18\u9332\u306e1\u65e5\u76ee\u3068\u3057\u3066\u4fdd\u5b58\u3055\u308c\u3066\u3044\u307e\u3059\u3002"],t.s)
A.Ls=s(["Voraussetzungen zum Start","Requisitos para empezar","Conditions de d\xe9part","Requisiti per iniziare","Requisitos para come\xe7ar","\u958b\u59cb\u6761\u4ef6"],t.s)
A.mP=s(["Die Gruppe kann erst aufbrechen, wenn alle folgenden Voraussetzungen erf\xfcllt sind.","El grupo solo puede partir cuando se cumplan todos los requisitos siguientes.","Le groupe ne peut partir que lorsque toutes les conditions ci-dessous sont remplies.","Il gruppo pu\xf2 partire solo quando tutti i requisiti seguenti sono soddisfatti.","O grupo s\xf3 pode partir quando todos os requisitos abaixo forem cumpridos.","\u4ee5\u4e0b\u306e\u6761\u4ef6\u3092\u3059\u3079\u3066\u6e80\u305f\u3059\u3068\u30b0\u30eb\u30fc\u30d7\u306f\u51fa\u767a\u3067\u304d\u307e\u3059\u3002"],t.s)
A.E8=s(["Voraussichtliche Belohnungen","Recompensas previstas","R\xe9compenses pr\xe9vues","Ricompense previste","Recompensas previstas","\u4e88\u60f3\u5831\u916c"],t.s)
A.Ar=s(["Drachenakademie","Academia de Dragones","Acad\xe9mie des Dragons","Accademia dei Draghi","Academia de Drag\xf5es","\u30c9\u30e9\u30b4\u30f3\u30a2\u30ab\u30c7\u30df\u30fc"],t.s)
A.x_=s(["\xdcbung macht Legenden","La pr\xe1ctica crea leyendas","La pratique forge les l\xe9gendes","La pratica crea leggende","A pr\xe1tica cria lendas","\u7df4\u7fd2\u304c\u4f1d\u8aac\u3092\u751f\u3080"],t.s)
A.L7=s(["Zehn kurze Lektionen, keine Versuche oder Belohnungen \u2013 nur deine Bestleistungen.","Diez lecciones breves, sin intentos ni recompensas: solo tus r\xe9cords personales.","Dix courtes le\xe7ons, sans essais ni r\xe9compenses : seulement vos records personnels.","Dieci brevi lezioni, senza tentativi n\xe9 ricompense: solo i tuoi record personali.","Dez li\xe7\xf5es curtas, sem tentativas nem recompensas \u2014 apenas seus recordes pessoais.","10\u7a2e\u985e\u306e\u77ed\u3044\u30ec\u30c3\u30b9\u30f3\u3002\u56de\u6570\u5236\u9650\u3082\u5831\u916c\u3082\u306a\u304f\u3001\u81ea\u5df1\u30d9\u30b9\u30c8\u3060\u3051\u3092\u7af6\u3044\u307e\u3059\u3002"],t.s)
A.IM=s(["ZEIT","TIEMPO","TEMPS","TEMPO","TEMPO","\u6642\u9593"],t.s)
A.D8=s(["Eine \xdcbungsrunde dauert 20 Sekunden und gibt keine Belohnungen.","Una ronda de pr\xe1ctica dura 20 segundos y no da recompensas.","Une manche d\u2019entra\xeenement dure 20 secondes et ne donne aucune r\xe9compense.","Un turno di pratica dura 20 secondi e non d\xe0 ricompense.","Uma rodada de treino dura 20 segundos e n\xe3o d\xe1 recompensas.","\u7df4\u7fd2\u30e9\u30a6\u30f3\u30c9\u306f20\u79d2\u9593\u3067\u3001\u5831\u916c\u306f\u3042\u308a\u307e\u305b\u3093\u3002"],t.s)
A.oK=s(["Lektion starten","Empezar lecci\xf3n","Commencer la le\xe7on","Inizia la lezione","Come\xe7ar li\xe7\xe3o","\u30ec\u30c3\u30b9\u30f3\u958b\u59cb"],t.s)
A.G9=s(["Lektion abgeschlossen","Lecci\xf3n completada","Le\xe7on termin\xe9e","Lezione completata","Li\xe7\xe3o conclu\xedda","\u30ec\u30c3\u30b9\u30f3\u5b8c\u4e86"],t.s)
A.ny=s(["Bestleistung","R\xe9cord personal","Record personnel","Record personale","Recorde pessoal","\u81ea\u5df1\u30d9\u30b9\u30c8"],t.s)
A.G6=s(["Erneut \xfcben","Practicar de nuevo","S\u2019entra\xeener \xe0 nouveau","Allenati di nuovo","Treinar novamente","\u3082\u3046\u4e00\u5ea6\u7df4\u7fd2"],t.s)
A.Kf=s(["Merken \u2026","Recuerda\u2026","M\xe9morisez\u2026","Ricorda\u2026","Lembre-se\u2026","\u899a\u3048\u3066\u2026"],t.s)
A.oS=s(["Welches Siegel?","\xbfQu\xe9 sigilo?","Quel sceau ?","Quale sigillo?","Qual sigilo?","\u3069\u306e\u7d0b\u7ae0\uff1f"],t.s)
A.zY=s(["N\xe4chste Schuppe","Siguiente escama","\xc9caille suivante","Scaglia successiva","Pr\xf3xima escama","\u6b21\u306e\u3046\u308d\u3053"],t.s)
A.y6=s(["Stopp","Detener","Arr\xeater","Ferma","Parar","\u505c\u6b62"],t.s)
A.Gs=s(["Raumreihenfolge \xe4ndern","Cambiar orden de salas","Modifier l\u2019ordre des salles","Cambia l\u2019ordine delle stanze","Alterar ordem das salas","\u90e8\u5c4b\u306e\u9806\u5e8f\u3092\u5909\u66f4"],t.s)
A.pg=s(["Ordne deinen Turm","Organiza tu Torre","Organisez votre Tour","Organizza la tua Torre","Organize sua Torre","\u5854\u3092\u4e26\u3079\u66ff\u3048\u308b"],t.s)
A.C4=s(["Ziehe die R\xe4ume von oben nach unten in deine gew\xfcnschte Reihenfolge.","Arrastra las salas al orden que prefieras de arriba abajo.","Faites glisser les salles dans l\u2019ordre souhait\xe9, de haut en bas.","Trascina le stanze nell\u2019ordine desiderato dall\u2019alto verso il basso.","Arraste as salas para a ordem desejada, de cima para baixo.","\u90e8\u5c4b\u3092\u30c9\u30e9\u30c3\u30b0\u3057\u3066\u3001\u4e0a\u304b\u3089\u9806\u306b\u597d\u304d\u306a\u4e26\u3073\u3078\u5909\u66f4\u3057\u307e\u3059\u3002"],t.s)
A.w9=s(["Oben fixiert","Fijo arriba","Fix\xe9 en haut","Fisso in cima","Fixo no topo","\u6700\u4e0a\u90e8\u306b\u56fa\u5b9a"],t.s)
A.ur=s(["Raum ziehen","Arrastrar sala","D\xe9placer la salle","Trascina stanza","Arrastar sala","\u90e8\u5c4b\u3092\u30c9\u30e9\u30c3\u30b0"],t.s)
A.A8=s(["10 Lektionen \xb7 pers\xf6nliche Rekorde","10 lecciones \xb7 r\xe9cords personales","10 le\xe7ons \xb7 records personnels","10 lezioni \xb7 record personali","10 li\xe7\xf5es \xb7 recordes pessoais","10\u30ec\u30c3\u30b9\u30f3\u30fb\u81ea\u5df1\u8a18\u9332"],t.s)
A.ye=s(["Wird mit 5 Turmetagen freigeschaltet","Se desbloquea cuando tu Torre tiene 5 pisos","Se d\xe9bloque lorsque votre Tour compte 5 \xe9tages","Si sblocca quando la Torre ha 5 piani","Desbloqueia quando sua Torre tiver 5 andares","\u5854\u304c5\u968e\u306b\u306a\u308b\u3068\u89e3\u653e"],t.s)
A.jK=s(["Deine Geschichte, bewahrt in Tinte und Sternenlicht","Tu historia, guardada entre tinta y luz estelar","Votre histoire, conserv\xe9e dans l\u2019encre et la lumi\xe8re des \xe9toiles","La tua storia, custodita nell\u2019inchiostro e nella luce stellare","Sua hist\xf3ria, guardada em tinta e luz estelar","\u30a4\u30f3\u30af\u3068\u661f\u660e\u304b\u308a\u306b\u523b\u307e\u308c\u305f\u3001\u3042\u306a\u305f\u306e\u7269\u8a9e"],t.s)
A.nU=s(["Abenteuer, Entdeckungen und Meilensteine aus deinem Leben als H\xfcter.","Aventuras, descubrimientos e hitos de tu vida como Guardi\xe1n.","Les aventures, d\xe9couvertes et \xe9tapes de votre vie de Gardien.","Avventure, scoperte e traguardi della tua vita da Custode.","Aventuras, descobertas e marcos da sua vida como Guardi\xe3o.","\u30ad\u30fc\u30d1\u30fc\u3068\u3057\u3066\u6b69\u3093\u3060\u5192\u967a\u3001\u767a\u898b\u3001\u7bc0\u76ee\u306e\u8a18\u9332\u3067\u3059\u3002"],t.s)
A.pr=s(["Tage","d\xedas","jours","giorni","dias","\u65e5"],t.s)
A.KH=s(["Momente","momentos","moments","momenti","momentos","\u8a18\u9332"],t.s)
A.DG=s(["Diese Seiten warten noch auf eine Geschichte.","Estas p\xe1ginas a\xfan esperan una historia.","Ces pages attendent encore une histoire.","Queste pagine aspettano ancora una storia.","Estas p\xe1ginas ainda esperam uma hist\xf3ria.","\u3053\u306e\u30da\u30fc\u30b8\u306f\u307e\u3060\u7269\u8a9e\u3092\u5f85\u3063\u3066\u3044\u307e\u3059\u3002"],t.s)
A.lv=s(["Abenteuer","Aventuras","Aventures","Avventure","Aventuras","\u5192\u967a"],t.s)
A.nK=s(["Entdeckungen","Descubrimientos","D\xe9couvertes","Scoperte","Descobertas","\u767a\u898b"],t.s)
A.E5=s(["Meilensteine","Hitos","\xc9tapes","Traguardi","Marcos","\u7bc0\u76ee"],t.s)
A.qC=s(["Heute","Hoy","Aujourd\u2019hui","Oggi","Hoje","\u4eca\u65e5"],t.s)
A.Hr=s(["Gestern","Ayer","Hier","Ieri","Ontem","\u6628\u65e5"],t.s)
A.Kc=s(["Supporter","Colaborador","Soutien","Sostenitore","Apoiador","\u30b5\u30dd\u30fc\u30bf\u30fc"],t.s)
A.lx=s(["Gr\xfcndungssupporter-Paket","Paquete de colaborador fundador","Pack Soutien fondateur","Pacchetto Sostenitore fondatore","Pacote Apoiador fundador","\u5275\u8a2d\u30b5\u30dd\u30fc\u30bf\u30fc\u30d1\u30c3\u30af"],t.s)
A.CK=s(["Eine dauerhafte Kosmetiksammlung als Dank an die H\xfcter, die DragonHaven beim Wachsen helfen.","Una colecci\xf3n permanente de cosm\xe9ticos para agradecer a los Guardianes que ayudan a crecer a DragonHaven.","Une collection permanente de cosm\xe9tiques pour remercier les Gardiens qui aident DragonHaven \xe0 grandir.","Una collezione permanente di elementi cosmetici per ringraziare i Custodi che aiutano DragonHaven a crescere.","Uma cole\xe7\xe3o permanente de cosm\xe9ticos para agradecer aos Guardi\xf5es que ajudam DragonHaven a crescer.","DragonHaven\u306e\u6210\u9577\u3092\u652f\u3048\u3066\u304f\u308c\u308b\u30ad\u30fc\u30d1\u30fc\u3078\u306e\u611f\u8b1d\u3092\u8fbc\u3081\u305f\u3001\u6052\u4e45\u7684\u306a\u30b3\u30b9\u30e1\u30b3\u30ec\u30af\u30b7\u30e7\u30f3\u3067\u3059\u3002"],t.s)
A.xm=s(["IM BESITZ","EN PROPIEDAD","POSS\xc9D\xc9","POSSEDUTO","ADQUIRIDO","\u6240\u6709\u6e08\u307f"],t.s)
A.n5=s(["Alles enthalten","Todo incluido","Tout est inclus","Tutto incluso","Tudo inclu\xeddo","\u3059\u3079\u3066\u540c\u68b1"],t.s)
A.k2=s(["Exklusives Supporterportr\xe4t","Retrato exclusivo de colaborador","Portrait exclusif de soutien","Ritratto esclusivo del sostenitore","Retrato exclusivo de apoiador","\u9650\u5b9a\u30b5\u30dd\u30fc\u30bf\u30fc\u8096\u50cf"],t.s)
A.qN=s(["Ist von Portr\xe4tkisten getrennt und ver\xe4ndert niemals deren Chancen.","Es independiente de los Cofres de retrato y nunca cambia sus probabilidades.","Ind\xe9pendant des Coffres de portrait, il ne modifie jamais leurs chances.","\xc8 separato dai Forzieri ritratto e non ne modifica mai le probabilit\xe0.","\xc9 separado dos Ba\xfas de retrato e nunca altera suas chances.","\u30dd\u30fc\u30c8\u30ec\u30fc\u30c8\u30c1\u30a7\u30b9\u30c8\u3068\u306f\u5225\u67a0\u3067\u3001\u6392\u51fa\u7387\u306b\u306f\u5f71\u97ff\u3057\u307e\u305b\u3093\u3002"],t.s)
A.B7=s(["Titel \u201eGr\xfcndungssupporter\u201c","T\xedtulo \xabColaborador fundador\xbb","Titre \xab Soutien fondateur \xbb","Titolo \u201cSostenitore fondatore\u201d","T\xedtulo \u201cApoiador fundador\u201d","\u300c\u5275\u8a2d\u30b5\u30dd\u30fc\u30bf\u30fc\u300d\u306e\u79f0\u53f7"],t.s)
A.qU=s(["Ist von Titelkisten getrennt und ver\xe4ndert niemals deren Chancen.","Es independiente de los Cofres de t\xedtulo y nunca cambia sus probabilidades.","Ind\xe9pendant des Coffres de titre, il ne modifie jamais leurs chances.","\xc8 separato dai Forzieri titolo e non ne modifica mai le probabilit\xe0.","\xc9 separado dos Ba\xfas de t\xedtulo e nunca altera suas chances.","\u30bf\u30a4\u30c8\u30eb\u30c1\u30a7\u30b9\u30c8\u3068\u306f\u5225\u67a0\u3067\u3001\u6392\u51fa\u7387\u306b\u306f\u5f71\u97ff\u3057\u307e\u305b\u3093\u3002"],t.s)
A.Hf=s(["Supporterabzeichen","Insignia de colaborador","Badge de soutien","Distintivo del sostenitore","Emblema de apoiador","\u30b5\u30dd\u30fc\u30bf\u30fc\u30d0\u30c3\u30b8"],t.s)
A.vR=s(["Ein neues Profilkosmetikum, das deine Unterst\xfctzung deutlich zeigt.","Un nuevo cosm\xe9tico de identidad que muestra claramente tu apoyo.","Un nouvel \xe9l\xe9ment cosm\xe9tique d\u2019identit\xe9 qui affiche clairement votre soutien.","Un nuovo elemento cosmetico dell\u2019identit\xe0 che mostra chiaramente il tuo sostegno.","Um novo cosm\xe9tico de identidade que mostra claramente seu apoio.","\u3042\u306a\u305f\u306e\u652f\u63f4\u3092\u306f\u3063\u304d\u308a\u793a\u3059\u3001\u65b0\u3057\u3044\u30d7\u30ed\u30d5\u30a3\u30fc\u30eb\u7528\u30b3\u30b9\u30e1\u3067\u3059\u3002"],t.s)
A.nD=s(["Supporter-Portr\xe4trahmen","Marco de retrato de colaborador","Cadre de portrait de soutien","Cornice ritratto del sostenitore","Moldura de retrato de apoiador","\u30b5\u30dd\u30fc\u30bf\u30fc\u8096\u50cf\u30d5\u30ec\u30fc\u30e0"],t.s)
A.mi=s(["Ein ausr\xfcstbarer Profilrahmen, der exklusiv f\xfcr dieses Paket erstellt wurde.","Un marco de perfil equipable creado exclusivamente para este paquete.","Un cadre de profil \xe9quipable cr\xe9\xe9 exclusivement pour ce pack.","Una cornice profilo equipaggiabile creata esclusivamente per questo pacchetto.","Uma moldura de perfil equip\xe1vel criada exclusivamente para este pacote.","\u3053\u306e\u30d1\u30c3\u30af\u5c02\u7528\u306b\u4f5c\u3089\u308c\u305f\u3001\u88c5\u7740\u53ef\u80fd\u306a\u30d7\u30ed\u30d5\u30a3\u30fc\u30eb\u30d5\u30ec\u30fc\u30e0\u3067\u3059\u3002"],t.s)
A.An=s(["Vollst\xe4ndiges Supporterm\xf6belset","Conjunto completo de muebles de colaborador","Ensemble complet de meubles de soutien","Set completo di arredi del sostenitore","Conjunto completo de m\xf3veis de apoiador","\u30b5\u30dd\u30fc\u30bf\u30fc\u5bb6\u5177\u4e00\u5f0f"],t.s)
A.F3=s(["Das Paket ist f\xfcr 2,99 \u20ac vorbereitet. Der Kauf wird verf\xfcgbar, sobald das Google-Play-Produkt und die sichere Serverpr\xfcfung verbunden sind.","El paquete est\xe1 preparado por 2,99 \u20ac. La compra estar\xe1 disponible cuando se conecten el producto de Google Play y la verificaci\xf3n segura del servidor.","Le pack est pr\xeat \xe0 2,99 \u20ac. L\u2019achat sera disponible une fois le produit Google Play et la v\xe9rification s\xe9curis\xe9e du serveur connect\xe9s.","Il pacchetto \xe8 pronto a 2,99 \u20ac. L\u2019acquisto sar\xe0 disponibile dopo aver collegato il prodotto Google Play e la verifica sicura del server.","O pacote est\xe1 pronto por \u20ac 2,99. A compra ficar\xe1 dispon\xedvel ap\xf3s conectar o produto do Google Play e a verifica\xe7\xe3o segura do servidor.","\u30d1\u30c3\u30af\u306f2.99\u30e6\u30fc\u30ed\u3067\u6e96\u5099\u6e08\u307f\u3067\u3059\u3002Google Play\u5546\u54c1\u3068\u5b89\u5168\u306a\u30b5\u30fc\u30d0\u30fc\u691c\u8a3c\u3092\u63a5\u7d9a\u3059\u308b\u3068\u8cfc\u5165\u53ef\u80fd\u306b\u306a\u308a\u307e\u3059\u3002"],t.s)
A.v9=s(["Paket im Besitz","Paquete adquirido","Pack poss\xe9d\xe9","Pacchetto posseduto","Pacote adquirido","\u30d1\u30c3\u30af\u6240\u6709\u6e08\u307f"],t.s)
A.HC=s(["2,99 \u20ac \xb7 Google-Play-Einrichtung erforderlich","2,99 \u20ac \xb7 Requiere configurar Google Play","2,99 \u20ac \xb7 Configuration Google Play requise","2,99 \u20ac \xb7 Configurazione Google Play necessaria","\u20ac 2,99 \xb7 Configura\xe7\xe3o do Google Play necess\xe1ria","2.99\u30e6\u30fc\u30ed\u30fbGoogle Play\u8a2d\u5b9a\u304c\u5fc5\u8981"],t.s)
A.DJ=s(["Nur kosmetisch: keine Gems, M\xfcnzen, St\xe4rke oder Spielvorteile.","Solo cosm\xe9tico: sin gemas, monedas, poder ni ventajas de juego.","Uniquement cosm\xe9tique : aucun gemme, pi\xe8ce, pouvoir ou avantage de jeu.","Solo cosmetico: nessuna gemma, moneta, potenza o vantaggio di gioco.","Apenas cosm\xe9tico: sem gemas, moedas, poder ou vantagem de jogo.","\u30b3\u30b9\u30e1\u9650\u5b9a\uff1a\u30b8\u30a7\u30e0\u3001\u30b3\u30a4\u30f3\u3001\u80fd\u529b\u3001\u30b2\u30fc\u30e0\u4e0a\u306e\u512a\u4f4d\u6027\u306f\u3042\u308a\u307e\u305b\u3093\u3002"],t.s)
A.CS=s(["F\xfcr diese Lektion sind nicht gen\xfcgend Drachen verf\xfcgbar.","No hay suficientes dragones disponibles para esta lecci\xf3n.","Il n\u2019y a pas assez de dragons disponibles pour cette le\xe7on.","Non ci sono abbastanza draghi disponibili per questa lezione.","N\xe3o h\xe1 drag\xf5es dispon\xedveis suficientes para esta li\xe7\xe3o.","\u3053\u306e\u30ec\u30c3\u30b9\u30f3\u306b\u53c2\u52a0\u3067\u304d\u308b\u30c9\u30e9\u30b4\u30f3\u304c\u8db3\u308a\u307e\u305b\u3093\u3002"],t.s)
A.ya=s(["W\xe4hle deine Sch\xfcler, verdiene jeden Stern einmal und erstelle f\xfcr jeden Drachen ein eigenes Zeugnis.","Elige a tus alumnos, gana cada estrella una vez y crea un bolet\xedn personal para cada drag\xf3n.","Choisis tes \xe9l\xe8ves, gagne chaque \xe9toile une fois et cr\xe9e un bulletin personnel pour chaque dragon.","Scegli gli allievi, ottieni ogni stella una volta e crea una pagella personale per ogni drago.","Escolha seus alunos, ganhe cada estrela uma vez e crie um boletim individual para cada drag\xe3o.","\u751f\u5f92\u3092\u9078\u3073\u3001\u5404\u30b9\u30bf\u30fc\u3092\u4e00\u5ea6\u305a\u3064\u7372\u5f97\u3057\u3066\u3001\u30c9\u30e9\u30b4\u30f3\u3054\u3068\u306e\u6210\u7e3e\u8868\u3092\u4f5c\u308a\u307e\u3057\u3087\u3046\u3002"],t.s)
A.uq=s(["30 Sterne pro Drache","30 estrellas por drag\xf3n","30 \xe9toiles par dragon","30 stelle per drago","30 estrelas por drag\xe3o","\u30c9\u30e9\u30b4\u30f31\u982d\u306b\u3064\u304d30\u30b9\u30bf\u30fc"],t.s)
A.K7=s(["H\xdcTERREKORD","R\xc9CORD DEL GUARDI\xc1N","RECORD DU GARDIEN","RECORD DEL CUSTODE","RECORDE DO GUARDI\xc3O","\u30ad\u30fc\u30d1\u30fc\u6700\u9ad8"],t.s)
A.FY=s(["Optionaler aufgestiegener Mentor","Mentor ascendido opcional","Mentor transcend\xe9 facultatif","Mentore asceso facoltativo","Mentor ascendido opcional","\u4efb\u610f\u306e\u30a2\u30bb\u30f3\u30c7\u30c3\u30c9\u30fb\u30e1\u30f3\u30bf\u30fc"],t.s)
A.Lf=s(["Ein Mentor f\xe4ngt einen Fehler ab. Die Sch\xfcler erhalten alle Sterne und Belohnungen.","Un mentor cubre un error. Los alumnos reciben todas las estrellas y recompensas.","Un mentor absorbe une erreur. Les \xe9l\xe8ves re\xe7oivent toutes les \xe9toiles et r\xe9compenses.","Un mentore assorbe un errore. Gli allievi ricevono tutte le stelle e le ricompense.","Um mentor absorve um erro. Os alunos recebem todas as estrelas e recompensas.","\u30e1\u30f3\u30bf\u30fc\u306f\u30df\u30b9\u30921\u56de\u9632\u304e\u307e\u3059\u3002\u30b9\u30bf\u30fc\u3068\u5831\u916c\u306f\u3059\u3079\u3066\u751f\u5f92\u304c\u53d7\u3051\u53d6\u308a\u307e\u3059\u3002"],t.s)
A.AY=s(["Kein Mentor","Sin mentor","Aucun mentor","Nessun mentore","Sem mentor","\u30e1\u30f3\u30bf\u30fc\u306a\u3057"],t.s)
A.x4=s(["Klassenzimmer betreten","Entrar al aula","Entrer en classe","Entra in classe","Entrar na sala de aula","\u6559\u5ba4\u3078"],t.s)
A.wn=s(["H\xfcterrekord","R\xe9cord del Guardi\xe1n","Record du Gardien","Record del Custode","Recorde do Guardi\xe3o","\u30ad\u30fc\u30d1\u30fc\u6700\u9ad8\u8a18\u9332"],t.s)
A.GL=s(["Diplom verdient!","\xa1Diploma conseguido!","Dipl\xf4me obtenu !","Diploma ottenuto!","Diploma conquistado!","\u5352\u696d\u8a3c\u66f8\u3092\u7372\u5f97\uff01"],t.s)
A.w1=s(["\xdcbung","Pr\xe1ctica","Entra\xeenement","Allenamento","Treino","\u7df4\u7fd2"],t.s)
A.DI=s(["Ausbalancieren","Equilibrar","\xc9quilibrer","Bilancia","Equilibrar","\u30d0\u30e9\u30f3\u30b9"],t.s)
A.rY=s(["Folge dem leuchtenden Pfad der Reihe nach","Sigue el camino brillante en orden","Suis le chemin lumineux dans l\u2019ordre","Segui il percorso luminoso nell\u2019ordine corretto","Siga o caminho brilhante na ordem correta","\u5149\u308b\u9053\u3092\u9806\u756a\u3069\u304a\u308a\u306b\u306a\u305e\u308d\u3046"],t.s)
A.L9=s(["Mentor","Mentor","Mentor","Mentore","Mentor","\u30e1\u30f3\u30bf\u30fc"],t.s)
A.DM=s([" \xb7 TEAMARBEIT"," \xb7 EQUIPO"," \xb7 \xc9QUIPE"," \xb7 SQUADRA"," \xb7 EQUIPE","\u30fb\u30c1\u30fc\u30e0\u30ef\u30fc\u30af"],t.s)
A.tF=s(["niedrigste Expertise","especialidad m\xe1s baja","expertise la plus faible","competenza pi\xf9 bassa","especialidade mais baixa","\u6700\u3082\u4f4e\u3044\u5c02\u9580\u80fd\u529b"],t.s)
A.KR=s(["10 Lektionen \xb7 Drachen, Sterne und Rekorde","10 lecciones \xb7 dragones, estrellas y r\xe9cords","10 le\xe7ons \xb7 dragons, \xe9toiles et records","10 lezioni \xb7 draghi, stelle e record","10 li\xe7\xf5es \xb7 drag\xf5es, estrelas e recordes","10\u30ec\u30c3\u30b9\u30f3\u30fb\u30c9\u30e9\u30b4\u30f3\u3001\u30b9\u30bf\u30fc\u3001\u8a18\u9332"],t.s)
A.nV=s(["Drachenakademie-Diplom","Diploma de la Academia de Dragones","Dipl\xf4me de l\u2019Acad\xe9mie des dragons","Diploma dell\u2019Accademia dei Draghi","Diploma da Academia de Drag\xf5es","\u30c9\u30e9\u30b4\u30f3\u30a2\u30ab\u30c7\u30df\u30fc\u5352\u696d\u8a3c\u66f8"],t.s)
A.tp=s(["Drachenakademie-Zeugnis","Bolet\xedn de la Academia de Dragones","Bulletin de l\u2019Acad\xe9mie des dragons","Pagella dell\u2019Accademia dei Draghi","Boletim da Academia de Drag\xf5es","\u30c9\u30e9\u30b4\u30f3\u30a2\u30ab\u30c7\u30df\u30fc\u6210\u7e3e\u8868"],t.s)
A.og=s(["Sterne","estrellas","\xe9toiles","stelle","estrelas","\u30b9\u30bf\u30fc"],t.s)
A.ph=s(["Gr\xfcndungssupporter-Paket freigeschaltet. Danke, dass du DragonHaven unterst\xfctzt!","Pack de Colaborador Fundador desbloqueado. \xa1Gracias por apoyar a DragonHaven!","Pack de soutien fondateur d\xe9bloqu\xe9. Merci de soutenir DragonHaven !","Pacchetto Sostenitore Fondatore sbloccato. Grazie per sostenere DragonHaven!","Pacote de Apoiador Fundador desbloqueado. Obrigado por apoiar DragonHaven!","\u5275\u8a2d\u30b5\u30dd\u30fc\u30bf\u30fc\u30d1\u30c3\u30af\u3092\u89e3\u9664\u3057\u307e\u3057\u305f\u3002DragonHaven\u3078\u306e\u5fdc\u63f4\u3042\u308a\u304c\u3068\u3046\u3054\u3056\u3044\u307e\u3059\uff01"],t.s)
A.By=s(["Du besitzt das Gr\xfcndungssupporter-Paket bereits.","Ya tienes el Pack de Colaborador Fundador.","Tu poss\xe8des d\xe9j\xe0 le Pack de soutien fondateur.","Possiedi gi\xe0 il Pacchetto Sostenitore Fondatore.","Voc\xea j\xe1 possui o Pacote de Apoiador Fundador.","\u5275\u8a2d\u30b5\u30dd\u30fc\u30bf\u30fc\u30d1\u30c3\u30af\u306f\u3059\u3067\u306b\u6240\u6301\u3057\u3066\u3044\u307e\u3059\u3002"],t.s)
A.HY=s(["Akademie-Rangliste","Clasificaci\xf3n de la academia","Classement de l\u2019acad\xe9mie","Classifica dell\u2019accademia","Classifica\xe7\xe3o da academia","\u30a2\u30ab\u30c7\u30df\u30fc\u9806\u4f4d\u8868"],t.s)
A.H3=s(["Beste Ergebnisse, fair \xfcber alle Lektionen normiert","Mejores resultados, normalizados de forma justa entre las lecciones","Meilleurs r\xe9sultats, normalis\xe9s \xe9quitablement entre les le\xe7ons","Migliori risultati, normalizzati equamente tra le lezioni","Melhores resultados, normalizados de forma justa entre as aulas","\u5168\u30ec\u30c3\u30b9\u30f3\u3092\u516c\u5e73\u306b\u6b63\u898f\u5316\u3057\u305f\u30d9\u30b9\u30c8\u7d50\u679c"],t.s)
A.xW=s(["Schlie\xdfe eine erste Lektion ab, um in die Rangliste zu kommen.","Completa una primera lecci\xf3n para entrar en la clasificaci\xf3n.","Termine une premi\xe8re le\xe7on pour entrer dans le classement.","Completa una prima lezione per entrare in classifica.","Conclua uma primeira aula para entrar na classifica\xe7\xe3o.","\u6700\u521d\u306e\u30ec\u30c3\u30b9\u30f3\u3092\u7d42\u3048\u308b\u3068\u9806\u4f4d\u8868\u306b\u5165\u308a\u307e\u3059\u3002"],t.s)
A.vC=s(["Gold entspricht 100 Akademiepunkten pro Lektion; au\xdfergew\xf6hnliche Ergebnisse bringen bis zu 20 Bonuspunkte.","El oro vale 100 puntos de academia por lecci\xf3n; las puntuaciones excepcionales dan hasta 20 puntos extra.","L\u2019or vaut 100 points d\u2019acad\xe9mie par le\xe7on ; un score exceptionnel rapporte jusqu\u2019\xe0 20 points bonus.","L\u2019oro vale 100 punti accademia per lezione; i punteggi eccezionali danno fino a 20 punti bonus.","O ouro vale 100 pontos da academia por aula; resultados excepcionais rendem at\xe9 20 pontos b\xf4nus.","\u30b4\u30fc\u30eb\u30c9\u306f1\u30ec\u30c3\u30b9\u30f3100\u70b9\u3002\u512a\u79c0\u306a\u30b9\u30b3\u30a2\u306b\u306f\u6700\u592720\u70b9\u306e\u30dc\u30fc\u30ca\u30b9\u304c\u3042\u308a\u307e\u3059\u3002"],t.s)
A.qM=s(["Versuche","intentos","tentatives","tentativi","tentativas","\u6311\u6226"],t.s)
A.wQ=s(["Sch\xfcler","Estudiante","\xc9l\xe8ve","Studente","Aluno","\u751f\u5f92"],t.s)
A.rF=s(["Drachenakademie-Abbrecher","Desertor de la Academia de Dragones","Dragon d\xe9crocheur","Drago che ha lasciato l\u2019accademia","Desistente da Academia de Drag\xf5es","\u30c9\u30e9\u30b4\u30f3\u30a2\u30ab\u30c7\u30df\u30fc\u4e2d\u9000"],t.s)
A.uA=s(["Absolvent","Graduado","Dipl\xf4m\xe9","Diplomato","Formado","\u5352\u696d\u751f"],t.s)
A.lb=s(["Abschluss mit Auszeichnung","Graduado con honores","Dipl\xf4m\xe9 avec mention","Diplomato con lode","Formado com honras","\u512a\u7b49\u5352\u696d"],t.s)
A.zS=s(["Abschluss mit h\xf6chster Auszeichnung","M\xe1ximos honores","Tr\xe8s grande distinction","Massimi onori","Honras m\xe1ximas","\u6700\u512a\u7b49"],t.s)
A.jY=s(["Jahrgangsbester","Mejor estudiante de la promoci\xf3n","Major de promotion","Migliore del corso","Melhor da turma","\u9996\u5e2d\u5352\u696d\u751f"],t.s)
A.Ih=s(["Bestwert behalten","Mejor marca conservada","Meilleur r\xe9sultat conserv\xe9","Record conservato","Melhor resultado mantido","\u30d9\u30b9\u30c8\u3092\u7dad\u6301"],t.s)
A.pE=s(["N\xe4chsten Versuch nutzen","Usar el siguiente intento","Utiliser la tentative suivante","Usa il tentativo successivo","Usar pr\xf3xima tentativa","\u6b21\u306e\u6311\u6226\u3092\u4f7f\u3046"],t.s)
A.pS=s(["Alle 3 Versuche verbraucht","Se usaron los 3 intentos","Les 3 tentatives sont utilis\xe9es","Tutti e 3 i tentativi usati","As 3 tentativas foram usadas","3\u56de\u306e\u6311\u6226\u3092\u3059\u3079\u3066\u4f7f\u7528\u6e08\u307f"],t.s)
A.zC=s(["Abschlusszeugnis fertig. Diplom erhalten!","Informe final completo. \xa1Diploma obtenido!","Rapport final termin\xe9. Dipl\xf4me obtenu !","Rapporto finale completato. Diploma ottenuto!","Relat\xf3rio final conclu\xeddo. Diploma conquistado!","\u6700\u7d42\u6210\u7e3e\u8868\u304c\u5b8c\u6210\u3002\u5352\u696d\u8a3c\u66f8\u3092\u7372\u5f97\uff01"],t.s)
A.Lt=s(["Abschlusszeugnis fertig. Diesmal kein Diplom, aber die Geschichte ist es wert, festgehalten zu werden.","Informe final completo. Esta vez no hay diploma, pero la historia merece quedar registrada.","Rapport final termin\xe9. Pas de dipl\xf4me cette fois, mais cette histoire m\xe9rite d\u2019\xeatre conserv\xe9e.","Rapporto finale completato. Niente diploma stavolta, ma la storia merita di essere ricordata.","Relat\xf3rio final conclu\xeddo. Sem diploma desta vez, mas a hist\xf3ria merece ser registrada.","\u6700\u7d42\u6210\u7e3e\u8868\u304c\u5b8c\u6210\u3002\u4eca\u56de\u306f\u5352\u696d\u3067\u304d\u306a\u304f\u3066\u3082\u3001\u3053\u306e\u7269\u8a9e\u306f\u8a18\u9332\u306b\u6b8b\u308a\u307e\u3059\u3002"],t.s)
A.C8=s(["Nicht genug geeignete Drachen. Jeder Sch\xfcler hat drei Versuche pro Lektion.","No hay suficientes dragones aptos. Cada alumno tiene tres intentos por lecci\xf3n.","Pas assez de dragons admissibles. Chaque \xe9l\xe8ve a trois tentatives par le\xe7on.","Non ci sono abbastanza draghi idonei. Ogni allievo ha tre tentativi per lezione.","N\xe3o h\xe1 drag\xf5es eleg\xedveis suficientes. Cada aluno tem tr\xeas tentativas por aula.","\u53c2\u52a0\u3067\u304d\u308b\u30c9\u30e9\u30b4\u30f3\u304c\u8db3\u308a\u307e\u305b\u3093\u3002\u5404\u751f\u5f92\u306f1\u30ec\u30c3\u30b9\u30f3\u306b\u3064\u304d3\u56de\u6311\u6226\u3067\u304d\u307e\u3059\u3002"],t.s)
A.tP=s(["Jeder Sch\xfcler hat drei offizielle Versuche pro Lektion. Die besten Ergebnisse bestimmen Diplom und Rang.","Cada alumno tiene tres intentos oficiales por lecci\xf3n. Sus mejores resultados deciden el diploma y la clasificaci\xf3n.","Chaque \xe9l\xe8ve a trois tentatives officielles par le\xe7on. Ses meilleurs r\xe9sultats d\xe9terminent le dipl\xf4me et le classement.","Ogni allievo ha tre tentativi ufficiali per lezione. I risultati migliori decidono diploma e classifica.","Cada aluno tem tr\xeas tentativas oficiais por aula. Os melhores resultados definem diploma e classifica\xe7\xe3o.","\u5404\u751f\u5f92\u306f1\u30ec\u30c3\u30b9\u30f3\u306b\u3064\u304d\u516c\u5f0f\u6311\u6226\u304c3\u56de\u3042\u308a\u307e\u3059\u3002\u6700\u9ad8\u6210\u7e3e\u3067\u5352\u696d\u7d50\u679c\u3068\u9806\u4f4d\u304c\u6c7a\u307e\u308a\u307e\u3059\u3002"],t.s)
A.DL=s(["3 Versuche pro Lektion","3 intentos por lecci\xf3n","3 tentatives par le\xe7on","3 tentativi per lezione","3 tentativas por aula","1\u30ec\u30c3\u30b9\u30f33\u56de"],t.s)
A.tM=s(["15 Sterne: Abschluss \xb7 21: Auszeichnung \xb7 27: h\xf6chste Auszeichnung \xb7 30: Jahrgangsbester. Unter 15: Abbrecher.","15 estrellas: Graduado \xb7 21: Honores \xb7 27: M\xe1ximos honores \xb7 30: Mejor de la promoci\xf3n. Menos de 15: Desertor.","15 \xe9toiles : Dipl\xf4m\xe9 \xb7 21 : Mention \xb7 27 : Grande distinction \xb7 30 : Major. Moins de 15 : D\xe9crocheur.","15 stelle: Diplomato \xb7 21: Lode \xb7 27: Massimi onori \xb7 30: Migliore del corso. Sotto 15: Ritirato.","15 estrelas: Formado \xb7 21: Honras \xb7 27: Honras m\xe1ximas \xb7 30: Melhor da turma. Abaixo de 15: Desistente.","15\u661f: \u5352\u696d \xb7 21: \u512a\u7b49 \xb7 27: \u6700\u512a\u7b49 \xb7 30: \u9996\u5e2d\u300215\u672a\u6e80\u306f\u4e2d\u9000\u3067\u3059\u3002"],t.s)
A.yr=s(["Jeder ausgew\xe4hlte Sch\xfcler hat alle drei Versuche f\xfcr diese Lektion verbraucht.","Todos los alumnos seleccionados han usado sus tres intentos para esta lecci\xf3n.","Chaque \xe9l\xe8ve s\xe9lectionn\xe9 a utilis\xe9 ses trois tentatives pour cette le\xe7on.","Ogni allievo selezionato ha usato tutti e tre i tentativi per questa lezione.","Todos os alunos selecionados usaram as tr\xeas tentativas desta aula.","\u9078\u629e\u3057\u305f\u751f\u5f92\u306f\u5168\u54e1\u3001\u3053\u306e\u30ec\u30c3\u30b9\u30f3\u306e3\u56de\u306e\u6311\u6226\u3092\u4f7f\u3044\u5207\u308a\u307e\u3057\u305f\u3002"],t.s)
A.Mj=new B.u(A.Oz,[A.tc,A.EP,A.Bk,A.Ij,A.Kh,A.ug,A.k7,A.KG,A.us,A.rt,A.ys,A.Jh,A.C9,A.nX,A.Be,A.wL,A.Hh,A.u_,A.ue,A.qs,A.Ko,A.oq,A.Fy,A.xt,A.lJ,A.qT,A.mo,A.F_,A.yJ,A.Ca,A.C1,A.pw,A.rP,A.zZ,A.Ls,A.mP,A.E8,A.Ar,A.x_,A.L7,A.IM,A.D8,A.oK,A.G9,A.ny,A.G6,A.Kf,A.oS,A.zY,A.y6,A.Gs,A.pg,A.C4,A.w9,A.ur,A.A8,A.ye,A.jK,A.nU,A.pr,A.KH,A.DG,A.lv,A.nK,A.E5,A.qC,A.Hr,A.Kc,A.lx,A.CK,A.xm,A.n5,A.k2,A.qN,A.B7,A.qU,A.Hf,A.vR,A.nD,A.mi,A.An,A.F3,A.v9,A.HC,A.DJ,A.CS,A.ya,A.uq,A.K7,A.FY,A.Lf,A.AY,A.x4,A.wn,A.GL,A.w1,A.DI,A.rY,A.L9,A.DM,A.tF,A.KR,A.nV,A.tp,A.og,A.ph,A.By,A.HY,A.H3,A.xW,A.vC,A.qM,A.wQ,A.rF,A.uA,A.lb,A.zS,A.jY,A.Ih,A.pE,A.pS,A.zC,A.Lt,A.C8,A.tP,A.DL,A.tM,A.yr],t.M)
A.O0={"Highlighted for this path":0,"Available dragons":1,Highlighted:2,"Highlighted for training":3,"Tap an Expertise to highlight it for training.":4,"TEST EVENT \xb7 TRIAL COMPLETE":5,Male:6,Female:7,"Test event \xb7 ":8,"Ends in":9,"Choose an Adventure and a dragon. Matching Expertise shortens the journey; tap the i beside a dragon\u2019s score to compare Might, Arcana and Spirit and see your highlights. The compact Draconomicon shortcut keeps your place in the picker. Active Adventures show the shortest remaining journey first. Aborting a solo journey gives no rewards.":10,"Join friends in a Group Adventure: the party starts when every place is filled and the combined requirements are met. Event Adventures remain finishable if started in time. Test Event Adventures and their Special Chests only preview rewards. Test Event Trials do give their normal permanent rewards; their event rankings stay separate.":11,"In My Dragons, open a dragon and tap one or more Expertise rows to highlight them for training; tap again to clear. Matching dragons appear under Highlighted for this path in Adventures and Trials. Train Expertise through Adventures, Trials and Academy lessons. Evolution choices raise different Expertise maximums; MAX always follows the correct dragon, form and Ascension cap.":12}
A.vI=s(["F\xfcr diesen Weg markiert","Destacados para esta ruta","Mis en \xe9vidence pour cette voie","In evidenza per questo percorso","Destacados para este caminho","\u3053\u306e\u9053\u306e\u80b2\u6210\u5bfe\u8c61"],t.s)
A.HO=s(["Verf\xfcgbare Drachen","Dragones disponibles","Dragons disponibles","Draghi disponibili","Drag\xf5es dispon\xedveis","\u9078\u3079\u308b\u30c9\u30e9\u30b4\u30f3"],t.s)
A.lA=s(["Markiert","Destacado","Mis en \xe9vidence","In evidenza","Destacado","\u80b2\u6210\u5bfe\u8c61"],t.s)
A.vr=s(["Zum Training markiert","Destacado para entrenar","Mis en \xe9vidence pour l\u2019entra\xeenement","In evidenza per l\u2019allenamento","Destacado para treinar","\u80b2\u6210\u5bfe\u8c61\u306b\u8a2d\u5b9a\u6e08\u307f"],t.s)
A.ow=s(["Tippe auf eine Expertise, um sie zum Training zu markieren.","Toca una especialidad para destacarla y entrenarla.","Touchez une expertise pour la mettre en \xe9vidence pour l\u2019entra\xeenement.","Tocca una competenza per metterla in evidenza per l\u2019allenamento.","Toca numa especialidade para a destacar para treino.","\u80b2\u6210\u3057\u305f\u3044\u5c02\u9580\u80fd\u529b\u3092\u30bf\u30c3\u30d7\u3057\u3066\u9078\u629e\u3057\u307e\u3059\u3002"],t.s)
A.vw=s(["TESTEVENT \xb7 PR\xdcFUNG ABGESCHLOSSEN","EVENTO DE PRUEBA \xb7 PRUEBA COMPLETADA","\xc9V\xc9NEMENT TEST \xb7 \xc9PREUVE TERMIN\xc9E","EVENTO DI TEST \xb7 PROVA COMPLETATA","EVENTO DE TESTE \xb7 PROVA CONCLU\xcdDA","\u30c6\u30b9\u30c8\u30a4\u30d9\u30f3\u30c8 \xb7 \u8a66\u7df4\u30af\u30ea\u30a2"],t.s)
A.r8=s(["M\xe4nnlich","Macho","M\xe2le","Maschio","Macho","\u30aa\u30b9"],t.s)
A.Gv=s(["Weiblich","Hembra","Femelle","Femmina","F\xeamea","\u30e1\u30b9"],t.s)
A.B0=s(["Testevent \xb7 ","Evento de prueba \xb7 ","\xc9v\xe9nement test \xb7 ","Evento di test \xb7 ","Evento de teste \xb7 ","\u30c6\u30b9\u30c8\u30a4\u30d9\u30f3\u30c8 \xb7 "],t.s)
A.xl=s(["Endet in","Termina en","Fin dans","Termina tra","Termina em","\u7d42\u4e86\u307e\u3067"],t.s)
A.oX=s(["W\xe4hle ein Abenteuer und einen Drachen. Passende Expertise verk\xfcrzt die Reise. Tippe auf das i neben seinem Wert, um Might, Arcana, Spirit und deine Markierungen zu sehen. Der kompakte Draconomicon-Knopf bewahrt deine Position in der Auswahl. Aktive Abenteuer zeigen die k\xfcrzeste Restdauer zuerst. Abgebrochene Soloreisen geben keine Belohnung.","Elige una aventura y un drag\xf3n. La especialidad adecuada acorta el viaje; toca la i junto a su puntuaci\xf3n para comparar Might, Arcana y Spirit y ver tus destacados. El acceso compacto al Draconomicon conserva tu lugar en la selecci\xf3n. Las aventuras activas muestran primero el viaje con menos tiempo restante. Cancelar un viaje individual no da recompensas.","Choisissez une aventure et un dragon. L\u2019expertise adapt\xe9e raccourcit le voyage ; touchez le i pr\xe8s de son score pour comparer Might, Arcana et Spirit et voir vos choix mis en \xe9vidence. Le raccourci compact du Draconomicon conserve votre place dans la s\xe9lection. Les aventures actives affichent d\u2019abord le temps restant le plus court. Annuler un voyage solo ne donne aucune r\xe9compense.","Scegli un\u2019avventura e un drago. La competenza adatta accorcia il viaggio; tocca la i accanto al punteggio per confrontare Might, Arcana e Spirit e vedere le tue scelte in evidenza. La scorciatoia compatta del Draconomicon conserva la posizione nella selezione. Le avventure attive mostrano prima quelle con meno tempo rimanente. Annullare un viaggio in solitaria non d\xe0 ricompense.","Escolhe uma aventura e um drag\xe3o. A especialidade adequada encurta a viagem; toca no i junto \xe0 pontua\xe7\xe3o para comparar Might, Arcana e Spirit e ver os teus destaques. O atalho compacto do Draconomicon mant\xe9m a tua posi\xe7\xe3o na sele\xe7\xe3o. As aventuras ativas mostram primeiro a viagem com menos tempo restante. Cancelar uma viagem a solo n\xe3o d\xe1 recompensas.","\u5192\u967a\u3068\u30c9\u30e9\u30b4\u30f3\u3092\u9078\u3073\u307e\u3057\u3087\u3046\u3002\u9069\u3057\u305f\u5c02\u9580\u80fd\u529b\u304c\u9ad8\u3044\u307b\u3069\u65c5\u304c\u77ed\u304f\u306a\u308a\u307e\u3059\u3002\u6570\u5024\u306e\u6a2a\u306ei\u3092\u30bf\u30c3\u30d7\u3059\u308b\u3068Might\u30fbArcana\u30fbSpirit\u3068\u80b2\u6210\u5bfe\u8c61\u3092\u78ba\u8a8d\u3067\u304d\u307e\u3059\u3002\u5c0f\u3055\u306aDraconomicon\u30dc\u30bf\u30f3\u304b\u3089\u56f3\u9451\u3092\u958b\u3044\u3066\u3082\u9078\u629e\u753b\u9762\u306e\u4f4d\u7f6e\u306f\u4fdd\u305f\u308c\u307e\u3059\u3002\u9032\u884c\u4e2d\u306e\u5192\u967a\u306f\u6b8b\u308a\u6642\u9593\u306e\u77ed\u3044\u9806\u306b\u8868\u793a\u3055\u308c\u307e\u3059\u3002\u5358\u72ec\u306e\u65c5\u3092\u4e2d\u6b62\u3059\u308b\u3068\u5831\u916c\u306f\u5f97\u3089\u308c\u307e\u305b\u3093\u3002"],t.s)
A.I0=s(["Nimm mit Freunden an einem Gruppenabenteuer teil: Die Gruppe startet, sobald alle Pl\xe4tze besetzt und die gemeinsamen Anforderungen erf\xfcllt sind. Rechtzeitig gestartete Event-Abenteuer k\xf6nnen sp\xe4ter beendet werden. Test-Event-Abenteuer und ihre Spezialtruhen zeigen Belohnungen nur als Vorschau. Test-Event-Pr\xfcfungen vergeben ihre normalen dauerhaften Belohnungen; ihre Event-Ranglisten bleiben getrennt.","\xdanete a una aventura de grupo con amigos: la partida comienza cuando se llenan las plazas y se cumplen los requisitos conjuntos. Las aventuras de evento iniciadas a tiempo pueden terminarse despu\xe9s. Las aventuras de eventos de prueba y sus cofres especiales solo muestran las recompensas. Sus Trials s\xed dan las recompensas normales permanentes; sus clasificaciones de evento siguen separadas.","Rejoignez une aventure de groupe avec vos amis : le d\xe9part a lieu quand toutes les places sont prises et les conditions communes remplies. Une aventure d\u2019\xe9v\xe9nement commenc\xe9e \xe0 temps peut \xeatre termin\xe9e plus tard. Les aventures d\u2019\xe9v\xe9nements test et leurs coffres sp\xe9ciaux ne font que montrer les r\xe9compenses. Leurs \xe9preuves donnent bien les r\xe9compenses permanentes normales ; leurs classements d\u2019\xe9v\xe9nement restent s\xe9par\xe9s.","Partecipa a un\u2019avventura di gruppo con gli amici: si parte quando tutti i posti sono occupati e i requisiti comuni sono soddisfatti. Le avventure evento iniziate in tempo possono essere completate dopo. Le avventure degli eventi di test e i relativi forzieri speciali mostrano soltanto le ricompense. Le prove degli eventi di test assegnano invece le normali ricompense permanenti; le classifiche evento restano separate.","Participa numa aventura de grupo com amigos: a equipa parte quando todos os lugares est\xe3o ocupados e os requisitos conjuntos s\xe3o cumpridos. As aventuras de evento iniciadas a tempo podem ser conclu\xeddas depois. As aventuras dos eventos de teste e os seus ba\xfas especiais apenas mostram as recompensas. As provas de eventos de teste d\xe3o as recompensas normais permanentes; as classifica\xe7\xf5es de evento continuam separadas.","\u53cb\u9054\u3068\u30b0\u30eb\u30fc\u30d7\u5192\u967a\u306b\u53c2\u52a0\u3057\u307e\u3057\u3087\u3046\u3002\u5168\u54e1\u304c\u305d\u308d\u3044\u3001\u5408\u8a08\u6761\u4ef6\u3092\u6e80\u305f\u3059\u3068\u51fa\u767a\u3057\u307e\u3059\u3002\u30a4\u30d9\u30f3\u30c8\u5192\u967a\u306f\u671f\u9593\u5185\u306b\u958b\u59cb\u3059\u308c\u3070\u7d42\u4e86\u5f8c\u3082\u5b8c\u4e86\u3067\u304d\u307e\u3059\u3002\u30c6\u30b9\u30c8\u30a4\u30d9\u30f3\u30c8\u306e\u5192\u967a\u3068\u7279\u5225\u306a\u5b9d\u7bb1\u306f\u5831\u916c\u306e\u30d7\u30ec\u30d3\u30e5\u30fc\u306e\u307f\u3067\u3059\u3002\u30c6\u30b9\u30c8\u30a4\u30d9\u30f3\u30c8\u306e\u8a66\u7df4\u3067\u306f\u901a\u5e38\u306e\u5831\u916c\u304c\u5b9f\u969b\u306b\u4ed8\u4e0e\u3055\u308c\u307e\u3059\u3002\u30a4\u30d9\u30f3\u30c8\u30e9\u30f3\u30ad\u30f3\u30b0\u306f\u672c\u756a\u3068\u5225\u306b\u8a18\u9332\u3055\u308c\u307e\u3059\u3002"],t.s)
A.I4=s(["\xd6ffne unter Meine Drachen einen Drachen und tippe auf eine oder mehrere Expertise-Zeilen, um sie zum Training zu markieren. Erneutes Tippen entfernt die Markierung. Passende Drachen erscheinen in Abenteuern und Pr\xfcfungen unter F\xfcr diesen Weg markiert. Trainiere Expertise durch Abenteuer, Pr\xfcfungen und Akademie-Lektionen. Evolutionen erh\xf6hen unterschiedliche H\xf6chstwerte; MAX ber\xfccksichtigt immer Drachen, Form und Aufstiegslimit.","Abre un drag\xf3n en Mis dragones y toca una o varias especialidades para destacarlas y entrenarlas; vuelve a tocar para quitarlas. Los dragones adecuados aparecen en Destacados para esta ruta en aventuras y Trials. Entrena con aventuras, Trials y clases de la academia. La evoluci\xf3n aumenta distintos m\xe1ximos; MAX siempre respeta el drag\xf3n, la forma y el l\xedmite de ascensi\xf3n.","Dans Mes dragons, ouvrez un dragon et touchez une ou plusieurs expertises pour les mettre en \xe9vidence pour l\u2019entra\xeenement ; touchez \xe0 nouveau pour annuler. Les dragons adapt\xe9s apparaissent sous Mis en \xe9vidence pour cette voie dans les aventures et \xe9preuves. Entra\xeenez les expertises avec les aventures, \xe9preuves et le\xe7ons de l\u2019acad\xe9mie. Les \xe9volutions augmentent diff\xe9rents plafonds ; MAX respecte toujours le dragon, sa forme et sa limite d\u2019ascension.","In I miei draghi, apri un drago e tocca una o pi\xf9 competenze per metterle in evidenza per l\u2019allenamento; tocca di nuovo per annullare. I draghi adatti appaiono in In evidenza per questo percorso nelle avventure e nelle prove. Allena le competenze con avventure, prove e lezioni dell\u2019accademia. Le evoluzioni aumentano massimi diversi; MAX rispetta sempre il drago, la forma e il limite di ascensione.","Em Os meus drag\xf5es, abre um drag\xe3o e toca numa ou mais especialidades para as destacar para treino; toca novamente para limpar. Os drag\xf5es adequados aparecem em Destacados para este caminho nas aventuras e provas. Treina especialidades com aventuras, provas e aulas da academia. As evolu\xe7\xf5es aumentam m\xe1ximos diferentes; MAX respeita sempre o drag\xe3o, a forma e o limite de ascens\xe3o.","\u300c\u30de\u30a4\u30c9\u30e9\u30b4\u30f3\u300d\u3067\u30c9\u30e9\u30b4\u30f3\u3092\u958b\u304d\u3001\u80b2\u6210\u3057\u305f\u3044\u5c02\u9580\u80fd\u529b\u30921\u3064\u4ee5\u4e0a\u30bf\u30c3\u30d7\u3057\u307e\u3059\u3002\u3082\u3046\u4e00\u5ea6\u30bf\u30c3\u30d7\u3059\u308b\u3068\u89e3\u9664\u3067\u304d\u307e\u3059\u3002\u8a72\u5f53\u3059\u308b\u30c9\u30e9\u30b4\u30f3\u306f\u5192\u967a\u3084\u8a66\u7df4\u306e\u300c\u3053\u306e\u9053\u306e\u80b2\u6210\u5bfe\u8c61\u300d\u306b\u8868\u793a\u3055\u308c\u307e\u3059\u3002\u5c02\u9580\u80fd\u529b\u306f\u5192\u967a\u30fb\u8a66\u7df4\u30fb\u30a2\u30ab\u30c7\u30df\u30fc\u3067\u935b\u3048\u3089\u308c\u307e\u3059\u3002\u9032\u5316\u306b\u3088\u3063\u3066\u4e0a\u9650\u304c\u5909\u308f\u308a\u3001MAX\u306f\u30c9\u30e9\u30b4\u30f3\u30fb\u5f62\u614b\u30fb\u6607\u5929\u306e\u4e0a\u9650\u306b\u5f93\u3044\u307e\u3059\u3002"],t.s)
A.Mk=new B.u(A.O0,[A.vI,A.HO,A.lA,A.vr,A.ow,A.vw,A.r8,A.Gv,A.B0,A.xl,A.oX,A.I0,A.I4],t.M)
A.Op={"Backup history":0,"View cloud":1,"Replace cloud":2,"Replace cloud progress?":3,"The current cloud progress will be replaced by this device. The previous cloud revision remains recoverable for up to thirty days.":4,"Cloud progress replaced safely.":5,"No cloud backup history is available.":6,"Up to five cloud revisions are kept for thirty days.":7,Revision:8,Current:9,"App version":10,"Save schema":11,"Restore this revision?":12,"Your local progress will be replaced by this cloud revision. A local recovery copy is kept.":13,"Restore revision":14,"Delete account":15,"Delete online account?":16,"This permanently deletes your online profile, friends, trades and cloud backup. Your current offline save stays on this device.":17,"Confirm password":18,"Delete permanently":19,"Online account deleted.":20,"Account deletion failed. Check your password and connection.":21,"New friend request":22,"{name} wants to be friends.":23,"Friend request accepted":24,"{name} is now in your friends list.":25,"New trade offer":26,"{name} wants to trade an item with you.":27,"Return item offered":28,"{name} offered an item. Confirm the trade.":29,"Your trade with {name} completed safely.":30,"Cloud backup":31,"Cloud backup revision":32,"Keep a versioned copy of this device's progress online.":33,"Back up":34,Restore:35,"Back up progress?":36,"This stores the current progress from this device in your online account. An older cloud backup will be replaced.":37,"Cloud backup saved.":38,"Cloud backup failed. Refresh and try again.":39,"Restore cloud progress?":40,"Your current local progress will be replaced by the latest cloud backup. A local recovery copy is kept.":41,"Cloud progress restored.":42,"No usable cloud backup was found.":43,"Three Trials are ready":44,[u.D]:45,"Android notifications are off for DragonHaven.":46,"Open settings":47,Notifications:48,"Choose which reminders you receive":49,"Music \xb7 R\xeaverie":50,OPEN:51,TRADE:52,"Trade needs your answer":53,"Open active trade":54,"Your reserved exchange is ready to view.":55,"Choose an egg, chest or relic for a safe exchange.":56,"Choose what may call you back":57,"Everything is enabled by default. You remain in control of every reminder.":58,"Eggs ready to hatch":59,"When an egg in the Rooftop Nest is ready.":60,Achievements:61,"When you unlock a new achievement.":62,"Dragon evolutions":63,"When one of your dragons reaches a new form.":64,"When another keeper sends you a request.":65,"Friend acceptances":66,"When your friend request is accepted.":67,"Trade proposals":68,"When a friend starts a trade with you.":69,"Trade return items":70,"When the other keeper offers their item.":71,"Completed trades":72,"When a trade has safely completed.":73,"Three Trials available":74,"When your Trial board reaches 3/3.":75,"Allow precise timing":76,"Android may delay timed reminders until Alarms & reminders is allowed.":77,Allow:78,"This dragon is currently away on an Adventure.":79,Jukebox:80,"Background music":81,"Portrait Chests cost 100 gems in the Shop and always reveal a portrait you do not own yet.":82,"Abort adventure":83,"Abort adventure?":84,"Keep going":85,Abort:86,"Adventure aborted. Your dragon is available again.":87,Mastery:88,"Filter dragons":89,"No dragons match these filters.":90,Clear:91,Form:92,"Spectral only":93,"Show dragons":94,"Unequip Twinstar Brooch":95,"Equip Twinstar Brooch":96,"Move Twinstar Brooch here":97,"Doubles all XP while equipped":98,"This dragon leaves your collection and cannot be trained. Its identity, form, alignment and hidden personality are preserved. Each day it has a 10% chance to return at a random time.":99,"Hatch time":100,"Show list":101,"Show tiles":102," \xb7 Reserved":103,"Reveal rarity with Astral Lens":104,"Music collection complete":105,"You already own every song. This Music Chest stays safely in your Inventory and cannot be opened.":106,Type:107,Beds:108,Plants:109,Lights:110,"No furniture matches these filters.":111,"Filter furniture":112,"Placed only":113,"Show furniture":114,"Not equipped":115,"Equipped to a dragon":116,"Egg in rooftop nest":117,"Inventory egg":118,"There is no egg with an unknown rarity.":119,"Reveal which egg?":120,"Rarity is still hidden":121,"Rarity revealed":122,Done:123,"Place an egg in the rooftop nest first.":124,"Choose a Chronoshard":125,"Its percentage was fixed when this relic was found.":126,"Shorten remaining incubation":127,"Choose Adventure type":128,"Use Wayfinder Sigil":129,"Create an extra Adventure":130,"Reroll this Adventure":131,"The Adventure choices have changed.":132,"Twinstar Brooch":133,"Only its current wearer receives double XP.":134,Unequip:135,Shuffle:136,Repeat:137,"Shuffle changes the order. Repeat starts a new full cycle after every selected track has played.":138,"No tracks selected":139,"Background music stays silent until you enable a track.":140,"Your music":141,"This Relic is not available in the shop.":142,"Contains one random song you do not own. Its contents are decided only when opened.":143,"Music Chest added to your Inventory.":144,"Every song is already owned or covered by an unopened Music Chest.":145,"SCORING TURNS LEFT":146,"Misses left":147,"Added to your Jukebox":148,"The online service took too long. Your local game is safe; please try again.":149,"Your online session expired. Sign in again.":150,"Astral Lens":151,Chronoshard:152,"Wayfinder Sigil":153,"Reveals only the hidden rarity of one unhatched dragon egg.":154,"Shortens the remaining incubation time of the egg in the nest by its fixed percentage.":155,"Rerolls one chosen adventure or creates a new adventure of a chosen type when space is available.":156,"A unique equipable relic that doubles all experience received only while its chosen dragon wears it.":157,"Copy support diagnostics":158,"Contains technical IDs and timings, never your password, e-mail or game save.":159,"Support diagnostics copied. Only share them with trusted DragonHaven support.":160,"Different cloud progress found":161,"Keep local for now":162,"Restore cloud":163,"Cloud progress restored. A local recovery copy was kept.":164,"Newer or different cloud progress was found. Nothing was overwritten.":165,"No cloud backup is available yet.":166,"The cloud backup could not be validated. Your local game is unchanged.":167,"This backup is too large for the online service. Your local game is safe.":168,"Support code":169,"Update available":170,"A newer version of DragonHaven is ready.":171,"Installed version":172,"Latest version":173,Later:174,"Start trade":175,"Collapse records":176,"Expand records":177,"TRADE COMPLETE!":178,"The exchange is safely sealed.":179,"YOU SENT":180,"YOU RECEIVED":181,"Cancel group":182,"Cancel this group?":183,Confirm:184,"Create group":185,"Friends looking for dragons":186,"Group Adventures are only available to verified online accounts.":187,"Group created. Friends can now join.":188,"Join with a dragon":189,"Only friends of the group starter can join.":190,Participants:191,"Remove dragon":192,"Rewards are ready":193,"Sign in for Group Adventures":194,"The dragon was removed from the group.":195,"The group has returned.":196,"The journey starts automatically when all requirements are met.":197,"The reward could not be linked to your local dragon.":198,"These Group Adventure rewards are not ready yet.":199,"This dragon is already reserved for a Group Adventure.":200,"This group has already started or expired.":201,"This group is full.":202,"This is only possible before the adventure starts.":203,Withdraw:204,"Withdraw from this group?":205,"You already used this weekly Group Adventure.":206,"You have already completed this week's Group Adventure.":207,"Your current weekly Group Adventure is reserved. Its lobby or journey stays under Active, then moves to Completed when rewards are ready.":208,"Your current weekly Group Adventure is reserved. Its lobby or run is shown under Active.":209,"Your dragon":210,"Your dragon joined the group.":211,"Your dragon left the group.":212,"Your offline name, portrait and title are used automatically online.":213,combined:214,"combined level":215,dragons:216,participants:217,"Confirm your email before signing in.":218,"Create a verified account to add friends by Keeper ID. You must confirm your email before signing in, and it is never shown to other players.":219,"A Mysterious Egg appeared in the tower nest.":220,"A chest was opened.":221,"A dragon evolved.":222,"A dragon hatched!":223,"A familiar shadow returned":224,"A global weekly expedition refreshes on Sunday at 12:00 Europe/Amsterdam. Online friends are required.":225,"A new form awakens!":226,"A new form is awakening\u2026":227,"A quiet tower. A mysterious egg. A collection waiting to become legend.":228,"A rare Tower moment":229,"A sanctuary activity was completed.":230,"A secret life is waiting inside one familiar shell.":231,"A soft glow fills every wellbeing bar.":232,"ABOUT THE GAME":233,"About DragonHaven":234,"Achievement unlocked!":235,"Activate egg":236,"Active expeditions":237,"Add a keeper":238,"Adventure rewards will appear here and on Adventure.":239,"Adventure rewards are stored here.":240,"Adventure started.":241,Adventuring:242,All:243,"An egg cannot go adventuring.":244,"Android download link copied.":245,Update:246,"Arcana is currently leading.":247,"Archived permanently; every day it has a 10% chance to return at a random time.":248,"Ascension complete":249,"Ascension paths":250,Ascended:251,Audio:252,"Begin hatching":253,"Both keepers must offer at least one egg, chest or item and confirm the final trade.":254,"Both settings react immediately and are stored independently for this local account.":255,"Build a home that grows with your dragon.":256,"Build room":257,"Built and ready":258,"Built in":259,"Buy gems":260,"Buy me a coffee":261,Cancel:262,Chests:263,"Choose a name":264,"Choose a name first.":265,"Choose a room type":266,"Claim the Starter Egg":267,"Clear search":268,"Cloud Sanctuary":269,"Dragon Chest":270,"Coin furniture":271,Collect:272,"Collect furniture for every dragon room.":273,Comfort:274,Common:275,"Compact view":276,"Connect online friends before joining a Group Adventure.":277,"Copy download link":278,"Copy one permanent Android download link for someone else, or open it to install the latest release over this app. Your progress stays safe.":279,"Created by":280,"Crystal Grotto":281,Curious:282,Decorate:283,Discard:284,"Discard egg":285,"Discard one chest":286,"Discard this Mysterious Egg?":287,Dismiss:288,"Download or update":289,"Dragon care":290,"Dragon keeper":291,"Dragon name":292,"Dragon room":293,"Dragon sanctuary":294,"DragonHaven logo":295,"EDIT MODE":296,"Each room is permanent and can be decorated independently.":297,"Edit keeper name":298,"Edit name":299,Egg:300,"Egg moved to the rooftop nest.":301,"Egg inventory":302,Eggs:303,Energy:304,"Enjoying DragonHaven? You can support its further development through Ko-fi.":305,"Event, code and returning-dragon adventures stay available for 48 hours.":306,"Evolve now":307,"Expand the sanctuary":308,Finish:309,"For example: Ember":310,"For example: Rick":311,Furniture:312,"Gem furniture":313,"Gold Chest":314,"GitHub returned unexpected release data.":315,"Good afternoon":316,"Good evening":317,"Good morning":318,Greenery:319,Group:320,HERE:321,"Hearth room":322,Hatchling:323,"Hidden chest":324,"House inventory":325,"House item":326,"House shop":327,INVENTORY:328,"In Tower":329,Incubate:330,"Its unopened contents will be lost.":331,Joy:332,"Keep this name":333,"Ko-fi could not be opened or copied.":334,"Ko-fi could not be opened. The link was copied instead.":335,"List view":336,"Listen to the mysterious egg":337,Long:338,Magic:339,"Maximum height reached":340,"Might is currently leading.":341,"Moon garden":342,"My dragons":343,"Mysterious Egg":344,"Mythical Chest":345,"New evolution!":346,"Name your dragon":347,"Nest room":348,"No Mysterious Eggs in your inventory yet.":349,"No internet connection. Please try again later.":350,"No public GitHub Release has been published yet.":351,"No waiting eggs. Rare chest drops will appear here.":352,"Not enough coins for this floor.":353,"Not ready yet":354,"Not yet":355,"OTHER ROOM":356,"Open tip form":357,"Opening the latest DragonHaven download\u2026":358,Open:359,"Payment via PayPal":360,Place:361,Placed:362,"Possible hatchling":363,"Purchased items are always yours.":364,"Purchases are disabled until Google Play product IDs and server-side receipt validation are configured.":365,Raise:366,"Raise this egg?":367,"Raise wonder. Build a home. Fill the Draconomicon.":368,Rare:369,"Read-only visits can show the favorite dragon, rooms and achievements\u2014including locked ??? secrets.":370,Ready:371,"Ready to hatch":372,Redeem:373,"Redeem code":374,Release:375,"Release dragon\u2026":376,Remove:377,"Remove favorite":378,"Remove permanently":379,Repair:380,"Return to inventory":381,"Rooftop Nest":382,Rooms:383,"Search house items":384,"Search by a stable player code; names are never treated as unique IDs.":385,"Synced with your offline profile":386,"Secret achievement":387,"Silver Chest":388,"Sinister Chest":389,"Select an item, then tap its new place in the room.":390,"Set as favorite":391,"Share or update DragonHaven":392,Shop:393,Mini:394,Wood:395,Short:396,"Something useful was discovered in the Spire.":397,Special:398,Dragons:399,Spectral:400,"Spirit is currently leading.":401,"Star loft":402,"Starlight Treat \xb7 3 gems":403,Start:404,Sunforge:405,"Talk to":406,"Tap the chest":407,"A tower treasure awaits":408,"Treasure claimed":409,"TAP TO CALL YOUR DRAGON":410,"TAP TO MOVE YOUR DRAGON":411,"That dragon is already away.":412,"That room cannot be built here.":413,"That was insightful":414,"The download could not be opened. The link was copied instead.":415,"The download link could not be copied.":416,"The download link could not be opened or copied.":417,"The future form is still a mystery.":418,"The Draconomicon":419,"The group does not meet the requirements.":420,"The GitHub repository is not connected yet. Build with --dart-define=DRAGONHAVEN_GITHUB_OWNER=yourname.":421,"The hidden dragon inside will be lost permanently.":422,"The highest trained path fixes the final form. Activities in Explore raise these values.":423,"The inventory is empty. Explore the Spire or visit the furniture market.":424,"The latest release contains no valid version data.":425,"The release check took too long.":426,"The secure connection to GitHub failed.":427,"The shell is trembling...":428,"The tower already has 20 floors.":429,"The tower nest":430,"This cannot be undone and gives no coins back.":431,"This build keeps your collection safely on this device. A real friend list needs authenticated accounts and a server, so no local demo person is shown as if they were online.":432,"This dragon leaves your collection and cannot be trained. Its identity, form, alignment and hidden personality are preserved.":433,"This code is not active.":434,"This offer is no longer available.":435,"This room is already part of the house.":436,"Tidal Library":437,Tower:438,"Tower visits":439,"Two-sided trade":440,"Undiscovered dragon form":441,"Unique atmosphere and layout":442,"Unknown lineage":443,"Up to 3 offers, refreshed at local midnight.":444,"Up to 3 offers. Open slots refresh every hour; you may dismiss one.":445,"Use only connected capital letters.":446,"Use only connected capital letters and numbers.":447,"Dragon emote pack unlocked. Its ten emotes are ready to use!":448,"You already own this Dragon emote pack.":449,Version:450,"Visit towers, lend a friendly dragon and trade eggs, chests or furniture.":451,Wall:452,Welcome:453,Wellbeing:454,"Wooden Chest":455,Wyrmling:456,"Your keeper name":457,"Your current dragon moves safely into the sanctuary collection. Coins, gems and discoveries stay yours.":458,"\u2726 SOMETHING IS DIFFERENT...":459,"Your living record of every dragon form you have raised.":460,"Your purchased furniture is stored here.":461,"Your sanctuary is not ready for this room yet.":462,coins:463,floors:464,forms:465,locked:466,"path undecided":467,unlocked:468,training:469,Dawn:470,Day:471,"Deep Night":472,Dusk:473,"Golden Hour":474,Legendary:475,Morning:476,Mythical:477,Night:478,Uncommon:479,"Very Rare":480,"A gentle glow lingers beneath your hand.":481,[u.V]:482,"A tiny spark skips across the shell.":483,"It goes quiet whenever you try to find a pattern.":484,"Something inside seems to listen back.":485,[u.L]:486,"The egg rolls a little. Uphill.":487,"The movements inside follow a precise rhythm.":488,[u.c]:489,"The shell feels unusually warm.":490,"You are fairly sure the egg just tapped back.":491,[u.i]:492,"{dragon} pulled out a book and looked shocked by chapter three.":493,"{dragon} curled up by the fire and immediately claimed the warmest spot.":494,"{dragon} inspected the snacks. One snack is now mysteriously absent.":495,"{dragon} made one tiny splash and one extremely non-tiny mess.":496,"{dragon} counted every shiny object twice, just to be certain.":497,"{dragon} disappeared between the leaves for a highly strategic nap.":498,"{dragon} turned the bedding into a fort. No adults allowed.":499,"{dragon} tapped the magic ornament. It politely tapped back.":500,"{dragon} looked around, nodded once, and declared this room acceptable.":501,[u.t]:502,[u.T]:503,"Your Mysterious Egg is ready":504,"Treasure revealed":505,"The lock is opening...":506,"Tap anywhere to return":507,"A quiet cradle for the next life in your collection.":508,"One hidden dragon is growing beneath the shell.":509,"Reveal the dragon":510,"No Mysterious Eggs are waiting in your inventory.":511,"Choose a Mysterious Egg":512,"Its identity is already safely hidden inside.":513,"The nest is already occupied.":514,"Tap the nest to choose an egg":515,"Tap the egg once to begin hatching":516,"The egg is beginning to hatch":517,"Something is moving inside...":518,"The nest is empty":519,"Choose one egg from your inventory.":520,"Rare eggs can be found in chests earned on Adventures.":521,"Choose an egg":522,"The egg moves to the Rooftop Nest. Your active dragon and the rest of the app stay available.":523,"Every form you raise leaves its magic on the page.":524,Available:525,Active:526,"Choose a path. Bring back stories, training and treasure.":527,"No trail is available here right now.":528,"Mystery chest":529,"Start adventure":530,"Choose a dragon":531,"Recommended for this path":532,"Other available dragons":533,Recommended:534,"No adventures are active":535,"Send a dragon out and its journey will appear here.":536,"Unknown dragon":537,"Ready to return":538,Dragon:539,Status:540,"Return in":541,"Dragon experience":542,"Training reward":543,Treasure:544,"One sealed chest":545,"Claim rewards":546,"Short Adventures":547,"Long Adventures":548,"Group Adventures":549,"Special Adventures":550,"Tiny outings":551,"Quick routes":552,"Patient journeys":553,"Shared discoveries":554,"Rare trails":555,"Refresh rules":556,Close:557,Vanity:558,Preferences:559,"No completed adventures":560,"Finished journeys wait here until you collect their rewards.":561,"Up to three routes wait. One free slot refills every 15 minutes. Visible routes stay until you start or dismiss them; they are not automatically replaced.":562,"Up to three routes wait. One free slot refills every hour. Visible routes stay until you start or dismiss them; they are not automatically replaced.":563,"Up to three routes wait. Free slots refill at local midnight. Visible routes stay until you start or dismiss them; they are not automatically replaced.":564,"Every keeper sees the same weekly route. It changes automatically every Sunday at 12:00 in Europe/Amsterdam. A group that already started always finishes and keeps its reward.":565,"Special routes appear only during certain events. They can expire or change automatically; their card shows them only while they are available.":566,"Tiny outings, quick training and wooden chests.":567,"Quick routes that refresh throughout the day.":568,"Patient journeys with richer returns.":569,"Shared discoveries for connected keepers.":570,"Rare trails that only appear at special moments.":571,Might:572,Arcana:573,Spirit:574,"No dragon is available for this adventure.":575,"Roaming in the Tower":576,"Resting off-stage":577,"Free roaming in the Tower":578,"This dragon may appear and wander through rooms.":579,"Zoom out":580,"The dragons found cozy places on other floors.":581,"Build another floor before clearing this room.":582,"Finish decorating":583,"Clear dragons":584,"TAP TO GUIDE YOUR FAVORITE":585,"TAP TO CALL YOUR FAVORITE":586,"Dragon type":587,Maturity:588,Experience:589,Level:590,"Invite to Tower":591,"The Tower is full. Build another floor or disable another roaming dragon.":592,Duration:593,"connected keepers":594,"Expertise training":595,Expertises:596,"Possible chests":597,"Keeper requirement":598,"shapes a Might Ascension":599,"shapes an Arcana Ascension":600,"shapes a Spirit Ascension":601,Lawful:602,Neutral:603,Chaotic:604,Good:605,Evil:606,"Moral nature":607,"Order nature":608,Personality:609,Undiscovered:610,"Highest level reached":611,"to next level":612,"Final evolution reached":613,"Next evolution":614,Relics:615,"No Relics yet":616,"Incubation after nesting":617,"Use this Relic?":618,"This is a consumable item. It disappears after revealing one dragon. Continue?":619,Continue:620,Rewards:621,"1 Gold, Dragon or Mythical Chest":622,"1 random relic":623,"Tap the chest to open":624,"Music revealed":625,Claim:626,"Remove from Tower":627,"Ancient magic awakens":628,"Sealed treasure":629,"Chest opening":630,"These exceptionally rare treasures can appear in Gold Chests and rarer chests.":631,"Choose carefully: each relic reveals one dragon and is consumed.":632,Use:633,"Already revealed":634,"Secret still hidden":635,"Remember this":636,"Moral Prism":637,"Order Compass":638,"Soul Mirror":639,"Reveals whether one dragon leans toward Good, Neutral or Evil.":640,"Reveals whether one dragon is Lawful, Neutral or Chaotic.":641,"Reveals the hidden personality traits of one dragon.":642,Sleepy:643,Nosy:644,Hoarder:645,"Drama Queen":646,Bookworm:647,"Food Thief":648,"Afraid of Heights":649,Restless:650,Shy:651,"Show-Off":652,Clumsy:653,"Neat Freak":654,Messy:655,Stubborn:656,Cuddly:657,Grumpy:658,"Easily Distracted":659,"Night Owl":660,"Early Bird":661,"Splash Lover":662,Firebug:663,"Attention Seeker":664,"Startles Easily":665,Tutorial:666,"Welcome to DragonHaven":667,"will show you around. You can skip now and replay this tour later from the three-dot menu.":668,"Online friends":669,"Create an e-mail-verified online account, then add other keepers by their Keeper ID. Friends can open each other's public profile and see portraits, titles, favorite dragons, discovered forms and Trial records.":670,"Trade and travel together":671,"From a friend you can offer a protected one-to-one Trade: eggs, chests and Relics stay reserved until it completes or expires. Logged-in friends can also enroll dragons together in asynchronous Group Adventures.":672,"Mini Adventures take minutes, Short Adventures hours and Long Adventures days. A dragon's matching Expertise shortens the timer. Group Adventures need 2\u20134 logged-in friends and begin automatically when their requirements are met.":673,Trials:674,"Trials are skill-based minigames and refill every 15 minutes, up to three waiting. Cavern Flight trains Spirit, Ruin Breaker trains Might and Runeweaver trains Arcana; your performance sets the rank, rewards and personal high score.":675,"Use the two large sprites at the top right: My Dragons opens your complete dragon collection, while the Draconomicon shows every discovered dragon form. Below them you can build, visit and decorate Tower floors.":676,"Eggs, unopened chests, furniture and Relics are stored here. Open chests, start an egg incubation or inspect what you own; items reserved for a Trade cannot be used until released.":677,"Buy furniture for your Tower with coins or gems. Title Chests cost coins and unlock account titles; Portrait Chests cost gems and unlock profile portraits. Open both from Inventory.":678,"The three-dot menu":679,"Tap the three dots at the top right for Account info, where you can change your portrait and title and manage Notifications and Audio. The same menu opens Language, Achievements and this Tutorial again.":680,"This is the future meeting place for linked Dragonkeepers, visits and fair trades.":681,"Send an available dragon on an Adventure to earn XP, Expertises and treasure chests.":682,"Build unique rooms, decorate them and choose which dragons may roam through their home.":683,"Your eggs, unopened chests, furniture and consumable Relics are safely stored here.":684,"Spend coins or gems on furniture that makes every Tower room feel like home.":685,"Skip tutorial":686,Next:687,"Nothing left to reveal":688,"This Relic has already revealed its secret for every dragon you own. Hatch or collect another dragon to use it.":689,Understood:690,"Expertises required":691,"Ascension requirements":692,"Complete both requirements before Ascension.":693,"Level & XP":694,"Minimum total Expertise":695,"Skip evolution animation":696,Portraits:697,"Account portrait":698,"No portraits collected yet":699,"Portrait Chests cost 99 gems in the Shop and always reveal a portrait you do not own yet.":700,"Choose account portrait":701,Coins:702,Gems:703,Buy:704,"No coin chests yet":705,"Special chests may be added here in a future update.":706,"Contains one random portrait you do not own. Its contents are decided only when opened.":707,"Collection complete":708,"Portrait Chest added to your Inventory.":709,"You already own all 100 portraits.":710,"You already own all 100 portraits, so another Portrait Chest cannot be purchased.":711,"Portrait revealed":712,"Added to your portrait collection":713,"Portrait collection complete":714,"You already own all 100 portraits. This Portrait Chest stays safely in your Inventory and cannot be opened.":715,"Portrait Chest":716,Infernal:717,"A Portrait Chest is waiting in your Inventory.":718,"A new account portrait joined your collection.":719,Titles:720,"Choose account title":721,"Title Chest":722,"Contains one random account title you do not own. Its contents are decided only when opened.":723,"Title Chest added to your Inventory.":724,"You already own all 500 account titles, so another Title Chest cannot be purchased.":725,"Title revealed":726,"Added to your title collection":727,"Title collection complete":728,"You already own all 500 account titles. This Title Chest stays safely in your Inventory and cannot be opened.":729,"A Title Chest is waiting in your Inventory.":730,"A request is already pending.":731,Accept:732,"Add by Keeper ID":733,"An account already exists for this email.":734,Block:735,"Block keeper":736,Blocked:737,"Check your email to confirm the account, then sign in.":738,"Connect your keeper":739,"Copy Keeper ID":740,Create:741,"Create a simple account to add friends by Keeper ID. Your email is never shown to other players.":742,"Create account":743,"Create online account":744,Discovered:745,"Discovered dragons":746,"Edit online profile":747,"Edit profile":748,"Enter a name.":749,"Enter a valid email.":750,"Favorite dragon":751,"Find trusted keepers, compare collections and visit their profiles.":752,"Friend removed for both keepers.":753,"Friend request sent.":754,"Friend requests":755,"Incorrect email or password.":756,"Keeper blocked.":757,"Keeper ID copied.":758,"Keeper name":759,"Keeper unblocked.":760,"No favorite dragon selected.":761,"No friends yet. Share your Keeper ID or add someone else.":762,"No keeper with that ID was found.":763,"Online account":764,"Online accounts are ready in this build, but this installation still needs its server URL and publishable key.":765,Password:766,Pending:767,"Profile saved.":768,Reject:769,"Remove friend":770,"Remove friend?":771,"Send request":772,"Sent requests":773,"Server setup required":774,"Sign in":775,"Sign out":776,"The online service could not complete this action. Please try again.":777,"This installation has no online server configuration yet.":778,"This keeper is unavailable.":779,"This request was recently rejected. Try again later.":780,Title:781,"Too many requests are pending.":782,Unblock:783,"Use at least 8 characters.":784,"You are already friends.":785,"You cannot add yourself.":786,"Your online account is ready.":787,"A new account title joined your collection.":788,"Cancel trade":789,Chest:790,"Choose my item":791,"Choose one item":792,"Complete this trade?":793,"Final confirmation":794,"New trade proposal":795,"Open trade":796,"Reject trade":797,Relic:798,"Reserved for trade":799,Send:800,"Send trade proposal?":801,"The completed trade could not be stored locally. Your server items remain safe; please refresh.":802,"The item is kept safe and cannot be used in another trade.":803,"This is the final confirmation. Both items will change owner immediately.":804,"This item cannot be traded.":805,"This item is no longer available or is already reserved.":806,"This trade has already changed. Refresh and try again.":807,Trade:808,"Trade cancelled":809,"Trade cancelled. Reserved items are available again.":810,"Trade completed":811,"Trade completed. The received item is in your inventory.":812,"Trade proposal sent.":813,"Trade rejected":814,"Trade rejected. Reserved items are available again.":815,"Trade with this friend":816,"Trades are only available between friends.":817,"Waiting for a return item.":818,"Waiting for final confirmation":819,"Waiting for your friend":820,"You have no unreserved eggs, chests or relics to trade.":821,"You have too many active trades. Finish or cancel one first.":822,"You offer":823,"Your final confirmation is needed":824,"Your item is reserved. Your friend can now confirm the trade.":825,"The item is kept safe and cannot be used in another trade. The proposal expires ten minutes after it is created.":826,"Only one active trade is allowed per account. Finish, reject or cancel it first.":827,"One of you has already completed three trades today. Try again tomorrow.":828,"This trade expired after ten minutes. The reserved items are available again.":829,"Trade expired":830,"Enter your password.":831,"Online server is not configured":832,"This profile is currently stored offline":833,"Trusted keepers, shared adventures and safe trades.":834,friends:835,requests:836,trades:837,"dragons discovered":838,"Use an uppercase letter, lowercase letter, number and symbol.":839,"Resend confirmation email":840,"Confirmation email sent. Check your inbox and spam folder.":841,"All remaining rewards covered":842,"Collection progress":843,"unopened chests":844,"Current portrait odds":845,"Tap an egg for its clue and actions.":846,egg:847,eggs:848,"Change dragon order":849,Name:850,Received:851,Rarity:852,"Show compact list":853,"Show gallery":854,"Tap the egg to shorten the wait by one second per tap. The final second always counts down normally.":855,"Tap the starter egg to shorten the timer by one second":856,"Relics bought here are untradeable. Relics found through gameplay remain tradeable. You may buy as many as you like.":857,"A Special Adventure has appeared":858,[u.r]:859,"All Expertises":860,"Journey shortening":861,"Might + Arcana + Spirit: every combined point removes 1 hour (minimum 1 day).":862,"Guaranteed Special Chest":863,"269 coins, 10 gems and a Special Egg with an event dragon.":864,"Guaranteed relic":865,"1 random relic; which one remains a surprise until you claim it.":866,"Guaranteed Music Chest":867,"1 Music Chest, rolled only when you open it.":868,"1 random relic; the exact relic is still a surprise.":869,"1 Music Chest, rolled when it is opened.":870,"Special Egg":871,"Special Events":872,"Available for":873,"When a Special Adventure becomes available.":874,"No Eggs in your inventory yet.":875,"Open 10":876,"No Eggs are waiting in your inventory.":877,"Choose an Egg":878,"New title":879,"A golden birthday wish for a beautiful woman whose kindness brightens the Haven.":880}
A.H1=s(["Sicherungsverlauf","Historial de copias","Historique des sauvegardes","Cronologia dei backup","Historico de backups","\u30d0\u30c3\u30af\u30a2\u30c3\u30d7\u5c65\u6b74"],t.s)
A.kh=s(["Cloud ansehen","Ver nube","Voir le cloud","Visualizza cloud","Ver nuvem","\u30af\u30e9\u30a6\u30c9\u3092\u8868\u793a"],t.s)
A.Cw=s(["Cloud ersetzen","Reemplazar nube","Remplacer le cloud","Sostituisci cloud","Substituir nuvem","\u30af\u30e9\u30a6\u30c9\u3092\u7f6e\u304d\u63db\u3048"],t.s)
A.tX=s(["Cloud-Fortschritt ersetzen?","Reemplazar el progreso de la nube?","Remplacer la progression cloud ?","Sostituire i progressi cloud?","Substituir o progresso na nuvem?","\u30af\u30e9\u30a6\u30c9\u306e\u9032\u884c\u72b6\u6cc1\u3092\u7f6e\u304d\u63db\u3048\u307e\u3059\u304b\uff1f"],t.s)
A.u7=s(["Der aktuelle Cloud-Fortschritt wird durch dieses Gerat ersetzt. Die vorherige Revision bleibt bis zu dreissig Tage wiederherstellbar.","El progreso actual de la nube sera reemplazado por este dispositivo. La revision anterior se puede recuperar durante treinta dias.","La progression cloud actuelle sera remplacee par cet appareil. La revision precedente restera recuperable pendant trente jours.","I progressi cloud attuali verranno sostituiti da questo dispositivo. La revisione precedente resta recuperabile per trenta giorni.","O progresso atual na nuvem sera substituido por este dispositivo. A revisao anterior podera ser recuperada por trinta dias.","\u73fe\u5728\u306e\u30af\u30e9\u30a6\u30c9\u9032\u884c\u72b6\u6cc1\u306f\u3053\u306e\u7aef\u672b\u306e\u30c7\u30fc\u30bf\u306b\u7f6e\u304d\u63db\u308f\u308a\u307e\u3059\u3002\u524d\u306e\u30ea\u30d3\u30b8\u30e7\u30f3\u306f30\u65e5\u9593\u5fa9\u5143\u3067\u304d\u307e\u3059\u3002"],t.s)
A.va=s(["Cloud-Fortschritt sicher ersetzt.","Progreso de la nube reemplazado de forma segura.","Progression cloud remplacee en toute securite.","Progressi cloud sostituiti in sicurezza.","Progresso na nuvem substituido com seguranca.","\u30af\u30e9\u30a6\u30c9\u306e\u9032\u884c\u72b6\u6cc1\u3092\u5b89\u5168\u306b\u7f6e\u304d\u63db\u3048\u307e\u3057\u305f\u3002"],t.s)
A.K8=s(["Kein Cloud-Sicherungsverlauf verfugbar.","No hay historial de copias en la nube.","Aucun historique de sauvegarde cloud disponible.","Nessuna cronologia di backup cloud disponibile.","Nenhum historico de backup na nuvem disponivel.","\u30af\u30e9\u30a6\u30c9\u30d0\u30c3\u30af\u30a2\u30c3\u30d7\u306e\u5c65\u6b74\u306f\u3042\u308a\u307e\u305b\u3093\u3002"],t.s)
A.JO=s(["Bis zu funf Cloud-Revisionen werden dreissig Tage aufbewahrt.","Se guardan hasta cinco revisiones en la nube durante treinta dias.","Jusqu'a cinq revisions cloud sont conservees pendant trente jours.","Fino a cinque revisioni cloud vengono conservate per trenta giorni.","Ate cinco revisoes na nuvem sao mantidas por trinta dias.","\u6700\u59275\u4ef6\u306e\u30af\u30e9\u30a6\u30c9\u30ea\u30d3\u30b8\u30e7\u30f3\u304c30\u65e5\u9593\u4fdd\u5b58\u3055\u308c\u307e\u3059\u3002"],t.s)
A.CR=s(["Revision","Revision","Revision","Revisione","Revisao","\u30ea\u30d3\u30b8\u30e7\u30f3"],t.s)
A.m6=s(["Aktuell","Actual","Actuelle","Attuale","Atual","\u73fe\u5728"],t.s)
A.Cq=s(["App-Version","Version de la app","Version de l'app","Versione app","Versao do app","\u30a2\u30d7\u30ea\u30d0\u30fc\u30b8\u30e7\u30f3"],t.s)
A.xP=s(["Speicherschema","Esquema de guardado","Schema de sauvegarde","Schema salvataggio","Esquema do save","\u30bb\u30fc\u30d6\u30b9\u30ad\u30fc\u30de"],t.s)
A.ka=s(["Diese Revision wiederherstellen?","Restaurar esta revision?","Restaurer cette revision ?","Ripristinare questa revisione?","Restaurar esta revisao?","\u3053\u306e\u30ea\u30d3\u30b8\u30e7\u30f3\u3092\u5fa9\u5143\u3057\u307e\u3059\u304b\uff1f"],t.s)
A.vt=s(["Dein lokaler Fortschritt wird durch diese Cloud-Revision ersetzt. Eine lokale Wiederherstellungskopie bleibt erhalten.","Tu progreso local sera reemplazado por esta revision de la nube. Se conserva una copia local de recuperacion.","Ta progression locale sera remplacee par cette revision cloud. Une copie locale de recuperation est conservee.","I progressi locali verranno sostituiti da questa revisione cloud. Viene conservata una copia locale di recupero.","Seu progresso local sera substituido por esta revisao na nuvem. Uma copia local de recuperacao sera mantida.","\u30ed\u30fc\u30ab\u30eb\u306e\u9032\u884c\u72b6\u6cc1\u306f\u3053\u306e\u30af\u30e9\u30a6\u30c9\u30ea\u30d3\u30b8\u30e7\u30f3\u306b\u7f6e\u304d\u63db\u308f\u308a\u307e\u3059\u3002\u30ed\u30fc\u30ab\u30eb\u306e\u5fa9\u5143\u30b3\u30d4\u30fc\u306f\u4fdd\u6301\u3055\u308c\u307e\u3059\u3002"],t.s)
A.lm=s(["Revision wiederherstellen","Restaurar revision","Restaurer la revision","Ripristina revisione","Restaurar revisao","\u30ea\u30d3\u30b8\u30e7\u30f3\u3092\u5fa9\u5143"],t.s)
A.lR=s(["Konto loschen","Eliminar cuenta","Supprimer le compte","Elimina account","Excluir conta","\u30a2\u30ab\u30a6\u30f3\u30c8\u3092\u524a\u9664"],t.s)
A.l8=s(["Online-Konto loschen?","Eliminar la cuenta online?","Supprimer le compte en ligne ?","Eliminare l'account online?","Excluir a conta online?","\u30aa\u30f3\u30e9\u30a4\u30f3\u30a2\u30ab\u30a6\u30f3\u30c8\u3092\u524a\u9664\u3057\u307e\u3059\u304b\uff1f"],t.s)
A.m7=s(["Dies loscht dein Online-Profil, Freunde, Tausche und die Cloud-Sicherung dauerhaft. Dein lokaler Spielstand bleibt auf diesem Gerat.","Esto elimina para siempre tu perfil, amigos, intercambios y copia en la nube. Tu partida local permanece en este dispositivo.","Cela supprime definitivement ton profil, tes amis, tes echanges et ta sauvegarde cloud. Ta partie locale reste sur cet appareil.","Elimina definitivamente profilo, amici, scambi e backup cloud. Il salvataggio locale resta sul dispositivo.","Isso exclui permanentemente perfil, amigos, trocas e backup na nuvem. O save local permanece no dispositivo.","\u30aa\u30f3\u30e9\u30a4\u30f3\u30d7\u30ed\u30d5\u30a3\u30fc\u30eb\u3001\u30d5\u30ec\u30f3\u30c9\u3001\u4ea4\u63db\u3001\u30af\u30e9\u30a6\u30c9\u30d0\u30c3\u30af\u30a2\u30c3\u30d7\u3092\u5b8c\u5168\u306b\u524a\u9664\u3057\u307e\u3059\u3002\u7aef\u672b\u306e\u30ed\u30fc\u30ab\u30eb\u30bb\u30fc\u30d6\u306f\u6b8b\u308a\u307e\u3059\u3002"],t.s)
A.IY=s(["Passwort bestatigen","Confirmar contrasena","Confirmer le mot de passe","Conferma password","Confirmar senha","\u30d1\u30b9\u30ef\u30fc\u30c9\u3092\u78ba\u8a8d"],t.s)
A.nG=s(["Dauerhaft loschen","Eliminar permanentemente","Supprimer definitivement","Elimina definitivamente","Excluir permanentemente","\u5b8c\u5168\u306b\u524a\u9664"],t.s)
A.J5=s(["Online-Konto geloscht.","Cuenta online eliminada.","Compte en ligne supprime.","Account online eliminato.","Conta online excluida.","\u30aa\u30f3\u30e9\u30a4\u30f3\u30a2\u30ab\u30a6\u30f3\u30c8\u3092\u524a\u9664\u3057\u307e\u3057\u305f\u3002"],t.s)
A.AU=s(["Kontoloschung fehlgeschlagen. Prufe Passwort und Verbindung.","No se pudo eliminar la cuenta. Comprueba la contrasena y la conexion.","La suppression a echoue. Verifie le mot de passe et la connexion.","Eliminazione non riuscita. Controlla password e connessione.","Falha ao excluir a conta. Verifique a senha e a conexao.","\u30a2\u30ab\u30a6\u30f3\u30c8\u3092\u524a\u9664\u3067\u304d\u307e\u305b\u3093\u3067\u3057\u305f\u3002\u30d1\u30b9\u30ef\u30fc\u30c9\u3068\u63a5\u7d9a\u3092\u78ba\u8a8d\u3057\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.rO=s(["Neue Freundschaftsanfrage","Nueva solicitud de amistad","Nouvelle demande d'ami","Nuova richiesta di amicizia","Novo pedido de amizade","\u65b0\u3057\u3044\u30d5\u30ec\u30f3\u30c9\u7533\u8acb"],t.s)
A.Aj=s(["{name} mochte befreundet sein.","{name} quiere ser tu amigo.","{name} souhaite devenir ton ami.","{name} vuole diventare tuo amico.","{name} quer ser seu amigo.","{name}\u304c\u30d5\u30ec\u30f3\u30c9\u306b\u306a\u308a\u305f\u304c\u3063\u3066\u3044\u307e\u3059\u3002"],t.s)
A.my=s(["Freundschaftsanfrage angenommen","Solicitud de amistad aceptada","Demande d'ami acceptee","Richiesta di amicizia accettata","Pedido de amizade aceito","\u30d5\u30ec\u30f3\u30c9\u7533\u8acb\u304c\u627f\u8a8d\u3055\u308c\u307e\u3057\u305f"],t.s)
A.xT=s(["{name} ist jetzt in deiner Freundesliste.","{name} esta ahora en tu lista de amigos.","{name} figure maintenant dans ta liste d'amis.","{name} e ora nella tua lista amici.","{name} agora esta na sua lista de amigos.","{name}\u304c\u30d5\u30ec\u30f3\u30c9\u30ea\u30b9\u30c8\u306b\u52a0\u308f\u308a\u307e\u3057\u305f\u3002"],t.s)
A.ze=s(["Neues Tauschangebot","Nueva oferta de intercambio","Nouvelle offre d'echange","Nuova offerta di scambio","Nova oferta de troca","\u65b0\u3057\u3044\u4ea4\u63db\u30aa\u30d5\u30a1\u30fc"],t.s)
A.EM=s(["{name} mochte einen Gegenstand mit dir tauschen.","{name} quiere intercambiar un objeto contigo.","{name} souhaite echanger un objet avec toi.","{name} vuole scambiare un oggetto con te.","{name} quer trocar um item com voce.","{name}\u304c\u30a2\u30a4\u30c6\u30e0\u3092\u4ea4\u63db\u3057\u305f\u304c\u3063\u3066\u3044\u307e\u3059\u3002"],t.s)
A.Io=s(["Gegenangebot erhalten","Objeto de vuelta ofrecido","Objet de retour propose","Oggetto di ritorno offerto","Item de retorno oferecido","\u304a\u8fd4\u3057\u306e\u30a2\u30a4\u30c6\u30e0\u304c\u63d0\u793a\u3055\u308c\u307e\u3057\u305f"],t.s)
A.lf=s(["{name} hat einen Gegenstand angeboten. Bestatige den Tausch.","{name} ofrecio un objeto. Confirma el intercambio.","{name} a propose un objet. Confirme l'echange.","{name} ha offerto un oggetto. Conferma lo scambio.","{name} ofereceu um item. Confirme a troca.","{name}\u304c\u30a2\u30a4\u30c6\u30e0\u3092\u63d0\u793a\u3057\u307e\u3057\u305f\u3002\u4ea4\u63db\u3092\u78ba\u8a8d\u3057\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.Aw=s(["Dein Tausch mit {name} wurde sicher abgeschlossen.","Tu intercambio con {name} se completo de forma segura.","Ton echange avec {name} est termine en toute securite.","Lo scambio con {name} e stato completato in sicurezza.","Sua troca com {name} foi concluida com seguranca.","{name}\u3068\u306e\u4ea4\u63db\u304c\u5b89\u5168\u306b\u5b8c\u4e86\u3057\u307e\u3057\u305f\u3002"],t.s)
A.KL=s(["Cloud-Sicherung","Copia en la nube","Sauvegarde cloud","Backup cloud","Backup na nuvem","\u30af\u30e9\u30a6\u30c9\u30d0\u30c3\u30af\u30a2\u30c3\u30d7"],t.s)
A.lh=s(["Cloud-Sicherung Revision","Revision de copia en la nube","Revision de sauvegarde cloud","Revisione backup cloud","Revisao do backup na nuvem","\u30af\u30e9\u30a6\u30c9\u30d0\u30c3\u30af\u30a2\u30c3\u30d7\u306e\u30ea\u30d3\u30b8\u30e7\u30f3"],t.s)
A.kR=s(["Bewahre online eine versionierte Kopie des Fortschritts dieses Gerats auf.","Guarda en linea una copia versionada del progreso de este dispositivo.","Conserve en ligne une copie versionnee de la progression de cet appareil.","Conserva online una copia con versione dei progressi di questo dispositivo.","Mantenha online uma copia com versao do progresso deste dispositivo.","\u3053\u306e\u7aef\u672b\u306e\u9032\u884c\u72b6\u6cc1\u3092\u4e16\u4ee3\u4ed8\u304d\u3067\u30aa\u30f3\u30e9\u30a4\u30f3\u4fdd\u5b58\u3057\u307e\u3059\u3002"],t.s)
A.ps=s(["Sichern","Guardar","Sauvegarder","Salva","Salvar","\u30d0\u30c3\u30af\u30a2\u30c3\u30d7"],t.s)
A.uU=s(["Wiederherstellen","Restaurar","Restaurer","Ripristina","Restaurar","\u5fa9\u5143"],t.s)
A.D7=s(["Fortschritt sichern?","Guardar el progreso?","Sauvegarder la progression ?","Salvare i progressi?","Salvar o progresso?","\u9032\u884c\u72b6\u6cc1\u3092\u30d0\u30c3\u30af\u30a2\u30c3\u30d7\u3057\u307e\u3059\u304b\uff1f"],t.s)
A.J7=s(["Dies speichert den aktuellen Fortschritt dieses Gerats im Online-Konto. Eine altere Cloud-Sicherung wird ersetzt.","Esto guarda el progreso actual de este dispositivo en tu cuenta. Se reemplazara una copia anterior.","Cela enregistre la progression actuelle de cet appareil dans ton compte. Une ancienne sauvegarde sera remplacee.","Salva i progressi attuali di questo dispositivo nel tuo account. Un backup precedente verra sostituito.","Isso salva o progresso atual deste dispositivo na sua conta. Um backup anterior sera substituido.","\u3053\u306e\u7aef\u672b\u306e\u73fe\u5728\u306e\u9032\u884c\u72b6\u6cc1\u3092\u30aa\u30f3\u30e9\u30a4\u30f3\u30a2\u30ab\u30a6\u30f3\u30c8\u306b\u4fdd\u5b58\u3057\u3001\u53e4\u3044\u30d0\u30c3\u30af\u30a2\u30c3\u30d7\u3092\u7f6e\u304d\u63db\u3048\u307e\u3059\u3002"],t.s)
A.mN=s(["Cloud-Sicherung gespeichert.","Copia en la nube guardada.","Sauvegarde cloud enregistree.","Backup cloud salvato.","Backup na nuvem salvo.","\u30af\u30e9\u30a6\u30c9\u30d0\u30c3\u30af\u30a2\u30c3\u30d7\u3092\u4fdd\u5b58\u3057\u307e\u3057\u305f\u3002"],t.s)
A.Ju=s(["Cloud-Sicherung fehlgeschlagen. Aktualisiere und versuche es erneut.","La copia fallo. Actualiza e intentalo de nuevo.","La sauvegarde a echoue. Actualise puis reessaie.","Backup non riuscito. Aggiorna e riprova.","Falha no backup. Atualize e tente novamente.","\u30af\u30e9\u30a6\u30c9\u30d0\u30c3\u30af\u30a2\u30c3\u30d7\u306b\u5931\u6557\u3057\u307e\u3057\u305f\u3002\u66f4\u65b0\u3057\u3066\u518d\u8a66\u884c\u3057\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.pW=s(["Cloud-Fortschritt wiederherstellen?","Restaurar progreso de la nube?","Restaurer la progression cloud ?","Ripristinare i progressi cloud?","Restaurar progresso da nuvem?","\u30af\u30e9\u30a6\u30c9\u306e\u9032\u884c\u72b6\u6cc1\u3092\u5fa9\u5143\u3057\u307e\u3059\u304b\uff1f"],t.s)
A.wA=s(["Dein lokaler Fortschritt wird durch die neueste Cloud-Sicherung ersetzt. Eine lokale Wiederherstellungskopie bleibt erhalten.","Tu progreso local se reemplazara por la copia mas reciente. Se conserva una copia local de recuperacion.","Ta progression locale sera remplacee par la sauvegarde la plus recente. Une copie locale de recuperation est conservee.","I progressi locali saranno sostituiti dal backup piu recente. Viene conservata una copia locale di recupero.","Seu progresso local sera substituido pelo backup mais recente. Uma copia local de recuperacao sera mantida.","\u73fe\u5728\u306e\u30ed\u30fc\u30ab\u30eb\u9032\u884c\u72b6\u6cc1\u306f\u6700\u65b0\u306e\u30af\u30e9\u30a6\u30c9\u30d0\u30c3\u30af\u30a2\u30c3\u30d7\u306b\u7f6e\u304d\u63db\u308f\u308a\u3001\u5fa9\u65e7\u7528\u30b3\u30d4\u30fc\u306f\u7aef\u672b\u306b\u6b8b\u308a\u307e\u3059\u3002"],t.s)
A.ol=s(["Cloud-Fortschritt wiederhergestellt.","Progreso de la nube restaurado.","Progression cloud restauree.","Progressi cloud ripristinati.","Progresso da nuvem restaurado.","\u30af\u30e9\u30a6\u30c9\u306e\u9032\u884c\u72b6\u6cc1\u3092\u5fa9\u5143\u3057\u307e\u3057\u305f\u3002"],t.s)
A.xj=s(["Keine brauchbare Cloud-Sicherung gefunden.","No se encontro una copia utilizable.","Aucune sauvegarde cloud utilisable trouvee.","Nessun backup cloud utilizzabile trovato.","Nenhum backup utilizavel foi encontrado.","\u5229\u7528\u3067\u304d\u308b\u30af\u30e9\u30a6\u30c9\u30d0\u30c3\u30af\u30a2\u30c3\u30d7\u304c\u898b\u3064\u304b\u308a\u307e\u305b\u3093\u3067\u3057\u305f\u3002"],t.s)
A.qX=s(["Drei Pr\xfcfungen sind bereit","Hay tres pruebas disponibles","Trois \xe9preuves sont pr\xeates","Tre prove sono pronte","Tr\xeas provas est\xe3o prontas","3\u3064\u306e\u8a66\u7df4\u306e\u6e96\u5099\u304c\u3067\u304d\u307e\u3057\u305f"],t.s)
A.y3=s(["Deine Pr\xfcfungstafel ist voll. W\xe4hle einen Drachen und jage einen neuen Rekord.","Tu tablero de pruebas est\xe1 lleno. Elige un drag\xf3n y busca un nuevo r\xe9cord.","Ton tableau d\u2019\xe9preuves est plein. Choisis un dragon et vise un nouveau record.","La bacheca delle prove \xe8 piena. Scegli un drago e punta a un nuovo record.","Seu painel de provas est\xe1 cheio. Escolha um drag\xe3o e busque um novo recorde.","\u8a66\u7df4\u30dc\u30fc\u30c9\u304c\u6e80\u676f\u3067\u3059\u3002\u30c9\u30e9\u30b4\u30f3\u3092\u9078\u3073\u3001\u65b0\u8a18\u9332\u3092\u76ee\u6307\u3057\u307e\u3057\u3087\u3046\u3002"],t.s)
A.Iw=s(["Android-Benachrichtigungen sind f\xfcr DragonHaven deaktiviert.","Las notificaciones de Android est\xe1n desactivadas para DragonHaven.","Les notifications Android sont d\xe9sactiv\xe9es pour DragonHaven.","Le notifiche Android sono disattivate per DragonHaven.","As notifica\xe7\xf5es do Android est\xe3o desativadas para o DragonHaven.","DragonHaven\u306eAndroid\u901a\u77e5\u306f\u30aa\u30d5\u306b\u306a\u3063\u3066\u3044\u307e\u3059\u3002"],t.s)
A.Dd=s(["Einstellungen \xf6ffnen","Abrir ajustes","Ouvrir les param\xe8tres","Apri impostazioni","Abrir configura\xe7\xf5es","\u8a2d\u5b9a\u3092\u958b\u304f"],t.s)
A.Jz=s(["Benachrichtigungen","Notificaciones","Notifications","Notifiche","Notifica\xe7\xf5es","\u901a\u77e5"],t.s)
A.k8=s(["W\xe4hle, welche Erinnerungen du erh\xe4ltst","Elige qu\xe9 recordatorios recibes","Choisis les rappels que tu re\xe7ois","Scegli quali promemoria ricevere","Escolha quais lembretes receber","\u53d7\u3051\u53d6\u308b\u901a\u77e5\u3092\u9078\u629e"],t.s)
A.Cf=s(["Musik \xb7 R\xeaverie","M\xfasica \xb7 R\xeaverie","Musique \xb7 R\xeaverie","Musica \xb7 R\xeaverie","M\xfasica \xb7 R\xeaverie","\u97f3\u697d \xb7 \u5922\u60f3"],t.s)
A.Lb=s(["\xd6FFNEN","ABRIR","OUVRIR","APRI","ABRIR","\u958b\u304f"],t.s)
A.nO=s(["TAUSCH","CAMBIO","\xc9CHANGE","SCAMBIA","TROCA","\u4ea4\u63db"],t.s)
A.tS=s(["Tausch wartet auf deine Antwort","El intercambio espera tu respuesta","L\u2019\xe9change attend ta r\xe9ponse","Lo scambio attende la tua risposta","A troca aguarda sua resposta","\u4ea4\u63db\u304c\u3042\u306a\u305f\u306e\u8fd4\u7b54\u3092\u5f85\u3063\u3066\u3044\u307e\u3059"],t.s)
A.lH=s(["Aktiven Tausch \xf6ffnen","Abrir intercambio activo","Ouvrir l\u2019\xe9change actif","Apri lo scambio attivo","Abrir troca ativa","\u9032\u884c\u4e2d\u306e\u4ea4\u63db\u3092\u958b\u304f"],t.s)
A.HG=s(["Dein reservierter Tausch kann angesehen werden.","Tu intercambio reservado est\xe1 listo para verse.","Ton \xe9change r\xe9serv\xe9 est pr\xeat \xe0 \xeatre consult\xe9.","Lo scambio riservato \xe8 pronto da visualizzare.","Sua troca reservada est\xe1 pronta para ser vista.","\u4e88\u7d04\u6e08\u307f\u306e\u4ea4\u63db\u3092\u78ba\u8a8d\u3067\u304d\u307e\u3059\u3002"],t.s)
A.AT=s(["W\xe4hle ein Ei, eine Truhe oder ein Relikt f\xfcr einen sicheren Tausch.","Elige un huevo, cofre o reliquia para un intercambio seguro.","Choisis un \u0153uf, un coffre ou une relique pour un \xe9change s\xfbr.","Scegli un uovo, forziere o reliquia per uno scambio sicuro.","Escolha um ovo, ba\xfa ou rel\xedquia para uma troca segura.","\u5375\u3001\u5b9d\u7bb1\u3001\u907a\u7269\u304b\u3089\u5b89\u5168\u306b\u4ea4\u63db\u3059\u308b\u54c1\u3092\u9078\u3073\u307e\u3059\u3002"],t.s)
A.qE=s(["W\xe4hle, was dich zur\xfcckrufen darf","Elige qu\xe9 puede avisarte","Choisis ce qui peut te rappeler","Scegli cosa pu\xf2 richiamarti","Escolha o que pode chamar voc\xea de volta","\u547c\u3073\u623b\u3057\u3066\u3088\u3044\u51fa\u6765\u4e8b\u3092\u9078\u629e"],t.s)
A.AO=s(["Standardm\xe4\xdfig ist alles aktiviert. Du beh\xe4ltst die Kontrolle \xfcber jede Erinnerung.","Todo est\xe1 activado de forma predeterminada. T\xfa controlas cada recordatorio.","Tout est activ\xe9 par d\xe9faut. Tu gardes le contr\xf4le de chaque rappel.","Tutto \xe8 attivo per impostazione predefinita. Mantieni il controllo di ogni promemoria.","Tudo vem ativado por padr\xe3o. Voc\xea controla cada lembrete.","\u3059\u3079\u3066\u521d\u671f\u8a2d\u5b9a\u3067\u6709\u52b9\u3067\u3059\u3002\u5404\u901a\u77e5\u306f\u81ea\u7531\u306b\u7ba1\u7406\u3067\u304d\u307e\u3059\u3002"],t.s)
A.J2=s(["Schlupfbereite Eier","Huevos listos para eclosionar","\u0152ufs pr\xeats \xe0 \xe9clore","Uova pronte a schiudersi","Ovos prontos para chocar","\u5b75\u5316\u3067\u304d\u308b\u5375"],t.s)
A.r9=s(["Wenn ein Ei im Dachnest bereit ist.","Cuando un huevo del Nido de la azotea est\xe1 listo.","Lorsqu\u2019un \u0153uf du Nid du toit est pr\xeat.","Quando un uovo nel Nido sul tetto \xe8 pronto.","Quando um ovo no Ninho do terra\xe7o estiver pronto.","\u5c4b\u4e0a\u306e\u5de3\u306e\u5375\u304c\u5b75\u5316\u3067\u304d\u308b\u3088\u3046\u306b\u306a\u3063\u305f\u3068\u304d\u3002"],t.s)
A.mS=s(["Erfolge","Logros","Succ\xe8s","Obiettivi","Conquistas","\u5b9f\u7e3e"],t.s)
A.kP=s(["Wenn du einen neuen Erfolg freischaltest.","Cuando desbloqueas un nuevo logro.","Lorsque tu d\xe9bloques un nouveau succ\xe8s.","Quando sblocchi un nuovo obiettivo.","Quando voc\xea desbloquear uma nova conquista.","\u65b0\u3057\u3044\u5b9f\u7e3e\u3092\u89e3\u9664\u3057\u305f\u3068\u304d\u3002"],t.s)
A.un=s(["Drachenentwicklungen","Evoluciones de dragones","\xc9volutions de dragons","Evoluzioni dei draghi","Evolu\xe7\xf5es de drag\xf5es","\u30c9\u30e9\u30b4\u30f3\u306e\u9032\u5316"],t.s)
A.o9=s(["Wenn einer deiner Drachen eine neue Form erreicht.","Cuando uno de tus dragones alcanza una nueva forma.","Lorsqu\u2019un de tes dragons atteint une nouvelle forme.","Quando uno dei tuoi draghi raggiunge una nuova forma.","Quando um dos seus drag\xf5es alcan\xe7ar uma nova forma.","\u30c9\u30e9\u30b4\u30f3\u304c\u65b0\u3057\u3044\u59ff\u306b\u9032\u5316\u3057\u305f\u3068\u304d\u3002"],t.s)
A.C2=s(["Wenn dir ein anderer H\xfcter eine Anfrage sendet.","Cuando otro guardi\xe1n te env\xeda una solicitud.","Lorsqu\u2019un autre gardien t\u2019envoie une demande.","Quando un altro custode ti invia una richiesta.","Quando outro guardi\xe3o enviar uma solicita\xe7\xe3o.","\u4ed6\u306e\u30ad\u30fc\u30d1\u30fc\u304b\u3089\u7533\u8acb\u304c\u5c4a\u3044\u305f\u3068\u304d\u3002"],t.s)
A.Le=s(["Angenommene Freundschaften","Solicitudes aceptadas","Demandes accept\xe9es","Amicizie accettate","Amizades aceitas","\u30d5\u30ec\u30f3\u30c9\u627f\u8a8d"],t.s)
A.Do=s(["Wenn deine Freundschaftsanfrage angenommen wird.","Cuando aceptan tu solicitud de amistad.","Lorsque ta demande d\u2019amiti\xe9 est accept\xe9e.","Quando la tua richiesta di amicizia viene accettata.","Quando sua solicita\xe7\xe3o de amizade for aceita.","\u30d5\u30ec\u30f3\u30c9\u7533\u8acb\u304c\u627f\u8a8d\u3055\u308c\u305f\u3068\u304d\u3002"],t.s)
A.Dl=s(["Tauschvorschl\xe4ge","Propuestas de intercambio","Propositions d\u2019\xe9change","Proposte di scambio","Propostas de troca","\u4ea4\u63db\u306e\u63d0\u6848"],t.s)
A.kL=s(["Wenn ein Freund einen Tausch mit dir beginnt.","Cuando un amigo inicia un intercambio contigo.","Lorsqu\u2019un ami commence un \xe9change avec toi.","Quando un amico avvia uno scambio con te.","Quando um amigo iniciar uma troca com voc\xea.","\u30d5\u30ec\u30f3\u30c9\u304c\u4ea4\u63db\u3092\u59cb\u3081\u305f\u3068\u304d\u3002"],t.s)
A.KO=s(["Tausch-Gegenangebote","Objetos ofrecidos a cambio","Objets propos\xe9s en retour","Oggetti offerti in cambio","Itens oferecidos em troca","\u4ea4\u63db\u76f8\u624b\u306e\u63d0\u793a\u30a2\u30a4\u30c6\u30e0"],t.s)
A.vs=s(["Wenn der andere H\xfcter seinen Gegenstand anbietet.","Cuando el otro guardi\xe1n ofrece su objeto.","Lorsque l\u2019autre gardien propose son objet.","Quando l\u2019altro custode offre il proprio oggetto.","Quando o outro guardi\xe3o oferecer seu item.","\u76f8\u624b\u306e\u30ad\u30fc\u30d1\u30fc\u304c\u30a2\u30a4\u30c6\u30e0\u3092\u63d0\u793a\u3057\u305f\u3068\u304d\u3002"],t.s)
A.kO=s(["Abgeschlossene Tauschgesch\xe4fte","Intercambios completados","\xc9changes termin\xe9s","Scambi completati","Trocas conclu\xeddas","\u5b8c\u4e86\u3057\u305f\u4ea4\u63db"],t.s)
A.lw=s(["Wenn ein Tausch sicher abgeschlossen wurde.","Cuando un intercambio se completa de forma segura.","Lorsqu\u2019un \xe9change est termin\xe9 en toute s\xe9curit\xe9.","Quando uno scambio si conclude in sicurezza.","Quando uma troca for conclu\xedda com seguran\xe7a.","\u4ea4\u63db\u304c\u5b89\u5168\u306b\u5b8c\u4e86\u3057\u305f\u3068\u304d\u3002"],t.s)
A.uC=s(["Drei Pr\xfcfungen verf\xfcgbar","Tres pruebas disponibles","Trois \xe9preuves disponibles","Tre prove disponibili","Tr\xeas provas dispon\xedveis","3\u3064\u306e\u8a66\u7df4\u304c\u5229\u7528\u53ef\u80fd"],t.s)
A.zL=s(["Wenn deine Pr\xfcfungstafel 3/3 erreicht.","Cuando tu tablero de pruebas llega a 3/3.","Lorsque ton tableau d\u2019\xe9preuves atteint 3/3.","Quando la bacheca delle prove raggiunge 3/3.","Quando seu painel de provas chegar a 3/3.","\u8a66\u7df4\u30dc\u30fc\u30c9\u304c3/3\u306b\u306a\u3063\u305f\u3068\u304d\u3002"],t.s)
A.p6=s(["Genaue Zeitplanung erlauben","Permitir horarios precisos","Autoriser les horaires pr\xe9cis","Consenti orari precisi","Permitir hor\xe1rios precisos","\u6b63\u78ba\u306a\u6642\u523b\u3092\u8a31\u53ef"],t.s)
A.Az=s(["Android kann zeitgesteuerte Erinnerungen verz\xf6gern, bis Alarme & Erinnerungen erlaubt ist.","Android puede retrasar los recordatorios programados hasta que se permita Alarmas y recordatorios.","Android peut retarder les rappels programm\xe9s tant que Alarmes et rappels n\u2019est pas autoris\xe9.","Android pu\xf2 ritardare i promemoria programmati finch\xe9 Sveglie e promemoria non \xe8 consentito.","O Android pode atrasar lembretes programados at\xe9 que Alarmes e lembretes seja permitido.","\u300c\u30a2\u30e9\u30fc\u30e0\u3068\u30ea\u30de\u30a4\u30f3\u30c0\u30fc\u300d\u304c\u8a31\u53ef\u3055\u308c\u308b\u307e\u3067\u3001Android\u304c\u6642\u523b\u6307\u5b9a\u306e\u901a\u77e5\u3092\u9045\u3089\u305b\u308b\u5834\u5408\u304c\u3042\u308a\u307e\u3059\u3002"],t.s)
A.yU=s(["Erlauben","Permitir","Autoriser","Consenti","Permitir","\u8a31\u53ef"],t.s)
A.JL=s(["Dieser Drache ist gerade auf einem Abenteuer.","Este drag\xf3n est\xe1 actualmente en una Aventura.","Ce dragon est actuellement parti en Aventure.","Questo drago \xe8 attualmente in Avventura.","Este drag\xe3o est\xe1 atualmente em uma Aventura.","\u3053\u306e\u30c9\u30e9\u30b4\u30f3\u306f\u73fe\u5728\u30a2\u30c9\u30d9\u30f3\u30c1\u30e3\u30fc\u4e2d\u3067\u3059\u3002"],t.s)
A.CY=s(["Musikbox","Gramola","Jukebox","Jukebox","Jukebox","\u30b8\u30e5\u30fc\u30af\u30dc\u30c3\u30af\u30b9"],t.s)
A.rM=s(["Hintergrundmusik","M\xfasica de fondo","Musique de fond","Musica di sottofondo","M\xfasica de fundo","BGM"],t.s)
A.kN=s(["Portr\xe4ttruhen kosten im Shop 100 Juwelen und enth\xfcllen immer ein Portr\xe4t, das du noch nicht besitzt.","Los Cofres de retratos cuestan 100 gemas en la Tienda y siempre revelan un retrato que a\xfan no tienes.","Les Coffres de portraits co\xfbtent 100 gemmes dans la Boutique et r\xe9v\xe8lent toujours un portrait que tu ne poss\xe8des pas.","I Forzieri ritratto costano 100 gemme nel Negozio e rivelano sempre un ritratto che non possiedi.","Ba\xfas de retrato custam 100 gemas na Loja e sempre revelam um retrato que voc\xea ainda n\xe3o possui.","\u30dd\u30fc\u30c8\u30ec\u30fc\u30c8\u5b9d\u7bb1\u306f\u30b7\u30e7\u30c3\u30d7\u3067100\u30b8\u30a7\u30e0\u304b\u304b\u308a\u3001\u672a\u6240\u6301\u306e\u30dd\u30fc\u30c8\u30ec\u30fc\u30c8\u304c\u5fc5\u305a\u51fa\u307e\u3059\u3002"],t.s)
A.HZ=s(["Abenteuer abbrechen","Abortar aventura","Abandonner l\u2019aventure","Interrompi avventura","Abortar aventura","\u5192\u967a\u3092\u4e2d\u6b62"],t.s)
A.Fl=s(["Abenteuer abbrechen?","\xbfAbortar la aventura?","Abandonner l\u2019aventure ?","Interrompere l\u2019avventura?","Abortar a aventura?","\u5192\u967a\u3092\u4e2d\u6b62\u3057\u307e\u3059\u304b\uff1f"],t.s)
A.uG=s(["Weitermachen","Continuar","Continuer","Continua","Continuar","\u7d9a\u3051\u308b"],t.s)
A.GE=s(["Abbrechen","Abortar","Abandonner","Interrompi","Abortar","\u4e2d\u6b62"],t.s)
A.lC=s(["Abenteuer abgebrochen. Dein Drache ist wieder verf\xfcgbar.","Aventura abortada. Tu drag\xf3n vuelve a estar disponible.","Aventure abandonn\xe9e. Ton dragon est de nouveau disponible.","Avventura interrotta. Il tuo drago \xe8 di nuovo disponibile.","Aventura abortada. Seu drag\xe3o est\xe1 dispon\xedvel novamente.","\u5192\u967a\u3092\u4e2d\u6b62\u3057\u307e\u3057\u305f\u3002\u30c9\u30e9\u30b4\u30f3\u306f\u518d\u3073\u5229\u7528\u3067\u304d\u307e\u3059\u3002"],t.s)
A.JG=s(["Meisterschaft","Maestr\xeda","Ma\xeetrise","Maestria","Maestria","\u6975\u610f"],t.s)
A.rX=s(["Drachen filtern","Filtrar dragones","Filtrer les dragons","Filtra draghi","Filtrar drag\xf5es","\u30c9\u30e9\u30b4\u30f3\u3092\u7d5e\u308a\u8fbc\u3080"],t.s)
A.tb=s(["Keine Drachen entsprechen diesen Filtern.","Ning\xfan drag\xf3n coincide con estos filtros.","Aucun dragon ne correspond \xe0 ces filtres.","Nessun drago corrisponde a questi filtri.","Nenhum drag\xe3o corresponde a estes filtros.","\u6761\u4ef6\u306b\u5408\u3046\u30c9\u30e9\u30b4\u30f3\u306f\u3044\u307e\u305b\u3093\u3002"],t.s)
A.Gx=s(["L\xf6schen","Limpiar","Effacer","Azzera","Limpar","\u30af\u30ea\u30a2"],t.s)
A.A0=s(["Form","Forma","Forme","Forma","Forma","\u5f62\u614b"],t.s)
A.nE=s(["Nur Spektral","Solo espectrales","Spectraux uniquement","Solo spettrali","Apenas espectrais","\u30b9\u30da\u30af\u30c8\u30e9\u30eb\u306e\u307f"],t.s)
A.En=s(["Drachen anzeigen","Mostrar dragones","Afficher les dragons","Mostra draghi","Mostrar drag\xf5es","\u30c9\u30e9\u30b4\u30f3\u3092\u8868\u793a"],t.s)
A.HF=s(["Zwillingssternbrosche ablegen","Desequipar Broche Estrella Gemela","Retirer la Broche aux \xe9toiles jumelles","Rimuovi Spilla Stella Gemella","Desequipar Broche Estrela G\xeamea","\u53cc\u661f\u306e\u30d6\u30ed\u30fc\u30c1\u3092\u5916\u3059"],t.s)
A.Lo=s(["Zwillingssternbrosche anlegen","Equipar Broche Estrella Gemela","\xc9quiper la Broche aux \xe9toiles jumelles","Equipaggia Spilla Stella Gemella","Equipar Broche Estrela G\xeamea","\u53cc\u661f\u306e\u30d6\u30ed\u30fc\u30c1\u3092\u88c5\u5099"],t.s)
A.vJ=s(["Zwillingssternbrosche hierher verschieben","Mover aqu\xed el Broche Estrella Gemela","D\xe9placer ici la Broche aux \xe9toiles jumelles","Sposta qui la Spilla Stella Gemella","Mover o Broche Estrela G\xeamea para c\xe1","\u53cc\u661f\u306e\u30d6\u30ed\u30fc\u30c1\u3092\u3053\u3053\u3078\u79fb\u3059"],t.s)
A.Jm=s(["Verdoppelt angelegt alle EP","Duplica toda la EXP mientras est\xe1 equipado","Double toute l\u2019EXP lorsqu\u2019elle est \xe9quip\xe9e","Raddoppia tutti i PE quando \xe8 equipaggiata","Duplica toda a EXP enquanto equipado","\u88c5\u5099\u4e2d\u306f\u3059\u3079\u3066\u306e\u7d4c\u9a13\u5024\u304c2\u500d"],t.s)
A.Js=s(["Dieser Drache verl\xe4sst deine Sammlung und kann nicht trainiert werden. Identit\xe4t, Form, Gesinnung und verborgene Pers\xf6nlichkeit bleiben erhalten. Jeden Tag besteht zu einer zuf\xe4lligen Zeit eine R\xfcckkehrchance von 10 %.","Este drag\xf3n abandona tu colecci\xf3n y no puede entrenarse. Se conservan su identidad, forma, alineamiento y personalidad oculta. Cada d\xeda tiene un 10 % de probabilidad de volver a una hora aleatoria.","Ce dragon quitte ta collection et ne peut plus \xeatre entra\xeen\xe9. Son identit\xe9, sa forme, son alignement et sa personnalit\xe9 cach\xe9e sont conserv\xe9s. Chaque jour, il a 10 % de chances de revenir \xe0 une heure al\xe9atoire.","Questo drago lascia la collezione e non pu\xf2 essere addestrato. Identit\xe0, forma, allineamento e personalit\xe0 nascosta restano invariati. Ogni giorno ha il 10% di probabilit\xe0 di tornare a un\u2019ora casuale.","Este drag\xe3o deixa sua cole\xe7\xe3o e n\xe3o pode ser treinado. Identidade, forma, alinhamento e personalidade oculta s\xe3o preservados. A cada dia, h\xe1 10% de chance de voltar em um hor\xe1rio aleat\xf3rio.","\u3053\u306e\u30c9\u30e9\u30b4\u30f3\u306f\u30b3\u30ec\u30af\u30b7\u30e7\u30f3\u3092\u96e2\u308c\u3001\u8a13\u7df4\u3067\u304d\u306a\u304f\u306a\u308a\u307e\u3059\u3002\u500b\u4f53\u3001\u5f62\u614b\u3001\u5c5e\u6027\u3001\u96a0\u308c\u305f\u6027\u683c\u306f\u4fdd\u6301\u3055\u308c\u307e\u3059\u3002\u6bce\u65e5\u30e9\u30f3\u30c0\u30e0\u306a\u6642\u523b\u306b10%\u306e\u78ba\u7387\u3067\u623b\u308a\u307e\u3059\u3002"],t.s)
A.jN=s(["Brutzeit","Tiempo de eclosi\xf3n","Temps d\u2019incubation","Tempo di schiusa","Tempo de incuba\xe7\xe3o","\u5b75\u5316\u6642\u9593"],t.s)
A.GD=s(["Liste anzeigen","Mostrar lista","Afficher la liste","Mostra elenco","Mostrar lista","\u30ea\u30b9\u30c8\u8868\u793a"],t.s)
A.Bf=s(["Kacheln anzeigen","Mostrar mosaicos","Afficher les tuiles","Mostra riquadri","Mostrar blocos","\u30bf\u30a4\u30eb\u8868\u793a"],t.s)
A.Kr=s([" \xb7 Reserviert"," \xb7 Reservado"," \xb7 R\xe9serv\xe9"," \xb7 Riservato"," \xb7 Reservado"," \xb7 \u4e88\u7d04\u6e08\u307f"],t.s)
A.yP=s(["Seltenheit mit Astrallinse enth\xfcllen","Revelar rareza con la Lente Astral","R\xe9v\xe9ler la raret\xe9 avec la Lentille astrale","Rivela rarit\xe0 con la Lente Astrale","Revelar raridade com a Lente Astral","\u661f\u754c\u306e\u30ec\u30f3\u30ba\u3067\u30ec\u30a2\u5ea6\u3092\u660e\u304b\u3059"],t.s)
A.wB=s(["Musiksammlung vollst\xe4ndig","Colecci\xf3n musical completa","Collection musicale compl\xe8te","Collezione musicale completa","Cole\xe7\xe3o musical completa","\u97f3\u697d\u30b3\u30ec\u30af\u30b7\u30e7\u30f3\u5b8c\u6210"],t.s)
A.qV=s(["Du besitzt bereits alle Lieder. Diese Musiktruhe bleibt sicher in deinem Inventar und kann nicht ge\xf6ffnet werden.","Ya tienes todas las canciones. Este Cofre musical permanece a salvo en tu Inventario y no puede abrirse.","Tu poss\xe8des d\xe9j\xe0 tous les morceaux. Ce Coffre musical reste en s\xe9curit\xe9 dans ton Inventaire et ne peut pas \xeatre ouvert.","Possiedi gi\xe0 tutti i brani. Questo Forziere musicale resta al sicuro nell\u2019Inventario e non pu\xf2 essere aperto.","Voc\xea j\xe1 possui todas as m\xfasicas. Este Ba\xfa musical fica seguro no Invent\xe1rio e n\xe3o pode ser aberto.","\u3059\u3079\u3066\u306e\u66f2\u3092\u6240\u6301\u3057\u3066\u3044\u307e\u3059\u3002\u3053\u306e\u97f3\u697d\u5b9d\u7bb1\u306f\u30a4\u30f3\u30d9\u30f3\u30c8\u30ea\u306b\u5b89\u5168\u306b\u6b8b\u308a\u3001\u958b\u3051\u308b\u3053\u3068\u306f\u3067\u304d\u307e\u305b\u3093\u3002"],t.s)
A.Bd=s(["Typ","Tipo","Type","Tipo","Tipo","\u7a2e\u985e"],t.s)
A.xE=s(["Betten","Camas","Lits","Letti","Camas","\u30d9\u30c3\u30c9"],t.s)
A.Ew=s(["Pflanzen","Plantas","Plantes","Piante","Plantas","\u690d\u7269"],t.s)
A.nM=s(["Lichter","Luces","Lumi\xe8res","Luci","Luzes","\u7167\u660e"],t.s)
A.wo=s(["Keine M\xf6bel entsprechen diesen Filtern.","Ning\xfan mueble coincide con estos filtros.","Aucun meuble ne correspond \xe0 ces filtres.","Nessun mobile corrisponde a questi filtri.","Nenhum m\xf3vel corresponde a estes filtros.","\u6761\u4ef6\u306b\u5408\u3046\u5bb6\u5177\u306f\u3042\u308a\u307e\u305b\u3093\u3002"],t.s)
A.Ib=s(["M\xf6bel filtern","Filtrar muebles","Filtrer les meubles","Filtra mobili","Filtrar m\xf3veis","\u5bb6\u5177\u3092\u7d5e\u308a\u8fbc\u3080"],t.s)
A.CL=s(["Nur platziert","Solo colocados","Plac\xe9s uniquement","Solo posizionati","Apenas posicionados","\u914d\u7f6e\u6e08\u307f\u306e\u307f"],t.s)
A.o6=s(["M\xf6bel anzeigen","Mostrar muebles","Afficher les meubles","Mostra mobili","Mostrar m\xf3veis","\u5bb6\u5177\u3092\u8868\u793a"],t.s)
A.yg=s(["Nicht ausger\xfcstet","Sin equipar","Non \xe9quip\xe9","Non equipaggiato","N\xe3o equipado","\u672a\u88c5\u5099"],t.s)
A.mI=s(["Von einem Drachen getragen","Equipado a un drag\xf3n","\xc9quip\xe9 sur un dragon","Equipaggiato a un drago","Equipado em um drag\xe3o","\u30c9\u30e9\u30b4\u30f3\u304c\u88c5\u5099\u4e2d"],t.s)
A.BN=s(["Ei im Dachnest","Huevo en el nido de la azotea","\u0152uf dans le nid du toit","Uovo nel nido sul tetto","Ovo no ninho do terra\xe7o","\u5c4b\u4e0a\u306e\u5de3\u306e\u5375"],t.s)
A.uN=s(["Inventar-Ei","Huevo del inventario","\u0152uf de l\u2019inventaire","Uovo nell\u2019inventario","Ovo do invent\xe1rio","\u30a4\u30f3\u30d9\u30f3\u30c8\u30ea\u306e\u5375"],t.s)
A.nn=s(["Es gibt kein Ei mit unbekannter Seltenheit.","No hay ning\xfan huevo de rareza desconocida.","Il n\u2019y a aucun \u0153uf \xe0 la raret\xe9 inconnue.","Non ci sono uova di rarit\xe0 sconosciuta.","N\xe3o h\xe1 ovo com raridade desconhecida.","\u30ec\u30a2\u5ea6\u304c\u4e0d\u660e\u306a\u5375\u306f\u3042\u308a\u307e\u305b\u3093\u3002"],t.s)
A.u3=s(["Welches Ei enth\xfcllen?","\xbfQu\xe9 huevo revelar?","Quel \u0153uf r\xe9v\xe9ler ?","Quale uovo rivelare?","Revelar qual ovo?","\u3069\u306e\u5375\u3092\u660e\u304b\u3057\u307e\u3059\u304b\uff1f"],t.s)
A.zf=s(["Seltenheit ist noch verborgen","La rareza sigue oculta","La raret\xe9 est encore cach\xe9e","La rarit\xe0 \xe8 ancora nascosta","A raridade ainda est\xe1 oculta","\u30ec\u30a2\u5ea6\u306f\u307e\u3060\u4e0d\u660e"],t.s)
A.GB=s(["Seltenheit enth\xfcllt","Rareza revelada","Raret\xe9 r\xe9v\xe9l\xe9e","Rarit\xe0 rivelata","Raridade revelada","\u30ec\u30a2\u5ea6\u5224\u660e"],t.s)
A.uX=s(["Fertig","Listo","Termin\xe9","Fatto","Conclu\xeddo","\u5b8c\u4e86"],t.s)
A.Ek=s(["Lege zuerst ein Ei ins Dachnest.","Primero coloca un huevo en el nido de la azotea.","Place d\u2019abord un \u0153uf dans le nid du toit.","Prima metti un uovo nel nido sul tetto.","Primeiro coloque um ovo no ninho do terra\xe7o.","\u5148\u306b\u5c4b\u4e0a\u306e\u5de3\u3078\u5375\u3092\u7f6e\u3044\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.Eb=s(["Chronosplitter w\xe4hlen","Elegir un Cronofragmento","Choisir un Chrono-\xe9clat","Scegli un Cronoframmento","Escolher um Cronofragmento","\u30af\u30ed\u30ce\u30b7\u30e3\u30fc\u30c9\u3092\u9078\u3076"],t.s)
A.pD=s(["Sein Prozentsatz wurde beim Fund dieses Relikts festgelegt.","Su porcentaje qued\xf3 fijado al encontrar esta reliquia.","Son pourcentage a \xe9t\xe9 fix\xe9 lorsque cette relique a \xe9t\xe9 trouv\xe9e.","La percentuale \xe8 stata fissata al ritrovamento della reliquia.","A porcentagem foi definida quando esta rel\xedquia foi encontrada.","\u5272\u5408\u306f\u3053\u306e\u30ec\u30ea\u30c3\u30af\u3092\u5165\u624b\u3057\u305f\u6642\u306b\u78ba\u5b9a\u3057\u307e\u3057\u305f\u3002"],t.s)
A.AJ=s(["Verbleibende Brutzeit verk\xfcrzen","Acortar incubaci\xf3n restante","Raccourcir l\u2019incubation restante","Riduci incubazione restante","Reduzir incuba\xe7\xe3o restante","\u6b8b\u308a\u306e\u5b75\u5316\u6642\u9593\u3092\u77ed\u7e2e"],t.s)
A.o3=s(["Abenteuertyp w\xe4hlen","Elegir tipo de aventura","Choisir le type d\u2019aventure","Scegli il tipo di avventura","Escolher tipo de aventura","\u5192\u967a\u30bf\u30a4\u30d7\u3092\u9078\u3076"],t.s)
A.l7=s(["Wegfindersiegel verwenden","Usar Sigilo Buscarrutas","Utiliser le Sceau du guide","Usa Sigillo del Viandante","Usar Sigilo do Desbravador","\u9053\u6a19\u306e\u5370\u7ae0\u3092\u4f7f\u3046"],t.s)
A.kj=s(["Zus\xe4tzliches Abenteuer erstellen","Crear una aventura adicional","Cr\xe9er une aventure suppl\xe9mentaire","Crea un\u2019avventura aggiuntiva","Criar uma aventura extra","\u5192\u967a\u30921\u3064\u8ffd\u52a0"],t.s)
A.CM=s(["Dieses Abenteuer neu w\xfcrfeln","Volver a generar esta aventura","Relancer cette aventure","Rigenera questa avventura","Gerar novamente esta aventura","\u3053\u306e\u5192\u967a\u3092\u518d\u62bd\u9078"],t.s)
A.oH=s(["Die Abenteueroptionen haben sich ge\xe4ndert.","Las opciones de aventura han cambiado.","Les choix d\u2019aventure ont chang\xe9.","Le scelte di avventura sono cambiate.","As op\xe7\xf5es de aventura mudaram.","\u5192\u967a\u306e\u5019\u88dc\u304c\u5909\u308f\u308a\u307e\u3057\u305f\u3002"],t.s)
A.Hm=s(["Zwillingssternbrosche","Broche Estrella Gemela","Broche aux \xe9toiles jumelles","Spilla Stella Gemella","Broche Estrela G\xeamea","\u53cc\u661f\u306e\u30d6\u30ed\u30fc\u30c1"],t.s)
A.Hs=s(["Nur der aktuelle Tr\xe4ger erh\xe4lt doppelte EP.","Solo quien la lleve recibe el doble de EXP.","Seul son porteur actuel re\xe7oit le double d\u2019EXP.","Solo chi la indossa riceve PE doppi.","Apenas quem estiver usando recebe EXP em dobro.","\u73fe\u5728\u306e\u88c5\u5099\u8005\u3060\u3051\u304c\u7d4c\u9a13\u50242\u500d\u306b\u306a\u308a\u307e\u3059\u3002"],t.s)
A.pv=s(["Ablegen","Desequipar","Retirer","Rimuovi","Desequipar","\u5916\u3059"],t.s)
A.kl=s(["Zuf\xe4llig","Aleatorio","Al\xe9atoire","Casuale","Aleat\xf3rio","\u30b7\u30e3\u30c3\u30d5\u30eb"],t.s)
A.yE=s(["Wiederholen","Repetir","R\xe9p\xe9ter","Ripeti","Repetir","\u30ea\u30d4\u30fc\u30c8"],t.s)
A.oW=s(["Zuf\xe4llig \xe4ndert die Reihenfolge. Wiederholen startet einen neuen vollst\xe4ndigen Durchlauf, nachdem alle ausgew\xe4hlten Titel gespielt wurden.","Aleatorio cambia el orden. Repetir inicia un ciclo completo nuevo cuando han sonado todas las pistas seleccionadas.","Al\xe9atoire change l\u2019ordre. R\xe9p\xe9ter lance un nouveau cycle complet lorsque tous les morceaux s\xe9lectionn\xe9s ont \xe9t\xe9 jou\xe9s.","Casuale cambia l\u2019ordine. Ripeti avvia un nuovo ciclo completo dopo la riproduzione di tutti i brani selezionati.","Aleat\xf3rio muda a ordem. Repetir inicia um novo ciclo completo ap\xf3s tocar todas as faixas selecionadas.","\u30b7\u30e3\u30c3\u30d5\u30eb\u306f\u66f2\u9806\u3092\u5909\u3048\u307e\u3059\u3002\u30ea\u30d4\u30fc\u30c8\u306f\u9078\u629e\u66f2\u3092\u3059\u3079\u3066\u518d\u751f\u3057\u305f\u5f8c\u3001\u65b0\u3057\u3044\u4e00\u5de1\u3092\u59cb\u3081\u307e\u3059\u3002"],t.s)
A.AA=s(["Keine Titel ausgew\xe4hlt","No hay pistas seleccionadas","Aucun morceau s\xe9lectionn\xe9","Nessun brano selezionato","Nenhuma faixa selecionada","\u66f2\u304c\u9078\u629e\u3055\u308c\u3066\u3044\u307e\u305b\u3093"],t.s)
A.IN=s(["Die Hintergrundmusik bleibt stumm, bis du einen Titel aktivierst.","La m\xfasica de fondo permanecer\xe1 en silencio hasta que actives una pista.","La musique de fond reste silencieuse jusqu\u2019\xe0 ce que tu actives un morceau.","La musica di sottofondo resta silenziosa finch\xe9 non attivi un brano.","A m\xfasica de fundo fica silenciosa at\xe9 voc\xea ativar uma faixa.","\u66f2\u3092\u6709\u52b9\u306b\u3059\u308b\u307e\u3067BGM\u306f\u6d41\u308c\u307e\u305b\u3093\u3002"],t.s)
A.Hu=s(["Deine Musik","Tu m\xfasica","Ta musique","La tua musica","Suas m\xfasicas","\u3042\u306a\u305f\u306e\u97f3\u697d"],t.s)
A.kM=s(["Dieses Relikt ist nicht im Shop erh\xe4ltlich.","Esta reliquia no est\xe1 disponible en la tienda.","Cette relique n\u2019est pas disponible dans la boutique.","Questa reliquia non \xe8 disponibile nel negozio.","Esta rel\xedquia n\xe3o est\xe1 dispon\xedvel na loja.","\u3053\u306e\u30ec\u30ea\u30c3\u30af\u306f\u30b7\u30e7\u30c3\u30d7\u3067\u306f\u5165\u624b\u3067\u304d\u307e\u305b\u3093\u3002"],t.s)
A.Ks=s(["Enth\xe4lt ein zuf\xe4lliges Lied, das du noch nicht besitzt. Der Inhalt wird erst beim \xd6ffnen bestimmt.","Contiene una canci\xf3n aleatoria que no tienes. El contenido se decide al abrirlo.","Contient un morceau al\xe9atoire que tu ne poss\xe8des pas. Son contenu est d\xe9cid\xe9 \xe0 l\u2019ouverture.","Contiene un brano casuale che non possiedi. Il contenuto viene deciso solo all\u2019apertura.","Cont\xe9m uma m\xfasica aleat\xf3ria que voc\xea n\xe3o possui. O conte\xfado \xe9 decidido ao abrir.","\u672a\u6240\u6301\u306e\u66f2\u304c\u30e9\u30f3\u30c0\u30e0\u30671\u66f2\u5165\u3063\u3066\u3044\u307e\u3059\u3002\u4e2d\u8eab\u306f\u958b\u5c01\u6642\u306b\u6c7a\u307e\u308a\u307e\u3059\u3002"],t.s)
A.lF=s(["Musiktruhe deinem Inventar hinzugef\xfcgt.","Cofre musical a\xf1adido a tu Inventario.","Coffre musical ajout\xe9 \xe0 ton Inventaire.","Forziere musicale aggiunto all\u2019Inventario.","Ba\xfa musical adicionado ao Invent\xe1rio.","\u97f3\u697d\u5b9d\u7bb1\u3092\u30a4\u30f3\u30d9\u30f3\u30c8\u30ea\u306b\u8ffd\u52a0\u3057\u307e\u3057\u305f\u3002"],t.s)
A.EU=s(["Alle Lieder sind bereits im Besitz oder durch eine unge\xf6ffnete Musiktruhe abgedeckt.","Ya tienes todas las canciones o est\xe1n cubiertas por un Cofre musical sin abrir.","Tous les morceaux sont d\xe9j\xe0 poss\xe9d\xe9s ou couverts par un Coffre musical non ouvert.","Ogni brano \xe8 gi\xe0 posseduto o coperto da un Forziere musicale chiuso.","Todas as m\xfasicas j\xe1 foram obtidas ou est\xe3o cobertas por um Ba\xfa musical fechado.","\u5168\u66f2\u3092\u6240\u6301\u3057\u3066\u3044\u308b\u304b\u3001\u672a\u958b\u5c01\u306e\u97f3\u697d\u5b9d\u7bb1\u3067\u78ba\u4fdd\u6e08\u307f\u3067\u3059\u3002"],t.s)
A.nS=s(["VERBLEIBENDE WERTUNGSVERSUCHE","TURNOS DE PUNTUACI\xd3N RESTANTES","TOURS DE SCORE RESTANTS","TURNI PUNTEGGIO RIMASTI","TURNOS DE PONTUA\xc7\xc3O RESTANTES","\u6b8b\u308a\u5f97\u70b9\u30bf\u30fc\u30f3"],t.s)
A.Ge=s(["Verbleibende Fehler","Fallos restantes","Erreurs restantes","Errori rimasti","Erros restantes","\u6b8b\u308a\u30df\u30b9"],t.s)
A.L0=s(["Zur Musikbox hinzugef\xfcgt","A\xf1adido a tu Gramola","Ajout\xe9 \xe0 ta Jukebox","Aggiunto al Jukebox","Adicionado \xe0 sua Jukebox","\u30b8\u30e5\u30fc\u30af\u30dc\u30c3\u30af\u30b9\u306b\u8ffd\u52a0"],t.s)
A.qj=s(["Der Onlinedienst hat zu lange gebraucht. Dein lokaler Spielstand ist sicher; versuche es erneut.","El servicio en l\xednea tard\xf3 demasiado. Tu partida local est\xe1 a salvo; int\xe9ntalo de nuevo.","Le service en ligne a pris trop de temps. Ta partie locale est en s\xe9curit\xe9 ; r\xe9essaie.","Il servizio online ha impiegato troppo tempo. La partita locale \xe8 al sicuro; riprova.","O servi\xe7o online demorou demais. Seu jogo local est\xe1 seguro; tente novamente.","\u30aa\u30f3\u30e9\u30a4\u30f3\u30b5\u30fc\u30d3\u30b9\u304c\u30bf\u30a4\u30e0\u30a2\u30a6\u30c8\u3057\u307e\u3057\u305f\u3002\u7aef\u672b\u306e\u30b2\u30fc\u30e0\u30c7\u30fc\u30bf\u306f\u5b89\u5168\u3067\u3059\u3002\u3082\u3046\u4e00\u5ea6\u304a\u8a66\u3057\u304f\u3060\u3055\u3044\u3002"],t.s)
A.wT=s(["Deine Online-Sitzung ist abgelaufen. Melde dich erneut an.","Tu sesi\xf3n en l\xednea ha caducado. Inicia sesi\xf3n de nuevo.","Votre session en ligne a expir\xe9. Reconnectez-vous.","La sessione online \xe8 scaduta. Accedi di nuovo.","Sua sess\xe3o online expirou. Entre novamente.","\u30aa\u30f3\u30e9\u30a4\u30f3\u30bb\u30c3\u30b7\u30e7\u30f3\u306e\u6709\u52b9\u671f\u9650\u304c\u5207\u308c\u307e\u3057\u305f\u3002\u3082\u3046\u4e00\u5ea6\u30ed\u30b0\u30a4\u30f3\u3057\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.Fc=s(["Astrallinse","Lente Astral","Lentille astrale","Lente Astrale","Lente Astral","\u661f\u754c\u306e\u30ec\u30f3\u30ba"],t.s)
A.oD=s(["Chronosplitter","Cronofragmento","Chrono-\xe9clat","Cronoframmento","Cronofragmento","\u30af\u30ed\u30ce\u30b7\u30e3\u30fc\u30c9"],t.s)
A.Jq=s(["Wegfindersiegel","Sigilo Buscarrutas","Sceau du guide","Sigillo del Viandante","Sigilo do Desbravador","\u9053\u6a19\u306e\u5370\u7ae0"],t.s)
A.pH=s(["Enth\xfcllt nur die verborgene Seltenheit eines noch nicht geschl\xfcpften Dracheneis.","Solo revela la rareza oculta de un huevo de drag\xf3n sin eclosionar.","R\xe9v\xe8le uniquement la raret\xe9 cach\xe9e d\u2019un \u0153uf de dragon non \xe9clos.","Rivela solo la rarit\xe0 nascosta di un uovo di drago non schiuso.","Revela apenas a raridade oculta de um ovo de drag\xe3o ainda n\xe3o chocado.","\u672a\u5b75\u5316\u306e\u30c9\u30e9\u30b4\u30f3\u306e\u53751\u500b\u306e\u96a0\u308c\u305f\u30ec\u30a2\u5ea6\u3060\u3051\u3092\u660e\u304b\u3057\u307e\u3059\u3002"],t.s)
A.k1=s(["Verk\xfcrzt die verbleibende Brutzeit des Eies im Nest um seinen festgelegten Prozentsatz.","Acorta el tiempo de incubaci\xf3n restante del huevo del nido seg\xfan su porcentaje fijado.","R\xe9duit le temps d\u2019incubation restant de l\u2019\u0153uf dans le nid selon son pourcentage fix\xe9.","Riduce il tempo di incubazione restante dell\u2019uovo nel nido della percentuale fissata.","Reduz o tempo de incuba\xe7\xe3o restante do ovo no ninho pela porcentagem definida.","\u5de3\u306b\u3042\u308b\u5375\u306e\u6b8b\u308a\u5b75\u5316\u6642\u9593\u3092\u3001\u78ba\u5b9a\u6e08\u307f\u306e\u5272\u5408\u3060\u3051\u77ed\u7e2e\u3057\u307e\u3059\u3002"],t.s)
A.uW=s(["W\xfcrfelt ein gew\xe4hltes Abenteuer neu oder erstellt bei freiem Platz ein neues Abenteuer des gew\xe4hlten Typs.","Vuelve a generar una aventura elegida o crea una nueva del tipo elegido cuando hay espacio.","Relance une aventure choisie ou cr\xe9e une nouvelle aventure du type choisi si une place est libre.","Rigenera un\u2019avventura scelta o ne crea una nuova del tipo scelto quando c\u2019\xe8 spazio.","Gera novamente uma aventura escolhida ou cria uma nova do tipo escolhido quando h\xe1 espa\xe7o.","\u9078\u3093\u3060\u5192\u967a\u3092\u518d\u62bd\u9078\u3059\u308b\u304b\u3001\u7a7a\u304d\u304c\u3042\u308c\u3070\u9078\u3093\u3060\u30bf\u30a4\u30d7\u306e\u5192\u967a\u3092\u65b0\u3057\u304f\u4f5c\u308a\u307e\u3059\u3002"],t.s)
A.zl=s(["Ein einzigartiges ausr\xfcstbares Relikt, das alle erhaltenen EP nur verdoppelt, solange der gew\xe4hlte Drache es tr\xe4gt.","Una reliquia equipable \xfanica que duplica toda la EXP recibida solo mientras la lleva el drag\xf3n elegido.","Une relique unique \xe0 \xe9quiper qui double toute l\u2019EXP re\xe7ue uniquement lorsque le dragon choisi la porte.","Una reliquia equipaggiabile unica che raddoppia tutti i PE ricevuti solo mentre il drago scelto la indossa.","Uma rel\xedquia equip\xe1vel \xfanica que duplica toda a EXP recebida apenas enquanto o drag\xe3o escolhido a usa.","\u9078\u3093\u3060\u30c9\u30e9\u30b4\u30f3\u304c\u88c5\u5099\u3057\u3066\u3044\u308b\u9593\u3060\u3051\u3001\u7372\u5f97\u7d4c\u9a13\u5024\u3092\u3059\u3079\u30662\u500d\u306b\u3059\u308b\u552f\u4e00\u306e\u88c5\u5099\u30ec\u30ea\u30c3\u30af\u3067\u3059\u3002"],t.s)
A.qI=s(["Supportdiagnose kopieren","Copiar diagn\xf3stico de soporte","Copier le diagnostic d\u2019assistance","Copia diagnostica di supporto","Copiar diagn\xf3stico de suporte","\u30b5\u30dd\u30fc\u30c8\u8a3a\u65ad\u3092\u30b3\u30d4\u30fc"],t.s)
A.vp=s(["Enth\xe4lt technische IDs und Zeitangaben, niemals dein Passwort, deine E-Mail-Adresse oder deinen Spielstand.","Contiene identificadores t\xe9cnicos y tiempos, nunca tu contrase\xf1a, correo electr\xf3nico ni partida guardada.","Contient des identifiants techniques et des dur\xe9es, jamais ton mot de passe, ton e-mail ni ta sauvegarde.","Contiene ID tecnici e tempi, mai la password, l\u2019e-mail o il salvataggio del gioco.","Cont\xe9m IDs t\xe9cnicos e tempos, nunca sua senha, e-mail ou jogo salvo.","\u6280\u8853\u7684\u306aID\u3068\u51e6\u7406\u6642\u9593\u306e\u307f\u304c\u542b\u307e\u308c\u3001\u30d1\u30b9\u30ef\u30fc\u30c9\u3001\u30e1\u30fc\u30eb\u30a2\u30c9\u30ec\u30b9\u3001\u30b2\u30fc\u30e0\u30c7\u30fc\u30bf\u306f\u542b\u307e\u308c\u307e\u305b\u3093\u3002"],t.s)
A.Em=s(["Supportdiagnose kopiert. Teile sie nur mit dem vertrauensw\xfcrdigen DragonHaven-Support.","Diagn\xf3stico de soporte copiado. Comp\xe1rtelo solo con el soporte de confianza de DragonHaven.","Diagnostic d\u2019assistance copi\xe9. Partage-le uniquement avec l\u2019assistance DragonHaven de confiance.","Diagnostica di supporto copiata. Condividila solo con l\u2019assistenza DragonHaven fidata.","Diagn\xf3stico de suporte copiado. Compartilhe somente com o suporte confi\xe1vel do DragonHaven.","\u30b5\u30dd\u30fc\u30c8\u8a3a\u65ad\u3092\u30b3\u30d4\u30fc\u3057\u307e\u3057\u305f\u3002\u4fe1\u983c\u3067\u304d\u308bDragonHaven\u30b5\u30dd\u30fc\u30c8\u3068\u306e\u307f\u5171\u6709\u3057\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.Ho=s(["Anderer Cloud-Fortschritt gefunden","Se encontr\xf3 un progreso diferente en la nube","Une progression diff\xe9rente a \xe9t\xe9 trouv\xe9e dans le cloud","Trovati progressi cloud differenti","Foi encontrado um progresso diferente na nuvem","\u7570\u306a\u308b\u30af\u30e9\u30a6\u30c9\u9032\u884c\u72b6\u6cc1\u304c\u898b\u3064\u304b\u308a\u307e\u3057\u305f"],t.s)
A.kK=s(["Vorerst lokal behalten","Mantener local por ahora","Garder la version locale pour le moment","Mantieni locale per ora","Manter local por enquanto","\u4eca\u306f\u30ed\u30fc\u30ab\u30eb\u7248\u3092\u4fdd\u6301"],t.s)
A.kz=s(["Cloud wiederherstellen","Restaurar desde la nube","Restaurer depuis le cloud","Ripristina dal cloud","Restaurar da nuvem","\u30af\u30e9\u30a6\u30c9\u7248\u3092\u5fa9\u5143"],t.s)
A.uu=s(["Cloud-Fortschritt wiederhergestellt. Eine lokale Wiederherstellungskopie wurde behalten.","Progreso de la nube restaurado. Se conserv\xf3 una copia de recuperaci\xf3n local.","Progression du cloud restaur\xe9e. Une copie de r\xe9cup\xe9ration locale a \xe9t\xe9 conserv\xe9e.","Progressi cloud ripristinati. \xc8 stata conservata una copia di recupero locale.","Progresso da nuvem restaurado. Uma c\xf3pia de recupera\xe7\xe3o local foi mantida.","\u30af\u30e9\u30a6\u30c9\u306e\u9032\u884c\u72b6\u6cc1\u3092\u5fa9\u5143\u3057\u307e\u3057\u305f\u3002\u30ed\u30fc\u30ab\u30eb\u306e\u5fa9\u65e7\u7528\u30b3\u30d4\u30fc\u306f\u4fdd\u6301\u3055\u308c\u3066\u3044\u307e\u3059\u3002"],t.s)
A.Ab=s(["Neuerer oder anderer Cloud-Fortschritt wurde gefunden. Nichts wurde \xfcberschrieben.","Se encontr\xf3 un progreso m\xe1s reciente o diferente en la nube. No se sobrescribi\xf3 nada.","Une progression plus r\xe9cente ou diff\xe9rente a \xe9t\xe9 trouv\xe9e dans le cloud. Rien n\u2019a \xe9t\xe9 \xe9cras\xe9.","Sono stati trovati progressi cloud pi\xf9 recenti o differenti. Nulla \xe8 stato sovrascritto.","Foi encontrado um progresso mais recente ou diferente na nuvem. Nada foi sobrescrito.","\u3088\u308a\u65b0\u3057\u3044\u3001\u307e\u305f\u306f\u7570\u306a\u308b\u30af\u30e9\u30a6\u30c9\u9032\u884c\u72b6\u6cc1\u304c\u898b\u3064\u304b\u308a\u307e\u3057\u305f\u3002\u4e0a\u66f8\u304d\u306f\u884c\u308f\u308c\u3066\u3044\u307e\u305b\u3093\u3002"],t.s)
A.n8=s(["Es ist noch kein Cloud-Backup verf\xfcgbar.","Todav\xeda no hay ninguna copia de seguridad en la nube disponible.","Aucune sauvegarde cloud n\u2019est encore disponible.","Non \xe8 ancora disponibile alcun backup cloud.","Ainda n\xe3o h\xe1 backup na nuvem dispon\xedvel.","\u30af\u30e9\u30a6\u30c9\u30d0\u30c3\u30af\u30a2\u30c3\u30d7\u306f\u307e\u3060\u3042\u308a\u307e\u305b\u3093\u3002"],t.s)
A.wk=s(["Das Cloud-Backup konnte nicht \xfcberpr\xfcft werden. Dein lokales Spiel wurde nicht ver\xe4ndert.","No se pudo validar la copia de seguridad en la nube. Tu partida local no ha cambiado.","La sauvegarde cloud n\u2019a pas pu \xeatre valid\xe9e. Ta partie locale n\u2019a pas \xe9t\xe9 modifi\xe9e.","Non \xe8 stato possibile convalidare il backup cloud. La partita locale non \xe8 stata modificata.","N\xe3o foi poss\xedvel validar o backup na nuvem. Seu jogo local n\xe3o foi alterado.","\u30af\u30e9\u30a6\u30c9\u30d0\u30c3\u30af\u30a2\u30c3\u30d7\u3092\u691c\u8a3c\u3067\u304d\u307e\u305b\u3093\u3067\u3057\u305f\u3002\u30ed\u30fc\u30ab\u30eb\u306e\u30b2\u30fc\u30e0\u30c7\u30fc\u30bf\u306f\u5909\u66f4\u3055\u308c\u3066\u3044\u307e\u305b\u3093\u3002"],t.s)
A.K_=s(["Dieses Backup ist zu gro\xdf f\xfcr den Onlinedienst. Dein lokales Spiel ist sicher.","Esta copia de seguridad es demasiado grande para el servicio en l\xednea. Tu partida local est\xe1 a salvo.","Cette sauvegarde est trop volumineuse pour le service en ligne. Ta partie locale est en s\xe9curit\xe9.","Questo backup \xe8 troppo grande per il servizio online. La partita locale \xe8 al sicuro.","Este backup \xe9 grande demais para o servi\xe7o online. Seu jogo local est\xe1 seguro.","\u3053\u306e\u30d0\u30c3\u30af\u30a2\u30c3\u30d7\u306f\u30aa\u30f3\u30e9\u30a4\u30f3\u30b5\u30fc\u30d3\u30b9\u306e\u4e0a\u9650\u3092\u8d85\u3048\u3066\u3044\u307e\u3059\u3002\u30ed\u30fc\u30ab\u30eb\u306e\u30b2\u30fc\u30e0\u30c7\u30fc\u30bf\u306f\u5b89\u5168\u3067\u3059\u3002"],t.s)
A.vj=s(["Supportcode","C\xf3digo de soporte","Code d\u2019assistance","Codice di supporto","C\xf3digo de suporte","\u30b5\u30dd\u30fc\u30c8\u30b3\u30fc\u30c9"],t.s)
A.vk=s(["Update verf\xfcgbar","Actualizaci\xf3n disponible","Mise \xe0 jour disponible","Aggiornamento disponibile","Atualiza\xe7\xe3o dispon\xedvel","\u30a2\u30c3\u30d7\u30c7\u30fc\u30c8\u304c\u3042\u308a\u307e\u3059"],t.s)
A.AM=s(["Eine neuere Version von DragonHaven ist bereit.","Hay una versi\xf3n m\xe1s reciente de DragonHaven disponible.","Une nouvelle version de DragonHaven est disponible.","\xc8 disponibile una nuova versione di DragonHaven.","Uma vers\xe3o mais recente de DragonHaven est\xe1 dispon\xedvel.","DragonHaven\u306e\u65b0\u3057\u3044\u30d0\u30fc\u30b8\u30e7\u30f3\u3092\u5229\u7528\u3067\u304d\u307e\u3059\u3002"],t.s)
A.AI=s(["Installierte Version","Versi\xf3n instalada","Version install\xe9e","Versione installata","Vers\xe3o instalada","\u30a4\u30f3\u30b9\u30c8\u30fc\u30eb\u6e08\u307f\u306e\u30d0\u30fc\u30b8\u30e7\u30f3"],t.s)
A.C0=s(["Neueste Version","\xdaltima versi\xf3n","Derni\xe8re version","Versione pi\xf9 recente","Vers\xe3o mais recente","\u6700\u65b0\u30d0\u30fc\u30b8\u30e7\u30f3"],t.s)
A.AZ=s(["Sp\xe4ter","M\xe1s tarde","Plus tard","Pi\xf9 tardi","Mais tarde","\u5f8c\u3067"],t.s)
A.x2=s(["Handel starten","Iniciar intercambio","Commencer l'\xe9change","Avvia scambio","Iniciar troca","\u4ea4\u63db\u3092\u958b\u59cb"],t.s)
A.lD=s(["Rekorde einklappen","Contraer r\xe9cords","Replier les records","Comprimi record","Recolher recordes","\u8a18\u9332\u3092\u6298\u308a\u305f\u305f\u3080"],t.s)
A.Dj=s(["Rekorde ausklappen","Expandir r\xe9cords","D\xe9plier les records","Espandi record","Expandir recordes","\u8a18\u9332\u3092\u5c55\u958b"],t.s)
A.Fq=s(["TAUSCH ABGESCHLOSSEN!","\xa1INTERCAMBIO COMPLETADO!","\xc9CHANGE TERMIN\xc9 !","SCAMBIO COMPLETATO!","TROCA CONCLU\xcdDA!","\u4ea4\u63db\u5b8c\u4e86\uff01"],t.s)
A.vc=s(["Der Tausch ist sicher besiegelt.","El intercambio ha quedado sellado de forma segura.","L'\xe9change est scell\xe9 en toute s\xe9curit\xe9.","Lo scambio \xe8 stato sigillato in sicurezza.","A troca foi selada com seguran\xe7a.","\u4ea4\u63db\u306f\u5b89\u5168\u306b\u78ba\u5b9a\u3055\u308c\u307e\u3057\u305f\u3002"],t.s)
A.CG=s(["DU HAST GESENDET","HAS ENVIADO","VOUS AVEZ ENVOY\xc9","HAI INVIATO","VOC\xca ENVIOU","\u3042\u306a\u305f\u304c\u6e21\u3057\u305f\u3082\u306e"],t.s)
A.nT=s(["DU HAST ERHALTEN","HAS RECIBIDO","VOUS AVEZ RE\xc7U","HAI RICEVUTO","VOC\xca RECEBEU","\u3042\u306a\u305f\u304c\u53d7\u3051\u53d6\u3063\u305f\u3082\u306e"],t.s)
A.jT=s(["Gruppe abbrechen","Cancelar grupo","Annuler le groupe","Annulla gruppo","Cancelar grupo","\u30b0\u30eb\u30fc\u30d7\u3092\u30ad\u30e3\u30f3\u30bb\u30eb"],t.s)
A.IG=s(["Diese Gruppe abbrechen?","\xbfCancelar este grupo?","Annuler ce groupe\xa0?","Annullare questo gruppo?","Cancelar este grupo?","\u3053\u306e\u30b0\u30eb\u30fc\u30d7\u3092\u30ad\u30e3\u30f3\u30bb\u30eb\u3057\u307e\u3059\u304b\uff1f"],t.s)
A.k_=s(["Best\xe4tigen","Confirmar","Confirmer","Conferma","Confirmar","\u78ba\u8a8d"],t.s)
A.rZ=s(["Gruppe erstellen","Crear grupo","Cr\xe9er un groupe","Crea gruppo","Criar grupo","\u30b0\u30eb\u30fc\u30d7\u3092\u4f5c\u6210"],t.s)
A.D4=s(["Freunde suchen Drachen","Amigos que buscan dragones","Amis \xe0 la recherche de dragons","Amici in cerca di draghi","Amigos \xe0 procura de drag\xf5es","\u30c9\u30e9\u30b4\u30f3\u3092\u63a2\u3057\u3066\u3044\u308b\u30d5\u30ec\u30f3\u30c9"],t.s)
A.ki=s(["Gruppenabenteuer sind nur f\xfcr best\xe4tigte Online-Konten verf\xfcgbar.","Las Aventuras de grupo solo est\xe1n disponibles para cuentas verificadas.","Les Aventures de groupe sont r\xe9serv\xe9es aux comptes en ligne v\xe9rifi\xe9s.","Le Avventure di gruppo sono disponibili solo per gli account verificati.","As Aventuras de grupo s\xf3 est\xe3o dispon\xedveis para contas verificadas.","\u30b0\u30eb\u30fc\u30d7\u30a2\u30c9\u30d9\u30f3\u30c1\u30e3\u30fc\u306f\u8a8d\u8a3c\u6e08\u307f\u30aa\u30f3\u30e9\u30a4\u30f3\u30a2\u30ab\u30a6\u30f3\u30c8\u3067\u306e\u307f\u5229\u7528\u3067\u304d\u307e\u3059\u3002"],t.s)
A.t5=s(["Gruppe erstellt. Freunde k\xf6nnen jetzt beitreten.","Grupo creado. Tus amigos ya pueden unirse.","Groupe cr\xe9\xe9. Tes amis peuvent maintenant le rejoindre.","Gruppo creato. Ora gli amici possono unirsi.","Grupo criado. Os amigos j\xe1 podem participar.","\u30b0\u30eb\u30fc\u30d7\u3092\u4f5c\u6210\u3057\u307e\u3057\u305f\u3002\u30d5\u30ec\u30f3\u30c9\u304c\u53c2\u52a0\u3067\u304d\u307e\u3059\u3002"],t.s)
A.Fm=s(["Mit einem Drachen beitreten","Unirse con un drag\xf3n","Rejoindre avec un dragon","Unisciti con un drago","Participar com um drag\xe3o","\u30c9\u30e9\u30b4\u30f3\u3068\u53c2\u52a0"],t.s)
A.yN=s(["Nur Freunde des Gruppengr\xfcnders k\xf6nnen beitreten.","Solo los amigos del creador del grupo pueden unirse.","Seuls les amis du cr\xe9ateur du groupe peuvent le rejoindre.","Solo gli amici di chi ha creato il gruppo possono unirsi.","S\xf3 os amigos de quem criou o grupo podem participar.","\u30b0\u30eb\u30fc\u30d7\u4f5c\u6210\u8005\u306e\u30d5\u30ec\u30f3\u30c9\u3060\u3051\u304c\u53c2\u52a0\u3067\u304d\u307e\u3059\u3002"],t.s)
A.zV=s(["Teilnehmer","Participantes","Participants","Partecipanti","Participantes","\u53c2\u52a0\u8005"],t.s)
A.tD=s(["Drachen entfernen","Quitar drag\xf3n","Retirer le dragon","Rimuovi drago","Remover drag\xe3o","\u30c9\u30e9\u30b4\u30f3\u3092\u5916\u3059"],t.s)
A.o4=s(["Belohnungen sind bereit","Las recompensas est\xe1n listas","Les r\xe9compenses sont pr\xeates","Le ricompense sono pronte","As recompensas est\xe3o prontas","\u5831\u916c\u3092\u53d7\u3051\u53d6\u308c\u307e\u3059"],t.s)
A.Eg=s(["F\xfcr Gruppenabenteuer anmelden","Inicia sesi\xf3n para las Aventuras de grupo","Connecte-toi pour les Aventures de groupe","Accedi per le Avventure di gruppo","Inicia sess\xe3o para as Aventuras de grupo","\u30b0\u30eb\u30fc\u30d7\u30a2\u30c9\u30d9\u30f3\u30c1\u30e3\u30fc\u306b\u30ed\u30b0\u30a4\u30f3"],t.s)
A.zx=s(["Der Drache wurde aus der Gruppe entfernt.","El drag\xf3n fue retirado del grupo.","Le dragon a \xe9t\xe9 retir\xe9 du groupe.","Il drago \xe8 stato rimosso dal gruppo.","O drag\xe3o foi removido do grupo.","\u30c9\u30e9\u30b4\u30f3\u3092\u30b0\u30eb\u30fc\u30d7\u304b\u3089\u5916\u3057\u307e\u3057\u305f\u3002"],t.s)
A.w4=s(["Die Gruppe ist zur\xfcckgekehrt.","El grupo ha regresado.","Le groupe est de retour.","Il gruppo \xe8 tornato.","O grupo regressou.","\u30b0\u30eb\u30fc\u30d7\u304c\u5e30\u9084\u3057\u307e\u3057\u305f\u3002"],t.s)
A.vu=s(["Die Reise startet automatisch, sobald alle Anforderungen erf\xfcllt sind.","El viaje comienza autom\xe1ticamente cuando se cumplen todos los requisitos.","Le voyage commence automatiquement lorsque toutes les conditions sont remplies.","Il viaggio inizia automaticamente quando tutti i requisiti sono soddisfatti.","A viagem come\xe7a automaticamente quando todos os requisitos forem cumpridos.","\u3059\u3079\u3066\u306e\u6761\u4ef6\u3092\u6e80\u305f\u3059\u3068\u65c5\u304c\u81ea\u52d5\u7684\u306b\u59cb\u307e\u308a\u307e\u3059\u3002"],t.s)
A.Dr=s(["Die Belohnung konnte deinem lokalen Drachen nicht zugeordnet werden.","No se pudo vincular la recompensa con tu drag\xf3n local.","La r\xe9compense n\u2019a pas pu \xeatre associ\xe9e \xe0 ton dragon local.","Non \xe8 stato possibile collegare la ricompensa al tuo drago locale.","N\xe3o foi poss\xedvel associar a recompensa ao teu drag\xe3o local.","\u5831\u916c\u3092\u30ed\u30fc\u30ab\u30eb\u306e\u30c9\u30e9\u30b4\u30f3\u306b\u53cd\u6620\u3067\u304d\u307e\u305b\u3093\u3067\u3057\u305f\u3002"],t.s)
A.mC=s(["Diese Gruppenabenteuer-Belohnungen sind noch nicht bereit.","Estas recompensas de la Aventura de grupo a\xfan no est\xe1n listas.","Ces r\xe9compenses d\u2019Aventure de groupe ne sont pas encore pr\xeates.","Le ricompense di questa Avventura di gruppo non sono ancora pronte.","Estas recompensas da Aventura de grupo ainda n\xe3o est\xe3o prontas.","\u3053\u306e\u30b0\u30eb\u30fc\u30d7\u30a2\u30c9\u30d9\u30f3\u30c1\u30e3\u30fc\u306e\u5831\u916c\u306f\u307e\u3060\u53d7\u3051\u53d6\u308c\u307e\u305b\u3093\u3002"],t.s)
A.K4=s(["Dieser Drache ist bereits f\xfcr ein Gruppenabenteuer reserviert.","Este drag\xf3n ya est\xe1 reservado para una Aventura de grupo.","Ce dragon est d\xe9j\xe0 r\xe9serv\xe9 pour une Aventure de groupe.","Questo drago \xe8 gi\xe0 riservato per un\u2019Avventura di gruppo.","Este drag\xe3o j\xe1 est\xe1 reservado para uma Aventura de grupo.","\u3053\u306e\u30c9\u30e9\u30b4\u30f3\u306f\u3059\u3067\u306b\u30b0\u30eb\u30fc\u30d7\u30a2\u30c9\u30d9\u30f3\u30c1\u30e3\u30fc\u306b\u4e88\u7d04\u3055\u308c\u3066\u3044\u307e\u3059\u3002"],t.s)
A.CZ=s(["Diese Gruppe ist bereits gestartet oder abgelaufen.","Este grupo ya ha comenzado o ha caducado.","Ce groupe a d\xe9j\xe0 commenc\xe9 ou a expir\xe9.","Questo gruppo \xe8 gi\xe0 partito o \xe8 scaduto.","Este grupo j\xe1 come\xe7ou ou expirou.","\u3053\u306e\u30b0\u30eb\u30fc\u30d7\u306f\u3059\u3067\u306b\u51fa\u767a\u3057\u305f\u304b\u671f\u9650\u5207\u308c\u3067\u3059\u3002"],t.s)
A.EZ=s(["Diese Gruppe ist voll.","Este grupo est\xe1 completo.","Ce groupe est complet.","Questo gruppo \xe8 al completo.","Este grupo est\xe1 cheio.","\u3053\u306e\u30b0\u30eb\u30fc\u30d7\u306f\u6e80\u54e1\u3067\u3059\u3002"],t.s)
A.yx=s(["Dies ist nur m\xf6glich, bevor das Abenteuer beginnt.","Esto solo es posible antes de que comience la aventura.","Cela n\u2019est possible qu\u2019avant le d\xe9but de l\u2019aventure.","\xc8 possibile farlo solo prima dell\u2019inizio dell\u2019avventura.","Isto s\xf3 \xe9 poss\xedvel antes de a aventura come\xe7ar.","\u3053\u306e\u64cd\u4f5c\u306f\u30a2\u30c9\u30d9\u30f3\u30c1\u30e3\u30fc\u958b\u59cb\u524d\u306e\u307f\u53ef\u80fd\u3067\u3059\u3002"],t.s)
A.q1=s(["Zur\xfcckziehen","Retirarse","Se retirer","Ritirati","Retirar-se","\u53c2\u52a0\u3092\u53d6\u308a\u6d88\u3059"],t.s)
A.yb=s(["Aus dieser Gruppe zur\xfcckziehen?","\xbfRetirarte de este grupo?","Te retirer de ce groupe\xa0?","Ritirarti da questo gruppo?","Retirar-te deste grupo?","\u3053\u306e\u30b0\u30eb\u30fc\u30d7\u3078\u306e\u53c2\u52a0\u3092\u53d6\u308a\u6d88\u3057\u307e\u3059\u304b\uff1f"],t.s)
A.Lh=s(["Du hast dieses w\xf6chentliche Gruppenabenteuer bereits genutzt.","Ya has usado esta Aventura de grupo semanal.","Tu as d\xe9j\xe0 utilis\xe9 cette Aventure de groupe hebdomadaire.","Hai gi\xe0 usato questa Avventura di gruppo settimanale.","J\xe1 usaste esta Aventura de grupo semanal.","\u4eca\u9031\u306e\u30b0\u30eb\u30fc\u30d7\u30a2\u30c9\u30d9\u30f3\u30c1\u30e3\u30fc\u306b\u306f\u3059\u3067\u306b\u53c2\u52a0\u3057\u3066\u3044\u307e\u3059\u3002"],t.s)
A.tI=s(["Du hast das Gruppenabenteuer dieser Woche bereits abgeschlossen.","Ya has completado la Aventura de grupo de esta semana.","Tu as d\xe9j\xe0 termin\xe9 l\u2019Aventure de groupe de cette semaine.","Hai gi\xe0 completato l\u2019Avventura di gruppo di questa settimana.","J\xe1 conclu\xedste a Aventura de grupo desta semana.","\u4eca\u9031\u306e\u30b0\u30eb\u30fc\u30d7\u30a2\u30c9\u30d9\u30f3\u30c1\u30e3\u30fc\u306f\u3059\u3067\u306b\u5b8c\u4e86\u3057\u3066\u3044\u307e\u3059\u3002"],t.s)
A.Dc=s(["Dein aktuelles w\xf6chentliches Gruppenabenteuer ist reserviert. Lobby oder Reise bleibt unter Aktiv und wechselt zu Abgeschlossen, sobald die Belohnungen bereit sind.","Tu aventura de grupo semanal est\xe1 reservada. El grupo o viaje permanece en Activas y pasa a Completadas cuando las recompensas est\xe1n listas.","Ton aventure de groupe hebdomadaire est r\xe9serv\xe9e. Le groupe ou le voyage reste dans Actives, puis passe dans Termin\xe9es quand les r\xe9compenses sont pr\xeates.","La tua avventura di gruppo settimanale \xe8 riservata. Il gruppo o viaggio resta in Attive e passa a Completate quando le ricompense sono pronte.","Sua aventura de grupo semanal est\xe1 reservada. O grupo ou jornada fica em Ativas e passa para Conclu\xeddas quando as recompensas est\xe3o prontas.","\u4eca\u9031\u306e\u30b0\u30eb\u30fc\u30d7\u5192\u967a\u306f\u4e88\u7d04\u6e08\u307f\u3067\u3059\u3002\u30ed\u30d3\u30fc\u307e\u305f\u306f\u65c5\u306f\u300c\u9032\u884c\u4e2d\u300d\u306b\u8868\u793a\u3055\u308c\u3001\u5831\u916c\u306e\u6e96\u5099\u304c\u3067\u304d\u308b\u3068\u300c\u5b8c\u4e86\u300d\u306b\u79fb\u52d5\u3057\u307e\u3059\u3002"],t.s)
A.wp=s(["Dein aktuelles w\xf6chentliches Gruppenabenteuer ist reserviert. Die Gruppe oder Reise wird unter \u201eAktiv\u201c angezeigt.","Tu Aventura de grupo semanal est\xe1 reservada. Su grupo o viaje aparece en Activas.","Ton Aventure de groupe hebdomadaire est r\xe9serv\xe9e. Son groupe ou son trajet appara\xeet dans Actives.","La tua Avventura di gruppo settimanale \xe8 riservata. Il gruppo o il viaggio appare in Attive.","A tua Aventura de grupo semanal est\xe1 reservada. O grupo ou a viagem aparece em Ativas.","\u4eca\u9031\u306e\u30b0\u30eb\u30fc\u30d7\u30a2\u30c9\u30d9\u30f3\u30c1\u30e3\u30fc\u306f\u4e88\u7d04\u6e08\u307f\u3067\u3059\u3002\u30b0\u30eb\u30fc\u30d7\u307e\u305f\u306f\u65c5\u306f\u300c\u9032\u884c\u4e2d\u300d\u306b\u8868\u793a\u3055\u308c\u307e\u3059\u3002"],t.s)
A.G_=s(["Dein Drache","Tu drag\xf3n","Ton dragon","Il tuo drago","O teu drag\xe3o","\u3042\u306a\u305f\u306e\u30c9\u30e9\u30b4\u30f3"],t.s)
A.z4=s(["Dein Drache ist der Gruppe beigetreten.","Tu drag\xf3n se ha unido al grupo.","Ton dragon a rejoint le groupe.","Il tuo drago si \xe8 unito al gruppo.","O teu drag\xe3o entrou no grupo.","\u30c9\u30e9\u30b4\u30f3\u304c\u30b0\u30eb\u30fc\u30d7\u306b\u53c2\u52a0\u3057\u307e\u3057\u305f\u3002"],t.s)
A.jU=s(["Dein Drache hat die Gruppe verlassen.","Tu drag\xf3n ha abandonado el grupo.","Ton dragon a quitt\xe9 le groupe.","Il tuo drago ha lasciato il gruppo.","O teu drag\xe3o saiu do grupo.","\u30c9\u30e9\u30b4\u30f3\u304c\u30b0\u30eb\u30fc\u30d7\u3092\u96e2\u308c\u307e\u3057\u305f\u3002"],t.s)
A.rr=s(["Dein Offline-Name, Portr\xe4t und Titel werden online automatisch verwendet.","Tu nombre, retrato y t\xedtulo sin conexi\xf3n se usan autom\xe1ticamente en l\xednea.","Ton nom, ton portrait et ton titre hors ligne sont utilis\xe9s automatiquement en ligne.","Il nome, il ritratto e il titolo offline vengono usati automaticamente online.","O teu nome, retrato e t\xedtulo offline s\xe3o usados automaticamente online.","\u30aa\u30d5\u30e9\u30a4\u30f3\u306e\u540d\u524d\u3001\u30dd\u30fc\u30c8\u30ec\u30fc\u30c8\u3001\u79f0\u53f7\u304c\u30aa\u30f3\u30e9\u30a4\u30f3\u3067\u3082\u81ea\u52d5\u7684\u306b\u4f7f\u308f\u308c\u307e\u3059\u3002"],t.s)
A.qi=s(["kombinierte","combinado","combin\xe9","combinato","combinado","\u5408\u8a08"],t.s)
A.Ln=s(["kombiniertes Level","nivel combinado","niveau combin\xe9","livello combinato","n\xedvel combinado","\u5408\u8a08\u30ec\u30d9\u30eb"],t.s)
A.IR=s(["Drachen","dragones","dragons","draghi","drag\xf5es","\u30c9\u30e9\u30b4\u30f3"],t.s)
A.oM=s(["Teilnehmer","participantes","participants","partecipanti","participantes","\u53c2\u52a0\u8005"],t.s)
A.H6=s(["Best\xe4tige deine E-Mail-Adresse, bevor du dich anmeldest.","Confirma tu correo electr\xf3nico antes de iniciar sesi\xf3n.","Confirme ton adresse e-mail avant de te connecter.","Conferma la tua e-mail prima di accedere.","Confirme seu e-mail antes de entrar.","\u30ed\u30b0\u30a4\u30f3\u524d\u306b\u30e1\u30fc\u30eb\u30a2\u30c9\u30ec\u30b9\u3092\u78ba\u8a8d\u3057\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.zK=s(["Erstelle ein best\xe4tigtes Konto, um Freunde per H\xfcter-ID hinzuzuf\xfcgen. Du musst deine E-Mail vor der Anmeldung best\xe4tigen; sie wird anderen Spielern nie angezeigt.","Crea una cuenta verificada para a\xf1adir amigos por ID de Guardi\xe1n. Debes confirmar tu correo antes de iniciar sesi\xf3n y nunca se muestra a otros jugadores.","Cr\xe9e un compte v\xe9rifi\xe9 pour ajouter des amis par ID de Gardien. Tu dois confirmer ton e-mail avant de te connecter; il n\u2019est jamais montr\xe9 aux autres joueurs.","Crea un account verificato per aggiungere amici tramite ID Custode. Devi confermare l\u2019e-mail prima di accedere e non viene mai mostrata agli altri giocatori.","Crie uma conta verificada para adicionar amigos pelo ID de Guardi\xe3o. Voc\xea deve confirmar o e-mail antes de entrar, e ele nunca \xe9 mostrado a outros jogadores.","\u30ad\u30fc\u30d1\u30fcID\u3067\u30d5\u30ec\u30f3\u30c9\u3092\u8ffd\u52a0\u3067\u304d\u308b\u8a8d\u8a3c\u6e08\u307f\u30a2\u30ab\u30a6\u30f3\u30c8\u3092\u4f5c\u6210\u3057\u307e\u3059\u3002\u30ed\u30b0\u30a4\u30f3\u524d\u306b\u30e1\u30fc\u30eb\u78ba\u8a8d\u304c\u5fc5\u8981\u3067\u3001\u30a2\u30c9\u30ec\u30b9\u306f\u4ed6\u306e\u30d7\u30ec\u30a4\u30e4\u30fc\u306b\u8868\u793a\u3055\u308c\u307e\u305b\u3093\u3002"],t.s)
A.Kg=s(["Ein geheimnisvolles Ei ist im Turmnest erschienen.","Un Huevo Misterioso apareci\xf3 en el nido de la torre.","Un \u0152uf myst\xe9rieux est apparu dans le nid de la tour.","Un Uovo misterioso \xe8 apparso nel nido della torre.","Um Ovo Misterioso apareceu no ninho da torre.","\u5854\u306e\u5de3\u306b\u4e0d\u601d\u8b70\u306a\u5375\u304c\u73fe\u308c\u307e\u3057\u305f\u3002"],t.s)
A.nb=s(["Eine Truhe wurde ge\xf6ffnet.","Se abri\xf3 un cofre.","Un coffre a \xe9t\xe9 ouvert.","\xc8 stato aperto un forziere.","Um ba\xfa foi aberto.","\u5b9d\u7bb1\u3092\u958b\u3051\u307e\u3057\u305f\u3002"],t.s)
A.KV=s(["Ein Drache hat sich entwickelt.","Un drag\xf3n ha evolucionado.","Un dragon a \xe9volu\xe9.","Un drago si \xe8 evoluto.","Um drag\xe3o evoluiu.","\u30c9\u30e9\u30b4\u30f3\u304c\u9032\u5316\u3057\u307e\u3057\u305f\u3002"],t.s)
A.nL=s(["Ein Drache ist geschl\xfcpft!","\xa1Ha nacido un drag\xf3n!","Un dragon vient d\u2019\xe9clore !","\xc8 nato un drago!","Um drag\xe3o nasceu!","\u30c9\u30e9\u30b4\u30f3\u304c\u5b75\u5316\u3057\u307e\u3057\u305f\uff01"],t.s)
A.Bc=s(["Ein vertrauter Schatten ist zur\xfcckgekehrt","Una sombra familiar ha regresado","Une ombre famili\xe8re est revenue","\xc8 tornata un\u2019ombra familiare","Uma sombra familiar retornou","\u898b\u899a\u3048\u306e\u3042\u308b\u5f71\u304c\u623b\u3063\u3066\u304d\u307e\u3057\u305f"],t.s)
A.FG=s(["Eine globale Wochenexpedition wird sonntags um 12:00 Uhr (Europa/Amsterdam) erneuert. Online-Freunde sind erforderlich.","Una expedici\xf3n semanal global se renueva el domingo a las 12:00 (Europa/\xc1msterdam). Se necesitan amigos en l\xednea.","Une exp\xe9dition hebdomadaire mondiale est renouvel\xe9e le dimanche \xe0 12 h (Europe/Amsterdam). Des amis en ligne sont requis.","Una spedizione settimanale globale si aggiorna la domenica alle 12:00 (Europa/Amsterdam). Servono amici online.","Uma expedi\xe7\xe3o semanal global \xe9 renovada no domingo \xe0s 12:00 (Europa/Amsterd\xe3). Amigos online s\xe3o necess\xe1rios.","\u4e16\u754c\u5171\u901a\u306e\u9031\u9593\u9060\u5f81\u306f\u65e5\u66dc12:00\uff08\u30e8\u30fc\u30ed\u30c3\u30d1\uff0f\u30a2\u30e0\u30b9\u30c6\u30eb\u30c0\u30e0\uff09\u306b\u66f4\u65b0\u3055\u308c\u307e\u3059\u3002\u30aa\u30f3\u30e9\u30a4\u30f3\u306e\u30d5\u30ec\u30f3\u30c9\u304c\u5fc5\u8981\u3067\u3059\u3002"],t.s)
A.pp=s(["Eine neue Form erwacht!","\xa1Despierta una nueva forma!","Une nouvelle forme s\u2019\xe9veille !","Si risveglia una nuova forma!","Uma nova forma desperta!","\u65b0\u305f\u306a\u59ff\u304c\u76ee\u899a\u3081\u307e\u3057\u305f\uff01"],t.s)
A.pR=s(["Eine neue Form erwacht \u2026","Una nueva forma est\xe1 despertando\u2026","Une nouvelle forme s\u2019\xe9veille\u2026","Una nuova forma si sta risvegliando\u2026","Uma nova forma est\xe1 despertando\u2026","\u65b0\u305f\u306a\u59ff\u304c\u76ee\u899a\u3081\u3088\u3046\u3068\u3057\u3066\u3044\u307e\u3059\u2026"],t.s)
A.rw=s(["Ein stiller Turm. Ein geheimnisvolles Ei. Eine Sammlung, die zur Legende werden will.","Una torre silenciosa. Un huevo misterioso. Una colecci\xf3n destinada a convertirse en leyenda.","Une tour paisible. Un \u0153uf myst\xe9rieux. Une collection qui ne demande qu\u2019\xe0 devenir l\xe9gendaire.","Una torre silenziosa. Un uovo misterioso. Una collezione pronta a diventare leggenda.","Uma torre tranquila. Um ovo misterioso. Uma cole\xe7\xe3o esperando para virar lenda.","\u9759\u304b\u306a\u5854\u3002\u4e0d\u601d\u8b70\u306a\u5375\u3002\u4f1d\u8aac\u306b\u306a\u308b\u65e5\u3092\u5f85\u3064\u30b3\u30ec\u30af\u30b7\u30e7\u30f3\u3002"],t.s)
A.KC=s(["Ein seltener Turmmoment","Un momento especial en la Torre","Un instant rare dans la Tour","Un raro momento nella Torre","Um momento raro na Torre","\u5854\u3067\u306e\u7279\u5225\u306a\u3072\u3068\u3068\u304d"],t.s)
A.nA=s(["Eine Aktivit\xe4t im Refugium wurde abgeschlossen.","Se complet\xf3 una actividad del santuario.","Une activit\xe9 du sanctuaire a \xe9t\xe9 termin\xe9e.","\xc8 stata completata un\u2019attivit\xe0 del santuario.","Uma atividade do santu\xe1rio foi conclu\xedda.","\u30b5\u30f3\u30af\u30c1\u30e5\u30a2\u30ea\u306e\u6d3b\u52d5\u3092\u5b8c\u4e86\u3057\u307e\u3057\u305f\u3002"],t.s)
A.vX=s(["In einer vertrauten Schale wartet ein geheimes Leben.","Una vida secreta espera dentro de una c\xe1scara familiar.","Une vie secr\xe8te attend dans une coquille famili\xe8re.","Una vita segreta attende dentro un guscio familiare.","Uma vida secreta espera dentro de uma casca familiar.","\u898b\u6163\u308c\u305f\u6bbb\u306e\u4e2d\u3067\u3001\u79d8\u5bc6\u306e\u547d\u304c\u5f85\u3063\u3066\u3044\u307e\u3059\u3002"],t.s)
A.A9=s(["Ein sanftes Leuchten f\xfcllt alle Wohlf\xfchlleisten.","Un brillo suave llena todas las barras de bienestar.","Une douce lueur remplit toutes les jauges de bien-\xeatre.","Un bagliore delicato riempie tutte le barre del benessere.","Um brilho suave preenche todas as barras de bem-estar.","\u3084\u308f\u3089\u304b\u306a\u5149\u304c\u3059\u3079\u3066\u306e\u30b3\u30f3\u30c7\u30a3\u30b7\u30e7\u30f3\u30b2\u30fc\u30b8\u3092\u6e80\u305f\u3057\u307e\u3059\u3002"],t.s)
A.mm=s(["\xdcBER DAS SPIEL","ACERCA DEL JUEGO","\xc0 PROPOS DU JEU","INFORMAZIONI SUL GIOCO","SOBRE O JOGO","\u30b2\u30fc\u30e0\u306b\u3064\u3044\u3066"],t.s)
A.Du=s(["\xdcber DragonHaven","Acerca de DragonHaven","\xc0 propos de DragonHaven","Informazioni su DragonHaven","Sobre DragonHaven","DragonHaven\u306b\u3064\u3044\u3066"],t.s)
A.rx=s(["Erfolg freigeschaltet!","\xa1Logro desbloqueado!","Succ\xe8s d\xe9bloqu\xe9 !","Obiettivo sbloccato!","Conquista desbloqueada!","\u5b9f\u7e3e\u3092\u89e3\u9664\u3057\u307e\u3057\u305f\uff01"],t.s)
A.Ad=s(["Ei aktivieren","Activar huevo","Activer l\u2019\u0153uf","Attiva uovo","Ativar ovo","\u5375\u3092\u80b2\u3066\u308b"],t.s)
A.mb=s(["Aktive Expeditionen","Expediciones activas","Exp\xe9ditions en cours","Spedizioni attive","Expedi\xe7\xf5es ativas","\u9032\u884c\u4e2d\u306e\u9060\u5f81"],t.s)
A.FA=s(["Drachenh\xfcter hinzuf\xfcgen","A\xf1adir cuidador","Ajouter un gardien","Aggiungi custode","Adicionar guardi\xe3o","\u30ad\u30fc\u30d1\u30fc\u3092\u8ffd\u52a0"],t.s)
A.mR=s(["Abenteuerbelohnungen erscheinen hier und im Bereich Abenteuer.","Las recompensas de aventura aparecer\xe1n aqu\xed y en Aventura.","Les r\xe9compenses d\u2019aventure appara\xeetront ici et dans Aventure.","Le ricompense delle avventure appariranno qui e in Avventura.","As recompensas de aventura aparecer\xe3o aqui e em Aventura.","\u5192\u967a\u306e\u5831\u916c\u306f\u3001\u3053\u3053\u53ca\u3073\u300c\u5192\u967a\u300d\u306b\u8868\u793a\u3055\u308c\u307e\u3059\u3002"],t.s)
A.tV=s(["Abenteuerbelohnungen werden hier aufbewahrt.","Las recompensas de aventura se guardan aqu\xed.","Les r\xe9compenses d\u2019aventure sont conserv\xe9es ici.","Le ricompense delle avventure vengono conservate qui.","As recompensas de aventura ficam guardadas aqui.","\u5192\u967a\u306e\u5831\u916c\u306f\u3053\u3053\u306b\u4fdd\u7ba1\u3055\u308c\u307e\u3059\u3002"],t.s)
A.nj=s(["Abenteuer gestartet.","Aventura iniciada.","Aventure lanc\xe9e.","Avventura iniziata.","Aventura iniciada.","\u5192\u967a\u3092\u958b\u59cb\u3057\u307e\u3057\u305f\u3002"],t.s)
A.zm=s(["Auf Abenteuer","De aventura","En aventure","In avventura","Em aventura","\u5192\u967a\u4e2d"],t.s)
A.HN=s(["Alle","Todo","Tout","Tutto","Tudo","\u3059\u3079\u3066"],t.s)
A.vl=s(["Ein Ei kann nicht auf Abenteuer gehen.","Un huevo no puede ir de aventura.","Un \u0153uf ne peut pas partir \xe0 l\u2019aventure.","Un uovo non pu\xf2 partire all\u2019avventura.","Um ovo n\xe3o pode partir em aventura.","\u5375\u306f\u5192\u967a\u306b\u51fa\u3089\u308c\u307e\u305b\u3093\u3002"],t.s)
A.Ki=s(["Android-Downloadlink kopiert.","Enlace de descarga de Android copiado.","Lien de t\xe9l\xe9chargement Android copi\xe9.","Link per il download Android copiato.","Link de download do Android copiado.","Android\u306e\u30c0\u30a6\u30f3\u30ed\u30fc\u30c9\u30ea\u30f3\u30af\u3092\u30b3\u30d4\u30fc\u3057\u307e\u3057\u305f\u3002"],t.s)
A.yD=s(["Aktualisieren","Actualizar","Mettre \xe0 jour","Aggiorna","Atualizar","\u66f4\u65b0"],t.s)
A.p1=s(["Arcana liegt derzeit vorn.","Arcana est\xe1 en cabeza.","Arcana est actuellement en t\xeate.","Arcana \xe8 attualmente in testa.","Arcana est\xe1 na frente.","\u73fe\u5728\u306f\u30a2\u30eb\u30ab\u30ca\u304c\u512a\u52e2\u3067\u3059\u3002"],t.s)
A.oR=s(["Dauerhaft archiviert; jeden Tag besteht eine Chance von 10 %, dass der Drache zu einer zuf\xe4lligen Zeit zur\xfcckkehrt.","Archivado permanentemente; cada d\xeda tiene un 10 % de probabilidad de volver a una hora aleatoria.","Archiv\xe9 d\xe9finitivement ; chaque jour, il a 10 % de chances de revenir \xe0 une heure al\xe9atoire.","Archiviato per sempre; ogni giorno ha il 10% di probabilit\xe0 di tornare a un orario casuale.","Arquivado permanentemente; todos os dias tem 10% de chance de voltar em um hor\xe1rio aleat\xf3rio.","\u6c38\u4e45\u306b\u8a18\u9332\u3055\u308c\u3001\u6bce\u65e510%\u306e\u78ba\u7387\u3067\u30e9\u30f3\u30c0\u30e0\u306a\u6642\u523b\u306b\u623b\u3063\u3066\u304d\u307e\u3059\u3002"],t.s)
A.t9=s(["Aufstieg abgeschlossen","Ascensi\xf3n completada","Ascension termin\xe9e","Ascensione completata","Ascens\xe3o conclu\xedda","\u6607\u83ef\u5b8c\u4e86"],t.s)
A.ok=s(["Aufstiegspfade","Sendas de ascensi\xf3n","Voies d\u2019ascension","Percorsi di ascensione","Caminhos da ascens\xe3o","\u6607\u83ef\u306e\u9053"],t.s)
A.Ej=s(["Erhaben","Ascendido","Transcend\xe9","Asceso","Ascendido","\u6607\u83ef\u7adc"],t.s)
A.pj=s(["Audio","Audio","Audio","Audio","\xc1udio","\u30aa\u30fc\u30c7\u30a3\u30aa"],t.s)
A.w0=s(["Schl\xfcpfen beginnen","Iniciar eclosi\xf3n","Commencer l\u2019\xe9closion","Inizia la schiusa","Iniciar eclos\xe3o","\u5b75\u5316\u3092\u59cb\u3081\u308b"],t.s)
A.zz=s(["Beide H\xfcter m\xfcssen mindestens ein Ei, eine Truhe oder einen Gegenstand anbieten und den endg\xfcltigen Tausch best\xe4tigen.","Ambos cuidadores deben ofrecer al menos un huevo, cofre u objeto y confirmar el intercambio final.","Les deux gardiens doivent proposer au moins un \u0153uf, un coffre ou un objet et confirmer l\u2019\xe9change final.","Entrambi i custodi devono offrire almeno un uovo, un forziere o un oggetto e confermare lo scambio finale.","Os dois guardi\xf5es devem oferecer pelo menos um ovo, ba\xfa ou item e confirmar a troca final.","\u53cc\u65b9\u306e\u30ad\u30fc\u30d1\u30fc\u304c\u5375\u3001\u5b9d\u7bb1\u3001\u30a2\u30a4\u30c6\u30e0\u306e\u3044\u305a\u308c\u304b\u30921\u3064\u4ee5\u4e0a\u63d0\u793a\u3057\u3001\u6700\u7d42\u7684\u306a\u4ea4\u63db\u3092\u627f\u8a8d\u3059\u308b\u5fc5\u8981\u304c\u3042\u308a\u307e\u3059\u3002"],t.s)
A.JC=s(["Beide Einstellungen wirken sofort und werden f\xfcr dieses lokale Konto getrennt gespeichert.","Ambos ajustes se aplican al instante y se guardan por separado para esta cuenta local.","Les deux r\xe9glages s\u2019appliquent imm\xe9diatement et sont enregistr\xe9s s\xe9par\xe9ment pour ce compte local.","Entrambe le impostazioni hanno effetto immediato e vengono salvate separatamente per questo account locale.","As duas configura\xe7\xf5es t\xeam efeito imediato e s\xe3o salvas separadamente para esta conta local.","\u3069\u3061\u3089\u306e\u8a2d\u5b9a\u3082\u3059\u3050\u306b\u53cd\u6620\u3055\u308c\u3001\u3053\u306e\u30ed\u30fc\u30ab\u30eb\u30a2\u30ab\u30a6\u30f3\u30c8\u306b\u500b\u5225\u306b\u4fdd\u5b58\u3055\u308c\u307e\u3059\u3002"],t.s)
A.qx=s(["Baue ein Zuhause, das mit deinem Drachen w\xe4chst.","Construye un hogar que crezca con tu drag\xf3n.","Construis un foyer qui grandit avec ton dragon.","Costruisci una casa che cresca con il tuo drago.","Construa um lar que cres\xe7a com seu drag\xe3o.","\u30c9\u30e9\u30b4\u30f3\u3068\u3068\u3082\u306b\u6210\u9577\u3059\u308b\u4f4f\u307e\u3044\u3092\u4f5c\u308a\u307e\u3057\u3087\u3046\u3002"],t.s)
A.tv=s(["Raum bauen","Construir habitaci\xf3n","Construire la pi\xe8ce","Costruisci stanza","Construir c\xf4modo","\u90e8\u5c4b\u3092\u5efa\u3066\u308b"],t.s)
A.Go=s(["Gebaut und bereit","Construido y listo","Construit et pr\xeat","Costruita e pronta","Constru\xeddo e pronto","\u5efa\u7bc9\u6e08\u307f"],t.s)
A.jI=s(["Entstanden","Creada en","Cr\xe9\xe9e en","Realizzata nel","Criado em","\u5236\u4f5c\u5e74"],t.s)
A.vh=s(["Edelsteine kaufen","Comprar gemas","Acheter des gemmes","Compra gemme","Comprar gemas","\u30b8\u30a7\u30e0\u3092\u8cfc\u5165"],t.s)
A.Eo=s(["Spendiere mir einen Kaffee","Inv\xedtame a un caf\xe9","Offrez-moi un caf\xe9","Offrimi un caff\xe8","Pague-me um caf\xe9","\u30b3\u30fc\u30d2\u30fc\u3067\u5fdc\u63f4"],t.s)
A.oh=s(["Abbrechen","Cancelar","Annuler","Annulla","Cancelar","\u30ad\u30e3\u30f3\u30bb\u30eb"],t.s)
A.wZ=s(["Truhen","Cofres","Coffres","Forzieri","Ba\xfas","\u5b9d\u7bb1"],t.s)
A.rG=s(["Namen w\xe4hlen","Elige un nombre","Choisir un nom","Scegli un nome","Escolha um nome","\u540d\u524d\u3092\u9078\u3076"],t.s)
A.wf=s(["W\xe4hle zuerst einen Namen.","Elige primero un nombre.","Choisis d\u2019abord un nom.","Scegli prima un nome.","Escolha um nome primeiro.","\u307e\u305a\u540d\u524d\u3092\u6c7a\u3081\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.o7=s(["Raumtyp w\xe4hlen","Elige un tipo de habitaci\xf3n","Choisir un type de pi\xe8ce","Scegli un tipo di stanza","Escolha um tipo de c\xf4modo","\u90e8\u5c4b\u306e\u7a2e\u985e\u3092\u9078\u3076"],t.s)
A.r5=s(["Starter-Ei annehmen","Recoger el Huevo Inicial","R\xe9cup\xe9rer l\u2019\u0152uf de d\xe9part","Ottieni l\u2019Uovo iniziale","Receber o Ovo Inicial","\u6700\u521d\u306e\u5375\u3092\u53d7\u3051\u53d6\u308b"],t.s)
A.Gm=s(["Suche l\xf6schen","Borrar b\xfasqueda","Effacer la recherche","Cancella ricerca","Limpar pesquisa","\u691c\u7d22\u3092\u6d88\u53bb"],t.s)
A.A1=s(["Wolkenrefugium","Santuario de las Nubes","Sanctuaire des Nuages","Santuario delle Nuvole","Santu\xe1rio das Nuvens","\u96f2\u306e\u8056\u57df"],t.s)
A.uK=s(["Drachentruhe","Cofre de Drag\xf3n","Coffre du Dragon","Forziere del Drago","Ba\xfa de Drag\xe3o","\u30c9\u30e9\u30b4\u30f3\u306e\u5b9d\u7bb1"],t.s)
A.Ci=s(["M\xfcnzm\xf6bel","Muebles por monedas","Meubles contre des pi\xe8ces","Mobili con monete","M\xf3veis por moedas","\u30b3\u30a4\u30f3\u5bb6\u5177"],t.s)
A.KM=s(["Einsammeln","Recoger","R\xe9cup\xe9rer","Raccogli","Coletar","\u53d7\u3051\u53d6\u308b"],t.s)
A.J_=s(["Sammle M\xf6bel f\xfcr jedes Drachenzimmer.","Colecciona muebles para todas las habitaciones de dragones.","Collectionne des meubles pour chaque pi\xe8ce des dragons.","Colleziona mobili per ogni stanza dei draghi.","Colecione m\xf3veis para cada c\xf4modo dos drag\xf5es.","\u3059\u3079\u3066\u306e\u30c9\u30e9\u30b4\u30f3\u90e8\u5c4b\u306b\u7f6e\u304f\u5bb6\u5177\u3092\u96c6\u3081\u307e\u3057\u3087\u3046\u3002"],t.s)
A.rb=s(["Komfort","Comodidad","Confort","Comfort","Conforto","\u5feb\u9069\u3055"],t.s)
A.L4=s(["Gew\xf6hnlich","Com\xfan","Commun","Comune","Comum","\u30b3\u30e2\u30f3"],t.s)
A.qS=s(["Kompaktansicht","Vista compacta","Vue compacte","Vista compatta","Visualiza\xe7\xe3o compacta","\u30b3\u30f3\u30d1\u30af\u30c8\u8868\u793a"],t.s)
A.nw=s(["Verbinde dich mit Online-Freunden, bevor du einem Gruppenabenteuer beitrittst.","Conecta amigos en l\xednea antes de unirte a una aventura grupal.","Connecte des amis en ligne avant de rejoindre une aventure de groupe.","Collega amici online prima di partecipare a un\u2019avventura di gruppo.","Conecte amigos online antes de entrar em uma aventura em grupo.","\u30b0\u30eb\u30fc\u30d7\u5192\u967a\u306b\u53c2\u52a0\u3059\u308b\u524d\u306b\u3001\u30aa\u30f3\u30e9\u30a4\u30f3\u306e\u30d5\u30ec\u30f3\u30c9\u3068\u63a5\u7d9a\u3057\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.AC=s(["Downloadlink kopieren","Copiar enlace de descarga","Copier le lien de t\xe9l\xe9chargement","Copia link di download","Copiar link de download","\u30c0\u30a6\u30f3\u30ed\u30fc\u30c9\u30ea\u30f3\u30af\u3092\u30b3\u30d4\u30fc"],t.s)
A.E3=s(["Kopiere einen dauerhaften Android-Downloadlink f\xfcr andere oder \xf6ffne ihn, um die neueste Version \xfcber dieser App zu installieren. Dein Fortschritt bleibt erhalten.","Copia un enlace permanente de descarga para Android o \xe1brelo para instalar la \xfaltima versi\xf3n sobre esta aplicaci\xf3n. Tu progreso se conserva.","Copiez un lien Android permanent ou ouvrez-le pour installer la derni\xe8re version par-dessus cette application. Votre progression est conserv\xe9e.","Copia un link Android permanente oppure aprilo per installare l\u2019ultima versione sopra questa app. I progressi restano al sicuro.","Copie um link permanente de download para Android ou abra-o para instalar a vers\xe3o mais recente sobre este app. Seu progresso fica seguro.","Android\u7528\u306e\u56fa\u5b9a\u30c0\u30a6\u30f3\u30ed\u30fc\u30c9\u30ea\u30f3\u30af\u3092\u5171\u6709\u7528\u306b\u30b3\u30d4\u30fc\u3059\u308b\u304b\u3001\u958b\u3044\u3066\u6700\u65b0\u7248\u3092\u4e0a\u66f8\u304d\u30a4\u30f3\u30b9\u30c8\u30fc\u30eb\u3067\u304d\u307e\u3059\u3002\u9032\u884c\u72b6\u6cc1\u306f\u4fdd\u6301\u3055\u308c\u307e\u3059\u3002"],t.s)
A.nk=s(["Erstellt von","Creado por","Cr\xe9\xe9 par","Creato da","Criado por","\u5236\u4f5c\u8005"],t.s)
A.F1=s(["Kristallgrotte","Gruta de Cristal","Grotte de Cristal","Grotta di Cristallo","Gruta de Cristal","\u6c34\u6676\u306e\u6d1e\u7a9f"],t.s)
A.Bz=s(["Neugierig","Curioso","Curieux","Curioso","Curioso","\u597d\u5947\u5fc3\u65fa\u76db"],t.s)
A.l5=s(["Dekorieren","Decorar","D\xe9corer","Decora","Decorar","\u98fe\u308a\u3064\u3051\u308b"],t.s)
A.tg=s(["Verwerfen","Descartar","Jeter","Scarta","Descartar","\u7834\u68c4"],t.s)
A.qA=s(["Ei verwerfen","Descartar huevo","Jeter l\u2019\u0153uf","Scarta uovo","Descartar ovo","\u5375\u3092\u7834\u68c4"],t.s)
A.B9=s(["Eine Truhe verwerfen","Descartar un cofre","Jeter un coffre","Scarta un forziere","Descartar um ba\xfa","\u5b9d\u7bb1\u30921\u3064\u7834\u68c4"],t.s)
A.yt=s(["Dieses geheimnisvolle Ei verwerfen?","\xbfDescartar este Huevo Misterioso?","Jeter cet \u0152uf myst\xe9rieux ?","Scartare questo Uovo misterioso?","Descartar este Ovo Misterioso?","\u3053\u306e\u4e0d\u601d\u8b70\u306a\u5375\u3092\u7834\u68c4\u3057\u307e\u3059\u304b\uff1f"],t.s)
A.Ao=s(["Wegschicken","Descartar","Ignorer","Congeda","Dispensar","\u898b\u9001\u308b"],t.s)
A.kx=s(["Herunterladen oder aktualisieren","Descargar o actualizar","T\xe9l\xe9charger ou mettre \xe0 jour","Scarica o aggiorna","Baixar ou atualizar","\u30c0\u30a6\u30f3\u30ed\u30fc\u30c9\uff0f\u66f4\u65b0"],t.s)
A.xi=s(["Drachenpflege","Cuidado del drag\xf3n","Soins du dragon","Cura del drago","Cuidados do drag\xe3o","\u30c9\u30e9\u30b4\u30f3\u306e\u304a\u4e16\u8a71"],t.s)
A.E1=s(["Drachenh\xfcter","Cuidador de dragones","Gardien de dragons","Custode dei draghi","Guardi\xe3o de drag\xf5es","\u30c9\u30e9\u30b4\u30f3\u30ad\u30fc\u30d1\u30fc"],t.s)
A.zb=s(["Drachenname","Nombre del drag\xf3n","Nom du dragon","Nome del drago","Nome do drag\xe3o","\u30c9\u30e9\u30b4\u30f3\u306e\u540d\u524d"],t.s)
A.kF=s(["Drachenzimmer","Habitaci\xf3n del drag\xf3n","Pi\xe8ce des dragons","Stanza dei draghi","C\xf4modo dos drag\xf5es","\u30c9\u30e9\u30b4\u30f3\u306e\u90e8\u5c4b"],t.s)
A.FF=s(["Drachenrefugium","Santuario de dragones","Sanctuaire des dragons","Santuario dei draghi","Santu\xe1rio dos drag\xf5es","\u30c9\u30e9\u30b4\u30f3\u306e\u8056\u57df"],t.s)
A.G0=s(["DragonHaven-Logo","Logotipo de DragonHaven","Logo de DragonHaven","Logo di DragonHaven","Logo do DragonHaven","DragonHaven\u306e\u30ed\u30b4"],t.s)
A.JW=s(["BEARBEITUNG","MODO EDICI\xd3N","MODE \xc9DITION","MODALIT\xc0 MODIFICA","MODO DE EDI\xc7\xc3O","\u7de8\u96c6\u30e2\u30fc\u30c9"],t.s)
A.J3=s(["Jeder Raum bleibt dauerhaft bestehen und kann einzeln eingerichtet werden.","Cada habitaci\xf3n es permanente y puede decorarse por separado.","Chaque pi\xe8ce est permanente et peut \xeatre d\xe9cor\xe9e s\xe9par\xe9ment.","Ogni stanza \xe8 permanente e pu\xf2 essere decorata separatamente.","Cada c\xf4modo \xe9 permanente e pode ser decorado separadamente.","\u5404\u90e8\u5c4b\u306f\u305a\u3063\u3068\u6b8b\u308a\u3001\u305d\u308c\u305e\u308c\u5225\u3005\u306b\u98fe\u308c\u307e\u3059\u3002"],t.s)
A.A7=s(["H\xfcternamen \xe4ndern","Editar nombre del cuidador","Modifier le nom du gardien","Modifica nome del custode","Editar nome do guardi\xe3o","\u30ad\u30fc\u30d1\u30fc\u540d\u3092\u7de8\u96c6"],t.s)
A.oL=s(["Namen \xe4ndern","Editar nombre","Modifier le nom","Modifica nome","Editar nome","\u540d\u524d\u3092\u7de8\u96c6"],t.s)
A.kD=s(["Ei","Huevo","\u0152uf","Uovo","Ovo","\u5375"],t.s)
A.wR=s(["Das Ei wurde ins Dachnest gebracht.","El huevo se traslad\xf3 al nido de la azotea.","L\u2019\u0153uf a \xe9t\xe9 d\xe9plac\xe9 dans le nid du toit.","L\u2019uovo \xe8 stato spostato nel nido sul tetto.","O ovo foi levado para o ninho no telhado.","\u5375\u3092\u5c4b\u4e0a\u306e\u5de3\u3078\u79fb\u3057\u307e\u3057\u305f\u3002"],t.s)
A.oC=s(["Eierinventar","Inventario de huevos","Inventaire des \u0153ufs","Inventario delle uova","Invent\xe1rio de ovos","\u5375\u306e\u6240\u6301\u54c1"],t.s)
A.Cu=s(["Eier","Huevos","\u0152ufs","Uova","Ovos","\u5375"],t.s)
A.tn=s(["Energie","Energ\xeda","\xc9nergie","Energia","Energia","\u5143\u6c17"],t.s)
A.J6=s(["Gef\xe4llt dir DragonHaven? \xdcber Ko-fi kannst du die weitere Entwicklung unterst\xfctzen.","\xbfTe gusta DragonHaven? Puedes apoyar su desarrollo en Ko-fi.","Vous aimez DragonHaven ? Soutenez son d\xe9veloppement sur Ko-fi.","Ti piace DragonHaven? Puoi sostenerne lo sviluppo su Ko-fi.","Est\xe1 gostando do DragonHaven? Apoie o desenvolvimento pelo Ko-fi.","DragonHaven\u3092\u697d\u3057\u3093\u3067\u3044\u307e\u3059\u304b\uff1fKo-fi\u304b\u3089\u4eca\u5f8c\u306e\u958b\u767a\u3092\u652f\u63f4\u3067\u304d\u307e\u3059\u3002"],t.s)
A.x0=s(["Event-, Code- und R\xfcckkehrer-Abenteuer bleiben 48 Stunden verf\xfcgbar.","Las aventuras de evento, c\xf3digo y dragones que regresan duran 48 horas.","Les aventures d\u2019\xe9v\xe9nement, de code et de dragons de retour restent disponibles 48 heures.","Le avventure evento, codice e drago di ritorno restano disponibili per 48 ore.","Aventuras de evento, c\xf3digo e drag\xe3o retornando ficam dispon\xedveis por 48 horas.","\u30a4\u30d9\u30f3\u30c8\u3001\u30b3\u30fc\u30c9\u3001\u5e30\u9084\u30c9\u30e9\u30b4\u30f3\u306e\u5192\u967a\u306f48\u6642\u9593\u6709\u52b9\u3067\u3059\u3002"],t.s)
A.H7=s(["Jetzt entwickeln","Evolucionar ahora","\xc9voluer maintenant","Evolvi ora","Evoluir agora","\u4eca\u3059\u3050\u9032\u5316"],t.s)
A.lP=s(["Refugium erweitern","Ampliar el santuario","Agrandir le sanctuaire","Espandi il santuario","Expandir o santu\xe1rio","\u8056\u57df\u3092\u62e1\u5f35"],t.s)
A.Lu=s(["Fertig","Terminar","Terminer","Fine","Concluir","\u5b8c\u4e86"],t.s)
A.tO=s(["Zum Beispiel: Ember","Por ejemplo: Ember","Par exemple : Ember","Per esempio: Ember","Por exemplo: Ember","\u4f8b\uff1aEmber"],t.s)
A.zk=s(["Zum Beispiel: Rick","Por ejemplo: Rick","Par exemple : Rick","Per esempio: Rick","Por exemplo: Rick","\u4f8b\uff1aRick"],t.s)
A.xg=s(["M\xf6bel","Muebles","Meubles","Mobili","M\xf3veis","\u5bb6\u5177"],t.s)
A.q_=s(["Edelsteinm\xf6bel","Muebles por gemas","Meubles contre des gemmes","Mobili con gemme","M\xf3veis por gemas","\u30b8\u30a7\u30e0\u5bb6\u5177"],t.s)
A.F9=s(["Goldtruhe","Cofre de Oro","Coffre en Or","Forziere d\u2019Oro","Ba\xfa de Ouro","\u91d1\u306e\u5b9d\u7bb1"],t.s)
A.wO=s(["GitHub hat unerwartete Releasedaten zur\xfcckgegeben.","GitHub devolvi\xf3 datos de versi\xf3n inesperados.","GitHub a renvoy\xe9 des donn\xe9es de version inattendues.","GitHub ha restituito dati di versione imprevisti.","O GitHub retornou dados de vers\xe3o inesperados.","GitHub\u304b\u3089\u4e88\u671f\u3057\u306a\u3044\u30ea\u30ea\u30fc\u30b9\u30c7\u30fc\u30bf\u304c\u8fd4\u3055\u308c\u307e\u3057\u305f\u3002"],t.s)
A.lE=s(["Guten Tag","Buenas tardes","Bonjour","Buon pomeriggio","Boa tarde","\u3053\u3093\u306b\u3061\u306f"],t.s)
A.wX=s(["Guten Abend","Buenas noches","Bonsoir","Buonasera","Boa noite","\u3053\u3093\u3070\u3093\u306f"],t.s)
A.uO=s(["Guten Morgen","Buenos d\xedas","Bonjour","Buongiorno","Bom dia","\u304a\u306f\u3088\u3046\u3054\u3056\u3044\u307e\u3059"],t.s)
A.pA=s(["Gr\xfcnpflanzen","Vegetaci\xf3n","Verdure","Piante","Plantas","\u690d\u7269"],t.s)
A.G3=s(["Gruppe","Grupo","Groupe","Gruppo","Grupo","\u30b0\u30eb\u30fc\u30d7"],t.s)
A.Jy=s(["HIER","AQU\xcd","ICI","QUI","AQUI","\u3053\u306e\u90e8\u5c4b"],t.s)
A.Jv=s(["Feuerzimmer","Sala del Hogar","Salle du Foyer","Sala del Focolare","Sala da Lareira","\u6696\u7089\u306e\u9593"],t.s)
A.HJ=s(["Schl\xfcpfling","Cr\xeda","Nouveau-n\xe9","Cucciolo","Filhote","\u5e7c\u7adc"],t.s)
A.Hk=s(["Verborgene Truhe","Cofre oculto","Coffre cach\xe9","Forziere nascosto","Ba\xfa oculto","\u96a0\u3055\u308c\u305f\u5b9d\u7bb1"],t.s)
A.ro=s(["Hausinventar","Inventario de la casa","Inventaire de la maison","Inventario della casa","Invent\xe1rio da casa","\u5bb6\u306e\u6301\u3061\u7269"],t.s)
A.wg=s(["Hausgegenstand","Objeto de la casa","Objet de maison","Oggetto per la casa","Item da casa","\u5bb6\u306e\u30a2\u30a4\u30c6\u30e0"],t.s)
A.zU=s(["Hausladen","Tienda de la casa","Boutique de la maison","Negozio della casa","Loja da casa","\u5bb6\u5177\u30b7\u30e7\u30c3\u30d7"],t.s)
A.rB=s(["INVENTAR","INVENTARIO","INVENTAIRE","INVENTARIO","INVENT\xc1RIO","\u6301\u3061\u7269"],t.s)
A.xx=s(["Im Turm","En la Torre","Dans la Tour","Nella Torre","Na Torre","\u5854\u306b\u3044\u308b"],t.s)
A.Kk=s(["Ausbr\xfcten","Incubar","Incuber","Incuba","Incubar","\u5b75\u3059"],t.s)
A.jH=s(["Der unge\xf6ffnete Inhalt geht verloren.","Su contenido sin abrir se perder\xe1.","Son contenu non ouvert sera perdu.","Il contenuto non aperto andr\xe0 perduto.","O conte\xfado fechado ser\xe1 perdido.","\u672a\u958b\u5c01\u306e\u4e2d\u8eab\u306f\u5931\u308f\u308c\u307e\u3059\u3002"],t.s)
A.HL=s(["Freude","Alegr\xeda","Joie","Gioia","Alegria","\u559c\u3073"],t.s)
A.AH=s(["Namen behalten","Guardar este nombre","Garder ce nom","Conferma questo nome","Manter este nome","\u3053\u306e\u540d\u524d\u306b\u3059\u308b"],t.s)
A.qJ=s(["Ko-fi konnte weder ge\xf6ffnet noch kopiert werden.","No se pudo abrir ni copiar Ko-fi.","Impossible d\u2019ouvrir ou de copier Ko-fi.","Impossibile aprire o copiare Ko-fi.","N\xe3o foi poss\xedvel abrir nem copiar o Ko-fi.","Ko-fi\u3092\u958b\u304f\u3053\u3068\u3082\u30b3\u30d4\u30fc\u3059\u308b\u3053\u3068\u3082\u3067\u304d\u307e\u305b\u3093\u3067\u3057\u305f\u3002"],t.s)
A.tu=s(["Ko-fi konnte nicht ge\xf6ffnet werden. Der Link wurde stattdessen kopiert.","No se pudo abrir Ko-fi. Se copi\xf3 el enlace.","Impossible d\u2019ouvrir Ko-fi. Le lien a \xe9t\xe9 copi\xe9.","Impossibile aprire Ko-fi. Il link \xe8 stato copiato.","N\xe3o foi poss\xedvel abrir o Ko-fi. O link foi copiado.","Ko-fi\u3092\u958b\u3051\u306a\u304b\u3063\u305f\u305f\u3081\u3001\u30ea\u30f3\u30af\u3092\u30b3\u30d4\u30fc\u3057\u307e\u3057\u305f\u3002"],t.s)
A.Aq=s(["Listenansicht","Vista de lista","Vue en liste","Vista elenco","Visualiza\xe7\xe3o em lista","\u30ea\u30b9\u30c8\u8868\u793a"],t.s)
A.Dp=s(["Dem geheimnisvollen Ei lauschen","Escuchar el huevo misterioso","\xc9couter l\u2019\u0153uf myst\xe9rieux","Ascolta l\u2019uovo misterioso","Ouvir o ovo misterioso","\u4e0d\u601d\u8b70\u306a\u5375\u306b\u8033\u3092\u6f84\u307e\u3059"],t.s)
A.xq=s(["Lang","Larga","Longue","Lunga","Longa","\u30ed\u30f3\u30b0"],t.s)
A.tQ=s(["Magie","Magia","Magie","Magia","Magia","\u9b54\u6cd5"],t.s)
A.Lm=s(["Maximale H\xf6he erreicht","Altura m\xe1xima alcanzada","Hauteur maximale atteinte","Altezza massima raggiunta","Altura m\xe1xima alcan\xe7ada","\u6700\u9ad8\u968e\u306b\u5230\u9054"],t.s)
A.Kd=s(["Macht liegt derzeit vorn.","Poder est\xe1 en cabeza.","Puissance est actuellement en t\xeate.","Potenza \xe8 attualmente in testa.","Poder est\xe1 na frente.","\u73fe\u5728\u306f\u30de\u30a4\u30c8\u304c\u512a\u52e2\u3067\u3059\u3002"],t.s)
A.kI=s(["Mondgarten","Jard\xedn Lunar","Jardin Lunaire","Giardino Lunare","Jardim Lunar","\u6708\u306e\u5ead\u5712"],t.s)
A.Er=s(["Meine Drachen","Mis dragones","Mes dragons","I miei draghi","Meus drag\xf5es","\u30de\u30a4\u30c9\u30e9\u30b4\u30f3"],t.s)
A.Gr=s(["Geheimnisvolles Ei","Huevo Misterioso","\u0152uf myst\xe9rieux","Uovo misterioso","Ovo Misterioso","\u4e0d\u601d\u8b70\u306a\u5375"],t.s)
A.r4=s(["Mythische Truhe","Cofre M\xedtico","Coffre Mythique","Forziere Mitico","Ba\xfa M\xedtico","\u795e\u8a71\u306e\u5b9d\u7bb1"],t.s)
A.tR=s(["Neue Entwicklung!","\xa1Nueva evoluci\xf3n!","Nouvelle \xe9volution !","Nuova evoluzione!","Nova evolu\xe7\xe3o!","\u65b0\u305f\u306a\u9032\u5316\uff01"],t.s)
A.BU=s(["Gib deinem Drachen einen Namen","Ponle nombre a tu drag\xf3n","Nomme ton dragon","Dai un nome al tuo drago","D\xea um nome ao seu drag\xe3o","\u30c9\u30e9\u30b4\u30f3\u306b\u540d\u524d\u3092\u3064\u3051\u308b"],t.s)
A.Af=s(["Nestzimmer","Sala del Nido","Salle du Nid","Sala del Nido","Sala do Ninho","\u5de3\u306e\u9593"],t.s)
A.ws=s(["Du hast noch keine geheimnisvollen Eier im Inventar.","A\xfan no hay Huevos Misteriosos en tu inventario.","Aucun \u0152uf myst\xe9rieux dans votre inventaire pour le moment.","Non ci sono ancora Uova misteriose nel tuo inventario.","Ainda n\xe3o h\xe1 Ovos Misteriosos no seu invent\xe1rio.","\u6240\u6301\u54c1\u306b\u306f\u307e\u3060\u4e0d\u601d\u8b70\u306a\u5375\u304c\u3042\u308a\u307e\u305b\u3093\u3002"],t.s)
A.wm=s(["Keine Internetverbindung. Bitte versuche es sp\xe4ter erneut.","Sin conexi\xf3n a Internet. Int\xe9ntalo de nuevo m\xe1s tarde.","Aucune connexion Internet. R\xe9essayez plus tard.","Nessuna connessione Internet. Riprova pi\xf9 tardi.","Sem conex\xe3o com a internet. Tente novamente mais tarde.","\u30a4\u30f3\u30bf\u30fc\u30cd\u30c3\u30c8\u306b\u63a5\u7d9a\u3067\u304d\u307e\u305b\u3093\u3002\u5f8c\u3067\u3082\u3046\u4e00\u5ea6\u304a\u8a66\u3057\u304f\u3060\u3055\u3044\u3002"],t.s)
A.pl=s(["Es wurde noch kein \xf6ffentliches GitHub-Release ver\xf6ffentlicht.","A\xfan no se ha publicado ninguna versi\xf3n p\xfablica en GitHub.","Aucune version publique n\u2019a encore \xe9t\xe9 publi\xe9e sur GitHub.","Non \xe8 ancora stata pubblicata alcuna release pubblica su GitHub.","Nenhuma vers\xe3o p\xfablica foi publicada no GitHub ainda.","\u516c\u958bGitHub\u30ea\u30ea\u30fc\u30b9\u306f\u307e\u3060\u3042\u308a\u307e\u305b\u3093\u3002"],t.s)
A.Ig=s(["Keine wartenden Eier. Seltene Eier aus Truhen erscheinen hier.","No hay huevos en espera. Aqu\xed aparecer\xe1n los raros que encuentres en cofres.","Aucun \u0153uf en attente. Les rares \u0153ufs trouv\xe9s dans des coffres appara\xeetront ici.","Nessun uovo in attesa. Le rare uova trovate nei forzieri appariranno qui.","Nenhum ovo em espera. Ovos raros encontrados em ba\xfas aparecer\xe3o aqui.","\u5f85\u6a5f\u4e2d\u306e\u5375\u306f\u3042\u308a\u307e\u305b\u3093\u3002\u5b9d\u7bb1\u304b\u3089\u51fa\u305f\u73cd\u3057\u3044\u5375\u304c\u3053\u3053\u306b\u4e26\u3073\u307e\u3059\u3002"],t.s)
A.yX=s(["Nicht genug M\xfcnzen f\xfcr diese Etage.","No tienes suficientes monedas para este piso.","Pas assez de pi\xe8ces pour cet \xe9tage.","Monete insufficienti per questo piano.","Moedas insuficientes para este andar.","\u3053\u306e\u968e\u3092\u5efa\u3066\u308b\u30b3\u30a4\u30f3\u304c\u8db3\u308a\u307e\u305b\u3093\u3002"],t.s)
A.BT=s(["Noch nicht bereit","A\xfan no est\xe1 listo","Pas encore pr\xeat","Non ancora pronto","Ainda n\xe3o est\xe1 pronto","\u307e\u3060\u6e96\u5099\u4e2d"],t.s)
A.kS=s(["Noch nicht","Todav\xeda no","Pas encore","Non ancora","Ainda n\xe3o","\u307e\u3060\u3057\u306a\u3044"],t.s)
A.vf=s(["ANDERER RAUM","OTRA HABITACI\xd3N","AUTRE PI\xc8CE","ALTRA STANZA","OUTRO C\xd4MODO","\u5225\u306e\u90e8\u5c4b"],t.s)
A.BB=s(["Trinkgeldseite \xf6ffnen","Abrir p\xe1gina de apoyo","Ouvrir la page de soutien","Apri la pagina di supporto","Abrir p\xe1gina de apoio","\u652f\u63f4\u30da\u30fc\u30b8\u3092\u958b\u304f"],t.s)
A.Ll=s(["Der neueste DragonHaven-Download wird ge\xf6ffnet \u2026","Abriendo la descarga m\xe1s reciente de DragonHaven\u2026","Ouverture du dernier t\xe9l\xe9chargement de DragonHaven\u2026","Apertura dell\u2019ultimo download di DragonHaven\u2026","Abrindo o download mais recente do DragonHaven\u2026","\u6700\u65b0\u306eDragonHaven\u30c0\u30a6\u30f3\u30ed\u30fc\u30c9\u3092\u958b\u3044\u3066\u3044\u307e\u3059\u2026"],t.s)
A.la=s(["\xd6ffnen","Abrir","Ouvrir","Apri","Abrir","\u958b\u304f"],t.s)
A.Fj=s(["Zahlung \xfcber PayPal","Pago mediante PayPal","Paiement via PayPal","Pagamento tramite PayPal","Pagamento via PayPal","PayPal\u3067\u652f\u6255\u3046"],t.s)
A.GW=s(["Platzieren","Colocar","Placer","Posiziona","Posicionar","\u914d\u7f6e"],t.s)
A.yu=s(["Platziert","Colocado","Plac\xe9","Posizionato","Posicionado","\u914d\u7f6e\u6e08\u307f"],t.s)
A.wq=s(["M\xf6gliches Jungtier","Posible cr\xeda","Nouveau-n\xe9 possible","Possibile cucciolo","Poss\xedvel filhote","\u5b75\u5316\u3059\u308b\u53ef\u80fd\u6027\u306e\u3042\u308b\u5e7c\u7adc"],t.s)
A.K0=s(["Gekaufte Gegenst\xe4nde geh\xf6ren dauerhaft dir.","Los objetos comprados siempre ser\xe1n tuyos.","Les objets achet\xe9s restent toujours \xe0 toi.","Gli oggetti acquistati restano sempre tuoi.","Itens comprados s\xe3o seus para sempre.","\u8cfc\u5165\u3057\u305f\u30a2\u30a4\u30c6\u30e0\u306f\u305a\u3063\u3068\u3042\u306a\u305f\u306e\u3082\u306e\u3067\u3059\u3002"],t.s)
A.Cc=s(["K\xe4ufe sind deaktiviert, bis Google-Play-Produkt-IDs und die serverseitige Belegpr\xfcfung eingerichtet sind.","Las compras est\xe1n desactivadas hasta configurar los ID de producto de Google Play y la validaci\xf3n de recibos en el servidor.","Les achats sont d\xe9sactiv\xe9s jusqu\u2019\xe0 la configuration des identifiants Google Play et de la validation des re\xe7us c\xf4t\xe9 serveur.","Gli acquisti sono disattivati finch\xe9 non saranno configurati gli ID prodotto Google Play e la convalida delle ricevute sul server.","As compras est\xe3o desativadas at\xe9 configurar IDs de produto do Google Play e valida\xe7\xe3o de recibos no servidor.","Google Play\u306e\u5546\u54c1ID\u3068\u30b5\u30fc\u30d0\u30fc\u5074\u306e\u30ec\u30b7\u30fc\u30c8\u691c\u8a3c\u304c\u8a2d\u5b9a\u3055\u308c\u308b\u307e\u3067\u8cfc\u5165\u306f\u7121\u52b9\u3067\u3059\u3002"],t.s)
A.yV=s(["Aufziehen","Criar","\xc9lever","Alleva","Criar","\u80b2\u3066\u308b"],t.s)
A.kG=s(["Dieses Ei aufziehen?","\xbfCriar este huevo?","\xc9lever cet \u0153uf ?","Allevare questo uovo?","Criar este ovo?","\u3053\u306e\u5375\u3092\u80b2\u3066\u307e\u3059\u304b\uff1f"],t.s)
A.FW=s(["Zieh Wunder gro\xdf. Bau ein Zuhause. F\xfclle das Draconomicon.","Cr\xeda maravillas. Construye un hogar. Completa el Draconomicon.","\xc9l\xe8ve l\u2019\xe9merveillement. B\xe2tis un foyer. Remplis le Draconomicon.","Coltiva la meraviglia. Costruisci una casa. Completa il Draconomicon.","Cultive maravilhas. Construa um lar. Complete o Draconomicon.","\u9a5a\u304d\u3092\u80b2\u3066\u3001\u4f4f\u307e\u3044\u3092\u7bc9\u304d\u3001\u30c9\u30e9\u30b3\u30ce\u30df\u30b3\u30f3\u3092\u6e80\u305f\u305d\u3046\u3002"],t.s)
A.lS=s(["Selten","Raro","Rare","Raro","Raro","\u30ec\u30a2"],t.s)
A.li=s(["Bei Besuchen k\xf6nnen Lieblingsdrache, R\xe4ume und Erfolge nur angesehen werden \u2013 auch gesperrte ???-Geheimnisse.","Las visitas de solo lectura muestran el drag\xf3n favorito, las habitaciones y los logros, incluidos secretos ??? bloqueados.","Les visites en lecture seule peuvent montrer le dragon favori, les pi\xe8ces et les succ\xe8s, y compris les secrets ??? verrouill\xe9s.","Le visite in sola lettura mostrano il drago preferito, le stanze e gli obiettivi, compresi i segreti ??? bloccati.","Visitas somente leitura mostram o drag\xe3o favorito, c\xf4modos e conquistas, incluindo segredos ??? bloqueados.","\u95b2\u89a7\u5c02\u7528\u306e\u8a2a\u554f\u3067\u306f\u3001\u304a\u6c17\u306b\u5165\u308a\u306e\u30c9\u30e9\u30b4\u30f3\u3001\u90e8\u5c4b\u3001\u5b9f\u7e3e\uff08\u672a\u89e3\u9664\u306e\u300c???\u300d\u3082\u542b\u3080\uff09\u3092\u78ba\u8a8d\u3067\u304d\u307e\u3059\u3002"],t.s)
A.CT=s(["Bereit","Listo","Pr\xeat","Pronto","Pronto","\u6e96\u5099\u5b8c\u4e86"],t.s)
A.oZ=s(["Bereit zum Schl\xfcpfen","Listo para eclosionar","Pr\xeat \xe0 \xe9clore","Pronto a schiudersi","Pronto para chocar","\u5b75\u5316\u3067\u304d\u307e\u3059"],t.s)
A.tN=s(["Einl\xf6sen","Canjear","Valider","Riscatta","Resgatar","\u5f15\u304d\u63db\u3048\u308b"],t.s)
A.wM=s(["Code einl\xf6sen","Canjear c\xf3digo","Utiliser un code","Riscatta codice","Resgatar c\xf3digo","\u30b3\u30fc\u30c9\u3092\u5f15\u304d\u63db\u3048\u308b"],t.s)
A.Cs=s(["Freilassen","Liberar","Lib\xe9rer","Libera","Libertar","\u653e\u3059"],t.s)
A.zt=s(["Drachen freilassen \u2026","Liberar drag\xf3n\u2026","Lib\xe9rer le dragon\u2026","Libera drago\u2026","Libertar drag\xe3o\u2026","\u30c9\u30e9\u30b4\u30f3\u3092\u653e\u3059\u2026"],t.s)
A.yq=s(["Entfernen","Quitar","Retirer","Rimuovi","Remover","\u53d6\u308a\u5916\u3059"],t.s)
A.B_=s(["Favorit entfernen","Quitar de favoritos","Retirer des favoris","Rimuovi dai preferiti","Remover dos favoritos","\u304a\u6c17\u306b\u5165\u308a\u3092\u89e3\u9664"],t.s)
A.Fh=s(["Dauerhaft entfernen","Eliminar para siempre","Retirer d\xe9finitivement","Rimuovi definitivamente","Remover permanentemente","\u5b8c\u5168\u306b\u524a\u9664"],t.s)
A.kr=s(["Reparieren","Reparar","R\xe9parer","Ripara","Reparar","\u4fee\u7406"],t.s)
A.GA=s(["Ins Inventar zur\xfccklegen","Devolver al inventario","Remettre dans l\u2019inventaire","Rimetti nell\u2019inventario","Devolver ao invent\xe1rio","\u6301\u3061\u7269\u306b\u623b\u3059"],t.s)
A.vD=s(["Dachnest","Nido de la Azotea","Nid du Toit","Nido sul Tetto","Ninho no Telhado","\u5c4b\u4e0a\u306e\u5de3"],t.s)
A.y5=s(["R\xe4ume","Habitaciones","Pi\xe8ces","Stanze","C\xf4modos","\u90e8\u5c4b"],t.s)
A.u2=s(["Hausgegenst\xe4nde suchen","Buscar objetos de la casa","Rechercher des objets pour la maison","Cerca oggetti per la casa","Pesquisar itens da casa","\u5bb6\u5177\u3092\u691c\u7d22"],t.s)
A.DE=s(["Suche \xfcber einen festen Spielercode; Namen gelten nie als eindeutige IDs.","Busca por un c\xf3digo de jugador estable; los nombres nunca se consideran identificadores \xfanicos.","Recherche avec un code joueur stable ; les noms ne sont jamais utilis\xe9s comme identifiants uniques.","Cerca tramite un codice giocatore stabile; i nomi non sono mai considerati ID univoci.","Pesquise por um c\xf3digo fixo de jogador; nomes nunca s\xe3o tratados como IDs exclusivos.","\u56fa\u5b9a\u306e\u30d7\u30ec\u30a4\u30e4\u30fc\u30b3\u30fc\u30c9\u3067\u691c\u7d22\u3057\u307e\u3059\u3002\u540d\u524d\u306f\u4e00\u610f\u306eID\u3068\u3057\u3066\u6271\u308f\u308c\u307e\u305b\u3093\u3002"],t.s)
A.q0=s(["Mit deinem Offline-Profil synchronisiert","Sincronizado con tu perfil sin conexi\xf3n","Synchronis\xe9 avec ton profil hors ligne","Sincronizzato con il tuo profilo offline","Sincronizado com o teu perfil offline","\u30aa\u30d5\u30e9\u30a4\u30f3\u30d7\u30ed\u30d5\u30a3\u30fc\u30eb\u3068\u540c\u671f\u6e08\u307f"],t.s)
A.oo=s(["Geheimer Erfolg","Logro secreto","Succ\xe8s secret","Obiettivo segreto","Conquista secreta","\u79d8\u5bc6\u306e\u5b9f\u7e3e"],t.s)
A.IE=s(["Silbertruhe","Cofre de Plata","Coffre en Argent","Forziere d\u2019Argento","Ba\xfa de Prata","\u9280\u306e\u5b9d\u7bb1"],t.s)
A.Dg=s(["Unheilvolle Truhe","Cofre Siniestro","Coffre Sinistre","Forziere Sinistro","Ba\xfa Sinistro","\u4e0d\u5409\u306a\u5b9d\u7bb1"],t.s)
A.Lq=s(["W\xe4hle einen Gegenstand und tippe dann auf seinen neuen Platz im Raum.","Selecciona un objeto y toca su nueva posici\xf3n en la habitaci\xf3n.","S\xe9lectionne un objet, puis touche son nouvel emplacement dans la pi\xe8ce.","Seleziona un oggetto, poi tocca il nuovo punto nella stanza.","Selecione um item e toque no novo lugar dele no c\xf4modo.","\u30a2\u30a4\u30c6\u30e0\u3092\u9078\u3073\u3001\u90e8\u5c4b\u306e\u65b0\u3057\u3044\u5834\u6240\u3092\u30bf\u30c3\u30d7\u3057\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.C_=s(["Als Favorit markieren","Marcar como favorito","Ajouter aux favoris","Imposta come preferito","Marcar como favorito","\u304a\u6c17\u306b\u5165\u308a\u306b\u3059\u308b"],t.s)
A.Fb=s(["DragonHaven teilen oder aktualisieren","Compartir o actualizar DragonHaven","Partager ou mettre \xe0 jour DragonHaven","Condividi o aggiorna DragonHaven","Compartilhar ou atualizar DragonHaven","DragonHaven\u3092\u5171\u6709\uff0f\u66f4\u65b0"],t.s)
A.mc=s(["Laden","Tienda","Boutique","Negozio","Loja","\u30b7\u30e7\u30c3\u30d7"],t.s)
A.uo=s(["Mini","Mini","Mini","Mini","Mini","\u30df\u30cb"],t.s)
A.lO=s(["Holz","Madera","Bois","Legno","Madeira","\u6728\u88fd"],t.s)
A.CX=s(["Kurz","Corta","Courte","Breve","Curta","\u30b7\u30e7\u30fc\u30c8"],t.s)
A.yW=s(["In der Spitze wurde etwas N\xfctzliches entdeckt.","Se descubri\xf3 algo \xfatil en la Aguja.","Quelque chose d\u2019utile a \xe9t\xe9 d\xe9couvert dans la Fl\xe8che.","\xc8 stato scoperto qualcosa di utile nella Guglia.","Algo \xfatil foi descoberto na Torre.","\u5854\u3067\u5f79\u7acb\u3064\u3082\u306e\u3092\u767a\u898b\u3057\u307e\u3057\u305f\u3002"],t.s)
A.FC=s(["Besonders","Especial","Sp\xe9cial","Speciale","Especial","\u30b9\u30da\u30b7\u30e3\u30eb"],t.s)
A.D5=s(["Drachen","Dragones","Dragons","Draghi","Drag\xf5es","\u30c9\u30e9\u30b4\u30f3"],t.s)
A.HM=s(["Spektral","Espectral","Spectral","Spettrale","Espectral","\u30b9\u30da\u30af\u30c8\u30e9\u30eb"],t.s)
A.A5=s(["Geist liegt derzeit vorn.","Esp\xedritu est\xe1 en cabeza.","Esprit est actuellement en t\xeate.","Spirito \xe8 attualmente in testa.","Esp\xedrito est\xe1 na frente.","\u73fe\u5728\u306f\u30b9\u30d4\u30ea\u30c3\u30c8\u304c\u512a\u52e2\u3067\u3059\u3002"],t.s)
A.Ka=s(["Sternendachboden","\xc1tico Estelar","Grenier des \xc9toiles","Soffitta Stellare","S\xf3t\xe3o Estelar","\u661f\u306e\u30ed\u30d5\u30c8"],t.s)
A.xs=s(["Sternenlicht-Leckerli \xb7 3 Edelsteine","Premio de luz estelar \xb7 3 gemas","Friandise astrale \xb7 3 gemmes","Dolcetto stellare \xb7 3 gemme","Petisco estelar \xb7 3 gemas","\u661f\u660e\u304b\u308a\u306e\u304a\u3084\u3064\u30fb\u30b8\u30a7\u30e03\u500b"],t.s)
A.AR=s(["Starten","Empezar","Commencer","Inizia","Iniciar","\u958b\u59cb"],t.s)
A.DD=s(["Sonnenschmiede","Forja Solar","Forge Solaire","Forgia Solare","Forja Solar","\u592a\u967d\u306e\u935b\u51b6\u5834"],t.s)
A.HH=s(["Sprich mit","Hablar con","Parler \xe0","Parla con","Falar com","\u8a71\u3057\u304b\u3051\u308b"],t.s)
A.pn=s(["Tippe auf die Truhe","Toca el cofre","Touchez le coffre","Tocca il forziere","Toque no ba\xfa","\u5b9d\u7bb1\u3092\u30bf\u30c3\u30d7"],t.s)
A.q9=s(["Ein Turmschatz wartet","Te espera un tesoro de la torre","Un tr\xe9sor de la tour vous attend","Ti aspetta un tesoro della torre","Um tesouro da torre espera por voc\xea","\u5854\u306e\u5b9d\u7269\u304c\u5f85\u3063\u3066\u3044\u307e\u3059"],t.s)
A.y1=s(["Schatz geborgen","Tesoro conseguido","Tr\xe9sor r\xe9cup\xe9r\xe9","Tesoro ottenuto","Tesouro resgatado","\u5b9d\u7269\u3092\u53d7\u3051\u53d6\u308a\u307e\u3057\u305f"],t.s)
A.Bp=s(["TIPPEN, UM DEINEN DRACHEN ZU RUFEN","TOCA PARA LLAMAR A TU DRAG\xd3N","TOUCHEZ POUR APPELER VOTRE DRAGON","TOCCA PER CHIAMARE IL TUO DRAGO","TOQUE PARA CHAMAR SEU DRAG\xc3O","\u30bf\u30c3\u30d7\u3057\u3066\u30c9\u30e9\u30b4\u30f3\u3092\u547c\u3076"],t.s)
A.Cz=s(["TIPPEN, UM DEINEN DRACHEN ZU BEWEGEN","TOCA PARA MOVER A TU DRAG\xd3N","TOUCHEZ POUR D\xc9PLACER VOTRE DRAGON","TOCCA PER SPOSTARE IL TUO DRAGO","TOQUE PARA MOVER SEU DRAG\xc3O","\u30bf\u30c3\u30d7\u3057\u3066\u30c9\u30e9\u30b4\u30f3\u3092\u79fb\u52d5"],t.s)
A.oY=s(["Dieser Drache ist bereits unterwegs.","Ese drag\xf3n ya est\xe1 fuera.","Ce dragon est d\xe9j\xe0 parti.","Quel drago \xe8 gi\xe0 fuori.","Esse drag\xe3o j\xe1 est\xe1 fora.","\u305d\u306e\u30c9\u30e9\u30b4\u30f3\u306f\u3059\u3067\u306b\u5916\u51fa\u4e2d\u3067\u3059\u3002"],t.s)
A.F6=s(["Dieser Raum kann hier nicht gebaut werden.","Esa habitaci\xf3n no puede construirse aqu\xed.","Cette pi\xe8ce ne peut pas \xeatre construite ici.","Questa stanza non pu\xf2 essere costruita qui.","Esse c\xf4modo n\xe3o pode ser constru\xeddo aqui.","\u3053\u3053\u306b\u306f\u305d\u306e\u90e8\u5c4b\u3092\u5efa\u3066\u3089\u308c\u307e\u305b\u3093\u3002"],t.s)
A.C3=s(["Das war aufschlussreich","Ha sido revelador","C\u2019\xe9tait instructif","\xc8 stato illuminante","Isso foi esclarecedor","\u3044\u3044\u8a71\u3067\u3057\u305f"],t.s)
A.x7=s(["Der Download konnte nicht ge\xf6ffnet werden. Der Link wurde stattdessen kopiert.","No se pudo abrir la descarga. Se copi\xf3 el enlace.","Impossible d\u2019ouvrir le t\xe9l\xe9chargement. Le lien a \xe9t\xe9 copi\xe9.","Impossibile aprire il download. Il link \xe8 stato copiato.","N\xe3o foi poss\xedvel abrir o download. O link foi copiado.","\u30c0\u30a6\u30f3\u30ed\u30fc\u30c9\u3092\u958b\u3051\u306a\u304b\u3063\u305f\u305f\u3081\u3001\u30ea\u30f3\u30af\u3092\u30b3\u30d4\u30fc\u3057\u307e\u3057\u305f\u3002"],t.s)
A.E2=s(["Der Downloadlink konnte nicht kopiert werden.","No se pudo copiar el enlace de descarga.","Impossible de copier le lien de t\xe9l\xe9chargement.","Impossibile copiare il link di download.","N\xe3o foi poss\xedvel copiar o link de download.","\u30c0\u30a6\u30f3\u30ed\u30fc\u30c9\u30ea\u30f3\u30af\u3092\u30b3\u30d4\u30fc\u3067\u304d\u307e\u305b\u3093\u3067\u3057\u305f\u3002"],t.s)
A.vx=s(["Der Downloadlink konnte weder ge\xf6ffnet noch kopiert werden.","No se pudo abrir ni copiar el enlace de descarga.","Impossible d\u2019ouvrir ou de copier le lien de t\xe9l\xe9chargement.","Impossibile aprire o copiare il link di download.","N\xe3o foi poss\xedvel abrir nem copiar o link de download.","\u30c0\u30a6\u30f3\u30ed\u30fc\u30c9\u30ea\u30f3\u30af\u3092\u958b\u304f\u3053\u3068\u3082\u30b3\u30d4\u30fc\u3059\u308b\u3053\u3068\u3082\u3067\u304d\u307e\u305b\u3093\u3067\u3057\u305f\u3002"],t.s)
A.JU=s(["Die zuk\xfcnftige Form ist noch ein Geheimnis.","La forma futura a\xfan es un misterio.","La forme future reste un myst\xe8re.","La forma futura \xe8 ancora un mistero.","A forma futura ainda \xe9 um mist\xe9rio.","\u672a\u6765\u306e\u59ff\u306f\u307e\u3060\u8b0e\u3067\u3059\u3002"],t.s)
A.uD=s(["Das Draconomicon","El Draconomicon","Le Draconomicon","Il Draconomicon","O Draconomicon","\u30c9\u30e9\u30b3\u30ce\u30df\u30b3\u30f3"],t.s)
A.IT=s(["Die Gruppe erf\xfcllt die Anforderungen nicht.","El grupo no cumple los requisitos.","Le groupe ne remplit pas les conditions.","Il gruppo non soddisfa i requisiti.","O grupo n\xe3o atende aos requisitos.","\u30b0\u30eb\u30fc\u30d7\u304c\u6761\u4ef6\u3092\u6e80\u305f\u3057\u3066\u3044\u307e\u305b\u3093\u3002"],t.s)
A.yj=s(["Das GitHub-Repository ist noch nicht verbunden. Baue mit --dart-define=DRAGONHAVEN_GITHUB_OWNER=deinname.","El repositorio de GitHub a\xfan no est\xe1 conectado. Compila con --dart-define=DRAGONHAVEN_GITHUB_OWNER=tunombre.","Le d\xe9p\xf4t GitHub n\u2019est pas encore connect\xe9. Compilez avec --dart-define=DRAGONHAVEN_GITHUB_OWNER=votrenom.","Il repository GitHub non \xe8 ancora collegato. Compila con --dart-define=DRAGONHAVEN_GITHUB_OWNER=tuonome.","O reposit\xf3rio do GitHub ainda n\xe3o est\xe1 conectado. Compile com --dart-define=DRAGONHAVEN_GITHUB_OWNER=seunome.","GitHub\u30ea\u30dd\u30b8\u30c8\u30ea\u304c\u672a\u63a5\u7d9a\u3067\u3059\u3002--dart-define=DRAGONHAVEN_GITHUB_OWNER=\u3042\u306a\u305f\u306e\u540d\u524d \u3092\u6307\u5b9a\u3057\u3066\u30d3\u30eb\u30c9\u3057\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.HD=s(["Der darin verborgene Drache geht f\xfcr immer verloren.","El drag\xf3n oculto en su interior se perder\xe1 para siempre.","Le dragon cach\xe9 \xe0 l\u2019int\xe9rieur sera perdu d\xe9finitivement.","Il drago nascosto all\u2019interno andr\xe0 perduto per sempre.","O drag\xe3o escondido dentro ser\xe1 perdido para sempre.","\u4e2d\u306b\u3044\u308b\u30c9\u30e9\u30b4\u30f3\u306f\u6c38\u4e45\u306b\u5931\u308f\u308c\u307e\u3059\u3002"],t.s)
A.mG=s(["Der am st\xe4rksten trainierte Pfad bestimmt die endg\xfcltige Form. Aktivit\xe4ten unter \u201eErkunden\u201c erh\xf6hen diese Werte.","La senda m\xe1s entrenada determina la forma final. Las actividades de Explorar aumentan estos valores.","La voie la plus entra\xeen\xe9e d\xe9termine la forme finale. Les activit\xe9s d\u2019Exploration augmentent ces valeurs.","Il percorso pi\xf9 allenato determina la forma finale. Le attivit\xe0 di Esplorazione aumentano questi valori.","O caminho mais treinado define a forma final. Atividades em Explorar aumentam esses valores.","\u6700\u3082\u935b\u3048\u305f\u9053\u304c\u6700\u7d42\u5f62\u614b\u3092\u6c7a\u3081\u307e\u3059\u3002\u300c\u63a2\u7d22\u300d\u306e\u6d3b\u52d5\u3067\u6570\u5024\u304c\u4e0a\u304c\u308a\u307e\u3059\u3002"],t.s)
A.p0=s(["Das Inventar ist leer. Erkunde die Spitze oder besuche den M\xf6belmarkt.","El inventario est\xe1 vac\xedo. Explora la Aguja o visita el mercado de muebles.","L\u2019inventaire est vide. Explore la Fl\xe8che ou visite le march\xe9 aux meubles.","L\u2019inventario \xe8 vuoto. Esplora la Guglia o visita il mercato dei mobili.","O invent\xe1rio est\xe1 vazio. Explore a Torre ou visite o mercado de m\xf3veis.","\u6301\u3061\u7269\u304c\u7a7a\u3067\u3059\u3002\u5854\u3092\u63a2\u7d22\u3059\u308b\u304b\u3001\u5bb6\u5177\u5e02\u5834\u3078\u884c\u304d\u307e\u3057\u3087\u3046\u3002"],t.s)
A.FR=s(["Das neueste Release enth\xe4lt keine g\xfcltigen Versionsdaten.","La versi\xf3n m\xe1s reciente no contiene datos de versi\xf3n v\xe1lidos.","La derni\xe8re version ne contient aucune donn\xe9e de version valide.","L\u2019ultima release non contiene dati di versione validi.","A vers\xe3o mais recente n\xe3o cont\xe9m dados de vers\xe3o v\xe1lidos.","\u6700\u65b0\u30ea\u30ea\u30fc\u30b9\u306b\u6709\u52b9\u306a\u30d0\u30fc\u30b8\u30e7\u30f3\u60c5\u5831\u304c\u3042\u308a\u307e\u305b\u3093\u3002"],t.s)
A.lo=s(["Die Versionspr\xfcfung hat zu lange gedauert.","La comprobaci\xf3n de la versi\xf3n tard\xf3 demasiado.","La v\xe9rification de la version a pris trop de temps.","Il controllo della versione ha richiesto troppo tempo.","A verifica\xe7\xe3o da vers\xe3o demorou demais.","\u30ea\u30ea\u30fc\u30b9\u306e\u78ba\u8a8d\u306b\u6642\u9593\u304c\u304b\u304b\u308a\u3059\u304e\u307e\u3057\u305f\u3002"],t.s)
A.wY=s(["Die sichere Verbindung zu GitHub ist fehlgeschlagen.","Fall\xf3 la conexi\xf3n segura con GitHub.","La connexion s\xe9curis\xe9e \xe0 GitHub a \xe9chou\xe9.","La connessione sicura a GitHub non \xe8 riuscita.","A conex\xe3o segura com o GitHub falhou.","GitHub\u3078\u306e\u5b89\u5168\u306a\u63a5\u7d9a\u306b\u5931\u6557\u3057\u307e\u3057\u305f\u3002"],t.s)
A.vF=s(["Die Schale zittert \u2026","La c\xe1scara est\xe1 temblando...","La coquille tremble...","Il guscio sta tremando...","A casca est\xe1 tremendo...","\u6bbb\u304c\u9707\u3048\u3066\u3044\u307e\u3059\u2026"],t.s)
A.GH=s(["Der Turm hat bereits 20 Etagen.","La torre ya tiene 20 pisos.","La tour compte d\xe9j\xe0 20 \xe9tages.","La torre ha gi\xe0 20 piani.","A torre j\xe1 tem 20 andares.","\u5854\u306f\u3059\u3067\u306b20\u968e\u3067\u3059\u3002"],t.s)
A.x6=s(["Das Turmnest","El nido de la torre","Le nid de la tour","Il nido della torre","O ninho da torre","\u5854\u306e\u5de3"],t.s)
A.xG=s(["Dies kann nicht r\xfcckg\xe4ngig gemacht werden und bringt keine M\xfcnzen zur\xfcck.","Esto no se puede deshacer y no devuelve monedas.","Cette action est irr\xe9versible et ne rend aucune pi\xe8ce.","L\u2019azione non pu\xf2 essere annullata e non restituisce monete.","Isso n\xe3o pode ser desfeito e n\xe3o devolve moedas.","\u5143\u306b\u623b\u3059\u3053\u3068\u306f\u3067\u304d\u305a\u3001\u30b3\u30a4\u30f3\u3082\u8fd4\u5374\u3055\u308c\u307e\u305b\u3093\u3002"],t.s)
A.mE=s(["Diese Version speichert deine Sammlung sicher auf diesem Ger\xe4t. Eine echte Freundesliste ben\xf6tigt angemeldete Konten und einen Server; deshalb werden keine lokalen Demokontakte als online angezeigt.","Esta versi\xf3n guarda tu colecci\xf3n de forma segura en este dispositivo. Una lista de amigos real necesita cuentas autenticadas y un servidor, as\xed que no se muestran contactos de prueba como si estuvieran en l\xednea.","Cette version conserve votre collection sur cet appareil. Une vraie liste d\u2019amis exige des comptes authentifi\xe9s et un serveur ; aucun contact fictif n\u2019est donc affich\xe9 comme connect\xe9.","Questa versione conserva la collezione sul dispositivo. Un vero elenco amici richiede account autenticati e un server, quindi non vengono mostrati contatti demo come se fossero online.","Esta vers\xe3o mant\xe9m sua cole\xe7\xe3o segura no dispositivo. Uma lista real de amigos requer contas autenticadas e um servidor, por isso nenhum contato de demonstra\xe7\xe3o aparece como online.","\u3053\u306e\u30d3\u30eb\u30c9\u3067\u306f\u30b3\u30ec\u30af\u30b7\u30e7\u30f3\u3092\u7aef\u672b\u5185\u306b\u5b89\u5168\u306b\u4fdd\u5b58\u3057\u307e\u3059\u3002\u672c\u7269\u306e\u30d5\u30ec\u30f3\u30c9\u30ea\u30b9\u30c8\u306b\u306f\u8a8d\u8a3c\u6e08\u307f\u30a2\u30ab\u30a6\u30f3\u30c8\u3068\u30b5\u30fc\u30d0\u30fc\u304c\u5fc5\u8981\u306a\u305f\u3081\u3001\u30c7\u30e2\u306e\u4eba\u7269\u3092\u30aa\u30f3\u30e9\u30a4\u30f3\u3068\u3057\u3066\u8868\u793a\u3057\u307e\u305b\u3093\u3002"],t.s)
A.ms=s(["Dieser Drache verl\xe4sst deine Sammlung und kann nicht mehr trainiert werden. Identit\xe4t, Form, Ausrichtung und verborgene Pers\xf6nlichkeit bleiben erhalten.","Este drag\xf3n dejar\xe1 tu colecci\xf3n y no podr\xe1 entrenarse. Se conservar\xe1n su identidad, forma, afinidad y personalidad oculta.","Ce dragon quittera votre collection et ne pourra plus \xeatre entra\xeen\xe9. Son identit\xe9, sa forme, son affinit\xe9 et sa personnalit\xe9 cach\xe9e seront conserv\xe9es.","Questo drago lascer\xe0 la collezione e non potr\xe0 essere allenato. Identit\xe0, forma, affinit\xe0 e personalit\xe0 nascosta resteranno intatte.","Este drag\xe3o deixar\xe1 sua cole\xe7\xe3o e n\xe3o poder\xe1 ser treinado. Identidade, forma, afinidade e personalidade oculta ser\xe3o preservadas.","\u3053\u306e\u30c9\u30e9\u30b4\u30f3\u306f\u30b3\u30ec\u30af\u30b7\u30e7\u30f3\u3092\u96e2\u308c\u3001\u8a13\u7df4\u3067\u304d\u306a\u304f\u306a\u308a\u307e\u3059\u3002\u500b\u4f53\u60c5\u5831\u3001\u5f62\u614b\u3001\u8cc7\u8cea\u3001\u96a0\u308c\u305f\u6027\u683c\u306f\u4fdd\u6301\u3055\u308c\u307e\u3059\u3002"],t.s)
A.tL=s(["Dieser Code ist nicht aktiv.","Este c\xf3digo no est\xe1 activo.","Ce code n\u2019est pas actif.","Questo codice non \xe8 attivo.","Este c\xf3digo n\xe3o est\xe1 ativo.","\u3053\u306e\u30b3\u30fc\u30c9\u306f\u6709\u52b9\u3067\u306f\u3042\u308a\u307e\u305b\u3093\u3002"],t.s)
A.ng=s(["Dieses Angebot ist nicht mehr verf\xfcgbar.","Esta oferta ya no est\xe1 disponible.","Cette offre n\u2019est plus disponible.","Questa offerta non \xe8 pi\xf9 disponibile.","Esta oferta n\xe3o est\xe1 mais dispon\xedvel.","\u3053\u306e\u4f9d\u983c\u306f\u3082\u3046\u5229\u7528\u3067\u304d\u307e\u305b\u3093\u3002"],t.s)
A.I2=s(["Dieser Raum geh\xf6rt bereits zum Haus.","Esta habitaci\xf3n ya forma parte de la casa.","Cette pi\xe8ce fait d\xe9j\xe0 partie de la maison.","Questa stanza fa gi\xe0 parte della casa.","Este c\xf4modo j\xe1 faz parte da casa.","\u3053\u306e\u90e8\u5c4b\u306f\u3059\u3067\u306b\u5efa\u7bc9\u6e08\u307f\u3067\u3059\u3002"],t.s)
A.qP=s(["Gezeitenbibliothek","Biblioteca de las Mareas","Biblioth\xe8que des Mar\xe9es","Biblioteca delle Maree","Biblioteca das Mar\xe9s","\u6f6e\u306e\u56f3\u66f8\u9928"],t.s)
A.kc=s(["Turm","Torre","Tour","Torre","Torre","\u5854"],t.s)
A.FQ=s(["Turmbesuche","Visitas a torres","Visites de tours","Visite alle torri","Visitas \xe0s torres","\u5854\u3078\u306e\u8a2a\u554f"],t.s)
A.Br=s(["Beidseitiger Tausch","Intercambio bilateral","\xc9change bilat\xe9ral","Scambio bilaterale","Troca bilateral","\u76f8\u4e92\u4ea4\u63db"],t.s)
A.Dq=s(["Unentdeckte Drachenform","Forma de drag\xf3n sin descubrir","Forme de dragon non d\xe9couverte","Forma di drago non scoperta","Forma de drag\xe3o n\xe3o descoberta","\u672a\u767a\u898b\u306e\u30c9\u30e9\u30b4\u30f3\u5f62\u614b"],t.s)
A.q6=s(["Einzigartige Stimmung und Raumaufteilung","Ambiente y distribuci\xf3n \xfanicos","Ambiance et agencement uniques","Atmosfera e disposizione uniche","Atmosfera e disposi\xe7\xe3o \xfanicas","\u56fa\u6709\u306e\u96f0\u56f2\u6c17\u3068\u30ec\u30a4\u30a2\u30a6\u30c8"],t.s)
A.oa=s(["Unbekannte Familie","Linaje desconocido","Lign\xe9e inconnue","Stirpe sconosciuta","Linhagem desconhecida","\u672a\u77e5\u306e\u7cfb\u7d71"],t.s)
A.wz=s(["Bis zu 3 Angebote, aktualisiert um Mitternacht deiner Ortszeit.","Hasta 3 ofertas, renovadas a medianoche local.","Jusqu\u2019\xe0 3 offres, renouvel\xe9es \xe0 minuit heure locale.","Fino a 3 offerte, aggiornate a mezzanotte locale.","At\xe9 3 ofertas, atualizadas \xe0 meia-noite local.","\u6700\u59273\u4ef6\u3002\u73fe\u5730\u6642\u9593\u306e\u5348\u524d0\u6642\u306b\u66f4\u65b0\u3055\u308c\u307e\u3059\u3002"],t.s)
A.tW=s(["Bis zu 3 Angebote. Freie Pl\xe4tze werden st\xfcndlich aufgef\xfcllt; du kannst eines wegschicken.","Hasta 3 ofertas. Los huecos se renuevan cada hora; puedes descartar una.","Jusqu\u2019\xe0 3 offres. Les places libres sont renouvel\xe9es chaque heure ; tu peux en ignorer une.","Fino a 3 offerte. Gli spazi liberi si aggiornano ogni ora; puoi congedarne una.","At\xe9 3 ofertas. Vagas abertas s\xe3o renovadas a cada hora; voc\xea pode dispensar uma.","\u6700\u59273\u4ef6\u3002\u7a7a\u304d\u67a0\u306f1\u6642\u9593\u3054\u3068\u306b\u66f4\u65b0\u3055\u308c\u30011\u4ef6\u3092\u898b\u9001\u308c\u307e\u3059\u3002"],t.s)
A.t3=s(["Verwende nur zusammenh\xe4ngende Gro\xdfbuchstaben.","Usa solo letras may\xfasculas seguidas.","Utilisez uniquement des lettres majuscules sans espace.","Usa solo lettere maiuscole consecutive.","Use apenas letras mai\xfasculas juntas.","\u5927\u6587\u5b57\u3060\u3051\u3092\u7d9a\u3051\u3066\u5165\u529b\u3057\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.FD=s(["Verwende nur zusammenh\xe4ngende Gro\xdfbuchstaben und Zahlen.","Usa solo letras may\xfasculas y n\xfameros seguidos.","Utilisez uniquement des lettres majuscules et des chiffres sans espace.","Usa solo lettere maiuscole e numeri consecutivi.","Use apenas letras mai\xfasculas e n\xfameros juntos.","\u5927\u6587\u5b57\u3068\u6570\u5b57\u3060\u3051\u3092\u7d9a\u3051\u3066\u5165\u529b\u3057\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.me=s(["Drachen-Emote-Paket freigeschaltet. Seine zehn Emotes sind einsatzbereit!","\xa1Paquete de emotes de drag\xf3n desbloqueado! Sus diez emotes est\xe1n listos para usar.","Pack d\u2019emotes de dragon d\xe9verrouill\xe9. Ses dix emotes sont pr\xeats \xe0 \xeatre utilis\xe9s !","Pacchetto di emote drago sbloccato. Le sue dieci emote sono pronte all\u2019uso!","Pacote de emotes de drag\xe3o desbloqueado. Os dez emotes est\xe3o prontos para usar!","\u30c9\u30e9\u30b4\u30f3\u7d75\u6587\u5b57\u30d1\u30c3\u30af\u3092\u30a2\u30f3\u30ed\u30c3\u30af\u3057\u307e\u3057\u305f\u300210\u7a2e\u985e\u3059\u3079\u3066\u4f7f\u7528\u3067\u304d\u307e\u3059\uff01"],t.s)
A.m1=s(["Du besitzt dieses Drachen-Emote-Paket bereits.","Ya tienes este paquete de emotes de drag\xf3n.","Vous poss\xe9dez d\xe9j\xe0 ce pack d\u2019emotes de dragon.","Possiedi gi\xe0 questo pacchetto di emote drago.","Voc\xea j\xe1 possui este pacote de emotes de drag\xe3o.","\u3053\u306e\u30c9\u30e9\u30b4\u30f3\u7d75\u6587\u5b57\u30d1\u30c3\u30af\u306f\u3059\u3067\u306b\u6240\u6709\u3057\u3066\u3044\u307e\u3059\u3002"],t.s)
A.Hy=s(["Version","Versi\xf3n","Version","Versione","Vers\xe3o","\u30d0\u30fc\u30b8\u30e7\u30f3"],t.s)
A.FT=s(["Besuche T\xfcrme, leihe einen freundlichen Drachen aus und tausche Eier, Truhen oder M\xf6bel.","Visita torres, presta un drag\xf3n amistoso e intercambia huevos, cofres o muebles.","Visite des tours, pr\xeate un dragon amical et \xe9change des \u0153ufs, coffres ou meubles.","Visita torri, presta un drago amichevole e scambia uova, forzieri o mobili.","Visite torres, empreste um drag\xe3o amig\xe1vel e troque ovos, ba\xfas ou m\xf3veis.","\u5854\u3092\u8a2a\u308c\u3001\u4ef2\u826f\u3057\u306e\u30c9\u30e9\u30b4\u30f3\u3092\u8cb8\u3057\u3001\u5375\u30fb\u5b9d\u7bb1\u30fb\u5bb6\u5177\u3092\u4ea4\u63db\u3057\u307e\u3057\u3087\u3046\u3002"],t.s)
A.Cv=s(["Wand","Pared","Mur","Parete","Parede","\u58c1\u98fe\u308a"],t.s)
A.L6=s(["Willkommen","Bienvenido","Bienvenue","Benvenuto","Boas-vindas","\u3088\u3046\u3053\u305d"],t.s)
A.p5=s(["Wohlbefinden","Bienestar","Bien-\xeatre","Benessere","Bem-estar","\u30b3\u30f3\u30c7\u30a3\u30b7\u30e7\u30f3"],t.s)
A.kW=s(["Holztruhe","Cofre de Madera","Coffre en Bois","Forziere di Legno","Ba\xfa de Madeira","\u6728\u306e\u5b9d\u7bb1"],t.s)
A.Ff=s(["Jungwyrm","Drag\xf3n joven","Jeune wyrm","Giovane wyrm","Jovem wyrm","\u82e5\u7adc"],t.s)
A.uY=s(["Name deines H\xfcters","Nombre de tu cuidador","Nom de ton gardien","Nome del tuo custode","Nome do seu guardi\xe3o","\u30ad\u30fc\u30d1\u30fc\u306e\u540d\u524d"],t.s)
A.py=s(["Dein aktueller Drache zieht sicher in die Sammlung des Refugiums. M\xfcnzen, Edelsteine und Entdeckungen bleiben erhalten.","Tu drag\xf3n actual pasar\xe1 a salvo a la colecci\xf3n del santuario. Conservar\xe1s monedas, gemas y descubrimientos.","Votre dragon actuel rejoint la collection du sanctuaire en toute s\xe9curit\xe9. Pi\xe8ces, gemmes et d\xe9couvertes sont conserv\xe9es.","Il drago attuale passer\xe0 al sicuro nella collezione del santuario. Monete, gemme e scoperte resteranno tue.","Seu drag\xe3o atual ir\xe1 com seguran\xe7a para a cole\xe7\xe3o do santu\xe1rio. Moedas, gemas e descobertas continuam suas.","\u73fe\u5728\u306e\u30c9\u30e9\u30b4\u30f3\u306f\u5b89\u5168\u306b\u8056\u57df\u306e\u30b3\u30ec\u30af\u30b7\u30e7\u30f3\u3078\u79fb\u308a\u307e\u3059\u3002\u30b3\u30a4\u30f3\u3001\u30b8\u30a7\u30e0\u3001\u767a\u898b\u8a18\u9332\u306f\u6b8b\u308a\u307e\u3059\u3002"],t.s)
A.BK=s(["\u2726 ETWAS IST ANDERS \u2026","\u2726 ALGO ES DIFERENTE...","\u2726 QUELQUE CHOSE EST DIFF\xc9RENT...","\u2726 C\u2019\xc8 QUALCOSA DI DIVERSO...","\u2726 ALGO EST\xc1 DIFERENTE...","\u2726 \u4f55\u304b\u304c\u9055\u3046\u2026"],t.s)
A.mx=s(["Dein lebendiges Verzeichnis aller Drachenformen, die du aufgezogen hast.","Tu registro vivo de todas las formas de drag\xf3n que has criado.","Le registre vivant de toutes les formes de dragon que tu as \xe9lev\xe9es.","Il registro vivente di ogni forma di drago che hai allevato.","Seu registro vivo de todas as formas de drag\xe3o que voc\xea criou.","\u80b2\u3066\u305f\u3059\u3079\u3066\u306e\u30c9\u30e9\u30b4\u30f3\u5f62\u614b\u3092\u8a18\u3059\u3001\u751f\u304d\u305f\u8a18\u9332\u3067\u3059\u3002"],t.s)
A.CD=s(["Deine gekauften M\xf6bel werden hier aufbewahrt.","Aqu\xed se guardan los muebles que has comprado.","Tes meubles achet\xe9s sont rang\xe9s ici.","I mobili acquistati sono conservati qui.","Seus m\xf3veis comprados ficam guardados aqui.","\u8cfc\u5165\u3057\u305f\u5bb6\u5177\u306f\u3053\u3053\u306b\u4fdd\u7ba1\u3055\u308c\u307e\u3059\u3002"],t.s)
A.xY=s(["Dein Refugium ist noch nicht bereit f\xfcr diesen Raum.","Tu santuario a\xfan no est\xe1 listo para esta habitaci\xf3n.","Ton sanctuaire n\u2019est pas encore pr\xeat pour cette pi\xe8ce.","Il tuo santuario non \xe8 ancora pronto per questa stanza.","Seu santu\xe1rio ainda n\xe3o est\xe1 pronto para este c\xf4modo.","\u8056\u57df\u306f\u307e\u3060\u3053\u306e\u90e8\u5c4b\u3092\u5efa\u3066\u3089\u308c\u308b\u6bb5\u968e\u3067\u306f\u3042\u308a\u307e\u305b\u3093\u3002"],t.s)
A.yn=s(["M\xfcnzen","monedas","pi\xe8ces","monete","moedas","\u30b3\u30a4\u30f3"],t.s)
A.zh=s(["Etagen","pisos","\xe9tages","piani","andares","\u968e"],t.s)
A.u9=s(["Formen","formas","formes","forme","formas","\u5f62\u614b"],t.s)
A.jW=s(["gesperrt","bloqueado","verrouill\xe9","bloccato","bloqueado","\u672a\u89e3\u9664"],t.s)
A.n2=s(["Pfad unentschieden","senda sin decidir","voie ind\xe9cise","percorso non deciso","caminho indefinido","\u9032\u5316\u306e\u9053\u306f\u672a\u5b9a"],t.s)
A.rc=s(["freigeschaltet","desbloqueado","d\xe9bloqu\xe9","sbloccato","desbloqueado","\u89e3\u9664\u6e08\u307f"],t.s)
A.q3=s(["Training","entrenamiento","entra\xeenement","allenamento","treino","\u30c8\u30ec\u30fc\u30cb\u30f3\u30b0"],t.s)
A.Ce=s(["Morgengrauen","Amanecer","Aube","Alba","Alvorada","\u591c\u660e\u3051"],t.s)
A.y7=s(["Tag","D\xeda","Jour","Giorno","Dia","\u663c"],t.s)
A.zO=s(["Tiefe Nacht","Noche profunda","Nuit profonde","Notte fonda","Noite profunda","\u6df1\u591c"],t.s)
A.uh=s(["D\xe4mmerung","Anochecer","Cr\xe9puscule","Tramonto","Anoitecer","\u5915\u66ae\u308c"],t.s)
A.L3=s(["Goldene Stunde","Hora dorada","Heure dor\xe9e","Ora dorata","Hora dourada","\u9ec4\u91d1\u306e\u6642\u9593"],t.s)
A.pk=s(["Legend\xe4r","Legendario","L\xe9gendaire","Leggendario","Lend\xe1rio","\u30ec\u30b8\u30a7\u30f3\u30c0\u30ea\u30fc"],t.s)
A.xN=s(["Morgen","Ma\xf1ana","Matin","Mattina","Manh\xe3","\u671d"],t.s)
A.ul=s(["Mythisch","M\xedtico","Mythique","Mitico","M\xedtico","\u30df\u30b7\u30ab\u30eb"],t.s)
A.Cy=s(["Nacht","Noche","Nuit","Notte","Noite","\u591c"],t.s)
A.xI=s(["Ungew\xf6hnlich","Poco com\xfan","Peu commun","Non comune","Incomum","\u30a2\u30f3\u30b3\u30e2\u30f3"],t.s)
A.Hd=s(["Sehr selten","Muy raro","Tr\xe8s rare","Molto raro","Muito raro","\u30d9\u30ea\u30fc\u30ec\u30a2"],t.s)
A.K3=s(["Ein sanftes Leuchten bleibt unter deiner Hand zur\xfcck.","Un brillo suave permanece bajo tu mano.","Une douce lueur persiste sous votre main.","Un bagliore delicato resta sotto la tua mano.","Um brilho suave permanece sob sua m\xe3o.","\u624b\u306e\u4e0b\u306b\u3084\u3055\u3057\u3044\u5149\u304c\u3057\u3070\u3089\u304f\u6b8b\u308a\u307e\u3059\u3002"],t.s)
A.zs=s(["Ein seltsames, musikalisches Klopfen antwortet von innen.","Un extra\xf1o golpecito musical responde desde dentro.","Un \xe9trange petit bruit musical r\xe9pond de l\u2019int\xe9rieur.","Dall\u2019interno risponde uno strano colpetto musicale.","Uma estranha batidinha musical responde l\xe1 de dentro.","\u4e2d\u304b\u3089\u4e0d\u601d\u8b70\u306a\u97f3\u8272\u306e\u30ce\u30c3\u30af\u304c\u8fd4\u3063\u3066\u304d\u307e\u3059\u3002"],t.s)
A.FN=s(["Ein winziger Funke tanzt \xfcber die Schale.","Una chispa diminuta salta sobre la c\xe1scara.","Une minuscule \xe9tincelle court sur la coquille.","Una minuscola scintilla corre sul guscio.","Uma fa\xedsca min\xfascula salta pela casca.","\u5c0f\u3055\u306a\u706b\u82b1\u304c\u6bbb\u306e\u4e0a\u3092\u8df3\u306d\u307e\u3057\u305f\u3002"],t.s)
A.Lj=s(["Sobald du ein Muster suchst, wird es still.","Se queda quieto cuando intentas encontrar un patr\xf3n.","Tout se calme d\xe8s que vous cherchez un rythme.","Si ferma ogni volta che cerchi uno schema.","Fica quieto sempre que voc\xea tenta encontrar um padr\xe3o.","\u52d5\u304d\u306e\u898f\u5247\u3092\u63a2\u305d\u3046\u3068\u3059\u308b\u3068\u3001\u3044\u3064\u3082\u9759\u304b\u306b\u306a\u308a\u307e\u3059\u3002"],t.s)
A.tt=s(["Etwas darin scheint aufmerksam zur\xfcckzulauschen.","Algo dentro parece escuchar a su vez.","Quelque chose \xe0 l\u2019int\xe9rieur semble \xe9couter en retour.","Qualcosa dentro sembra ascoltare a sua volta.","Algo l\xe1 dentro parece escutar voc\xea tamb\xe9m.","\u4e2d\u306b\u3044\u308b\u4f55\u304b\u3082\u3001\u3053\u3061\u3089\u306e\u97f3\u306b\u8033\u3092\u6f84\u307e\u305b\u3066\u3044\u307e\u3059\u3002"],t.s)
A.Fg=s(["Wenn die Sterne erscheinen, wird das Ei unruhig.","El huevo se inquieta cuando aparecen las estrellas.","L\u2019\u0153uf s\u2019agite lorsque les \xe9toiles apparaissent.","L\u2019uovo diventa irrequieto quando compaiono le stelle.","O ovo fica inquieto quando as estrelas aparecem.","\u661f\u304c\u73fe\u308c\u308b\u3068\u3001\u5375\u304c\u305d\u308f\u305d\u308f\u3057\u59cb\u3081\u307e\u3059\u3002"],t.s)
A.Ix=s(["Das Ei rollt ein St\xfcck. Bergauf.","El huevo rueda un poco. Cuesta arriba.","L\u2019\u0153uf roule un peu. Vers le haut de la pente.","L\u2019uovo rotola un po\u2019. In salita.","O ovo rola um pouco. Morro acima.","\u5375\u304c\u5c11\u3057\u8ee2\u304c\u308a\u307e\u3057\u305f\u3002\u5742\u306e\u4e0a\u3078\u3002"],t.s)
A.Ie=s(["Die Bewegungen darin folgen einem pr\xe4zisen Rhythmus.","Los movimientos interiores siguen un ritmo preciso.","Les mouvements \xe0 l\u2019int\xe9rieur suivent un rythme pr\xe9cis.","I movimenti all\u2019interno seguono un ritmo preciso.","Os movimentos l\xe1 dentro seguem um ritmo preciso.","\u4e2d\u306e\u52d5\u304d\u306f\u6b63\u78ba\u306a\u30ea\u30ba\u30e0\u306b\u5f93\u3063\u3066\u3044\u307e\u3059\u3002"],t.s)
A.FM=s(["Das Nest riecht pl\xf6tzlich nach Regen und Moos.","De pronto, el nido huele a lluvia y musgo.","Le nid sent soudain la pluie et la mousse.","Il nido profuma improvvisamente di pioggia e muschio.","De repente, o ninho cheira a chuva e musgo.","\u5de3\u304b\u3089\u7a81\u7136\u3001\u96e8\u3068\u82d4\u306e\u9999\u308a\u304c\u3057\u307e\u3059\u3002"],t.s)
A.mX=s(["Die Schale f\xfchlt sich ungew\xf6hnlich warm an.","La c\xe1scara est\xe1 inusualmente caliente.","La coquille semble anormalement chaude.","Il guscio sembra insolitamente caldo.","A casca parece quente demais.","\u6bbb\u304c\u3044\u3064\u3082\u3088\u308a\u6e29\u304b\u304f\u611f\u3058\u307e\u3059\u3002"],t.s)
A.yc=s(["Du bist ziemlich sicher, dass das Ei gerade zur\xfcckgeklopft hat.","Est\xe1s casi seguro de que el huevo acaba de responder con un golpecito.","Vous \xeates presque certain que l\u2019\u0153uf vient de r\xe9pondre.","Sei quasi certo che l\u2019uovo abbia appena risposto con un colpetto.","Voc\xea tem quase certeza de que o ovo acabou de bater de volta.","\u5375\u304c\u4eca\u3001\u3053\u3061\u3089\u3078\u30ce\u30c3\u30af\u3092\u8fd4\u3057\u305f\u6c17\u304c\u3057\u307e\u3059\u3002"],t.s)
A.Jx=s(["Du h\xf6rst etwas, das beinahe wie ferne Wellen klingt.","Oyes algo parecido a olas lejanas.","Vous entendez quelque chose qui ressemble \xe0 des vagues lointaines.","Senti qualcosa che somiglia a onde lontane.","Voc\xea ouve algo parecido com ondas distantes.","\u9060\u304f\u306e\u6ce2\u306e\u3088\u3046\u306a\u97f3\u304c\u805e\u3053\u3048\u307e\u3059\u3002"],t.s)
A.J9=s(["{dragon} zog ein Buch heraus und blickte bei Kapitel drei schockiert.","{dragon} sac\xf3 un libro y qued\xf3 sorprendido con el cap\xedtulo tres.","{dragon} a sorti un livre et a sembl\xe9 boulevers\xe9 par le chapitre trois.","{dragon} ha preso un libro ed \xe8 rimasto sconvolto dal terzo capitolo.","{dragon} puxou um livro e ficou chocado com o cap\xedtulo tr\xeas.","{dragon} \u306f\u672c\u3092\u53d6\u308a\u51fa\u3057\u3001\u7b2c3\u7ae0\u3092\u8aad\u3093\u3067\u9a5a\u304d\u307e\u3057\u305f\u3002"],t.s)
A.HQ=s(["{dragon} rollte sich am Feuer zusammen und beanspruchte sofort den w\xe4rmsten Platz.","{dragon} se acurruc\xf3 junto al fuego y reclam\xf3 el lugar m\xe1s c\xe1lido.","{dragon} s\u2019est blotti pr\xe8s du feu et a aussit\xf4t pris la place la plus chaude.","{dragon} si \xe8 raggomitolato accanto al fuoco prendendo subito il posto pi\xf9 caldo.","{dragon} se enrolou perto do fogo e logo ocupou o lugar mais quente.","{dragon} \u306f\u706b\u306e\u305d\u3070\u3067\u4e38\u304f\u306a\u308a\u3001\u4e00\u756a\u6696\u304b\u3044\u5834\u6240\u3092\u78ba\u4fdd\u3057\u307e\u3057\u305f\u3002"],t.s)
A.ln=s(["{dragon} pr\xfcfte die Snacks. Einer fehlt nun auf geheimnisvolle Weise.","{dragon} inspeccion\xf3 los aperitivos. Ahora falta uno misteriosamente.","{dragon} a inspect\xe9 les friandises. L\u2019une d\u2019elles a myst\xe9rieusement disparu.","{dragon} ha ispezionato gli spuntini. Ora ne manca misteriosamente uno.","{dragon} inspecionou os petiscos. Um deles sumiu misteriosamente.","{dragon} \u306f\u304a\u3084\u3064\u3092\u70b9\u691c\u3057\u307e\u3057\u305f\u3002\u4e00\u3064\u3060\u3051\u4e0d\u601d\u8b70\u3068\u6d88\u3048\u3066\u3044\u307e\u3059\u3002"],t.s)
A.GV=s(["{dragon} machte einen winzigen Platscher und ein ganz und gar nicht winziges Durcheinander.","{dragon} dio un peque\xf1o chapuz\xf3n y arm\xf3 un desastre nada peque\xf1o.","{dragon} a fait une petite \xe9claboussure et un d\xe9sordre pas petit du tout.","{dragon} ha fatto un piccolo spruzzo e un disastro per niente piccolo.","{dragon} deu um pequeno mergulho e fez uma bagun\xe7a nada pequena.","{dragon} \u306f\u5c0f\u3055\u304f\u6c34\u3092\u306f\u306d\u3001\u3068\u3066\u3082\u5c0f\u3055\u3044\u3068\u306f\u8a00\u3048\u306a\u3044\u9a12\u304e\u3092\u8d77\u3053\u3057\u307e\u3057\u305f\u3002"],t.s)
A.vY=s(["{dragon} z\xe4hlte jeden gl\xe4nzenden Gegenstand sicherheitshalber zweimal.","{dragon} cont\xf3 dos veces cada objeto brillante, por si acaso.","{dragon} a compt\xe9 deux fois chaque objet brillant, par prudence.","{dragon} ha contato due volte ogni oggetto brillante, per sicurezza.","{dragon} contou cada objeto brilhante duas vezes, s\xf3 por garantia.","{dragon} \u306f\u5ff5\u306e\u305f\u3081\u3001\u5149\u308b\u3082\u306e\u3092\u3059\u3079\u3066\u4e8c\u56de\u6570\u3048\u307e\u3057\u305f\u3002"],t.s)
A.rK=s(["{dragon} verschwand f\xfcr ein h\xf6chst strategisches Nickerchen zwischen den Bl\xe4ttern.","{dragon} desapareci\xf3 entre las hojas para una siesta muy estrat\xe9gica.","{dragon} a disparu entre les feuilles pour une sieste hautement strat\xe9gique.","{dragon} \xe8 sparito tra le foglie per un pisolino altamente strategico.","{dragon} sumiu entre as folhas para um cochilo altamente estrat\xe9gico.","{dragon} \u306f\u6975\u3081\u3066\u6226\u7565\u7684\u306a\u663c\u5bdd\u306e\u305f\u3081\u3001\u8449\u306e\u9593\u306b\u6d88\u3048\u307e\u3057\u305f\u3002"],t.s)
A.kf=s(["{dragon} baute aus dem Bettzeug eine Festung. Erwachsene verboten.","{dragon} convirti\xf3 la ropa de cama en una fortaleza. Prohibidos los adultos.","{dragon} a transform\xe9 la literie en fort. Adultes interdits.","{dragon} ha trasformato il letto in un fortino. Adulti vietati.","{dragon} transformou a cama em um forte. Adultos n\xe3o entram.","{dragon} \u306f\u5bdd\u5177\u3067\u7826\u3092\u4f5c\u308a\u307e\u3057\u305f\u3002\u5927\u4eba\u306f\u7acb\u5165\u7981\u6b62\u3067\u3059\u3002"],t.s)
A.kw=s(["{dragon} tippte auf den magischen Schmuck. Er tippte h\xf6flich zur\xfcck.","{dragon} toc\xf3 el adorno m\xe1gico. Este respondi\xf3 educadamente.","{dragon} a touch\xe9 l\u2019ornement magique. Il a poliment r\xe9pondu.","{dragon} ha toccato l\u2019ornamento magico. Quello ha risposto con educazione.","{dragon} tocou no enfeite m\xe1gico. Ele respondeu educadamente.","{dragon} \u306f\u9b54\u6cd5\u306e\u98fe\u308a\u3092\u53e9\u304d\u307e\u3057\u305f\u3002\u98fe\u308a\u3082\u4e01\u5be7\u306b\u53e9\u304d\u8fd4\u3057\u307e\u3057\u305f\u3002"],t.s)
A.ob=s(["{dragon} sah sich um, nickte einmal und erkl\xe4rte den Raum f\xfcr akzeptabel.","{dragon} mir\xf3 alrededor, asinti\xf3 y declar\xf3 aceptable la habitaci\xf3n.","{dragon} a regard\xe9 autour de lui, hoch\xe9 la t\xeate et d\xe9clar\xe9 la pi\xe8ce acceptable.","{dragon} si \xe8 guardato intorno, ha annuito e dichiarato la stanza accettabile.","{dragon} olhou ao redor, assentiu e declarou o c\xf4modo aceit\xe1vel.","{dragon} \u306f\u5468\u56f2\u3092\u898b\u56de\u3057\u3001\u4e00\u5ea6\u3046\u306a\u305a\u3044\u3066\u3001\u3053\u306e\u90e8\u5c4b\u3092\u5408\u683c\u3068\u3057\u307e\u3057\u305f\u3002"],t.s)
A.Bn=s(["In DragonHaven wartet eine Abenteuerbelohnung.","Hay una recompensa de aventura lista en DragonHaven.","Une r\xe9compense d\u2019aventure vous attend dans DragonHaven.","Una ricompensa dell\u2019avventura \xe8 pronta in DragonHaven.","Uma recompensa de aventura est\xe1 pronta no DragonHaven.","DragonHaven\u3067\u5192\u967a\u306e\u5831\u916c\u3092\u53d7\u3051\u53d6\u308c\u307e\u3059\u3002"],t.s)
A.HR=s(["Etwas darin m\xf6chte im Dachnest schl\xfcpfen.","Algo dentro quiere eclosionar en el Nido de la Azotea.","Quelque chose \xe0 l\u2019int\xe9rieur veut \xe9clore dans le Nid du Toit.","Qualcosa dentro vuole schiudersi nel Nido sul Tetto.","Algo l\xe1 dentro quer chocar no Ninho do Telhado.","\u4e2d\u306b\u3044\u308b\u4f55\u304b\u304c\u5c4b\u4e0a\u306e\u5de3\u3067\u5b75\u5316\u3057\u305f\u304c\u3063\u3066\u3044\u307e\u3059\u3002"],t.s)
A.vA=s(["Dein geheimnisvolles Ei ist bereit","Tu Huevo Misterioso est\xe1 listo","Votre \u0152uf myst\xe9rieux est pr\xeat","Il tuo Uovo misterioso \xe8 pronto","Seu Ovo Misterioso est\xe1 pronto","\u4e0d\u601d\u8b70\u306a\u5375\u306e\u6e96\u5099\u304c\u3067\u304d\u307e\u3057\u305f"],t.s)
A.qr=s(["Schatz enth\xfcllt","Tesoro revelado","Tr\xe9sor r\xe9v\xe9l\xe9","Tesoro svelato","Tesouro revelado","\u5b9d\u7269\u304c\u73fe\u308c\u307e\u3057\u305f"],t.s)
A.oA=s(["Das Schloss \xf6ffnet sich...","La cerradura se est\xe1 abriendo...","La serrure s\u2019ouvre...","La serratura si sta aprendo...","A fechadura est\xe1 abrindo...","\u9375\u304c\u958b\u3044\u3066\u3044\u307e\u3059\u2026"],t.s)
A.xA=s(["Tippe irgendwo, um zur\xfcckzukehren","Toca en cualquier lugar para volver","Touchez n\u2019importe o\xf9 pour revenir","Tocca ovunque per tornare","Toque em qualquer lugar para voltar","\u3069\u3053\u304b\u3092\u30bf\u30c3\u30d7\u3057\u3066\u623b\u308b"],t.s)
A.J0=s(["Eine stille Wiege f\xfcr das n\xe4chste Leben in deiner Sammlung.","Una cuna tranquila para la pr\xf3xima vida de tu colecci\xf3n.","Un berceau paisible pour la prochaine vie de votre collection.","Una culla tranquilla per la prossima vita della tua collezione.","Um ber\xe7o tranquilo para a pr\xf3xima vida da sua cole\xe7\xe3o.","\u30b3\u30ec\u30af\u30b7\u30e7\u30f3\u306b\u52a0\u308f\u308b\u6b21\u306e\u547d\u306e\u305f\u3081\u306e\u9759\u304b\u306a\u63fa\u308a\u304b\u3054\u3002"],t.s)
A.K5=s(["Unter der Schale w\xe4chst ein verborgener Drache.","Un drag\xf3n oculto crece bajo el cascar\xf3n.","Un dragon cach\xe9 grandit sous la coquille.","Un drago nascosto cresce sotto il guscio.","Um drag\xe3o oculto cresce sob a casca.","\u6bbb\u306e\u4e0b\u3067\u4e00\u4f53\u306e\u79d8\u5bc6\u306e\u30c9\u30e9\u30b4\u30f3\u304c\u80b2\u3063\u3066\u3044\u307e\u3059\u3002"],t.s)
A.yS=s(["Enth\xfclle den Drachen","Revela el drag\xf3n","R\xe9v\xe9ler le dragon","Rivela il drago","Revelar o drag\xe3o","\u30c9\u30e9\u30b4\u30f3\u3092\u660e\u3089\u304b\u306b\u3059\u308b"],t.s)
A.rp=s(["In deinem Inventar warten keine geheimnisvollen Eier.","No hay Huevos Misteriosos esperando en tu inventario.","Aucun \u0152uf myst\xe9rieux n\u2019attend dans votre inventaire.","Non ci sono Uova misteriose nel tuo inventario.","N\xe3o h\xe1 Ovos Misteriosos esperando no seu invent\xe1rio.","\u6240\u6301\u54c1\u306b\u5f85\u6a5f\u4e2d\u306e\u4e0d\u601d\u8b70\u306a\u5375\u306f\u3042\u308a\u307e\u305b\u3093\u3002"],t.s)
A.KZ=s(["W\xe4hle ein geheimnisvolles Ei","Elige un Huevo Misterioso","Choisissez un \u0152uf myst\xe9rieux","Scegli un Uovo misterioso","Escolha um Ovo Misterioso","\u4e0d\u601d\u8b70\u306a\u5375\u3092\u9078\u3076"],t.s)
A.nH=s(["Seine Identit\xe4t ist bereits sicher darin verborgen.","Su identidad ya est\xe1 oculta de forma segura en su interior.","Son identit\xe9 est d\xe9j\xe0 bien cach\xe9e \xe0 l\u2019int\xe9rieur.","La sua identit\xe0 \xe8 gi\xe0 nascosta al sicuro al suo interno.","A identidade j\xe1 est\xe1 escondida com seguran\xe7a l\xe1 dentro.","\u305d\u306e\u6b63\u4f53\u306f\u3059\u3067\u306b\u4e2d\u306b\u5927\u5207\u306b\u96a0\u3055\u308c\u3066\u3044\u307e\u3059\u3002"],t.s)
A.pI=s(["Das Nest ist bereits belegt.","El nido ya est\xe1 ocupado.","Le nid est d\xe9j\xe0 occup\xe9.","Il nido \xe8 gi\xe0 occupato.","O ninho j\xe1 est\xe1 ocupado.","\u5de3\u306b\u306f\u3059\u3067\u306b\u5375\u304c\u3042\u308a\u307e\u3059\u3002"],t.s)
A.Ep=s(["Tippe auf das Nest, um ein Ei auszuw\xe4hlen","Toca el nido para elegir un huevo","Touchez le nid pour choisir un \u0153uf","Tocca il nido per scegliere un uovo","Toque no ninho para escolher um ovo","\u5de3\u3092\u30bf\u30c3\u30d7\u3057\u3066\u5375\u3092\u9078\u3076"],t.s)
A.Kb=s(["Tippe einmal auf das Ei, um das Schl\xfcpfen zu beginnen","Toca el huevo una vez para comenzar la eclosi\xf3n","Touchez l\u2019\u0153uf une fois pour lancer l\u2019\xe9closion","Tocca una volta l\u2019uovo per iniziare la schiusa","Toque no ovo uma vez para iniciar a eclos\xe3o","\u5375\u3092\u4e00\u5ea6\u30bf\u30c3\u30d7\u3057\u3066\u5b75\u5316\u3092\u59cb\u3081\u308b"],t.s)
A.FB=s(["Das Ei beginnt zu schl\xfcpfen","El huevo est\xe1 empezando a eclosionar","L\u2019\u0153uf commence \xe0 \xe9clore","L\u2019uovo sta iniziando a schiudersi","O ovo est\xe1 come\xe7ando a eclodir","\u5375\u304c\u5b75\u5316\u3057\u59cb\u3081\u3066\u3044\u307e\u3059"],t.s)
A.rz=s(["Etwas bewegt sich darin...","Algo se mueve dentro...","Quelque chose bouge \xe0 l\u2019int\xe9rieur...","Qualcosa si muove dentro...","Algo est\xe1 se mexendo l\xe1 dentro...","\u4e2d\u3067\u4f55\u304b\u304c\u52d5\u3044\u3066\u3044\u307e\u3059\u2026"],t.s)
A.Bh=s(["Das Nest ist leer","El nido est\xe1 vac\xedo","Le nid est vide","Il nido \xe8 vuoto","O ninho est\xe1 vazio","\u5de3\u306f\u7a7a\u3067\u3059"],t.s)
A.zM=s(["W\xe4hle ein Ei aus deinem Inventar.","Elige un huevo de tu inventario.","Choisissez un \u0153uf dans votre inventaire.","Scegli un uovo dal tuo inventario.","Escolha um ovo do seu invent\xe1rio.","\u6240\u6301\u54c1\u304b\u3089\u5375\u3092\u4e00\u3064\u9078\u3093\u3067\u304f\u3060\u3055\u3044\u3002"],t.s)
A.Ia=s(["Seltene Eier k\xf6nnen in Truhen aus Abenteuern gefunden werden.","Puedes encontrar huevos raros en cofres ganados en Aventuras.","Des \u0153ufs rares peuvent \xeatre trouv\xe9s dans les coffres gagn\xe9s en Aventure.","Puoi trovare uova rare nei forzieri ottenuti nelle Avventure.","Ovos raros podem ser encontrados em ba\xfas ganhos nas Aventuras.","\u5192\u967a\u3067\u7372\u5f97\u3057\u305f\u5b9d\u7bb1\u304b\u3089\u73cd\u3057\u3044\u5375\u304c\u898b\u3064\u304b\u308b\u3053\u3068\u304c\u3042\u308a\u307e\u3059\u3002"],t.s)
A.Ky=s(["Ei ausw\xe4hlen","Elegir un huevo","Choisir un \u0153uf","Scegli un uovo","Escolher um ovo","\u5375\u3092\u9078\u3076"],t.s)
A.vL=s(["Das Ei zieht ins Dachnest. Dein aktiver Drache und der Rest der App bleiben verf\xfcgbar.","El huevo se traslada al Nido de la Azotea. Tu drag\xf3n activo y el resto de la aplicaci\xf3n siguen disponibles.","L\u2019\u0153uf rejoint le Nid du Toit. Votre dragon actif et le reste de l\u2019application restent disponibles.","L\u2019uovo si sposta nel Nido sul Tetto. Il tuo drago attivo e il resto dell\u2019app restano disponibili.","O ovo vai para o Ninho do Telhado. Seu drag\xe3o ativo e o restante do aplicativo continuam dispon\xedveis.","\u5375\u306f\u5c4b\u4e0a\u306e\u5de3\u3078\u79fb\u52d5\u3057\u307e\u3059\u3002\u30a2\u30af\u30c6\u30a3\u30d6\u306a\u30c9\u30e9\u30b4\u30f3\u3068\u30a2\u30d7\u30ea\u306e\u4ed6\u306e\u6a5f\u80fd\u306f\u5f15\u304d\u7d9a\u304d\u5229\u7528\u3067\u304d\u307e\u3059\u3002"],t.s)
A.A2=s(["Jede Form, die du gro\xdfziehst, hinterl\xe4sst ihre Magie auf der Seite.","Cada forma que cr\xedas deja su magia en la p\xe1gina.","Chaque forme que vous \xe9levez laisse sa magie sur la page.","Ogni forma che allevi lascia la sua magia sulla pagina.","Cada forma que voc\xea cria deixa sua magia na p\xe1gina.","\u80b2\u3066\u305f\u3059\u3079\u3066\u306e\u59ff\u304c\u3001\u3053\u306e\u30da\u30fc\u30b8\u306b\u9b54\u6cd5\u3092\u6b8b\u3057\u307e\u3059\u3002"],t.s)
A.tT=s(["Verf\xfcgbar","Disponibles","Disponibles","Disponibili","Dispon\xedveis","\u5229\u7528\u53ef\u80fd"],t.s)
A.Lc=s(["Aktiv","Activas","Actives","Attive","Ativas","\u9032\u884c\u4e2d"],t.s)
A.wh=s(["W\xe4hle einen Pfad. Bring Geschichten, Training und Sch\xe4tze zur\xfcck.","Elige una ruta. Regresa con historias, entrenamiento y tesoros.","Choisissez une voie. Rapportez des histoires, de l\u2019entra\xeenement et des tr\xe9sors.","Scegli un percorso. Torna con storie, allenamento e tesori.","Escolha um caminho. Traga hist\xf3rias, treino e tesouros.","\u9053\u3092\u9078\u3073\u3001\u7269\u8a9e\u3068\u8a13\u7df4\u306e\u6210\u679c\u3068\u5b9d\u7269\u3092\u6301\u3061\u5e30\u308a\u307e\u3057\u3087\u3046\u3002"],t.s)
A.KK=s(["Hier ist gerade kein Pfad verf\xfcgbar.","Ahora mismo no hay ninguna ruta disponible aqu\xed.","Aucune piste n\u2019est disponible ici pour le moment.","Al momento non \xe8 disponibile alcun percorso qui.","Nenhuma trilha est\xe1 dispon\xedvel aqui agora.","\u3053\u3053\u306b\u306f\u73fe\u5728\u5229\u7528\u3067\u304d\u308b\u9053\u304c\u3042\u308a\u307e\u305b\u3093\u3002"],t.s)
A.kA=s(["Mysteri\xf6se Truhe","Cofre misterioso","Coffre myst\xe8re","Forziere misterioso","Ba\xfa misterioso","\u8b0e\u306e\u5b9d\u7bb1"],t.s)
A.zB=s(["Abenteuer starten","Iniciar aventura","Commencer l\u2019aventure","Avvia avventura","Iniciar aventura","\u5192\u967a\u3092\u59cb\u3081\u308b"],t.s)
A.jS=s(["Drachen w\xe4hlen","Elige un drag\xf3n","Choisir un dragon","Scegli un drago","Escolha um drag\xe3o","\u30c9\u30e9\u30b4\u30f3\u3092\u9078\u3076"],t.s)
A.p9=s(["F\xfcr diesen Pfad empfohlen","Recomendados para esta ruta","Recommand\xe9s pour cette voie","Consigliati per questo percorso","Recomendados para este caminho","\u3053\u306e\u9053\u306b\u304a\u3059\u3059\u3081"],t.s)
A.Ds=s(["Andere verf\xfcgbare Drachen","Otros dragones disponibles","Autres dragons disponibles","Altri draghi disponibili","Outros drag\xf5es dispon\xedveis","\u307b\u304b\u306e\u5229\u7528\u53ef\u80fd\u306a\u30c9\u30e9\u30b4\u30f3"],t.s)
A.GQ=s(["Empfohlen","Recomendado","Recommand\xe9","Consigliato","Recomendado","\u304a\u3059\u3059\u3081"],t.s)
A.xZ=s(["Keine Abenteuer sind aktiv","No hay aventuras activas","Aucune aventure n\u2019est active","Nessuna avventura \xe8 attiva","Nenhuma aventura est\xe1 ativa","\u9032\u884c\u4e2d\u306e\u5192\u967a\u306f\u3042\u308a\u307e\u305b\u3093"],t.s)
A.Il=s(["Schicke einen Drachen los und seine Reise erscheint hier.","Env\xeda un drag\xf3n y su viaje aparecer\xe1 aqu\xed.","Envoyez un dragon et son voyage appara\xeetra ici.","Invia un drago e il suo viaggio apparir\xe0 qui.","Envie um drag\xe3o e a jornada dele aparecer\xe1 aqui.","\u30c9\u30e9\u30b4\u30f3\u3092\u9001\u308a\u51fa\u3059\u3068\u3001\u305d\u306e\u65c5\u304c\u3053\u3053\u306b\u8868\u793a\u3055\u308c\u307e\u3059\u3002"],t.s)
A.Fv=s(["Unbekannter Drache","Drag\xf3n desconocido","Dragon inconnu","Drago sconosciuto","Drag\xe3o desconhecido","\u4e0d\u660e\u306a\u30c9\u30e9\u30b4\u30f3"],t.s)
A.vB=s(["Bereit zur R\xfcckkehr","Listo para volver","Pr\xeat \xe0 revenir","Pronto a tornare","Pronto para voltar","\u5e30\u9084\u53ef\u80fd"],t.s)
A.nm=s(["Drache","Drag\xf3n","Dragon","Drago","Drag\xe3o","\u30c9\u30e9\u30b4\u30f3"],t.s)
A.Fx=s(["Status","Estado","Statut","Stato","Status","\u72b6\u614b"],t.s)
A.FZ=s(["R\xfcckkehr in","Regresa en","Retour dans","Ritorno tra","Retorno em","\u5e30\u9084\u307e\u3067"],t.s)
A.xv=s(["Drachenerfahrung","Experiencia del drag\xf3n","Exp\xe9rience du dragon","Esperienza del drago","Experi\xeancia do drag\xe3o","\u30c9\u30e9\u30b4\u30f3\u7d4c\u9a13\u5024"],t.s)
A.mM=s(["Trainingsbelohnung","Recompensa de entrenamiento","R\xe9compense d\u2019entra\xeenement","Ricompensa di allenamento","Recompensa de treino","\u8a13\u7df4\u5831\u916c"],t.s)
A.Jr=s(["Schatz","Tesoro","Tr\xe9sor","Tesoro","Tesouro","\u5b9d\u7269"],t.s)
A.rm=s(["Eine versiegelte Truhe","Un cofre sellado","Un coffre scell\xe9","Un forziere sigillato","Um ba\xfa selado","\u5c01\u5370\u3055\u308c\u305f\u5b9d\u7bb11\u500b"],t.s)
A.u4=s(["Belohnungen abholen","Recoger recompensas","R\xe9cup\xe9rer les r\xe9compenses","Ritira ricompense","Coletar recompensas","\u5831\u916c\u3092\u53d7\u3051\u53d6\u308b"],t.s)
A.Jj=s(["Kurze Abenteuer","Aventuras cortas","Aventures courtes","Avventure brevi","Aventuras curtas","\u77ed\u3044\u5192\u967a"],t.s)
A.rd=s(["Lange Abenteuer","Aventuras largas","Aventures longues","Avventure lunghe","Aventuras longas","\u9577\u3044\u5192\u967a"],t.s)
A.BO=s(["Gruppenabenteuer","Aventuras de grupo","Aventures de groupe","Avventure di gruppo","Aventuras em grupo","\u30b0\u30eb\u30fc\u30d7\u5192\u967a"],t.s)
A.Kn=s(["Besondere Abenteuer","Aventuras especiales","Aventures sp\xe9ciales","Avventure speciali","Aventuras especiais","\u7279\u5225\u306a\u5192\u967a"],t.s)
A.qg=s(["Kleine Ausfl\xfcge","Peque\xf1as salidas","Petites sorties","Piccole uscite","Pequenos passeios","\u5c0f\u3055\u306a\u304a\u51fa\u304b\u3051"],t.s)
A.v_=s(["Schnelle Routen","Rutas r\xe1pidas","Itin\xe9raires rapides","Percorsi rapidi","Rotas r\xe1pidas","\u77ed\u3044\u30eb\u30fc\u30c8"],t.s)
A.Li=s(["Geduldige Reisen","Viajes pacientes","Voyages patients","Viaggi pazienti","Jornadas pacientes","\u6c17\u9577\u306a\u65c5"],t.s)
A.Kl=s(["Gemeinsame Entdeckungen","Descubrimientos compartidos","D\xe9couvertes partag\xe9es","Scoperte condivise","Descobertas compartilhadas","\u5171\u6709\u306e\u767a\u898b"],t.s)
A.Ag=s(["Seltene Pfade","Rutas raras","Pistes rares","Percorsi rari","Trilhas raras","\u73cd\u3057\u3044\u9053"],t.s)
A.wx=s(["Aktualisierungsregeln","Reglas de renovaci\xf3n","R\xe8gles de renouvellement","Regole di rinnovo","Regras de renova\xe7\xe3o","\u66f4\u65b0\u30eb\u30fc\u30eb"],t.s)
A.yA=s(["Schlie\xdfen","Cerrar","Fermer","Chiudi","Fechar","\u9589\u3058\u308b"],t.s)
A.u8=s(["Erscheinungsbild","Apariencia","Apparence","Aspetto","Apar\xeancia","\u5916\u898b"],t.s)
A.IP=s(["Einstellungen","Preferencias","Pr\xe9f\xe9rences","Preferenze","Prefer\xeancias","\u74b0\u5883\u8a2d\u5b9a"],t.s)
A.JA=s(["Keine abgeschlossenen Abenteuer","No hay aventuras completadas","Aucune aventure termin\xe9e","Nessuna avventura completata","Nenhuma aventura conclu\xedda","\u5b8c\u4e86\u3057\u305f\u5192\u967a\u306f\u3042\u308a\u307e\u305b\u3093"],t.s)
A.JI=s(["Beendete Reisen warten hier, bis du ihre Belohnungen abholst.","Los viajes terminados esperan aqu\xed hasta que recojas sus recompensas.","Les voyages termin\xe9s attendent ici que vous r\xe9cup\xe9riez leurs r\xe9compenses.","I viaggi conclusi restano qui finch\xe9 non ritiri le ricompense.","As jornadas conclu\xeddas ficam aqui at\xe9 voc\xea coletar as recompensas.","\u7d42\u308f\u3063\u305f\u65c5\u306f\u5831\u916c\u3092\u53d7\u3051\u53d6\u308b\u307e\u3067\u3053\u3053\u3067\u5f85\u6a5f\u3057\u307e\u3059\u3002"],t.s)
A.k5=s(["Bis zu drei Routen warten. Alle 15 Minuten wird ein freier Platz aufgef\xfcllt. Sichtbare Routen bleiben, bis du sie startest oder verwirfst; sie werden nicht automatisch ersetzt.","Esperan hasta tres rutas. Cada 15 minutos se rellena un espacio libre. Las rutas visibles permanecen hasta que las inicies o descartes; no se sustituyen autom\xe1ticamente.","Jusqu\u2019\xe0 trois itin\xe9raires attendent. Une place libre est remplie toutes les 15 minutes. Les itin\xe9raires visibles restent jusqu\u2019\xe0 leur lancement ou rejet ; ils ne sont pas remplac\xe9s automatiquement.","Sono disponibili fino a tre percorsi. Ogni 15 minuti viene riempito uno spazio libero. I percorsi visibili restano finch\xe9 non li avvii o scarti; non vengono sostituiti automaticamente.","At\xe9 tr\xeas rotas ficam dispon\xedveis. Uma vaga livre \xe9 preenchida a cada 15 minutos. As rotas vis\xedveis permanecem at\xe9 serem iniciadas ou descartadas; n\xe3o s\xe3o substitu\xeddas automaticamente.","\u6700\u59273\u3064\u306e\u30eb\u30fc\u30c8\u304c\u5f85\u6a5f\u3057\u307e\u3059\u3002\u7a7a\u304d\u67a0\u306f15\u5206\u3054\u3068\u306b1\u3064\u88dc\u5145\u3055\u308c\u307e\u3059\u3002\u8868\u793a\u4e2d\u306e\u30eb\u30fc\u30c8\u306f\u958b\u59cb\u307e\u305f\u306f\u7834\u68c4\u3059\u308b\u307e\u3067\u6b8b\u308a\u3001\u81ea\u52d5\u3067\u306f\u5165\u308c\u66ff\u308f\u308a\u307e\u305b\u3093\u3002"],t.s)
A.u0=s(["Bis zu drei Routen warten. Jede Stunde wird ein freier Platz aufgef\xfcllt. Sichtbare Routen bleiben, bis du sie startest oder verwirfst; sie werden nicht automatisch ersetzt.","Esperan hasta tres rutas. Cada hora se rellena un espacio libre. Las rutas visibles permanecen hasta que las inicies o descartes; no se sustituyen autom\xe1ticamente.","Jusqu\u2019\xe0 trois itin\xe9raires attendent. Une place libre est remplie chaque heure. Les itin\xe9raires visibles restent jusqu\u2019\xe0 leur lancement ou rejet ; ils ne sont pas remplac\xe9s automatiquement.","Sono disponibili fino a tre percorsi. Ogni ora viene riempito uno spazio libero. I percorsi visibili restano finch\xe9 non li avvii o scarti; non vengono sostituiti automaticamente.","At\xe9 tr\xeas rotas ficam dispon\xedveis. Uma vaga livre \xe9 preenchida a cada hora. As rotas vis\xedveis permanecem at\xe9 serem iniciadas ou descartadas; n\xe3o s\xe3o substitu\xeddas automaticamente.","\u6700\u59273\u3064\u306e\u30eb\u30fc\u30c8\u304c\u5f85\u6a5f\u3057\u307e\u3059\u3002\u7a7a\u304d\u67a0\u306f1\u6642\u9593\u3054\u3068\u306b1\u3064\u88dc\u5145\u3055\u308c\u307e\u3059\u3002\u8868\u793a\u4e2d\u306e\u30eb\u30fc\u30c8\u306f\u958b\u59cb\u307e\u305f\u306f\u7834\u68c4\u3059\u308b\u307e\u3067\u6b8b\u308a\u3001\u81ea\u52d5\u3067\u306f\u5165\u308c\u66ff\u308f\u308a\u307e\u305b\u3093\u3002"],t.s)
A.E0=s(["Bis zu drei Routen warten. Freie Pl\xe4tze werden um lokale Mitternacht aufgef\xfcllt. Sichtbare Routen bleiben, bis du sie startest oder verwirfst; sie werden nicht automatisch ersetzt.","Esperan hasta tres rutas. Los espacios libres se rellenan a medianoche local. Las rutas visibles permanecen hasta que las inicies o descartes; no se sustituyen autom\xe1ticamente.","Jusqu\u2019\xe0 trois itin\xe9raires attendent. Les places libres sont remplies \xe0 minuit, heure locale. Les itin\xe9raires visibles restent jusqu\u2019\xe0 leur lancement ou rejet ; ils ne sont pas remplac\xe9s automatiquement.","Sono disponibili fino a tre percorsi. Gli spazi liberi vengono riempiti alla mezzanotte locale. I percorsi visibili restano finch\xe9 non li avvii o scarti; non vengono sostituiti automaticamente.","At\xe9 tr\xeas rotas ficam dispon\xedveis. As vagas livres s\xe3o preenchidas \xe0 meia-noite local. As rotas vis\xedveis permanecem at\xe9 serem iniciadas ou descartadas; n\xe3o s\xe3o substitu\xeddas automaticamente.","\u6700\u59273\u3064\u306e\u30eb\u30fc\u30c8\u304c\u5f85\u6a5f\u3057\u307e\u3059\u3002\u7a7a\u304d\u67a0\u306f\u73fe\u5730\u6642\u9593\u306e\u6df1\u591c0\u6642\u306b\u88dc\u5145\u3055\u308c\u307e\u3059\u3002\u8868\u793a\u4e2d\u306e\u30eb\u30fc\u30c8\u306f\u958b\u59cb\u307e\u305f\u306f\u7834\u68c4\u3059\u308b\u307e\u3067\u6b8b\u308a\u3001\u81ea\u52d5\u3067\u306f\u5165\u308c\u66ff\u308f\u308a\u307e\u305b\u3093\u3002"],t.s)
A.DZ=s(["Alle H\xfcter sehen dieselbe w\xf6chentliche Route. Sie wechselt automatisch jeden Sonntag um 12:00 Uhr in Europe/Amsterdam. Eine bereits gestartete Gruppe beendet die Reise immer und beh\xe4lt ihre Belohnung.","Todos los cuidadores ven la misma ruta semanal. Cambia autom\xe1ticamente cada domingo a las 12:00 en Europe/Amsterdam. Un grupo que ya empez\xf3 siempre termina y conserva su recompensa.","Tous les gardiens voient le m\xeame itin\xe9raire hebdomadaire. Il change automatiquement chaque dimanche \xe0 12 h dans Europe/Amsterdam. Un groupe d\xe9j\xe0 parti termine toujours et conserve sa r\xe9compense.","Tutti i custodi vedono lo stesso percorso settimanale. Cambia automaticamente ogni domenica alle 12:00 in Europe/Amsterdam. Un gruppo gi\xe0 partito conclude sempre il viaggio e conserva la ricompensa.","Todos os guardi\xf5es veem a mesma rota semanal. Ela muda automaticamente todo domingo \xe0s 12:00 em Europe/Amsterdam. Um grupo que j\xe1 come\xe7ou sempre termina e mant\xe9m a recompensa.","\u3059\u3079\u3066\u306e\u30ad\u30fc\u30d1\u30fc\u306b\u540c\u3058\u9031\u9593\u30eb\u30fc\u30c8\u304c\u8868\u793a\u3055\u308c\u307e\u3059\u3002Europe/Amsterdam\u306e\u6bce\u9031\u65e5\u66dc12:00\u306b\u81ea\u52d5\u66f4\u65b0\u3055\u308c\u307e\u3059\u3002\u51fa\u767a\u6e08\u307f\u306e\u30b0\u30eb\u30fc\u30d7\u306f\u5fc5\u305a\u5b8c\u8d70\u3057\u3001\u5831\u916c\u3082\u4fdd\u6301\u3055\u308c\u307e\u3059\u3002"],t.s)
A.tE=s(["Spezialrouten erscheinen nur w\xe4hrend bestimmter Ereignisse. Sie k\xf6nnen automatisch ablaufen oder wechseln; ihre Karte wird nur w\xe4hrend der Verf\xfcgbarkeit angezeigt.","Las rutas especiales solo aparecen durante ciertos eventos. Pueden caducar o cambiar autom\xe1ticamente; su tarjeta solo se muestra mientras est\xe9n disponibles.","Les itin\xe9raires sp\xe9ciaux n\u2019apparaissent que pendant certains \xe9v\xe9nements. Ils peuvent expirer ou changer automatiquement ; leur carte n\u2019est visible que pendant leur disponibilit\xe9.","I percorsi speciali appaiono solo durante determinati eventi. Possono scadere o cambiare automaticamente; la loro scheda \xe8 visibile solo mentre sono disponibili.","Rotas especiais aparecem apenas durante certos eventos. Elas podem expirar ou mudar automaticamente; o cart\xe3o s\xf3 aparece enquanto est\xe3o dispon\xedveis.","\u7279\u5225\u30eb\u30fc\u30c8\u306f\u7279\u5b9a\u306e\u30a4\u30d9\u30f3\u30c8\u4e2d\u306b\u306e\u307f\u8868\u793a\u3055\u308c\u307e\u3059\u3002\u81ea\u52d5\u3067\u671f\u9650\u5207\u308c\u307e\u305f\u306f\u5909\u66f4\u3055\u308c\u308b\u3053\u3068\u304c\u3042\u308a\u3001\u5229\u7528\u53ef\u80fd\u306a\u9593\u3060\u3051\u30ab\u30fc\u30c9\u304c\u8868\u793a\u3055\u308c\u307e\u3059\u3002"],t.s)
A.lz=s(["Winzige Ausfl\xfcge, schnelles Training und Holzkisten.","Peque\xf1as salidas, entrenamiento r\xe1pido y cofres de madera.","Petites sorties, entra\xeenement rapide et coffres en bois.","Piccole uscite, allenamento rapido e forzieri di legno.","Pequenos passeios, treino r\xe1pido e ba\xfas de madeira.","\u5c0f\u3055\u306a\u304a\u51fa\u304b\u3051\u3001\u624b\u8efd\u306a\u8a13\u7df4\u3001\u305d\u3057\u3066\u6728\u306e\u5b9d\u7bb1\u3002"],t.s)
A.r_=s(["Schnelle Routen, die sich im Laufe des Tages erneuern.","Rutas r\xe1pidas que se renuevan durante el d\xeda.","Des itin\xe9raires rapides renouvel\xe9s au fil de la journ\xe9e.","Percorsi rapidi che si aggiornano durante il giorno.","Rotas r\xe1pidas que se renovam ao longo do dia.","\u4e00\u65e5\u3092\u901a\u3057\u3066\u66f4\u65b0\u3055\u308c\u308b\u77ed\u3044\u30eb\u30fc\u30c8\u3067\u3059\u3002"],t.s)
A.u1=s(["Geduldige Reisen mit reicheren Ertr\xe4gen.","Viajes pacientes con mejores recompensas.","Des voyages patients aux gains plus riches.","Viaggi pazienti con ricompense pi\xf9 ricche.","Jornadas pacientes com retornos melhores.","\u6642\u9593\u3092\u304b\u3051\u308b\u3076\u3093\u3001\u5b9f\u308a\u8c4a\u304b\u306a\u65c5\u3067\u3059\u3002"],t.s)
A.rW=s(["Gemeinsame Entdeckungen f\xfcr verbundene H\xfcter.","Descubrimientos compartidos para cuidadores conectados.","Des d\xe9couvertes partag\xe9es pour les gardiens connect\xe9s.","Scoperte condivise per custodi collegati.","Descobertas compartilhadas para guardi\xf5es conectados.","\u3064\u306a\u304c\u3063\u305f\u30ad\u30fc\u30d1\u30fc\u305f\u3061\u3067\u6311\u3080\u5171\u540c\u767a\u898b\u3067\u3059\u3002"],t.s)
A.Jw=s(["Seltene Pfade, die nur zu besonderen Momenten erscheinen.","Rutas raras que solo aparecen en momentos especiales.","Des pistes rares qui n\u2019apparaissent qu\u2019\xe0 des moments particuliers.","Percorsi rari che appaiono solo in momenti speciali.","Trilhas raras que s\xf3 aparecem em momentos especiais.","\u7279\u5225\u306a\u77ac\u9593\u306b\u3060\u3051\u73fe\u308c\u308b\u73cd\u3057\u3044\u9053\u3067\u3059\u3002"],t.s)
A.kb=s(["St\xe4rke","Fuerza","Puissance","Potenza","For\xe7a","\u529b"],t.s)
A.zW=s(["Arkana","Arcanos","Arcanes","Arcano","Arcana","\u79d8\u8853"],t.s)
A.Cl=s(["Geist","Esp\xedritu","Esprit","Spirito","Esp\xedrito","\u7cbe\u795e"],t.s)
A.vV=s(["F\xfcr dieses Abenteuer ist kein Drache verf\xfcgbar.","No hay ning\xfan drag\xf3n disponible para esta aventura.","Aucun dragon n\u2019est disponible pour cette aventure.","Nessun drago \xe8 disponibile per questa avventura.","Nenhum drag\xe3o est\xe1 dispon\xedvel para esta aventura.","\u3053\u306e\u5192\u967a\u306b\u53c2\u52a0\u3067\u304d\u308b\u30c9\u30e9\u30b4\u30f3\u304c\u3044\u307e\u305b\u3093\u3002"],t.s)
A.DB=s(["Unterwegs im Turm","Paseando por la Torre","Se prom\xe8ne dans la Tour","Gira per la Torre","Passeando pela Torre","\u5854\u3092\u6563\u6b69\u4e2d"],t.s)
A.oQ=s(["Ruht au\xdferhalb der R\xe4ume","Descansa fuera de escena","Se repose hors sc\xe8ne","Riposa fuori scena","Descansando fora de cena","\u753b\u9762\u5916\u3067\u4f11\u61a9\u4e2d"],t.s)
A.kQ=s(["Freies Herumlaufen im Turm","Paseo libre por la Torre","D\xe9placement libre dans la Tour","Libero movimento nella Torre","Livre circula\xe7\xe3o na Torre","\u5854\u5185\u3092\u81ea\u7531\u306b\u6b69\u304f"],t.s)
A.qD=s(["Dieser Drache kann in R\xe4umen erscheinen und umherlaufen.","Este drag\xf3n puede aparecer y pasear por las habitaciones.","Ce dragon peut appara\xeetre et se promener dans les pi\xe8ces.","Questo drago pu\xf2 apparire e girare per le stanze.","Este drag\xe3o pode aparecer e passear pelos c\xf4modos.","\u3053\u306e\u30c9\u30e9\u30b4\u30f3\u306f\u90e8\u5c4b\u306b\u73fe\u308c\u3066\u6b69\u304d\u56de\u308c\u307e\u3059\u3002"],t.s)
A.CJ=s(["Herauszoomen","Alejar","D\xe9zoomer","Riduci zoom","Diminuir zoom","\u30ba\u30fc\u30e0\u30a2\u30a6\u30c8"],t.s)
A.CP=s(["Die Drachen haben gem\xfctliche Pl\xe4tze auf anderen Etagen gefunden.","Los dragones encontraron lugares acogedores en otros pisos.","Les dragons ont trouv\xe9 des endroits confortables aux autres \xe9tages.","I draghi hanno trovato posti accoglienti sugli altri piani.","Os drag\xf5es encontraram lugares aconchegantes em outros andares.","\u30c9\u30e9\u30b4\u30f3\u305f\u3061\u306f\u5225\u306e\u968e\u3067\u5c45\u5fc3\u5730\u306e\u3088\u3044\u5834\u6240\u3092\u898b\u3064\u3051\u307e\u3057\u305f\u3002"],t.s)
A.np=s(["Baue eine weitere Etage, bevor du diesen Raum leerst.","Construye otro piso antes de despejar esta habitaci\xf3n.","Construisez un autre \xe9tage avant de vider cette pi\xe8ce.","Costruisci un altro piano prima di liberare questa stanza.","Construa outro andar antes de esvaziar este c\xf4modo.","\u3053\u306e\u90e8\u5c4b\u304b\u3089\u30c9\u30e9\u30b4\u30f3\u3092\u79fb\u3059\u524d\u306b\u3001\u5225\u306e\u968e\u3092\u5efa\u3066\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.JH=s(["Dekorieren beenden","Terminar de decorar","Terminer la d\xe9coration","Termina decorazione","Terminar decora\xe7\xe3o","\u6a21\u69d8\u66ff\u3048\u3092\u7d42\u3048\u308b"],t.s)
A.Gj=s(["Drachen umquartieren","Mover dragones","D\xe9placer les dragons","Sposta draghi","Mover drag\xf5es","\u30c9\u30e9\u30b4\u30f3\u3092\u79fb\u52d5"],t.s)
A.yR=s(["TIPPE, UM DEINEN FAVORITEN ZU LENKEN","TOCA PARA GUIAR A TU FAVORITO","TOUCHEZ POUR GUIDER VOTRE FAVORI","TOCCA PER GUIDARE IL TUO PREFERITO","TOQUE PARA GUIAR SEU FAVORITO","\u30bf\u30c3\u30d7\u3057\u3066\u304a\u6c17\u306b\u5165\u308a\u3092\u5c0e\u304f"],t.s)
A.pb=s(["TIPPE, UM DEINEN FAVORITEN ZU RUFEN","TOCA PARA LLAMAR A TU FAVORITO","TOUCHEZ POUR APPELER VOTRE FAVORI","TOCCA PER CHIAMARE IL TUO PREFERITO","TOQUE PARA CHAMAR SEU FAVORITO","\u30bf\u30c3\u30d7\u3057\u3066\u304a\u6c17\u306b\u5165\u308a\u3092\u547c\u3076"],t.s)
A.mj=s(["Drachentyp","Tipo de drag\xf3n","Type de dragon","Tipo di drago","Tipo de drag\xe3o","\u30c9\u30e9\u30b4\u30f3\u306e\u7a2e\u985e"],t.s)
A.yT=s(["Reifestufe","Madurez","Maturit\xe9","Maturit\xe0","Maturidade","\u6210\u9577\u6bb5\u968e"],t.s)
A.Ei=s(["Erfahrung","Experiencia","Exp\xe9rience","Esperienza","Experi\xeancia","\u7d4c\u9a13\u5024"],t.s)
A.v8=s(["Level","Nivel","Niveau","Livello","N\xedvel","\u30ec\u30d9\u30eb"],t.s)
A.ui=s(["In den Turm einladen","Invitar a la Torre","Inviter dans la Tour","Invita nella Torre","Convidar para a Torre","\u5854\u306b\u62db\u5f85\u3059\u308b"],t.s)
A.nl=s(["Der Turm ist voll. Baue eine weitere Etage oder deaktiviere einen anderen umherziehenden Drachen.","La Torre est\xe1 llena. Construye otro piso o desactiva otro drag\xf3n que deambula.","La Tour est pleine. Construisez un autre \xe9tage ou d\xe9sactivez un autre dragon en libert\xe9.","La Torre \xe8 piena. Costruisci un altro piano o disattiva un altro drago in giro.","A Torre est\xe1 cheia. Construa outro andar ou desative outro drag\xe3o que circula.","\u5854\u304c\u6e80\u54e1\u3067\u3059\u3002\u968e\u3092\u5897\u3084\u3059\u304b\u3001\u5225\u306e\u30c9\u30e9\u30b4\u30f3\u306e\u5de1\u56de\u3092\u89e3\u9664\u3057\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.yF=s(["Dauer","Duraci\xf3n","Dur\xe9e","Durata","Dura\xe7\xe3o","\u6240\u8981\u6642\u9593"],t.s)
A.m2=s(["verbundene H\xfcter","cuidadores conectados","gardiens connect\xe9s","custodi collegati","guardi\xf5es conectados","\u3064\u306a\u304c\u3063\u3066\u3044\u308b\u30ad\u30fc\u30d1\u30fc"],t.s)
A.Jd=s(["Expertisentraining","Entrenamiento de pericia","Entra\xeenement d\u2019expertise","Allenamento competenza","Treino de especialidade","\u5c02\u9580\u6280\u80fd\u30c8\u30ec\u30fc\u30cb\u30f3\u30b0"],t.s)
A.nP=s(["Expertisen","Pericias","Expertises","Competenze","Especialidades","\u5c02\u9580\u6280\u80fd"],t.s)
A.oI=s(["M\xf6gliche Truhen","Cofres posibles","Coffres possibles","Forzieri possibili","Ba\xfas poss\xedveis","\u5165\u624b\u53ef\u80fd\u306a\u5b9d\u7bb1"],t.s)
A.t6=s(["H\xfcter-Anforderung","Requisito de cuidadores","Condition de gardiens","Requisito dei custodi","Requisito de guardi\xf5es","\u30ad\u30fc\u30d1\u30fc\u6761\u4ef6"],t.s)
A.xc=s(["pr\xe4gt eine St\xe4rke-Aszension","moldea una Ascensi\xf3n de Fuerza","fa\xe7onne une Ascension de Puissance","plasma un\u2019Ascensione di Potenza","molda uma Ascens\xe3o de For\xe7a","\u529b\u306e\u30a2\u30bb\u30f3\u30b7\u30e7\u30f3\u3092\u5f62\u4f5c\u308b"],t.s)
A.jP=s(["pr\xe4gt eine Arkana-Aszension","moldea una Ascensi\xf3n Arcana","fa\xe7onne une Ascension des Arcanes","plasma un\u2019Ascensione Arcana","molda uma Ascens\xe3o Arcana","\u79d8\u8853\u306e\u30a2\u30bb\u30f3\u30b7\u30e7\u30f3\u3092\u5f62\u4f5c\u308b"],t.s)
A.l6=s(["pr\xe4gt eine Geist-Aszension","moldea una Ascensi\xf3n de Esp\xedritu","fa\xe7onne une Ascension d\u2019Esprit","plasma un\u2019Ascensione di Spirito","molda uma Ascens\xe3o de Esp\xedrito","\u7cbe\u795e\u306e\u30a2\u30bb\u30f3\u30b7\u30e7\u30f3\u3092\u5f62\u4f5c\u308b"],t.s)
A.JX=s(["Rechtschaffen","Legal","Loyal","Legale","Leal","\u79e9\u5e8f"],t.s)
A.K2=s(["Neutral","Neutral","Neutre","Neutrale","Neutro","\u4e2d\u7acb"],t.s)
A.Ct=s(["Chaotisch","Ca\xf3tico","Chaotique","Caotico","Ca\xf3tico","\u6df7\u6c8c"],t.s)
A.m3=s(["Gut","Bueno","Bon","Buono","Bom","\u5584"],t.s)
A.mD=s(["B\xf6se","Malvado","Mauvais","Malvagio","Mau","\u60aa"],t.s)
A.uy=s(["Moralische Natur","Naturaleza moral","Nature morale","Natura morale","Natureza moral","\u9053\u5fb3\u7684\u6027\u8cea"],t.s)
A.xb=s(["Ordnungsnatur","Naturaleza de orden","Nature d\u2019ordre","Natura dell\u2019ordine","Natureza de ordem","\u79e9\u5e8f\u7684\u6027\u8cea"],t.s)
A.Fw=s(["Pers\xf6nlichkeit","Personalidad","Personnalit\xe9","Personalit\xe0","Personalidade","\u6027\u683c"],t.s)
A.Kv=s(["Unentdeckt","Sin descubrir","Non d\xe9couvert","Non scoperto","N\xe3o descoberto","\u672a\u767a\u898b"],t.s)
A.H5=s(["H\xf6chste Stufe erreicht","Nivel m\xe1ximo alcanzado","Niveau maximal atteint","Livello massimo raggiunto","N\xedvel m\xe1ximo alcan\xe7ado","\u6700\u9ad8\u30ec\u30d9\u30eb\u306b\u5230\u9054"],t.s)
A.Ap=s(["bis zur n\xe4chsten Stufe","para el siguiente nivel","avant le niveau suivant","al livello successivo","para o pr\xf3ximo n\xedvel","\u6b21\u306e\u30ec\u30d9\u30eb\u307e\u3067"],t.s)
A.Fp=s(["Letzte Evolution erreicht","Evoluci\xf3n final alcanzada","\xc9volution finale atteinte","Evoluzione finale raggiunta","Evolu\xe7\xe3o final alcan\xe7ada","\u6700\u7d42\u9032\u5316\u306b\u5230\u9054"],t.s)
A.r2=s(["N\xe4chste Evolution","Pr\xf3xima evoluci\xf3n","Prochaine \xe9volution","Prossima evoluzione","Pr\xf3xima evolu\xe7\xe3o","\u6b21\u306e\u9032\u5316"],t.s)
A.ta=s(["Relikte","Reliquias","Reliques","Reliquie","Rel\xedquias","\u79d8\u5b9d"],t.s)
A.Cj=s(["Noch keine Relikte","A\xfan no hay Reliquias","Pas encore de Reliques","Ancora nessuna Reliquia","Ainda n\xe3o h\xe1 Rel\xedquias","\u79d8\u5b9d\u306f\u307e\u3060\u3042\u308a\u307e\u305b\u3093"],t.s)
A.th=s(["Brutzeit nach dem Einsetzen","Incubaci\xf3n tras colocarlo","Incubation apr\xe8s installation","Incubazione dopo il posizionamento","Incuba\xe7\xe3o ap\xf3s colocar no ninho","\u5de3\u306b\u7f6e\u3044\u305f\u5f8c\u306e\u5b75\u5316\u6642\u9593"],t.s)
A.wa=s(["Dieses Relikt benutzen?","\xbfUsar esta Reliquia?","Utiliser cette Relique ?","Usare questa Reliquia?","Usar esta Rel\xedquia?","\u3053\u306e\u79d8\u5b9d\u3092\u4f7f\u3044\u307e\u3059\u304b\uff1f"],t.s)
A.l1=s(["Dies ist ein Verbrauchsgegenstand. Er verschwindet, nachdem er einen Drachen enth\xfcllt hat. Fortfahren?","Este objeto es consumible. Desaparece tras revelar un drag\xf3n. \xbfContinuar?","Cet objet est consommable. Il dispara\xeet apr\xe8s avoir r\xe9v\xe9l\xe9 un dragon. Continuer ?","Questo oggetto \xe8 consumabile. Scompare dopo aver rivelato un drago. Continuare?","Este item \xe9 consum\xedvel. Ele desaparece ap\xf3s revelar um drag\xe3o. Continuar?","\u3053\u308c\u306f\u6d88\u8017\u30a2\u30a4\u30c6\u30e0\u3067\u3059\u3002\u30c9\u30e9\u30b4\u30f3\u30921\u4f53\u660e\u304b\u3059\u3068\u6d88\u3048\u307e\u3059\u3002\u7d9a\u3051\u307e\u3059\u304b\uff1f"],t.s)
A.xp=s(["Weiter","Continuar","Continuer","Continua","Continuar","\u7d9a\u3051\u308b"],t.s)
A.Av=s(["Belohnungen","Recompensas","R\xe9compenses","Ricompense","Recompensas","\u5831\u916c"],t.s)
A.pe=s(["1 Gold-, Drachen- oder Mythische Truhe","1 Cofre Dorado, de Drag\xf3n o M\xedtico","1 Coffre d\u2019or, de Dragon ou Mythique","1 Forziere d\u2019Oro, del Drago o Mitico","1 Ba\xfa de Ouro, de Drag\xe3o ou M\xedtico","\u30b4\u30fc\u30eb\u30c9\u3001\u30c9\u30e9\u30b4\u30f3\u3001\u30df\u30b7\u30ab\u30eb\u5b9d\u7bb1\u306e\u3044\u305a\u308c\u304b1\u500b"],t.s)
A.JJ=s(["1 zuf\xe4lliges Relikt","1 reliquia aleatoria","1 relique al\xe9atoire","1 reliquia casuale","1 rel\xedquia aleat\xf3ria","\u30e9\u30f3\u30c0\u30e0\u306a\u79d8\u5b9d1\u500b"],t.s)
A.vS=s(["Tippe zum \xd6ffnen auf die Truhe","Toca el cofre para abrirlo","Touchez le coffre pour l\u2019ouvrir","Tocca il forziere per aprirlo","Toque no ba\xfa para abrir","\u5b9d\u7bb1\u3092\u30bf\u30c3\u30d7\u3057\u3066\u958b\u304f"],t.s)
A.or=s(["Musik enth\xfcllt","M\xfasica revelada","Musique r\xe9v\xe9l\xe9e","Musica rivelata","M\xfasica revelada","\u697d\u66f2\u3092\u7372\u5f97"],t.s)
A.oE=s(["Abholen","Recoger","R\xe9cup\xe9rer","Riscatta","Coletar","\u53d7\u3051\u53d6\u308b"],t.s)
A.tr=s(["Aus dem Turm entfernen","Retirar de la Torre","Retirer de la Tour","Rimuovi dalla Torre","Remover da Torre","\u5854\u304b\u3089\u5916\u3059"],t.s)
A.nJ=s(["Uralte Magie erwacht","La magia antigua despierta","Une magie ancienne s\u2019\xe9veille","La magia antica si risveglia","A magia antiga desperta","\u53e4\u306e\u9b54\u6cd5\u304c\u76ee\u899a\u3081\u308b"],t.s)
A.EO=s(["Versiegelter Schatz","Tesoro sellado","Tr\xe9sor scell\xe9","Tesoro sigillato","Tesouro selado","\u5c01\u5370\u3055\u308c\u305f\u5b9d\u7269"],t.s)
A.wc=s(["Truhe \xf6ffnet sich","El cofre se abre","Ouverture du coffre","Apertura del forziere","Ba\xfa abrindo","\u5b9d\u7bb1\u3092\u958b\u5c01\u4e2d"],t.s)
A.vT=s(["Diese au\xdfergew\xf6hnlich seltenen Sch\xe4tze k\xf6nnen in Goldtruhen und selteneren Truhen erscheinen.","Estos tesoros excepcionalmente raros pueden aparecer en Cofres Dorados y cofres m\xe1s raros.","Ces tr\xe9sors exceptionnellement rares peuvent appara\xeetre dans les Coffres d\u2019or et les coffres plus rares.","Questi tesori eccezionalmente rari possono apparire nei Forzieri d\u2019Oro e in quelli pi\xf9 rari.","Esses tesouros excepcionalmente raros podem aparecer em Ba\xfas de Ouro e ba\xfas mais raros.","\u3053\u306e\u6975\u3081\u3066\u5e0c\u5c11\u306a\u5b9d\u7269\u306f\u3001\u30b4\u30fc\u30eb\u30c9\u5b9d\u7bb1\u4ee5\u4e0a\u306e\u5b9d\u7bb1\u304b\u3089\u51fa\u73fe\u3057\u307e\u3059\u3002"],t.s)
A.Fd=s(["W\xe4hle mit Bedacht: Jedes Relikt enth\xfcllt einen Drachen und wird verbraucht.","Elige con cuidado: cada reliquia revela un drag\xf3n y se consume.","Choisissez avec soin : chaque relique r\xe9v\xe8le un dragon et est consomm\xe9e.","Scegli con cura: ogni reliquia rivela un drago e viene consumata.","Escolha com cuidado: cada rel\xedquia revela um drag\xe3o e \xe9 consumida.","\u614e\u91cd\u306b\u9078\u3093\u3067\u304f\u3060\u3055\u3044\u3002\u79d8\u5b9d\u306f1\u4f53\u306e\u30c9\u30e9\u30b4\u30f3\u3092\u660e\u304b\u3057\u3001\u4f7f\u7528\u3059\u308b\u3068\u6d88\u8cbb\u3055\u308c\u307e\u3059\u3002"],t.s)
A.kq=s(["Benutzen","Usar","Utiliser","Usa","Usar","\u4f7f\u3046"],t.s)
A.HV=s(["Bereits enth\xfcllt","Ya revelado","D\xe9j\xe0 r\xe9v\xe9l\xe9","Gi\xe0 rivelato","J\xe1 revelado","\u78ba\u8a8d\u6e08\u307f"],t.s)
A.rJ=s(["Geheimnis noch verborgen","Secreto a\xfan oculto","Secret encore cach\xe9","Segreto ancora nascosto","Segredo ainda oculto","\u79d8\u5bc6\u306f\u307e\u3060\u96a0\u3055\u308c\u3066\u3044\u307e\u3059"],t.s)
A.Fo=s(["Merken","Recordar esto","S\u2019en souvenir","Ricordalo","Lembrar disso","\u899a\u3048\u3066\u304a\u304f"],t.s)
A.oG=s(["Moralprisma","Prisma Moral","Prisme Moral","Prisma Morale","Prisma Moral","\u9053\u5fb3\u306e\u30d7\u30ea\u30ba\u30e0"],t.s)
A.kC=s(["Ordnungskompass","Br\xfajula del Orden","Boussole de l\u2019Ordre","Bussola dell\u2019Ordine","B\xfassola da Ordem","\u79e9\u5e8f\u306e\u7f85\u91dd\u76e4"],t.s)
A.qO=s(["Seelenspiegel","Espejo del Alma","Miroir de l\u2019\xc2me","Specchio dell\u2019Anima","Espelho da Alma","\u9b42\u306e\u93e1"],t.s)
A.vQ=s(["Enth\xfcllt, ob ein Drache zu Gut, Neutral oder B\xf6se neigt.","Revela si un drag\xf3n se inclina hacia el Bien, la Neutralidad o el Mal.","R\xe9v\xe8le si un dragon penche vers le Bien, la Neutralit\xe9 ou le Mal.","Rivela se un drago tende al Bene, alla Neutralit\xe0 o al Male.","Revela se um drag\xe3o tende ao Bem, \xe0 Neutralidade ou ao Mal.","1\u4f53\u306e\u30c9\u30e9\u30b4\u30f3\u304c\u5584\u30fb\u4e2d\u7acb\u30fb\u60aa\u306e\u3069\u308c\u306b\u50be\u304f\u304b\u3092\u660e\u304b\u3057\u307e\u3059\u3002"],t.s)
A.Gk=s(["Enth\xfcllt, ob ein Drache rechtschaffen, neutral oder chaotisch ist.","Revela si un drag\xf3n es Legal, Neutral o Ca\xf3tico.","R\xe9v\xe8le si un dragon est Loyal, Neutre ou Chaotique.","Rivela se un drago \xe8 Legale, Neutrale o Caotico.","Revela se um drag\xe3o \xe9 Leal, Neutro ou Ca\xf3tico.","1\u4f53\u306e\u30c9\u30e9\u30b4\u30f3\u304c\u79e9\u5e8f\u30fb\u4e2d\u7acb\u30fb\u6df7\u6c8c\u306e\u3069\u308c\u304b\u3092\u660e\u304b\u3057\u307e\u3059\u3002"],t.s)
A.I9=s(["Enth\xfcllt die verborgenen Pers\xf6nlichkeitsmerkmale eines Drachen.","Revela los rasgos de personalidad ocultos de un drag\xf3n.","R\xe9v\xe8le les traits de personnalit\xe9 cach\xe9s d\u2019un dragon.","Rivela i tratti nascosti della personalit\xe0 di un drago.","Revela os tra\xe7os de personalidade ocultos de um drag\xe3o.","1\u4f53\u306e\u30c9\u30e9\u30b4\u30f3\u306b\u96a0\u3055\u308c\u305f\u6027\u683c\u7279\u6027\u3092\u660e\u304b\u3057\u307e\u3059\u3002"],t.s)
A.JF=s(["Schl\xe4frig","Dormil\xf3n","Somnolent","Sonnolento","Sonolento","\u7720\u305f\u304c\u308a"],t.s)
A.DX=s(["Neugierig","Entrometido","Fouineur","Ficcanaso","Intrometido","\u8a6e\u7d22\u597d\u304d"],t.s)
A.IU=s(["Sammler","Acaparador","Collectionneur","Accumulatore","Acumulador","\u305f\u3081\u8fbc\u307f\u5c4b"],t.s)
A.G2=s(["Dramak\xf6nig","Reina del drama","Roi du drame","Re del dramma","Rei do drama","\u30c9\u30e9\u30de\u738b"],t.s)
A.kt=s(["B\xfccherwurm","Rat\xf3n de biblioteca","Rat de biblioth\xe8que","Topo di biblioteca","Rato de biblioteca","\u672c\u306e\u866b"],t.s)
A.J1=s(["Futterdieb","Ladr\xf3n de comida","Voleur de nourriture","Ladro di cibo","Ladr\xe3o de comida","\u98df\u3044\u3057\u3093\u574a\u6ce5\u68d2"],t.s)
A.Gh=s(["H\xf6henangst","Miedo a las alturas","Peur du vide","Paura dell\u2019altezza","Medo de altura","\u9ad8\u6240\u6050\u6016\u75c7"],t.s)
A.G1=s(["Rastlos","Inquieto","Agit\xe9","Irrequieto","Inquieto","\u843d\u3061\u7740\u304d\u304c\u306a\u3044"],t.s)
A.Dt=s(["Sch\xfcchtern","T\xedmido","Timide","Timido","T\xedmido","\u6065\u305a\u304b\u3057\u304c\u308a"],t.s)
A.kB=s(["Angeber","Presumido","Frimeur","Esibizionista","Exibido","\u76ee\u7acb\u3061\u305f\u304c\u308a"],t.s)
A.CU=s(["Tollpatschig","Torpe","Maladroit","Goffo","Desajeitado","\u4e0d\u5668\u7528"],t.s)
A.DR=s(["Ordnungsfanatiker","Fan\xe1tico del orden","Maniaque du rangement","Maniaco dell\u2019ordine","Fan\xe1tico por organiza\xe7\xe3o","\u304d\u308c\u3044\u597d\u304d"],t.s)
A.H_=s(["Unordentlich","Desordenado","D\xe9sordonn\xe9","Disordinato","Bagunceiro","\u6563\u3089\u304b\u3057\u5c4b"],t.s)
A.lG=s(["Stur","Terco","T\xeatu","Testardo","Teimoso","\u9811\u56fa"],t.s)
A.m_=s(["Kuschelig","Cari\xf1oso","C\xe2lin","Coccolone","Carinhoso","\u7518\u3048\u3093\u574a"],t.s)
A.t2=s(["M\xfcrrisch","Gru\xf1\xf3n","Grognon","Brontolone","Rabugento","\u4e0d\u6a5f\u5acc"],t.s)
A.EX=s(["Leicht ablenkbar","Se distrae f\xe1cilmente","Facilement distrait","Si distrae facilmente","Distrai-se facilmente","\u6c17\u304c\u6563\u308a\u3084\u3059\u3044"],t.s)
A.Dz=s(["Nachteule","Noct\xe1mbulo","Oiseau de nuit","Nottambulo","Not\xedvago","\u591c\u66f4\u304b\u3057"],t.s)
A.Cx=s(["Fr\xfchaufsteher","Madrugador","L\xe8ve-t\xf4t","Mattiniero","Madrugador","\u65e9\u8d77\u304d"],t.s)
A.L_=s(["Planschfreund","Amante de las salpicaduras","Fan d\u2019\xe9claboussures","Amante degli spruzzi","Amante de respingos","\u6c34\u904a\u3073\u597d\u304d"],t.s)
A.v0=s(["Feuerteufel","Pir\xf3mano","Pyromane","Piromane","Incendi\xe1rio","\u706b\u904a\u3073\u597d\u304d"],t.s)
A.yH=s(["Aufmerksamkeitssucher","Busca atenci\xf3n","En qu\xeate d\u2019attention","In cerca di attenzioni","Busca aten\xe7\xe3o","\u304b\u307e\u3063\u3066\u3061\u3083\u3093"],t.s)
A.q8=s(["Schreckhaft","Se asusta f\xe1cilmente","Facile \xe0 effrayer","Si spaventa facilmente","Assusta-se facilmente","\u9a5a\u304d\u3084\u3059\u3044"],t.s)
A.t_=s(["Tutorial","Tutorial","Tutoriel","Tutorial","Tutorial","\u30c1\u30e5\u30fc\u30c8\u30ea\u30a2\u30eb"],t.s)
A.ti=s(["Willkommen in DragonHaven","Te damos la bienvenida a DragonHaven","Bienvenue dans DragonHaven","Benvenuto a DragonHaven","Boas-vindas a DragonHaven","DragonHaven\u3078\u3088\u3046\u3053\u305d"],t.s)
A.k9=s(["zeigt dir alles. Du kannst jetzt \xfcberspringen und diese F\xfchrung sp\xe4ter \xfcber das Dreipunkt-Men\xfc wiederholen.","te ense\xf1ar\xe1 todo. Puedes omitirlo ahora y repetir este recorrido m\xe1s tarde desde el men\xfa de tres puntos.","va te guider. Tu peux passer maintenant et relancer cette visite plus tard depuis le menu \xe0 trois points.","ti far\xe0 da guida. Puoi saltare ora e ripetere il tour pi\xf9 tardi dal menu con i tre puntini.","vai guiar voc\xea. Voc\xea pode pular agora e repetir este passeio depois pelo menu de tr\xeas pontos.","\u304c\u6848\u5185\u3057\u307e\u3059\u3002\u4eca\u306f\u30b9\u30ad\u30c3\u30d7\u3057\u3066\u3082\u3001\u5f8c\u3067\u4e09\u70b9\u30e1\u30cb\u30e5\u30fc\u304b\u3089\u3082\u3046\u4e00\u5ea6\u59cb\u3081\u3089\u308c\u307e\u3059\u3002"],t.s)
A.Cn=s(["Online-Freunde","Amigos en l\xednea","Amis en ligne","Amici online","Amigos online","\u30aa\u30f3\u30e9\u30a4\u30f3\u306e\u30d5\u30ec\u30f3\u30c9"],t.s)
A.ub=s(["Erstelle ein per E-Mail best\xe4tigtes Online-Konto und f\xfcge andere H\xfcter \xfcber ihre H\xfcter-ID hinzu. Freunde k\xf6nnen gegenseitig ihre \xf6ffentlichen Profile \xf6ffnen und Portr\xe4ts, Titel, Lieblingsdrachen, entdeckte Formen und Pr\xfcfungsrekorde sehen.","Crea una cuenta en l\xednea verificada por correo electr\xf3nico y a\xf1ade a otros guardianes mediante su ID. Los amigos pueden abrir sus perfiles p\xfablicos y ver retratos, t\xedtulos, dragones favoritos, formas descubiertas y r\xe9cords de Pruebas.","Cr\xe9e un compte en ligne v\xe9rifi\xe9 par e-mail, puis ajoute d\u2019autres gardiens gr\xe2ce \xe0 leur identifiant. Les amis peuvent consulter leurs profils publics, portraits, titres, dragons favoris, formes d\xe9couvertes et records d\u2019\xc9preuves.","Crea un account online verificato via e-mail e aggiungi altri custodi tramite il loro ID. Gli amici possono aprire i profili pubblici e vedere ritratti, titoli, draghi preferiti, forme scoperte e record delle Prove.","Crie uma conta online verificada por e-mail e adicione outros guardi\xf5es pelo ID. Amigos podem abrir os perfis p\xfablicos uns dos outros e ver retratos, t\xedtulos, drag\xf5es favoritos, formas descobertas e recordes das Provas.","\u30e1\u30fc\u30eb\u8a8d\u8a3c\u6e08\u307f\u306e\u30aa\u30f3\u30e9\u30a4\u30f3\u30a2\u30ab\u30a6\u30f3\u30c8\u3092\u4f5c\u6210\u3057\u3001Keeper ID\u3067\u307b\u304b\u306e\u30ad\u30fc\u30d1\u30fc\u3092\u8ffd\u52a0\u3067\u304d\u307e\u3059\u3002\u30d5\u30ec\u30f3\u30c9\u540c\u58eb\u3067\u516c\u958b\u30d7\u30ed\u30d5\u30a3\u30fc\u30eb\u3001\u30dd\u30fc\u30c8\u30ec\u30fc\u30c8\u3001\u79f0\u53f7\u3001\u304a\u6c17\u306b\u5165\u308a\u306e\u30c9\u30e9\u30b4\u30f3\u3001\u767a\u898b\u6e08\u307f\u5f62\u614b\u3001\u8a66\u7df4\u8a18\u9332\u3092\u78ba\u8a8d\u3067\u304d\u307e\u3059\u3002"],t.s)
A.Ck=s(["Gemeinsam handeln und reisen","Intercambia y viaja en compa\xf1\xeda","\xc9changer et voyager ensemble","Scambia e viaggia insieme","Troque e viaje em grupo","\u4e00\u7dd2\u306b\u4ea4\u63db\u3057\u3066\u5192\u967a"],t.s)
A.yB=s(["Bei einem Freund kannst du einen gesch\xfctzten Eins-zu-eins-Tausch anbieten: Eier, Truhen und Relikte bleiben reserviert, bis der Tausch abgeschlossen ist oder abl\xe4uft. Angemeldete Freunde k\xf6nnen ihre Drachen au\xdferdem gemeinsam f\xfcr asynchrone Gruppenabenteuer anmelden.","Desde el perfil de un amigo puedes ofrecer un intercambio individual protegido: los huevos, cofres y Reliquias quedan reservados hasta que termine o caduque. Los amigos conectados tambi\xe9n pueden inscribir dragones juntos en Aventuras grupales as\xedncronas.","Depuis le profil d\u2019un ami, tu peux proposer un \xe9change individuel s\xe9curis\xe9 : \u0153ufs, coffres et Reliques restent r\xe9serv\xe9s jusqu\u2019\xe0 sa conclusion ou son expiration. Les amis connect\xe9s peuvent aussi inscrire ensemble leurs dragons \xe0 des Aventures de groupe asynchrones.","Dal profilo di un amico puoi proporre uno scambio uno a uno protetto: uova, scrigni e Reliquie restano riservati finch\xe9 lo scambio non termina o scade. Gli amici connessi possono anche iscrivere insieme i draghi alle Avventure di gruppo asincrone.","No perfil de um amigo, voc\xea pode oferecer uma troca individual protegida: ovos, ba\xfas e Rel\xedquias ficam reservados at\xe9 a conclus\xe3o ou expira\xe7\xe3o. Amigos conectados tamb\xe9m podem inscrever drag\xf5es juntos em Aventuras em grupo ass\xedncronas.","\u30d5\u30ec\u30f3\u30c9\u306b\u306f\u4fdd\u8b77\u3055\u308c\u305f1\u5bfe1\u306e\u4ea4\u63db\u3092\u63d0\u6848\u3067\u304d\u307e\u3059\u3002\u5375\u3001\u5b9d\u7bb1\u3001\u30ec\u30ea\u30c3\u30af\u306f\u4ea4\u63db\u304c\u5b8c\u4e86\u307e\u305f\u306f\u671f\u9650\u5207\u308c\u306b\u306a\u308b\u307e\u3067\u78ba\u4fdd\u3055\u308c\u307e\u3059\u3002\u30ed\u30b0\u30a4\u30f3\u4e2d\u306e\u30d5\u30ec\u30f3\u30c9\u540c\u58eb\u3067\u3001\u975e\u540c\u671f\u306e\u30b0\u30eb\u30fc\u30d7\u5192\u967a\u306b\u30c9\u30e9\u30b4\u30f3\u3092\u53c2\u52a0\u3055\u305b\u308b\u3053\u3068\u3082\u3067\u304d\u307e\u3059\u3002"],t.s)
A.Bs=s(["Mini-Abenteuer dauern Minuten, kurze Abenteuer Stunden und lange Abenteuer Tage. Die passende Expertise eines Drachen verk\xfcrzt den Timer. Gruppenabenteuer ben\xf6tigen 2\u20134 angemeldete Freunde und starten automatisch, sobald ihre Anforderungen erf\xfcllt sind.","Las Aventuras mini duran minutos, las cortas horas y las largas d\xedas. La Pericia correspondiente del drag\xf3n reduce el tiempo. Las Aventuras grupales necesitan entre 2 y 4 amigos conectados y comienzan autom\xe1ticamente cuando se cumplen los requisitos.","Les mini-Aventures durent quelques minutes, les Aventures courtes plusieurs heures et les longues plusieurs jours. L\u2019Expertise correspondante du dragon r\xe9duit le temps. Les Aventures de groupe n\xe9cessitent 2 \xe0 4 amis connect\xe9s et commencent automatiquement lorsque leurs conditions sont remplies.","Le Avventure mini durano minuti, quelle brevi ore e quelle lunghe giorni. La Competenza corrispondente del drago riduce il tempo. Le Avventure di gruppo richiedono 2\u20134 amici connessi e iniziano automaticamente quando i requisiti sono soddisfatti.","Aventuras mini duram minutos, Aventuras curtas duram horas e Aventuras longas duram dias. A Especialidade correspondente do drag\xe3o reduz o tempo. Aventuras em grupo precisam de 2\u20134 amigos conectados e come\xe7am automaticamente quando os requisitos s\xe3o atendidos.","\u30df\u30cb\u5192\u967a\u306f\u6570\u5206\u3001\u30b7\u30e7\u30fc\u30c8\u5192\u967a\u306f\u6570\u6642\u9593\u3001\u30ed\u30f3\u30b0\u5192\u967a\u306f\u6570\u65e5\u304b\u304b\u308a\u307e\u3059\u3002\u30c9\u30e9\u30b4\u30f3\u306e\u5bfe\u5fdc\u3059\u308b\u5c02\u9580\u6280\u80fd\u3067\u6642\u9593\u304c\u77ed\u7e2e\u3055\u308c\u307e\u3059\u3002\u30b0\u30eb\u30fc\u30d7\u5192\u967a\u306b\u306f\u30ed\u30b0\u30a4\u30f3\u4e2d\u306e\u30d5\u30ec\u30f3\u30c9\u304c2\uff5e4\u4eba\u5fc5\u8981\u3067\u3001\u6761\u4ef6\u3092\u6e80\u305f\u3059\u3068\u81ea\u52d5\u3067\u59cb\u307e\u308a\u307e\u3059\u3002"],t.s)
A.ch=s(["Pr\xfcfungen","Pruebas","\xc9preuves","Prove","Provas","\u8a66\u7df4"],t.s)
A.Fs=s(["Pr\xfcfungen sind geschicklichkeitsbasierte Minispiele und werden alle 15 Minuten bis zu maximal drei erg\xe4nzt. H\xf6hlenflug trainiert Geist, Ruinenbrecher St\xe4rke und Runenweber Arkana; deine Leistung bestimmt Rang, Belohnungen und pers\xf6nlichen Rekord.","Las Pruebas son minijuegos de habilidad y se reponen cada 15 minutos, hasta un m\xe1ximo de tres. Vuelo cavernario entrena Esp\xedritu, Romperruinas Poder y Tejerrunas Arcana; tu rendimiento determina el rango, las recompensas y el r\xe9cord personal.","Les \xc9preuves sont des mini-jeux d\u2019adresse renouvel\xe9s toutes les 15 minutes, jusqu\u2019\xe0 trois en attente. Vol cavernicole entra\xeene l\u2019Esprit, Briseur de ruines la Puissance et Tisseur de runes les Arcanes ; ta performance d\xe9termine le rang, les r\xe9compenses et le record personnel.","Le Prove sono minigiochi di abilit\xe0 e si ricaricano ogni 15 minuti, fino a un massimo di tre. Volo nella caverna allena lo Spirito, Spezzarovine la Potenza e Tessirune l\u2019Arcano; la prestazione determina grado, ricompense e record personale.","As Provas s\xe3o minijogos de habilidade e s\xe3o renovadas a cada 15 minutos, at\xe9 tr\xeas dispon\xedveis. Voo na caverna treina Esp\xedrito, Quebra-ru\xednas Poder e Tecel\xe3o de runas Arcano; seu desempenho determina classifica\xe7\xe3o, recompensas e recorde pessoal.","\u8a66\u7df4\u306f\u8155\u524d\u3092\u8a66\u3059\u30df\u30cb\u30b2\u30fc\u30e0\u3067\u300115\u5206\u3054\u3068\u306b\u6700\u59273\u3064\u307e\u3067\u88dc\u5145\u3055\u308c\u307e\u3059\u3002\u6d1e\u7a9f\u98db\u884c\u306f\u7cbe\u795e\u3001\u30eb\u30a4\u30f3\u30d6\u30ec\u30a4\u30ab\u30fc\u306f\u529b\u3001\u30eb\u30fc\u30f3\u30a6\u30a3\u30fc\u30d0\u30fc\u306f\u795e\u79d8\u3092\u935b\u3048\u3001\u6210\u7e3e\u306b\u3088\u3063\u3066\u30e9\u30f3\u30af\u3001\u5831\u916c\u3001\u81ea\u5df1\u30d9\u30b9\u30c8\u304c\u6c7a\u307e\u308a\u307e\u3059\u3002"],t.s)
A.qZ=s(["Nutze die beiden gro\xdfen Symbole oben rechts: Meine Drachen \xf6ffnet deine vollst\xe4ndige Drachensammlung, w\xe4hrend das Draconomicon jede entdeckte Drachenform zeigt. Darunter kannst du Turmgeschosse bauen, besuchen und dekorieren.","Usa los dos iconos grandes de arriba a la derecha: Mis dragones abre tu colecci\xf3n completa y el Draconomicon muestra cada forma de drag\xf3n descubierta. Debajo puedes construir, visitar y decorar pisos de la Torre.","Utilise les deux grandes ic\xf4nes en haut \xe0 droite : Mes dragons ouvre ta collection compl\xe8te, tandis que le Draconomicon montre chaque forme de dragon d\xe9couverte. En dessous, tu peux construire, visiter et d\xe9corer les \xe9tages de la Tour.","Usa le due grandi icone in alto a destra: I miei draghi apre la collezione completa, mentre il Draconomicon mostra ogni forma di drago scoperta. Sotto puoi costruire, visitare e decorare i piani della Torre.","Use os dois \xedcones grandes no canto superior direito: Meus drag\xf5es abre sua cole\xe7\xe3o completa, enquanto o Draconomicon mostra cada forma de drag\xe3o descoberta. Abaixo deles voc\xea pode construir, visitar e decorar andares da Torre.","\u53f3\u4e0a\u306e2\u3064\u306e\u5927\u304d\u306a\u30a2\u30a4\u30b3\u30f3\u3092\u4f7f\u3044\u307e\u3059\u3002\u300c\u30de\u30a4\u30c9\u30e9\u30b4\u30f3\u300d\u3067\u306f\u5168\u30c9\u30e9\u30b4\u30f3\u3092\u78ba\u8a8d\u3067\u304d\u3001\u30c9\u30e9\u30b3\u30ce\u30df\u30b3\u30f3\u306b\u306f\u767a\u898b\u6e08\u307f\u306e\u30c9\u30e9\u30b4\u30f3\u5f62\u614b\u304c\u8868\u793a\u3055\u308c\u307e\u3059\u3002\u305d\u306e\u4e0b\u3067\u306f\u5854\u306e\u968e\u3092\u5efa\u7bc9\u3001\u8a2a\u554f\u3001\u88c5\u98fe\u3067\u304d\u307e\u3059\u3002"],t.s)
A.um=s(["Hier werden Eier, unge\xf6ffnete Truhen, M\xf6bel und Relikte aufbewahrt. \xd6ffne Truhen, beginne die Brut eines Eis oder pr\xfcfe deinen Besitz; f\xfcr einen Tausch reservierte Gegenst\xe4nde bleiben bis zur Freigabe unbenutzbar.","Aqu\xed se guardan huevos, cofres sin abrir, muebles y Reliquias. Abre cofres, inicia la incubaci\xf3n de un huevo o revisa lo que tienes; los objetos reservados para un intercambio no pueden usarse hasta quedar libres.","Tes \u0153ufs, coffres non ouverts, meubles et Reliques sont conserv\xe9s ici. Ouvre des coffres, lance l\u2019incubation d\u2019un \u0153uf ou consulte tes possessions ; les objets r\xe9serv\xe9s pour un \xe9change restent inutilisables jusqu\u2019\xe0 leur lib\xe9ration.","Qui vengono conservati uova, scrigni non aperti, mobili e Reliquie. Apri gli scrigni, avvia l\u2019incubazione di un uovo o controlla ci\xf2 che possiedi; gli oggetti riservati per uno scambio non possono essere usati finch\xe9 non vengono liberati.","Ovos, ba\xfas fechados, m\xf3veis e Rel\xedquias ficam guardados aqui. Abra ba\xfas, inicie a incuba\xe7\xe3o de um ovo ou confira o que possui; itens reservados para uma troca n\xe3o podem ser usados at\xe9 serem liberados.","\u5375\u3001\u672a\u958b\u5c01\u306e\u5b9d\u7bb1\u3001\u5bb6\u5177\u3001\u30ec\u30ea\u30c3\u30af\u306f\u3053\u3053\u306b\u4fdd\u7ba1\u3055\u308c\u307e\u3059\u3002\u5b9d\u7bb1\u3092\u958b\u3051\u305f\u308a\u3001\u5375\u306e\u5b75\u5316\u3092\u59cb\u3081\u305f\u308a\u3001\u6240\u6301\u54c1\u3092\u78ba\u8a8d\u3067\u304d\u307e\u3059\u3002\u4ea4\u63db\u7528\u306b\u78ba\u4fdd\u3055\u308c\u305f\u30a2\u30a4\u30c6\u30e0\u306f\u89e3\u653e\u3055\u308c\u308b\u307e\u3067\u4f7f\u3048\u307e\u305b\u3093\u3002"],t.s)
A.ns=s(["Kaufe mit M\xfcnzen oder Edelsteinen M\xf6bel f\xfcr deinen Turm. Titeltruhen kosten M\xfcnzen und schalten Kontotitel frei; Portr\xe4ttruhen kosten Edelsteine und schalten Profilportr\xe4ts frei. Beide \xf6ffnest du im Inventar.","Compra muebles para tu Torre con monedas o gemas. Los Cofres de t\xedtulos cuestan monedas y desbloquean t\xedtulos de cuenta; los Cofres de retratos cuestan gemas y desbloquean retratos de perfil. Abre ambos desde el Inventario.","Ach\xe8te des meubles pour ta Tour avec des pi\xe8ces ou des gemmes. Les Coffres de titres co\xfbtent des pi\xe8ces et d\xe9bloquent des titres de compte ; les Coffres de portraits co\xfbtent des gemmes et d\xe9bloquent des portraits de profil. Ouvre-les depuis l\u2019Inventaire.","Acquista mobili per la Torre con monete o gemme. Gli Scrigni dei titoli costano monete e sbloccano titoli dell\u2019account; gli Scrigni dei ritratti costano gemme e sbloccano ritratti del profilo. Aprili dall\u2019Inventario.","Compre m\xf3veis para a Torre com moedas ou gemas. Ba\xfas de t\xedtulos custam moedas e desbloqueiam t\xedtulos da conta; Ba\xfas de retratos custam gemas e desbloqueiam retratos de perfil. Abra ambos no Invent\xe1rio.","\u30b3\u30a4\u30f3\u3084\u30b8\u30a7\u30e0\u3067\u5854\u306e\u5bb6\u5177\u3092\u8cfc\u5165\u3067\u304d\u307e\u3059\u3002\u79f0\u53f7\u306e\u5b9d\u7bb1\u306f\u30b3\u30a4\u30f3\u3067\u30a2\u30ab\u30a6\u30f3\u30c8\u79f0\u53f7\u3092\u3001\u30dd\u30fc\u30c8\u30ec\u30fc\u30c8\u306e\u5b9d\u7bb1\u306f\u30b8\u30a7\u30e0\u3067\u30d7\u30ed\u30d5\u30a3\u30fc\u30eb\u753b\u50cf\u3092\u89e3\u653e\u3057\u307e\u3059\u3002\u3069\u3061\u3089\u3082\u30a4\u30f3\u30d9\u30f3\u30c8\u30ea\u304b\u3089\u958b\u3051\u307e\u3059\u3002"],t.s)
A.Kx=s(["Das Dreipunkt-Men\xfc","El men\xfa de tres puntos","Le menu \xe0 trois points","Il menu con tre puntini","O menu de tr\xeas pontos","3\u70b9\u30e1\u30cb\u30e5\u30fc"],t.s)
A.Bg=s(["Tippe oben rechts auf die drei Punkte, um die Kontoinformationen zu \xf6ffnen. Dort kannst du Portr\xe4t und Titel \xe4ndern sowie Benachrichtigungen und Audio verwalten. Dasselbe Men\xfc \xf6ffnet Sprache, Erfolge und erneut dieses Tutorial.","Toca los tres puntos de arriba a la derecha para abrir la informaci\xf3n de la cuenta, donde puedes cambiar el retrato y el t\xedtulo y gestionar Notificaciones y Audio. El mismo men\xfa abre Idioma, Logros y este Tutorial de nuevo.","Touche les trois points en haut \xe0 droite pour ouvrir les informations du compte, o\xf9 tu peux modifier portrait et titre et g\xe9rer Notifications et Audio. Le m\xeame menu ouvre aussi Langue, Succ\xe8s et ce Tutoriel.","Tocca i tre puntini in alto a destra per aprire le informazioni dell\u2019account, dove puoi cambiare ritratto e titolo e gestire Notifiche e Audio. Lo stesso menu apre Lingua, Obiettivi e di nuovo questo Tutorial.","Toque nos tr\xeas pontos no canto superior direito para abrir as informa\xe7\xf5es da conta, onde voc\xea pode mudar retrato e t\xedtulo e gerenciar Notifica\xe7\xf5es e \xc1udio. O mesmo menu abre Idioma, Conquistas e este Tutorial novamente.","\u53f3\u4e0a\u306e3\u70b9\u3092\u30bf\u30c3\u30d7\u3059\u308b\u3068\u30a2\u30ab\u30a6\u30f3\u30c8\u60c5\u5831\u304c\u958b\u304d\u3001\u30dd\u30fc\u30c8\u30ec\u30fc\u30c8\u3068\u79f0\u53f7\u306e\u5909\u66f4\u3001\u901a\u77e5\u3068\u30aa\u30fc\u30c7\u30a3\u30aa\u306e\u7ba1\u7406\u304c\u3067\u304d\u307e\u3059\u3002\u540c\u3058\u30e1\u30cb\u30e5\u30fc\u304b\u3089\u8a00\u8a9e\u3001\u5b9f\u7e3e\u3001\u3053\u306e\u30c1\u30e5\u30fc\u30c8\u30ea\u30a2\u30eb\u3082\u958b\u3051\u307e\u3059\u3002"],t.s)
A.yy=s(["Dies wird der Treffpunkt f\xfcr verbundene Drachenh\xfcter, Besuche und faire Tauschgesch\xe4fte.","Este ser\xe1 el punto de encuentro para Guardianes de Dragones conectados, visitas e intercambios justos.","Ce sera le lieu de rencontre des Gardiens de dragons li\xe9s, des visites et des \xe9changes \xe9quitables.","Questo sar\xe0 il punto d\u2019incontro per Custodi di draghi collegati, visite e scambi equi.","Este ser\xe1 o ponto de encontro para Guardi\xf5es de Drag\xf5es conectados, visitas e trocas justas.","\u3053\u3053\u306f\u9023\u643a\u3057\u305f\u30c9\u30e9\u30b4\u30f3\u30ad\u30fc\u30d1\u30fc\u3068\u306e\u8a2a\u554f\u3084\u516c\u6b63\u306a\u4ea4\u63db\u306e\u5834\u306b\u306a\u308a\u307e\u3059\u3002"],t.s)
A.FJ=s(["Schicke einen verf\xfcgbaren Drachen auf ein Abenteuer, um XP, Expertisen und Schatztruhen zu verdienen.","Env\xeda un drag\xf3n disponible a una Aventura para ganar XP, Pericias y cofres del tesoro.","Envoie un dragon disponible en Aventure pour gagner de l\u2019XP, des Expertises et des coffres au tr\xe9sor.","Invia un drago disponibile in un\u2019Avventura per ottenere XP, Competenze e scrigni.","Envie um drag\xe3o dispon\xedvel em uma Aventura para ganhar XP, Especialidades e ba\xfas do tesouro.","\u7a7a\u3044\u3066\u3044\u308b\u30c9\u30e9\u30b4\u30f3\u3092\u5192\u967a\u306b\u9001\u308a\u3001XP\u3001\u5c02\u9580\u6280\u80fd\u3001\u5b9d\u7bb1\u3092\u7372\u5f97\u3057\u307e\u3057\u3087\u3046\u3002"],t.s)
A.Fn=s(["Baue einzigartige R\xe4ume, dekoriere sie und w\xe4hle, welche Drachen durch ihr Zuhause streifen d\xfcrfen.","Construye habitaciones \xfanicas, dec\xf3ralas y elige qu\xe9 dragones pueden recorrer su hogar.","Construis des pi\xe8ces uniques, d\xe9core-les et choisis quels dragons peuvent parcourir leur foyer.","Costruisci stanze uniche, decorale e scegli quali draghi possono girare nella loro casa.","Construa c\xf4modos \xfanicos, decore-os e escolha quais drag\xf5es podem passear pelo lar.","\u500b\u6027\u7684\u306a\u90e8\u5c4b\u3092\u5efa\u3066\u3066\u98fe\u308a\u3001\u5bb6\u306e\u4e2d\u3092\u6b69\u304d\u56de\u308c\u308b\u30c9\u30e9\u30b4\u30f3\u3092\u9078\u3073\u307e\u3057\u3087\u3046\u3002"],t.s)
A.y8=s(["Deine Eier, unge\xf6ffneten Truhen, M\xf6bel und verbrauchbaren Relikte werden hier sicher aufbewahrt.","Aqu\xed se guardan de forma segura tus huevos, cofres sin abrir, muebles y Reliquias consumibles.","Tes \u0153ufs, coffres non ouverts, meubles et Reliques consommables sont conserv\xe9s ici.","Qui sono custoditi uova, scrigni non aperti, mobili e Reliquie consumabili.","Seus ovos, ba\xfas fechados, m\xf3veis e Rel\xedquias consum\xedveis ficam guardados aqui.","\u5375\u3001\u672a\u958b\u5c01\u306e\u5b9d\u7bb1\u3001\u5bb6\u5177\u3001\u6d88\u8cbb\u578b\u306e\u30ec\u30ea\u30c3\u30af\u306f\u3053\u3053\u306b\u5b89\u5168\u306b\u4fdd\u7ba1\u3055\u308c\u307e\u3059\u3002"],t.s)
A.GO=s(["Gib M\xfcnzen oder Edelsteine f\xfcr M\xf6bel aus, die jeden Turmraum wohnlich machen.","Gasta monedas o gemas en muebles que hagan acogedora cada sala de la Torre.","D\xe9pense des pi\xe8ces ou des gemmes en meubles pour rendre chaque pi\xe8ce de la Tour accueillante.","Spendi monete o gemme in mobili che rendano accogliente ogni stanza della Torre.","Gaste moedas ou gemas em m\xf3veis que deixem cada c\xf4modo da Torre aconchegante.","\u30b3\u30a4\u30f3\u3084\u30b8\u30a7\u30e0\u3067\u5bb6\u5177\u3092\u8cb7\u3044\u3001\u5854\u306e\u3069\u306e\u90e8\u5c4b\u3082\u5c45\u5fc3\u5730\u306e\u3088\u3044\u5bb6\u306b\u3057\u307e\u3057\u3087\u3046\u3002"],t.s)
A.I8=s(["Tutorial \xfcberspringen","Omitir tutorial","Passer le tutoriel","Salta tutorial","Pular tutorial","\u30c1\u30e5\u30fc\u30c8\u30ea\u30a2\u30eb\u3092\u30b9\u30ad\u30c3\u30d7"],t.s)
A.HA=s(["Weiter","Siguiente","Suivant","Avanti","Pr\xf3ximo","\u6b21\u3078"],t.s)
A.wU=s(["Nichts mehr zu enth\xfcllen","No queda nada por revelar","Plus rien \xe0 r\xe9v\xe9ler","Non resta nulla da rivelare","N\xe3o h\xe1 mais nada para revelar","\u660e\u304b\u305b\u308b\u79d8\u5bc6\u306f\u3042\u308a\u307e\u305b\u3093"],t.s)
A.w2=s(["Dieses Relikt hat sein Geheimnis bereits f\xfcr jeden deiner Drachen enth\xfcllt. Br\xfcte einen weiteren Drachen aus oder sammle ihn, um es zu verwenden.","Esta Reliquia ya revel\xf3 su secreto para todos tus dragones. Incuba o consigue otro drag\xf3n para usarla.","Cette Relique a d\xe9j\xe0 r\xe9v\xe9l\xe9 son secret pour chacun de tes dragons. Fais \xe9clore ou collectionne un autre dragon pour l\u2019utiliser.","Questa Reliquia ha gi\xe0 rivelato il suo segreto per ogni drago che possiedi. Fai schiudere o raccogli un altro drago per usarla.","Esta Rel\xedquia j\xe1 revelou seu segredo para todos os seus drag\xf5es. Choque ou consiga outro drag\xe3o para us\xe1-la.","\u3053\u306e\u30ec\u30ea\u30c3\u30af\u306f\u6240\u6709\u3059\u308b\u5168\u30c9\u30e9\u30b4\u30f3\u306e\u79d8\u5bc6\u3092\u3059\u3067\u306b\u660e\u304b\u3057\u3066\u3044\u307e\u3059\u3002\u5225\u306e\u30c9\u30e9\u30b4\u30f3\u3092\u5b75\u5316\u307e\u305f\u306f\u53ce\u96c6\u3059\u308b\u3068\u4f7f\u3048\u307e\u3059\u3002"],t.s)
A.kp=s(["Verstanden","Entendido","Compris","Capito","Entendido","\u4e86\u89e3"],t.s)
A.HP=s(["Ben\xf6tigte Expertisen","Pericias necesarias","Expertises requises","Competenze richieste","Especialidades necess\xe1rias","\u5fc5\u8981\u306a\u5c02\u9580\u6280\u80fd"],t.s)
A.ll=s(["Ascension-Voraussetzungen","Requisitos de Ascensi\xf3n","Conditions d\u2019Ascension","Requisiti per l\u2019Ascensione","Requisitos de Ascens\xe3o","\u30a2\u30bb\u30f3\u30b7\u30e7\u30f3\u306e\u6761\u4ef6"],t.s)
A.JS=s(["Erf\xfclle vor der Ascension beide Voraussetzungen.","Completa ambos requisitos antes de la Ascensi\xf3n.","Remplissez les deux conditions avant l\u2019Ascension.","Completa entrambi i requisiti prima dell\u2019Ascensione.","Cumpra os dois requisitos antes da Ascens\xe3o.","\u30a2\u30bb\u30f3\u30b7\u30e7\u30f3\u306e\u524d\u306b\u4e21\u65b9\u306e\u6761\u4ef6\u3092\u9054\u6210\u3057\u307e\u3057\u3087\u3046\u3002"],t.s)
A.jL=s(["Level & EP","Nivel y XP","Niveau et XP","Livello ed XP","N\xedvel e XP","\u30ec\u30d9\u30eb & XP"],t.s)
A.Cd=s(["Erforderliche Gesamtexpertise","Pericia total m\xednima","Expertise totale minimale","Competenza totale minima","Especialidade total m\xednima","\u5fc5\u8981\u306a\u5408\u8a08\u5c02\u9580\u6280\u80fd"],t.s)
A.qB=s(["Evolutionsanimation \xfcberspringen","Omitir animaci\xf3n de evoluci\xf3n","Passer l\u2019animation d\u2019\xe9volution","Salta animazione evoluzione","Pular anima\xe7\xe3o de evolu\xe7\xe3o","\u9032\u5316\u30a2\u30cb\u30e1\u30fc\u30b7\u30e7\u30f3\u3092\u30b9\u30ad\u30c3\u30d7"],t.s)
A.vv=s(["Portr\xe4ts","Retratos","Portraits","Ritratti","Retratos","\u30dd\u30fc\u30c8\u30ec\u30fc\u30c8"],t.s)
A.q5=s(["Kontoportr\xe4t","Retrato de cuenta","Portrait du compte","Ritratto account","Retrato da conta","\u30a2\u30ab\u30a6\u30f3\u30c8\u30dd\u30fc\u30c8\u30ec\u30fc\u30c8"],t.s)
A.DK=s(["Noch keine Portr\xe4ts gesammelt","A\xfan no has conseguido retratos","Aucun portrait collectionn\xe9","Nessun ritratto raccolto","Nenhum retrato coletado","\u30dd\u30fc\u30c8\u30ec\u30fc\u30c8\u306f\u307e\u3060\u3042\u308a\u307e\u305b\u3093"],t.s)
A.yw=s(["Portr\xe4ttruhen kosten im Shop 99 Edelsteine und enth\xfcllen immer ein Portr\xe4t, das du noch nicht besitzt.","Los cofres de retrato cuestan 99 gemas en la tienda y siempre revelan un retrato que a\xfan no tienes.","Les coffres de portrait co\xfbtent 99 gemmes dans la boutique et r\xe9v\xe8lent toujours un portrait in\xe9dit.","I forzieri ritratto costano 99 gemme nel negozio e rivelano sempre un ritratto che non possiedi.","Ba\xfas de retrato custam 99 gemas na Loja e sempre revelam um retrato que voc\xea ainda n\xe3o possui.","\u30dd\u30fc\u30c8\u30ec\u30fc\u30c8\u30c1\u30a7\u30b9\u30c8\u306f\u30b7\u30e7\u30c3\u30d7\u306799\u30b8\u30a7\u30e0\u3002\u672a\u6240\u6301\u306e\u30dd\u30fc\u30c8\u30ec\u30fc\u30c8\u304c\u5fc5\u305a\u51fa\u307e\u3059\u3002"],t.s)
A.xh=s(["Kontoportr\xe4t w\xe4hlen","Elegir retrato de cuenta","Choisir le portrait du compte","Scegli ritratto account","Escolher retrato da conta","\u30a2\u30ab\u30a6\u30f3\u30c8\u30dd\u30fc\u30c8\u30ec\u30fc\u30c8\u3092\u9078\u629e"],t.s)
A.le=s(["M\xfcnzen","Monedas","Pi\xe8ces","Monete","Moedas","\u30b3\u30a4\u30f3"],t.s)
A.rI=s(["Edelsteine","Gemas","Gemmes","Gemme","Gemas","\u30b8\u30a7\u30e0"],t.s)
A.zI=s(["Kaufen","Comprar","Acheter","Acquista","Comprar","\u8cfc\u5165"],t.s)
A.tH=s(["Noch keine M\xfcnztruhen","A\xfan no hay cofres de monedas","Pas encore de coffres \xe0 pi\xe8ces","Nessun forziere monete per ora","Ainda n\xe3o h\xe1 ba\xfas de moedas","\u30b3\u30a4\u30f3\u7528\u30c1\u30a7\u30b9\u30c8\u306f\u307e\u3060\u3042\u308a\u307e\u305b\u3093"],t.s)
A.jV=s(["In einem zuk\xfcnftigen Update k\xf6nnen hier besondere Truhen erscheinen.","En una futura actualizaci\xf3n podr\xe1n aparecer cofres especiales aqu\xed.","Des coffres sp\xe9ciaux pourront \xeatre ajout\xe9s ici ult\xe9rieurement.","In futuro potranno essere aggiunti forzieri speciali qui.","Ba\xfas especiais poder\xe3o ser adicionados aqui futuramente.","\u4eca\u5f8c\u306e\u30a2\u30c3\u30d7\u30c7\u30fc\u30c8\u3067\u7279\u5225\u306a\u30c1\u30a7\u30b9\u30c8\u304c\u8ffd\u52a0\u3055\u308c\u308b\u4e88\u5b9a\u3067\u3059\u3002"],t.s)
A.nz=s(["Enth\xe4lt ein zuf\xe4lliges Portr\xe4t, das du noch nicht besitzt. Der Inhalt wird erst beim \xd6ffnen bestimmt.","Contiene un retrato aleatorio que no tienes. El contenido se decide al abrirlo.","Contient un portrait al\xe9atoire in\xe9dit. Son contenu est d\xe9termin\xe9 \xe0 l\u2019ouverture.","Contiene un ritratto casuale che non possiedi. Il contenuto viene deciso solo all\u2019apertura.","Cont\xe9m um retrato aleat\xf3rio que voc\xea ainda n\xe3o possui. O conte\xfado s\xf3 \xe9 decidido ao abrir.","\u672a\u6240\u6301\u306e\u30dd\u30fc\u30c8\u30ec\u30fc\u30c8\u304c1\u3064\u5165\u3063\u3066\u3044\u307e\u3059\u3002\u4e2d\u8eab\u306f\u958b\u5c01\u6642\u306b\u6c7a\u307e\u308a\u307e\u3059\u3002"],t.s)
A.Jl=s(["Sammlung vollst\xe4ndig","Colecci\xf3n completa","Collection compl\xe8te","Collezione completa","Cole\xe7\xe3o completa","\u30b3\u30ec\u30af\u30b7\u30e7\u30f3\u5b8c\u6210"],t.s)
A.k6=s(["Portr\xe4ttruhe zum Inventar hinzugef\xfcgt.","Cofre de retrato a\xf1adido al Inventario.","Coffre de portrait ajout\xe9 \xe0 l\u2019Inventaire.","Forziere ritratto aggiunto all\u2019Inventario.","Ba\xfa de retrato adicionado ao Invent\xe1rio.","\u30dd\u30fc\u30c8\u30ec\u30fc\u30c8\u30c1\u30a7\u30b9\u30c8\u3092\u30a4\u30f3\u30d9\u30f3\u30c8\u30ea\u306b\u8ffd\u52a0\u3057\u307e\u3057\u305f\u3002"],t.s)
A.EG=s(["Du besitzt bereits alle 100 Portr\xe4ts.","Ya tienes los 100 retratos.","Tu poss\xe8des d\xe9j\xe0 les 100 portraits.","Possiedi gi\xe0 tutti e 100 i ritratti.","Voc\xea j\xe1 possui todos os 100 retratos.","100\u7a2e\u985e\u3059\u3079\u3066\u306e\u30dd\u30fc\u30c8\u30ec\u30fc\u30c8\u3092\u6240\u6301\u3057\u3066\u3044\u307e\u3059\u3002"],t.s)
A.CH=s(["Du besitzt bereits alle 100 Portr\xe4ts, daher kann keine weitere Portr\xe4ttruhe gekauft werden.","Ya tienes los 100 retratos, as\xed que no puedes comprar otro cofre de retrato.","Tu poss\xe8des d\xe9j\xe0 les 100 portraits, il est donc impossible d\u2019acheter un autre coffre de portrait.","Possiedi gi\xe0 tutti e 100 i ritratti, quindi non puoi acquistare un altro forziere ritratto.","Voc\xea j\xe1 possui todos os 100 retratos, ent\xe3o n\xe3o pode comprar outro ba\xfa de retrato.","100\u7a2e\u985e\u3059\u3079\u3066\u3092\u6240\u6301\u3057\u3066\u3044\u308b\u305f\u3081\u3001\u8ffd\u52a0\u306e\u30dd\u30fc\u30c8\u30ec\u30fc\u30c8\u30c1\u30a7\u30b9\u30c8\u306f\u8cfc\u5165\u3067\u304d\u307e\u305b\u3093\u3002"],t.s)
A.z3=s(["Portr\xe4t enth\xfcllt","Retrato revelado","Portrait r\xe9v\xe9l\xe9","Ritratto rivelato","Retrato revelado","\u30dd\u30fc\u30c8\u30ec\u30fc\u30c8\u51fa\u73fe"],t.s)
A.Ai=s(["Deiner Portr\xe4tsammlung hinzugef\xfcgt","A\xf1adido a tu colecci\xf3n de retratos","Ajout\xe9 \xe0 ta collection de portraits","Aggiunto alla tua collezione di ritratti","Adicionado \xe0 sua cole\xe7\xe3o de retratos","\u30dd\u30fc\u30c8\u30ec\u30fc\u30c8\u30b3\u30ec\u30af\u30b7\u30e7\u30f3\u306b\u8ffd\u52a0\u3057\u307e\u3057\u305f"],t.s)
A.wV=s(["Portr\xe4tsammlung vollst\xe4ndig","Colecci\xf3n de retratos completa","Collection de portraits compl\xe8te","Collezione ritratti completa","Cole\xe7\xe3o de retratos completa","\u30dd\u30fc\u30c8\u30ec\u30fc\u30c8\u30b3\u30ec\u30af\u30b7\u30e7\u30f3\u5b8c\u6210"],t.s)
A.zF=s(["Du besitzt bereits alle 100 Portr\xe4ts. Diese Portr\xe4ttruhe bleibt sicher im Inventar und kann nicht ge\xf6ffnet werden.","Ya tienes los 100 retratos. Este cofre permanece a salvo en tu Inventario y no puede abrirse.","Tu poss\xe8des d\xe9j\xe0 les 100 portraits. Ce coffre reste dans ton Inventaire et ne peut pas \xeatre ouvert.","Possiedi gi\xe0 tutti e 100 i ritratti. Il forziere rimane al sicuro nell\u2019Inventario e non pu\xf2 essere aperto.","Voc\xea j\xe1 possui todos os 100 retratos. Este ba\xfa fica seguro no Invent\xe1rio e n\xe3o pode ser aberto.","100\u7a2e\u985e\u3059\u3079\u3066\u3092\u6240\u6301\u3057\u3066\u3044\u308b\u305f\u3081\u3001\u3053\u306e\u30c1\u30a7\u30b9\u30c8\u306f\u30a4\u30f3\u30d9\u30f3\u30c8\u30ea\u306b\u6b8b\u308a\u3001\u958b\u5c01\u3067\u304d\u307e\u305b\u3093\u3002"],t.s)
A.oJ=s(["Portr\xe4ttruhe","Cofre de retrato","Coffre de portrait","Forziere ritratto","Ba\xfa de retrato","\u30dd\u30fc\u30c8\u30ec\u30fc\u30c8\u30c1\u30a7\u30b9\u30c8"],t.s)
A.pz=s(["Infernalisch","Infernal","Infernal","Infernale","Infernal","\u30a4\u30f3\u30d5\u30a1\u30fc\u30ca\u30eb"],t.s)
A.Ch=s(["Eine Portr\xe4ttruhe wartet in deinem Inventar.","Hay un cofre de retrato esperando en tu Inventario.","Un coffre de portrait t\u2019attend dans ton Inventaire.","Un forziere ritratto ti aspetta nell\u2019Inventario.","Um ba\xfa de retrato est\xe1 esperando no seu Invent\xe1rio.","\u30dd\u30fc\u30c8\u30ec\u30fc\u30c8\u30c1\u30a7\u30b9\u30c8\u304c\u30a4\u30f3\u30d9\u30f3\u30c8\u30ea\u3067\u5f85\u3063\u3066\u3044\u307e\u3059\u3002"],t.s)
A.po=s(["Ein neues Kontoportr\xe4t wurde deiner Sammlung hinzugef\xfcgt.","Un nuevo retrato de cuenta se uni\xf3 a tu colecci\xf3n.","Un nouveau portrait de compte a rejoint ta collection.","Un nuovo ritratto account si \xe8 aggiunto alla collezione.","Um novo retrato de conta entrou na sua cole\xe7\xe3o.","\u65b0\u3057\u3044\u30a2\u30ab\u30a6\u30f3\u30c8\u30dd\u30fc\u30c8\u30ec\u30fc\u30c8\u304c\u30b3\u30ec\u30af\u30b7\u30e7\u30f3\u306b\u52a0\u308f\u308a\u307e\u3057\u305f\u3002"],t.s)
A.nB=s(["Titel","T\xedtulos","Titres","Titoli","T\xedtulos","\u79f0\u53f7"],t.s)
A.qk=s(["Kontotitel w\xe4hlen","Elegir t\xedtulo de cuenta","Choisir le titre du compte","Scegli il titolo dell\u2019account","Escolher t\xedtulo da conta","\u30a2\u30ab\u30a6\u30f3\u30c8\u79f0\u53f7\u3092\u9078\u629e"],t.s)
A.IJ=s(["Titeltruhe","Cofre de t\xedtulos","Coffre de titres","Forziere dei titoli","Ba\xfa de t\xedtulos","\u79f0\u53f7\u30c1\u30a7\u30b9\u30c8"],t.s)
A.n9=s(["Enth\xe4lt einen zuf\xe4lligen Kontotitel, den du noch nicht besitzt. Der Inhalt wird erst beim \xd6ffnen bestimmt.","Contiene un t\xedtulo de cuenta aleatorio que a\xfan no tienes. El contenido se decide al abrirlo.","Contient un titre de compte al\xe9atoire que tu ne poss\xe8des pas. Son contenu est d\xe9termin\xe9 \xe0 l\u2019ouverture.","Contiene un titolo account casuale che non possiedi. Il contenuto viene deciso solo all\u2019apertura.","Cont\xe9m um t\xedtulo de conta aleat\xf3rio que voc\xea ainda n\xe3o possui. O conte\xfado \xe9 definido apenas ao abrir.","\u672a\u6240\u6301\u306e\u30a2\u30ab\u30a6\u30f3\u30c8\u79f0\u53f7\u304c1\u3064\u30e9\u30f3\u30c0\u30e0\u3067\u5165\u3063\u3066\u3044\u307e\u3059\u3002\u5185\u5bb9\u306f\u958b\u5c01\u6642\u306b\u6c7a\u307e\u308a\u307e\u3059\u3002"],t.s)
A.wt=s(["Titeltruhe deinem Inventar hinzugef\xfcgt.","Cofre de t\xedtulos a\xf1adido a tu Inventario.","Coffre de titres ajout\xe9 \xe0 ton Inventaire.","Forziere dei titoli aggiunto all\u2019Inventario.","Ba\xfa de t\xedtulos adicionado ao Invent\xe1rio.","\u79f0\u53f7\u30c1\u30a7\u30b9\u30c8\u3092\u30a4\u30f3\u30d9\u30f3\u30c8\u30ea\u306b\u8ffd\u52a0\u3057\u307e\u3057\u305f\u3002"],t.s)
A.DW=s(["Du besitzt bereits alle 500 Kontotitel, daher kann keine weitere Titeltruhe gekauft werden.","Ya tienes los 500 t\xedtulos de cuenta, as\xed que no puedes comprar otro cofre de t\xedtulos.","Tu poss\xe8des d\xe9j\xe0 les 500 titres de compte, il est donc impossible d\u2019acheter un autre coffre de titres.","Possiedi gi\xe0 tutti i 500 titoli account, quindi non puoi acquistare un altro forziere dei titoli.","Voc\xea j\xe1 possui todos os 500 t\xedtulos de conta, ent\xe3o n\xe3o pode comprar outro ba\xfa de t\xedtulos.","500\u7a2e\u985e\u3059\u3079\u3066\u306e\u30a2\u30ab\u30a6\u30f3\u30c8\u79f0\u53f7\u3092\u6240\u6301\u3057\u3066\u3044\u308b\u305f\u3081\u3001\u8ffd\u52a0\u306e\u79f0\u53f7\u30c1\u30a7\u30b9\u30c8\u306f\u8cfc\u5165\u3067\u304d\u307e\u305b\u3093\u3002"],t.s)
A.k0=s(["Titel enth\xfcllt","T\xedtulo revelado","Titre r\xe9v\xe9l\xe9","Titolo rivelato","T\xedtulo revelado","\u79f0\u53f7\u51fa\u73fe"],t.s)
A.IB=s(["Deiner Titelsammlung hinzugef\xfcgt","A\xf1adido a tu colecci\xf3n de t\xedtulos","Ajout\xe9 \xe0 ta collection de titres","Aggiunto alla tua collezione di titoli","Adicionado \xe0 sua cole\xe7\xe3o de t\xedtulos","\u79f0\u53f7\u30b3\u30ec\u30af\u30b7\u30e7\u30f3\u306b\u8ffd\u52a0\u3057\u307e\u3057\u305f"],t.s)
A.r0=s(["Titelsammlung vollst\xe4ndig","Colecci\xf3n de t\xedtulos completa","Collection de titres compl\xe8te","Collezione titoli completa","Cole\xe7\xe3o de t\xedtulos completa","\u79f0\u53f7\u30b3\u30ec\u30af\u30b7\u30e7\u30f3\u5b8c\u6210"],t.s)
A.kV=s(["Du besitzt bereits alle 500 Kontotitel. Diese Titeltruhe bleibt sicher im Inventar und kann nicht ge\xf6ffnet werden.","Ya tienes los 500 t\xedtulos de cuenta. Este cofre permanece a salvo en tu Inventario y no puede abrirse.","Tu poss\xe8des d\xe9j\xe0 les 500 titres de compte. Ce coffre reste dans ton Inventaire et ne peut pas \xeatre ouvert.","Possiedi gi\xe0 tutti i 500 titoli account. Il forziere rimane al sicuro nell\u2019Inventario e non pu\xf2 essere aperto.","Voc\xea j\xe1 possui todos os 500 t\xedtulos de conta. Este ba\xfa fica seguro no Invent\xe1rio e n\xe3o pode ser aberto.","500\u7a2e\u985e\u3059\u3079\u3066\u306e\u30a2\u30ab\u30a6\u30f3\u30c8\u79f0\u53f7\u3092\u6240\u6301\u3057\u3066\u3044\u308b\u305f\u3081\u3001\u3053\u306e\u30c1\u30a7\u30b9\u30c8\u306f\u30a4\u30f3\u30d9\u30f3\u30c8\u30ea\u306b\u6b8b\u308a\u3001\u958b\u5c01\u3067\u304d\u307e\u305b\u3093\u3002"],t.s)
A.qL=s(["Eine Titeltruhe wartet in deinem Inventar.","Hay un cofre de t\xedtulos esperando en tu Inventario.","Un coffre de titres t\u2019attend dans ton Inventaire.","Un forziere dei titoli ti aspetta nell\u2019Inventario.","Um ba\xfa de t\xedtulos est\xe1 esperando no seu Invent\xe1rio.","\u79f0\u53f7\u30c1\u30a7\u30b9\u30c8\u304c\u30a4\u30f3\u30d9\u30f3\u30c8\u30ea\u3067\u5f85\u3063\u3066\u3044\u307e\u3059\u3002"],t.s)
A.km=s(["Eine Anfrage steht bereits aus.","Ya hay una solicitud pendiente.","Une demande est d\xe9j\xe0 en attente.","Una richiesta \xe8 gi\xe0 in attesa.","J\xe1 existe uma solicita\xe7\xe3o pendente.","\u3059\u3067\u306b\u4fdd\u7559\u4e2d\u306e\u7533\u8acb\u304c\u3042\u308a\u307e\u3059\u3002"],t.s)
A.Hi=s(["Akzeptieren","Aceptar","Accepter","Accetta","Aceitar","\u627f\u8a8d"],t.s)
A.jO=s(["Per H\xfcter-ID hinzuf\xfcgen","A\xf1adir por ID de Guardi\xe1n","Ajouter par ID de Gardien","Aggiungi tramite ID Custode","Adicionar por ID de Guardi\xe3o","\u30ad\u30fc\u30d1\u30fcID\u3067\u8ffd\u52a0"],t.s)
A.Gl=s(["F\xfcr diese E-Mail-Adresse existiert bereits ein Konto.","Ya existe una cuenta para este correo electr\xf3nico.","Un compte existe d\xe9j\xe0 pour cette adresse e-mail.","Esiste gi\xe0 un account per questa e-mail.","J\xe1 existe uma conta para este e-mail.","\u3053\u306e\u30e1\u30fc\u30eb\u30a2\u30c9\u30ec\u30b9\u306e\u30a2\u30ab\u30a6\u30f3\u30c8\u306f\u3059\u3067\u306b\u5b58\u5728\u3057\u307e\u3059\u3002"],t.s)
A.xn=s(["Blockieren","Bloquear","Bloquer","Blocca","Bloquear","\u30d6\u30ed\u30c3\u30af"],t.s)
A.Lp=s(["H\xfcter blockieren","Bloquear Guardi\xe1n","Bloquer le Gardien","Blocca Custode","Bloquear Guardi\xe3o","\u30ad\u30fc\u30d1\u30fc\u3092\u30d6\u30ed\u30c3\u30af"],t.s)
A.mn=s(["Blockiert","Bloqueados","Bloqu\xe9s","Bloccati","Bloqueados","\u30d6\u30ed\u30c3\u30af\u4e2d"],t.s)
A.qY=s(["Best\xe4tige das Konto \xfcber deine E-Mail und melde dich danach an.","Revisa tu correo para confirmar la cuenta y luego inicia sesi\xf3n.","Consulte ton e-mail pour confirmer le compte, puis connecte-toi.","Controlla l\u2019e-mail per confermare l\u2019account, poi accedi.","Verifique seu e-mail para confirmar a conta e depois entre.","\u30e1\u30fc\u30eb\u3067\u30a2\u30ab\u30a6\u30f3\u30c8\u3092\u78ba\u8a8d\u3057\u3066\u304b\u3089\u30ed\u30b0\u30a4\u30f3\u3057\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.Jg=s(["Verbinde deinen H\xfcter","Conecta a tu Guardi\xe1n","Connecte ton Gardien","Collega il tuo Custode","Conecte seu Guardi\xe3o","\u30ad\u30fc\u30d1\u30fc\u3092\u63a5\u7d9a"],t.s)
A.y2=s(["H\xfcter-ID kopieren","Copiar ID de Guardi\xe1n","Copier l\u2019ID de Gardien","Copia ID Custode","Copiar ID de Guardi\xe3o","\u30ad\u30fc\u30d1\u30fcID\u3092\u30b3\u30d4\u30fc"],t.s)
A.vK=s(["Erstellen","Crear","Cr\xe9er","Crea","Criar","\u4f5c\u6210"],t.s)
A.mK=s(["Erstelle ein einfaches Konto, um Freunde per H\xfcter-ID hinzuzuf\xfcgen. Deine E-Mail wird anderen Spielern nie angezeigt.","Crea una cuenta sencilla para a\xf1adir amigos por ID de Guardi\xe1n. Tu correo nunca se muestra a otros jugadores.","Cr\xe9e un compte simple pour ajouter des amis par ID de Gardien. Ton e-mail n\u2019est jamais montr\xe9 aux autres joueurs.","Crea un account semplice per aggiungere amici tramite ID Custode. La tua e-mail non viene mai mostrata agli altri giocatori.","Crie uma conta simples para adicionar amigos pelo ID de Guardi\xe3o. Seu e-mail nunca \xe9 exibido a outros jogadores.","\u30b7\u30f3\u30d7\u30eb\u306a\u30a2\u30ab\u30a6\u30f3\u30c8\u3092\u4f5c\u6210\u3059\u308b\u3068\u3001\u30ad\u30fc\u30d1\u30fcID\u3067\u30d5\u30ec\u30f3\u30c9\u3092\u8ffd\u52a0\u3067\u304d\u307e\u3059\u3002\u30e1\u30fc\u30eb\u30a2\u30c9\u30ec\u30b9\u304c\u4ed6\u306e\u30d7\u30ec\u30a4\u30e4\u30fc\u306b\u8868\u793a\u3055\u308c\u308b\u3053\u3068\u306f\u3042\u308a\u307e\u305b\u3093\u3002"],t.s)
A.kJ=s(["Konto erstellen","Crear cuenta","Cr\xe9er un compte","Crea account","Criar conta","\u30a2\u30ab\u30a6\u30f3\u30c8\u3092\u4f5c\u6210"],t.s)
A.KN=s(["Online-Konto erstellen","Crear cuenta en l\xednea","Cr\xe9er un compte en ligne","Crea account online","Criar conta online","\u30aa\u30f3\u30e9\u30a4\u30f3\u30a2\u30ab\u30a6\u30f3\u30c8\u3092\u4f5c\u6210"],t.s)
A.t8=s(["Entdeckt","Descubiertos","D\xe9couverts","Scoperti","Descobertos","\u767a\u898b\u6e08\u307f"],t.s)
A.uB=s(["Entdeckte Drachen","Dragones descubiertos","Dragons d\xe9couverts","Draghi scoperti","Drag\xf5es descobertos","\u767a\u898b\u3057\u305f\u30c9\u30e9\u30b4\u30f3"],t.s)
A.uT=s(["Online-Profil bearbeiten","Editar perfil en l\xednea","Modifier le profil en ligne","Modifica profilo online","Editar perfil online","\u30aa\u30f3\u30e9\u30a4\u30f3\u30d7\u30ed\u30d5\u30a3\u30fc\u30eb\u3092\u7de8\u96c6"],t.s)
A.IZ=s(["Profil bearbeiten","Editar perfil","Modifier le profil","Modifica profilo","Editar perfil","\u30d7\u30ed\u30d5\u30a3\u30fc\u30eb\u3092\u7de8\u96c6"],t.s)
A.wN=s(["Gib einen Namen ein.","Introduce un nombre.","Saisis un nom.","Inserisci un nome.","Digite um nome.","\u540d\u524d\u3092\u5165\u529b\u3057\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.pK=s(["Gib eine g\xfcltige E-Mail-Adresse ein.","Introduce un correo electr\xf3nico v\xe1lido.","Saisis une adresse e-mail valide.","Inserisci un indirizzo e-mail valido.","Digite um e-mail v\xe1lido.","\u6709\u52b9\u306a\u30e1\u30fc\u30eb\u30a2\u30c9\u30ec\u30b9\u3092\u5165\u529b\u3057\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.lL=s(["Lieblingsdrache","Drag\xf3n favorito","Dragon favori","Drago preferito","Drag\xe3o favorito","\u304a\u6c17\u306b\u5165\u308a\u306e\u30c9\u30e9\u30b4\u30f3"],t.s)
A.z_=s(["Finde vertrauensw\xfcrdige H\xfcter, vergleiche Sammlungen und besuche ihre Profile.","Encuentra Guardianes de confianza, compara colecciones y visita sus perfiles.","Trouve des Gardiens de confiance, compare les collections et consulte leurs profils.","Trova Custodi fidati, confronta le collezioni e visita i loro profili.","Encontre Guardi\xf5es confi\xe1veis, compare cole\xe7\xf5es e visite seus perfis.","\u4fe1\u983c\u3067\u304d\u308b\u30ad\u30fc\u30d1\u30fc\u3092\u898b\u3064\u3051\u3001\u30b3\u30ec\u30af\u30b7\u30e7\u30f3\u3092\u6bd4\u3079\u3066\u30d7\u30ed\u30d5\u30a3\u30fc\u30eb\u3092\u8a2a\u554f\u3057\u307e\u3057\u3087\u3046\u3002"],t.s)
A.F7=s(["Die Freundschaft wurde f\xfcr beide H\xfcter entfernt.","La amistad se elimin\xf3 para ambos Guardianes.","L\u2019amiti\xe9 a \xe9t\xe9 supprim\xe9e pour les deux Gardiens.","L\u2019amicizia \xe8 stata rimossa per entrambi i Custodi.","A amizade foi removida para ambos os Guardi\xf5es.","\u4e21\u65b9\u306e\u30ad\u30fc\u30d1\u30fc\u306e\u30d5\u30ec\u30f3\u30c9\u95a2\u4fc2\u3092\u524a\u9664\u3057\u307e\u3057\u305f\u3002"],t.s)
A.Ft=s(["Freundschaftsanfrage gesendet.","Solicitud de amistad enviada.","Demande d\u2019amiti\xe9 envoy\xe9e.","Richiesta di amicizia inviata.","Solicita\xe7\xe3o de amizade enviada.","\u30d5\u30ec\u30f3\u30c9\u7533\u8acb\u3092\u9001\u4fe1\u3057\u307e\u3057\u305f\u3002"],t.s)
A.zH=s(["Freundschaftsanfragen","Solicitudes de amistad","Demandes d\u2019amiti\xe9","Richieste di amicizia","Solicita\xe7\xf5es de amizade","\u30d5\u30ec\u30f3\u30c9\u7533\u8acb"],t.s)
A.uv=s(["E-Mail oder Passwort ist falsch.","Correo o contrase\xf1a incorrectos.","E-mail ou mot de passe incorrect.","E-mail o password errati.","E-mail ou senha incorretos.","\u30e1\u30fc\u30eb\u30a2\u30c9\u30ec\u30b9\u307e\u305f\u306f\u30d1\u30b9\u30ef\u30fc\u30c9\u304c\u6b63\u3057\u304f\u3042\u308a\u307e\u305b\u3093\u3002"],t.s)
A.ni=s(["H\xfcter blockiert.","Guardi\xe1n bloqueado.","Gardien bloqu\xe9.","Custode bloccato.","Guardi\xe3o bloqueado.","\u30ad\u30fc\u30d1\u30fc\u3092\u30d6\u30ed\u30c3\u30af\u3057\u307e\u3057\u305f\u3002"],t.s)
A.uj=s(["H\xfcter-ID kopiert.","ID de Guardi\xe1n copiado.","ID de Gardien copi\xe9.","ID Custode copiato.","ID de Guardi\xe3o copiado.","\u30ad\u30fc\u30d1\u30fcID\u3092\u30b3\u30d4\u30fc\u3057\u307e\u3057\u305f\u3002"],t.s)
A.zD=s(["H\xfctername","Nombre del Guardi\xe1n","Nom du Gardien","Nome Custode","Nome do Guardi\xe3o","\u30ad\u30fc\u30d1\u30fc\u540d"],t.s)
A.I5=s(["H\xfcter entsperrt.","Guardi\xe1n desbloqueado.","Gardien d\xe9bloqu\xe9.","Custode sbloccato.","Guardi\xe3o desbloqueado.","\u30ad\u30fc\u30d1\u30fc\u306e\u30d6\u30ed\u30c3\u30af\u3092\u89e3\u9664\u3057\u307e\u3057\u305f\u3002"],t.s)
A.DV=s(["Kein Lieblingsdrache ausgew\xe4hlt.","No se ha elegido un drag\xf3n favorito.","Aucun dragon favori s\xe9lectionn\xe9.","Nessun drago preferito selezionato.","Nenhum drag\xe3o favorito selecionado.","\u304a\u6c17\u306b\u5165\u308a\u306e\u30c9\u30e9\u30b4\u30f3\u304c\u9078\u3070\u308c\u3066\u3044\u307e\u305b\u3093\u3002"],t.s)
A.ua=s(["Noch keine Freunde. Teile deine H\xfcter-ID oder f\xfcge jemanden hinzu.","A\xfan no tienes amigos. Comparte tu ID de Guardi\xe1n o a\xf1ade a alguien.","Pas encore d\u2019amis. Partage ton ID de Gardien ou ajoute quelqu\u2019un.","Ancora nessun amico. Condividi il tuo ID Custode o aggiungi qualcuno.","Ainda n\xe3o h\xe1 amigos. Compartilhe seu ID de Guardi\xe3o ou adicione algu\xe9m.","\u307e\u3060\u30d5\u30ec\u30f3\u30c9\u306f\u3044\u307e\u305b\u3093\u3002\u30ad\u30fc\u30d1\u30fcID\u3092\u5171\u6709\u3059\u308b\u304b\u3001\u8ab0\u304b\u3092\u8ffd\u52a0\u3057\u307e\u3057\u3087\u3046\u3002"],t.s)
A.B3=s(["Kein H\xfcter mit dieser ID wurde gefunden.","No se encontr\xf3 ning\xfan Guardi\xe1n con ese ID.","Aucun Gardien avec cet ID n\u2019a \xe9t\xe9 trouv\xe9.","Nessun Custode trovato con questo ID.","Nenhum Guardi\xe3o com esse ID foi encontrado.","\u305d\u306eID\u306e\u30ad\u30fc\u30d1\u30fc\u306f\u898b\u3064\u304b\u308a\u307e\u305b\u3093\u3067\u3057\u305f\u3002"],t.s)
A.ry=s(["Online-Konto","Cuenta en l\xednea","Compte en ligne","Account online","Conta online","\u30aa\u30f3\u30e9\u30a4\u30f3\u30a2\u30ab\u30a6\u30f3\u30c8"],t.s)
A.BZ=s(["Online-Konten sind in diesem Build bereit, aber dieser Installation fehlen noch Server-URL und \xf6ffentlicher Schl\xfcssel.","Las cuentas en l\xednea est\xe1n listas, pero esta instalaci\xf3n a\xfan necesita la URL del servidor y la clave p\xfablica.","Les comptes en ligne sont pr\xeats, mais cette installation n\xe9cessite encore l\u2019URL du serveur et la cl\xe9 publique.","Gli account online sono pronti, ma questa installazione richiede ancora l\u2019URL del server e la chiave pubblica.","As contas online est\xe3o prontas, mas esta instala\xe7\xe3o ainda precisa da URL do servidor e da chave p\xfablica.","\u30aa\u30f3\u30e9\u30a4\u30f3\u30a2\u30ab\u30a6\u30f3\u30c8\u306b\u306f\u5bfe\u5fdc\u3057\u3066\u3044\u307e\u3059\u304c\u3001\u3053\u306e\u30a4\u30f3\u30b9\u30c8\u30fc\u30eb\u306b\u306f\u30b5\u30fc\u30d0\u30fcURL\u3068\u516c\u958b\u30ad\u30fc\u304c\u5fc5\u8981\u3067\u3059\u3002"],t.s)
A.HS=s(["Passwort","Contrase\xf1a","Mot de passe","Password","Senha","\u30d1\u30b9\u30ef\u30fc\u30c9"],t.s)
A.uF=s(["Ausstehend","Pendiente","En attente","In attesa","Pendente","\u4fdd\u7559\u4e2d"],t.s)
A.Lk=s(["Profil gespeichert.","Perfil guardado.","Profil enregistr\xe9.","Profilo salvato.","Perfil salvo.","\u30d7\u30ed\u30d5\u30a3\u30fc\u30eb\u3092\u4fdd\u5b58\u3057\u307e\u3057\u305f\u3002"],t.s)
A.uz=s(["Ablehnen","Rechazar","Refuser","Rifiuta","Recusar","\u62d2\u5426"],t.s)
A.B1=s(["Freund entfernen","Eliminar amigo","Retirer l\u2019ami","Rimuovi amico","Remover amigo","\u30d5\u30ec\u30f3\u30c9\u3092\u524a\u9664"],t.s)
A.tK=s(["Freund entfernen?","\xbfEliminar amigo?","Retirer cet ami ?","Rimuovere l\u2019amico?","Remover amigo?","\u30d5\u30ec\u30f3\u30c9\u3092\u524a\u9664\u3057\u307e\u3059\u304b\uff1f"],t.s)
A.G8=s(["Anfrage senden","Enviar solicitud","Envoyer la demande","Invia richiesta","Enviar solicita\xe7\xe3o","\u7533\u8acb\u3092\u9001\u4fe1"],t.s)
A.qG=s(["Gesendete Anfragen","Solicitudes enviadas","Demandes envoy\xe9es","Richieste inviate","Solicita\xe7\xf5es enviadas","\u9001\u4fe1\u6e08\u307f\u7533\u8acb"],t.s)
A.yK=s(["Server-Einrichtung erforderlich","Configuraci\xf3n del servidor necesaria","Configuration du serveur requise","Configurazione server necessaria","Configura\xe7\xe3o do servidor necess\xe1ria","\u30b5\u30fc\u30d0\u30fc\u8a2d\u5b9a\u304c\u5fc5\u8981\u3067\u3059"],t.s)
A.CF=s(["Anmelden","Iniciar sesi\xf3n","Se connecter","Accedi","Entrar","\u30ed\u30b0\u30a4\u30f3"],t.s)
A.IC=s(["Abmelden","Cerrar sesi\xf3n","Se d\xe9connecter","Esci","Sair","\u30ed\u30b0\u30a2\u30a6\u30c8"],t.s)
A.F4=s(["Der Onlinedienst konnte diese Aktion nicht abschlie\xdfen. Versuche es erneut.","El servicio en l\xednea no pudo completar esta acci\xf3n. Int\xe9ntalo de nuevo.","Le service en ligne n\u2019a pas pu terminer cette action. R\xe9essaie.","Il servizio online non ha potuto completare l\u2019azione. Riprova.","O servi\xe7o online n\xe3o conseguiu concluir esta a\xe7\xe3o. Tente novamente.","\u30aa\u30f3\u30e9\u30a4\u30f3\u30b5\u30fc\u30d3\u30b9\u3067\u3053\u306e\u64cd\u4f5c\u3092\u5b8c\u4e86\u3067\u304d\u307e\u305b\u3093\u3067\u3057\u305f\u3002\u3082\u3046\u4e00\u5ea6\u304a\u8a66\u3057\u304f\u3060\u3055\u3044\u3002"],t.s)
A.ly=s(["Diese Installation hat noch keine Online-Serverkonfiguration.","Esta instalaci\xf3n a\xfan no tiene configuraci\xf3n de servidor en l\xednea.","Cette installation n\u2019a pas encore de configuration de serveur en ligne.","Questa installazione non ha ancora una configurazione server online.","Esta instala\xe7\xe3o ainda n\xe3o possui configura\xe7\xe3o de servidor online.","\u3053\u306e\u30a4\u30f3\u30b9\u30c8\u30fc\u30eb\u306b\u306f\u30aa\u30f3\u30e9\u30a4\u30f3\u30b5\u30fc\u30d0\u30fc\u8a2d\u5b9a\u304c\u3042\u308a\u307e\u305b\u3093\u3002"],t.s)
A.FV=s(["Dieser H\xfcter ist nicht verf\xfcgbar.","Este Guardi\xe1n no est\xe1 disponible.","Ce Gardien est indisponible.","Questo Custode non \xe8 disponibile.","Este Guardi\xe3o n\xe3o est\xe1 dispon\xedvel.","\u3053\u306e\u30ad\u30fc\u30d1\u30fc\u306f\u5229\u7528\u3067\u304d\u307e\u305b\u3093\u3002"],t.s)
A.qz=s(["Diese Anfrage wurde k\xfcrzlich abgelehnt. Versuche es sp\xe4ter erneut.","Esta solicitud se rechaz\xf3 recientemente. Int\xe9ntalo m\xe1s tarde.","Cette demande a \xe9t\xe9 refus\xe9e r\xe9cemment. R\xe9essaie plus tard.","Questa richiesta \xe8 stata rifiutata di recente. Riprova pi\xf9 tardi.","Esta solicita\xe7\xe3o foi recusada recentemente. Tente novamente mais tarde.","\u3053\u306e\u7533\u8acb\u306f\u6700\u8fd1\u62d2\u5426\u3055\u308c\u307e\u3057\u305f\u3002\u5f8c\u3067\u3082\u3046\u4e00\u5ea6\u304a\u8a66\u3057\u304f\u3060\u3055\u3044\u3002"],t.s)
A.tk=s(["Titel","T\xedtulo","Titre","Titolo","T\xedtulo","\u79f0\u53f7"],t.s)
A.op=s(["Zu viele Anfragen stehen aus.","Hay demasiadas solicitudes pendientes.","Trop de demandes sont en attente.","Ci sono troppe richieste in attesa.","H\xe1 solicita\xe7\xf5es pendentes demais.","\u4fdd\u7559\u4e2d\u306e\u7533\u8acb\u304c\u591a\u3059\u304e\u307e\u3059\u3002"],t.s)
A.zj=s(["Entsperren","Desbloquear","D\xe9bloquer","Sblocca","Desbloquear","\u30d6\u30ed\u30c3\u30af\u89e3\u9664"],t.s)
A.Fe=s(["Verwende mindestens 8 Zeichen.","Usa al menos 8 caracteres.","Utilise au moins 8 caract\xe8res.","Usa almeno 8 caratteri.","Use pelo menos 8 caracteres.","8\u6587\u5b57\u4ee5\u4e0a\u4f7f\u7528\u3057\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.xf=s(["Ihr seid bereits Freunde.","Ya sois amigos.","Vous \xeates d\xe9j\xe0 amis.","Siete gi\xe0 amici.","Voc\xeas j\xe1 s\xe3o amigos.","\u3059\u3067\u306b\u30d5\u30ec\u30f3\u30c9\u3067\u3059\u3002"],t.s)
A.Ex=s(["Du kannst dich nicht selbst hinzuf\xfcgen.","No puedes a\xf1adirte a ti mismo.","Tu ne peux pas t\u2019ajouter toi-m\xeame.","Non puoi aggiungere te stesso.","Voc\xea n\xe3o pode adicionar a si mesmo.","\u81ea\u5206\u81ea\u8eab\u3092\u8ffd\u52a0\u3059\u308b\u3053\u3068\u306f\u3067\u304d\u307e\u305b\u3093\u3002"],t.s)
A.Gy=s(["Dein Online-Konto ist bereit.","Tu cuenta en l\xednea est\xe1 lista.","Ton compte en ligne est pr\xeat.","Il tuo account online \xe8 pronto.","Sua conta online est\xe1 pronta.","\u30aa\u30f3\u30e9\u30a4\u30f3\u30a2\u30ab\u30a6\u30f3\u30c8\u306e\u6e96\u5099\u304c\u3067\u304d\u307e\u3057\u305f\u3002"],t.s)
A.ww=s(["Ein neuer Kontotitel wurde deiner Sammlung hinzugef\xfcgt.","Un nuevo t\xedtulo de cuenta se uni\xf3 a tu colecci\xf3n.","Un nouveau titre de compte a rejoint ta collection.","Un nuovo titolo account si \xe8 aggiunto alla collezione.","Um novo t\xedtulo de conta entrou na sua cole\xe7\xe3o.","\u65b0\u3057\u3044\u30a2\u30ab\u30a6\u30f3\u30c8\u79f0\u53f7\u304c\u30b3\u30ec\u30af\u30b7\u30e7\u30f3\u306b\u52a0\u308f\u308a\u307e\u3057\u305f\u3002"],t.s)
A.I_=s(["Handel abbrechen","Cancelar intercambio","Annuler l\u2019\xe9change","Annulla scambio","Cancelar troca","\u4ea4\u63db\u3092\u30ad\u30e3\u30f3\u30bb\u30eb"],t.s)
A.xC=s(["Truhe","Cofre","Coffre","Forziere","Ba\xfa","\u5b9d\u7bb1"],t.s)
A.KD=s(["Meinen Gegenstand w\xe4hlen","Elegir mi objeto","Choisir mon objet","Scegli il mio oggetto","Escolher meu item","\u81ea\u5206\u306e\u30a2\u30a4\u30c6\u30e0\u3092\u9078\u3076"],t.s)
A.CC=s(["Einen Gegenstand w\xe4hlen","Elige un objeto","Choisis un objet","Scegli un oggetto","Escolha um item","\u30a2\u30a4\u30c6\u30e0\u30921\u3064\u9078\u3076"],t.s)
A.JP=s(["Diesen Handel abschlie\xdfen?","\xbfCompletar este intercambio?","Finaliser cet \xe9change ?","Completare questo scambio?","Concluir esta troca?","\u3053\u306e\u4ea4\u63db\u3092\u5b8c\u4e86\u3057\u307e\u3059\u304b\uff1f"],t.s)
A.pu=s(["Endg\xfcltig best\xe4tigen","Confirmaci\xf3n final","Confirmation finale","Conferma finale","Confirma\xe7\xe3o final","\u6700\u7d42\u78ba\u8a8d"],t.s)
A.Ga=s(["Neues Handelsangebot","Nueva propuesta de intercambio","Nouvelle proposition d\u2019\xe9change","Nuova proposta di scambio","Nova proposta de troca","\u65b0\u3057\u3044\u4ea4\u63db\u63d0\u6848"],t.s)
A.r3=s(["Handel \xf6ffnen","Abrir intercambio","Ouvrir l\u2019\xe9change","Apri scambio","Abrir troca","\u4ea4\u63db\u3092\u958b\u304f"],t.s)
A.rH=s(["Handel ablehnen","Rechazar intercambio","Refuser l\u2019\xe9change","Rifiuta scambio","Recusar troca","\u4ea4\u63db\u3092\u62d2\u5426"],t.s)
A.E4=s(["Relikt","Reliquia","Relique","Reliquia","Rel\xedquia","\u30ec\u30ea\u30c3\u30af"],t.s)
A.JT=s(["F\xfcr Handel reserviert","Reservado para intercambio","R\xe9serv\xe9 pour un \xe9change","Riservato per lo scambio","Reservado para troca","\u4ea4\u63db\u7528\u306b\u4e88\u7d04\u6e08\u307f"],t.s)
A.Lv=s(["Senden","Enviar","Envoyer","Invia","Enviar","\u9001\u4fe1"],t.s)
A.jJ=s(["Handelsangebot senden?","\xbfEnviar propuesta de intercambio?","Envoyer la proposition d\u2019\xe9change ?","Inviare la proposta di scambio?","Enviar proposta de troca?","\u4ea4\u63db\u63d0\u6848\u3092\u9001\u308a\u307e\u3059\u304b\uff1f"],t.s)
A.om=s(["Der abgeschlossene Handel konnte lokal nicht gespeichert werden. Deine Servergegenst\xe4nde sind sicher; bitte aktualisieren.","El intercambio completado no pudo guardarse localmente. Tus objetos del servidor est\xe1n seguros; actualiza.","L\u2019\xe9change termin\xe9 n\u2019a pas pu \xeatre enregistr\xe9 localement. Tes objets serveur restent en s\xe9curit\xe9 ; actualise.","Lo scambio completato non \xe8 stato salvato localmente. Gli oggetti sul server sono al sicuro; aggiorna.","A troca conclu\xedda n\xe3o p\xf4de ser salva localmente. Seus itens no servidor est\xe3o seguros; atualize.","\u5b8c\u4e86\u3057\u305f\u4ea4\u63db\u3092\u7aef\u672b\u306b\u4fdd\u5b58\u3067\u304d\u307e\u305b\u3093\u3067\u3057\u305f\u3002\u30b5\u30fc\u30d0\u30fc\u4e0a\u306e\u30a2\u30a4\u30c6\u30e0\u306f\u5b89\u5168\u3067\u3059\u3002\u66f4\u65b0\u3057\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.AK=s(["Der Gegenstand wird sicher verwahrt und kann nicht in einem anderen Handel verwendet werden.","El objeto queda protegido y no puede usarse en otro intercambio.","L\u2019objet est conserv\xe9 en s\xe9curit\xe9 et ne peut pas servir dans un autre \xe9change.","L\u2019oggetto viene custodito e non pu\xf2 essere usato in un altro scambio.","O item fica protegido e n\xe3o pode ser usado em outra troca.","\u30a2\u30a4\u30c6\u30e0\u306f\u5b89\u5168\u306b\u78ba\u4fdd\u3055\u308c\u3001\u5225\u306e\u4ea4\u63db\u306b\u306f\u4f7f\u3048\u307e\u305b\u3093\u3002"],t.s)
A.A6=s(["Dies ist die endg\xfcltige Best\xe4tigung. Beide Gegenst\xe4nde wechseln sofort den Besitzer.","Esta es la confirmaci\xf3n final. Ambos objetos cambiar\xe1n de due\xf1o inmediatamente.","C\u2019est la confirmation finale. Les deux objets changeront imm\xe9diatement de propri\xe9taire.","Questa \xe8 la conferma finale. Entrambi gli oggetti cambieranno subito proprietario.","Esta \xe9 a confirma\xe7\xe3o final. Os dois itens mudar\xe3o de dono imediatamente.","\u3053\u308c\u304c\u6700\u7d42\u78ba\u8a8d\u3067\u3059\u3002\u4e21\u65b9\u306e\u30a2\u30a4\u30c6\u30e0\u306f\u3059\u3050\u306b\u6240\u6709\u8005\u304c\u5909\u308f\u308a\u307e\u3059\u3002"],t.s)
A.Ha=s(["Dieser Gegenstand kann nicht gehandelt werden.","Este objeto no se puede intercambiar.","Cet objet ne peut pas \xeatre \xe9chang\xe9.","Questo oggetto non pu\xf2 essere scambiato.","Este item n\xe3o pode ser trocado.","\u3053\u306e\u30a2\u30a4\u30c6\u30e0\u306f\u4ea4\u63db\u3067\u304d\u307e\u305b\u3093\u3002"],t.s)
A.yd=s(["Dieser Gegenstand ist nicht mehr verf\xfcgbar oder bereits reserviert.","Este objeto ya no est\xe1 disponible o ya est\xe1 reservado.","Cet objet n\u2019est plus disponible ou est d\xe9j\xe0 r\xe9serv\xe9.","Questo oggetto non \xe8 pi\xf9 disponibile o \xe8 gi\xe0 riservato.","Este item n\xe3o est\xe1 mais dispon\xedvel ou j\xe1 est\xe1 reservado.","\u3053\u306e\u30a2\u30a4\u30c6\u30e0\u306f\u5229\u7528\u3067\u304d\u306a\u3044\u304b\u3001\u3059\u3067\u306b\u4e88\u7d04\u3055\u308c\u3066\u3044\u307e\u3059\u3002"],t.s)
A.Jk=s(["Dieser Handel hat sich bereits ge\xe4ndert. Aktualisiere und versuche es erneut.","Este intercambio ya ha cambiado. Actualiza e int\xe9ntalo de nuevo.","Cet \xe9change a d\xe9j\xe0 chang\xe9. Actualise et r\xe9essaie.","Questo scambio \xe8 gi\xe0 cambiato. Aggiorna e riprova.","Esta troca j\xe1 mudou. Atualize e tente novamente.","\u3053\u306e\u4ea4\u63db\u306f\u3059\u3067\u306b\u5909\u66f4\u3055\u308c\u3066\u3044\u307e\u3059\u3002\u66f4\u65b0\u3057\u3066\u3082\u3046\u4e00\u5ea6\u304a\u8a66\u3057\u304f\u3060\u3055\u3044\u3002"],t.s)
A.xH=s(["Handeln","Intercambiar","\xc9changer","Scambia","Trocar","\u4ea4\u63db"],t.s)
A.Hc=s(["Handel abgebrochen","Intercambio cancelado","\xc9change annul\xe9","Scambio annullato","Troca cancelada","\u4ea4\u63db\u306f\u30ad\u30e3\u30f3\u30bb\u30eb\u3055\u308c\u307e\u3057\u305f"],t.s)
A.EK=s(["Handel abgebrochen. Reservierte Gegenst\xe4nde sind wieder verf\xfcgbar.","Intercambio cancelado. Los objetos reservados vuelven a estar disponibles.","\xc9change annul\xe9. Les objets r\xe9serv\xe9s sont de nouveau disponibles.","Scambio annullato. Gli oggetti riservati sono di nuovo disponibili.","Troca cancelada. Os itens reservados est\xe3o dispon\xedveis novamente.","\u4ea4\u63db\u3092\u30ad\u30e3\u30f3\u30bb\u30eb\u3057\u307e\u3057\u305f\u3002\u4e88\u7d04\u30a2\u30a4\u30c6\u30e0\u306f\u518d\u3073\u5229\u7528\u3067\u304d\u307e\u3059\u3002"],t.s)
A.vy=s(["Handel abgeschlossen","Intercambio completado","\xc9change termin\xe9","Scambio completato","Troca conclu\xedda","\u4ea4\u63db\u5b8c\u4e86"],t.s)
A.lr=s(["Handel abgeschlossen. Der erhaltene Gegenstand ist in deinem Inventar.","Intercambio completado. El objeto recibido est\xe1 en tu inventario.","\xc9change termin\xe9. L\u2019objet re\xe7u est dans ton inventaire.","Scambio completato. L\u2019oggetto ricevuto \xe8 nel tuo inventario.","Troca conclu\xedda. O item recebido est\xe1 no seu invent\xe1rio.","\u4ea4\u63db\u5b8c\u4e86\u3002\u53d7\u3051\u53d6\u3063\u305f\u30a2\u30a4\u30c6\u30e0\u306f\u30a4\u30f3\u30d9\u30f3\u30c8\u30ea\u306b\u3042\u308a\u307e\u3059\u3002"],t.s)
A.GP=s(["Handelsangebot gesendet.","Propuesta de intercambio enviada.","Proposition d\u2019\xe9change envoy\xe9e.","Proposta di scambio inviata.","Proposta de troca enviada.","\u4ea4\u63db\u63d0\u6848\u3092\u9001\u4fe1\u3057\u307e\u3057\u305f\u3002"],t.s)
A.FP=s(["Handel abgelehnt","Intercambio rechazado","\xc9change refus\xe9","Scambio rifiutato","Troca recusada","\u4ea4\u63db\u306f\u62d2\u5426\u3055\u308c\u307e\u3057\u305f"],t.s)
A.A_=s(["Handel abgelehnt. Reservierte Gegenst\xe4nde sind wieder verf\xfcgbar.","Intercambio rechazado. Los objetos reservados vuelven a estar disponibles.","\xc9change refus\xe9. Les objets r\xe9serv\xe9s sont de nouveau disponibles.","Scambio rifiutato. Gli oggetti riservati sono di nuovo disponibili.","Troca recusada. Os itens reservados est\xe3o dispon\xedveis novamente.","\u4ea4\u63db\u3092\u62d2\u5426\u3057\u307e\u3057\u305f\u3002\u4e88\u7d04\u30a2\u30a4\u30c6\u30e0\u306f\u518d\u3073\u5229\u7528\u3067\u304d\u307e\u3059\u3002"],t.s)
A.JY=s(["Mit diesem Freund handeln","Intercambiar con este amigo","\xc9changer avec cet ami","Scambia con questo amico","Trocar com este amigo","\u3053\u306e\u30d5\u30ec\u30f3\u30c9\u3068\u4ea4\u63db"],t.s)
A.ku=s(["Handel ist nur zwischen Freunden m\xf6glich.","Los intercambios solo est\xe1n disponibles entre amigos.","Les \xe9changes sont r\xe9serv\xe9s aux amis.","Gli scambi sono disponibili solo tra amici.","Trocas est\xe3o dispon\xedveis apenas entre amigos.","\u4ea4\u63db\u306f\u30d5\u30ec\u30f3\u30c9\u540c\u58eb\u3067\u306e\u307f\u5229\u7528\u3067\u304d\u307e\u3059\u3002"],t.s)
A.qo=s(["Warten auf einen Gegengegenstand.","Esperando un objeto a cambio.","En attente d\u2019un objet en retour.","In attesa di un oggetto in cambio.","Aguardando um item em troca.","\u76f8\u624b\u306e\u30a2\u30a4\u30c6\u30e0\u3092\u5f85\u3063\u3066\u3044\u307e\u3059\u3002"],t.s)
A.rR=s(["Warten auf die endg\xfcltige Best\xe4tigung","Esperando la confirmaci\xf3n final","En attente de la confirmation finale","In attesa della conferma finale","Aguardando a confirma\xe7\xe3o final","\u6700\u7d42\u78ba\u8a8d\u3092\u5f85\u3063\u3066\u3044\u307e\u3059"],t.s)
A.GN=s(["Warten auf deinen Freund","Esperando a tu amigo","En attente de ton ami","In attesa del tuo amico","Aguardando seu amigo","\u30d5\u30ec\u30f3\u30c9\u3092\u5f85\u3063\u3066\u3044\u307e\u3059"],t.s)
A.kk=s(["Du hast keine freien Eier, Truhen oder Relikte zum Handeln.","No tienes huevos, cofres ni reliquias sin reservar para intercambiar.","Tu n\u2019as aucun \u0153uf, coffre ou relique libre \xe0 \xe9changer.","Non hai uova, forzieri o reliquie liberi da scambiare.","Voc\xea n\xe3o tem ovos, ba\xfas ou rel\xedquias livres para trocar.","\u4ea4\u63db\u3067\u304d\u308b\u672a\u4e88\u7d04\u306e\u5375\u3001\u5b9d\u7bb1\u3001\u30ec\u30ea\u30c3\u30af\u304c\u3042\u308a\u307e\u305b\u3093\u3002"],t.s)
A.Is=s(["Du hast zu viele aktive Handel. Schlie\xdfe zuerst einen ab oder brich ihn ab.","Tienes demasiados intercambios activos. Completa o cancela uno primero.","Tu as trop d\u2019\xe9changes actifs. Termine ou annule-en un d\u2019abord.","Hai troppi scambi attivi. Completane o annullane prima uno.","Voc\xea tem trocas ativas demais. Conclua ou cancele uma primeiro.","\u9032\u884c\u4e2d\u306e\u4ea4\u63db\u304c\u591a\u3059\u304e\u307e\u3059\u3002\u5148\u306b1\u4ef6\u5b8c\u4e86\u307e\u305f\u306f\u30ad\u30e3\u30f3\u30bb\u30eb\u3057\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.BA=s(["Du bietest an","T\xfa ofreces","Tu proposes","Tu offri","Voc\xea oferece","\u3042\u306a\u305f\u306e\u63d0\u793a"],t.s)
A.IV=s(["Deine endg\xfcltige Best\xe4tigung ist erforderlich","Se necesita tu confirmaci\xf3n final","Ta confirmation finale est n\xe9cessaire","Serve la tua conferma finale","Sua confirma\xe7\xe3o final \xe9 necess\xe1ria","\u3042\u306a\u305f\u306e\u6700\u7d42\u78ba\u8a8d\u304c\u5fc5\u8981\u3067\u3059"],t.s)
A.JD=s(["Dein Gegenstand ist reserviert. Dein Freund kann den Handel jetzt best\xe4tigen.","Tu objeto est\xe1 reservado. Tu amigo ya puede confirmar el intercambio.","Ton objet est r\xe9serv\xe9. Ton ami peut maintenant confirmer l\u2019\xe9change.","Il tuo oggetto \xe8 riservato. Il tuo amico pu\xf2 ora confermare lo scambio.","Seu item est\xe1 reservado. Seu amigo j\xe1 pode confirmar a troca.","\u30a2\u30a4\u30c6\u30e0\u3092\u4e88\u7d04\u3057\u307e\u3057\u305f\u3002\u30d5\u30ec\u30f3\u30c9\u304c\u4ea4\u63db\u3092\u78ba\u8a8d\u3067\u304d\u307e\u3059\u3002"],t.s)
A.z7=s(["Der Gegenstand wird sicher verwahrt und kann nicht in einem anderen Handel verwendet werden. Der Vorschlag verf\xe4llt zehn Minuten nach seiner Erstellung.","El objeto queda protegido y no puede usarse en otro intercambio. La propuesta caduca diez minutos despu\xe9s de su creaci\xf3n.","L\u2019objet est conserv\xe9 en s\xe9curit\xe9 et ne peut pas servir dans un autre \xe9change. La proposition expire dix minutes apr\xe8s sa cr\xe9ation.","L\u2019oggetto viene custodito e non pu\xf2 essere usato in un altro scambio. La proposta scade dieci minuti dopo la creazione.","O item fica protegido e n\xe3o pode ser usado em outra troca. A proposta expira dez minutos ap\xf3s ser criada.","\u30a2\u30a4\u30c6\u30e0\u306f\u5b89\u5168\u306b\u78ba\u4fdd\u3055\u308c\u3001\u5225\u306e\u4ea4\u63db\u306b\u306f\u4f7f\u3048\u307e\u305b\u3093\u3002\u63d0\u6848\u306f\u4f5c\u6210\u304b\u308910\u5206\u5f8c\u306b\u671f\u9650\u5207\u308c\u306b\u306a\u308a\u307e\u3059\u3002"],t.s)
A.yv=s(["Pro Konto ist nur ein aktiver Handel erlaubt. Schlie\xdfe ihn zuerst ab, lehne ihn ab oder brich ihn ab.","Solo se permite un intercambio activo por cuenta. Compl\xe9talo, rech\xe1zalo o canc\xe9lalo primero.","Un seul \xe9change actif est autoris\xe9 par compte. Termine-le, refuse-le ou annule-le d\u2019abord.","\xc8 consentito un solo scambio attivo per account. Prima completalo, rifiutalo o annullalo.","S\xf3 \xe9 permitida uma troca ativa por conta. Primeiro conclua, recuse ou cancele essa troca.","\u30a2\u30ab\u30a6\u30f3\u30c8\u3054\u3068\u306b\u540c\u6642\u9032\u884c\u3067\u304d\u308b\u4ea4\u63db\u306f1\u4ef6\u3060\u3051\u3067\u3059\u3002\u5148\u306b\u5b8c\u4e86\u3001\u62d2\u5426\u3001\u307e\u305f\u306f\u30ad\u30e3\u30f3\u30bb\u30eb\u3057\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.wH=s(["Einer von euch hat heute bereits drei Handelsvorg\xe4nge abgeschlossen. Versucht es morgen erneut.","Uno de vosotros ya ha completado tres intercambios hoy. Int\xe9ntalo de nuevo ma\xf1ana.","L\u2019un de vous a d\xe9j\xe0 termin\xe9 trois \xe9changes aujourd\u2019hui. R\xe9essayez demain.","Uno di voi ha gi\xe0 completato tre scambi oggi. Riprova domani.","Um de voc\xeas j\xe1 concluiu tr\xeas trocas hoje. Tente novamente amanh\xe3.","\u3069\u3061\u3089\u304b\u304c\u4eca\u65e5\u3059\u3067\u306b3\u4ef6\u306e\u4ea4\u63db\u3092\u5b8c\u4e86\u3057\u3066\u3044\u307e\u3059\u3002\u660e\u65e5\u3082\u3046\u4e00\u5ea6\u304a\u8a66\u3057\u304f\u3060\u3055\u3044\u3002"],t.s)
A.ml=s(["Dieser Handel ist nach zehn Minuten abgelaufen. Die reservierten Gegenst\xe4nde sind wieder verf\xfcgbar.","Este intercambio caduc\xf3 tras diez minutos. Los objetos reservados vuelven a estar disponibles.","Cet \xe9change a expir\xe9 apr\xe8s dix minutes. Les objets r\xe9serv\xe9s sont de nouveau disponibles.","Questo scambio \xe8 scaduto dopo dieci minuti. Gli oggetti riservati sono di nuovo disponibili.","Esta troca expirou ap\xf3s dez minutos. Os itens reservados est\xe3o dispon\xedveis novamente.","\u3053\u306e\u4ea4\u63db\u306f10\u5206\u5f8c\u306b\u671f\u9650\u5207\u308c\u306b\u306a\u308a\u307e\u3057\u305f\u3002\u78ba\u4fdd\u3055\u308c\u3066\u3044\u305f\u30a2\u30a4\u30c6\u30e0\u306f\u518d\u3073\u4f7f\u7528\u3067\u304d\u307e\u3059\u3002"],t.s)
A.Hq=s(["Handel abgelaufen","Intercambio caducado","\xc9change expir\xe9","Scambio scaduto","Troca expirada","\u4ea4\u63db\u671f\u9650\u5207\u308c"],t.s)
A.GS=s(["Gib dein Passwort ein.","Introduce tu contrase\xf1a.","Saisis ton mot de passe.","Inserisci la password.","Digite sua senha.","\u30d1\u30b9\u30ef\u30fc\u30c9\u3092\u5165\u529b\u3057\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.ra=s(["Der Online-Server ist nicht konfiguriert.","El servidor en l\xednea no est\xe1 configurado.","Le serveur en ligne n\u2019est pas configur\xe9.","Il server online non \xe8 configurato.","O servidor online n\xe3o est\xe1 configurado.","\u30aa\u30f3\u30e9\u30a4\u30f3\u30b5\u30fc\u30d0\u30fc\u304c\u8a2d\u5b9a\u3055\u308c\u3066\u3044\u307e\u305b\u3093\u3002"],t.s)
A.qc=s(["Dieses Profil wird derzeit offline gespeichert.","Este perfil se guarda actualmente sin conexi\xf3n.","Ce profil est actuellement enregistr\xe9 hors ligne.","Questo profilo \xe8 attualmente salvato offline.","Este perfil est\xe1 armazenado offline no momento.","\u3053\u306e\u30d7\u30ed\u30d5\u30a3\u30fc\u30eb\u306f\u73fe\u5728\u30aa\u30d5\u30e9\u30a4\u30f3\u3067\u4fdd\u5b58\u3055\u308c\u3066\u3044\u307e\u3059\u3002"],t.s)
A.C5=s(["Vertrauensw\xfcrdige H\xfcter, gemeinsame Abenteuer und sichere Tauschgesch\xe4fte.","Guardianes de confianza, aventuras compartidas e intercambios seguros.","Gardiens de confiance, aventures partag\xe9es et \xe9changes s\xe9curis\xe9s.","Custodi fidati, avventure condivise e scambi sicuri.","Guardi\xf5es confi\xe1veis, aventuras compartilhadas e trocas seguras.","\u4fe1\u983c\u3067\u304d\u308b\u30ad\u30fc\u30d1\u30fc\u3001\u5354\u529b\u30a2\u30c9\u30d9\u30f3\u30c1\u30e3\u30fc\u3001\u5b89\u5168\u306a\u4ea4\u63db\u3002"],t.s)
A.na=s(["Freunde","amigos","amis","amici","amigos","\u30d5\u30ec\u30f3\u30c9"],t.s)
A.K1=s(["Anfragen","solicitudes","demandes","richieste","pedidos","\u30ea\u30af\u30a8\u30b9\u30c8"],t.s)
A.nq=s(["Tauschgesch\xe4fte","intercambios","\xe9changes","scambi","trocas","\u4ea4\u63db"],t.s)
A.pL=s(["Drachen entdeckt","dragones descubiertos","dragons d\xe9couverts","draghi scoperti","drag\xf5es descobertos","\u767a\u898b\u3057\u305f\u30c9\u30e9\u30b4\u30f3"],t.s)
A.mO=s(["Verwende einen Gro\xdfbuchstaben, einen Kleinbuchstaben, eine Zahl und ein Symbol.","Usa una may\xfascula, una min\xfascula, un n\xfamero y un s\xedmbolo.","Utilise une majuscule, une minuscule, un chiffre et un symbole.","Usa una lettera maiuscola, una minuscola, un numero e un simbolo.","Use uma letra mai\xfascula, uma min\xfascula, um n\xfamero e um s\xedmbolo.","\u5927\u6587\u5b57\u3001\u5c0f\u6587\u5b57\u3001\u6570\u5b57\u3001\u8a18\u53f7\u3092\u305d\u308c\u305e\u308c\u4f7f\u7528\u3057\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.pO=s(["Best\xe4tigungs-E-Mail erneut senden","Reenviar correo de confirmaci\xf3n","Renvoyer l\u2019e-mail de confirmation","Invia di nuovo l\u2019e-mail di conferma","Reenviar e-mail de confirma\xe7\xe3o","\u78ba\u8a8d\u30e1\u30fc\u30eb\u3092\u518d\u9001"],t.s)
A.rN=s(["Best\xe4tigungs-E-Mail gesendet. Pr\xfcfe deinen Posteingang und Spam-Ordner.","Correo de confirmaci\xf3n enviado. Revisa tu bandeja de entrada y spam.","E-mail de confirmation envoy\xe9. V\xe9rifiez votre bo\xeete de r\xe9ception et vos spams.","E-mail di conferma inviata. Controlla la posta in arrivo e lo spam.","E-mail de confirma\xe7\xe3o enviado. Verifique a caixa de entrada e o spam.","\u78ba\u8a8d\u30e1\u30fc\u30eb\u3092\u9001\u4fe1\u3057\u307e\u3057\u305f\u3002\u53d7\u4fe1\u30c8\u30ec\u30a4\u3068\u8ff7\u60d1\u30e1\u30fc\u30eb\u3092\u3054\u78ba\u8a8d\u304f\u3060\u3055\u3044\u3002"],t.s)
A.CQ=s(["Alle \xfcbrigen Belohnungen abgedeckt","Todas las recompensas restantes cubiertas","Toutes les r\xe9compenses restantes sont couvertes","Tutte le ricompense rimanenti sono coperte","Todas as recompensas restantes est\xe3o cobertas","\u6b8b\u308a\u306e\u5831\u916c\u306f\u3059\u3079\u3066\u78ba\u4fdd\u6e08\u307f"],t.s)
A.mA=s(["Sammlungsfortschritt","Progreso de la colecci\xf3n","Progression de la collection","Progresso della collezione","Progresso da cole\xe7\xe3o","\u30b3\u30ec\u30af\u30b7\u30e7\u30f3\u9032\u6357"],t.s)
A.IK=s(["unge\xf6ffnete Truhen","cofres sin abrir","coffres non ouverts","forzieri non aperti","ba\xfas fechados","\u500b\u306e\u672a\u958b\u5c01\u5b9d\u7bb1"],t.s)
A.Jf=s(["Aktuelle Portr\xe4tchancen","Probabilidades actuales de retrato","Chances actuelles de portrait","Probabilit\xe0 attuali dei ritratti","Probabilidades atuais de retrato","\u73fe\u5728\u306e\u8096\u50cf\u78ba\u7387"],t.s)
A.rD=s(["Tippe auf ein Ei, um seinen Hinweis und die Aktionen zu sehen.","Toca un huevo para ver su pista y sus acciones.","Touchez un \u0153uf pour voir son indice et ses actions.","Tocca un uovo per vedere il suo indizio e le azioni.","Toque em um ovo para ver a pista e as a\xe7\xf5es.","\u5375\u3092\u30bf\u30c3\u30d7\u3059\u308b\u3068\u30d2\u30f3\u30c8\u3068\u64cd\u4f5c\u304c\u8868\u793a\u3055\u308c\u307e\u3059\u3002"],t.s)
A.Ae=s(["Ei","huevo","\u0153uf","uovo","ovo","\u500b\u306e\u5375"],t.s)
A.vH=s(["Eier","huevos","\u0153ufs","uova","ovos","\u500b\u306e\u5375"],t.s)
A.Jo=s(["Drachenreihenfolge \xe4ndern","Cambiar el orden de los dragones","Modifier l\u2019ordre des dragons","Cambia l\u2019ordine dei draghi","Alterar a ordem dos drag\xf5es","\u30c9\u30e9\u30b4\u30f3\u306e\u4e26\u3073\u9806\u3092\u5909\u66f4"],t.s)
A.Bi=s(["Name","Nombre","Nom","Nome","Nome","\u540d\u524d"],t.s)
A.KJ=s(["Erhalten","Recibido","Re\xe7u","Ricevuto","Recebido","\u5165\u624b\u65e5"],t.s)
A.Hj=s(["Seltenheit","Rareza","Raret\xe9","Rarit\xe0","Raridade","\u30ec\u30a2\u5ea6"],t.s)
A.BC=s(["Kompakte Liste anzeigen","Mostrar lista compacta","Afficher la liste compacte","Mostra elenco compatto","Mostrar lista compacta","\u30b3\u30f3\u30d1\u30af\u30c8\u30ea\u30b9\u30c8\u3092\u8868\u793a"],t.s)
A.In=s(["Galerie anzeigen","Mostrar galer\xeda","Afficher la galerie","Mostra galleria","Mostrar galeria","\u30ae\u30e3\u30e9\u30ea\u30fc\u3092\u8868\u793a"],t.s)
A.DN=s(["Tippe auf das Ei, um die Wartezeit pro Tippen um eine Sekunde zu verk\xfcrzen. Die letzte Sekunde l\xe4uft immer normal ab.","Toca el huevo para acortar la espera un segundo por toque. El \xfaltimo segundo siempre transcurre con normalidad.","Touchez l\u2019\u0153uf pour raccourcir l\u2019attente d\u2019une seconde \xe0 chaque fois. La derni\xe8re seconde se d\xe9roule toujours normalement.","Tocca l\u2019uovo per ridurre l\u2019attesa di un secondo a ogni tocco. L\u2019ultimo secondo scorre sempre normalmente.","Toque no ovo para reduzir a espera em um segundo por toque. O \xfaltimo segundo sempre passa normalmente.","\u5375\u3092\u30bf\u30c3\u30d7\u3059\u308b\u305f\u3073\u306b\u5f85\u3061\u6642\u9593\u304c1\u79d2\u77ed\u304f\u306a\u308a\u307e\u3059\u3002\u6700\u5f8c\u306e1\u79d2\u306f\u5fc5\u305a\u901a\u5e38\u3069\u304a\u308a\u30ab\u30a6\u30f3\u30c8\u30c0\u30a6\u30f3\u3057\u307e\u3059\u3002"],t.s)
A.pM=s(["Tippe auf das Starter-Ei, um den Timer um eine Sekunde zu verk\xfcrzen","Toca el huevo inicial para acortar el temporizador un segundo","Touchez l\u2019\u0153uf de d\xe9part pour raccourcir le minuteur d\u2019une seconde","Tocca l\u2019uovo iniziale per accorciare il timer di un secondo","Toque no ovo inicial para reduzir o temporizador em um segundo","\u30b9\u30bf\u30fc\u30bf\u30fc\u30a8\u30c3\u30b0\u3092\u30bf\u30c3\u30d7\u3057\u3066\u30bf\u30a4\u30de\u30fc\u30921\u79d2\u77ed\u7e2e"],t.s)
A.yI=s(["Hier gekaufte Relikte sind nicht handelbar. Im Spiel gefundene Relikte bleiben handelbar. Du kannst beliebig viele kaufen.","Las reliquias compradas aqu\xed no se pueden intercambiar. Las encontradas durante el juego s\xed siguen siendo intercambiables. Puedes comprar todas las que quieras.","Les reliques achet\xe9es ici ne sont pas \xe9changeables. Celles trouv\xe9es en jouant restent \xe9changeables. Vous pouvez en acheter autant que vous voulez.","Le reliquie acquistate qui non sono scambiabili. Quelle trovate durante il gioco restano scambiabili. Puoi acquistarne quante ne vuoi.","As rel\xedquias compradas aqui n\xe3o s\xe3o negoci\xe1veis. As encontradas durante o jogo continuam negoci\xe1veis. Voc\xea pode comprar quantas quiser.","\u3053\u3053\u3067\u8cfc\u5165\u3057\u305f\u30ec\u30ea\u30c3\u30af\u306f\u4ea4\u63db\u3067\u304d\u307e\u305b\u3093\u3002\u30b2\u30fc\u30e0\u3067\u5165\u624b\u3057\u305f\u30ec\u30ea\u30c3\u30af\u306f\u5f15\u304d\u7d9a\u304d\u4ea4\u63db\u3067\u304d\u307e\u3059\u3002\u8cfc\u5165\u6570\u306b\u5236\u9650\u306f\u3042\u308a\u307e\u305b\u3093\u3002"],t.s)
A.yM=s(["Ein Spezialabenteuer ist erschienen","Ha aparecido una Aventura especial","Une Aventure sp\xe9ciale est apparue","\xc8 apparsa un\u2019Avventura speciale","Uma Aventura especial apareceu","\u30b9\u30da\u30b7\u30e3\u30eb\u30a2\u30c9\u30d9\u30f3\u30c1\u30e3\u30fc\u304c\u51fa\u73fe\u3057\u307e\u3057\u305f"],t.s)
A.v7=s(["Eine sanfte goldene W\xe4rme umgibt dieses Ei, als tr\xfcge es einen Wunsch f\xfcr einen ganz besonderen Menschen.","Una suave calidez dorada rodea este huevo, como si llevara un deseo para alguien realmente especial.","Une douce chaleur dor\xe9e entoure cet \u0153uf, comme s\u2019il portait un v\u0153u destin\xe9 \xe0 une personne vraiment sp\xe9ciale.","Un dolce calore dorato avvolge questo uovo, come se custodisse un desiderio per una persona davvero speciale.","Um suave calor dourado envolve este ovo, como se carregasse um desejo para algu\xe9m realmente especial.","\u3053\u306e\u5375\u306b\u306f\u3001\u304b\u3051\u304c\u3048\u306e\u306a\u3044\u8ab0\u304b\u3078\u306e\u9858\u3044\u3092\u5bbf\u3059\u3088\u3046\u306a\u3001\u512a\u3057\u3044\u9ec4\u91d1\u306e\u306c\u304f\u3082\u308a\u304c\u6b8b\u3063\u3066\u3044\u307e\u3059\u3002"],t.s)
A.vb=s(["Alle Expertisen","Todas las pericias","Toutes les expertises","Tutte le competenze","Todas as especialidades","\u3059\u3079\u3066\u306e\u5c02\u9580\u80fd\u529b"],t.s)
A.BP=s(["Reiseverk\xfcrzung","Reducci\xf3n del viaje","R\xe9duction du voyage","Riduzione del viaggio","Redu\xe7\xe3o da jornada","\u65c5\u7a0b\u306e\u77ed\u7e2e"],t.s)
A.oF=s(["Macht + Arkana + Geist: Jeder gemeinsame Punkt verk\xfcrzt um 1 Stunde (mindestens 1 Tag).","Poder + Arcana + Esp\xedritu: cada punto combinado reduce 1 hora (m\xednimo 1 d\xeda).","Puissance + Arcane + Esprit : chaque point cumul\xe9 retire 1 heure (minimum 1 jour).","Forza + Arcano + Spirito: ogni punto combinato riduce di 1 ora (minimo 1 giorno).","Poder + Arcana + Esp\xedrito: cada ponto combinado reduz 1 hora (m\xednimo de 1 dia).","\u30de\u30a4\u30c8\uff0b\u30a2\u30eb\u30ab\u30ca\uff0b\u30b9\u30d4\u30ea\u30c3\u30c8\uff1a\u5408\u8a081\u30dd\u30a4\u30f3\u30c8\u3054\u3068\u306b1\u6642\u9593\u77ed\u7e2e\uff08\u6700\u77ed1\u65e5\uff09\u3002"],t.s)
A.L2=s(["Garantierte Spezialtruhe","Cofre especial garantizado","Coffre sp\xe9cial garanti","Forziere speciale garantito","Ba\xfa especial garantido","\u30b9\u30da\u30b7\u30e3\u30eb\u30c1\u30a7\u30b9\u30c8\u78ba\u5b9a"],t.s)
A.zd=s(["269 M\xfcnzen, 10 Edelsteine und ein Spezial-Ei mit einem Eventdrachen.","269 monedas, 10 gemas y un Huevo especial con un drag\xf3n del evento.","269 pi\xe8ces, 10 gemmes et un \u0152uf sp\xe9cial contenant un dragon d\u2019\xe9v\xe9nement.","269 monete, 10 gemme e un Uovo speciale con un drago dell\u2019evento.","269 moedas, 10 gemas e um Ovo especial com um drag\xe3o do evento.","269\u30b3\u30a4\u30f3\u300110\u30b8\u30a7\u30e0\u3001\u30a4\u30d9\u30f3\u30c8\u30c9\u30e9\u30b4\u30f3\u5165\u308a\u306e\u30b9\u30da\u30b7\u30e3\u30eb\u30a8\u30c3\u30b0\u3002"],t.s)
A.Fk=s(["Garantiertes Relikt","Reliquia garantizada","Relique garantie","Reliquia garantita","Rel\xedquia garantida","\u30ec\u30ea\u30c3\u30af\u78ba\u5b9a"],t.s)
A.AN=s(["1 zuf\xe4lliges Relikt; welches es ist, bleibt bis zum Abholen eine \xdcberraschung.","1 reliquia aleatoria; cu\xe1l ser\xe1 seguir\xe1 siendo una sorpresa hasta reclamarla.","1 relique al\xe9atoire ; son identit\xe9 reste une surprise jusqu\u2019\xe0 sa r\xe9cup\xe9ration.","1 reliquia casuale; quale sar\xe0 resta una sorpresa fino alla riscossione.","1 rel\xedquia aleat\xf3ria; qual ser\xe1 continua sendo surpresa at\xe9 o resgate.","\u30e9\u30f3\u30c0\u30e0\u306a\u30ec\u30ea\u30c3\u30af1\u500b\u3002\u53d7\u3051\u53d6\u308b\u307e\u3067\u4e2d\u8eab\u306f\u79d8\u5bc6\u3067\u3059\u3002"],t.s)
A.zq=s(["Garantierte Musiktruhe","Cofre de m\xfasica garantizado","Coffre musical garanti","Forziere musicale garantito","Ba\xfa de m\xfasica garantido","\u30df\u30e5\u30fc\u30b8\u30c3\u30af\u30c1\u30a7\u30b9\u30c8\u78ba\u5b9a"],t.s)
A.AB=s(["1 Musiktruhe, deren Inhalt erst beim \xd6ffnen bestimmt wird.","1 Cofre de m\xfasica, cuyo contenido se decide solo al abrirlo.","1 Coffre musical, dont le contenu est tir\xe9 uniquement \xe0 l\u2019ouverture.","1 Forziere musicale, estratto solo quando lo apri.","1 Ba\xfa de m\xfasica, sorteado somente quando voc\xea o abre.","\u30df\u30e5\u30fc\u30b8\u30c3\u30af\u30c1\u30a7\u30b9\u30c81\u500b\u3002\u958b\u3051\u305f\u6642\u306b\u3060\u3051\u62bd\u9078\u3055\u308c\u307e\u3059\u3002"],t.s)
A.mY=s(["1 zuf\xe4lliges Relikt; das genaue Relikt bleibt eine \xdcberraschung.","1 reliquia aleatoria; la reliquia exacta sigue siendo una sorpresa.","1 relique al\xe9atoire ; la relique exacte reste une surprise.","1 reliquia casuale; la reliquia esatta resta una sorpresa.","1 rel\xedquia aleat\xf3ria; a rel\xedquia exata continua sendo surpresa.","\u30e9\u30f3\u30c0\u30e0\u306a\u30ec\u30ea\u30c3\u30af1\u500b\u3002\u3069\u308c\u304b\u306f\u307e\u3060\u79d8\u5bc6\u3067\u3059\u3002"],t.s)
A.ID=s(["1 Musiktruhe, deren Inhalt beim \xd6ffnen bestimmt wird.","1 Cofre de m\xfasica, cuyo contenido se decide al abrirlo.","1 Coffre musical, dont le contenu est tir\xe9 \xe0 l\u2019ouverture.","1 Forziere musicale, estratto quando viene aperto.","1 Ba\xfa de m\xfasica, sorteado quando \xe9 aberto.","\u30df\u30e5\u30fc\u30b8\u30c3\u30af\u30c1\u30a7\u30b9\u30c81\u500b\u3002\u958b\u5c01\u6642\u306b\u62bd\u9078\u3055\u308c\u307e\u3059\u3002"],t.s)
A.qF=s(["Spezial-Ei","Huevo especial","\u0152uf sp\xe9cial","Uovo speciale","Ovo especial","\u30b9\u30da\u30b7\u30e3\u30eb\u30a8\u30c3\u30b0"],t.s)
A.B5=s(["Spezialevents","Eventos especiales","\xc9v\xe9nements sp\xe9ciaux","Eventi speciali","Eventos especiais","\u30b9\u30da\u30b7\u30e3\u30eb\u30a4\u30d9\u30f3\u30c8"],t.s)
A.BF=s(["Verf\xfcgbar f\xfcr","Disponible durante","Disponible pendant","Disponibile per","Dispon\xedvel por","\u6b8b\u308a\u6642\u9593"],t.s)
A.zy=s(["Wenn ein Spezialabenteuer verf\xfcgbar wird.","Cuando una Aventura especial est\xe9 disponible.","Lorsqu\u2019une Aventure sp\xe9ciale devient disponible.","Quando diventa disponibile un\u2019Avventura speciale.","Quando uma Aventura especial fica dispon\xedvel.","\u30b9\u30da\u30b7\u30e3\u30eb\u30a2\u30c9\u30d9\u30f3\u30c1\u30e3\u30fc\u304c\u5229\u7528\u53ef\u80fd\u306b\u306a\u3063\u305f\u6642\u3002"],t.s)
A.Bx=s(["Noch keine Eier in deinem Inventar.","Todav\xeda no hay huevos en tu inventario.","Aucun \u0153uf dans votre inventaire pour le moment.","Non ci sono ancora uova nel tuo inventario.","Ainda n\xe3o h\xe1 ovos no seu invent\xe1rio.","\u30a4\u30f3\u30d9\u30f3\u30c8\u30ea\u306b\u306f\u307e\u3060\u5375\u304c\u3042\u308a\u307e\u305b\u3093\u3002"],t.s)
A.I6=s(["10 \xf6ffnen","Abrir 10","Ouvrir 10","Apri 10","Abrir 10","10\u500b\u958b\u3051\u308b"],t.s)
A.Bu=s(["In deinem Inventar warten keine Eier.","No hay huevos esperando en tu inventario.","Aucun \u0153uf n\u2019attend dans votre inventaire.","Non ci sono uova in attesa nel tuo inventario.","N\xe3o h\xe1 ovos esperando no seu invent\xe1rio.","\u30a4\u30f3\u30d9\u30f3\u30c8\u30ea\u306b\u5f85\u6a5f\u4e2d\u306e\u5375\u306f\u3042\u308a\u307e\u305b\u3093\u3002"],t.s)
A.qy=s(["W\xe4hle ein Ei","Elige un huevo","Choisir un \u0153uf","Scegli un uovo","Escolha um ovo","\u5375\u3092\u9078\u3076"],t.s)
A.Jb=s(["Neuer Titel","Nuevo t\xedtulo","Nouveau titre","Nuovo titolo","Novo t\xedtulo","\u65b0\u3057\u3044\u79f0\u53f7"],t.s)
A.kv=s(["Ein goldener Geburtstagswunsch f\xfcr eine wundervolle Frau, deren G\xfcte den Haven erhellt.","Un deseo dorado de cumplea\xf1os para una mujer maravillosa cuya bondad ilumina el Haven.","Un v\u0153u d\u2019anniversaire dor\xe9 pour une femme merveilleuse dont la bont\xe9 illumine le Haven.","Un augurio di compleanno dorato per una donna meravigliosa la cui gentilezza illumina l\u2019Haven.","Um desejo dourado de anivers\xe1rio para uma mulher maravilhosa cuja bondade ilumina o Haven.","\u512a\u3057\u3055\u3067\u30d8\u30a4\u30f4\u30f3\u3092\u7167\u3089\u3059\u7d20\u6575\u306a\u5973\u6027\u3078\u8d08\u308b\u3001\u9ec4\u91d1\u306e\u8a95\u751f\u65e5\u306e\u9858\u3044\u3002"],t.s)
A.Ml=new B.u(A.Op,[A.H1,A.kh,A.Cw,A.tX,A.u7,A.va,A.K8,A.JO,A.CR,A.m6,A.Cq,A.xP,A.ka,A.vt,A.lm,A.lR,A.l8,A.m7,A.IY,A.nG,A.J5,A.AU,A.rO,A.Aj,A.my,A.xT,A.ze,A.EM,A.Io,A.lf,A.Aw,A.KL,A.lh,A.kR,A.ps,A.uU,A.D7,A.J7,A.mN,A.Ju,A.pW,A.wA,A.ol,A.xj,A.qX,A.y3,A.Iw,A.Dd,A.Jz,A.k8,A.Cf,A.Lb,A.nO,A.tS,A.lH,A.HG,A.AT,A.qE,A.AO,A.J2,A.r9,A.mS,A.kP,A.un,A.o9,A.C2,A.Le,A.Do,A.Dl,A.kL,A.KO,A.vs,A.kO,A.lw,A.uC,A.zL,A.p6,A.Az,A.yU,A.JL,A.CY,A.rM,A.kN,A.HZ,A.Fl,A.uG,A.GE,A.lC,A.JG,A.rX,A.tb,A.Gx,A.A0,A.nE,A.En,A.HF,A.Lo,A.vJ,A.Jm,A.Js,A.jN,A.GD,A.Bf,A.Kr,A.yP,A.wB,A.qV,A.Bd,A.xE,A.Ew,A.nM,A.wo,A.Ib,A.CL,A.o6,A.yg,A.mI,A.BN,A.uN,A.nn,A.u3,A.zf,A.GB,A.uX,A.Ek,A.Eb,A.pD,A.AJ,A.o3,A.l7,A.kj,A.CM,A.oH,A.Hm,A.Hs,A.pv,A.kl,A.yE,A.oW,A.AA,A.IN,A.Hu,A.kM,A.Ks,A.lF,A.EU,A.nS,A.Ge,A.L0,A.qj,A.wT,A.Fc,A.oD,A.Jq,A.pH,A.k1,A.uW,A.zl,A.qI,A.vp,A.Em,A.Ho,A.kK,A.kz,A.uu,A.Ab,A.n8,A.wk,A.K_,A.vj,A.vk,A.AM,A.AI,A.C0,A.AZ,A.x2,A.lD,A.Dj,A.Fq,A.vc,A.CG,A.nT,A.jT,A.IG,A.k_,A.rZ,A.D4,A.ki,A.t5,A.Fm,A.yN,A.zV,A.tD,A.o4,A.Eg,A.zx,A.w4,A.vu,A.Dr,A.mC,A.K4,A.CZ,A.EZ,A.yx,A.q1,A.yb,A.Lh,A.tI,A.Dc,A.wp,A.G_,A.z4,A.jU,A.rr,A.qi,A.Ln,A.IR,A.oM,A.H6,A.zK,A.Kg,A.nb,A.KV,A.nL,A.Bc,A.FG,A.pp,A.pR,A.rw,A.KC,A.nA,A.vX,A.A9,A.mm,A.Du,A.rx,A.Ad,A.mb,A.FA,A.mR,A.tV,A.nj,A.zm,A.HN,A.vl,A.Ki,A.yD,A.p1,A.oR,A.t9,A.ok,A.Ej,A.pj,A.w0,A.zz,A.JC,A.qx,A.tv,A.Go,A.jI,A.vh,A.Eo,A.oh,A.wZ,A.rG,A.wf,A.o7,A.r5,A.Gm,A.A1,A.uK,A.Ci,A.KM,A.J_,A.rb,A.L4,A.qS,A.nw,A.AC,A.E3,A.nk,A.F1,A.Bz,A.l5,A.tg,A.qA,A.B9,A.yt,A.Ao,A.kx,A.xi,A.E1,A.zb,A.kF,A.FF,A.G0,A.JW,A.J3,A.A7,A.oL,A.kD,A.wR,A.oC,A.Cu,A.tn,A.J6,A.x0,A.H7,A.lP,A.Lu,A.tO,A.zk,A.xg,A.q_,A.F9,A.wO,A.lE,A.wX,A.uO,A.pA,A.G3,A.Jy,A.Jv,A.HJ,A.Hk,A.ro,A.wg,A.zU,A.rB,A.xx,A.Kk,A.jH,A.HL,A.AH,A.qJ,A.tu,A.Aq,A.Dp,A.xq,A.tQ,A.Lm,A.Kd,A.kI,A.Er,A.Gr,A.r4,A.tR,A.BU,A.Af,A.ws,A.wm,A.pl,A.Ig,A.yX,A.BT,A.kS,A.vf,A.BB,A.Ll,A.la,A.Fj,A.GW,A.yu,A.wq,A.K0,A.Cc,A.yV,A.kG,A.FW,A.lS,A.li,A.CT,A.oZ,A.tN,A.wM,A.Cs,A.zt,A.yq,A.B_,A.Fh,A.kr,A.GA,A.vD,A.y5,A.u2,A.DE,A.q0,A.oo,A.IE,A.Dg,A.Lq,A.C_,A.Fb,A.mc,A.uo,A.lO,A.CX,A.yW,A.FC,A.D5,A.HM,A.A5,A.Ka,A.xs,A.AR,A.DD,A.HH,A.pn,A.q9,A.y1,A.Bp,A.Cz,A.oY,A.F6,A.C3,A.x7,A.E2,A.vx,A.JU,A.uD,A.IT,A.yj,A.HD,A.mG,A.p0,A.FR,A.lo,A.wY,A.vF,A.GH,A.x6,A.xG,A.mE,A.ms,A.tL,A.ng,A.I2,A.qP,A.kc,A.FQ,A.Br,A.Dq,A.q6,A.oa,A.wz,A.tW,A.t3,A.FD,A.me,A.m1,A.Hy,A.FT,A.Cv,A.L6,A.p5,A.kW,A.Ff,A.uY,A.py,A.BK,A.mx,A.CD,A.xY,A.yn,A.zh,A.u9,A.jW,A.n2,A.rc,A.q3,A.Ce,A.y7,A.zO,A.uh,A.L3,A.pk,A.xN,A.ul,A.Cy,A.xI,A.Hd,A.K3,A.zs,A.FN,A.Lj,A.tt,A.Fg,A.Ix,A.Ie,A.FM,A.mX,A.yc,A.Jx,A.J9,A.HQ,A.ln,A.GV,A.vY,A.rK,A.kf,A.kw,A.ob,A.Bn,A.HR,A.vA,A.qr,A.oA,A.xA,A.J0,A.K5,A.yS,A.rp,A.KZ,A.nH,A.pI,A.Ep,A.Kb,A.FB,A.rz,A.Bh,A.zM,A.Ia,A.Ky,A.vL,A.A2,A.tT,A.Lc,A.wh,A.KK,A.kA,A.zB,A.jS,A.p9,A.Ds,A.GQ,A.xZ,A.Il,A.Fv,A.vB,A.nm,A.Fx,A.FZ,A.xv,A.mM,A.Jr,A.rm,A.u4,A.Jj,A.rd,A.BO,A.Kn,A.qg,A.v_,A.Li,A.Kl,A.Ag,A.wx,A.yA,A.u8,A.IP,A.JA,A.JI,A.k5,A.u0,A.E0,A.DZ,A.tE,A.lz,A.r_,A.u1,A.rW,A.Jw,A.kb,A.zW,A.Cl,A.vV,A.DB,A.oQ,A.kQ,A.qD,A.CJ,A.CP,A.np,A.JH,A.Gj,A.yR,A.pb,A.mj,A.yT,A.Ei,A.v8,A.ui,A.nl,A.yF,A.m2,A.Jd,A.nP,A.oI,A.t6,A.xc,A.jP,A.l6,A.JX,A.K2,A.Ct,A.m3,A.mD,A.uy,A.xb,A.Fw,A.Kv,A.H5,A.Ap,A.Fp,A.r2,A.ta,A.Cj,A.th,A.wa,A.l1,A.xp,A.Av,A.pe,A.JJ,A.vS,A.or,A.oE,A.tr,A.nJ,A.EO,A.wc,A.vT,A.Fd,A.kq,A.HV,A.rJ,A.Fo,A.oG,A.kC,A.qO,A.vQ,A.Gk,A.I9,A.JF,A.DX,A.IU,A.G2,A.kt,A.J1,A.Gh,A.G1,A.Dt,A.kB,A.CU,A.DR,A.H_,A.lG,A.m_,A.t2,A.EX,A.Dz,A.Cx,A.L_,A.v0,A.yH,A.q8,A.t_,A.ti,A.k9,A.Cn,A.ub,A.Ck,A.yB,A.Bs,A.ch,A.Fs,A.qZ,A.um,A.ns,A.Kx,A.Bg,A.yy,A.FJ,A.Fn,A.y8,A.GO,A.I8,A.HA,A.wU,A.w2,A.kp,A.HP,A.ll,A.JS,A.jL,A.Cd,A.qB,A.vv,A.q5,A.DK,A.yw,A.xh,A.le,A.rI,A.zI,A.tH,A.jV,A.nz,A.Jl,A.k6,A.EG,A.CH,A.z3,A.Ai,A.wV,A.zF,A.oJ,A.pz,A.Ch,A.po,A.nB,A.qk,A.IJ,A.n9,A.wt,A.DW,A.k0,A.IB,A.r0,A.kV,A.qL,A.km,A.Hi,A.jO,A.Gl,A.xn,A.Lp,A.mn,A.qY,A.Jg,A.y2,A.vK,A.mK,A.kJ,A.KN,A.t8,A.uB,A.uT,A.IZ,A.wN,A.pK,A.lL,A.z_,A.F7,A.Ft,A.zH,A.uv,A.ni,A.uj,A.zD,A.I5,A.DV,A.ua,A.B3,A.ry,A.BZ,A.HS,A.uF,A.Lk,A.uz,A.B1,A.tK,A.G8,A.qG,A.yK,A.CF,A.IC,A.F4,A.ly,A.FV,A.qz,A.tk,A.op,A.zj,A.Fe,A.xf,A.Ex,A.Gy,A.ww,A.I_,A.xC,A.KD,A.CC,A.JP,A.pu,A.Ga,A.r3,A.rH,A.E4,A.JT,A.Lv,A.jJ,A.om,A.AK,A.A6,A.Ha,A.yd,A.Jk,A.xH,A.Hc,A.EK,A.vy,A.lr,A.GP,A.FP,A.A_,A.JY,A.ku,A.qo,A.rR,A.GN,A.kk,A.Is,A.BA,A.IV,A.JD,A.z7,A.yv,A.wH,A.ml,A.Hq,A.GS,A.ra,A.qc,A.C5,A.na,A.K1,A.nq,A.pL,A.mO,A.pO,A.rN,A.CQ,A.mA,A.IK,A.Jf,A.rD,A.Ae,A.vH,A.Jo,A.Bi,A.KJ,A.Hj,A.BC,A.In,A.DN,A.pM,A.yI,A.yM,A.v7,A.vb,A.BP,A.oF,A.L2,A.zd,A.Fk,A.AN,A.zq,A.AB,A.mY,A.ID,A.qF,A.B5,A.BF,A.zy,A.Bx,A.I6,A.Bu,A.qy,A.Jb,A.kv],t.M)
A.O_={Trials:0,"Dragon Trials":1,"Your dragon helps, but your performance decides the reward.":2,"The Trial gates are resting":3,"A new Trial appears at the next quarter-hour.":4,"Dismiss Trial":5,"No account record yet":6,"Account best":7,"No dragon is currently available for this Trial.":8,"Choose your Trial dragon":9,Best:10,"Higher Spirit makes the real collision box up to 10% smaller.":11,"Higher Might widens successful timing up to 15% and Perfect up to 5%.":12,"Higher Arcana keeps every demonstrated rune visible longer.":13,"This Trial is no longer available.":14,SCORE:15,BEST:16,"TRIAL COMPLETE":17,points:18,"Tap to flap":19,"Fly through every opening. Spirit subtly reduces your real hitbox.":20,"RECOVERING...":21,"CHASM \u2014 JUMP!":22,Mistakes:23,"ATTEMPTS LEFT":24,Combo:25,"Tap for the perfect hit":26,"Stop the moving marker in the center. Watch out for chasms.":27,"WATCH THE RUNES":28,"WEAVE THE SEQUENCE":29,"ARCANE SURGE":30,Sequence:31,Completed:32,"Tap to awaken the gate":33,"Watch each rune, then reproduce the complete sequence.":34,"Account Trial records":35,"Dragon Trial records":36,"Not set":37,"Cavern Flight":38,"Ruin Breaker":39,Runeweaver:40,"Thread the crystal cavern with instinct and control.":41,"Time every strike and shatter the ancient road.":42,"Remember the runes and awaken the sealed gate.":43,"Trial Rankings":44,"View Trial Rankings":45,"Conclave Trial Rankings":46,World:47,Friends:48,"The strongest published Keeper records worldwide.":49,"Compare your best score with your friends.":50,"Every scored Keeper in your Conclave.":51,"Rankings could not be loaded":52,"Try again":53,"No scores yet":54,"Complete this Trial to place the first score in this ranking.":55,You:56}
A.wG=s(["Drachenpr\xfcfungen","Pruebas de dragones","\xc9preuves draconiques","Prove dei draghi","Provas de drag\xe3o","\u30c9\u30e9\u30b4\u30f3\u8a66\u7df4"],t.s)
A.l0=s(["Dein Drache hilft, aber deine Leistung bestimmt die Belohnung.","Tu drag\xf3n ayuda, pero tu rendimiento determina la recompensa.","Votre dragon vous aide, mais votre performance d\xe9termine la r\xe9compense.","Il tuo drago ti aiuta, ma la tua prestazione determina la ricompensa.","Seu drag\xe3o ajuda, mas seu desempenho determina a recompensa.","\u30c9\u30e9\u30b4\u30f3\u306f\u52a9\u3051\u3066\u304f\u308c\u307e\u3059\u304c\u3001\u5831\u916c\u3092\u6c7a\u3081\u308b\u306e\u306f\u3042\u306a\u305f\u306e\u8155\u524d\u3067\u3059\u3002"],t.s)
A.qH=s(["Die Pr\xfcfungstore ruhen","Las puertas de las Pruebas descansan","Les portes des \xc9preuves sont au repos","I portali delle Prove riposano","Os port\xf5es das Provas est\xe3o descansando","\u8a66\u7df4\u306e\u9580\u306f\u4f11\u606f\u4e2d\u3067\u3059"],t.s)
A.DU=s(["Zur n\xe4chsten Viertelstunde erscheint eine neue Pr\xfcfung.","En el pr\xf3ximo cuarto de hora aparecer\xe1 una nueva Prueba.","Une nouvelle \xc9preuve appara\xeet au prochain quart d\u2019heure.","Al prossimo quarto d\u2019ora apparir\xe0 una nuova Prova.","Uma nova Prova aparece no pr\xf3ximo quarto de hora.","\u6b21\u306e15\u5206\u533a\u5207\u308a\u306b\u65b0\u3057\u3044\u8a66\u7df4\u304c\u73fe\u308c\u307e\u3059\u3002"],t.s)
A.KU=s(["Pr\xfcfung verwerfen","Descartar Prueba","Ignorer l\u2019\xc9preuve","Scarta Prova","Dispensar Prova","\u8a66\u7df4\u3092\u7834\u68c4"],t.s)
A.H4=s(["Noch kein Kontorekord","A\xfan no hay r\xe9cord de la cuenta","Aucun record de compte pour le moment","Nessun record dell\u2019account","Nenhum recorde da conta ainda","\u30a2\u30ab\u30a6\u30f3\u30c8\u8a18\u9332\u306f\u307e\u3060\u3042\u308a\u307e\u305b\u3093"],t.s)
A.oy=s(["Kontobestleistung","Mejor marca de la cuenta","Meilleur score du compte","Record dell\u2019account","Melhor marca da conta","\u30a2\u30ab\u30a6\u30f3\u30c8\u30d9\u30b9\u30c8"],t.s)
A.G7=s(["Derzeit ist kein Drache f\xfcr diese Pr\xfcfung verf\xfcgbar.","No hay ning\xfan drag\xf3n disponible para esta Prueba.","Aucun dragon n\u2019est actuellement disponible pour cette \xc9preuve.","Nessun drago \xe8 disponibile per questa Prova.","Nenhum drag\xe3o est\xe1 dispon\xedvel para esta Prova.","\u73fe\u5728\u3053\u306e\u8a66\u7df4\u306b\u53c2\u52a0\u3067\u304d\u308b\u30c9\u30e9\u30b4\u30f3\u306f\u3044\u307e\u305b\u3093\u3002"],t.s)
A.u6=s(["W\xe4hle deinen Pr\xfcfungsdrachen","Elige tu drag\xf3n para la Prueba","Choisissez votre dragon pour l\u2019\xc9preuve","Scegli il drago per la Prova","Escolha seu drag\xe3o para a Prova","\u8a66\u7df4\u306b\u6311\u3080\u30c9\u30e9\u30b4\u30f3\u3092\u9078\u629e"],t.s)
A.l_=s(["Bestleistung","Mejor","Meilleur","Migliore","Melhor","\u30d9\u30b9\u30c8"],t.s)
A.xF=s(["H\xf6herer Spirit verkleinert die echte Kollisionsbox um bis zu 10 %.","Un Spirit m\xe1s alto reduce la zona de colisi\xf3n real hasta un 10 %.","Un Spirit sup\xe9rieur r\xe9duit la zone de collision r\xe9elle jusqu\u2019\xe0 10 %.","Uno Spirit pi\xf9 alto riduce la vera area di collisione fino al 10%.","Spirit mais alto reduz a \xe1rea de colis\xe3o real em at\xe9 10%.","Spirit\u304c\u9ad8\u3044\u307b\u3069\u5b9f\u969b\u306e\u5f53\u305f\u308a\u5224\u5b9a\u304c\u6700\u592710%\u5c0f\u3055\u304f\u306a\u308a\u307e\u3059\u3002"],t.s)
A.ED=s(["H\xf6herer Might erweitert das Erfolgsfenster um bis zu 15 % und Perfekt um bis zu 5 %.","Un Might m\xe1s alto ampl\xeda la zona de acierto hasta un 15 % y la Perfecta hasta un 5 %.","Un Might sup\xe9rieur \xe9largit la zone de r\xe9ussite jusqu\u2019\xe0 15 % et la zone Parfaite jusqu\u2019\xe0 5 %.","Uno Might pi\xf9 alto amplia la zona di successo fino al 15% e quella Perfetta fino al 5%.","Might mais alto amplia a zona de sucesso em at\xe9 15% e a Perfeita em at\xe9 5%.","Might\u304c\u9ad8\u3044\u307b\u3069\u6210\u529f\u7bc4\u56f2\u304c\u6700\u592715%\u3001Perfect\u7bc4\u56f2\u304c\u6700\u59275%\u5e83\u304c\u308a\u307e\u3059\u3002"],t.s)
A.D9=s(["H\xf6here Arcana l\xe4sst jede gezeigte Rune l\xe4nger sichtbar.","Una Arcana m\xe1s alta mantiene visible cada runa durante m\xe1s tiempo.","Une Arcana sup\xe9rieure laisse chaque rune affich\xe9e plus longtemps.","Un\u2019Arcana pi\xf9 alta mantiene visibile pi\xf9 a lungo ogni runa mostrata.","Arcana mais alta mant\xe9m cada runa demonstrada vis\xedvel por mais tempo.","Arcana\u304c\u9ad8\u3044\u307b\u3069\u63d0\u793a\u3055\u308c\u305f\u30eb\u30fc\u30f3\u304c\u9577\u304f\u8868\u793a\u3055\u308c\u307e\u3059\u3002"],t.s)
A.mr=s(["Diese Pr\xfcfung ist nicht mehr verf\xfcgbar.","Esta Prueba ya no est\xe1 disponible.","Cette \xc9preuve n\u2019est plus disponible.","Questa Prova non \xe8 pi\xf9 disponibile.","Esta Prova n\xe3o est\xe1 mais dispon\xedvel.","\u3053\u306e\u8a66\u7df4\u306f\u3082\u3046\u5229\u7528\u3067\u304d\u307e\u305b\u3093\u3002"],t.s)
A.nt=s(["PUNKTE","PUNTOS","SCORE","PUNTI","PONTOS","\u30b9\u30b3\u30a2"],t.s)
A.o8=s(["BESTLEISTUNG","MEJOR","MEILLEUR","MIGLIORE","MELHOR","\u30d9\u30b9\u30c8"],t.s)
A.Dn=s(["PR\xdcFUNG ABGESCHLOSSEN","PRUEBA COMPLETADA","\xc9PREUVE TERMIN\xc9E","PROVA COMPLETATA","PROVA CONCLU\xcdDA","\u8a66\u7df4\u5b8c\u4e86"],t.s)
A.pB=s(["Punkte","puntos","points","punti","pontos","\u30dd\u30a4\u30f3\u30c8"],t.s)
A.rL=s(["Tippe zum Fl\xfcgelschlag","Toca para aletear","Touchez pour battre des ailes","Tocca per battere le ali","Toque para bater as asas","\u30bf\u30c3\u30d7\u3057\u3066\u7fbd\u3070\u305f\u304f"],t.s)
A.Dy=s(["Fliege durch jede \xd6ffnung. Spirit verkleinert deine echte Trefferzone ein wenig.","Vuela por cada abertura. Spirit reduce sutilmente tu zona de impacto real.","Volez \xe0 travers chaque ouverture. Spirit r\xe9duit l\xe9g\xe8rement votre vraie zone de collision.","Vola attraverso ogni apertura. Spirit riduce leggermente la tua vera area di collisione.","Voe por cada abertura. Spirit reduz sutilmente sua \xe1rea de colis\xe3o real.","\u3059\u3079\u3066\u306e\u9699\u9593\u3092\u98db\u3073\u629c\u3051\u307e\u3057\u3087\u3046\u3002Spirit\u306f\u5b9f\u969b\u306e\u5f53\u305f\u308a\u5224\u5b9a\u3092\u5c11\u3057\u5c0f\u3055\u304f\u3057\u307e\u3059\u3002"],t.s)
A.oe=s(["ERHOLUNG...","RECUPERANDO...","R\xc9CUP\xc9RATION...","RECUPERO...","RECUPERANDO...","\u56de\u5fa9\u4e2d..."],t.s)
A.Cr=s(["ABGRUND \u2014 SPRING!","\xa1BARRANCO \u2014 SALTA!","GOUFFRE \u2014 SAUTEZ !","BARATRO \u2014 SALTA!","ABISMO \u2014 PULE!","\u5948\u843d \u2014 \u30b8\u30e3\u30f3\u30d7\uff01"],t.s)
A.BY=s(["Fehler","Fallos","Erreurs","Errori","Erros","\u30df\u30b9"],t.s)
A.v2=s(["VERSUCHE \xdcBRIG","INTENTOS RESTANTES","ESSAIS RESTANTS","TENTATIVI RIMASTI","TENTATIVAS RESTANTES","\u6b8b\u308a\u56de\u6570"],t.s)
A.As=s(["Kombo","Combo","Combo","Combo","Combo","\u30b3\u30f3\u30dc"],t.s)
A.p8=s(["Tippe f\xfcr den perfekten Treffer","Toca para dar el golpe perfecto","Touchez pour le coup parfait","Tocca per il colpo perfetto","Toque para o golpe perfeito","\u30bf\u30c3\u30d7\u3057\u3066\u5b8c\u74a7\u306a\u4e00\u6483"],t.s)
A.n3=s(["Stoppe den beweglichen Marker in der Mitte. Achte auf Abgr\xfcnde.","Det\xe9n el marcador m\xf3vil en el centro. Cuidado con los barrancos.","Arr\xeatez le marqueur mobile au centre. Attention aux gouffres.","Ferma l\u2019indicatore mobile al centro. Attento ai baratri.","Pare o marcador m\xf3vel no centro. Cuidado com os abismos.","\u52d5\u304f\u30de\u30fc\u30ab\u30fc\u3092\u4e2d\u592e\u3067\u6b62\u3081\u307e\u3057\u3087\u3046\u3002\u5948\u843d\u306b\u6ce8\u610f\u3057\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.DP=s(["BEOBACHTE DIE RUNEN","OBSERVA LAS RUNAS","OBSERVEZ LES RUNES","OSSERVA LE RUNE","OBSERVE AS RUNAS","\u30eb\u30fc\u30f3\u3092\u898b\u3088\u3046"],t.s)
A.yz=s(["WEBE DIE SEQUENZ","TEJE LA SECUENCIA","TISSEZ LA S\xc9QUENCE","INTRECCIA LA SEQUENZA","TE\xc7A A SEQU\xcaNCIA","\u30b7\u30fc\u30b1\u30f3\u30b9\u3092\u7d21\u3054\u3046"],t.s)
A.r7=s(["MAGISCHER SCHUB","OLEADA ARCANA","D\xc9FERLANTE ARCANIQUE","IMPULSO ARCANO","SURTO ARCANO","\u30a2\u30fc\u30b1\u30a4\u30f3\u30b5\u30fc\u30b8"],t.s)
A.Fa=s(["Sequenz","Secuencia","S\xe9quence","Sequenza","Sequ\xeancia","\u30b7\u30fc\u30b1\u30f3\u30b9"],t.s)
A.t4=s(["Abgeschlossen","Completadas","Termin\xe9es","Completate","Conclu\xeddas","\u5b8c\u4e86"],t.s)
A.EA=s(["Tippe, um das Tor zu erwecken","Toca para despertar la puerta","Touchez pour \xe9veiller la porte","Tocca per risvegliare il portale","Toque para despertar o portal","\u30bf\u30c3\u30d7\u3057\u3066\u9580\u3092\u76ee\u899a\u3081\u3055\u305b\u308b"],t.s)
A.J4=s(["Beobachte jede Rune und wiederhole dann die vollst\xe4ndige Sequenz.","Observa cada runa y reproduce despu\xe9s la secuencia completa.","Observez chaque rune, puis reproduisez la s\xe9quence compl\xe8te.","Osserva ogni runa, poi riproduci la sequenza completa.","Observe cada runa e depois reproduza a sequ\xeancia completa.","\u5404\u30eb\u30fc\u30f3\u3092\u898b\u3066\u304b\u3089\u3001\u5b8c\u5168\u306a\u30b7\u30fc\u30b1\u30f3\u30b9\u3092\u518d\u73fe\u3057\u3066\u304f\u3060\u3055\u3044\u3002"],t.s)
A.Gp=s(["Pr\xfcfungsrekorde des Kontos","R\xe9cords de Pruebas de la cuenta","Records d\u2019\xc9preuves du compte","Record delle Prove dell\u2019account","Recordes de Provas da conta","\u30a2\u30ab\u30a6\u30f3\u30c8\u306e\u8a66\u7df4\u8a18\u9332"],t.s)
A.xS=s(["Pr\xfcfungsrekorde des Drachen","R\xe9cords de Pruebas del drag\xf3n","Records d\u2019\xc9preuves du dragon","Record delle Prove del drago","Recordes de Provas do drag\xe3o","\u30c9\u30e9\u30b4\u30f3\u306e\u8a66\u7df4\u8a18\u9332"],t.s)
A.Cp=s(["Nicht gesetzt","Sin marca","Non d\xe9fini","Non impostato","N\xe3o definido","\u672a\u8a2d\u5b9a"],t.s)
A.JK=s(["H\xf6hlenflug","Vuelo cavernario","Vol de la caverne","Volo nella caverna","Voo na caverna","\u6d1e\u7a9f\u98db\u884c"],t.s)
A.zA=s(["Ruinenbrecher","Romperruinas","Briseur de ruines","Spezzarovine","Quebra-ru\xednas","\u907a\u8de1\u30d6\u30ec\u30a4\u30ab\u30fc"],t.s)
A.pV=s(["Runenweber","Tejerrunas","Tisseur de runes","Tessirune","Tecel\xe3o de runas","\u30eb\u30fc\u30f3\u30a6\u30a3\u30fc\u30d0\u30fc"],t.s)
A.Kp=s(["Durchquere die Kristallh\xf6hle mit Instinkt und Kontrolle.","Atraviesa la caverna de cristal con instinto y control.","Traversez la caverne de cristal avec instinct et ma\xeetrise.","Attraversa la caverna di cristallo con istinto e controllo.","Atravesse a caverna de cristal com instinto e controle.","\u672c\u80fd\u3068\u64cd\u4f5c\u3067\u30af\u30ea\u30b9\u30bf\u30eb\u6d1e\u7a9f\u3092\u98db\u3073\u629c\u3051\u3088\u3046\u3002"],t.s)
A.KT=s(["Passe jeden Schlag ab und zerschmettere den uralten Weg.","Calcula cada golpe y destroza el antiguo camino.","Synchronisez chaque frappe et brisez la voie antique.","Calcola ogni colpo e frantuma l\u2019antica via.","Acerte o tempo de cada golpe e destrua o caminho ancestral.","\u4e00\u6483\u3054\u3068\u306e\u30bf\u30a4\u30df\u30f3\u30b0\u3092\u5408\u308f\u305b\u3001\u53e4\u4ee3\u306e\u9053\u3092\u6253\u3061\u7815\u3053\u3046\u3002"],t.s)
A.nW=s(["Merke dir die Runen und erwecke das versiegelte Tor.","Recuerda las runas y despierta la puerta sellada.","M\xe9morisez les runes et \xe9veillez la porte scell\xe9e.","Ricorda le rune e risveglia il portale sigillato.","Lembre-se das runas e desperte o portal selado.","\u30eb\u30fc\u30f3\u3092\u899a\u3048\u3066\u5c01\u5370\u3055\u308c\u305f\u9580\u3092\u76ee\u899a\u3081\u3055\u305b\u3088\u3046\u3002"],t.s)
A.pY=s(["Pr\xfcfungsranglisten","Clasificaciones de pruebas","Classements des \xe9preuves","Classifiche delle prove","Classifica\xe7\xf5es das provas","\u8a66\u7df4\u30e9\u30f3\u30ad\u30f3\u30b0"],t.s)
A.nZ=s(["Pr\xfcfungsranglisten anzeigen","Ver clasificaciones de pruebas","Voir les classements des \xe9preuves","Vedi classifiche delle prove","Ver classifica\xe7\xf5es das provas","\u8a66\u7df4\u30e9\u30f3\u30ad\u30f3\u30b0\u3092\u898b\u308b"],t.s)
A.EI=s(["Konklave-Pr\xfcfungsranglisten","Clasificaciones de pruebas del C\xf3nclave","Classements des \xe9preuves du Conclave","Classifiche delle prove del Conclave","Classifica\xe7\xf5es das provas do Conclave","\u30b3\u30f3\u30af\u30ec\u30fc\u30d6\u8a66\u7df4\u30e9\u30f3\u30ad\u30f3\u30b0"],t.s)
A.n_=s(["Welt","Mundo","Monde","Mondo","Mundo","\u4e16\u754c"],t.s)
A.xa=s(["Freunde","Amigos","Amis","Amici","Amigos","\u30d5\u30ec\u30f3\u30c9"],t.s)
A.Lr=s(["Die st\xe4rksten ver\xf6ffentlichten H\xfcterrekorde weltweit.","Los mejores r\xe9cords publicados de Guardianes de todo el mundo.","Les meilleurs records de Gardiens publi\xe9s dans le monde.","I migliori record pubblicati dei Custodi nel mondo.","Os melhores recordes publicados de Guardi\xf5es do mundo.","\u4e16\u754c\u4e2d\u3067\u516c\u958b\u3055\u308c\u305f\u30ad\u30fc\u30d1\u30fc\u306e\u6700\u9ad8\u8a18\u9332\u3067\u3059\u3002"],t.s)
A.kY=s(["Vergleiche deinen Bestwert mit deinen Freunden.","Compara tu mejor puntuaci\xf3n con tus amigos.","Comparez votre meilleur score \xe0 celui de vos amis.","Confronta il tuo record con quello degli amici.","Compare sua melhor pontua\xe7\xe3o com a de seus amigos.","\u81ea\u5df1\u30d9\u30b9\u30c8\u3092\u30d5\u30ec\u30f3\u30c9\u3068\u6bd4\u8f03\u3057\u307e\u3059\u3002"],t.s)
A.Ic=s(["Jeder H\xfcter mit einem Ergebnis in deiner Konklave.","Todos los Guardianes con puntuaci\xf3n de tu C\xf3nclave.","Chaque Gardien ayant un score dans votre Conclave.","Ogni Custode con un punteggio nel tuo Conclave.","Todos os Guardi\xf5es com pontua\xe7\xe3o no seu Conclave.","\u30b3\u30f3\u30af\u30ec\u30fc\u30d6\u5185\u3067\u8a18\u9332\u3092\u6301\u3064\u5168\u30ad\u30fc\u30d1\u30fc\u3067\u3059\u3002"],t.s)
A.uZ=s(["Ranglisten konnten nicht geladen werden","No se pudieron cargar las clasificaciones","Impossible de charger les classements","Impossibile caricare le classifiche","N\xe3o foi poss\xedvel carregar as classifica\xe7\xf5es","\u30e9\u30f3\u30ad\u30f3\u30b0\u3092\u8aad\u307f\u8fbc\u3081\u307e\u305b\u3093\u3067\u3057\u305f"],t.s)
A.vP=s(["Erneut versuchen","Intentar de nuevo","R\xe9essayer","Riprova","Tentar novamente","\u3082\u3046\u4e00\u5ea6\u8a66\u3059"],t.s)
A.q4=s(["Noch keine Ergebnisse","A\xfan no hay puntuaciones","Aucun score pour le moment","Ancora nessun punteggio","Ainda n\xe3o h\xe1 pontua\xe7\xf5es","\u307e\u3060\u8a18\u9332\u304c\u3042\u308a\u307e\u305b\u3093"],t.s)
A.ql=s(["Schlie\xdfe diese Pr\xfcfung ab, um den ersten Wert in dieser Rangliste zu erzielen.","Completa esta prueba para registrar la primera puntuaci\xf3n de la clasificaci\xf3n.","Terminez cette \xe9preuve pour inscrire le premier score du classement.","Completa questa prova per registrare il primo punteggio in classifica.","Conclua esta prova para registrar a primeira pontua\xe7\xe3o da classifica\xe7\xe3o.","\u3053\u306e\u8a66\u7df4\u3092\u5b8c\u4e86\u3057\u3066\u3001\u30e9\u30f3\u30ad\u30f3\u30b0\u306b\u6700\u521d\u306e\u8a18\u9332\u3092\u6b8b\u3057\u307e\u3057\u3087\u3046\u3002"],t.s)
A.wy=s(["Du","T\xfa","Vous","Tu","Voc\xea","\u3042\u306a\u305f"],t.s)
A.Mm=new B.u(A.O_,[A.ch,A.wG,A.l0,A.qH,A.DU,A.KU,A.H4,A.oy,A.G7,A.u6,A.l_,A.xF,A.ED,A.D9,A.mr,A.nt,A.o8,A.Dn,A.pB,A.rL,A.Dy,A.oe,A.Cr,A.BY,A.v2,A.As,A.p8,A.n3,A.DP,A.yz,A.r7,A.Fa,A.t4,A.EA,A.J4,A.Gp,A.xS,A.Cp,A.JK,A.zA,A.pV,A.Kp,A.KT,A.nW,A.pY,A.nZ,A.EI,A.n_,A.xa,A.Lr,A.kY,A.Ic,A.uZ,A.vP,A.q4,A.ql,A.wy],t.M)
A.NW={golden_wings_chest_v1:0,witchlight_chest_v1:1,starlight_gift_chest_v1:2,firstlight_celebration_chest_v1:3,twinheart_keepsake_chest_v1:4,radiant_festival_chest_v1:5}
A.Rr=new B.c9("golden_wings_chest_v1","Golden Wings Chest",269,10,"golden_wings_egg_v1")
A.Ru=new B.c9("witchlight_chest_v1","Witchlight Chest",313,13,"witchlight_egg_v1")
A.Rp=new B.c9("starlight_gift_chest_v1","Starlight Gift Chest",250,12,"starlit_evergreen_egg_v1")
A.Rq=new B.c9("firstlight_celebration_chest_v1","Firstlight Celebration Chest",365,12,"turning_year_egg_v1")
A.Rt=new B.c9("twinheart_keepsake_chest_v1","Twinheart Keepsake Chest",214,14,"rosebound_egg_v1")
A.Rs=new B.c9("radiant_festival_chest_v1","Radiant Festival Chest",300,15,"truecolor_egg_v1")
A.bo=new B.u(A.NW,[A.Rr,A.Ru,A.Rp,A.Rq,A.Rt,A.Rs],B.W("u<d,c9>"))
A.Mn=new B.cU(0,"purchased")
A.Mo=new B.cU(1,"insufficientGems")
A.Mp=new B.cU(2,"collectionComplete")
A.NM=new B.cV(0,"purchased")
A.NN=new B.cV(1,"insufficientGems")
A.NO=new B.cV(2,"notAvailable")
A.NP=new B.ct(0,"revealed")
A.NQ=new B.ct(1,"notOwned")
A.NR=new B.ct(2,"dragonNotFound")
A.bp=new B.ct(3,"alreadyKnown")
A.OA=new B.cX(0,"purchased")
A.OB=new B.cX(1,"insufficientGems")
A.OC=new B.cX(2,"collectionComplete")
A.cy=new B.c2(0,"common")
A.OD=new B.c2(1,"rare")
A.OE=new B.c2(2,"veryRare")
A.cz=new B.c2(3,"legendary")
A.OF=new B.c2(4,"infernal")
A.OG=new B.c2(5,"mythical")
A.OH=new B.c3("portrait_supporter_founder",A.cz)
A.OI=new B.c4(0,"purchased")
A.OJ=new B.c4(1,"equipped")
A.OK=new B.c4(2,"insufficientCoins")
A.OL=new B.c4(3,"insufficientGems")
A.OM=new B.c4(4,"alreadyEquipped")
A.OX=new B.J(0.5,0.42)
A.OY=new B.J(0.5,0.82)
A.PJ=new B.J(0.28,0.34)
A.PQ=new B.J(0.23,0.32)
A.PT=new B.J(0.81,0.36)
A.PU=new B.J(0.77,0.32)
A.PV=new B.J(0.5,0.22)
A.PW=new B.J(0.23,0.78)
A.PX=new B.J(0.5,0.66)
A.PY=new B.J(0.2,0.34)
A.PZ=new B.J(0.8,0.35)
A.Q_=new B.J(0.14,0.38)
A.Q0=new B.J(0.5,0.27)
A.Q1=new B.J(0.88,0.7)
A.Q2=new B.J(0.5,0.3)
A.Q3=new B.J(0.12,0.7)
A.Q4=new B.J(0.86,0.38)
A.Q5=new B.J(0.5,0.4)
A.Q6=new B.J(0.5,0.24)
A.Q7=new B.J(0.72,0.34)
A.Q8=new B.J(0.29,0.77)
A.Q9=new B.J(0.19,0.36)
A.Qa=new B.J(0.5,0.28)
A.Qb=new B.J(0.5,0.67)
A.Qc=new B.J(0.8,0.34)
A.Qd=new B.J(0.66,0.34)
A.Qe=new B.J(0.84,0.73)
A.Qf=new B.J(0.17,0.67)
A.Qg=new B.J(0.2,0.35)
A.Qh=new B.J(0.77,0.78)
A.Qi=new B.J(0.34,0.34)
A.Qj=new B.J(0.83,0.67)
A.Qk=new B.J(0.71,0.77)
A.Ql=new B.J(0.73,0.8)
A.Qm=new B.J(0.32,0.39)
A.Qn=new B.J(0.5,0.63)
A.Qo=new B.J(0.5,0.74)
A.Qp=new B.J(0.5,0.8)
A.Qq=new B.J(0.5,0.34)
A.Qr=new B.J(0.27,0.8)
A.Qs=new B.J(0.68,0.39)
A.Qt=new B.J(0.16,0.73)
A.Qz=new B.cv(0,"unlocked")
A.QA=new B.cv(1,"insufficientCoins")
A.QB=new B.cv(2,"levelLocked")
A.QC=new B.cv(3,"alreadyUnlocked")
A.Oe={honey:0,copper:1,meadow:2}
A.QG=new B.T(A.Oe,3,t.O)
A.Oy={tiles:0,list:1}
A.QK=new B.T(A.Oy,2,t.O)
A.NZ={name:0,acquiredAt:1,rarity:2}
A.QL=new B.T(A.NZ,3,t.O)
A.O4={acquiredAt:0,hatchTime:1}
A.QN=new B.T(A.O4,2,t.O)
A.Ou={rewards:0,identities:1}
A.QP=new B.T(A.Ou,2,t.O)
A.O7={cavernFlight:0,ruinBreaker:1,runeweaver:2,witchlightWard:3,hollyfrostGiftforge:4,midnightChime:5,rosevowRelay:6,prismaticParade:7}
A.cI=new B.T(A.O7,8,t.O)
A.QT=new B.T(A.cw,8,t.O)
A.Od={runeRush:0,crystalChase:1,emberReflex:2,sigilMemory:3,scaleOrder:4,shadowMatch:5,breathBalance:6,cloudWeave:7,safeHoard:8,constellationTrace:9}
A.am=new B.T(A.Od,10,t.O)
A.NX={ocean:0,frost:1,cloud:2,sapphire:3}
A.QV=new B.T(A.NX,4,t.O)
A.Ok={gallery:0,compact:1}
A.QW=new B.T(A.Ok,2,t.O)
A.Oi={ember:0,sun:1}
A.QZ=new B.T(A.Oi,2,t.O)
A.RA=new B.d1(0,"purchased")
A.RB=new B.d1(1,"insufficientCoins")
A.RC=new B.d1(2,"collectionComplete")
A.RD=new B.cy(0,"built")
A.RE=new B.cy(1,"maximumReached")
A.RF=new B.cy(2,"insufficientCoins")
A.RG=new B.cy(3,"invalidRoom")
A.RP=new B.cc(0,"d")
A.RQ=new B.cc(1,"c")
A.RR=new B.cc(2,"b")
A.RS=new B.cc(3,"a")
A.RT=new B.cc(4,"s")
A.aV=new B.cc(5,"sPlus")
A.RU=B.bz("tH")
A.RV=B.bz("nq")
A.RW=B.bz("pR")
A.RX=B.bz("pS")
A.RY=B.bz("q4")
A.RZ=B.bz("q5")
A.S_=B.bz("q6")
A.S0=B.bz("I")
A.S1=B.bz("qz")
A.S2=B.bz("mV")
A.S3=B.bz("qA")
A.S4=B.bz("mW")
A.S5=new B.cf(0,"changed")
A.S6=new B.cf(1,"notOwned")
A.S7=new B.cf(2,"unsupportedAdventure")
A.S8=new B.cf(3,"adventureNotFound")
A.cM=new B.cf(4,"noCapacity")
A.S9=new B.bg(0,0,0)
A.Sa=new B.bg(10,1,0)
A.Sb=new B.bg(125,12,2)
A.Sc=new B.bg(20,1,0)
A.Sd=new B.bg(30,2,0)
A.Se=new B.bg(50,5,1)})();(function staticFields(){$.lz=null
$.bh=B.m([],t.hf)
$.nQ=null
$.no=null
$.nn=null
$.oA=null
$.ot=null
$.oE=null
$.lY=null
$.m6=null
$.na=null
$.lG=B.m([],B.W("v<G<I>?>"))
$.dK=null
$.eO=null
$.eP=null
$.n4=!1
$.ar=A.ac})();(function lazyInitializers(){var s=hunkHelpers.lazyFinal
s($,"tJ","oI",()=>B.oz("_$dart_dartClosure"))
s($,"tI","ml",()=>B.oz("_$dart_dartClosure_dartJSInterop"))
s($,"u5","oX",()=>B.m([new J.fj()],B.W("v<em>")))
s($,"tP","oL",()=>B.ce(B.lf({
toString:function(){return"$receiver$"}})))
s($,"tQ","oM",()=>B.ce(B.lf({$method$:null,
toString:function(){return"$receiver$"}})))
s($,"tR","oN",()=>B.ce(B.lf(null)))
s($,"tS","oO",()=>B.ce(function(){var $argumentsExpr$="$arguments$"
try{null.$method$($argumentsExpr$)}catch(r){return r.message}}()))
s($,"tV","oR",()=>B.ce(B.lf(void 0)))
s($,"tW","oS",()=>B.ce(function(){var $argumentsExpr$="$arguments$"
try{(void 0).$method$($argumentsExpr$)}catch(r){return r.message}}()))
s($,"tU","oQ",()=>B.ce(B.nX(null)))
s($,"tT","oP",()=>B.ce(function(){try{null.$method$}catch(r){return r.message}}()))
s($,"tY","oU",()=>B.ce(B.nX(void 0)))
s($,"tX","oT",()=>B.ce(function(){try{(void 0).$method$}catch(r){return r.message}}()))
s($,"tZ","nh",()=>B.qB())
s($,"tK","oJ",()=>B.L("^([+-]?\\d{4,6})-?(\\d\\d)-?(\\d\\d)(?:[ T](\\d\\d)(?::?(\\d\\d)(?::?(\\d\\d)(?:[.,](\\d+))?)?)?( ?[zZ]| ?([-+])(\\d\\d)(?::?(\\d\\d))?)?)?$"))
s($,"u1","ha",()=>B.nd(A.S0))
s($,"u2","oV",()=>Symbol("jsBoxedDartObjectProperty"))
s($,"tL","oK",()=>J.p7(A.NS.gbu(new Uint16Array(B.oi(B.m([1],t.t)))),0,null).getInt8(0)===1?A.dU:A.bP)
s($,"u7","dP",()=>B.aR(B.dx(500,new B.lX(),t.z),t.V))
s($,"u8","oY",()=>{var r=B.fr($.dP(),!0,t.z)
r.push(A.cN)
r.push(A.cO)
return B.aR(r,t.V)})
s($,"u_","ni",()=>{var r,q,p,o,n=t.z
n=B.n(n,n)
for(r=$.oY(),q=r.length,p=0;p<q;++p){o=r[p]
n.j(0,o.a,o)}return B.dX(n,t.N,t.V)})
s($,"tE","mi",()=>B.aR(B.dx(200,new B.hg(),t.z),t.G))
s($,"tF","mj",()=>B.aR(B.dx(300,new B.hh(),t.z),t.G))
s($,"tD","mh",()=>B.aR(B.dx(200,new B.hf(),t.z),t.G))
s($,"tC","ng",()=>B.aR(B.dx(200,new B.he(),t.z),t.G))
s($,"tG","mk",()=>B.aR(B.dx(100,new B.hi(),t.z),t.G))
s($,"tB","b2",()=>{var r,q,p,o,n,m=t.z
m=B.n(m,m)
for(r=t.G,q=B.fr($.mi(),!0,r),A.b.A(q,$.mj()),A.b.A(q,$.mh()),A.b.A(q,$.ng()),A.b.A(q,$.mk()),q.push(A.dH),q.push(A.dJ),q.push(A.dI),q.push(A.dE),q.push(A.dF),q.push(A.dG),p=q.length,o=0;o<q.length;q.length===p||(0,B.Z)(q),++o){n=q[o]
m.j(0,n.a,n)}return B.dX(m,t.N,r)})
s($,"uc","p0",()=>{var r,q,p=B.n(t.N,t.F)
for(r=0;r<155;++r){q=A.bj[r]
p.j(0,q.a,q)}return p})
s($,"ui","hb",()=>B.aR(A.b.cu(A.a2,new B.mg()),t.Y))
s($,"u0","h9",()=>{var r,q,p=t.z
p=B.n(p,p)
for(r=0;r<49;++r){q=A.a2[r]
p.j(0,q.a,q)}return B.dX(p,t.N,t.Y)})
s($,"u4","dd",()=>{var r,q,p=t.z
p=B.n(p,p)
for(r=0;r<8;++r){q=A.cs[r]
p.j(0,q.a,q)}return B.dX(p,t.N,B.W("bk"))})
s($,"ug","p3",()=>{var r,q,p=B.n(t.N,t.r)
for(r=0;r<5;++r){q=A.ct[r]
p.j(0,q.a,q)}return p})
s($,"ud","p1",()=>{var r,q,p=B.n(t.N,t.r)
for(r=0;r<80;++r){q=A.bg[r]
p.j(0,q.a,q)}return p})
s($,"ue","dQ",()=>B.aR(B.dx(100,new B.me(),t.z),t.J))
s($,"ua","p_",()=>{var r=B.fr($.dQ(),!0,t.z)
r.push(A.OH)
return B.aR(r,t.J)})
s($,"u3","oW",()=>{var r,q,p,o,n=t.z
n=B.n(n,n)
for(r=$.p_(),q=r.length,p=0;p<q;++p){o=r[p]
n.j(0,o.a,o)}return B.dX(n,t.N,t.J)})
s($,"uf","p2",()=>{var r,q,p=B.n(t.N,B.W("c5"))
for(r=0;r<5;++r){q=A.wu[r]
p.j(0,q.a,q)}return p})
s($,"uh","p4",()=>{var r,q,p,o,n,m,l,k=B.fr(A.uc,!0,t.z)
for(r=B.nI(A.B4,B.W("a7")).gq(0),q=B.W("bm");r.l();){p=r.gu()
for(o=B.nI(A.vU,q).gq(0),n=p.b,m=p.a;o.l();){l=o.gu()
k.push(B.rd(n,l.b,m,l.a))}}return B.aR(k,t.jx)})
s($,"u9","oZ",()=>{var r=B.fr($.p4(),!0,t.z)
A.b.A(r,A.cq)
return B.aR(r,t.jx)})
s($,"u6","de",()=>{var r,q,p,o,n=t.z
n=B.n(n,n)
for(r=$.oZ(),q=r.length,p=0;p<q;++p){o=r[p]
n.j(0,o.a,o)}return B.dX(n,t.N,t.jx)})})();(function nativeSupport(){!function(){var s=function(a){var m={}
m[a]=1
return Object.keys(hunkHelpers.convertToFastObject(m))[0]}
v.getIsolateTag=function(a){return s("___dart_"+a+v.isolateTag)}
var r="___dart_isolate_tags_"
var q=Object[r]||(Object[r]=Object.create(null))
var p="_ZxYxX"
for(var o=0;;o++){var n=s(p+"_"+o+"_")
if(!(n in q)){q[n]=1
v.isolateTag=n
break}}v.dispatchPropertyName=v.getIsolateTag("dispatch_record")}()
hunkHelpers.setOrUpdateInterceptorsByTag({ArrayBuffer:B.cW,SharedArrayBuffer:B.cW,ArrayBufferView:B.ef,DataView:B.fs,Float32Array:B.ft,Float64Array:B.fu,Int16Array:B.fv,Int32Array:B.fw,Int8Array:B.fx,Uint16Array:B.eg,Uint32Array:B.eh,Uint8ClampedArray:B.ei,CanvasPixelArray:B.ei,Uint8Array:B.ej})
hunkHelpers.setOrUpdateLeafTags({ArrayBuffer:true,SharedArrayBuffer:true,ArrayBufferView:false,DataView:true,Float32Array:true,Float64Array:true,Int16Array:true,Int32Array:true,Int8Array:true,Uint16Array:true,Uint32Array:true,Uint8ClampedArray:true,CanvasPixelArray:true,Uint8Array:false})
B.aK.$nativeSuperclassTag="ArrayBufferView"
B.eA.$nativeSuperclassTag="ArrayBufferView"
B.eB.$nativeSuperclassTag="ArrayBufferView"
B.cu.$nativeSuperclassTag="ArrayBufferView"
B.eC.$nativeSuperclassTag="ArrayBufferView"
B.eD.$nativeSuperclassTag="ArrayBufferView"
B.bf.$nativeSuperclassTag="ArrayBufferView"})()
Function.prototype.$1=function(a){return this(a)}
Function.prototype.$2=function(a,b){return this(a,b)}
Function.prototype.$0=function(){return this()}
Function.prototype.$3=function(a,b,c){return this(a,b,c)}
Function.prototype.$4=function(a,b,c,d){return this(a,b,c,d)}
Function.prototype.$1$1=function(a){return this(a)}
Function.prototype.$1$0=function(){return this()}
Function.prototype.$2$1=function(a){return this(a)}
Function.prototype.$1$2=function(a,b){return this(a,b)}
convertAllToFastObject(w)
convertToFastObject($);(function(a){if(typeof document==="undefined"){a(null)
return}if(typeof document.currentScript!="undefined"){a(document.currentScript)
return}var s=document.scripts
function onLoad(b){for(var q=0;q<s.length;++q){s[q].removeEventListener("load",onLoad,false)}a(b.target)}for(var r=0;r<s.length;++r){s[r].addEventListener("load",onLoad,false)}})(function(a){v.currentScript=a
var s=B.tp
if(typeof dartMainRunner==="function"){dartMainRunner(s,[])}else{s([])}})})()