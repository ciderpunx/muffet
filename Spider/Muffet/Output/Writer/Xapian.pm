package Spider::Muffet::Output::Writer::Xapian;
use Moose;
extends 'Spider::Muffet::Output::Writer';

has '+opts' => (
     default   => sub { {
        xap_tmp_file => '/tmp/muffet.tmp',
        xap_index_file => '/home/charlie/muffet/xapian.index',
        xap_db_file => '/var/lib/xapian-omega/data/default',
      } },
);

after set_opt => sub {
  my $self=shift;
  $self->output_to($self->get_opt('xap_tmp_file'));
};

sub output_record {
  my $self=shift;
  return unless  ($self->title 
                  && $self->url
                  && $self->body);
  my $fh = $self->out;
  print $fh "title=" . $self->title . "\n";
  print $fh "url=" . $self->url . "\n";
  print $fh "body=" . $self->body . "\n";
  print $fh "sample=" . $self->sample . "\n";
  print $fh "modified=" . $self->modified . "\n";
  print $fh "category= " . $self->category . "\n";
  print $fh "tags= " . $self->tags . "\n\n";
}

sub flush {
  # this is a hack to avoid using badly documented xapian::search API
  my $self = shift;
  my $cmd = '/usr/local/bin/scriptindex ' 
            . $self->get_opt('xap_db_file') 
            . ' ' 
            . $self->get_opt('xap_index_file') 
            . ' ' 
            . $self->get_opt('xap_tmp_file'); 
  print "Running $cmd";
  my $res =  `$cmd`;
  print $res;
}
no Moose;
__PACKAGE__->meta->make_immutable;
1;
