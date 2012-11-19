use strict;
use warnings;

use Test::More;

subtest "use_ok" => sub {
    use_ok 'SampleNoExists';
};

subtest "hello" => sub {
    is SampleNoExists->hello, 'Hello World';
};

done_testing;
