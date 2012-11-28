#! /usr/bin/env perl
use strict;
use warnings;
use TAP::Parser;

my $source = do { local $/; <> };
my $parser = TAP::Parser->new( { source =>  $source } );
while ( my $result =  $parser->next ) {
    if ($result->type eq 'unknown') {
        print $1,"\n" if $result->raw =~ /^.*\#.*(at .*\.t.*)/;
    }
}

__END__

=pod

=NAME

test_error_location.pl

=DESCRIPTION

TAP形式で実行されたテストの結果をパースしてエラー箇所を出力します

=SYNOPSIS

$ prove t/lib/Foo.t | ./test_error_location.pl
at t/lib/Foo.t line 4.
at t/lib/Foo.t line 16.

=AUTHOR

satoshi.namai

=cut
