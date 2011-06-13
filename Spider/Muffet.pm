# Spider::Muffet, a generic spider class for building indexes for search tools.
# currently supports only xapian. Modify out method for others.
package Spider::Muffet;
use Spider::Muffet::Output::Factory;
use Spider::Muffet::Output::Writer;
use Spider::Muffet::Filter::Factory;
use Spider::Muffet::Filter::Reader;
use LWP::UserAgent;
use Data::Dumper;
use POSIX qw(strftime);
use WWW::Mechanize;
use HTML::TreeBuilder::XPath;
use URI;
use LWP::Debug qw(+);
use Moose;
  with 'MooseX::Getopt';
use Moose::Util::TypeConstraints;

has 'user' => (
    is            => 'rw',
    isa           => 'str',
    required      => 0,
    documentation => 'user to attempt http auth with',
);
has 'pass' => (
    is            => 'rw',
    isa           => 'Str',
    required      => 0,
    documentation => 'Password to attempt HTTP auth with',
);
has 'format' => (
    is            => 'rw',
    isa           => 'Str',
    default       => 'raw',
    documentation => 'Output in this format currently Xapian or Raw',
);    
has 'xpath_body' => (
    is      => 'rw',
    isa     => 'Str',
    default => '//body',
    documentation =>
        'Where to look for our body data as an XPath expression',
);
has 'xpath_sample' => (
    is      => 'rw',
    isa     => 'Str',
    default => '//meta[@name="search-teaser"]/@content',
    documentation =>
        'Where to look for our summary data as an XPath expression',
);
has 'xpath_category' => (
    is      => 'rw',
    isa     => 'Str',
    default => '//meta[@name="search-type"]/@content',
    documentation =>
        'Where to look for our title as an XPath expression'
);
has 'xpath_tags' => (
    is      => 'rw',
    isa     => 'Str',
    default => '//meta[@name="search-tags"]/@content',
    documentation =>
        'Where to look for our tags as an XPath expression'
);
has 'xpath_title' => (
    is            => 'rw',
    isa           => 'Str',
    default       => '//meta[@name="search-title"]/@content',
    documentation => 'Where to look for our title in html docs as an XPath expression',
);
has 'xpath_modified' => (
    is            => 'rw',
    isa           => 'Str',
    default       => '//meta[@name="search-mtime"]/@content',
    documentation => 'Where to look for our modification time as an XPath expression',
);
has 'xpath_noindex' => (
    is            => 'rw',
    isa           => 'Str',
    default       => '//meta[@name="search-skip"]/@content',
    documentation => 'Where to look for our noindex elements as an XPath expression',
);
has 'xap_db_file' => (
    is            => 'rw',
    isa           => 'Str',
    documentation => 'Database file for Xapian output',
);
has 'xap_tmp_file' => (
    is            => 'rw',
    isa           => 'Str',
    documentation => 'Temp file for Xapian output defaults to /tmp/muffet.dmp',
);
has 'xap_index_file' => (
    is            => 'rw',
    isa           => 'Str',
    documentation => 'Index description file for scriptindex if using Xapian',
);
has 'ignore' => (
    is            => 'rw',
    isa           => 'Str',
    required      => 0,
    documentation => 'Elements to ignore. should be an array',
);
has 'verbose' => (
    is            => 'rw',
    isa           => 'Bool',
    required      => 0,
    documentation => 'Be verbose',
);
has 'debug' => (
    is            => 'rw',
    isa           => 'Bool',
    required      => 0,
    documentation => 'Show debugging blurb',
);
has 'skip_inpage' => (
    is            => 'rw',
    isa           => 'Bool',
    required      => 0,
    default       => 1,
    documentation => 'Ignore in-page links e.g. href="#chapter_one"',
);
has 'url'  => (
  traits => ['Array'],
  is => 'rw', 
  isa => 'ArrayRef', 
  required => 1,
  handles => {
    add_url => 'push',
    next_url => 'shift',
  },
  documentation => 'The URL/s to start spidering from. If you don\'t say https?://, http:// is inferred',
);
has '_seen' => (
      traits    => ['Hash'],
      is        => 'ro',
      isa       => 'HashRef[Str]',
      default   => sub { {} },
      init_arg  => undef,
      handles  => {
          set_seen => 'set',
          get_seen => 'get',
          was_seen => 'exists',
      }
);
has '_visited' => (
      traits    => ['Hash'],
      is        => 'ro',
      isa       => 'HashRef[Str]',
      default   => sub { {} },
      init_arg  => undef,
      handles  => {
          set_visited => 'set',
          get_visited => 'get',
          was_visited => 'exists',
      }
);
has '_output_writer' => (
  is => 'rw',
  isa => 'Spider::Muffet::Output::Writer',
);
has 'extensions'  => (
  traits => ['Array'],
  is => 'rw', 
  isa => 'ArrayRef', 
  required => 0,
  default   => sub { ['txt','htm','html','shtml','php','pl','pdf','rtf',] },
  documentation => 'Valid File Extensions to Spider',
);
has 'skip_urls'  => (
  traits => ['Array'],
  is => 'rw', 
  isa => 'ArrayRef', 
  required => 0,
  default   => sub { [] },
  documentation => 'URLs containing this/these strings will be skipped',
);
has 'link_tags'  => (
  traits => ['Array'],
  is => 'rw', 
  isa => 'ArrayRef', 
  required => 0,
  default   => sub { ['a'] },
  documentation => 'Only follow link tags of this type eg. a link ',
);
has '_extn_regexp' => (
    is            => 'ro',
    isa           => 'str',
    required      => 0,
);
has '_skip_url_regexp' => (
    is            => 'ro',
    isa           => 'str',
    required      => 0,
);
has '_link_tag_regexp' => (
    is            => 'ro',
    isa           => 'str',
    required      => 0,
);


# starts out the spidering process
sub start {
	my $self = shift;
  my $f = Spider::Muffet::Output::Factory->new;
  $self->{_output_writer} = $f->create_writer($self->format);
  $self->{_output_writer}->set_opt('xap_db_file',$self->xap_db_file) if ($self->xap_db_file);
  $self->{_output_writer}->set_opt('xap_tmp_file',$self->xap_tmp_file) if ($self->xap_tmp_file);
  $self->{_output_writer}->set_opt('xap_index_file',$self->xap_index_file) if ($self->xap_index_file);
  my $regexstr = '\.(' . (join "|", @{$self->extensions}) . ')';
  $self->{_extn_regexp} = qr/$regexstr/i;
  $regexstr = '(' . (join "|", @{$self->skip_urls}) . ')';
  $self->{_skip_url_regexp} = qr/$regexstr/i;
  $regexstr = '(' . (join "|", @{$self->link_tags}) . ')';
  $self->{_link_tag_regexp} = qr/$regexstr/i;
  

  $self->_tidy_base_urls;  

  for my $url (@{$self->url}) {
    $self->visit_url($url);
  }
  $self->_log(Dumper $self->{_visited}) if $self->debug;
  $self->{_output_writer}->flush;
}

# Sort out sketchy urls given on command line
sub _tidy_base_urls {
	my $self = shift;
  my $i=0;
  for my $url (@{$self->url}) {
    my $u = new URI($url);
    unless ($u->scheme) {
      $u->scheme('http');
    }
    my $host = $u->host ||undef;
    unless ($host) {
      my ($host,$path) = split /\//,$url;
      $u->host($host); 
      $u->path($path);
    }
    if($u->path eq '') {
      $u->path('/');
    }
    $self->url->[$i] = "$u";
  }

}


# Visit an URL
sub visit_url {
  my ($self,$url) = (shift,shift);
  if($self->was_visited($url)) {
    return;
  }
  $self->_log("Visiting URL: " . $url);
  $self->set_visited($url,1);
  $self->_get_page($url);
}

sub _get_page {
  my ($self,$url) = (shift,shift);
  # parse host bit out of url
  my $host = URI->new($url)->host;
  my $mech = WWW::Mechanize->new();
  if($self->user && $self->pass) {
    $mech->credentials( $self->user, $self->pass );
  }
  my $err;
  eval { $err = $mech->get($url); };
  unless ($mech->success) {
    $self->_log("!! Unable to retrieve $url. Response: " . $mech->response->status_line);
    return;
  }
  # We deal with non-html content types here. Can't follow links which is fine
  # for now.
  unless($mech->is_html) {
    $self->{_output_writer}->url($url);
    $self->{_output_writer}->title($url);
    $self->{_output_writer}->modified(time());
    my $f = Spider::Muffet::Filter::Factory->new;
    my $filter = $f->create_reader(lc $mech->ct);
    $filter->content($mech->content);
    $self->{_output_writer}->body($filter->body);
    $self->write_record;
    return;
  }

  # Grab all links on this host and add to spidering list
  my @links = $mech->find_all_links(
    tag_regex     => $self->_link_tag_regexp, 
    url_abs_regex => qr|^http://$host| 
  ); 
  foreach my $a (@links) {
    if ($self->was_seen($a->url_abs->as_string)) {
      $self->_log("Already seen " . $a->url_abs->as_string) if $self->debug;
      next;
    }
    next if ($a->url_abs->as_string =~ /#/ && $self->skip_inpage);
    next if ($a->url_abs->as_string =~ $self->{_skip_url_regexp});  
    next unless ($a->url_abs->as_string =~ $self->{_extn_regexp} || $a->url_abs->as_string =~ /\/$/ );
    #next if ($a->url_abs->as_string =~ /\.(css|xml|mp3|ogg|sxw|gz|zip|bz2|bzip2|odt|doc|jpg|jpeg|gif|png)(\?.*)?$/i); # deprecated, but could add back in I guess 
    $self->_log("Adding URL: " . $a->url_abs->as_string);
    $self->add_url($a->url_abs->as_string);
    $self->set_seen($a->url_abs->as_string,1);
  }
  $self->_parse_page($url,$mech->content);
}

sub _parse_page {
  my ($self,$url,$content) = (shift,shift,shift);
  my $tree=HTML::TreeBuilder::XPath->new_from_content($content);
  my $skip = join ' ', $tree->findvalues($self->xpath_noindex);
  if($skip eq 'true') {
    $self->_log("URL $url set to noindex. Skipping.");
    return;
  }
  $self->{_output_writer}->url($url); 
  $self->{_output_writer}->title(join " ", $tree->findvalues($self->xpath_title));
  my $body = join " ", $tree->findnodes_as_strings($self->xpath_body);
  $body =~ s/\n//g;
  $self->{_output_writer}->body($body);
  my $sample = join " ", $tree->findnodes_as_strings($self->xpath_sample);
  $sample =~ s/&(\x23\d+|\w+);?//g; # Strip /all/ html entities
  $sample = "  " if ($sample eq ''); # Should allow empty sample text for eg. xapian
  $self->{_output_writer}->sample($sample);
  $self->{_output_writer}->category(join " ", $tree->findnodes_as_strings($self->xpath_category));
  my $tags = join " ", $tree->findnodes_as_strings($self->xpath_tags);
  $tags=~s/\n//g;
  $self->{_output_writer}->tags($tags);
  my $mtime = join " ", $tree->findvalues($self->xpath_modified);
  $mtime = time() if(!$mtime);
  $self->{_output_writer}->modified($mtime);
  $self->_log("Writing record for URL: " . $url);
  $self->write_record;
  $tree->delete;
}

sub write_record {
	my $self = shift;
	$self->{_output_writer}->output_record;
	$self->{_output_writer}->clear_all;
}

sub _log {
	my ($self,$msg) = (shift,shift);
  return unless $self->verbose;
	warn strftime("%Y-%m-%d %T - ",localtime) . "$msg\n";
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
