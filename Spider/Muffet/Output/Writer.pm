package Spider::Muffet::Output::Writer;
binmode STDOUT, ':utf8';
use Moose;
use Moose::Util::TypeConstraints;
use Data::Dumper;

# hash of options to pass on to subclasses
has opts => (
      traits    => ['Hash'],
      is        => 'rw',
      isa       => 'HashRef[Str]',
      auto_deref  => 1,
      default => sub { {} }, 
      handles   => {
          set_opt     => 'set',
          get_opt     => 'get',
          has_no_opts => 'is_empty',
          num_opts    => 'count',
          delete_opt  => 'delete',
          pairs          => 'kv',
      },
);

has out => (
  is => 'rw',
  isa => 'FileHandle',
);

has output_to => (
  is  => 'rw',
  isa    => 'Str',
  default => '&STDOUT',
);

before 'output_to' => sub {
  my $self=shift;
  my $filename = shift;
  return if (!$filename && $self->out);
  open OUT,">$filename" or 
    confess "Can't open output file $filename: $!";
  binmode OUT, ':utf8';
  $self->out(\*OUT);
};


has url => (
  is => 'rw',
  isa => 'Str',
  default => '',
);

has title => (
  is => 'rw',
  isa => 'Str',
  default => 'No title',
);

has body => (
  is => 'rw',
  isa => 'Str',
  default => '',
);
has sample => (
  is => 'rw',
  isa => 'Str',
  default => '',
);

has modified => (
  is => 'rw',
  isa => 'Str',
  default => '',
);

has category => (
  is => 'rw',
  isa => 'Str',
  default => '',
);

has tags => (
  is => 'rw',
  isa => 'Str',
  default => '',
);
sub BUILD {
  my $self=shift;
  $self->output_to('&STDOUT');
}

sub output_record {
  my $self=shift;
  print Dumper $self;
}

sub clear_all {
  my $self=shift;
  $self->url('');
  $self->title('No title');
  $self->body('');
  $self->sample('');
  $self->modified('');
}

sub flush {
  my $self=shift;
}
no Moose;
__PACKAGE__->meta->make_immutable;
1;
