# Copyright (c) 2002 Jesse Vincent (jesse@bestpractical.com)

package Class::ReturnValue;

# {{{ POD Overview

=head1 NAME

Class::ReturnValue - A return-value object that lets you treat it 
as as a boolean, array or object

=head1 DESCRIPTION

Class::ReturnValue is a "clever" return value object that can allow
code calling your routine to expect:
    a boolean value (did it fail)
or  a list (what are the return values)

=head1 EXAMPLE

    sub demo {
        my $value = shift;
        my $ret = Class::ReturnValue->new();
        $ret->return_array('0', 'No results found');
    
        unless($value) {
            $ret->return_error(errno => '1',
                               message => "You didn't supply a parameter.",
                               do_backtrace => 1);
        }

        return($ret);
    }

    if (demo('foo')){ 
        print "the routine succeeded with one parameter";
    }
    if (demo()) {
        print "The routine succeeded with 0 paramters. shouldn't happen";
    } else {
        print "The routine failed with 0 parameters (as it should).";
    }


    my $return = demo();
    if ($return) {
        print "The routine succeeded with 0 paramters. shouldn't happen";
    } else {
        print "The routine failed with 0 parameters (as it should). ".
              "Stack trace:\n".
        $return->backtrace;
    }

    my @return3 = demo('foo');
    print "The routine got ".join(',',@return3).
          "when asking for demo's results as an array";


    my $return2 = demo('foo');

    unless ($return2) {
        print "The routine failed with a parameter. shouldn't happen.".
             "Stack trace:\n".
        $return2->backtrace;
    }

    my @return2_array = @{$return2}; # TODO: does this work
    my @return2_array2 = $return2->as_array;



=for testing
use Class::ReturnValue;
use Test::More;

=cut

# }}}

use vars qw($VERSION);
use Carp;
use Devel::StackTrace;

$VERSION = '0.20';

use overload 'bool' => \&error_condition;
use overload '""' => \&error_condition;
use overload 'eq' => \&my_eq;

=head1 METHODS 

=item new

Instantiate a new Class::ReturnValue object

=cut

sub new {
    my $self = {};
    bless($self);
    return($self);
}

sub my_eq {
    my $self = shift;
    if (wantarray()) {
        return($self->as_array);
    }
    else {
        return($self);
    }    
}


=item as_array

Return the 'return_array' attribute of this object as an array.

=begin testing 

sub foo {
    my $r = Class::ReturnValue->new();
    $r->return_array('one', 'two',  'three');
    return $r;
}

my @array;
ok(@array = foo());
is($array[0] , 'one','dereferencing to an array is ok');

ok(my $ref = foo());
ok(my @array2 = $ref->as_array());
is($array2[0] , 'one','dereferencing to an array is ok');

ok(foo(),"Foo returns true in a boolean context");

=end testing

=cut

sub as_array {
    my $self = shift;
    return(@{$self->{'return_array'}});
}



=item return_array ARRAY

If $self is called in an array context, returns the array specified in ARRAY

=cut

sub return_array {

    my $self = shift;
    @{$self->{'return_array'}} = @_;

}


=item return_error HASH

Turns this return-value object into  an error return object.  TAkes three parameters:

    message
    do_backtrace
    errno 

    'message' is a human readable error message explaining what's going on

    'do_backtrace' is a boolean. If it's true, a carp-style backtrace will be 
    stored in $self->{'backtrace'}. It defaults to true

    errno and message default to undef. errno _must_ be specified. 
    It's a numeric error number.  Any true integer value  will cause the 
    object to evaluate to false in a scalar context. At first, this may look a 
    bit counterintuitive, but it means that you can have error codes and still 
    allow simple use of your functions in a style like this:


        if ($obj->do_something) {
            print "Yay! it worked";
        } else {
            print "Sorry. there's been an error.";
        }


        as well as more complex use like this:

        my $retval = $obj->do_something;
        
        if ($retval) {
            print "Yay. we did something\n";
            my ($foo, $bar, $baz) = @{$retval};
            my $human_readable_return = $retval;
        } else {
            if ($retval->errno == 20) {
                die "Failed with error 20 (Not enough monkeys).";
            } else {
                die  $retval->backtrace; # Die and print out a backtrace 
            }
        }
    

=cut

sub return_error {
    my $self = shift;
    my %args = ( errno => undef,
                 message => undef,
                 do_backtrace => 1,
                 @_);

    unless($args{'errno'}) {
        carp "$self -> return_error called without an 'errno' parameter";
        return (undef);
    }

    $self->{'errno'} = $args{'errno'};
    $self->{'error_message'} = $args{'message'};
    if ($args{'do_backtrace'}) {
        # Use carp's internal backtrace methods, rather than duplicating them ourselves
         my $trace = Devel::StackTrace->new(ignore_package => 'Class::ReturnValue');

        $self->{'backtrace'} = $trace->as_string; # like carp
    }

    return(1);
}


=item errno 

Returns the errno if there's been an error. Otherwise, return undef

=cut

sub errno { 
    my $self = shift;
    if ($self->{'errno'}) {
        return ($self->{'errno'});
     }
     else {
        return(undef);
     }
}


=item error_message

If there's been an error return the error message.

=cut

sub error_message {
    my $self = shift;
    if ($self->{'error_message'}) {
        return($self->{'error_message'});
    }
    else {
        return(undef);
    }
}


=item backtrace

If there's been an error and we asked for a backtrace, return the backtrace. 
Otherwise, return undef.

=cut

sub backtrace {
    my $self = shift;
    if ($self->{'backtrace'}) {
        return($self->{'backtrace'});
    }
    else {
        return(undef);
    }
}

=begin testing


sub bar {
    my $retval3 = Class::ReturnValue->new();
    $retval3->return_array(1,'asq');
    return $retval3;
}
ok(bar());
sub baz {
    my $retval = Class::ReturnValue->new();
    $retval->return_error(errno=> 1);
    return $retval;
}

if(baz()){
 ok (0,"returning an error evals as true");
} else {
 ok (1,"returning an error evals as false");

}
exit(0);

ok(my $retval = Class::ReturnValue->new());
ok($retval->return_error( errno => 20,
                        message => "You've been eited",
                        do_backtrace => 1));
ok($retval->backtrace ne undef);
is($retval->error_message,"You've been eited");
ok(!$retval);


ok(my $retval2 = Class::ReturnValue->new());
ok($retval2->return_error( errno => 1,
                            message => "You've been eited",
                             do_backtrace => 0 ));
ok($retval2->backtrace eq undef);
is($retval2->errno, 1, "Got the errno");
isnt($retval2->errno,20, "Errno knows that 20 != 1");

=end testing

=cut

=item error_condition

If there's been an error, return undef. Otherwise return 1

=cut

sub error_condition { 
    my $self = shift;
    if ($self->{'errno'}) {
            return (0);
        }
        elsif (wantarray()) {
            return(@{$self->{'return_array'}});
        }
       else { 
            return(1);
       }     
}

=head1 AUTHOR
    
    Jesse Vincent <jesse@bestpractical.com>

=head1 BUGS

    This module has, as yet, not been used in production code. I thing
    it should work, but have never benchmarked it. I have not yet used
    it extensively, though I do plan to in the not-too-distant future.
    If you have questions or comments,  please write me.

    If you need to report a bug, please send mail to 
    <bug-class-returnvalue@rt.cpan.org> or report your error on the web
    at http://rt.cpan.org/

=head1 COPYRIGHT

    Copyright (c) 2002, Jesse Vincent <jesse@bestpractical.com>
    You may use, modify, fold, spindle or mutilate this module under
    the same terms as perl itself.

=head1 SEE ALSO

    Class::ReturnValue isn't an exception handler. If it doesn't
    do what you want, you might want look at one of the exception handlers
    below

    Error, Exception, Exceptions, Exceptions::Class

=cut

1;
