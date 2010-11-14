package Whatever;
    use warnings;
    use strict;
    use List::Util 'reduce';
    our ($a, $b);
    use overload fallback => 1,
        '&{}' => sub {
            my $self = shift;
            sub {@_ < 2 ? &$$self : reduce {$a->($b)} $$self, @_}
        },
        (map { # binary ops
            my $code = eval "sub {\$_[0] $_ \$_[1]}" or die $@;
            $_ => sub {
                my ($self, $flip) = @_[0, 2];
                my $arg2 = \$_[1];
                bless \sub {
                    $code->($flip ? ($$arg2, &$self)
                                  : (&$self, $$arg2))
                }
            }
        } qw (+ - * / % ** << >> x . & | ^ < <= > >= == != lt le gt
              ge eq ne <=> cmp ), $^V >= 5.010 ? '~~' : ()),
        (map { # unary ops
            my $code = eval "sub {$_ \$_[0]}" or die $@;
            ($_ eq '-' ? 'neg' : $_) => sub {
                my $self = $_[0];
                bless \sub {$code->(&$self)}
            }
        } qw (- ! ~)),
        (map { # functions
            my $code = eval "sub {$_(\$_[0]".(/2/ ? ',$_[1])}' : ')}') or die $@;
            $_ => sub {
                my $self = $_[0];
                bless \sub {$code->(&$self)}
            }
        } qw (atan2 cos sin exp abs log sqrt));

    ** = sub {bless \sub {@_ ? shift : $_}};
    *@ = sub {bless \sub {shift}};
    *_ = sub {bless \sub {$_}};
    ** = \do{&*};

    sub AUTOLOAD {
        my $self = shift;
        my $args = \@_;
        my $method = substr our $AUTOLOAD, 2 + length __PACKAGE__;
        bless \sub {(&$self)->$method(@$args)}
    }
    sub DESTROY {}
    our $VERSION = '0.10';

=head1 NAME

Whatever - a perl6ish whatever-star for perl5

=head1 VERSION

Version 0.10

=head1 SYNOPSIS

this module provides a whatever-star C< * > term for perl 5. since this
module is B<not> a source filter, the name C< &* > or C< $* > is as close as
it's going to get.

    use Whatever;

    my $greet = 'hello, ' . &* . '!';

    say $greet->('world'); # prints 'hello, world!'

what was:

    my $result = $someobj->map(sub{$_ * 2});

can now be:

    my $result = $someobj->map(&* * 2);

=head1 EXPORT

    &*  the whatever-star
    $*  the whatever-star ($* is deprecated in 5.10+, so i'm taking it)
    &@  the gets-val-from-@_-star
    &_  the gets-val-from-$_-star

like all punctuation variables, the whatever terms are global across all
packages after this module is loaded.

=head1 SUBROUTINES

the C< &* > and C< $* > stars are the most generic terms, which return their
expression as a sub that will take its argument from C< $_[0] > if it is
available, or C< $_ > otherwise. this allows the terms to dwim in most contexts.

the C< &@ > term always uses C< $_[0] >, while the C< &_ > always uses C< $_ >

beyond where they get their eventual argument from, all of the whatever terms
behave the same way.  each is a 'sticky' overloaded object that will bind to
the operators and variables that it interacts with.  the end result is a
subroutine that will perform the operations when passed it's value.

a few more examples are probably in order:

    my $greet = "hello, $*!";  # the $* term interpolates in strings
    say $greet->('world'); # prints 'hello, world!'

    say "hello, $*!"->('world');

    my $inc = $* + 1;
    say $inc->(5); # prints 6

    my $inc_2 = $inc * 2;
    say $inc_2->(5); # prints 12

    my $inc_inc = $inc->($inc);
    say $inc_inc->(5); # prints 7

    my $repeat = &* x &*;
    my $line = $repeat->('-');
    my $hr = $line . "\n";

    print $hr->(80);  # prints ('-' x 80)."\n"

    {package Array;
        sub new  {shift; bless \@_}
        sub map  {new Array map  $_[1]() => @{$_[0]}}
        sub grep {new Array grep $_[1]() => @{$_[0]}}
        sub str  {join ' ' => @{$_[0]}}
    }
    my $array = new Array 1 .. 10;

    say $array->map(&_ * 2)->str;              # '2 4 6 8 10 12 14 16 18 20'
    say $array->map(&_ * 2)->map(&_ + 1)->str; # '3 5 7 9 11 13 15 17 19 21'
    say $array->map(&_ * 2 + 1)->str;          # '3 5 7 9 11 13 15 17 19 21'

    my $str = &*->str;
    say $str->($array); # prints '1 2 3 4 5 6 7 8 9 10'

    my $multi_call = &*->map(&_ * 2 + 1)->grep(&_ % 5)->str;

    say $multi_call->($array); # prints '3 7 9 11 13 17 19 21'

when working with subs created by combining multiple stars, you can bind
multiple values at once by passing multiple arguments.

    my $join3 = &* . &* . &*;

    say $join3->(1)(2)(3); # prints '123'
    say $join3->(1 .. 3);  # prints '123'

    my $indent = $join3->(' ', ' ');

    say $indent->('xyz'); # prints '  xyz'

the stars lazily bind to variables, which allows the variable to get its value
after the star is defined, and to change its value between calls

    my $future;
    my $delorean = $future . (' ' . $* . '!');

    $future = 1.21;
    say $delorean->('gigawatts'); # prints "1.21 gigawatts!"

    $future = &*;
    say $delorean->('folks')->("that's all");  # prints "that's all folks!"

=head1 AUTHOR

Eric Strom, C<< <asg at cpan.org> >>

=head1 BUGS

this module is new, there are probably some.

Please report any bugs or feature requests to C<bug-whatever at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Whatever>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 ACKNOWLEDGEMENTS

those behind the perl6 whatever-star

=head1 LICENSE AND COPYRIGHT

copyright 2010 Eric Strom.

this program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

see http://dev.perl.org/licenses/ for more information.

=cut

__PACKAGE__ if 'first require';
