[![Actions Status](https://github.com/lizmat/Hash-LRU/workflows/test/badge.svg)](https://github.com/lizmat/Hash-LRU/actions)

NAME
====

Hash::LRU - trait for limiting number of keys in hashes by usage

SYNOPSIS
========

    use Hash::LRU;  # Least Recently Used

    my %h is LRU;   # defaults to elements => 100

    my %h is LRU(elements => 42);  # note: value must be known at compile time!

    my %h{Any} is LRU;  # object hashes also supported

DESCRIPTION
===========

Hash::LRU provides a `is LRU` trait on `Hash`es as an easy way to limit the number of keys kept in the `Hash`. Keys will be added as long as the number of keys is under the limit. As soon as a new key is added that would exceed the limit, the least recently used key is removed from the `Hash`.

Both "normal" as well as object hashes are supported.

EXAMPLE
=======

    use Hash::LRU;

    my %h is LRU(elements => 3);

    %h<name>       = "Alex";
    %h<language>   = "Raku";
    %h<occupation> = "devops";
    %h<location>   = "Russia";

    say %h.raku;
    # {:location("Russia"), :occupation("devops"), :language("Raku")}

AUTHOR
======

Elizabeth Mattijsen <liz@raku.rocks>

Source can be located at: https://github.com/lizmat/Hash-LRU . Comments and Pull Requests are welcome.

COPYRIGHT AND LICENSE
=====================

Copyright 2018, 2020, 2021 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

