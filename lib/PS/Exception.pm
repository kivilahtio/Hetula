use 5.22.0;

package PS::Exception;

use Exception::Class (
  'PS::Exception' => {
    description => 'PatronStore exceptions base class',
  },
);

use Scalar::Util qw(blessed);

sub newFromDie {
  my ($class, $die) = @_;
  return PS::Exception->new(error => "$die");
}

=head2 handleDefaults

Handles all the boring exception cases in a default way. Saving you a lot of typing.

Instead of:
    return $c->render(status => 500, text => $_) unless blessed($_); #Hopefully with a good stack trace
    return $c->render(status => 401, text => $_->toText) if $_->isa('PS::Exception::Auth::Authentication');
    return $c->render(status => 403, text => $_->toText) if $_->isa('PS::Exception::Auth');
    return $c->render(status => 404, text => $_->toText) if $_->isa('PS::Exception::User::NotFound');
    return $c->render(status => 500, text => $_->toText) if $_->isa('PS::Exception');
    return $c->render(status => 500, text => PS::Exception::toTextMojo($_)) if $_->isa('Mojo::Exception');
    return $c->render(status => 500, text => PS::Exception::toTextUnknown($_));

You can say:

    my $default = PS::Exception::handleDefaults($_);
    return $c->render(status => 500, text => $default) if $default;
    return $c->render(status => 401, text => $_->toText) if $_->isa('PS::Exception::Auth::Authentication');
    return $c->render(status => 403, text => $_->toText) if $_->isa('PS::Exception::Auth');
    return $c->render(status => 404, text => $_->toText) if $_->isa('PS::Exception::User::NotFound');

=cut

sub handleDefaults {
  my ($e) = @_;

  return $e unless blessed($e);
  return toTextMojo($e) if $e->isa('Mojo::Exception');
  return $e->toText if ref($e) eq 'PS::Exception'; #If this is THE 'PS::Exception', then handle it here
  return undef if $e->isa('PS::Exception'); #If this is a subclass of 'PS::Exception', then let it through
  return toTextUnknown($e);
}

=head2 toText

@RETURNS String, a textual representation of this exception,
                 Full::module::package :> error message, other supplied error keys

=cut

sub toText {
  my ($self) = @_;

  my @sb;
  push(@sb, ref($self).' :> '.$self->error);
# You can override global exception handling behaviour here.
# Maybe throw stack traces or somehow automatically identify
# supplementary exception payloads to show?
#
#  while (my ($k, $v) = each(%$self)) {
#    next if $k eq 'error';
#    push(@sb, "$k => '$v'");
#  }
  return join(', ', @sb);
}

=head2 toTextUnknown
@STATIC

@RETURNS String, a textual representation of this exception,
                 Full::module::package :> error message, other supplied error keys

=cut

sub toTextUnknown {
  my ($e) = @_;

  my @sb;
  if (ref($e) eq 'HASH' || blessed($e)) {
    while (my ($k, $v) = each(%$e)) {
      push(@sb, "$k => '$v'");
    }
  }
  elsif (ref($e) eq 'ARRAY') {
    @sb = @$e;
  }
  else {
    push(@sb, $e);
  }
  return join(', ', @sb);
}

=head2 toTextMojo

Returns a text representation of a Mojo::Exception

=cut

sub toTextMojo {
    my ($e) = @_;
    return $e->verbose(1)->to_string;
}

return 1;
