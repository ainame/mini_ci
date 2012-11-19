use strict;
use warnings;

use Test::More;

subtest "use_ok" => sub {
    use_ok 'Sample';
};

subtest "hello" => sub {
    is Sample->hello, 'Hello World';
};

done_testing;
