use strict;
use warnings FATAL => "recursion";
no if $] >= 5.018, warnings => "experimental::smartmatch";
use feature qw(switch);
use File::Basename;
use lib dirname (__FILE__);

use Data::Dumper;
use List::Util qw(pairs pairmap);
use Scalar::Util qw(blessed);

use readline qw(mal_readline set_rl_mode);
use types qw($nil $true $false);
use reader;
use printer;
use env;
use core;

# read
sub READ {
    my $str = shift;
    return reader::read_str($str);
}

# eval
sub eval_ast {
    my($ast, $env) = @_;
    if ($ast->isa('Mal::Symbol')) {
	return $env->get($ast);
    } elsif ($ast->isa('Mal::Sequence')) {
	return ref($ast)->new([ map { EVAL($_, $env) } @$ast ]);
    } elsif ($ast->isa('Mal::HashMap')) {
	return Mal::HashMap->new({ pairmap { $a => EVAL($b, $env) } %$ast });
    } else {
	return $ast;
    }
}

sub EVAL {
    my($ast, $env) = @_;

    #print "EVAL: " . printer::_pr_str($ast) . "\n";
    if (! $ast->isa('Mal::List')) {
        goto &eval_ast;
    }

    # apply list
    unless (@$ast) { return $ast; }
    my ($a0) = @$ast;
    given ($a0->isa('Mal::Symbol') ? $$a0 : $a0) {
        when ('def!') {
	    my (undef, $sym, $val) = @$ast;
            return $env->set($sym, EVAL($val, $env));
        }
        when ('let*') {
	    my (undef, $bindings, $body) = @$ast;
            my $let_env = Mal::Env->new($env);
	    foreach my $pair (pairs @$bindings) {
		my ($k, $v) = @$pair;
                $let_env->set($k, EVAL($v, $let_env));
            }
	    @_ = ($body, $let_env);
	    goto &EVAL;
        }
        when ('do') {
	    my (undef, @todo) = @$ast;
	    my $last = pop @todo;
            eval_ast(Mal::List->new(\@todo), $env);
            @_ = ($last, $env);
            goto &EVAL;
        }
        when ('if') {
	    my (undef, $if, $then, $else) = @$ast;
            my $cond = EVAL($if, $env);
            if ($cond eq $nil || $cond eq $false) {
                @_ = ($else // $nil, $env);
            } else {
                @_ = ($then, $env);
            }
	    goto &EVAL;
        }
        when ('fn*') {
	    my (undef, $params, $body) = @$ast;
            return Mal::Function->new(sub {
                #print "running fn*\n";
		@_ = ($body, Mal::Env->new($env, $params, \@_));
                goto &EVAL;
            });
        }
        default {
            @_ = @{eval_ast($ast, $env)};
            my $f = shift;
	    goto &$f;
        }
    }
}

# print
sub PRINT {
    my $exp = shift;
    return printer::_pr_str($exp);
}

# repl
my $repl_env = Mal::Env->new();
sub REP {
    my $str = shift;
    return PRINT(EVAL(READ($str), $repl_env));
}

# core.pl: defined using perl
foreach my $n (keys %core::ns) {
    $repl_env->set(Mal::Symbol->new($n), $core::ns{$n});
}
$repl_env->set(Mal::Symbol->new('eval'),
	       Mal::Function->new(sub { EVAL($_[0], $repl_env) }));
my @_argv = map {Mal::String->new($_)}  @ARGV[1..$#ARGV];
$repl_env->set(Mal::Symbol->new('*ARGV*'), Mal::List->new(\@_argv));

# core.mal: defined using the language itself
REP(q[(def! not (fn* (a) (if a false true)))]);
REP(q[(def! load-file (fn* (f) (eval (read-string (str "(do " (slurp f) "\nnil)")))))]);

if (@ARGV && $ARGV[0] eq "--raw") {
    set_rl_mode("raw");
    shift @ARGV;
}
if (@ARGV) {
    REP(qq[(load-file "$ARGV[0]")]);
    exit 0;
}
while (1) {
    my $line = mal_readline("user> ");
    if (! defined $line) { last; }
    do {
        local $@;
        my $ret;
        eval {
            print(REP($line), "\n");
            1;
        } or do {
            my $err = $@;
            if (defined(blessed $err) && $err->isa('Mal::BlankException')) {
		# ignore and continue
	    } else {
		chomp $err;
		print "Error: $err\n";
            }
        };
    };
}
