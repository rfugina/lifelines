/* 
   Copyright (c) 2002 Perry Rapp
   "The MIT license"
   Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
   The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
/*===========================================================
 * xlat.h -- Header file for translation module
 * xlat module converts between named codesets
 * It uses iconv & charmaps as steps in a chain, as needed
 *=========================================================*/

#ifndef xlat_h_included
#define xlat_h_included

/* xlat.c */
XLAT xl_get_xlat(CNSTRING src, CNSTRING dest);
void xl_load_all_tts(CNSTRING ttpath);
void xl_free_adhoc_xlats(void);
void xl_free_xlats(void);
BOOLEAN xl_do_xlat(XLAT xlat, ZSTR * pzstr);

#endif /* xlat_h_included */
