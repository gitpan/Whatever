use strict;
use warnings;
use Test::Magic tests => 62;
use lib '../lib';
use Whatever;

diag "Whatever $Whatever::VERSION";

{no warnings 'redefine';
sub is ($) {
    @_ = "@_" if ref $_[0] eq 'Whatever';
    goto &Test::Magic::is
}}

test 'basic',
  is ref(&*) eq 'Whatever',
  is &* == qr/^Whatever.+/,
  is &*->(5) == 5,
  is &*->('a') eq 'a',
  map {is &*->() == $_} 3;

my $lhs = &* . 3;

my $rhs = ">$*";

test 'single lhs',
  is ref($lhs) eq 'Whatever',
  is $lhs->(2) == 23,
  map {is $lhs->() == 43} 4;

test 'single rhs',
  is ref($rhs) eq 'Whatever',
  is $rhs->('x') eq '>x',
  map {is $rhs->() eq '>5'} 5;

test 'double',
  is  ref($lhs . 8) eq 'Whatever',
  is +($lhs . 8)->('asdf') eq 'asdf38';

sub plus2 {$_[0] + 2}
sub mymap {my $code = shift; map $code->(), @_}

test 'sub',
  is +(3 + plus2 &*)->(5) == 10,
  is join(' ' => mymap &* * 5, 0 .. 10) eq '0 5 10 15 20 25 30 35 40 45 50';

my $greet = "hello, $*!";

test 'compose',
  is $greet->('world') eq 'hello, world!',
  is "hello, $*!"->('world') eq 'hello, world!';

my $ss = &* . &*;

test 'complex compose',
  is +($ss->('a') . 'c')->('b') eq 'abc',
  is +('c' . $ss->('a'))->('b') eq 'cab',
  is +('x' . $ss->('a') . 'c')->('b') eq 'xabc';

my $future;
my $delorean = $future . (' ' . &*);

test 'lazy arg',
  do {$future = 1.21;    is $delorean->('gigawatts!') eq '1.21 gigawatts!'},
  do {$future = 'world'; is $greet->($delorean)->('from the future')
                            eq 'hello, world from the future!'},
  do {$future = &*;      is $delorean->('folks')->("that's all")
                            eq "that's all folks"};

{package Array;
    sub new  {shift; bless \@_}
    sub map  {new Array map  $_[1]() => @{$_[0]}}
    sub grep {new Array grep $_[1]() => @{$_[0]}}
    sub join {join $_[1] => @{$_[0]}}
    sub str  {$_[0]->join(' ')}
}

my $array = new Array 1 .. 10;

test 'method',
  is $array->map(&_ * 2)->str                   eq '2 4 6 8 10 12 14 16 18 20',
  is $array->map(&_ * 2)->map(&_ + 1)->str      eq '3 5 7 9 11 13 15 17 19 21',
  is $array->map(&_ * 2 + 1)->str               eq '3 5 7 9 11 13 15 17 19 21',
  is $array->map(&_ * 2 + 1)->grep(&* % 5)->str eq '3 7 9 11 13 17 19 21';

test 'method call', do {
  my $str = &*->str;
  my $add1 = &*->map(&* + 1);
  my $add1evens = &*->map(&* + 1)->grep(not &* % 2);
  is $str->($array)               eq '1 2 3 4 5 6 7 8 9 10',
  is $str->($add1->($array))      eq '2 3 4 5 6 7 8 9 10 11',
  is $str->($add1evens->($array)) eq '2 4 6 8 10',
};

for (&*) {
    test 'aliased $_',
      is +('a'.$_.'c'.$_.'e')->('b')('d') eq 'abcde';

    test 'method aliased $_',
      is $array->map($_ * 2)->str                   eq '2 4 6 8 10 12 14 16 18 20',
      is $array->map($_ * 2)->map($_ + 1)->str      eq '3 5 7 9 11 13 15 17 19 21',
      is $array->map($_ * 2 + 1)->str               eq '3 5 7 9 11 13 15 17 19 21',
      is $array->map($_ * 2 + 1)->grep($_ % 5)->str eq '3 7 9 11 13 17 19 21';
}

test 'a$*c$*e',
  is "a$*c$*e"->('b')('d') eq 'abcde';

test 'method $*',
  is $array->map($* * 2)->str                   eq '2 4 6 8 10 12 14 16 18 20',
  is $array->map($* * 2)->map($* + 1)->str      eq '3 5 7 9 11 13 15 17 19 21',
  is $array->map($* * 2 + 1)->str               eq '3 5 7 9 11 13 15 17 19 21',
  is $array->map($* * 2 + 1)->grep($* % 5)->str eq '3 7 9 11 13 17 19 21';

test 'sin($*)',
  is +(5 * sin $*)->(0.5) == 5 * sin 0.5;

my $not = not &*;
test 'not',
  is $not->(1) eq ! 1,
  is $not->(0) == ! 0;

test '&* x &*', do {
    my $rep  = &* x &*;
    my $line = $rep->('-');
    my $hr = $line . "\n";
    is $line->(10)            eq '-' x 10,
    is $rep->($line->(10))(2) eq '-' x 20,
    is $rep->($line)(3)(10)   eq '-' x 30,
    is $hr->(20)              eq '-' x 20 . "\n",
};

use List::Util 'reduce';
our ($a, $b);

test 'chain', do {
    my $chain = reduce {$a . $b} map &*, 0 .. 8;
    my $link = $chain;
    is $chain->(1)(2)(3)(4)(5)(6)(7)(8)(9) eq 123456789,
    is $chain->(1..8)->(910) eq 12345678910,
    do {
        my $x = 9;
        $link = $link->($x--) while ref $link;
        is $link eq 987654321
    }
};

test 'join', do {
    my $join2   = &* . &*;
    my $join4   = $join2 . $join2;
    my $join8   = $join4 . $join4;
    my $join16  = $join8 . $join8;
    my $join16r = reduce {$a . $*} $*, 2 .. 16;
    is $join2  ->(1 .. 2)   eq 12,
    is $join4  ->(2)(4)(6)(8)   eq 2468,
    is $join4  ->('a'..'d') eq 'abcd',
    is $join16 ->(1 .. 16)  eq '12345678910111213141516',
    is $join16r->(1 .. 16)  eq '12345678910111213141516',
};

test 'join bind', do {
    my $join2   = &* .' '. &*;
    my $join4   = $join2->($join2)($join2);
    my $join8   = $join2->($join4)($join4);
    my $join16  = $join2->($join8)($join8);
    is $join2  ->(1 .. 2)   eq '1 2',
    is $join4  ->(2)(4)(6)(8)   eq '2 4 6 8',
    is $join4  ->('a'..'d') eq 'a b c d',
    is $join16 ->(1 .. 16)  eq '1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16',
};

test 'inc', do {
    my $inc     = $* + 1;
    my $inc_2   = $inc * 2;
    my $inc_inc = $inc->($inc);
    is $inc->(5)     == 6,
    is $inc_2->(5)   == 12,
    is $inc_inc->(5) == 7,
};
