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

  this.splitMeta = function(glosses) {

    var ss = glosses[0].split(' ');
    //var a = [];
    var r = {};

    Nu.each(ss, function(e) {
      var title = kanjiMeta[e.charAt(0)];
      //if ( ! title) a.push(e);
      if (title) r[title] = e.slice(1);
    });

    //glosses[0] = a.join(' ');
    glosses.splice(0, 1);

    return r;
  };

  return this;

}).apply({});

