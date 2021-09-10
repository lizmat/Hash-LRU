use v6.d;

module Hash::LRU:ver<0.0.5>:auth<zef:lizmat> {

    # The basic logic for keeping LRU data up-to-date
    my role basic {
        method AT-KEY(::?CLASS:D: \key) is raw is hidden-from-backtrace {
            self!SEEN-KEY(key) if self.EXISTS-KEY(key);
            nextsame
        }
        method ASSIGN-KEY(::?CLASS:D: \key, \value) is hidden-from-backtrace {
            self!SEEN-KEY(key);
            nextsame
        }
        method BIND-KEY(::?CLASS:D: \key, \value) is hidden-from-backtrace {
            self!SEEN-KEY(key);
            nextsame
        }
        method STORE(\to_store) is hidden-from-backtrace {
            callsame;
            self!INIT-KEYS;
            self!SEEN-KEY($_) for self.keys;
            self
        }
    }

    # The role to be applied when a specific limit is given for hashes
    my role limit-given-hash[$max] does basic {
        my int $max-elems = $max;  # cannot parameterize to a native int yet
        has str @!keys;

        method !INIT-KEYS(--> Nil) {
            @!keys = ();
        }

        method !SEEN-KEY(Str(Any) $key --> Nil) {
            if @!keys.elems -> int $elems {
                my int $i = -1;
                Nil while ++$i < $elems && @!keys.AT-POS($i) ne $key;
                if $i < $elems {
                    @!keys.splice($i,1);
                }
                elsif $elems == $max-elems {
                    self.DELETE-KEY(@!keys.pop);
                }
            }
            @!keys.unshift($key);
        }
    }

    # The role to be applied when a specific limit is given for object hashes
    my role limit-given-object-hash[$max] does basic {
        my int $max-elems = $max;  # cannot parameterize to a native int yet
        has str @!whiches;
        has @!keys;

        method !INIT-KEYS(--> Nil) {
            @!whiches = ();
            @!keys    = ();
        }

        method !SEEN-KEY(\key --> Nil) {
            my str $WHICH = key.WHICH;
            if @!whiches.elems -> int $elems {
                my int $i = -1;
                Nil while ++$i < $elems && @!whiches.AT-POS($i) ne $WHICH;
                if $i < $elems {
                    @!whiches.splice($i,1);
                    @!keys.splice($i,1);
                }
                elsif $elems == $max-elems {
                    @!whiches.pop;
                    self.DELETE-KEY(@!keys.pop);
                }
            }
            @!whiches.unshift($WHICH);
            @!keys.unshift(key);
        }
    }

    # Handle the "is LRU" / is LRU(Bool:D) cases
    multi sub trait_mod:<is>(Variable:D \v, Bool:D :$LRU!) is export {
        die "Can only apply 'is LRU' on a Hash, not a {v.var.WHAT}"
          unless v.var.WHAT ~~ Hash;
        my $name = v.var.^name;
        if $LRU {
            trait_mod:<does>(v, v.var.keyof =:= Str(Any)
              ?? limit-given-hash[100]
              !! limit-given-object-hash[100]
            );
            v.var.WHAT.^set_name("$name\(LRU)");
        }
    }

    # Handle the "is LRU(elements => N)" case
    multi sub trait_mod:<is>(Variable:D \v, :%LRU!) is export {
        die "Can only apply 'is LRU' on a Hash, not a {v.var.WHAT}"
          unless v.var.WHAT ~~ Hash;
        my $name = v.var.^name;

        if %LRU<elements>:exists {
            with %LRU<elements> {
                trait_mod:<does>(v, v.var.keyof =:= Str(Any)
                  ?? limit-given-hash[$_]
                  !! limit-given-object-hash[$_]
                );
            }
            else {
                die "Cannot use an undefined value for 'elements' in 'is LRU'. "
                    ~ 'Did you try to set it at runtime?';
            }
        }
        elsif %LRU.keys.sort -> @keys {
            die "Don't know what to do with '{ @keys }' in 'is LRU'";
        }
        v.var.WHAT.^set_name("$name\(LRU)");
    }
}

=begin pod

=head1 NAME

Hash::LRU - trait for limiting number of keys in hashes by usage

=head1 SYNOPSIS

  use Hash::LRU;  # Least Recently Used

  my %h is LRU;   # defaults to elements => 100

  my %h is LRU(elements => 42);  # note: value must be known at compile time!

  my %h{Any} is LRU;  # object hashes also supported

=head1 DESCRIPTION

Hash::LRU provides a C<is LRU> trait on C<Hash>es as an easy way to limit
the number of keys kept in the C<Hash>.  Keys will be added as long as
the number of keys is under the limit.  As soon as a new key is added that
would exceed the limit, the least recently used key is removed from the
C<Hash>.

Both "normal" as well as object hashes are supported.

=head1 EXAMPLE

  use Hash::LRU;

  my %h is LRU(elements => 3);

  %h<name>       = "Alex";
  %h<language>   = "Raku";
  %h<occupation> = "devops";
  %h<location>   = "Russia";

  say %h.raku;
  # {:location("Russia"), :occupation("devops"), :language("Raku")}

=head1 AUTHOR

Elizabeth Mattijsen <liz@raku.rocks>

Source can be located at: https://github.com/lizmat/Hash-LRU . Comments and
Pull Requests are welcome.

=head1 COPYRIGHT AND LICENSE

Copyright 2018, 2020, 2021 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under
the Artistic License 2.0.

=end pod

# vim: expandtab shiftwidth=4
