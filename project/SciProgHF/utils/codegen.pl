#! /usr/bin/perl -w
#
# This program is a part of a "Automatic code generation framework for
# analytical functional derivative evaluation", Pawel Salek, 2004.
#
# It takes as input a maxima file describing a functional and generates
# a C file implementing the functional and its first, second and third
# derivatives.
#
# accepted options:
# -k: keep the intermediate maxima files (for debugging).
# -x: assume functional is an exchange functional and generate
#     an optimized code.
# ===================================================================
# HEADER/FOOTER GENERATION SUBROUTINES
# ===================================================================
my $verbose = 1;
sub generate_header($$$$) {
    my($out,$fun_cname,$funid,$inp) = @_;
    my $ufun_cname = ucfirst $fun_cname;
    unless(open FL, ">$out") {
        warn "cannot open $out for writing.\n";
        return undef;
    }
    unless(open INP, $inp) {
        die "cannot open $inp for reading.\n";
    }
    local $/ = undef;
    my $inpstring = <INP>;
    close INP;
    my ($inlinestr) = ($inpstring =~ m,/\*CINCLUDE(.*?)CEND\*/,s);
    $inlinestr = "" unless defined $inlinestr;
    my ($hfweight)  = ($inpstring =~ m,/\* *HFWEIGHT *:= *(.*?) *\*/,s);
    $hfweight = 0 unless defined $hfweight;
    $inpstring =~ s,/\*|\*/,,g;
    print "HFWEIGHT= $hfweight\n";

    print FL << "EOF";
/*-*-mode: C; c-indentation-style: "bsd"; c-basic-offset: 4; -*-*/
/* $out:

   Automatically generated code implementing $funid functional and
   its derivatives. It is generated by func-codegen.pl being a part of
   a "Automatic code generation framework for analytical functional
   derivative evaluation", Pawel Salek, 2005

    This functional is connected by making following changes:
    1. add "extern Functional ${fun_cname}Functional;" to 'functionals.h'
    2. add "&${fun_cname}Functional," to 'functionals.c'
    3. add "${out}" to 'Makefile.am', 'Makefile.in' or 'Makefile'.

    This functional has been generated from following input:
    ------ cut here -------
$inpstring
    ------ cut here -------
*/

 
/* strictly conform to XOPEN ANSI C standard */
#if !defined(SYS_DEC)
/* XOPEN compliance is missing on old Tru64 4.0E Alphas and pow() prototype
 * is not specified. */
#define _XOPEN_SOURCE          500
#define _XOPEN_SOURCE_EXTENDED 1
#endif
#include <math.h>
#include <stddef.h>
 
#define __CVERSION__
 
#include "functionals.h"
 
/* INTERFACE PART */
static int ${fun_cname}_isgga(void) { return 1; } /* FIXME: detect! */
static int ${fun_cname}_read(const char *conf_line);
static real ${fun_cname}_energy(const FunDensProp* dp);
static void ${fun_cname}_first(FunFirstFuncDrv *ds,   real factor,
                         const FunDensProp* dp);
static void ${fun_cname}_second(FunSecondFuncDrv *ds, real factor,
                          const FunDensProp* dp);
 
Functional ${ufun_cname}Functional = {
  "${funid}",       /* name */
  ${fun_cname}_isgga,   /* gga-corrected */
  ${fun_cname}_read,
  NULL,
  ${fun_cname}_energy,
  ${fun_cname}_first,
  ${fun_cname}_second
};
 
/* IMPLEMENTATION PART */
static int
${fun_cname}_read(const char *conf_line)
{
    fun_set_hf_weight($hfweight);
    return 1;
}

$inlinestr
EOF
    close FL;
    return 1;
}

sub generate_footer($) {
    # Footer is empty for now
}

# ===================================================================
# MAXIMA INPUT-GENERATION AND OUTPUT-PARSING SUBROUTINES
# ===================================================================
sub generate_input($$$) {
    my($flnm, $out, $line) = @_;
    unless(open OUT,">$out") {
        warn "cannot open $out for writing.\n";
        return undef;
    }
    #print OUT ":lisp (ALLOCATE 'CONS 200000)\n";
    print OUT "batchload(\"$flnm\");\n";
    print OUT "display2d: false; /* START */\n"; # to make the parsing easier.
    print OUT "string(float(subst(pow,\"^\",optimize([$line]))));\n";
    close OUT;
    return 1;
}

#
# get_expression return expression length either to the end of the string
# or to the nearest coma that matches the parentes nesting rules.

sub get_expression($) {
    my ($input) = @_;
    my $c;
    my ($pos, $depth, $len) = (0,0, length $input);
    while( $pos<$len and
           !( (($c = substr $input, $pos, 1)  eq ',')
              and $depth ==0) ) {
        $depth-- if $c eq ')' or $c eq ']';
        $depth++ if $c eq '(' or $c eq '[';
        $pos++;
    }
    return $pos;
}

# generate_code converts a single string containing MAXIMA's form of
# the expression to a C function. This is NOT a general parser: we
# handle only two cases: plain expression or a BLOCK() type
# expression.

sub generate_code($){
    my ($input) = @_;
    my ($output,$header, $vars, $indent) = ("", "", "", ' 'x4);
    my ($pos, $expr);

    if($input =~ /^BLOCK/i) {
        $input =~ s,^BLOCK\((.*)\)$,$1,i;
        # skip parameter list [%1,%2,...],
        $input =~ s/^\[.*?\],//;
        #
        # generate temporary variable assignments
        #
        while( ($num) = ($input =~ m/^%([0-9]+):/)) {
            $input =~ s/^%[0-9]+://;
            $pos = get_expression $input;
            $output .= $indent ."t$num = ". (substr $input, 0, $pos) . ";\n";
            $input = substr $input, $pos+1;
            $vars .= $vars ? ", t$num" : $indent ."real t$num";
            if(length $vars>45) {
                $header .= $vars .";\n";
                $vars = "";
            }
        }
        $header .= $vars .";\n" if $vars;
        $header .= "\n";
    }
    #
    # generate the derivatives expressed in terms of temporary variables.
    # The derivatives usually come enclosed in '[' and ']'.
    die "expected '[' but found '".substr($input, 0, 60) ."'!"
        unless '[' eq substr $input, 0,1;
    $input = substr $input, 1, length($input) -2;
    $output .= "\n   /* code */\n";
    print "processing variable "; my $cnt = -1;
    while( ($num) = ($input =~ m/^([a-z0-9\]\[]+)\s*=\s*/) ) {
        print "$num "; print "\n" if ++$cnt % 5 == 4;
        $input =~ s/^[a-z0-9\[\]]+\s*=\s*//;
        $pos = get_expression $input;
        $output .= $indent ."$num = ". (substr $input, 0, $pos) . ";\n";
        last unless $pos < length $input;
        $input = substr $input, $pos+1;
    }
    print "\n" unless $cnt % 5 == 4;
    # strip trailing brackets
    $input =~ s/\]\)$//;
    $output = $header. $output;
    $output =~ s,%([0-9]+),t$1,g;

    # wrap lines but not on /*, or 1E-4.
    $output =~ s:([^\n]{55,}?[^E]+?[-+/*,])([^*]):$1\n$indent$indent$2:gi;
    # lower-case commonly used functions... observe ABS->fabs()!
    $output =~ s:(ASINH|COS|SIN|EXP|ERF|LOG|SQRT):lc $1:egs;
    $output =~ s:ABS:fabs:gs;
    $output =~ s:%PI:M_PI:gs;
    # change indexes: they start from 1 in Maxima, from 0 in C.
    $output =~ s:\[(\d+)\]:'['.($1-1).']':egs;    
    return $output;
}

# parse_maxima_output parses the maxima output and generates function
# body.
sub parse_maxima_output($) {
    my($maxout) = @_;
    unless(open FL, $maxout) {
        warn "Cannot open $maxout for reading.\n";
        return undef;
    }
    my $res = "";
    while(<FL>) {
        return undef if /Maxima encountered a Lisp error/;
        # our command is the third one in the stream...
        # Older maximas prefixed command number with D,
        # never ones with %o.
        if(/^\((D|%o)3\)/) {
            ($res) = ($_ =~ m,"(.*?)",);
        }
    }
    close FL;
    warn "parse_maxima_output: Maxima output has unexpected format\n"
        unless $res;
    $res = generate_code $res;
    return $res;
}

# ===================================================================
# Functional derivative implementation templates.
# General case.
# ===================================================================
my $varmappings = 
'    real rhoa = dp->rhoa, rhob = dp->rhob;
    real grada = dp->grada, gradb = dp->gradb, gradab = dp->gradab;
';

my $vars_1st = 
'    real dfdra, dfdrb, dfdga, dfdgb, dfdgab;';

my $assign_1st = 
'    ds->df1000 += factor*dfdra;
    ds->df0100 += factor*dfdrb;
    ds->df0010 += factor*dfdga;
    ds->df0001 += factor*dfdgb;
    ds->df00001+= factor*dfdgab;
';

my $vars_2nd = 
'    real d2fdrara, d2fdrarb, d2fdraga, d2fdragb, d2fdraab, d2fdrbrb,
        d2fdrbga, d2fdrbgb, d2fdrbgab, d2fdgaga, d2fdgagb, d2fdgagab,
        d2fdgbgb, d2fdgbgab, d2fdgabgab;';

my $assign_2nd =
'    ds->df2000 += factor*d2fdrara;
    ds->df1100 += factor*d2fdrarb;
    ds->df1010 += factor*d2fdraga;
    ds->df1001 += factor*d2fdragb;
    ds->df10001+= factor*d2fdraab;
    ds->df0200 += factor*d2fdrbrb;
    ds->df0110 += factor*d2fdrbga;
    ds->df0101 += factor*d2fdrbgb;
    ds->df01001+= factor*d2fdrbgab;
    ds->df0020 += factor*d2fdgaga;
    ds->df0011 += factor*d2fdgagb;
    ds->df00101+= factor*d2fdgagab;
    ds->df0002 += factor*d2fdgbgb;
    ds->df00011+= factor*d2fdgbgab;
    ds->df00002+= factor*d2fdgabgab;
';

my $vars_3rd = 
'    real d3fdrarara, d3fdrararb, d3fdraraga, d3fdraragb, d3fdraraab,
         d3fdrarbrb, d3fdrarbga, d3fdrarbgb, d3fdrarbab, d3fdragaga,
         d3fdragagb, d3fdragaab, d3fdragbgb, d3fdragbab, d3fdraabab,
         d3fdrbrbrb, d3fdrbrbga, d3fdrbrbgb, d3fdrbrbab, d3fdrbgaga,
         d3fdrbgagb, d3fdrbgaab, d3fdrbgbgb, d3fdrbgbab, d3fdrbabab,
         d3fdgagaga, d3fdgagagb, d3fdgagaab, d3fdgagbgb, d3fdgagbab,
         d3fdgaabab, d3fdgbgbgb, d3fdgbgbab, d3fdgbabab, d3fdababab;';

my $assign_3rd = 
'    ds->df3000 += factor*d3fdrarara;
    ds->df2100  += factor*d3fdrararb;
    ds->df2010  += factor*d3fdraraga;
    ds->df2001  += factor*d3fdraragb;
    ds->df20001 += factor*d3fdraraab;
    ds->df1200  += factor*d3fdrarbrb;
    ds->df1110  += factor*d3fdrarbga;
    ds->df1101  += factor*d3fdrarbgb;
    ds->df11001 += factor*d3fdrarbab;
    ds->df1020  += factor*d3fdragaga;
    ds->df1011  += factor*d3fdragagb;
    ds->df10101 += factor*d3fdragaab;
    ds->df1002  += factor*d3fdragbgb;
    ds->df10011 += factor*d3fdragbab;
    ds->df10002 += factor*d3fdraabab;
    ds->df0300  += factor*d3fdrbrbrb;
    ds->df0210  += factor*d3fdrbrbga;
    ds->df0201  += factor*d3fdrbrbgb;
    ds->df02001 += factor*d3fdrbrbab;
    ds->df0120  += factor*d3fdrbgaga;
    ds->df0111  += factor*d3fdrbgagb;
    ds->df01101 += factor*d3fdrbgaab;
    ds->df0102  += factor*d3fdrbgbgb;
    ds->df01011 += factor*d3fdrbgbab;
    ds->df01002 += factor*d3fdrbabab;
    ds->df0030  += factor*d3fdgagaga;
    ds->df0021  += factor*d3fdgagagb;
    ds->df00201 += factor*d3fdgagaab;
    ds->df0012  += factor*d3fdgagbgb;
    ds->df00111 += factor*d3fdgagbab;
    ds->df00102 += factor*d3fdgaabab;
    ds->df0003  += factor*d3fdgbgbgb;
    ds->df00021 += factor*d3fdgbgbab;
    ds->df00012 += factor*d3fdgbabab;
    ds->df00003 += factor*d3fdababab;
';

my $vars_4th = 
'    real d4fdrararara, d4fdrarararb, d4fdrararaga, d4fdrararagb,
         d4fdrararaab, d4fdrararbrb, d4fdrararbga, d4fdrararbgb, d4fdrararbab,
         d4fdraragaga, d4fdraragagb, d4fdraragaab, d4fdraragbgb, d4fdraragbab,
         d4fdraraabab, d4fdrarbrbrb, d4fdrarbrbga, d4fdrarbrbgb, d4fdrarbrbab,
         d4fdrarbgaga, d4fdrarbgagb, d4fdrarbgaab, d4fdrarbgbgb, d4fdrarbgbab,
         d4fdrarbabab, d4fdragagaga, d4fdragagagb, d4fdragagaab, d4fdragagbgb,
         d4fdragagbab, d4fdragaabab, d4fdragbgbgb, d4fdragbgbab, d4fdragbabab,
         d4fdraababab, d4fdrbrbrbrb, d4fdrbrbrbga, d4fdrbrbrbgb, d4fdrbrbrbab,
         d4fdrbrbgaga, d4fdrbrbgagb, d4fdrbrbgaab, d4fdrbrbgbgb, d4fdrbrbgbab,
         d4fdrbrbabab, d4fdrbgagaga, d4fdrbgagagb, d4fdrbgagaab, d4fdrbgagbgb,
         d4fdrbgagbab, d4fdrbgaabab, d4fdrbgbgbgb, d4fdrbgbgbab, d4fdrbgbabab,
         d4fdrbababab, d4fdgagagaga, d4fdgagagagb, d4fdgagagaab, d4fdgagagbgb,
         d4fdgagagbab, d4fdgagaabab, d4fdgagbgbgb, d4fdgagbgbab, d4fdgagbabab,
         d4fdgaababab, d4fdgbgbgbgb, d4fdgbgbgbab, d4fdgbgbabab, d4fdgbababab,
         d4fdabababab;';


my $assign_4th = 
'    ds->df4000  += factor*d4fdrararara;
    ds->df3100  += factor*d4fdrarararb;
    ds->df3010  += factor*d4fdrararaga;
    ds->df3001  += factor*d4fdrararagb;
    ds->df30001 += factor*d4fdrararaab;
    ds->df2200  += factor*d4fdrararbrb;
    ds->df2110  += factor*d4fdrararbga;
    ds->df2101  += factor*d4fdrararbgb;
    ds->df21001 += factor*d4fdrararbab;
    ds->df2020  += factor*d4fdraragaga;
    ds->df2011  += factor*d4fdraragagb;
    ds->df20101 += factor*d4fdraragaab;
    ds->df2002  += factor*d4fdraragbgb;
    ds->df20011 += factor*d4fdraragbab;
    ds->df20002 += factor*d4fdraraabab;
    ds->df1300  += factor*d4fdrarbrbrb;
    ds->df1210  += factor*d4fdrarbrbga;
    ds->df1201  += factor*d4fdrarbrbgb;
    ds->df12001 += factor*d4fdrarbrbab;
    ds->df1120  += factor*d4fdrarbgaga;
    ds->df1111  += factor*d4fdrarbgagb;
    ds->df11101 += factor*d4fdrarbgaab;
    ds->df1102  += factor*d4fdrarbgbgb;
    ds->df11011 += factor*d4fdrarbgbab;
    ds->df11002 += factor*d4fdrarbabab;
    ds->df1030  += factor*d4fdragagaga;
    ds->df1021  += factor*d4fdragagagb;
    ds->df10201 += factor*d4fdragagaab;
    ds->df1012  += factor*d4fdragagbgb;
    ds->df10111 += factor*d4fdragagbab;
    ds->df10102 += factor*d4fdragaabab;
    ds->df1003  += factor*d4fdragbgbgb;
    ds->df10021 += factor*d4fdragbgbab;
    ds->df10012 += factor*d4fdragbabab;
    ds->df10003 += factor*d4fdraababab;
    ds->df0400  += factor*d4fdrbrbrbrb;
    ds->df0310  += factor*d4fdrbrbrbga;
    ds->df0301  += factor*d4fdrbrbrbgb;
    ds->df03001 += factor*d4fdrbrbrbab;
    ds->df0220  += factor*d4fdrbrbgaga;
    ds->df0211  += factor*d4fdrbrbgagb;
    ds->df02101 += factor*d4fdrbrbgaab;
    ds->df0202  += factor*d4fdrbrbgbgb;
    ds->df02011 += factor*d4fdrbrbgbab;
    ds->df02002 += factor*d4fdrbrbabab;
    ds->df0130  += factor*d4fdrbgagaga;
    ds->df0121  += factor*d4fdrbgagagb;
    ds->df01201 += factor*d4fdrbgagaab;
    ds->df0112  += factor*d4fdrbgagbgb;
    ds->df01111 += factor*d4fdrbgagbab;
    ds->df01102 += factor*d4fdrbgaabab;
    ds->df0103  += factor*d4fdrbgbgbgb;
    ds->df01021 += factor*d4fdrbgbgbab;
    ds->df01012 += factor*d4fdrbgbabab;
    ds->df01003 += factor*d4fdrbababab;
    ds->df0040  += factor*d4fdgagagaga;
    ds->df0031  += factor*d4fdgagagagb;
    ds->df00301 += factor*d4fdgagagaab;
    ds->df0022  += factor*d4fdgagagbgb;
    ds->df00211 += factor*d4fdgagagbab;
    ds->df00202 += factor*d4fdgagaabab;
    ds->df0013  += factor*d4fdgagbgbgb;
    ds->df00121 += factor*d4fdgagbgbab;
    ds->df00112 += factor*d4fdgagbabab;
    ds->df00103 += factor*d4fdgaababab;
    ds->df0004  += factor*d4fdgbgbgbgb;
    ds->df00031 += factor*d4fdgbgbgbab;
    ds->df00022 += factor*d4fdgbgbabab;
    ds->df00013 += factor*d4fdgbababab;
    ds->df00004 += factor*d4fdabababab;
';

sub get_func_template($$) { 
    my ($fun, $body) = @_;
    print COUT "
static real
${fun}_energy(const FunDensProp *dp)
{
    real res;
$varmappings
$body
    return res;
}
";
}


sub get_1st_template($$) { 
    my ($fun, $body) = @_;
    print COUT "
static void
${fun}_first(FunFirstFuncDrv *ds, real factor, const FunDensProp *dp)
{
$vars_1st
$varmappings
$body

$assign_1st   
}
";
}

sub get_2nd_template($$){
    my ($fun, $body) = @_; 
    print COUT "
static void
${fun}_second(FunSecondFuncDrv *ds, real factor, const FunDensProp* dp)
{
$vars_1st
$vars_2nd
$varmappings
$body

$assign_1st
$assign_2nd
}
";
}

sub get_3rd_template($$){
    my ($fun, $body) = @_; 
    print COUT "
static void
${fun}_third(FunThirdFuncDrv *ds, real factor, const FunDensProp* dp)
{
$vars_1st
$vars_2nd
$vars_3rd
$varmappings
$body

$assign_1st
$assign_2nd
$assign_3rd
}
";
}


sub get_4th_template($$){
    my ($fun, $body) = @_; 
    print COUT "
static void
${fun}_fourth(FunFourthFuncDrv *ds, real factor, const FunDensProp* dp)
{
$vars_1st
$vars_2nd
$vars_3rd
$vars_4th
$varmappings
$body

$assign_1st
$assign_2nd
$assign_3rd
$assign_4th
}
";
}

# ===================================================================
# Functional derivative implementation templates.
# Exchange functionals.
# ===================================================================

my $assign_1st_a =
'    ds->df1000 += factor*res[0];
    ds->df0010 += factor*res[1];
';
my $assign_1st_b =
'    ds->df0100 += factor*res[0];
    ds->df0001 += factor*res[1];
';

my $assign_2nd_a =
'    ds->df2000 += factor*res[2];
    ds->df1010 += factor*res[3];
    ds->df0020 += factor*res[4];
';
my $assign_2nd_b =
'    ds->df0200 += factor*res[2];
    ds->df0101 += factor*res[3];
    ds->df0002 += factor*res[4];
';

my $assign_3rd_a = 
'    ds->df3000 += factor*res[5];
    ds->df2010 += factor*res[6];
    ds->df1020 += factor*res[7];
    ds->df0030 += factor*res[8];
';

my $assign_3rd_b = 
'    ds->df0300 += factor*res[5];
    ds->df0201 += factor*res[6];
    ds->df0102 += factor*res[7];
    ds->df0003 += factor*res[8];
';

my $assign_4th_a = 
'    ds->df4000 += factor*res[9];
    ds->df3010 += factor*res[10];
    ds->df2020 += factor*res[11];
    ds->df1030 += factor*res[12];
    ds->df0040 += factor*res[13];
';

my $assign_4th_b = 
'    ds->df0400 += factor*res[9];
    ds->df0301 += factor*res[10];
    ds->df0202 += factor*res[11];
    ds->df0103 += factor*res[12];
    ds->df0004 += factor*res[13];
';

sub get_func_template_ex($$) { 
    my ($fun, $body) = @_;
    #print "'$body'\n";
    print COUT "
static real
${fun}_energy(const FunDensProp *dp)
{
    real res;
$varmappings
$body
    return res;
}
";
}

sub get_1st_template_ex($$) { 
    my ($fun, $body) = @_;
    print COUT "
static void
${fun}_first_helper(real rhoa, real grada, real *res)
{$body}

static void
${fun}_first(FunFirstFuncDrv *ds, real factor, const FunDensProp *dp)
{
    real res[2];

    ${fun}_first_helper(dp->rhoa, dp->grada, res);
   /* Final assignment */
$assign_1st_a

    if(fabs(dp->rhoa-dp->rhob)>1e-13 ||
       fabs(dp->grada-dp->gradb)>1e-13)
        ${fun}_first_helper(dp->rhob, dp->gradb, res);
$assign_1st_b
}
";
}

sub get_2nd_template_ex($$){
    my ($fun, $body) = @_; 
    print COUT "
static void
${fun}_second_helper(real rhoa, real grada, real *res)
{
$body
}

static void
${fun}_second(FunSecondFuncDrv *ds, real factor, const FunDensProp* dp)
{
    real res[5];
 
    ${fun}_second_helper(dp->rhoa, dp->grada, res);

$assign_1st_a
$assign_2nd_a

    if(fabs(dp->rhoa-dp->rhob)>1e-13 ||
       fabs(dp->grada-dp->gradb)>1e-13)
        ${fun}_second_helper(dp->rhob, dp->gradb, res);
$assign_1st_b
$assign_2nd_b
}
";
}

sub get_3rd_template_ex($$){
    my ($fun, $body) = @_; 
    print COUT "
static void
${fun}_third_helper(real rhoa, real grada, real *res)
{
$body
}

static void
${fun}_third(FunThirdFuncDrv *ds, real factor, const FunDensProp* dp)
{
    real res[9];
 
    ${fun}_third_helper(dp->rhoa, dp->grada, res);

$assign_1st_a
$assign_2nd_a
$assign_3rd_a

    if(fabs(dp->rhoa-dp->rhob)>1e-13 ||
       fabs(dp->grada-dp->gradb)>1e-13)
        ${fun}_third_helper(dp->rhob, dp->gradb, res);

$assign_1st_b
$assign_2nd_b
$assign_3rd_b
}
";
}

sub get_4th_template_ex($$){
    my ($fun, $body) = @_; 
    print COUT "
static void
${fun}_fourth_helper(real rhoa, real grada, real *res)
{
$body
}

static void
${fun}_fourth(FunFourthFuncDrv *ds, real factor, const FunDensProp* dp)
{
    real res[14];
 
    ${fun}_fourth_helper(dp->rhoa, dp->grada, res);

$assign_1st_a
$assign_2nd_a
$assign_3rd_a
$assign_4th_a

    if(fabs(dp->rhoa-dp->rhob)>1e-13 ||
       fabs(dp->grada-dp->gradb)>1e-13)
        ${fun}_fourth_helper(dp->rhob, dp->gradb, res);

$assign_1st_b
$assign_2nd_b
$assign_3rd_b
$assign_4th_b
}
";
}

# ===================================================================
# MAIN PROGRAM.
# ===================================================================
my $keepfiles = 0;
my $exch_func = 0;
my $file_name = undef;
my $usage_string = 
"usage [-x] [-k] funcdef.max

 -k: keep the intermediate maxima files for debugging.
 -x: assume functional is an exchange functional and generate
     an optimized code.
";

foreach $arg (@ARGV) {
   if($arg eq '-h') {
       print $usage_string, "\n";
       exit 0;
   } elsif($arg eq '-k') {
       $keepfiles = 1;
   } elsif($arg eq '-x') {
       $exch_func = 1;
   } elsif(!defined $file_name) {
       $file_name = $arg;
       die "$file_name does not exist.\n\n$usage_string"
           unless -f $file_name;
   } else { die $usage_string ."\n"; }
}

die $usage_string unless defined $file_name; 


($dirname) = ($file_name =~ m,^(.*/),); $dirname = "" unless defined $dirname;
($basename) = substr $file_name, length $dirname;
$basename =~ s,\.max$,,;
my $temp_maxima_inp = $basename . "-input.maxima";
my $c_output = $dirname . "fun-".$basename . ".c";

my $funname = $basename;
$funname =~ s,\.max$,,;
$funname =~ s,[.+-],_,g;

# we split the generation into different orders because it can be very
# time-consuming, particularly the expression optimization phase.

if($exch_func) {
    # templates for exchange functionals - we can simplify a lot.
    %ingenerators =
    (0 => 'res=K(rhoa,grada,rhob,gradb,gradab)',
     1 => 
     'res[1]=diff(K(rhoa,grada,rhob,gradb,gradab),rhoa),
      res[2]=diff(K(rhoa,grada,rhob,gradb,gradab),grada)');
    $ingenerators{2} = $ingenerators{1} . ",\n".
     'res[3]=diff(K(rhoa,grada,rhob,gradb,gradab),rhoa,2),
      res[4]=diff(K(rhoa,grada,rhob,gradb,gradab),rhoa,1,grada,1),
      res[5]=diff(K(rhoa,grada,rhob,gradb,gradab),grada,2)';
    $ingenerators{3} = $ingenerators{2} . ",\n".
     'res[6]=diff(K(rhoa,grada,rhob,gradb,gradab),rhoa,3), 
      res[7]=diff(K(rhoa,grada,rhob,gradb,gradab),rhoa,2,grada,1),
      res[8]=diff(K(rhoa,grada,rhob,gradb,gradab),rhoa,1,grada,2),
      res[9]=diff(K(rhoa,grada,rhob,gradb,gradab),grada,3)';
    $ingenerators{4} = $ingenerators{3} . ",\n".
     'res[10]=diff(K(rhoa,grada,rhob,gradb,gradab),rhoa,4), 
      res[11]=diff(K(rhoa,grada,rhob,gradb,gradab),rhoa,3,grada,1),
      res[12]=diff(K(rhoa,grada,rhob,gradb,gradab),rhoa,2,grada,2),
      res[13]=diff(K(rhoa,grada,rhob,gradb,gradab),rhoa,1,grada,3),
      res[14]=diff(K(rhoa,grada,rhob,gradb,gradab),grada,4)';

    %outtemplates = ( 0 => 'get_func_template_ex',
                      1 => 'get_1st_template_ex',
                      2 => 'get_2nd_template_ex',
                      3 => 'get_3rd_template_ex',
                      4 => 'get_4th_template_ex');
} else {
    %ingenerators =
        (0 => 'res=K(rhoa,grada,rhob,gradb,gradab)',
     1 => 
     'dfdra=diff(K(rhoa,grada,rhob,gradb,gradab),rhoa),
      dfdrb=diff(K(rhoa,grada,rhob,gradb,gradab),rhob),
      dfdga=diff(K(rhoa,grada,rhob,gradb,gradab),grada),
      dfdgb=diff(K(rhoa,grada,rhob,gradb,gradab),gradb),
      dfdgab=diff(K(rhoa,grada,rhob,gradb,gradab),gradab)');
     $ingenerators{2} = $ingenerators{1} . ",\n".
     'd2fdrara=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 2),
      d2fdrarb=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 1, rhob, 1),
      d2fdraga=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 1, grada, 1),
      d2fdragb=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 1, gradb, 1),
      d2fdraab=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 1, gradab, 1),
      d2fdrbrb=diff(K(rhoa,grada,rhob,gradb,gradab), rhob, 2),
      d2fdrbga=diff(K(rhoa,grada,rhob,gradb,gradab), rhob, 1, grada, 1),
      d2fdrbgb=diff(K(rhoa,grada,rhob,gradb,gradab), rhob, 1, gradb, 1),
      d2fdrbgab=diff(K(rhoa,grada,rhob,gradb,gradab), rhob, 1, gradab, 1),
      d2fdgaga=diff(K(rhoa,grada,rhob,gradb,gradab), grada, 2),
      d2fdgagb=diff(K(rhoa,grada,rhob,gradb,gradab), grada, 1, gradb, 1),
      d2fdgagab=diff(K(rhoa,grada,rhob,gradb,gradab), grada, 1, gradab, 1),
      d2fdgbgb=diff(K(rhoa,grada,rhob,gradb,gradab), gradb, 2),
      d2fdgbgab=diff(K(rhoa,grada,rhob,gradb,gradab), gradb, 1, gradab, 1),
      d2fdgabgab=diff(K(rhoa,grada,rhob,gradb,gradab), gradab, 2)';
     $ingenerators{3}  = $ingenerators{2} . ",\n".
     'd3fdrarara=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 3),
      d3fdrararb=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 2, rhob, 1),
      d3fdraraga=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 2, grada, 1),
      d3fdraragb=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 2, gradb, 1),
      d3fdraraab=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 2, gradab, 1),
      d3fdrarbrb=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 1, rhob, 2),
      d3fdrarbga=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 1, rhob, 1, grada, 1),
      d3fdrarbgb=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 1, rhob, 1, gradb, 1),
      d3fdrarbab=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 1, rhob, 1, gradab, 1),
      d3fdragaga=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 1, grada, 2),
      d3fdragagb=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 1, grada, 1, gradb, 1),
      d3fdragaab=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 1, grada, 1, gradab, 1),
      d3fdragbgb=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 1, gradb, 2),
      d3fdragbab=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 1, gradb, 1, gradab, 1),
      d3fdraabab=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 1, gradab, 2),
      d3fdrbrbrb=diff(K(rhoa,grada,rhob,gradb,gradab), rhob, 3),
      d3fdrbrbga=diff(K(rhoa,grada,rhob,gradb,gradab), rhob, 2, grada, 1),
      d3fdrbrbgb=diff(K(rhoa,grada,rhob,gradb,gradab), rhob, 2, gradb, 1),
      d3fdrbrbab=diff(K(rhoa,grada,rhob,gradb,gradab), rhob, 2, gradab, 1),
      d3fdrbgaga=diff(K(rhoa,grada,rhob,gradb,gradab), rhob, 1, grada, 2),
      d3fdrbgagb=diff(K(rhoa,grada,rhob,gradb,gradab), rhob, 1, grada, 1, gradb, 1),
      d3fdrbgaab=diff(K(rhoa,grada,rhob,gradb,gradab), rhob, 1, grada, 1, gradab, 1),
      d3fdrbgbgb=diff(K(rhoa,grada,rhob,gradb,gradab), rhob, 1, gradb, 2),
      d3fdrbgbab=diff(K(rhoa,grada,rhob,gradb,gradab), rhob, 1, gradb, 1, gradab, 1),
      d3fdrbabab=diff(K(rhoa,grada,rhob,gradb,gradab), rhob, 1, gradab, 2),
      d3fdgagaga=diff(K(rhoa,grada,rhob,gradb,gradab), grada, 3),
      d3fdgagagb=diff(K(rhoa,grada,rhob,gradb,gradab), grada, 2, gradb, 1),
      d3fdgagaab=diff(K(rhoa,grada,rhob,gradb,gradab), grada, 2, gradab, 1),
      d3fdgagbgb=diff(K(rhoa,grada,rhob,gradb,gradab), grada, 1, gradb, 2),
      d3fdgagbab=diff(K(rhoa,grada,rhob,gradb,gradab), grada, 1, gradb, 1, gradab, 1),
      d3fdgaabab=diff(K(rhoa,grada,rhob,gradb,gradab), grada, 1, gradab, 2),
      d3fdgbgbgb=diff(K(rhoa,grada,rhob,gradb,gradab), gradb, 3),
      d3fdgbgbab=diff(K(rhoa,grada,rhob,gradb,gradab), gradb, 2, gradab, 1),
      d3fdgbabab=diff(K(rhoa,grada,rhob,gradb,gradab), gradb, 1, gradab, 2),
      d3fdababab=diff(K(rhoa,grada,rhob,gradb,gradab), gradab, 3)';
     $ingenerators{4}  = $ingenerators{3} . ",\n".
     'd4fdrararara=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 4),
      d4fdrarararb=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 3, rhob, 1),
      d4fdrararaga=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 3, grada, 1),
      d4fdrararagb=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 3, gradb, 1),
      d4fdrararaab=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 3, gradab, 1),
      d4fdrararbrb=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 2, rhob, 2),
      d4fdrararbga=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 2, rhob, 1, grada, 1),
      d4fdrararbgb=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 2, rhob, 1, gradb, 1),
      d4fdrararbab=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 2, rhob, 1, gradab, 1),
      d4fdraragaga=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 2, grada, 2),
      d4fdraragagb=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 2, grada, 1, gradb, 1),
      d4fdraragaab=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 2, grada, 1, gradab, 1),
      d4fdraragbgb=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 2, gradb, 2),
      d4fdraragbab=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 2, gradb, 1, gradab, 1),
      d4fdraraabab=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 2, gradab, 2),
      d4fdrarbrbrb=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 1, rhob, 3),
      d4fdrarbrbga=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 1, rhob, 2, grada, 1),
      d4fdrarbrbgb=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 1, rhob, 2, gradb, 1),
      d4fdrarbrbab=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 1, rhob, 2, gradab, 1),
      d4fdrarbgaga=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 1, rhob, 1, grada, 2),
      d4fdrarbgagb=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 1, rhob, 1, grada, 1, gradb, 1),
      d4fdrarbgaab=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 1, rhob, 1, grada, 1, gradab, 1),
      d4fdrarbgbgb=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 1, rhob, 1, gradb, 2),
      d4fdrarbgbab=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 1, rhob, 1, gradb, 1, gradab, 1),
      d4fdrarbabab=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 1, rhob, 1, gradab, 2),
      d4fdragagaga=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 1, grada, 3),
      d4fdragagagb=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 1, grada, 2, gradb, 1),
      d4fdragagaab=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 1, grada, 2, gradab, 1),
      d4fdragagbgb=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 1, grada, 1, gradb, 2),
      d4fdragagbab=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 1, grada, 1, gradb, 1, gradab, 1),
      d4fdragaabab=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 1, grada, 1, gradab, 2),
      d4fdragbgbgb=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 1, gradb, 3),
      d4fdragbgbab=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 1, gradb, 2, gradab, 1),
      d4fdragbabab=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 1, gradb, 1, gradab, 2),
      d4fdraababab=diff(K(rhoa,grada,rhob,gradb,gradab), rhoa, 1, gradab, 3),
      d4fdrbrbrbrb=diff(K(rhoa,grada,rhob,gradb,gradab), rhob, 4),
      d4fdrbrbrbga=diff(K(rhoa,grada,rhob,gradb,gradab), rhob, 3, grada, 1),
      d4fdrbrbrbgb=diff(K(rhoa,grada,rhob,gradb,gradab), rhob, 3, gradb, 1),
      d4fdrbrbrbab=diff(K(rhoa,grada,rhob,gradb,gradab), rhob, 3, gradab, 1),
      d4fdrbrbgaga=diff(K(rhoa,grada,rhob,gradb,gradab), rhob, 2, grada, 2),
      d4fdrbrbgagb=diff(K(rhoa,grada,rhob,gradb,gradab), rhob, 2, grada, 1, gradb, 1),
      d4fdrbrbgaab=diff(K(rhoa,grada,rhob,gradb,gradab), rhob, 2, grada, 1, gradab, 1),
      d4fdrbrbgbgb=diff(K(rhoa,grada,rhob,gradb,gradab), rhob, 2, gradb, 2),
      d4fdrbrbgbab=diff(K(rhoa,grada,rhob,gradb,gradab), rhob, 2, gradb, 1, gradab, 1),
      d4fdrbrbabab=diff(K(rhoa,grada,rhob,gradb,gradab), rhob, 2, gradab, 2),
      d4fdrbgagaga=diff(K(rhoa,grada,rhob,gradb,gradab), rhob, 1, grada, 3),
      d4fdrbgagagb=diff(K(rhoa,grada,rhob,gradb,gradab), rhob, 1, grada, 2, gradb, 1),
      d4fdrbgagaab=diff(K(rhoa,grada,rhob,gradb,gradab), rhob, 1, grada, 2, gradab, 1),
      d4fdrbgagbgb=diff(K(rhoa,grada,rhob,gradb,gradab), rhob, 1, grada, 1, gradb, 2),
      d4fdrbgagbab=diff(K(rhoa,grada,rhob,gradb,gradab), rhob, 1, grada, 1, gradb, 1, gradab, 1),
      d4fdrbgaabab=diff(K(rhoa,grada,rhob,gradb,gradab), rhob, 1, grada, 1, gradab, 2),
      d4fdrbgbgbgb=diff(K(rhoa,grada,rhob,gradb,gradab), rhob, 1, gradb, 3),
      d4fdrbgbgbab=diff(K(rhoa,grada,rhob,gradb,gradab), rhob, 1, gradb, 2, gradab, 1),
      d4fdrbgbabab=diff(K(rhoa,grada,rhob,gradb,gradab), rhob, 1, gradb, 1, gradab, 2),
      d4fdrbababab=diff(K(rhoa,grada,rhob,gradb,gradab), rhob, 1, gradab, 3),
      d4fdgagagaga=diff(K(rhoa,grada,rhob,gradb,gradab), grada, 4),
      d4fdgagagagb=diff(K(rhoa,grada,rhob,gradb,gradab), grada, 3, gradb, 1),
      d4fdgagagaab=diff(K(rhoa,grada,rhob,gradb,gradab), grada, 3, gradab, 1),
      d4fdgagagbgb=diff(K(rhoa,grada,rhob,gradb,gradab), grada, 2, gradb, 2),
      d4fdgagagbab=diff(K(rhoa,grada,rhob,gradb,gradab), grada, 2, gradb, 1, gradab, 1),
      d4fdgagaabab=diff(K(rhoa,grada,rhob,gradb,gradab), grada, 2, gradab, 2),
      d4fdgagbgbgb=diff(K(rhoa,grada,rhob,gradb,gradab), grada, 1, gradb, 3),
      d4fdgagbgbab=diff(K(rhoa,grada,rhob,gradb,gradab), grada, 1, gradb, 2, gradab, 1),
      d4fdgagbabab=diff(K(rhoa,grada,rhob,gradb,gradab), grada, 1, gradb, 1, gradab, 2),
      d4fdgaababab=diff(K(rhoa,grada,rhob,gradb,gradab), grada, 1, gradab, 3),
      d4fdgbgbgbgb=diff(K(rhoa,grada,rhob,gradb,gradab), gradb, 4),
      d4fdgbgbgbab=diff(K(rhoa,grada,rhob,gradb,gradab), gradb, 3, gradab, 1),
      d4fdgbgbabab=diff(K(rhoa,grada,rhob,gradb,gradab), gradb, 2, gradab, 2),
      d4fdgbababab=diff(K(rhoa,grada,rhob,gradb,gradab), gradb, 1, gradab, 3),
      d4fdabababab=diff(K(rhoa,grada,rhob,gradb,gradab), gradab, 4)';

    %outtemplates = ( 0 => 'get_func_template',
                      1 => 'get_1st_template',
                      2 => 'get_2nd_template',
                      3 => 'get_3rd_template',
                      4 => 'get_4th_template');
}

generate_header $c_output, $funname, uc $basename, $file_name;

open COUT,  ">>$c_output" or
    die "cannot open $c_output for appending.\n";

foreach $order ( qw(0 1 2) ) {
    generate_input($file_name, $temp_maxima_inp, $ingenerators{$order})
        or die;
    my $temp_maxima_out = $funname."-output".$order.".out";
    system("maxima < $temp_maxima_inp > $temp_maxima_out") == 0
        or die "Running maxima<$temp_maxima_inp>$temp_maxima_out failed.\n".
        "Investigate the cause.\n";
    my $body = parse_maxima_output $temp_maxima_out;
    if(!$body) {
        print STDERR "\nMaxima output parsing failed. Maxima output was:\n\n";
        if(open FL, $temp_maxima_out) {while(<FL>){print STDERR;}; close FL; }
        print STDERR "\n";
        die;
    }
    $outtemplates{$order}($funname, $body);
    unless($keepfiles) {
        unlink $temp_maxima_inp;
        unlink $temp_maxima_out;
    }
    print "Order: $order finished.\n";
}
close COUT;
generate_footer $c_output;
