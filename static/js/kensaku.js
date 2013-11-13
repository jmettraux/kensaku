/*
 * Copyright (c) 2012-2013, John Mettraux, jmettraux@gmail.com
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

var Ks = (function() {

  var self = this;

  this.codeToChar = function(c) {

    return String.fromCharCode(parseInt(c, 16));
  };

  this.charToCode = function(c, prefix) {

    if ( ! prefix) prefix = 'U';

    return prefix + c.charCodeAt(0).toString(16);
  };

  var kanjiMeta =
    {
      N: 'nlsn', B: 'nlsn 部首', C: 'cla 部首',
      S: 'strokes', G: 'grade', H: 'halpern', F: 'freq', P: 'skip',
      Q: '4co', M: '大漢和', Y: 'pinyin', W: 'korean', T: 't'
    };

  this.spliceMeta = function(glosses) {

    var r = {};

    var ss = glosses[0].split(' ');

    Nu.each(ss, function(e) {
      var title = kanjiMeta[e.charAt(0)];
      if (title) r[title] = e.slice(1);
    });

    glosses.splice(0, 1);

    return r;
  };

  this.intersection = function(array0, array1) {

    var a = [];

    var l;
    l = array0.length;
    for (var i = 0; i < l; i++) {
      var e = array0[i];
      if (array1.indexOf(e) > -1 && a.indexOf(e) < 0) a.push(e);
    }
    l = array1.length;
    for (var i = 0; i < l; i++) {
      var e = array1[i];
      if (array0.indexOf(e) > -1 && a.indexOf(e) < 0) a.push(e);
    }

    return a;
  };

  return this;

}).apply({});

