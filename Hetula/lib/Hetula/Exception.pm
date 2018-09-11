package Hetula::Exception;

use Hetula::Pragmas;

my $l = bless({}, 'Hetula::Logger');

use Exception::Class (
  'Hetula::Exception' => {
    description => 'Hetula exceptions base class',
    fields => ['httpStatus'],
  },
);

=head2 generateNew

Returns Perl code block which when eval'd creates a constructor for the class
setting the Exception::Class instances' package variable $httpStatus as the
httpStatus-fields value, if it doesn't already exist.

This hack erases code duplication for this feature touching all Exceptions in Hetula.

=cut

sub generateNew {
  return 'sub new {
    my $class = shift;
    push(@_, httpStatus => $httpStatus) unless (List::Util::first {$_ eq "httpStatus"} @_);
    my $self = $class->SUPER::new(@_);
  }';
}

sub newFromDie {
  my ($class, $die) = @_;
  return Hetula::Exception->new(error => "$die");
}

=head2 rethrowDefault

Because there are so many different types of exception classes with different
interfaces, use this to rethrow if you dont know exactly what you are getting.

@PARAM1 somekind of monster

=cut

sub rethrowDefaults {
  my ($e) = @_;

  die $e unless blessed($e);
  die $e if $e->isa('Mojo::Exception'); #Dying a Mojo::Exception actually rethrows it.
  $e->rethrow if ref($e) eq 'Hetula::Exception'; #If this is THE 'Hetula::Exception', then handle it here
  $e->rethrow if $e->isa('Hetula::Exception'); #If this is a subclass of 'Hetula::Exception', then let it through
  $e->rethrow; #Exception classes are expected to implement rethrow like good exceptions should!!
}

=head2 handleDefaults

Handles all the boring exception cases in a default way. Saving you a lot of typing.

Instead of:
    return $c->render(status => 500, text => $_) unless blessed($_); #Hopefully with a good stack trace
    return $c->render(status => 401, text => $_->toText) if $_->isa('Hetula::Exception::Auth::Authentication');
    return $c->render(status => 403, text => $_->toText) if $_->isa('Hetula::Exception::Auth');
    return $c->render(status => 404, text => $_->toText) if $_->isa('Hetula::Exception::User::NotFound');
    return $c->render(status => 500, text => $_->toText) if $_->isa('Hetula::Exception');
    return $c->render(status => 500, text => Hetula::Exception::toTextMojo($_)) if $_->isa('Mojo::Exception');
    return $c->render(status => 500, text => Hetula::Exception::toTextUnknown($_));

You can say:

    my @render = Hetula::Exception::handleDefaults($_);
    @render = (status => 401, text => $_->toText) if $_->isa('Hetula::Exception::Auth::Authentication');
    @render = (status => 403, text => $_->toText) if $_->isa('Hetula::Exception::Auth');
    @render = (status => 404, text => $_->toText) if $_->isa('Hetula::Exception::User::NotFound');
    $c->render(@render);

Or, if using the Exception default http status codes, even:

    return $c->render(Hetula::Exception::handleDefaults($_));

=cut

sub handleDefaults {
  my ($e) = @_;

  return (status => 500, text => $e) unless blessed($e);
  return (status => 500, text => toTextMojo($e)) if $e->isa('Mojo::Exception');
  return (status => 500, text => $e->toText) if ref($e) eq 'Hetula::Exception'; #If this is THE 'Hetula::Exception', then handle it here
  return (status => $e->httpStatus || 500, text => $e->toText) if $e->isa('Hetula::Exception'); #If this is a subclass of 'Hetula::Exception', then handle it here, the status|text can be later overridden
  return (status => 500, text => toTextUnknown($e));
}

=head2 toText

@RETURNS String, a textual representation of this exception,
                 Full::module::package :> error message, other supplied error keys

=cut

sub toText {
  my ($self) = @_;

  my @sb;
  push(@sb, _toTextHeader($self));

  # You can override global exception handling behaviour here.
  # Maybe throw stack traces or somehow automatically identify
  # supplementary exception payloads to show?
  if (Hetula::Logger::isMojoDebug() || $l->is_debug()) {
    #Show any extra fields/keys
    my @kb = ('Extra exception keys:');
    while (my ($k, $v) = each(%$self)) {
      next if ($k eq 'error' || $k eq 'message' || $k eq 'trace');
      push(@kb, "$k => '$v'");
    }
    push(@sb, join(', ', @kb));
    #Show stack trace
    if (my $trace = $self->{trace}) {
      if ($ENV{MOJO_LOG_LEVEL} ne 'trace') {
        my @rows = split("\n", $trace);
        $trace = join("\n<br/>    ", $rows[0], $rows[1], $rows[2], $rows[3], $rows[4], $rows[5], $rows[6], $rows[7]); #Why this doesn't work?   $trace =~ /((?:^.+?$){10})/sm;
      }
      push(@sb, 'Exception stack trace:', $trace);
    }
  }
  return join("\n<br/>", @sb); #Maybe the separator works for both worlds :D
}

sub _toTextHeader {
  my ($self) = @_;
  return ref($self).' :> '.$self->error;
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

1;
