## Domain Registry Interface, EPP Connection handling
##
## Copyright (c) 2005,2006,2007,2008,2009 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
#
# 
#
####################################################################################################

package Net::DRI::Protocol::EPP::Connection;

use strict;
use warnings;

use Net::DRI::Util;
use Net::DRI::Data::Raw;
use Net::DRI::Protocol::ResultStatus;

our $VERSION=do { my @r=(q$Revision: 1.17 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Connection - EPP over TCP/TLS Connection Handling (RFC4934) for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Patrick Mevzek, E<lt>netdri@dotandco.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2005,2006,2007,2008,2009 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub login
{
 my ($class,$cm,$id,$pass,$cltrid,$dr,$newpass,$pdata,$pversion)=@_;

 my $got=$cm->();
 $got->parse($dr);
 my $rg=$got->result_greeting();
 my $version = Net::DRI::Util::check_equal($pversion, ['1.0','0.4'],'1.0');

 my $mes=$cm->();
 $mes->command([$version gt 0.4 ? 'login' : 'creds']);
 my @d;
 push @d,['clID',$id];
 push @d,['pw',$pass];
 push @d,['newPW',$newpass] if (defined($newpass) && $newpass);
 push @d,['options',['version',$rg->{version}->[0]],['lang','en']];

 my @s;
 push @s,map { ['objURI',$_] } @{$rg->{svcs}};
 push @s,['svcExtension',map {['extURI',$_]} @{$rg->{svcext}}] if (exists($rg->{svcext}) && defined($rg->{svcext}) && (ref($rg->{svcext}) eq 'ARRAY'));
 @s=$pdata->{login_service_filter}->(@s) if (defined($pdata) && ref($pdata) eq 'HASH' && exists($pdata->{login_service_filter}) && ref($pdata->{login_service_filter}) eq 'CODE');

 if ($version gt 0.4)
 {
	push @d,['svcs',@s] if @s;
 }
 else
 {
	$mes->ver04login(['svcs', @s]);
 }

 $mes->command_body(\@d);
 $mes->cltrid($cltrid) if $cltrid;
 return $mes;
}

sub logout
{
 my ($class,$cm,$cltrid)=@_;
 my $mes=$cm->();
 $mes->command(['logout']);
 $mes->cltrid($cltrid) if $cltrid;
 return $mes;
}

sub keepalive
{
 my ($class,$cm)=@_;
 my $mes=$cm->();
 $mes->command(['hello']);
 return $mes;
}

####################################################################################################

sub read_data
{
 my ($class,$to,$sock)=@_;
 my $version = $to->{transport}->{protocol_version};
 my $m='';

 if ($version gt 0.4)
 {
  my $c;
  my $rl=$sock->sysread($c,4); ## first 4 bytes are the packed length
  die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_FAILED_CLOSING','Unable to read EPP 4 bytes length (connection closed by registry '.$to->transport_data('remote_uri').' ?): '.($! || 'no error given'),'en')) unless (defined $rl && $rl==4);
  my $length=unpack('N',$c)-4;
  while ($length > 0)
  {
   my $new;
   $length-=$sock->sysread($new,$length);
   $m.=$new;
  }
 }
 else
 {
  my $byte;

  while ($sock->read($byte, 1))
  {
   $m .= $byte;
   last if ($m =~ m!</epp>$!);
   $byte = undef;
  }
 }

 $m=Net::DRI::Util::decode_utf8($m);
 die(Net::DRI::Protocol::ResultStatus->new_error('COMMAND_SYNTAX_ERROR',$m? 'Got unexpected EPP message: '.$m : '<empty message from server>','en')) unless ($m=~m!</epp>\s*$!s);
 return Net::DRI::Data::Raw->new_from_xmlstring($m);
}

sub write_message
{
 my ($self,$to,$msg)=@_;
 my $version = $to->{transport}->{protocol_version};

 my $m=Net::DRI::Util::encode_utf8($msg);
 my $l=pack('N',4+length($m)); ## RFC 4934 �4
 return ($version gt 0.4 ? $l : '') . $m;
}

sub parse_greeting
{
 my ($class,$dc)=@_;
 my ($code,$msg,$lang)=find_code($dc);
 unless (defined($code) && ($code==1000))
 {
  return Net::DRI::Protocol::ResultStatus->new_error('COMMAND_SYNTAX_ERROR','No greeting node',$lang);
 } else
 {
  return Net::DRI::Protocol::ResultStatus->new_success('COMMAND_SUCCESSFUL','Greeting OK',$lang);
 }
}

## Since <hello /> is used as keepalive, answer is a <greeting>
sub parse_keepalive
{
 return shift->parse_greeting(@_);
}

sub parse_login
{
 my ($class,$dc)=@_;
 my ($code,$msg,$lang)=find_code($dc);
 unless (defined($code) && ($code==1000))
 {
  my $eppcode=(defined($code))? $code : 'COMMAND_SYNTAX_ERROR';
  return Net::DRI::Protocol::ResultStatus->new_error($eppcode,$msg || 'Login failed',$lang);
 } else
 {
  return Net::DRI::Protocol::ResultStatus->new_success('COMMAND_SUCCESSFUL',$msg || 'Login OK',$lang);
 }
}

sub parse_logout
{
 my ($class,$dc)=@_;
 my ($code,$msg,$lang)=find_code($dc);
 unless (defined($code) && ($code==1500))
 {
  my $eppcode=(defined($code))? $code : 'COMMAND_SYNTAX_ERROR';
  return Net::DRI::Protocol::ResultStatus->new_error($eppcode,$msg || 'Logout failed',$lang);
 } else
 {
  return Net::DRI::Protocol::ResultStatus->new_success('COMMAND_SUCCESSFUL_END ',$msg || 'Logout OK',$lang);
 }
}

sub find_code
{
 my $dc=shift;
 my $a=$dc->as_string();
 return () unless ($a=~m!</epp>!);
 return (1000,'Greeting OK','en')  if ($a=~m!<greeting>!);
 $a=~s/>[\n\s\t]+/>/g;
 $a=~s/[\n\s\t]+</</g;
 my ($code,$msg,$lang);
 return () unless (($code)=($a=~m!<response><result code=["'](\d+)["']>!));
 return () unless (($lang,$msg)=($a=~m!<msg(?: lang=["'](\S+)["'])?>(.+)</msg>!));
 return (0+$code,$msg,$lang || 'en');
}

## TODO: implement defaults from 4934bis
sub transport_default
{
 my ($self,$tname)=@_;
 return (defer => 0, socktype => 'ssl', ssl_cipher_list => 'TLSv1', remote_port => 700);
}

####################################################################################################
1;
