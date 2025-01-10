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

    # Cache::LRU compatibility
    method set($key, $value) { self.ASSIGN-KEY($key, $value) }
    method get($key)         { self.AT-KEY($key)             }
    method remove($key)      { self.DELETE-KEY($key)         }
    method clear()           { self = ()                     }
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

# vim: expandtab shiftwidth=4
