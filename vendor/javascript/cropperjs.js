function ownKeys(t,e){var i=Object.keys(t);if(Object.getOwnPropertySymbols){var a=Object.getOwnPropertySymbols(t);e&&(a=a.filter((function(e){return Object.getOwnPropertyDescriptor(t,e).enumerable}))),i.push.apply(i,a)}return i}function _objectSpread2(t){for(var e=1;e<arguments.length;e++){var i=null!=arguments[e]?arguments[e]:{};e%2?ownKeys(Object(i),!0).forEach((function(e){_defineProperty(t,e,i[e])})):Object.getOwnPropertyDescriptors?Object.defineProperties(t,Object.getOwnPropertyDescriptors(i)):ownKeys(Object(i)).forEach((function(e){Object.defineProperty(t,e,Object.getOwnPropertyDescriptor(i,e))}))}return t}function _toPrimitive(t,e){if("object"!=typeof t||!t)return t;var i=t[Symbol.toPrimitive];if(void 0!==i){var a=i.call(t,e||"default");if("object"!=typeof a)return a;throw new TypeError("@@toPrimitive must return a primitive value.")}return("string"===e?String:Number)(t)}function _toPropertyKey(t){var e=_toPrimitive(t,"string");return"symbol"==typeof e?e:e+""}function _typeof(t){return _typeof="function"==typeof Symbol&&"symbol"==typeof Symbol.iterator?function(t){return typeof t}:function(t){return t&&"function"==typeof Symbol&&t.constructor===Symbol&&t!==Symbol.prototype?"symbol":typeof t},_typeof(t)}function _classCallCheck(t,e){if(!(t instanceof e))throw new TypeError("Cannot call a class as a function")}function _defineProperties(t,e){for(var i=0;i<e.length;i++){var a=e[i];a.enumerable=a.enumerable||false;a.configurable=true;"value"in a&&(a.writable=true);Object.defineProperty(t,_toPropertyKey(a.key),a)}}function _createClass(t,e,i){e&&_defineProperties(t.prototype,e);i&&_defineProperties(t,i);Object.defineProperty(t,"prototype",{writable:false});return t}function _defineProperty(t,e,i){e=_toPropertyKey(e);e in t?Object.defineProperty(t,e,{value:i,enumerable:true,configurable:true,writable:true}):t[e]=i;return t}function _toConsumableArray(t){return _arrayWithoutHoles(t)||_iterableToArray(t)||_unsupportedIterableToArray(t)||_nonIterableSpread()}function _arrayWithoutHoles(t){if(Array.isArray(t))return _arrayLikeToArray(t)}function _iterableToArray(t){if(typeof Symbol!=="undefined"&&t[Symbol.iterator]!=null||t["@@iterator"]!=null)return Array.from(t)}function _unsupportedIterableToArray(t,e){if(t){if(typeof t==="string")return _arrayLikeToArray(t,e);var i=Object.prototype.toString.call(t).slice(8,-1);i==="Object"&&t.constructor&&(i=t.constructor.name);return i==="Map"||i==="Set"?Array.from(t):i==="Arguments"||/^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(i)?_arrayLikeToArray(t,e):void 0}}function _arrayLikeToArray(t,e){(e==null||e>t.length)&&(e=t.length);for(var i=0,a=new Array(e);i<e;i++)a[i]=t[i];return a}function _nonIterableSpread(){throw new TypeError("Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.")}var t=typeof window!=="undefined"&&typeof window.document!=="undefined";var e=t?window:{};var i=!(!t||!e.document.documentElement)&&"ontouchstart"in e.document.documentElement;var a=!!t&&"PointerEvent"in e;var r="cropper";var n="all";var o="crop";var s="move";var h="zoom";var c="e";var l="w";var d="s";var p="n";var u="ne";var f="nw";var v="se";var m="sw";var g="".concat(r,"-crop");var b="".concat(r,"-disabled");var w="".concat(r,"-hidden");var y="".concat(r,"-hide");var x="".concat(r,"-invisible");var C="".concat(r,"-modal");var D="".concat(r,"-move");var M="".concat(r,"Action");var N="".concat(r,"Preview");var O="crop";var E="move";var T="none";var L="crop";var B="cropend";var k="cropmove";var S="cropstart";var z="dblclick";var A=i?"touchstart":"mousedown";var j=i?"touchmove":"mousemove";var W=i?"touchend touchcancel":"mouseup";var P=a?"pointerdown":A;var H=a?"pointermove":j;var R=a?"pointerup pointercancel":W;var Y="ready";var X="resize";var I="wheel";var _="zoom";var U="image/jpeg";var F=/^e|w|s|n|se|sw|ne|nw|all|crop|move|zoom$/;var q=/^data:/;var K=/^data:image\/jpeg;base64,/;var $=/^img|canvas$/i;var Z=200;var Q=100;var G={viewMode:0,dragMode:O,initialAspectRatio:NaN,aspectRatio:NaN,data:null,preview:"",responsive:true,restore:true,checkCrossOrigin:true,checkOrientation:true,modal:true,guides:true,center:true,highlight:true,background:true,autoCrop:true,autoCropArea:.8,movable:true,rotatable:true,scalable:true,zoomable:true,zoomOnTouch:true,zoomOnWheel:true,wheelZoomRatio:.1,cropBoxMovable:true,cropBoxResizable:true,toggleDragModeOnDblclick:true,minCanvasWidth:0,minCanvasHeight:0,minCropBoxWidth:0,minCropBoxHeight:0,minContainerWidth:Z,minContainerHeight:Q,ready:null,cropstart:null,cropmove:null,cropend:null,crop:null,zoom:null};var V='<div class="cropper-container" touch-action="none"><div class="cropper-wrap-box"><div class="cropper-canvas"></div></div><div class="cropper-drag-box"></div><div class="cropper-crop-box"><span class="cropper-view-box"></span><span class="cropper-dashed dashed-h"></span><span class="cropper-dashed dashed-v"></span><span class="cropper-center"></span><span class="cropper-face"></span><span class="cropper-line line-e" data-cropper-action="e"></span><span class="cropper-line line-n" data-cropper-action="n"></span><span class="cropper-line line-w" data-cropper-action="w"></span><span class="cropper-line line-s" data-cropper-action="s"></span><span class="cropper-point point-e" data-cropper-action="e"></span><span class="cropper-point point-n" data-cropper-action="n"></span><span class="cropper-point point-w" data-cropper-action="w"></span><span class="cropper-point point-s" data-cropper-action="s"></span><span class="cropper-point point-ne" data-cropper-action="ne"></span><span class="cropper-point point-nw" data-cropper-action="nw"></span><span class="cropper-point point-sw" data-cropper-action="sw"></span><span class="cropper-point point-se" data-cropper-action="se"></span></div></div>';var J=Number.isNaN||e.isNaN;
/**
 * Check if the given value is a number.
 * @param {*} value - The value to check.
 * @returns {boolean} Returns `true` if the given value is a number, else `false`.
 */function isNumber(t){return typeof t==="number"&&!J(t)}
/**
 * Check if the given value is a positive number.
 * @param {*} value - The value to check.
 * @returns {boolean} Returns `true` if the given value is a positive number, else `false`.
 */var tt=function isPositiveNumber(t){return t>0&&t<Infinity};
/**
 * Check if the given value is undefined.
 * @param {*} value - The value to check.
 * @returns {boolean} Returns `true` if the given value is undefined, else `false`.
 */function isUndefined(t){return typeof t==="undefined"}
/**
 * Check if the given value is an object.
 * @param {*} value - The value to check.
 * @returns {boolean} Returns `true` if the given value is an object, else `false`.
 */function isObject(t){return _typeof(t)==="object"&&t!==null}var et=Object.prototype.hasOwnProperty;
/**
 * Check if the given value is a plain object.
 * @param {*} value - The value to check.
 * @returns {boolean} Returns `true` if the given value is a plain object, else `false`.
 */function isPlainObject(t){if(!isObject(t))return false;try{var e=t.constructor;var i=e.prototype;return e&&i&&et.call(i,"isPrototypeOf")}catch(t){return false}}
/**
 * Check if the given value is a function.
 * @param {*} value - The value to check.
 * @returns {boolean} Returns `true` if the given value is a function, else `false`.
 */function isFunction(t){return typeof t==="function"}var it=Array.prototype.slice;
/**
 * Convert array-like or iterable object to an array.
 * @param {*} value - The value to convert.
 * @returns {Array} Returns a new array.
 */function toArray(t){return Array.from?Array.from(t):it.call(t)}
/**
 * Iterate the given data.
 * @param {*} data - The data to iterate.
 * @param {Function} callback - The process function for each element.
 * @returns {*} The original data.
 */function forEach(t,e){t&&isFunction(e)&&(Array.isArray(t)||isNumber(t.length)?toArray(t).forEach((function(i,a){e.call(t,i,a,t)})):isObject(t)&&Object.keys(t).forEach((function(i){e.call(t,t[i],i,t)})));return t}
/**
 * Extend the given object.
 * @param {*} target - The target object to extend.
 * @param {*} args - The rest objects for merging to the target object.
 * @returns {Object} The extended object.
 */var at=Object.assign||function assign(t){for(var e=arguments.length,i=new Array(e>1?e-1:0),a=1;a<e;a++)i[a-1]=arguments[a];isObject(t)&&i.length>0&&i.forEach((function(e){isObject(e)&&Object.keys(e).forEach((function(i){t[i]=e[i]}))}));return t};var rt=/\.\d*(?:0|9){12}\d*$/;
/**
 * Normalize decimal number.
 * Check out {@link https://0.30000000000000004.com/}
 * @param {number} value - The value to normalize.
 * @param {number} [times=100000000000] - The times for normalizing.
 * @returns {number} Returns the normalized number.
 */function normalizeDecimalNumber(t){var e=arguments.length>1&&arguments[1]!==void 0?arguments[1]:1e11;return rt.test(t)?Math.round(t*e)/e:t}var nt=/^width|height|left|top|marginLeft|marginTop$/;
/**
 * Apply styles to the given element.
 * @param {Element} element - The target element.
 * @param {Object} styles - The styles for applying.
 */function setStyle(t,e){var i=t.style;forEach(e,(function(t,e){nt.test(e)&&isNumber(t)&&(t="".concat(t,"px"));i[e]=t}))}
/**
 * Check if the given element has a special class.
 * @param {Element} element - The element to check.
 * @param {string} value - The class to search.
 * @returns {boolean} Returns `true` if the special class was found.
 */function hasClass(t,e){return t.classList?t.classList.contains(e):t.className.indexOf(e)>-1}
/**
 * Add classes to the given element.
 * @param {Element} element - The target element.
 * @param {string} value - The classes to be added.
 */function addClass(t,e){if(e)if(isNumber(t.length))forEach(t,(function(t){addClass(t,e)}));else if(t.classList)t.classList.add(e);else{var i=t.className.trim();i?i.indexOf(e)<0&&(t.className="".concat(i," ").concat(e)):t.className=e}}
/**
 * Remove classes from the given element.
 * @param {Element} element - The target element.
 * @param {string} value - The classes to be removed.
 */function removeClass(t,e){e&&(isNumber(t.length)?forEach(t,(function(t){removeClass(t,e)})):t.classList?t.classList.remove(e):t.className.indexOf(e)>=0&&(t.className=t.className.replace(e,"")))}
/**
 * Add or remove classes from the given element.
 * @param {Element} element - The target element.
 * @param {string} value - The classes to be toggled.
 * @param {boolean} added - Add only.
 */function toggleClass(t,e,i){e&&(isNumber(t.length)?forEach(t,(function(t){toggleClass(t,e,i)})):i?addClass(t,e):removeClass(t,e))}var ot=/([a-z\d])([A-Z])/g;
/**
 * Transform the given string from camelCase to kebab-case
 * @param {string} value - The value to transform.
 * @returns {string} The transformed value.
 */function toParamCase(t){return t.replace(ot,"$1-$2").toLowerCase()}
/**
 * Get data from the given element.
 * @param {Element} element - The target element.
 * @param {string} name - The data key to get.
 * @returns {string} The data value.
 */function getData(t,e){return isObject(t[e])?t[e]:t.dataset?t.dataset[e]:t.getAttribute("data-".concat(toParamCase(e)))}
/**
 * Set data to the given element.
 * @param {Element} element - The target element.
 * @param {string} name - The data key to set.
 * @param {string} data - The data value.
 */function setData(t,e,i){isObject(i)?t[e]=i:t.dataset?t.dataset[e]=i:t.setAttribute("data-".concat(toParamCase(e)),i)}
/**
 * Remove data from the given element.
 * @param {Element} element - The target element.
 * @param {string} name - The data key to remove.
 */function removeData(t,e){if(isObject(t[e]))try{delete t[e]}catch(i){t[e]=void 0}else if(t.dataset)try{delete t.dataset[e]}catch(i){t.dataset[e]=void 0}else t.removeAttribute("data-".concat(toParamCase(e)))}var st=/\s\s*/;var ht=function(){var i=false;if(t){var a=false;var r=function listener(){};var n=Object.defineProperty({},"once",{get:function get(){i=true;return a},
/**
       * This setter can fix a `TypeError` in strict mode
       * {@link https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Errors/Getter_only}
       * @param {boolean} value - The value to set
       */
set:function set(t){a=t}});e.addEventListener("test",r,n);e.removeEventListener("test",r,n)}return i}();
/**
 * Remove event listener from the target element.
 * @param {Element} element - The event target.
 * @param {string} type - The event type(s).
 * @param {Function} listener - The event listener.
 * @param {Object} options - The event options.
 */function removeListener(t,e,i){var a=arguments.length>3&&arguments[3]!==void 0?arguments[3]:{};var r=i;e.trim().split(st).forEach((function(e){if(!ht){var n=t.listeners;if(n&&n[e]&&n[e][i]){r=n[e][i];delete n[e][i];Object.keys(n[e]).length===0&&delete n[e];Object.keys(n).length===0&&delete t.listeners}}t.removeEventListener(e,r,a)}))}
/**
 * Add event listener to the target element.
 * @param {Element} element - The event target.
 * @param {string} type - The event type(s).
 * @param {Function} listener - The event listener.
 * @param {Object} options - The event options.
 */function addListener(t,e,i){var a=arguments.length>3&&arguments[3]!==void 0?arguments[3]:{};var r=i;e.trim().split(st).forEach((function(e){if(a.once&&!ht){var n=t.listeners,o=n===void 0?{}:n;r=function handler(){delete o[e][i];t.removeEventListener(e,r,a);for(var n=arguments.length,s=new Array(n),h=0;h<n;h++)s[h]=arguments[h];i.apply(t,s)};o[e]||(o[e]={});o[e][i]&&t.removeEventListener(e,o[e][i],a);o[e][i]=r;t.listeners=o}t.addEventListener(e,r,a)}))}
/**
 * Dispatch event on the target element.
 * @param {Element} element - The event target.
 * @param {string} type - The event type(s).
 * @param {Object} data - The additional event data.
 * @returns {boolean} Indicate if the event is default prevented or not.
 */function dispatchEvent(t,e,i){var a;if(isFunction(Event)&&isFunction(CustomEvent))a=new CustomEvent(e,{detail:i,bubbles:true,cancelable:true});else{a=document.createEvent("CustomEvent");a.initCustomEvent(e,true,true,i)}return t.dispatchEvent(a)}
/**
 * Get the offset base on the document.
 * @param {Element} element - The target element.
 * @returns {Object} The offset data.
 */function getOffset(t){var e=t.getBoundingClientRect();return{left:e.left+(window.pageXOffset-document.documentElement.clientLeft),top:e.top+(window.pageYOffset-document.documentElement.clientTop)}}var ct=e.location;var lt=/^(\w+:)\/\/([^:/?#]*):?(\d*)/i;
/**
 * Check if the given URL is a cross origin URL.
 * @param {string} url - The target URL.
 * @returns {boolean} Returns `true` if the given URL is a cross origin URL, else `false`.
 */function isCrossOriginURL(t){var e=t.match(lt);return e!==null&&(e[1]!==ct.protocol||e[2]!==ct.hostname||e[3]!==ct.port)}
/**
 * Add timestamp to the given URL.
 * @param {string} url - The target URL.
 * @returns {string} The result URL.
 */function addTimestamp(t){var e="timestamp=".concat((new Date).getTime());return t+(t.indexOf("?")===-1?"?":"&")+e}
/**
 * Get transforms base on the given object.
 * @param {Object} obj - The target object.
 * @returns {string} A string contains transform values.
 */function getTransforms(t){var e=t.rotate,i=t.scaleX,a=t.scaleY,r=t.translateX,n=t.translateY;var o=[];isNumber(r)&&r!==0&&o.push("translateX(".concat(r,"px)"));isNumber(n)&&n!==0&&o.push("translateY(".concat(n,"px)"));isNumber(e)&&e!==0&&o.push("rotate(".concat(e,"deg)"));isNumber(i)&&i!==1&&o.push("scaleX(".concat(i,")"));isNumber(a)&&a!==1&&o.push("scaleY(".concat(a,")"));var s=o.length?o.join(" "):"none";return{WebkitTransform:s,msTransform:s,transform:s}}
/**
 * Get the max ratio of a group of pointers.
 * @param {string} pointers - The target pointers.
 * @returns {number} The result ratio.
 */function getMaxZoomRatio(t){var e=_objectSpread2({},t);var i=0;forEach(t,(function(t,a){delete e[a];forEach(e,(function(e){var a=Math.abs(t.startX-e.startX);var r=Math.abs(t.startY-e.startY);var n=Math.abs(t.endX-e.endX);var o=Math.abs(t.endY-e.endY);var s=Math.sqrt(a*a+r*r);var h=Math.sqrt(n*n+o*o);var c=(h-s)/s;Math.abs(c)>Math.abs(i)&&(i=c)}))}));return i}
/**
 * Get a pointer from an event object.
 * @param {Object} event - The target event object.
 * @param {boolean} endOnly - Indicates if only returns the end point coordinate or not.
 * @returns {Object} The result pointer contains start and/or end point coordinates.
 */function getPointer(t,e){var i=t.pageX,a=t.pageY;var r={endX:i,endY:a};return e?r:_objectSpread2({startX:i,startY:a},r)}
/**
 * Get the center point coordinate of a group of pointers.
 * @param {Object} pointers - The target pointers.
 * @returns {Object} The center point coordinate.
 */function getPointersCenter(t){var e=0;var i=0;var a=0;forEach(t,(function(t){var r=t.startX,n=t.startY;e+=r;i+=n;a+=1}));e/=a;i/=a;return{pageX:e,pageY:i}}
/**
 * Get the max sizes in a rectangle under the given aspect ratio.
 * @param {Object} data - The original sizes.
 * @param {string} [type='contain'] - The adjust type.
 * @returns {Object} The result sizes.
 */function getAdjustedSizes(t){var e=t.aspectRatio,i=t.height,a=t.width;var r=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"contain";var n=tt(a);var o=tt(i);if(n&&o){var s=i*e;r==="contain"&&s>a||r==="cover"&&s<a?i=a/e:a=i*e}else n?i=a/e:o&&(a=i*e);return{width:a,height:i}}
/**
 * Get the new sizes of a rectangle after rotated.
 * @param {Object} data - The original sizes.
 * @returns {Object} The result sizes.
 */function getRotatedSizes(t){var e=t.width,i=t.height,a=t.degree;a=Math.abs(a)%180;if(a===90)return{width:i,height:e};var r=a%90*Math.PI/180;var n=Math.sin(r);var o=Math.cos(r);var s=e*o+i*n;var h=e*n+i*o;return a>90?{width:h,height:s}:{width:s,height:h}}
/**
 * Get a canvas which drew the given image.
 * @param {HTMLImageElement} image - The image for drawing.
 * @param {Object} imageData - The image data.
 * @param {Object} canvasData - The canvas data.
 * @param {Object} options - The options.
 * @returns {HTMLCanvasElement} The result canvas.
 */function getSourceCanvas(t,e,i,a){var r=e.aspectRatio,n=e.naturalWidth,o=e.naturalHeight,s=e.rotate,h=s===void 0?0:s,c=e.scaleX,l=c===void 0?1:c,d=e.scaleY,p=d===void 0?1:d;var u=i.aspectRatio,f=i.naturalWidth,v=i.naturalHeight;var m=a.fillColor,g=m===void 0?"transparent":m,b=a.imageSmoothingEnabled,w=b===void 0||b,y=a.imageSmoothingQuality,x=y===void 0?"low":y,C=a.maxWidth,D=C===void 0?Infinity:C,M=a.maxHeight,N=M===void 0?Infinity:M,O=a.minWidth,E=O===void 0?0:O,T=a.minHeight,L=T===void 0?0:T;var B=document.createElement("canvas");var k=B.getContext("2d");var S=getAdjustedSizes({aspectRatio:u,width:D,height:N});var z=getAdjustedSizes({aspectRatio:u,width:E,height:L},"cover");var A=Math.min(S.width,Math.max(z.width,f));var j=Math.min(S.height,Math.max(z.height,v));var W=getAdjustedSizes({aspectRatio:r,width:D,height:N});var P=getAdjustedSizes({aspectRatio:r,width:E,height:L},"cover");var H=Math.min(W.width,Math.max(P.width,n));var R=Math.min(W.height,Math.max(P.height,o));var Y=[-H/2,-R/2,H,R];B.width=normalizeDecimalNumber(A);B.height=normalizeDecimalNumber(j);k.fillStyle=g;k.fillRect(0,0,A,j);k.save();k.translate(A/2,j/2);k.rotate(h*Math.PI/180);k.scale(l,p);k.imageSmoothingEnabled=w;k.imageSmoothingQuality=x;k.drawImage.apply(k,[t].concat(_toConsumableArray(Y.map((function(t){return Math.floor(normalizeDecimalNumber(t))})))));k.restore();return B}var dt=String.fromCharCode;
/**
 * Get string from char code in data view.
 * @param {DataView} dataView - The data view for read.
 * @param {number} start - The start index.
 * @param {number} length - The read length.
 * @returns {string} The read result.
 */function getStringFromCharCode(t,e,i){var a="";i+=e;for(var r=e;r<i;r+=1)a+=dt(t.getUint8(r));return a}var pt=/^data:.*,/;
/**
 * Transform Data URL to array buffer.
 * @param {string} dataURL - The Data URL to transform.
 * @returns {ArrayBuffer} The result array buffer.
 */function dataURLToArrayBuffer(t){var e=t.replace(pt,"");var i=atob(e);var a=new ArrayBuffer(i.length);var r=new Uint8Array(a);forEach(r,(function(t,e){r[e]=i.charCodeAt(e)}));return a}
/**
 * Transform array buffer to Data URL.
 * @param {ArrayBuffer} arrayBuffer - The array buffer to transform.
 * @param {string} mimeType - The mime type of the Data URL.
 * @returns {string} The result Data URL.
 */function arrayBufferToDataURL(t,e){var i=[];var a=8192;var r=new Uint8Array(t);while(r.length>0){i.push(dt.apply(null,toArray(r.subarray(0,a))));r=r.subarray(a)}return"data:".concat(e,";base64,").concat(btoa(i.join("")))}
/**
 * Get orientation value from given array buffer.
 * @param {ArrayBuffer} arrayBuffer - The array buffer to read.
 * @returns {number} The read orientation value.
 */function resetAndGetOrientation(t){var e=new DataView(t);var i;try{var a;var r;var n;if(e.getUint8(0)===255&&e.getUint8(1)===216){var o=e.byteLength;var s=2;while(s+1<o){if(e.getUint8(s)===255&&e.getUint8(s+1)===225){r=s;break}s+=1}}if(r){var h=r+4;var c=r+10;if(getStringFromCharCode(e,h,4)==="Exif"){var l=e.getUint16(c);a=l===18761;if((a||l===19789)&&e.getUint16(c+2,a)===42){var d=e.getUint32(c+4,a);d>=8&&(n=c+d)}}}if(n){var p=e.getUint16(n,a);var u;var f;for(f=0;f<p;f+=1){u=n+f*12+2;if(e.getUint16(u,a)===274){u+=8;i=e.getUint16(u,a);e.setUint16(u,1,a);break}}}}catch(t){i=1}return i}
/**
 * Parse Exif Orientation value.
 * @param {number} orientation - The orientation to parse.
 * @returns {Object} The parsed result.
 */function parseOrientation(t){var e=0;var i=1;var a=1;switch(t){case 2:i=-1;break;case 3:e=-180;break;case 4:a=-1;break;case 5:e=90;a=-1;break;case 6:e=90;break;case 7:e=90;i=-1;break;case 8:e=-90;break}return{rotate:e,scaleX:i,scaleY:a}}var ut={render:function render(){this.initContainer();this.initCanvas();this.initCropBox();this.renderCanvas();this.cropped&&this.renderCropBox()},initContainer:function initContainer(){var t=this.element,e=this.options,i=this.container,a=this.cropper;var r=Number(e.minContainerWidth);var n=Number(e.minContainerHeight);addClass(a,w);removeClass(t,w);var o={width:Math.max(i.offsetWidth,r>=0?r:Z),height:Math.max(i.offsetHeight,n>=0?n:Q)};this.containerData=o;setStyle(a,{width:o.width,height:o.height});addClass(t,w);removeClass(a,w)},initCanvas:function initCanvas(){var t=this.containerData,e=this.imageData;var i=this.options.viewMode;var a=Math.abs(e.rotate)%180===90;var r=a?e.naturalHeight:e.naturalWidth;var n=a?e.naturalWidth:e.naturalHeight;var o=r/n;var s=t.width;var h=t.height;t.height*o>t.width?i===3?s=t.height*o:h=t.width/o:i===3?h=t.width/o:s=t.height*o;var c={aspectRatio:o,naturalWidth:r,naturalHeight:n,width:s,height:h};this.canvasData=c;this.limited=i===1||i===2;this.limitCanvas(true,true);c.width=Math.min(Math.max(c.width,c.minWidth),c.maxWidth);c.height=Math.min(Math.max(c.height,c.minHeight),c.maxHeight);c.left=(t.width-c.width)/2;c.top=(t.height-c.height)/2;c.oldLeft=c.left;c.oldTop=c.top;this.initialCanvasData=at({},c)},limitCanvas:function limitCanvas(t,e){var i=this.options,a=this.containerData,r=this.canvasData,n=this.cropBoxData;var o=i.viewMode;var s=r.aspectRatio;var h=this.cropped&&n;if(t){var c=Number(i.minCanvasWidth)||0;var l=Number(i.minCanvasHeight)||0;if(o>1){c=Math.max(c,a.width);l=Math.max(l,a.height);o===3&&(l*s>c?c=l*s:l=c/s)}else if(o>0)if(c)c=Math.max(c,h?n.width:0);else if(l)l=Math.max(l,h?n.height:0);else if(h){c=n.width;l=n.height;l*s>c?c=l*s:l=c/s}var d=getAdjustedSizes({aspectRatio:s,width:c,height:l});c=d.width;l=d.height;r.minWidth=c;r.minHeight=l;r.maxWidth=Infinity;r.maxHeight=Infinity}if(e)if(o>(h?0:1)){var p=a.width-r.width;var u=a.height-r.height;r.minLeft=Math.min(0,p);r.minTop=Math.min(0,u);r.maxLeft=Math.max(0,p);r.maxTop=Math.max(0,u);if(h&&this.limited){r.minLeft=Math.min(n.left,n.left+(n.width-r.width));r.minTop=Math.min(n.top,n.top+(n.height-r.height));r.maxLeft=n.left;r.maxTop=n.top;if(o===2){if(r.width>=a.width){r.minLeft=Math.min(0,p);r.maxLeft=Math.max(0,p)}if(r.height>=a.height){r.minTop=Math.min(0,u);r.maxTop=Math.max(0,u)}}}}else{r.minLeft=-r.width;r.minTop=-r.height;r.maxLeft=a.width;r.maxTop=a.height}},renderCanvas:function renderCanvas(t,e){var i=this.canvasData,a=this.imageData;if(e){var r=getRotatedSizes({width:a.naturalWidth*Math.abs(a.scaleX||1),height:a.naturalHeight*Math.abs(a.scaleY||1),degree:a.rotate||0}),n=r.width,o=r.height;var s=i.width*(n/i.naturalWidth);var h=i.height*(o/i.naturalHeight);i.left-=(s-i.width)/2;i.top-=(h-i.height)/2;i.width=s;i.height=h;i.aspectRatio=n/o;i.naturalWidth=n;i.naturalHeight=o;this.limitCanvas(true,false)}(i.width>i.maxWidth||i.width<i.minWidth)&&(i.left=i.oldLeft);(i.height>i.maxHeight||i.height<i.minHeight)&&(i.top=i.oldTop);i.width=Math.min(Math.max(i.width,i.minWidth),i.maxWidth);i.height=Math.min(Math.max(i.height,i.minHeight),i.maxHeight);this.limitCanvas(false,true);i.left=Math.min(Math.max(i.left,i.minLeft),i.maxLeft);i.top=Math.min(Math.max(i.top,i.minTop),i.maxTop);i.oldLeft=i.left;i.oldTop=i.top;setStyle(this.canvas,at({width:i.width,height:i.height},getTransforms({translateX:i.left,translateY:i.top})));this.renderImage(t);this.cropped&&this.limited&&this.limitCropBox(true,true)},renderImage:function renderImage(t){var e=this.canvasData,i=this.imageData;var a=i.naturalWidth*(e.width/e.naturalWidth);var r=i.naturalHeight*(e.height/e.naturalHeight);at(i,{width:a,height:r,left:(e.width-a)/2,top:(e.height-r)/2});setStyle(this.image,at({width:i.width,height:i.height},getTransforms(at({translateX:i.left,translateY:i.top},i))));t&&this.output()},initCropBox:function initCropBox(){var t=this.options,e=this.canvasData;var i=t.aspectRatio||t.initialAspectRatio;var a=Number(t.autoCropArea)||.8;var r={width:e.width,height:e.height};i&&(e.height*i>e.width?r.height=r.width/i:r.width=r.height*i);this.cropBoxData=r;this.limitCropBox(true,true);r.width=Math.min(Math.max(r.width,r.minWidth),r.maxWidth);r.height=Math.min(Math.max(r.height,r.minHeight),r.maxHeight);r.width=Math.max(r.minWidth,r.width*a);r.height=Math.max(r.minHeight,r.height*a);r.left=e.left+(e.width-r.width)/2;r.top=e.top+(e.height-r.height)/2;r.oldLeft=r.left;r.oldTop=r.top;this.initialCropBoxData=at({},r)},limitCropBox:function limitCropBox(t,e){var i=this.options,a=this.containerData,r=this.canvasData,n=this.cropBoxData,o=this.limited;var s=i.aspectRatio;if(t){var h=Number(i.minCropBoxWidth)||0;var c=Number(i.minCropBoxHeight)||0;var l=o?Math.min(a.width,r.width,r.width+r.left,a.width-r.left):a.width;var d=o?Math.min(a.height,r.height,r.height+r.top,a.height-r.top):a.height;h=Math.min(h,a.width);c=Math.min(c,a.height);if(s){h&&c?c*s>h?c=h/s:h=c*s:h?c=h/s:c&&(h=c*s);d*s>l?d=l/s:l=d*s}n.minWidth=Math.min(h,l);n.minHeight=Math.min(c,d);n.maxWidth=l;n.maxHeight=d}if(e)if(o){n.minLeft=Math.max(0,r.left);n.minTop=Math.max(0,r.top);n.maxLeft=Math.min(a.width,r.left+r.width)-n.width;n.maxTop=Math.min(a.height,r.top+r.height)-n.height}else{n.minLeft=0;n.minTop=0;n.maxLeft=a.width-n.width;n.maxTop=a.height-n.height}},renderCropBox:function renderCropBox(){var t=this.options,e=this.containerData,i=this.cropBoxData;(i.width>i.maxWidth||i.width<i.minWidth)&&(i.left=i.oldLeft);(i.height>i.maxHeight||i.height<i.minHeight)&&(i.top=i.oldTop);i.width=Math.min(Math.max(i.width,i.minWidth),i.maxWidth);i.height=Math.min(Math.max(i.height,i.minHeight),i.maxHeight);this.limitCropBox(false,true);i.left=Math.min(Math.max(i.left,i.minLeft),i.maxLeft);i.top=Math.min(Math.max(i.top,i.minTop),i.maxTop);i.oldLeft=i.left;i.oldTop=i.top;t.movable&&t.cropBoxMovable&&setData(this.face,M,i.width>=e.width&&i.height>=e.height?s:n);setStyle(this.cropBox,at({width:i.width,height:i.height},getTransforms({translateX:i.left,translateY:i.top})));this.cropped&&this.limited&&this.limitCanvas(true,true);this.disabled||this.output()},output:function output(){this.preview();dispatchEvent(this.element,L,this.getData())}};var ft={initPreview:function initPreview(){var t=this.element,e=this.crossOrigin;var i=this.options.preview;var a=e?this.crossOriginUrl:this.url;var r=t.alt||"The image to preview";var n=document.createElement("img");e&&(n.crossOrigin=e);n.src=a;n.alt=r;this.viewBox.appendChild(n);this.viewBoxImage=n;if(i){var o=i;typeof i==="string"?o=t.ownerDocument.querySelectorAll(i):i.querySelector&&(o=[i]);this.previews=o;forEach(o,(function(t){var i=document.createElement("img");setData(t,N,{width:t.offsetWidth,height:t.offsetHeight,html:t.innerHTML});e&&(i.crossOrigin=e);i.src=a;i.alt=r;i.style.cssText='display:block;width:100%;height:auto;min-width:0!important;min-height:0!important;max-width:none!important;max-height:none!important;image-orientation:0deg!important;"';t.innerHTML="";t.appendChild(i)}))}},resetPreview:function resetPreview(){forEach(this.previews,(function(t){var e=getData(t,N);setStyle(t,{width:e.width,height:e.height});t.innerHTML=e.html;removeData(t,N)}))},preview:function preview(){var t=this.imageData,e=this.canvasData,i=this.cropBoxData;var a=i.width,r=i.height;var n=t.width,o=t.height;var s=i.left-e.left-t.left;var h=i.top-e.top-t.top;if(this.cropped&&!this.disabled){setStyle(this.viewBoxImage,at({width:n,height:o},getTransforms(at({translateX:-s,translateY:-h},t))));forEach(this.previews,(function(e){var i=getData(e,N);var c=i.width;var l=i.height;var d=c;var p=l;var u=1;if(a){u=c/a;p=r*u}if(r&&p>l){u=l/r;d=a*u;p=l}setStyle(e,{width:d,height:p});setStyle(e.getElementsByTagName("img")[0],at({width:n*u,height:o*u},getTransforms(at({translateX:-s*u,translateY:-h*u},t))))}))}}};var vt={bind:function bind(){var t=this.element,e=this.options,i=this.cropper;isFunction(e.cropstart)&&addListener(t,S,e.cropstart);isFunction(e.cropmove)&&addListener(t,k,e.cropmove);isFunction(e.cropend)&&addListener(t,B,e.cropend);isFunction(e.crop)&&addListener(t,L,e.crop);isFunction(e.zoom)&&addListener(t,_,e.zoom);addListener(i,P,this.onCropStart=this.cropStart.bind(this));e.zoomable&&e.zoomOnWheel&&addListener(i,I,this.onWheel=this.wheel.bind(this),{passive:false,capture:true});e.toggleDragModeOnDblclick&&addListener(i,z,this.onDblclick=this.dblclick.bind(this));addListener(t.ownerDocument,H,this.onCropMove=this.cropMove.bind(this));addListener(t.ownerDocument,R,this.onCropEnd=this.cropEnd.bind(this));e.responsive&&addListener(window,X,this.onResize=this.resize.bind(this))},unbind:function unbind(){var t=this.element,e=this.options,i=this.cropper;isFunction(e.cropstart)&&removeListener(t,S,e.cropstart);isFunction(e.cropmove)&&removeListener(t,k,e.cropmove);isFunction(e.cropend)&&removeListener(t,B,e.cropend);isFunction(e.crop)&&removeListener(t,L,e.crop);isFunction(e.zoom)&&removeListener(t,_,e.zoom);removeListener(i,P,this.onCropStart);e.zoomable&&e.zoomOnWheel&&removeListener(i,I,this.onWheel,{passive:false,capture:true});e.toggleDragModeOnDblclick&&removeListener(i,z,this.onDblclick);removeListener(t.ownerDocument,H,this.onCropMove);removeListener(t.ownerDocument,R,this.onCropEnd);e.responsive&&removeListener(window,X,this.onResize)}};var mt={resize:function resize(){if(!this.disabled){var t=this.options,e=this.container,i=this.containerData;var a=e.offsetWidth/i.width;var r=e.offsetHeight/i.height;var n=Math.abs(a-1)>Math.abs(r-1)?a:r;if(n!==1){var o;var s;if(t.restore){o=this.getCanvasData();s=this.getCropBoxData()}this.render();if(t.restore){this.setCanvasData(forEach(o,(function(t,e){o[e]=t*n})));this.setCropBoxData(forEach(s,(function(t,e){s[e]=t*n})))}}}},dblclick:function dblclick(){this.disabled||this.options.dragMode===T||this.setDragMode(hasClass(this.dragBox,g)?E:O)},wheel:function wheel(t){var e=this;var i=Number(this.options.wheelZoomRatio)||.1;var a=1;if(!this.disabled){t.preventDefault();if(!this.wheeling){this.wheeling=true;setTimeout((function(){e.wheeling=false}),50);t.deltaY?a=t.deltaY>0?1:-1:t.wheelDelta?a=-t.wheelDelta/120:t.detail&&(a=t.detail>0?1:-1);this.zoom(-a*i,t)}}},cropStart:function cropStart(t){var e=t.buttons,i=t.button;if(!(this.disabled||(t.type==="mousedown"||t.type==="pointerdown"&&t.pointerType==="mouse")&&(isNumber(e)&&e!==1||isNumber(i)&&i!==0||t.ctrlKey))){var a=this.options,r=this.pointers;var n;t.changedTouches?forEach(t.changedTouches,(function(t){r[t.identifier]=getPointer(t)})):r[t.pointerId||0]=getPointer(t);n=Object.keys(r).length>1&&a.zoomable&&a.zoomOnTouch?h:getData(t.target,M);if(F.test(n)&&dispatchEvent(this.element,S,{originalEvent:t,action:n})!==false){t.preventDefault();this.action=n;this.cropping=false;if(n===o){this.cropping=true;addClass(this.dragBox,C)}}}},cropMove:function cropMove(t){var e=this.action;if(!this.disabled&&e){var i=this.pointers;t.preventDefault();if(dispatchEvent(this.element,k,{originalEvent:t,action:e})!==false){t.changedTouches?forEach(t.changedTouches,(function(t){at(i[t.identifier]||{},getPointer(t,true))})):at(i[t.pointerId||0]||{},getPointer(t,true));this.change(t)}}},cropEnd:function cropEnd(t){if(!this.disabled){var e=this.action,i=this.pointers;t.changedTouches?forEach(t.changedTouches,(function(t){delete i[t.identifier]})):delete i[t.pointerId||0];if(e){t.preventDefault();Object.keys(i).length||(this.action="");if(this.cropping){this.cropping=false;toggleClass(this.dragBox,C,this.cropped&&this.options.modal)}dispatchEvent(this.element,B,{originalEvent:t,action:e})}}}};var gt={change:function change(t){var e=this.options,i=this.canvasData,a=this.containerData,r=this.cropBoxData,g=this.pointers;var b=this.action;var y=e.aspectRatio;var x=r.left,C=r.top,D=r.width,M=r.height;var N=x+D;var O=C+M;var E=0;var T=0;var L=a.width;var B=a.height;var k=true;var S;!y&&t.shiftKey&&(y=D&&M?D/M:1);if(this.limited){E=r.minLeft;T=r.minTop;L=E+Math.min(a.width,i.width,i.left+i.width);B=T+Math.min(a.height,i.height,i.top+i.height)}var z=g[Object.keys(g)[0]];var A={x:z.endX-z.startX,y:z.endY-z.startY};var j=function check(t){switch(t){case c:N+A.x>L&&(A.x=L-N);break;case l:x+A.x<E&&(A.x=E-x);break;case p:C+A.y<T&&(A.y=T-C);break;case d:O+A.y>B&&(A.y=B-O);break}};switch(b){case n:x+=A.x;C+=A.y;break;case c:if(A.x>=0&&(N>=L||y&&(C<=T||O>=B))){k=false;break}j(c);D+=A.x;if(D<0){b=l;D=-D;x-=D}if(y){M=D/y;C+=(r.height-M)/2}break;case p:if(A.y<=0&&(C<=T||y&&(x<=E||N>=L))){k=false;break}j(p);M-=A.y;C+=A.y;if(M<0){b=d;M=-M;C-=M}if(y){D=M*y;x+=(r.width-D)/2}break;case l:if(A.x<=0&&(x<=E||y&&(C<=T||O>=B))){k=false;break}j(l);D-=A.x;x+=A.x;if(D<0){b=c;D=-D;x-=D}if(y){M=D/y;C+=(r.height-M)/2}break;case d:if(A.y>=0&&(O>=B||y&&(x<=E||N>=L))){k=false;break}j(d);M+=A.y;if(M<0){b=p;M=-M;C-=M}if(y){D=M*y;x+=(r.width-D)/2}break;case u:if(y){if(A.y<=0&&(C<=T||N>=L)){k=false;break}j(p);M-=A.y;C+=A.y;D=M*y}else{j(p);j(c);A.x>=0?N<L?D+=A.x:A.y<=0&&C<=T&&(k=false):D+=A.x;if(A.y<=0){if(C>T){M-=A.y;C+=A.y}}else{M-=A.y;C+=A.y}}if(D<0&&M<0){b=m;M=-M;D=-D;C-=M;x-=D}else if(D<0){b=f;D=-D;x-=D}else if(M<0){b=v;M=-M;C-=M}break;case f:if(y){if(A.y<=0&&(C<=T||x<=E)){k=false;break}j(p);M-=A.y;C+=A.y;D=M*y;x+=r.width-D}else{j(p);j(l);if(A.x<=0)if(x>E){D-=A.x;x+=A.x}else A.y<=0&&C<=T&&(k=false);else{D-=A.x;x+=A.x}if(A.y<=0){if(C>T){M-=A.y;C+=A.y}}else{M-=A.y;C+=A.y}}if(D<0&&M<0){b=v;M=-M;D=-D;C-=M;x-=D}else if(D<0){b=u;D=-D;x-=D}else if(M<0){b=m;M=-M;C-=M}break;case m:if(y){if(A.x<=0&&(x<=E||O>=B)){k=false;break}j(l);D-=A.x;x+=A.x;M=D/y}else{j(d);j(l);if(A.x<=0)if(x>E){D-=A.x;x+=A.x}else A.y>=0&&O>=B&&(k=false);else{D-=A.x;x+=A.x}A.y>=0?O<B&&(M+=A.y):M+=A.y}if(D<0&&M<0){b=u;M=-M;D=-D;C-=M;x-=D}else if(D<0){b=v;D=-D;x-=D}else if(M<0){b=f;M=-M;C-=M}break;case v:if(y){if(A.x>=0&&(N>=L||O>=B)){k=false;break}j(c);D+=A.x;M=D/y}else{j(d);j(c);A.x>=0?N<L?D+=A.x:A.y>=0&&O>=B&&(k=false):D+=A.x;A.y>=0?O<B&&(M+=A.y):M+=A.y}if(D<0&&M<0){b=f;M=-M;D=-D;C-=M;x-=D}else if(D<0){b=m;D=-D;x-=D}else if(M<0){b=u;M=-M;C-=M}break;case s:this.move(A.x,A.y);k=false;break;case h:this.zoom(getMaxZoomRatio(g),t);k=false;break;case o:if(!A.x||!A.y){k=false;break}S=getOffset(this.cropper);x=z.startX-S.left;C=z.startY-S.top;D=r.minWidth;M=r.minHeight;if(A.x>0)b=A.y>0?v:u;else if(A.x<0){x-=D;b=A.y>0?m:f}A.y<0&&(C-=M);if(!this.cropped){removeClass(this.cropBox,w);this.cropped=true;this.limited&&this.limitCropBox(true,true)}break}if(k){r.width=D;r.height=M;r.left=x;r.top=C;this.action=b;this.renderCropBox()}forEach(g,(function(t){t.startX=t.endX;t.startY=t.endY}))}};var bt={crop:function crop(){if(this.ready&&!this.cropped&&!this.disabled){this.cropped=true;this.limitCropBox(true,true);this.options.modal&&addClass(this.dragBox,C);removeClass(this.cropBox,w);this.setCropBoxData(this.initialCropBoxData)}return this},reset:function reset(){if(this.ready&&!this.disabled){this.imageData=at({},this.initialImageData);this.canvasData=at({},this.initialCanvasData);this.cropBoxData=at({},this.initialCropBoxData);this.renderCanvas();this.cropped&&this.renderCropBox()}return this},clear:function clear(){if(this.cropped&&!this.disabled){at(this.cropBoxData,{left:0,top:0,width:0,height:0});this.cropped=false;this.renderCropBox();this.limitCanvas(true,true);this.renderCanvas();removeClass(this.dragBox,C);addClass(this.cropBox,w)}return this},
/**
   * Replace the image's src and rebuild the cropper
   * @param {string} url - The new URL.
   * @param {boolean} [hasSameSize] - Indicate if the new image has the same size as the old one.
   * @returns {Cropper} this
   */
replace:function replace(t){var e=arguments.length>1&&arguments[1]!==void 0&&arguments[1];if(!this.disabled&&t){this.isImg&&(this.element.src=t);if(e){this.url=t;this.image.src=t;if(this.ready){this.viewBoxImage.src=t;forEach(this.previews,(function(e){e.getElementsByTagName("img")[0].src=t}))}}else{this.isImg&&(this.replaced=true);this.options.data=null;this.uncreate();this.load(t)}}return this},enable:function enable(){if(this.ready&&this.disabled){this.disabled=false;removeClass(this.cropper,b)}return this},disable:function disable(){if(this.ready&&!this.disabled){this.disabled=true;addClass(this.cropper,b)}return this},
/**
   * Destroy the cropper and remove the instance from the image
   * @returns {Cropper} this
   */
destroy:function destroy(){var t=this.element;if(!t[r])return this;t[r]=void 0;this.isImg&&this.replaced&&(t.src=this.originalUrl);this.uncreate();return this},
/**
   * Move the canvas with relative offsets
   * @param {number} offsetX - The relative offset distance on the x-axis.
   * @param {number} [offsetY=offsetX] - The relative offset distance on the y-axis.
   * @returns {Cropper} this
   */
move:function move(t){var e=arguments.length>1&&arguments[1]!==void 0?arguments[1]:t;var i=this.canvasData,a=i.left,r=i.top;return this.moveTo(isUndefined(t)?t:a+Number(t),isUndefined(e)?e:r+Number(e))},
/**
   * Move the canvas to an absolute point
   * @param {number} x - The x-axis coordinate.
   * @param {number} [y=x] - The y-axis coordinate.
   * @returns {Cropper} this
   */
moveTo:function moveTo(t){var e=arguments.length>1&&arguments[1]!==void 0?arguments[1]:t;var i=this.canvasData;var a=false;t=Number(t);e=Number(e);if(this.ready&&!this.disabled&&this.options.movable){if(isNumber(t)){i.left=t;a=true}if(isNumber(e)){i.top=e;a=true}a&&this.renderCanvas(true)}return this},
/**
   * Zoom the canvas with a relative ratio
   * @param {number} ratio - The target ratio.
   * @param {Event} _originalEvent - The original event if any.
   * @returns {Cropper} this
   */
zoom:function zoom(t,e){var i=this.canvasData;t=Number(t);t=t<0?1/(1-t):1+t;return this.zoomTo(i.width*t/i.naturalWidth,null,e)},
/**
   * Zoom the canvas to an absolute ratio
   * @param {number} ratio - The target ratio.
   * @param {Object} pivot - The zoom pivot point coordinate.
   * @param {Event} _originalEvent - The original event if any.
   * @returns {Cropper} this
   */
zoomTo:function zoomTo(t,e,i){var a=this.options,r=this.canvasData;var n=r.width,o=r.height,s=r.naturalWidth,h=r.naturalHeight;t=Number(t);if(t>=0&&this.ready&&!this.disabled&&a.zoomable){var c=s*t;var l=h*t;if(dispatchEvent(this.element,_,{ratio:t,oldRatio:n/s,originalEvent:i})===false)return this;if(i){var d=this.pointers;var p=getOffset(this.cropper);var u=d&&Object.keys(d).length?getPointersCenter(d):{pageX:i.pageX,pageY:i.pageY};r.left-=(c-n)*((u.pageX-p.left-r.left)/n);r.top-=(l-o)*((u.pageY-p.top-r.top)/o)}else if(isPlainObject(e)&&isNumber(e.x)&&isNumber(e.y)){r.left-=(c-n)*((e.x-r.left)/n);r.top-=(l-o)*((e.y-r.top)/o)}else{r.left-=(c-n)/2;r.top-=(l-o)/2}r.width=c;r.height=l;this.renderCanvas(true)}return this},
/**
   * Rotate the canvas with a relative degree
   * @param {number} degree - The rotate degree.
   * @returns {Cropper} this
   */
rotate:function rotate(t){return this.rotateTo((this.imageData.rotate||0)+Number(t))},
/**
   * Rotate the canvas to an absolute degree
   * @param {number} degree - The rotate degree.
   * @returns {Cropper} this
   */
rotateTo:function rotateTo(t){t=Number(t);if(isNumber(t)&&this.ready&&!this.disabled&&this.options.rotatable){this.imageData.rotate=t%360;this.renderCanvas(true,true)}return this},
/**
   * Scale the image on the x-axis.
   * @param {number} scaleX - The scale ratio on the x-axis.
   * @returns {Cropper} this
   */
scaleX:function scaleX(t){var e=this.imageData.scaleY;return this.scale(t,isNumber(e)?e:1)},
/**
   * Scale the image on the y-axis.
   * @param {number} scaleY - The scale ratio on the y-axis.
   * @returns {Cropper} this
   */
scaleY:function scaleY(t){var e=this.imageData.scaleX;return this.scale(isNumber(e)?e:1,t)},
/**
   * Scale the image
   * @param {number} scaleX - The scale ratio on the x-axis.
   * @param {number} [scaleY=scaleX] - The scale ratio on the y-axis.
   * @returns {Cropper} this
   */
scale:function scale(t){var e=arguments.length>1&&arguments[1]!==void 0?arguments[1]:t;var i=this.imageData;var a=false;t=Number(t);e=Number(e);if(this.ready&&!this.disabled&&this.options.scalable){if(isNumber(t)){i.scaleX=t;a=true}if(isNumber(e)){i.scaleY=e;a=true}a&&this.renderCanvas(true,true)}return this},
/**
   * Get the cropped area position and size data (base on the original image)
   * @param {boolean} [rounded=false] - Indicate if round the data values or not.
   * @returns {Object} The result cropped data.
   */
getData:function getData(){var t=arguments.length>0&&arguments[0]!==void 0&&arguments[0];var e=this.options,i=this.imageData,a=this.canvasData,r=this.cropBoxData;var n;if(this.ready&&this.cropped){n={x:r.left-a.left,y:r.top-a.top,width:r.width,height:r.height};var o=i.width/i.naturalWidth;forEach(n,(function(t,e){n[e]=t/o}));if(t){var s=Math.round(n.y+n.height);var h=Math.round(n.x+n.width);n.x=Math.round(n.x);n.y=Math.round(n.y);n.width=h-n.x;n.height=s-n.y}}else n={x:0,y:0,width:0,height:0};e.rotatable&&(n.rotate=i.rotate||0);if(e.scalable){n.scaleX=i.scaleX||1;n.scaleY=i.scaleY||1}return n},
/**
   * Set the cropped area position and size with new data
   * @param {Object} data - The new data.
   * @returns {Cropper} this
   */
setData:function setData(t){var e=this.options,i=this.imageData,a=this.canvasData;var r={};if(this.ready&&!this.disabled&&isPlainObject(t)){var n=false;if(e.rotatable&&isNumber(t.rotate)&&t.rotate!==i.rotate){i.rotate=t.rotate;n=true}if(e.scalable){if(isNumber(t.scaleX)&&t.scaleX!==i.scaleX){i.scaleX=t.scaleX;n=true}if(isNumber(t.scaleY)&&t.scaleY!==i.scaleY){i.scaleY=t.scaleY;n=true}}n&&this.renderCanvas(true,true);var o=i.width/i.naturalWidth;isNumber(t.x)&&(r.left=t.x*o+a.left);isNumber(t.y)&&(r.top=t.y*o+a.top);isNumber(t.width)&&(r.width=t.width*o);isNumber(t.height)&&(r.height=t.height*o);this.setCropBoxData(r)}return this},
/**
   * Get the container size data.
   * @returns {Object} The result container data.
   */
getContainerData:function getContainerData(){return this.ready?at({},this.containerData):{}},
/**
   * Get the image position and size data.
   * @returns {Object} The result image data.
   */
getImageData:function getImageData(){return this.sized?at({},this.imageData):{}},
/**
   * Get the canvas position and size data.
   * @returns {Object} The result canvas data.
   */
getCanvasData:function getCanvasData(){var t=this.canvasData;var e={};this.ready&&forEach(["left","top","width","height","naturalWidth","naturalHeight"],(function(i){e[i]=t[i]}));return e},
/**
   * Set the canvas position and size with new data.
   * @param {Object} data - The new canvas data.
   * @returns {Cropper} this
   */
setCanvasData:function setCanvasData(t){var e=this.canvasData;var i=e.aspectRatio;if(this.ready&&!this.disabled&&isPlainObject(t)){isNumber(t.left)&&(e.left=t.left);isNumber(t.top)&&(e.top=t.top);if(isNumber(t.width)){e.width=t.width;e.height=t.width/i}else if(isNumber(t.height)){e.height=t.height;e.width=t.height*i}this.renderCanvas(true)}return this},
/**
   * Get the crop box position and size data.
   * @returns {Object} The result crop box data.
   */
getCropBoxData:function getCropBoxData(){var t=this.cropBoxData;var e;this.ready&&this.cropped&&(e={left:t.left,top:t.top,width:t.width,height:t.height});return e||{}},
/**
   * Set the crop box position and size with new data.
   * @param {Object} data - The new crop box data.
   * @returns {Cropper} this
   */
setCropBoxData:function setCropBoxData(t){var e=this.cropBoxData;var i=this.options.aspectRatio;var a;var r;if(this.ready&&this.cropped&&!this.disabled&&isPlainObject(t)){isNumber(t.left)&&(e.left=t.left);isNumber(t.top)&&(e.top=t.top);if(isNumber(t.width)&&t.width!==e.width){a=true;e.width=t.width}if(isNumber(t.height)&&t.height!==e.height){r=true;e.height=t.height}i&&(a?e.height=e.width/i:r&&(e.width=e.height*i));this.renderCropBox()}return this},
/**
   * Get a canvas drawn the cropped image.
   * @param {Object} [options={}] - The config options.
   * @returns {HTMLCanvasElement} - The result canvas.
   */
getCroppedCanvas:function getCroppedCanvas(){var t=arguments.length>0&&arguments[0]!==void 0?arguments[0]:{};if(!this.ready||!window.HTMLCanvasElement)return null;var e=this.canvasData;var i=getSourceCanvas(this.image,this.imageData,e,t);if(!this.cropped)return i;var a=this.getData(t.rounded),r=a.x,n=a.y,o=a.width,s=a.height;var h=i.width/Math.floor(e.naturalWidth);if(h!==1){r*=h;n*=h;o*=h;s*=h}var c=o/s;var l=getAdjustedSizes({aspectRatio:c,width:t.maxWidth||Infinity,height:t.maxHeight||Infinity});var d=getAdjustedSizes({aspectRatio:c,width:t.minWidth||0,height:t.minHeight||0},"cover");var p=getAdjustedSizes({aspectRatio:c,width:t.width||(h!==1?i.width:o),height:t.height||(h!==1?i.height:s)}),u=p.width,f=p.height;u=Math.min(l.width,Math.max(d.width,u));f=Math.min(l.height,Math.max(d.height,f));var v=document.createElement("canvas");var m=v.getContext("2d");v.width=normalizeDecimalNumber(u);v.height=normalizeDecimalNumber(f);m.fillStyle=t.fillColor||"transparent";m.fillRect(0,0,u,f);var g=t.imageSmoothingEnabled,b=g===void 0||g,w=t.imageSmoothingQuality;m.imageSmoothingEnabled=b;w&&(m.imageSmoothingQuality=w);var y=i.width;var x=i.height;var C=r;var D=n;var M;var N;var O;var E;var T;var L;if(C<=-o||C>y){C=0;M=0;O=0;T=0}else if(C<=0){O=-C;C=0;M=Math.min(y,o+C);T=M}else if(C<=y){O=0;M=Math.min(o,y-C);T=M}if(M<=0||D<=-s||D>x){D=0;N=0;E=0;L=0}else if(D<=0){E=-D;D=0;N=Math.min(x,s+D);L=N}else if(D<=x){E=0;N=Math.min(s,x-D);L=N}var B=[C,D,M,N];if(T>0&&L>0){var k=u/o;B.push(O*k,E*k,T*k,L*k)}m.drawImage.apply(m,[i].concat(_toConsumableArray(B.map((function(t){return Math.floor(normalizeDecimalNumber(t))})))));return v},
/**
   * Change the aspect ratio of the crop box.
   * @param {number} aspectRatio - The new aspect ratio.
   * @returns {Cropper} this
   */
setAspectRatio:function setAspectRatio(t){var e=this.options;if(!this.disabled&&!isUndefined(t)){e.aspectRatio=Math.max(0,t)||NaN;if(this.ready){this.initCropBox();this.cropped&&this.renderCropBox()}}return this},
/**
   * Change the drag mode.
   * @param {string} mode - The new drag mode.
   * @returns {Cropper} this
   */
setDragMode:function setDragMode(t){var e=this.options,i=this.dragBox,a=this.face;if(this.ready&&!this.disabled){var r=t===O;var n=e.movable&&t===E;t=r||n?t:T;e.dragMode=t;setData(i,M,t);toggleClass(i,g,r);toggleClass(i,D,n);if(!e.cropBoxMovable){setData(a,M,t);toggleClass(a,g,r);toggleClass(a,D,n)}}return this}};var wt=e.Cropper;var yt=function(){
/**
   * Create a new Cropper.
   * @param {Element} element - The target element for cropping.
   * @param {Object} [options={}] - The configuration options.
   */
function Cropper(t){var e=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{};_classCallCheck(this,Cropper);if(!t||!$.test(t.tagName))throw new Error("The first argument is required and must be an <img> or <canvas> element.");this.element=t;this.options=at({},G,isPlainObject(e)&&e);this.cropped=false;this.disabled=false;this.pointers={};this.ready=false;this.reloading=false;this.replaced=false;this.sized=false;this.sizing=false;this.init()}return _createClass(Cropper,[{key:"init",value:function init(){var t=this.element;var e=t.tagName.toLowerCase();var i;if(!t[r]){t[r]=this;if(e==="img"){this.isImg=true;i=t.getAttribute("src")||"";this.originalUrl=i;if(!i)return;i=t.src}else e==="canvas"&&window.HTMLCanvasElement&&(i=t.toDataURL());this.load(i)}}},{key:"load",value:function load(t){var e=this;if(t){this.url=t;this.imageData={};var i=this.element,a=this.options;a.rotatable||a.scalable||(a.checkOrientation=false);if(a.checkOrientation&&window.ArrayBuffer)if(q.test(t))K.test(t)?this.read(dataURLToArrayBuffer(t)):this.clone();else{var r=new XMLHttpRequest;var n=this.clone.bind(this);this.reloading=true;this.xhr=r;r.onabort=n;r.onerror=n;r.ontimeout=n;r.onprogress=function(){r.getResponseHeader("content-type")!==U&&r.abort()};r.onload=function(){e.read(r.response)};r.onloadend=function(){e.reloading=false;e.xhr=null};a.checkCrossOrigin&&isCrossOriginURL(t)&&i.crossOrigin&&(t=addTimestamp(t));r.open("GET",t,true);r.responseType="arraybuffer";r.withCredentials=i.crossOrigin==="use-credentials";r.send()}else this.clone()}}},{key:"read",value:function read(t){var e=this.options,i=this.imageData;var a=resetAndGetOrientation(t);var r=0;var n=1;var o=1;if(a>1){this.url=arrayBufferToDataURL(t,U);var s=parseOrientation(a);r=s.rotate;n=s.scaleX;o=s.scaleY}e.rotatable&&(i.rotate=r);if(e.scalable){i.scaleX=n;i.scaleY=o}this.clone()}},{key:"clone",value:function clone(){var t=this.element,e=this.url;var i=t.crossOrigin;var a=e;if(this.options.checkCrossOrigin&&isCrossOriginURL(e)){i||(i="anonymous");a=addTimestamp(e)}this.crossOrigin=i;this.crossOriginUrl=a;var r=document.createElement("img");i&&(r.crossOrigin=i);r.src=a||e;r.alt=t.alt||"The image to crop";this.image=r;r.onload=this.start.bind(this);r.onerror=this.stop.bind(this);addClass(r,y);t.parentNode.insertBefore(r,t.nextSibling)}},{key:"start",value:function start(){var t=this;var i=this.image;i.onload=null;i.onerror=null;this.sizing=true;var a=e.navigator&&/(?:iPad|iPhone|iPod).*?AppleWebKit/i.test(e.navigator.userAgent);var r=function done(e,i){at(t.imageData,{naturalWidth:e,naturalHeight:i,aspectRatio:e/i});t.initialImageData=at({},t.imageData);t.sizing=false;t.sized=true;t.build()};if(!i.naturalWidth||a){var n=document.createElement("img");var o=document.body||document.documentElement;this.sizingImage=n;n.onload=function(){r(n.width,n.height);a||o.removeChild(n)};n.src=i.src;if(!a){n.style.cssText="left:0;max-height:none!important;max-width:none!important;min-height:0!important;min-width:0!important;opacity:0;position:absolute;top:0;z-index:-1;";o.appendChild(n)}}else r(i.naturalWidth,i.naturalHeight)}},{key:"stop",value:function stop(){var t=this.image;t.onload=null;t.onerror=null;t.parentNode.removeChild(t);this.image=null}},{key:"build",value:function build(){if(this.sized&&!this.ready){var t=this.element,e=this.options,i=this.image;var a=t.parentNode;var o=document.createElement("div");o.innerHTML=V;var s=o.querySelector(".".concat(r,"-container"));var h=s.querySelector(".".concat(r,"-canvas"));var c=s.querySelector(".".concat(r,"-drag-box"));var l=s.querySelector(".".concat(r,"-crop-box"));var d=l.querySelector(".".concat(r,"-face"));this.container=a;this.cropper=s;this.canvas=h;this.dragBox=c;this.cropBox=l;this.viewBox=s.querySelector(".".concat(r,"-view-box"));this.face=d;h.appendChild(i);addClass(t,w);a.insertBefore(s,t.nextSibling);removeClass(i,y);this.initPreview();this.bind();e.initialAspectRatio=Math.max(0,e.initialAspectRatio)||NaN;e.aspectRatio=Math.max(0,e.aspectRatio)||NaN;e.viewMode=Math.max(0,Math.min(3,Math.round(e.viewMode)))||0;addClass(l,w);e.guides||addClass(l.getElementsByClassName("".concat(r,"-dashed")),w);e.center||addClass(l.getElementsByClassName("".concat(r,"-center")),w);e.background&&addClass(s,"".concat(r,"-bg"));e.highlight||addClass(d,x);if(e.cropBoxMovable){addClass(d,D);setData(d,M,n)}if(!e.cropBoxResizable){addClass(l.getElementsByClassName("".concat(r,"-line")),w);addClass(l.getElementsByClassName("".concat(r,"-point")),w)}this.render();this.ready=true;this.setDragMode(e.dragMode);e.autoCrop&&this.crop();this.setData(e.data);isFunction(e.ready)&&addListener(t,Y,e.ready,{once:true});dispatchEvent(t,Y)}}},{key:"unbuild",value:function unbuild(){if(this.ready){this.ready=false;this.unbind();this.resetPreview();var t=this.cropper.parentNode;t&&t.removeChild(this.cropper);removeClass(this.element,w)}}},{key:"uncreate",value:function uncreate(){if(this.ready){this.unbuild();this.ready=false;this.cropped=false}else if(this.sizing){this.sizingImage.onload=null;this.sizing=false;this.sized=false}else if(this.reloading){this.xhr.onabort=null;this.xhr.abort()}else this.image&&this.stop()}
/**
     * Get the no conflict cropper class.
     * @returns {Cropper} The cropper class.
     */}],[{key:"noConflict",value:function noConflict(){window.Cropper=wt;return Cropper}
/**
     * Change the default options.
     * @param {Object} options - The new default options.
     */},{key:"setDefaults",value:function setDefaults(t){at(G,isPlainObject(t)&&t)}}])}();at(yt.prototype,ut,ft,vt,mt,gt,bt);export{yt as default};
//# sourceMappingURL=cropper.esm.js.map
