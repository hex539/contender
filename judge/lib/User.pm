#!/usr/bin/perl

package User;

use strict;
use warnings;
use feature 'state';
use Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(get force);

use URI::Escape;
use Database;
use AuthCAS;

sub new_bath_cas {
  state $cas = new AuthCAS(casUrl => 'https://auth.bath.ac.uk',
                           CAFile => '/home/hex539/sso-cert.pem');
  return $cas;
}

sub canon_url {
  my ($c) = @_;

  my $result = $c->request->uri;
  $result =~ s/\?[^\?]*$//g;
  return $result;
}

sub get {
  my ($c, %args) = @_;

  $c->session_expires;

  if (exists $c->request->params->{signout}) {
    $c->delete_session;
    $c->response->redirect(canon_url $c);
    $c->detach;
    return undef;
  }

  if (defined $c->request->params->{ticket}) {
    if (my $user = new_bath_cas->validateST(canon_url($c), $c->request->params->{ticket})) {
      $c->session->{username} = $user;
      $c->session_expire_key(username => 36000);
    }
    $c->response->redirect(canon_url $c);
    $c->detach;
    return undef;
  }

  if (not defined $c->session->{username}) {
    if (not exists $args{force} and exists $c->request->params->{signin}) {
      return force($c, %args);
    }
    return undef;
  }

  return db->resultset('users')->find_or_create({
    username => $c->session->{username} . '@bath.ac.uk',
  });
}

sub force {
  my ($c, %args) = @_;

  if (my $result = get($c, %args, force => 1)) {
    return $result;
  }

  $c->response->redirect(new_bath_cas->getServerLoginURL(canon_url($c)));
  $c->detach;
}

1;
