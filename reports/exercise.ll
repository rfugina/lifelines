/*
 * @progname       exercise
 * @version        0.100 (2002/07/23)
 * @author         Perry Rapp
 
 * @category       test

 * @output         mixed

 * @description    Perry's test program.

Exercises some report language functions,
and optionally does a gengedcomstrong dump of
the first few of each type of record.
May be used as a regression test.

 - Tests string functions
 - Tests date functions

TODO: logic tests
TODO: Add simple German & Greek date tests
TODO: Flag date tests for gedcom legal vs illegal

*/


/* This file is all ASCII, so we don't need to choose a codeset */
/* char_encoding("UTF-8") */

require("lifelines-reports.version:1.3")
option("explicitvars") /* Disallow use of undefined variables */
include("exer_UTF-8")
include("exer_8859-1")

global(dead)
global(cutoff_yr)
global(true)
global(undef) /* variable with no set value, used in string tests */
global(dbuse)
global(logout)
global(testok)
global(testfail)
global(testskip)


proc check_collate(str1, str2, str1nam, str2nam)
{
	if (ge(strcmp(str1,str2),0)) {
		set(fstr, concat("strcmp(", str1nam,",",str2nam,") FAILED"))
		call reportfail(fstr)
	}
}
func set_and_check_locale(locstr, locname)
{
	set(res, setlocale(locstr))
	if (nestr(res, "C")) {
		return(1)
	}
	call reportfail(concat("Locale missing: ", locstr, " (", locname, ")"))
	return (0)
}
proc testCollate()
{
	call testCollate_UTF_8()
	call testCollate_8859_1()
}

proc main()
{
	set(true,1)
	set(testok,0)
	set(testfail,0)
	set(testskip,0)

	getint(dbuse, "Exercise db functions ? (0=no)")
	set(cutoff_yr, 1900) /* assume anyone born before this is dead */

	if (not(dbuse)) {
	  getint(logout, "Output errors to file (0=no)")
	}

	getint(locales, "Test collation locales ? (0=no)")

	if (locales) {
		call testCollate()
	}
	call testStrings()
	call testNums()
	call testDates()

	if (dbuse) 
	{
	  call exerciseDb()
	}
}

proc exerciseDb()
{
	"database: " database() nl()
	"version: " version() nl()

	set(N, 5) /* output this many of each type of record */

	set(living,0)
	set(dead,0)

	/* count up # of living & dead indis, and output first 10 of each */
	nl() nl() "*** PERSONS ***" nl() nl()
	indiset(iset)
	forindi (person, pnum) 
	{
		/* exercise indi stuff with the first person */
		if (lt(add(living,dead),1)) 
		{
			call exerciseIndi(person)
		}
		/* output the first five living & first N dead people */
		if (isLivingPerson(person)) 
		{
			set(living,add(living,1))
			if (lt(living,N)) 
			{
				call outputLivingIndi(person)
				addtoset(iset,person,1)
			}
		}
		else
		{
			set(dead,add(dead,1))
			if (lt(dead,N)) 
			{
				call outputRec(person)
				addtoset(iset,person,0)
			}
		}
	}
	nl() "Live INDI: " d(living) nl()
	"Dead INDI: " d(dead) nl()

	set(living,0)
	set(dead,0)
	/* count up # of living & dead fams, and output first 10 of each */

	nl() nl() "*** FAMILIES ***" nl() nl()
	forfam (fam, fnum)
	{
		/* output the first N living & first five dead families */
		if (isLivingFam(fam)) 
		{
			set(living,add(living,1))
			if (lt(living,N)) 
			{
				call outputLivingFam(fam)
			}
		}
		else 
		{
			set(dead,add(dead,1))
			if (lt(dead,N)) 
			{
				call outputRec(fam)
			}
		}
	}
	nl() "Live FAM: " d(living) nl()
	"Dead FAM: " d(dead) nl()

	nl() nl() "*** SOURCES ***" nl() nl()
	forsour (sour,snum) 
	{
		if (lt(snum,N)) 
		{
			call outputRec(sour)
		}
	}
	
	nl() nl() "*** EVENTS ***" nl() nl()
	foreven (even,enum) 
	{
		if (lt(enum,N)) 
		{
			call outputRec(even)
		}
	}

	nl() nl() "*** OTHERS ***" nl() nl()
	forothr (othr,onum) 
	{
		if (lt(onum,N)) 
		{
			call outputRec(othr)
		}
	}

	nl() nl() "*** GENGEDCOMSTRONG *** " nl() nl()
	gengedcomstrong(iset)
}

/* Output entire record, except filter out SOUR & NOTE sections */
proc outputRec(record)
{
	traverse (root(record), node, level) 
	{
		if (or(eq(level,0),and(ne(tag(node),"SOUR"),ne(tag(node),"NOTE")))) 
		{
			d(level) " " xref(node) " " tag(node) " " value(node)
			nl()
		}
	}
}

proc outputLivingIndi(indi)
{
	"0 @" key(indi) "@ INDI" nl()
	"1 NAME " fullname(indi,0,1,50) nl()
	fornodes(inode(indi), node) 
	{
		if (isFamilyPtr(node)) 
		{
			"1 " xref(node) " " tag(node) " " value(node)
			nl()
		}
	}
}

proc outputLivingFam(fam)
{
	"0 @" key(fam) "@ FAM" nl()
	fornodes(root(fam), node) 
	{
		if (isMemberPtr(node)) 
		{
			"1 " xref(node) " " tag(node) " " value(node)
			nl()
		}
	}
}

func isLivingFam(fam)
{
	fornodes(root(fam), node) 
	{
		if (isMemberPtr(node)) 
		{
			if (isLivingPerson(indi(value(node)))) { return (1) }
		}
	}
	return (0)
}

func isLivingPerson(indi)
{
	if (death(indi)) { return (0) }
	if (birth(indi)) 
	{
		extractdate(birth(indi),day,mon,yr)
		if (and(gt(yr,300),lt(yr,cutoff_yr))) { return (0) }
	}
	return (1)
}


func isFamilyPtr (node) 
{
	if (eq(tag(node),"FAMC")) { return (1) }
	if (eq(tag(node),"FAMS")) { return (1) }
	return (0)
}

func isMemberPtr (node) 
{
	if (eq(tag(node),"HUSB")) { return (1) }
	if (eq(tag(node),"WIFE")) { return (1) }
	if (eq(tag(node),"CHIL")) { return (1) }
	return (0)
}

/* Uses a lot of function calls */
proc exerciseIndi(indi)
{
	list(lst)
	set(em, empty(lst))
	enqueue(lst, indi)
	push(lst, father(indi))
	requeue(lst, mother(indi))
	set(junk,pop(lst))
	setel(lst, 1, nextsib(indi))
	forlist(lst, el, count)
	{
		name(el) " " d(count) nl()
	}
	table(tbl)
	insert(tbl, "bob", indi)
	set(thing, lookup(tbl, "bob"))
	indiset(iset)
	addtoset(iset,indi,"bob")
	set(iset,union(iset,parentset(iset)))
	addtoset(iset,indi,"jerry")
	addtoset(iset,father(indi), "dad")
	addtoset(iset,mother(indi), "mom")
	addtoset(iset,nextsib(indi), "bro")
	spouses(indi,spouse,fam,num)
	{
		addtoset(iset,spouse,fam)
		"spouse: " fullname(spouse, true, true, 20) nl()
	}
	families(indi,fam,spouse,num)
	{
		addtoset(iset,spouse,num)
		"family: " key(fam) nl()
	}
	addtoset(iset,nextindi(indi),"next")
	addtoset(iset,previndi(indi),"prev")
	set(p,99)
	"name: " name(indi) nl()
	"title: " title(indi) nl()
	"key: " key(indi) nl()
	parents(indi) nl()
	"fullname(12): " fullname(indi,true,true,12) nl()
	"surname: " surname(indi) nl()
	"givens: " givens(indi) nl()
	"trimname(8): " trimname(indi,8) nl()
	lock(indi)
	call dumpnode("birth", birth(indi))
	call dumpnodetr("death", death(indi))
	unlock(indi)
}

proc dumpnode(desc, node)
{
	if (node)
	{
		desc ": " xref(node) " " tag(node) " " value(node)
		fornodes(node, child)
		{
			call dumpnode2(child)
		}
	}
}

proc dumpnode2(node)
{
	xref(node) " " tag(node) " " value(node)
	fornodes(node, child)
	{
		call dumpnode2(child)
	}
}

proc dumpnodetr(desc, node)
{
	if (node)
	{
		desc ": " xref(node) " " tag(node) " " value(node) nl()
		traverse(node, child,lvl)
		{
			xref(node) " " tag(node) " " value(node) nl()
		}
	}
}

/* report failure to screen, as well to to output */
proc reportfail(str)
{
	print(str)
	print("\n")
	if (or(dbuse, logout)) {
		str nl()
	}
	incr(testfail)
}

/*
 test some string functions against defined & undefined strings
  */
proc testStrings()
{
	set(testok, 0)
	set(testfail, 0)
	set(testskip, 0)

	set(str,"hey")
	set(str2,upper(str))
	if (ne(str2,"HEY")) {
		call reportfail("upper FAILED")
	}
	else { incr(testok) }

	set(str4,capitalize(str))
	if (ne(str4,"Hey")) {
		call reportfail("capitalize FAILED")
	}
	else { incr(testok) }

	set(str4,titlecase(str))
	if (ne(str4,"Hey")) {
		call reportfail("titlecase FAILED")
	}
	else { incr(testok) }

	set(str6,concat(str2,str4))
	if (ne(str6,"HEYHey")) {
		call reportfail("concat FAILED")
	}
	else { incr(testok) }

	set(str3,upper(undef))
	set(str5,capitalize(undef))
	set(str5,titlecase(undef))
	set(str7,concat(str3,str5))
	if (ne(str7,undef)) {
		call reportfail("concat FAILED on undefs")
	}
	else { incr(testok) }

	set(str7,strconcat(str3,str5))
	if (ne(str7,undef)) {
		call reportfail("strconcat FAILED on undefs")
	}
	else { incr(testok) }

	set(str8,lower(str4))
	if (ne(str8,"hey")) {
		call reportfail("lower FAILED")
	}
	else { incr(testok) }

	set(str9,lower(undef))
	if (ne(str9,undef)) {
		call reportfail("lower FAILED on undef")
	}
	else { incr(testok) }

	set(str10,alpha(3))
	if(ne(str10,"c")) {
		call reportfail("alpha(3) FAILED")
	}
	else { incr(testok) }

	set(str10,roman(4))
	if(ne(str10,"iv")) {
		call reportfail("roman(4) FAILED")
	}
	else { incr(testok) }

	set(str11,d(43))
	if(ne(str11,"43")) {
		call reportfail("d(43) FAILED")
	}
	else { incr(testok) }

	set(str12,card(4))
	if(ne(str12,"four")) {
		call reportfail("card(4) FAILED")
	}
	else { incr(testok) }

	set(str13,ord(5))
	if(ne(str13,"fifth")) {
		call reportfail("ord(5) FAILED")
	}
	else { incr(testok) }

	set(str14,titlecase("big  brown 1mean horse"))
	if(ne(str14,"Big  Brown 1mean Horse")) {
		call reportfail("titlecase FAILED")
	}
	else { incr(testok) }

	if (ge(strcmp("alpha","beta"),0)) {
		call reportfail("strcmp(alpha,beta) FAILED")
	}
	else { incr(testok) }

	if (le(strcmp("gamma","delta"),0)) {
		call reportfail("strcmp(gamma,delta) FAILED")
	}
	else { incr(testok) }

	if (ne(strcmp("zeta","zeta"),0)) {
		call reportfail("strcmp(zeta,zeta) FAILED")
	}
	else { incr(testok) }

	if (ne(strcmp(undef,""),0)) {
		call reportfail("strcmp(undef,) FAILED")
	}
	else { incr(testok) }

	if (ne(substring("considerable",2,4),"ons")) {
		call reportfail("substring(considerable,2,4) FAILED")
	}
	else { incr(testok) }

	if (ne(substring(undef,2,4),0)) {
		call reportfail("substring(undef,2,4) FAILED")
	}
	else { incr(testok) }

	if (ne(rjustify("hey",5), "  hey")) {
		call reportfail("rjustify(hey,5) FAILED")
	}
	else { incr(testok) }

	if (ne(rjustify("heymon",5), "heymo")) {
		call reportfail("rjustify(heymon,5) FAILED")
	}
	else { incr(testok) }

	/* eqstr returns bool, which may be compared to 0 but no other number */
	if (ne(eqstr("alpha","beta"),0)) {
		call reportfail("eqstr(alpha,beta) FAILED")
	}
	else { incr(testok) }

	if (not(eqstr("alpha","alpha"))) {
		call reportfail("eqstr(alpha,alpha) FAILED")
	}
	else { incr(testok) }

	if (ne(strtoint("4"), 4)) {
		call reportfail("strtoint(4) FAILED")
	}
	else { incr(testok) }

	if (ne(strsoundex("pat"),strsoundex("pet"))) {
		call reportfail("soundex(pat) FAILED")
	}
	else { incr(testok) }

	if (ne(strlen("pitch"),5)) {
		call reportfail("strlen(pitch) FAILED")
	}
	else { incr(testok) }

	set(str14,"the cat in the hat put the sack on the rat and the hat on the bat ")
	if (ne(index(str14,"at",1),6)) {
		call reportfail("index(str14,at,1) FAILED")
	}
	else { incr(testok) }

	if (ne(index(str14,"at",2),17)) 
	{
		call reportfail("index(str14,at,2) FAILED")
	}
	else { incr(testok) }

	if (ne(index(str14,"at",3),41)) 
	{
		call reportfail("index(str14,at,3) FAILED")
	}
	else { incr(testok) }

	if (ne(index(str14,"at",4),53)) 
	{
		call reportfail("index(str14,at,4) FAILED")
	}
	else { incr(testok) }

	if (ne(index(str14,"at",5),64)) 
	{
		call reportfail("index(str14,at,5) FAILED")
	}
	else { incr(testok) }

	if (ne(strlen(str14),66)) 
	{
		call reportfail("strlen(str14) FAILED")
	}
	else { incr(testok) }

	set(str15,strconcat(str14,str14))
	if (ne(strlen(str15),132)) 
	{
		call reportfail("strlen(str15) FAILED")
	}
	else { incr(testok) }

	if (ne(index(str15,"at",10),130)) 
	{
		call reportfail("index(str15,at,10) FAILED")
	}
	else { incr(testok) }

	set(str16,strconcat(str15,str15))
	if (ne(strlen(str16),264)) 
	{
		call reportfail("strlen(str16) FAILED")
	}
	else { incr(testok) }

	if (ne(index(str16,"at",20),262)) 
	{
		call reportfail("index(str16,at,20) FAILED")
	}
	else { incr(testok) }

	if (ne(substring(str16,260,262)," ba")) 
	{
		call reportfail("substring(str16,260,262) FAILED")
	}
	else { incr(testok) }

    call reportSubsection("string tests")
}

/*
 test some numeric functions 
 */
proc testNums()
{
	set(testok, 0)
	set(testfail, 0)

	set(one,1)
	set(two,add(one,one))
	if (ne(two,2)) {
		call reportfail("1+1 FAILED")
	}
	else { incr(testok) }

	if (eq(two,one)) {
		call reportfail("1==2 FAILED")
	}
	else { incr(testok) }

	if (ne(add(two,two,two,two,two),10)) {
		call reportfail("2+2+2+2+2 FAILED")
	}
	else { incr(testok) }

	if (ne(sub(two,one),1)) {
		call reportfail("2-1 FAILED")
	}
	else { incr(testok) }

	if (ne(sub(890,30),860)) {
		call reportfail("890-30 FAILED")
	}
	else { incr(testok) }

	if (ne(mul(3,4),12)) {
		call reportfail("3*4 FAILED")
	}
	else { incr(testok) }

	if (ne(mul(3,-4),-12)) {
		call reportfail("3*(-4) FAILED")
	}
	else { incr(testok) }

	if (ne(mul(-3,-4),12)) {
		call reportfail("(-3)*(-4) FAILED")
	}
	else { incr(testok) }

	if (ne(mul(.5,.5),.25)) {
		call reportfail(".5*.5 FAILED")
	}
	else { incr(testok) }

	if (ne(mul(2,.5),1)) {
		call reportfail("2*.5 FAILED")
	}
	else { incr(testok) }

	if (gt(.5, .7)) {
		call reportfail(".5>.7 FAILED")
	}
	else { incr(testok) }

	if (lt(-.4,-.5)) {
		call reportfail("-.4<-.5 FAILED")
	}
	else { incr(testok) }

	if (ge(15,18)) {
		call reportfail("15>=18 FAILED")
	}
	else { incr(testok) }

	if (le(-.4,-.5)) {
		call reportfail("-.4<=-.5 FAILED")
	}
	else { incr(testok) }

	if (not(le(-.4,-.4))) {
		call reportfail("-.4<=-.4 FAILED")
	}
	else { incr(testok) }

	if (not(le(-1,-.4))) {
		call reportfail("-1<=-.4 FAILED")
	}
	else { incr(testok) }

	if (not(le(-1.1,-1))) {
		call reportfail("-1.1<=-1 FAILED")
	}
	else { incr(testok) }

	if (ne(div(20, 4), 5)) {
		call reportfail("20/4==5 FAILED")
	}
	else { incr(testok) }

	if (ne(mod(22, 7), 1)) {
		call reportfail("22 % 7==1 FAILED")
	}
	else { incr(testok) }

	if (ne(exp(2, 10), 1024)) {
		call reportfail("2 ^10 ==1024 FAILED")
	}
	else { incr(testok) }

	if (ne(exp(.5, 2), .25)) {
		call reportfail(".5 ^2 ==.25 FAILED")
	}
	else { incr(testok) }

	set(bubba,34)
	incr(bubba)
	if (ne(bubba,35)) {
		call reportfail("incr(34) == 35 FAILED")
	}
	else { incr(testok) }

	set(bubba,45)
	decr(bubba)
	if (ne(bubba,44)) {
		call reportfail("decr(45) == 44 FAILED")
	}
	else { incr(testok) }

	set(bubba,45.3)
	decr(bubba)
	if (ne(bubba,44.3)) {
		call reportfail("decr(45.3) == 44.3 FAILED")
	}
	else { incr(testok) }

	set(bubba,34.3)
	incr(bubba)
	if (ne(bubba,35.3)) {
		call reportfail("incr(34.3) == 35.3 FAILED")
	}
	else { incr(testok) }

	set(bubba,45.6)
	decr(bubba)
	if (ne(bubba,44.6)) {
		call reportfail("decr(45.6) == 44.6 FAILED")
	}
	else { incr(testok) }

	if (ne(neg(52), -52)) {
		call reportfail("neg(52) == -52 FAILED")
	}
	else { incr(testok) }

    call reportSubsection("number tests")
}

/* 
  (Worker routine for testDates)
  Test parsing & formatting simultaneously
  Using specified formats, check stddate(src) against dests
  and complexdate(src) against destc
  tdfb = test date format both (simple & complex)
  If destc="*", then we'll test complexdate result against dests
  */
proc tdfb(src, dayfmt, monfmt, yrfmt, sfmt, ofmt, cfmt, dests, destc)
{
	dayformat(dayfmt)
	monthformat(monfmt)
	yearformat(yrfmt)
	dateformat(sfmt)
	eraformat(ofmt)
	set(result, stddate(src))
	if (ne(result, dests)) 
	{
		set(orig, concat(src,", ", d(dayfmt), ", ", d(monfmt)))
		set(orig, concat(orig, ", ", d(yrfmt), ", ",d(sfmt)))
		set(orig, concat(orig, ", ", d(ofmt)))
		call reportfail(concat("stddate failure: '", dests, "'<>'", result, "'", " from ", orig))
	} else {
		incr(testok)
	}
	complexformat(cfmt)
	if (eq(destc,"*"))
	{
		set(destc, dests)
	}
	set(result, complexdate(src))
	if (ne(result, destc)) 
	{
		set(orig, concat(src,", ", d(dayfmt), ", ", d(monfmt)))
		set(orig, concat(orig, ", ", d(yrfmt), ", ",d(sfmt)))
		set(orig, concat(orig, ", ", d(ofmt)))
		call reportfail(concat("complexdate failure: '", destc, "'<>'", result, "'", " from ", orig))
	} else {
		incr(testok)
	}
}

/*
 Test parsing only, using year(), month(), and day() functions 
 src is the string to parse
 yr,mo,da is the correct output against which to test
*/

proc tdparse(src, yr, mo, da)
{
	set(result, strtoint(year(src)))
	if (ne(result, yr)) 
	{
		call reportfail(concat("year(", src, ") failure: ", d(yr), "<>", d(result)))
	} else {
		incr(testok)
	}
	extractdatestr(modvar, dvar, mvar, yvar, ystvar, src)
	if (ne(yvar, yr))
	{
		call reportfail(concat("extractdatestr(", src, ").yr failure: ", d(yr), "<>", d(yvar)))
	} else {
		incr(testok)
	}
	if (ne(mvar, mo))
	{
		call reportfail(concat("extractdatestr(", src, ").mo failure: ", d(mo), "<>", d(mvar)))
	} else {
		incr(testok)
	}
	if (ne(dvar, da))
	{
		call reportfail(concat("extractdatestr(", src, ").da failure: ", d(da), "<>", d(dvar)))
	} else {
		incr(testok)
	}
}

/* 
  test some date functions with various GEDCOM dates
  */
proc testDates()
{
	set(testok, 0)
	set(testfail, 0)

	set_and_check_locale("en_US", "English")
	
/* Test parsing only */
	call tdparse("2 JAN 1953", 1953, 1, 2)
	call tdparse("14 FEB 857", 857, 2, 14)
	call tdparse("8/14/33", 33, 8, 14)
	call tdparse("9/22/1", 1, 9, 22)
	call tdparse("14 OCT 3 B.C.", 3, 10, 14)
	call tdparse("9/22/1", 1, 9, 22)
	call tdparse("AFT 3 SEP 1630", 1630, 9, 3)
	call tdparse("FROM 30 SEP 1630 TO 1700", 1630, 9, 30)
	call tdparse("@#DJULIAN@ 5 MAY 1204", 1204, 5, 5)
	call tdparse("@#DHEBREW@ 1 ADR 3011", 3011, 6, 1)
	call tdparse("@#DFRENCH R@ 1 VEND 11", 11, 1, 1)
	call tdparse("junk", 0, 0, 0)
	call tdparse("15 ___ 1945", 1945, 0, 15)
	call tdparse("__ ___ 1945", 1945, 0, 0)
	call tdparse("_ ___ 1950", 1950, 0, 0)
	call tdparse("_ ___ 90", 90, 0, 0)
	call tdparse("2/3 JAN 1953", 1953, 1, 2)
	call tdparse("2/3 JAN 1953/4", 1953, 1, 2)
	call tdparse("2/3 JAN 1953/54", 1953, 1, 2)
	call tdparse("2/3 JAN 1953/954", 1953, 1, 2)
	call tdparse("FROM 2/3 JAN 1953/954 TO 2004", 1953, 1, 2)
	call tdparse("2 JAN 1950s", 1950, 1, 2)
	call tdparse("2-5 JAN 1950-1970", 1950, 1, 2)
	call tdparse("2-13 OCT 1880-87", 1880, 10, 2)
	call tdparse("1930-11-24", 1930, 11, 24)


/* NB: We do not test all possible format combinations, as there are quite a lot
  (3 day formats, 11 month formats, 3 year formats, 14 combining formats,
  9 era formats -- multiply out to over thousands of combinations for stddate
  and times 6 cmplx formats for each complex date) */


	datepic(0)
/* test simple 4 digit year dates */
	/* test different day formats */
	call tdfb("2 JAN 1953", 0, 0, 0, 0, 0, 1, " 2  1 1953", "*")
	call tdfb("2 JAN 1953", 1, 0, 0, 0, 0, 1, "02  1 1953", "*")
	call tdfb("2 JAN 1953", 2, 0, 0, 0, 0, 1, "2  1 1953", "*")
	/* test different month formats */
	call tdfb("2 JAN 1953", 2, 1, 0, 0, 0, 1, "2 01 1953", "*")
	call tdfb("2 JAN 1953", 2, 2, 0, 0, 0, 1, "2 1 1953", "*")
	call tdfb("2 JAN 1953", 2, 3, 0, 0, 0, 1, "2 JAN 1953", "*")
	call tdfb("2 JAN 1953", 2, 4, 0, 0, 0, 1, "2 Jan 1953", "*")
	call tdfb("2 JAN 1953", 2, 5, 0, 0, 0, 1, "2 JANUARY 1953", "*")
	call tdfb("2 JAN 1953", 2, 6, 0, 0, 0, 1, "2 January 1953", "*")
	call tdfb("2 JAN 1953", 2, 7, 0, 0, 0, 1, "2 jan 1953", "*")
	call tdfb("2 JAN 1953", 2, 8, 0, 0, 0, 1, "2 january 1953", "*")
	call tdfb("2 JAN 1953", 2, 9, 0, 0, 0, 1, "2 JAN 1953", "*")
	call tdfb("2 JAN 1953", 2,10, 0, 0, 0, 1, "2 i 1953", "*")
	call tdfb("2 JAN 1953", 2,11, 0, 0, 0, 1, "2 I 1953", "*")
	/* test different era formats */
	call tdfb("2 JAN 1953", 2, 2, 0, 0, 2, 1, "2 1 1953 A.D.", "*")
	call tdfb("2 JAN 1953", 2, 2, 0, 0, 12, 1, "2 1 1953 AD", "*")
	call tdfb("2 JAN 1953", 2, 2, 0, 0, 22, 1, "2 1 1953 C.E.", "*")
	call tdfb("2 JAN 1953", 2, 2, 0, 0, 32, 1, "2 1 1953 CE", "*")
	/* test different date (ymd) formats */
	call tdfb("2 JAN 1953", 2, 2, 0, 1, 32, 1, "1 2, 1953 CE", "*")
	call tdfb("2 JAN 1953", 2, 2, 0, 2, 32, 1, "1/2/1953 CE", "*")
	call tdfb("2 JAN 1953", 2, 2, 0, 3, 32, 1, "2/1/1953 CE", "*")
	call tdfb("2 JAN 1953", 2, 2, 0, 4, 32, 1, "1-2-1953 CE", "*")
	call tdfb("2 JAN 1953", 2, 2, 0, 5, 32, 1, "2-1-1953 CE", "*")
	call tdfb("2 JAN 1953", 2, 2, 0, 6, 32, 1, "121953 CE", "*")
	call tdfb("2 JAN 1953", 2, 2, 0, 7, 32, 1, "211953 CE", "*")
	call tdfb("2 JAN 1953", 2, 2, 0, 8, 32, 1, "1953 1 2 CE", "*")
	call tdfb("2 JAN 1953", 2, 2, 0, 9, 32, 1, "1953/1/2 CE", "*")
	call tdfb("2 JAN 1953", 2, 2, 0, 10, 32, 1, "1953-1-2 CE", "*")
	call tdfb("2 JAN 1953", 2, 2, 0, 11, 32, 1, "195312 CE", "*")
	call tdfb("2 JAN 1953", 2, 2, 0, 12, 32, 1, "1953", "*")
	call tdfb("2 JAN 1953", 2, 2, 0, 13, 32, 1, "2/1 1953 CE", "*")
	call tdfb("2 JAN 1953", 2, 2, 0, 14, 32, 1, "2 JAN 1953", "*")
	/* test custom date pic */
	datepic("%d.%m.%y")
	call tdfb("2 JAN 1953", 2, 2, 0, 10, 32, 1, "2.1.1953 CE", "*")
	datepic("%d of %m, %y")
	call tdfb("2 JAN 1953", 2, 4, 0, 10, 1, 1, "2 of Jan, 1953", "*")
	datepic("%y.%m.%d")
	call tdfb("2 JAN 1953", 2, 10, 2, 10, 1, 1, "1953.i.2", "*")
	datepic(0)
	/* test missing day or month (legal in GEDCOM) */
	call tdfb("2 JAN 1953", 1, 1, 1, 2, 2, 1, "01/02/1953 A.D.", "*")
	call tdfb("JAN 1953", 1, 1, 1, 2, 2, 1, "01/  /1953 A.D.", "*")
	call tdfb("1953", 1, 1, 1, 2, 2, 1, "  /  /1953 A.D.", "*")

/* test Italian months */
	if (not(set_and_check_locale("it", "Italian"))) {
	set(testskip, add(testskip, 6))
	} else {
	call tdfb("2 JAN 1953", 2, 3, 0, 0, 0, 1, "2 GEN 1953", "*")
	call tdfb("2 JAN 1953", 2, 4, 0, 0, 0, 1, "2 Gen 1953", "*")
	call tdfb("2 JAN 1953", 2, 5, 0, 0, 0, 1, "2 GENNAIO 1953", "*")
	call tdfb("2 JAN 1953", 2, 6, 0, 0, 0, 1, "2 Gennaio 1953", "*")
	call tdfb("2 JAN 1953", 2, 7, 0, 0, 0, 1, "2 gen 1953", "*")
	call tdfb("2 JAN 1953", 2, 8, 0, 0, 0, 1, "2 gennaio 1953", "*")
	set_and_check_locale("en_US", "English")
	}

/* test Swedish months */
	if (not(set_and_check_locale("sv", "Swedish"))) {
	set(testskip, add(testskip, 6))
	} else {
	call tdfb("2 OCT 1953", 2, 3, 0, 0, 0, 1, "2 OKT 1953", "*")
	call tdfb("2 OCT 1953", 2, 4, 0, 0, 0, 1, "2 Okt 1953", "*")
	call tdfb("2 OCT 1953", 2, 5, 0, 0, 0, 1, "2 OKTOBER 1953", "*")
	call tdfb("2 OCT 1953", 2, 6, 0, 0, 0, 1, "2 Oktober 1953", "*")
	call tdfb("2 OCT 1953", 2, 7, 0, 0, 0, 1, "2 okt 1953", "*")
	call tdfb("2 OCT 1953", 2, 8, 0, 0, 0, 1, "2 oktober 1953", "*")
	set_and_check_locale("en_US", "English")
	}

/* test roman numeral months */
	call tdfb("2 JAN 1953", 2,10, 0, 0, 0, 1, "2 i 1953", "*")
	call tdfb("2 JAN 1953", 2,11, 0, 0, 0, 1, "2 I 1953", "*")
	call tdfb("2 FEB 1953", 2,10, 0, 0, 0, 1, "2 ii 1953", "*")
	call tdfb("2 FEB 1953", 2,11, 0, 0, 0, 1, "2 II 1953", "*")
	call tdfb("2 MAR 1953", 2,10, 0, 0, 0, 1, "2 iii 1953", "*")
	call tdfb("2 MAR 1953", 2,11, 0, 0, 0, 1, "2 III 1953", "*")
	call tdfb("2 APR 1953", 2,10, 0, 0, 0, 1, "2 iv 1953", "*")
	call tdfb("2 APR 1953", 2,11, 0, 0, 0, 1, "2 IV 1953", "*")
	call tdfb("2 MAY 1953", 2,10, 0, 0, 0, 1, "2 v 1953", "*")
	call tdfb("2 MAY 1953", 2,11, 0, 0, 0, 1, "2 V 1953", "*")
	call tdfb("2 JUN 1953", 2,10, 0, 0, 0, 1, "2 vi 1953", "*")
	call tdfb("2 JUN 1953", 2,11, 0, 0, 0, 1, "2 VI 1953", "*")
	call tdfb("2 JUL 1953", 2,10, 0, 0, 0, 1, "2 vii 1953", "*")
	call tdfb("2 JUL 1953", 2,11, 0, 0, 0, 1, "2 VII 1953", "*")
	call tdfb("2 AUG 1953", 2,10, 0, 0, 0, 1, "2 viii 1953", "*")
	call tdfb("2 AUG 1953", 2,11, 0, 0, 0, 1, "2 VIII 1953", "*")
	call tdfb("2 SEP 1953", 2,10, 0, 0, 0, 1, "2 ix 1953", "*")
	call tdfb("2 SEP 1953", 2,11, 0, 0, 0, 1, "2 IX 1953", "*")
	call tdfb("2 OCT 1953", 2,10, 0, 0, 0, 1, "2 x 1953", "*")
	call tdfb("2 OCT 1953", 2,11, 0, 0, 0, 1, "2 X 1953", "*")
	call tdfb("2 NOV 1953", 2,10, 0, 0, 0, 1, "2 xi 1953", "*")
	call tdfb("2 NOV 1953", 2,11, 0, 0, 0, 1, "2 XI 1953", "*")
	call tdfb("2 DEC 1953", 2,10, 0, 0, 0, 1, "2 xii 1953", "*")
	call tdfb("2 DEC 1953", 2,11, 0, 0, 0, 1, "2 XII 1953", "*")
	call tdfb("@#DHEBREW@ 2 ELL 1953", 2,10, 0, 0, 0, 1, "2 xiii 1953 HEB", "*")
	call tdfb("@#DHEBREW@ 2 ELL 1953", 2,11, 0, 0, 0, 1, "2 XIII 1953 HEB", "*")

/* test simple 3 digit year dates */
	call tdfb("11 MAY 812", 0, 0, 0, 0, 0, 1, "11  5  812", "*")
	call tdfb("11 MAY 812", 0, 1, 0, 0, 0, 1, "11 05  812", "*")
	call tdfb("11 MAY 812", 0, 2, 0, 0, 0, 1, "11 5  812", "*")
	call tdfb("11 MAY 812", 0, 3, 0, 0, 0, 1, "11 MAY  812", "*")
	call tdfb("11 MAY 812", 0, 4, 0, 0, 0, 1, "11 May  812", "*")
	call tdfb("11 MAY 812", 0, 5, 0, 0, 0, 1, "11 MAY  812", "*" )
	call tdfb("11 MAY 812", 0, 6, 0, 0, 0, 1, "11 May  812", "*")
	call tdfb("11 MAY 812", 1, 6, 0, 0, 0, 1, "11 May  812", "*")
	call tdfb("11 MAY 812", 2, 6, 0, 0, 0, 1, "11 May  812", "*")
	/* test missing day or month (legal in GEDCOM) */
	call tdfb("11 MAY 812", 1, 1, 1, 2, 2, 1, "05/11/0812 A.D.", "*")
	call tdfb("MAY 812", 1, 1, 1, 2, 2, 1, "05/  /0812 A.D.", "*")
	call tdfb("812", 1, 1, 1, 2, 2, 1, "  /  /0812 A.D.", "*")

/* test simple 2 digit year dates */
	call tdfb("2 JAN 53", 0, 0, 0, 0, 0, 1, " 2  1   53", "*")
	call tdfb("2 JAN 53", 1, 0, 0, 0, 0, 1, "02  1   53", "*")
	call tdfb("2 JAN 53", 2, 0, 0, 0, 0, 1, "2  1   53", "*")
	call tdfb("2 JAN 53", 2, 1, 0, 0, 0, 1, "2 01   53", "*")
	call tdfb("2 JAN 53", 2, 1, 1, 0, 0, 1, "2 01 0053", "*")
	call tdfb("2 JAN 53", 2, 1, 2, 0, 0, 1, "2 01 53", "*")
	/* test missing day or month (legal in GEDCOM) */
	call tdfb("2 JAN 53", 1, 1, 1, 2, 2, 1, "01/02/0053 A.D.", "*")
	call tdfb("JAN 53", 1, 1, 1, 2, 2, 1, "01/  /0053 A.D.", "*")
	call tdfb("53", 1, 1, 1, 2, 2, 1, "  /  /0053 A.D.", "*")

/* test simple 1 digit year dates */
	call tdfb("2 JAN 3", 0, 0, 0, 0, 0, 1, " 2  1    3", "*")
	call tdfb("2 JAN 3", 1, 0, 0, 0, 0, 1, "02  1    3", "*")
	call tdfb("2 JAN 3", 2, 0, 0, 0, 0, 1, "2  1    3", "*")
	call tdfb("2 JAN 3", 2, 1, 0, 0, 0, 1, "2 01    3", "*")
	call tdfb("2 JAN 3", 2, 1, 1, 0, 0, 1, "2 01 0003", "*")
	call tdfb("2 JAN 3", 2, 1, 2, 0, 0, 1, "2 01 3", "*")
	/* test missing day or month (legal in GEDCOM) */
	call tdfb("2 JAN 3", 1, 1, 1, 2, 2, 1, "01/02/0003 A.D.", "*")
	call tdfb("JAN 3", 1, 1, 1, 2, 2, 1, "01/  /0003 A.D.", "*")
	call tdfb("3", 1, 1, 1, 2, 2, 1, "  /  /0003 A.D.", "*")

/* test slash years */
	call tdfb("24 FEB 1956/7", 2, 2, 0, 10, 0, 0, "1956-2-24", "*")
	call tdfb("24 FEB 1956/57", 2, 2, 0, 10, 0, 0, "1956-2-24", "*")
	call tdfb("24 FEB 1956/957", 2, 2, 0, 10, 0, 0, "1956-2-24", "*")
	call tdfb("24 FEB 1956/1957", 2, 2, 0, 10, 0, 0, "1956-2-24", "*")

/* test simple BC dates */
	call tdfb("15 MAR 30 B.C.", 0, 0, 0, 0, 0, 1, "15  3   30", "*")
	call tdfb("15 MAR 30 B.C.", 0, 0, 0, 0, 1, 1, "15  3   30 B.C.", "*")
	call tdfb("15 MAR 30 B.C.", 0, 0, 1, 0, 1, 1, "15  3 0030 B.C.", "*")
	call tdfb("15 MAR 30 B.C.", 0, 0, 2, 0, 1, 1, "15  3 30 B.C.", "*")
	call tdfb("15 MAR 30 B.C.", 0, 0, 2, 0, 2, 1, "15  3 30 B.C.", "*")
	call tdfb("15 MAR 30 B.C.", 0, 0, 2, 0, 11, 1, "15  3 30 BC", "*")
	call tdfb("15 MAR 30 B.C.", 0, 0, 2, 0, 21, 1, "15  3 30 B.C.E.", "*")
	call tdfb("15 MAR 30 B.C.", 0, 0, 2, 0, 31, 1, "15  3 30 BCE", "*")
	call tdfb("15 MAR 30 (B.C.)", 0, 0, 0, 0, 0, 1, "15  3   30", "*")
	call tdfb("15 MAR 30 (B.C.)", 0, 0, 0, 0, 1, 1, "15  3   30 B.C.", "*")
	call tdfb("15 MAR 30 (B.C.)", 0, 0, 1, 0, 1, 1, "15  3 0030 B.C.", "*")
	call tdfb("15 MAR 30 (B.C.)", 0, 0, 2, 0, 1, 1, "15  3 30 B.C.", "*")
	call tdfb("15 MAR 30 (B.C.)", 0, 0, 2, 0, 2, 1, "15  3 30 B.C.", "*")
	call tdfb("15 MAR 30 (B.C.)", 0, 0, 2, 0, 11, 1, "15  3 30 BC", "*")
	call tdfb("15 MAR 30 (B.C.)", 0, 0, 2, 0, 21, 1, "15  3 30 B.C.E.", "*")
	call tdfb("15 MAR 30 (B.C.)", 0, 0, 2, 0, 31, 1, "15  3 30 BCE", "*")

/* test simple dates in non-GEDCOM format */
	/* It tries to handle 3 numbers, *if* it can find unambiguous interpretation */
	call tdfb("1930/11/24", 0, 0, 0, 0, 0, 1, "24 11 1930", "*")
	call tdfb("1930 11 24", 0, 0, 0, 0, 0, 1, "24 11 1930", "*")
	call tdfb("1930.11.24", 0, 0, 0, 0, 0, 1, "24 11 1930", "*")
	call tdfb("1930-11-24", 0, 0, 0, 0, 0, 1, "24 11 1930", "*")
	call tdfb("11/24/1930", 0, 0, 0, 0, 0, 1, "24 11 1930", "*")
	call tdfb("24/11/1930", 0, 0, 0, 0, 0, 1, "24 11 1930", "*")
	call tdfb("1956/7 FEB 24", 2, 2, 0, 10, 0, 0, "1956-2-24", "*")
	call tdfb("1956/57 FEB 24", 2, 2, 0, 10, 0, 0, "1956-2-24", "*")
	call tdfb("1956/957 FEB 24", 2, 2, 0, 10, 0, 0, "1956-2-24", "*")
	call tdfb("1956/1957 FEB 24", 2, 2, 0, 10, 0, 0, "1956-2-24", "*")
	call tdfb("1956/7 24 2", 2, 2, 0, 10, 0, 0, "1956-2-24", "*")
	call tdfb("1956/57 24 2", 2, 2, 0, 10, 0, 0, "1956-2-24", "*")
	call tdfb("1956/957 24 2", 2, 2, 0, 10, 0, 0, "1956-2-24", "*")
	call tdfb("1956/1957 24 2", 2, 2, 0, 10, 0, 0, "1956-2-24", "*")
	call tdfb("1956/7 24 2", 2, 2, 0, 10, 0, 0, "1956-2-24", "*")
	call tdfb("1956/57 24 2", 2, 2, 0, 10, 0, 0, "1956-2-24", "*")
	call tdfb("1956/957 24 2", 2, 2, 0, 10, 0, 0, "1956-2-24", "*")
	call tdfb("1956/1957 24 2", 2, 2, 0, 10, 0, 0, "1956-2-24", "*")

/* Complex tests */
	complexpic(4, 0)
	call tdfb("AFT 3 SEP 1630", 0, 0, 0, 0, 0, 1, " 3  9 1630", "after  3  9 1630")
	call tdfb("AFT 3 SEP 1630", 0, 0, 0, 0, 0, 3, " 3  9 1630", "AFT  3  9 1630")
	call tdfb("AFT 3 SEP 1630", 0, 0, 0, 0, 0, 4, " 3  9 1630", "Aft  3  9 1630")
	call tdfb("AFT 3 SEP 1630", 0, 0, 0, 0, 0, 5, " 3  9 1630", "AFTER  3  9 1630")
	call tdfb("AFT 3 SEP 1630", 0, 0, 0, 0, 0, 6, " 3  9 1630", "After  3  9 1630")
	call tdfb("AFT 3 SEP 1630", 0, 0, 0, 0, 0, 7, " 3  9 1630", "aft  3  9 1630")
	call tdfb("AFT 3 SEP 1630", 0, 0, 0, 0, 0, 8, " 3  9 1630", "after  3  9 1630")
	complexpic(4, ">%1")
	call tdfb("AFT 3 SEP 1630", 0, 0, 0, 0, 0, 8, " 3  9 1630", "> 3  9 1630")
	complexpic(4, 0)
	complexpic(3, 0)
	call tdfb("BEF 3 SEP 1630", 0, 0, 0, 0, 0, 1, " 3  9 1630", "before  3  9 1630")
	call tdfb("BEF 3 SEP 1630", 0, 0, 0, 0, 0, 3, " 3  9 1630", "BEF  3  9 1630")
	call tdfb("BEF 3 SEP 1630", 0, 0, 0, 0, 0, 4, " 3  9 1630", "Bef  3  9 1630")
	call tdfb("BEF 3 SEP 1630", 0, 0, 0, 0, 0, 5, " 3  9 1630", "BEFORE  3  9 1630")
	call tdfb("BEF 3 SEP 1630", 0, 0, 0, 0, 0, 6, " 3  9 1630", "Before  3  9 1630")
	call tdfb("BEF 3 SEP 1630", 0, 0, 0, 0, 0, 7, " 3  9 1630", "bef  3  9 1630")
	call tdfb("BEF 3 SEP 1630", 0, 0, 0, 0, 0, 8, " 3  9 1630", "before  3  9 1630")
	complexpic(3, "<%1")
	call tdfb("BEF 3 SEP 1630", 0, 0, 0, 0, 0, 8, " 3  9 1630", "< 3  9 1630")
	complexpic(3, 0)
	complexpic(5, 0)
	call tdfb("BET 3 SEP 1630 AND OCT 1900", 0, 0, 0, 0, 0, 1, " 3  9 1630", "between  3  9 1630 and    10 1900")
	complexpic(5, "%1/%2")
	call tdfb("BET 3 SEP 1630 AND OCT 1900", 2, 2, 0, 5, 0, 1, "3-9-1630", "3-9-1630/-10-1900")
	complexpic(5, 0)
	complexpic(6, 0)
	call tdfb("FROM 3 SEP 1630", 0, 0, 0, 0, 0, 1, " 3  9 1630", "from  3  9 1630")
	complexpic(7, 0)
	call tdfb("TO 3 SEP 1630", 0, 0, 0, 0, 0, 1, " 3  9 1630", "to  3  9 1630")
	complexpic(8, 0)
	call tdfb("FROM 3 SEP 1630 TO 1700", 0, 0, 0, 0, 0, 1, " 3  9 1630", "from  3  9 1630 to       1700")
	call tdfb("FROM 3 SEP 1630 TO 1700", 0, 0, 0, 0, 0, 3, " 3  9 1630", "FR  3  9 1630 TO       1700")
	call tdfb("FROM 3 SEP 1630 TO 1700", 0, 0, 0, 0, 0, 4, " 3  9 1630", "Fr  3  9 1630 To       1700")
	call tdfb("FROM 3 SEP 1630 TO 1700", 0, 0, 0, 0, 0, 5, " 3  9 1630", "FROM  3  9 1630 TO       1700")
	call tdfb("FROM 3 SEP 1630 TO 1700", 0, 0, 0, 0, 0, 6, " 3  9 1630", "From  3  9 1630 To       1700")
	call tdfb("FROM 3 SEP 1630 TO 1700", 0, 0, 0, 0, 0, 7, " 3  9 1630", "fr  3  9 1630 to       1700")
	call tdfb("FROM 3 SEP 1630 TO 1700", 0, 0, 0, 0, 0, 8, " 3  9 1630", "from  3  9 1630 to       1700")
	complexpic(8, "%1=>%2")
	call tdfb("FROM 3 SEP 1630 TO 1700", 2, 2, 0, 9, 0, 8, "1630/9/3", "1630/9/3=>1700//")
	complexpic(8, 0)
	complexpic(1, 0)
	call tdfb("ABT 3 SEP 890", 0, 0, 0, 0, 0, 1, " 3  9  890", "about  3  9  890")
	call tdfb("EST 3 SEP 890", 0, 0, 0, 0, 0, 1, " 3  9  890", "estimated  3  9  890")
	call tdfb("EST 3 SEP 890", 0, 0, 0, 0, 0, 3, " 3  9  890", "EST  3  9  890")
	call tdfb("EST 3 SEP 890", 0, 0, 0, 0, 0, 4, " 3  9  890", "Est  3  9  890")
	call tdfb("EST 3 SEP 890", 0, 0, 0, 0, 0, 5, " 3  9  890", "ESTIMATED  3  9  890")
	call tdfb("EST 3 SEP 890", 0, 0, 0, 0, 0, 6, " 3  9  890", "Estimated  3  9  890")
	call tdfb("EST 3 SEP 890", 0, 0, 0, 0, 0, 7, " 3  9  890", "est  3  9  890")
	call tdfb("EST 3 SEP 890", 0, 0, 0, 0, 0, 8, " 3  9  890", "estimated  3  9  890")
	complexpic(1, "~%1")
	call tdfb("EST 3 SEP 890", 0, 0, 0, 0, 0, 1, " 3  9  890", "~ 3  9  890")
	complexpic(1, 0)
	complexpic(2, 0)
	call tdfb("CAL 3 SEP 890", 2, 2, 2, 10, 0, 1, "890-9-3", "calculated 890-9-3")
	call tdfb("CAL 3 SEP 890", 2, 2, 2, 10, 0, 3, "890-9-3", "CAL 890-9-3")
	call tdfb("CAL 3 SEP 890", 2, 2, 2, 10, 0, 4, "890-9-3", "Cal 890-9-3")
	call tdfb("CAL 3 SEP 890", 2, 2, 2, 10, 0, 5, "890-9-3", "CALCULATED 890-9-3")
	call tdfb("CAL 3 SEP 890", 2, 2, 2, 10, 0, 6, "890-9-3", "Calculated 890-9-3")
	call tdfb("CAL 3 SEP 890", 2, 2, 2, 10, 0, 7, "890-9-3", "cal 890-9-3")
	call tdfb("CAL 3 SEP 890", 2, 2, 2, 10, 0, 8, "890-9-3", "calculated 890-9-3")
	complexpic(2, "^%1")
	call tdfb("CAL 3 SEP 890", 2, 2, 2, 10, 0, 1, "890-9-3", "^890-9-3")
	complexpic(2, "^")
	call tdfb("CAL 3 SEP 890", 2, 2, 2, 10, 0, 1, "890-9-3", "^")
	complexpic(2, "^%1^%1")
	call tdfb("CAL 3 SEP 890", 2, 2, 2, 10, 0, 1, "890-9-3", "^890-9-3^890-9-3")
	complexpic(2, 0)

/* Complex tests with bad input */
	call tdfb("24 SEP 811 TO 29 SEP 811", 0, 0, 0, 0, 0, 1, "24  9  811", "from 24  9  811 to 29  9  811")


/* Calendar tests */
	call tdfb("@#DGREGORIAN@ 1 JAN 1953", 2, 6, 0, 0, 0, 1, "1 January 1953", "*")
	call tdfb("@#DJULIAN@ 1 JAN 1953", 2, 6, 0, 0, 0, 1, "1 January 1953J", "*")

/* French Republic Calendar tests */
	call tdfb("@#DFRENCH R@ 1 VEND 11", 2, 0, 2, 0, 0, 1, "1  1 11 FR", "*")
	call tdfb("@#DFRENCH R@ 1 VEND 11", 2, 1, 2, 0, 0, 1, "1 01 11 FR", "*")
	call tdfb("@#DFRENCH R@ 1 VEND 11", 2, 2, 2, 0, 0, 1, "1 1 11 FR", "*")
	call tdfb("@#DFRENCH R@ 1 VEND 11", 2, 3, 2, 0, 0, 1, "1 VEND 11 FR", "*")
	call tdfb("@#DFRENCH R@ 1 VEND 11", 2, 4, 2, 0, 0, 1, "1 Vend 11 FR", "*")
	call tdfb("@#DFRENCH R@ 1 VEND 11", 2, 5, 2, 0, 0, 1, "1 VENDEMIAIRE 11 FR", "*")
	call tdfb("@#DFRENCH R@ 1 VEND 11", 2, 6, 2, 0, 0, 1, "1 Vendemiaire 11 FR", "*")
	call tdfb("@#DFRENCH R@ 1 VEND 11", 2, 7, 2, 0, 0, 1, "1 vend 11 FR", "1 vend 11 FR")
	call tdfb("@#DFRENCH R@ 1 VEND 11", 2, 8, 2, 0, 0, 1, "1 vendemiaire 11 FR", "1 vendemiaire 11 FR")
	call tdfb("@#DFRENCH R@ 1 BRUM 11", 2, 8, 2, 0, 0, 1, "1 brumaire 11 FR", "1 brumaire 11 FR")
	call tdfb("@#DFRENCH R@ 1 FRIM 11", 2, 8, 2, 0, 0, 1, "1 frimaire 11 FR", "1 frimaire 11 FR")
	call tdfb("@#DFRENCH R@ 1 NIVO 11", 2, 8, 2, 0, 0, 1, "1 nivose 11 FR", "1 nivose 11 FR")
	call tdfb("@#DFRENCH R@ 1 PLUV 11", 2, 8, 2, 0, 0, 1, "1 pluviose 11 FR", "*")
	call tdfb("@#DFRENCH R@ 1 VENT 11", 2, 8, 2, 0, 0, 1, "1 ventose 11 FR", "*")
	call tdfb("@#DFRENCH R@ 1 GERM 11", 2, 8, 2, 0, 0, 1, "1 germinal 11 FR", "*")
	call tdfb("@#DFRENCH R@ 1 FLOR 11", 2, 8, 2, 0, 0, 1, "1 floreal 11 FR", "*")
	call tdfb("@#DFRENCH R@ 1 PRAI 11", 2, 8, 2, 0, 0, 1, "1 prairial 11 FR", "*")
	call tdfb("BET @#DFRENCH R@ 1 PRAI 11 AND @#DFRENCH R@ 2 BRUM 12", 2, 8, 2, 0, 0, 1
		, "1 prairial 11 FR", "between 1 prairial 11 FR and 2 brumaire 12 FR")
	call tdfb("BET @#DFRENCH R@ 1 PRAI 11 AND @#DFRENCH R@ 2 BRUM 12", 2, 2, 2, 10, 0, 7
		, "11-9-1 FR", "bet 11-9-1 FR and 12-2-2 FR")

/* Hebrew Calendar tests */
	call tdfb("@#DHEBREW@ 1 TSH 3011", 2, 0, 0, 0, 0, 1, "1  1 3011 HEB", "*")
	call tdfb("@#DHEBREW@ 1 TSH 3011", 2, 1, 0, 0, 0, 1, "1 01 3011 HEB", "*")
	call tdfb("@#DHEBREW@ 1 TSH 3011", 2, 2, 0, 0, 0, 1, "1 1 3011 HEB", "*")
	call tdfb("@#DHEBREW@ 1 TSH 3011", 2, 3, 0, 0, 0, 1, "1 TSH 3011 HEB", "*")
	call tdfb("@#DHEBREW@ 1 TSH 3011", 2, 4, 0, 0, 0, 1, "1 Tsh 3011 HEB", "*")
	call tdfb("@#DHEBREW@ 1 TSH 3011", 2, 5, 0, 0, 0, 1, "1 TISHRI 3011 HEB", "*")
	call tdfb("@#DHEBREW@ 1 TSH 3011", 2, 6, 0, 0, 0, 1, "1 Tishri 3011 HEB", "*")
	call tdfb("@#DHEBREW@ 1 TSH 3011", 2, 7, 0, 0, 0, 1, "1 tsh 3011 HEB", "1 tsh 3011 HEB")
	call tdfb("@#DHEBREW@ 1 TSH 3011", 2, 8, 0, 0, 0, 1, "1 tishri 3011 HEB", "1 tishri 3011 HEB")
	call tdfb("@#DHEBREW@ 1 ADS 3011", 2, 0, 0, 0, 0, 1, "1  7 3011 HEB", "*")
	call tdfb("@#DHEBREW@ 1 ADS 3011", 2, 1, 0, 0, 0, 1, "1 07 3011 HEB", "*")
	call tdfb("@#DHEBREW@ 1 ADS 3011", 2, 2, 0, 0, 0, 1, "1 7 3011 HEB", "*")
	call tdfb("@#DHEBREW@ 1 ADS 3011", 2, 3, 0, 0, 0, 1, "1 ADS 3011 HEB", "*")
	call tdfb("@#DHEBREW@ 1 ADS 3011", 2, 4, 0, 0, 0, 1, "1 Ads 3011 HEB", "*")
	call tdfb("@#DHEBREW@ 1 ADS 3011", 2, 5, 0, 0, 0, 1, "1 ADAR SHENI 3011 HEB", "*")
	call tdfb("@#DHEBREW@ 1 ADS 3011", 2, 6, 0, 0, 0, 1, "1 Adar Sheni 3011 HEB", "*")
	call tdfb("@#DHEBREW@ 1 ADS 3011", 2, 7, 0, 0, 0, 1, "1 ads 3011 HEB", "*")
	call tdfb("@#DHEBREW@ 1 ADS 3011", 2, 8, 0, 0, 0, 1, "1 adar sheni 3011 HEB", "*")
	call tdfb("@#DHEBREW@ 1 CSH 3011", 2, 1, 0, 0, 0, 1, "1 02 3011 HEB", "*")
	call tdfb("@#DHEBREW@ 1 KSL 3011", 2, 1, 0, 0, 0, 1, "1 03 3011 HEB", "*")
	call tdfb("@#DHEBREW@ 1 TVT 3011", 2, 1, 0, 0, 0, 1, "1 04 3011 HEB", "*")
	call tdfb("@#DHEBREW@ 1 SHV 3011", 2, 1, 0, 0, 0, 1, "1 05 3011 HEB", "*")
	call tdfb("@#DHEBREW@ 1 ADR 3011", 2, 1, 0, 0, 0, 1, "1 06 3011 HEB", "*")
	call tdfb("@#DHEBREW@ 1 ADS 3011", 2, 1, 0, 0, 0, 1, "1 07 3011 HEB", "*")
	call tdfb("@#DHEBREW@ 1 NSN 3011", 2, 1, 0, 0, 0, 1, "1 08 3011 HEB", "*")
	call tdfb("@#DHEBREW@ 1 IYR 3011", 2, 1, 0, 0, 0, 1, "1 09 3011 HEB", "*")
	call tdfb("@#DHEBREW@ 1 SVN 3011", 2, 1, 0, 0, 0, 1, "1 10 3011 HEB", "*")
	call tdfb("@#DHEBREW@ 1 TMZ 3011", 2, 1, 0, 0, 0, 1, "1 11 3011 HEB", "*")
	call tdfb("@#DHEBREW@ 1 AAV 3011", 2, 1, 0, 0, 0, 1, "1 12 3011 HEB", "*")
	call tdfb("@#DHEBREW@ 1 ELL 3011", 2, 1, 0, 0, 0, 1, "1 13 3011 HEB", "*")

	/* ROMAN would presumably be in AUC, and days counted before K,N,I */

    call reportSubsection("date tests")
}

proc reportSubsection(title)
{
	set(res, concat("Passed ", d(testok), "/", d(add(testok,testfail)), " "))
	if (gt(testskip, 0)) {
		set(res, concat(res, "(skipped ", d(testskip), ") "))
	}
	set(res, concat(res, title, "\n"))
	print(res)
	set(testok, 0)
	set(testfail, 0)
}
