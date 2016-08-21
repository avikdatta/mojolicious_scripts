#!/usr/bin/env perl

use strict;
use warnings;
use DBI;
use Mojolicious::Lite;
use Getopt::Long;

my $dbhost='localhost';
my $dbuser=undef;
my $dbpass=undef;
my $dbname=undef;

GetOptions( 'dbhost=s' => \$dbhost,
            'dbuser=s' => \$dbuser,
            'dbpass=s' => \$dbpass,
            'dbname=s' => \$dbname
          );

my %dbparams=( dbhost => $dbhost,
               dbuser => $dbuser,
               dbpass => $dbpass,
               dbname => $dbname
             );

die if (!$dbhost || !$dbuser || !$dbpass || !$dbname);

my $dbh = get_db_con(\%dbparams);
my $exp_type_summary = get_exp_type($dbh);
my $lib_strategy     = get_lib_strategy($dbh);
my $histone_counts   = get_histone_counts($dbh);

## index page
get '/' => sub {
    my $self = shift;
    my $url  = $self->req->url->to_abs->to_string;
    $url =~ s/\/$//;
    $self->render( template => 'index', title => '', url => $url );
};

## summary page
get 'summary' => sub {
  my $self = shift;
  $self->respond_to(
    json => sub{
              $self->render(
                json => {
                  experiment_type  => $exp_type_summary,
                  library_strategy => $lib_strategy,
                  histone_count    => $histone_counts,
                }
              );
            },
    html => sub{
      $self->stash( experiment_type  => $exp_type_summary, 
                    library_strategy => $lib_strategy,
                    histone_count    => $histone_counts
                  );
      $self->render( template => 'summary', title => 'Summary');
    },
  );
};
app->start;

sub get_exp_type{
  my ( $dbh ) = @_;
  my $stmt='select experiment_type, count(filename) as `counts` from ftp_index_file group by experiment_type';
  my $sth = $dbh->prepare($stmt);
  $sth->execute();
  my @summary;
  while(my $row=$sth->fetchrow_hashref()){
    push @summary, $row;
  }
  $sth->finish();
  return \@summary;
}

sub get_lib_strategy{
  my ( $dbh ) = @_;
  my $stmt='select library_strategy, count(distinct sample_name) as sample
            from ftp_index_file
            group by library_strategy'; 
  my $sth = $dbh->prepare($stmt);
  $sth->execute();
  my @summary;
  while(my $row=$sth->fetchrow_hashref()){
    push @summary, $row;
  } 
  $sth->finish();
  return \@summary; 
}

sub get_histone_counts{
  my ( $dbh ) = @_;
  my $stmt='select t.experiment_type as experiment_type,
            count(distinct t.sample_name) as sample from 
            (select experiment_type , sample_name from ftp_index_file 
            where library_strategy = \'ChIP-Seq\')as t
            group by t.experiment_type';
  my $sth = $dbh->prepare($stmt);
  $sth->execute();
  my @summary;
  while(my $row=$sth->fetchrow_hashref()){
    push @summary, $row;
  } 
  $sth->finish();
  return \@summary;
}

sub get_db_con{
  my ($dbparams) = @_;
  my $database = $dbparams->{dbname};
  my $hostname = $dbparams->{dbhost};
  my $user     = $dbparams->{dbuser};
  my $password = $dbparams->{dbpass};

  my $dsn = "DBI:mysql:database=$database;host=$hostname";
  my $dbh = DBI->connect($dsn, $user, $password);

  return $dbh;
}

__DATA__
@@ index.html.ep
<html>
<head>
<title>FTP files information</title>
</head>
<body>
<h1>FTP files information</h1>
<h2>Subpages</h2>
<dl class="dl-horizontal">
<dt><a href="<%= $url %>/summary">/summary</a></dt>
<dd>Report summary stats</dd>
</dl>
</body>

@@ summary.html.ep
<html>
<head>
<title><%= $title %></title>
</head>
<body>
<h2>Experiment type summary</h2>
<table class="table table-hover table-condensed table-striped">
<thead>
<tr>
<th>Experiment type</th>
<th>File counts</th>
</tr>
</thead>
<tbody>

% for my $row ( @$experiment_type) {
  <tr>
    <td><%= $$row{'experiment_type'}%></td>
    <td><%= $$row{'counts'}%></td>
  </tr>
% }
</table>
<p/>
<p/>
<h2>Library strategy summary</h2>
<table class="table table-hover table-condensed table-striped">
<thead>
<tr>
<th>Library strategy</th>
<th>Sample counts</th>
</tr>
</thead>
<tbody>

% for my $row ( @$library_strategy){
  <tr>
    <td><%= $$row{'library_strategy'}%></td>
    <td><%= $$row{'sample'}%></td>
  </tr>
% }
</table>
<p/>
<p/>
<h2>ChIP-Seq Histone summary</h2> 
<table class="table table-hover table-condensed table-striped">
<thead>
<tr>
<th>Experiment type</th>
<th>Sample count</th>
</tr>
</thead>
<tbody>

% for my $row ( @$histone_count ){
  <tr>
    <td><%= $$row{'experiment_type'}%></td>
    <td><%= $$row{'sample'}%></td>
  </tr>
% }
</table>
<p/>
</p>
</body>
