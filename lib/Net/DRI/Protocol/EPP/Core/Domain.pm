## Domain Registry Interface, EPP Domain commands (RFC3731)
##
## Copyright (c) 2005,2006,2007 Patrick Mevzek <netdri@dotandco.com>. All rights reserved.
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

package Net::DRI::Protocol::EPP::Core::Domain;

use strict;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Data::Hosts;
use Net::DRI::Data::ContactSet;
use Net::DRI::Protocol::EPP;

use DateTime::Format::ISO8601;

our $VERSION=do { my @r=(q$Revision: 1.12 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Core::Domain - EPP Domain commands (RFC3731) for Net::DRI

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

Copyright (c) 2005,2006,2007 Patrick Mevzek <netdri@dotandco.com>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub register_commands
{
 my ($class,$version)=@_;
 my %tmp=(
           check  => [ \&check, \&check_parse ],
           info   => [ \&info, \&info_parse ],
           transfer_query  => [ \&transfer_query, \&transfer_parse ],
           create => [ \&create, \&create_parse ],
           delete => [ \&delete ],
           renew => [ \&renew, \&renew_parse ],
           transfer_request => [ \&transfer_request, \&transfer_parse ],
           transfer_cancel  => [ \&transfer_cancel,\&transfer_parse ],
           transfer_answer  => [ \&transfer_answer,\&transfer_parse ],
           update => [ \&update ],
           review_complete => [ undef, \&pandata_parse ],
         );

 $tmp{check_multi}=$tmp{check};
 return { 'domain' => \%tmp };
}

sub build_command
{
 my ($msg,$command,$domain,$domainattr)=@_;
 my @dom=(ref($domain))? @$domain : ($domain);
 Net::DRI::Exception->die(1,'protocol/EPP',2,"Domain name needed") unless @dom;
 foreach my $d (@dom)
 {
  Net::DRI::Exception->die(1,'protocol/EPP',2,'Domain name needed') unless defined($d) && $d;
  Net::DRI::Exception->die(1,'protocol/EPP',10,'Invalid domain name: '.$d) unless Net::DRI::Util::is_hostname($d);
 }

 my $tcommand=(ref($command))? $command->[0] : $command;
 my @ns=@{$msg->ns->{domain}};
 $msg->command([$command,'domain:'.$tcommand,sprintf('xmlns:domain="%s" xsi:schemaLocation="%s %s"',$ns[0],$ns[0],$ns[1])]);


 my @d=map { ['domain:name',$_,$domainattr] } @dom;
 return @d;
}

sub build_authinfo
{
 my $rauth=shift;
 return ['domain:authInfo',['domain:pw',$rauth->{pw},exists($rauth->{roid})? { 'roid' => $rauth->{roid} } : undef]];
}

sub build_period
{
 my $dtd=shift; ## DateTime::Duration
 my ($y,$m)=$dtd->in_units('years','months'); ## all values are integral, but may be negative
 ($y,$m)=(0,$m+12*$y) if ($y && $m);
 my ($v,$u);
 if ($y)
 {
  Net::DRI::Exception::usererr_invalid_parameters("years must be between 1 and 99") unless ($y >= 1 && $y <= 99);
  $v=$y;
  $u='y';
 } else
 {
  Net::DRI::Exception::usererr_invalid_parameters("months must be between 1 and 99") unless ($m >= 1 && $m <= 99);
  $v=$m;
  $u='m';
 }
 
 return ['domain:period',$v,{'unit' => $u}];
}

##################################################################################################

########### Query commands

sub check
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,'check',$domain);
 $mes->command_body(\@d);
}


sub check_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $chkdata=$mes->get_content('chkData',$mes->ns('domain'));
 return unless $chkdata;
 foreach my $cd ($chkdata->getElementsByTagNameNS($mes->ns('domain'),'cd'))
 {
  my $c=$cd->getFirstChild();
  my $domain;
  while($c)
  {
   my $n=$c->localname() || $c->nodeName();
   if ($n eq 'name')
   {
    $domain=lc($c->getFirstChild()->getData());
    $rinfo->{domain}->{$domain}->{action}='check';
    $rinfo->{domain}->{$domain}->{exist}=1-Net::DRI::Util::xml_parse_boolean($c->getAttribute('avail'));
   }
   if ($n eq 'reason')
   {
    $rinfo->{domain}->{$domain}->{exist_reason}=$c->getFirstChild()->getData();
   }
   $c=$c->getNextSibling();
  }
 }
}

sub verify_rd
{
 my ($rd,$key)=@_;
 return 0 unless (defined($key) && $key);
 return 0 unless (defined($rd) && (ref($rd) eq 'HASH') && exists($rd->{$key}) && defined($rd->{$key}));
 return 1;
}

sub info
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my $hosts='all';
 $hosts=$rd->{hosts} if (defined($rd) && (ref($rd) eq 'HASH') && exists($rd->{hosts}) && ($rd->{hosts}=~m/^(?:all|del|sub|none)$/));
 my @d=build_command($mes,'info',$domain,{'hosts'=> $hosts});
 push @d,build_authinfo($rd->{auth}) if (verify_rd($rd,'auth') && (ref($rd->{auth}) eq 'HASH'));
 $mes->command_body(\@d);
}

sub info_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();
 my $infdata=$mes->get_content('infData',$mes->ns('domain'));
 return unless $infdata;
 my (@s,@host);
 my $cs=Net::DRI::Data::ContactSet->new();
 my $cf=$po->factories()->{contact};
 my $c=$infdata->getFirstChild();
 while ($c)
 {
  my $name=$c->localname() || $c->nodeName();
  next unless $name;
  if ($name eq 'name')
  {
   $oname=lc($c->getFirstChild()->getData());
   $rinfo->{domain}->{$oname}->{action}='info';
   $rinfo->{domain}->{$oname}->{exist}=1;
  } elsif ($name eq 'roid')
  {
   $rinfo->{domain}->{$oname}->{roid}=$c->getFirstChild()->getData();
  } elsif ($name eq 'status')
  {
   push @s,Net::DRI::Protocol::EPP::parse_status($c);
  } elsif ($name eq 'registrant')
  {
   $cs->set($cf->()->srid($c->getFirstChild()->getData()),'registrant');
  } elsif ($name eq 'contact')
  {
   $cs->add($cf->()->srid($c->getFirstChild()->getData()),$c->getAttribute('type'));
  } elsif ($name eq 'ns')
  {
   $rinfo->{domain}->{$oname}->{ns}=parse_ns($c);
  } elsif ($name eq 'host')
  {
   push @host,$c->getFirstChild()->getData();
  } elsif ($name=~m/^(clID|crID|upID)$/)
  {
   $rinfo->{domain}->{$oname}->{$1}=$c->getFirstChild()->getData();
  } elsif ($name=~m/^(crDate|upDate|trDate|exDate)$/)
  {
   $rinfo->{domain}->{$oname}->{$1}=DateTime::Format::ISO8601->new()->parse_datetime($c->getFirstChild()->getData());
  } elsif ($name eq 'authInfo')
  {
   my $pw=($c->getElementsByTagNameNS($mes->ns('domain'),'pw'))[0]; ## will be empty on domain:info request for objects we do not own
   $rinfo->{domain}->{$oname}->{auth}={pw => ($pw->hasChildNodes())? $pw->getFirstChild()->getData() : undef };
  }
  $c=$c->getNextSibling();
 }

 $rinfo->{domain}->{$oname}->{contact}=$cs;
 $rinfo->{domain}->{$oname}->{status}=$po->create_local_object('status')->add(@s);
 $rinfo->{domain}->{$oname}->{host}=Net::DRI::Data::Hosts->new_set(@host) if @host;
}

sub parse_ns ## RFC 3731 �1.1
{
 my $node=shift;
 my $ns=Net::DRI::Data::Hosts->new();

 my $n=$node->getFirstChild();
 while($n)
 {
  my $name=$n->localname() || $n->nodeName();
  next unless $name;
  if ($name eq 'hostObj')
  {
   $ns->add($n->getFirstChild()->getData());
  } elsif ($name eq 'hostAttr')
  {
   my ($hostname,@ip4,@ip6);
   my $nn=$n->getFirstChild();
   while($nn)
   {
    my $name2=$nn->localname() || $nn->nodeName();
    next unless $name2;
    if ($name2 eq 'hostName')
    {
     $hostname=$nn->getFirstChild()->getData();
    } elsif ($name2 eq 'hostAddr')
    {
     my $ip=$nn->getAttribute('ip') || 'v4';
     if ($ip eq 'v6')
     {
      push @ip6,$nn->getFirstChild()->getData();
     } else
     {
      push @ip4,$nn->getFirstChild()->getData();
     }
    }
    $nn=$nn->getNextSibling();
   }
   $ns->add($hostname,\@ip4,\@ip6);
  }
  $n=$n->getNextSibling();
 }
 return $ns;
}

sub transfer_query
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,['transfer',{'op'=>'query'}],$domain);
 push @d,build_authinfo($rd->{auth}) if (verify_rd($rd,'auth') && (ref($rd->{auth}) eq 'HASH'));
 $mes->command_body(\@d);
}

sub transfer_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $trndata=$mes->get_content('trnData',$mes->ns('domain'));
 return unless $trndata;

 my $c=$trndata->getFirstChild();
 while ($c)
 {
  my $name=$c->localname() || $c->nodeName();
  next unless $name;

  if ($name eq 'name')
  {
   $oname=lc($c->getFirstChild()->getData());
   $rinfo->{domain}->{$oname}->{action}='transfer';
   $rinfo->{domain}->{$oname}->{exist}=1;
  } elsif ($name=~m/^(trStatus|reID|acID)$/)
  {
   $rinfo->{domain}->{$oname}->{$1}=$c->getFirstChild()->getData();
  } elsif ($name=~m/^(reDate|acDate|exDate)$/)
  {
   $rinfo->{domain}->{$oname}->{$1}=DateTime::Format::ISO8601->new()->parse_datetime($c->getFirstChild()->getData());
  }
  $c=$c->getNextSibling();
 }
}

############ Transform commands

sub create
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,'create',$domain);
 
 my $def=$epp->default_parameters();
 if ($def && (ref($def) eq 'HASH') && exists($def->{domain_create}) && (ref($def->{domain_create}) eq 'HASH'))
 {
  $rd={} unless ($rd && (ref($rd) eq 'HASH') && keys(%$rd));
  while(my ($k,$v)=each(%{$def->{domain_create}}))
  {
   next if exists($rd->{$k});
   $rd->{$k}=$v;
  }
 }

 ## Period, OPTIONAL
 if (verify_rd($rd,'duration'))
 {
  my $period=$rd->{duration};
  Net::DRI::Util::check_isa($period,'DateTime::Duration');
  push @d,build_period($period);
 }

 ## Nameservers, OPTIONAL
 push @d,build_ns($epp,$rd->{ns},$domain) if (verify_rd($rd,'ns') && UNIVERSAL::isa($rd->{ns},'Net::DRI::Data::Hosts') && !$rd->{ns}->is_empty());

 ## Contacts, all OPTIONAL
 if (verify_rd($rd,'contact') && UNIVERSAL::isa($rd->{contact},'Net::DRI::Data::ContactSet'))
 {
  my $cs=$rd->{contact};
  my @o=$cs->get('registrant');
  push @d,['domain:registrant',$o[0]->srid()] if (@o);
  push @d,build_contact_noregistrant($cs);
 }

 ## AuthInfo
 Net::DRI::Exception::usererr_insufficient_parameters("authInfo is mandatory") unless (verify_rd($rd,'auth') && (ref($rd->{auth}) eq 'HASH'));
 push @d,build_authinfo($rd->{auth});
 $mes->command_body(\@d);
}

sub build_contact_noregistrant
{
 my $cs=shift;
 my @d;
 foreach my $t (sort($cs->types()))
 {
  next if ($t eq 'registrant');
  my @o=$cs->get($t);
  push @d,map { ['domain:contact',$_->srid(),{'type'=>$t}] } @o;
 }
 return @d;
}

sub build_ns
{
 my ($epp,$ns,$domain,$xmlns)=@_;

 my @d;
 my $asattr=$epp->{hostasattr};

 if ($asattr)
 {
  foreach my $i (1..$ns->count())
  {
   my ($n,$r4,$r6)=$ns->get_details($i);
   my @h;
   push @h,['domain:hostName',$n];
   if (($n=~m/\S+\.${domain}$/i) || (lc($n) eq lc($domain)) || ($asattr==2))
   {
    push @h,map { ['domain:hostAddr',$_,{ip=>'v4'}] } @$r4 if @$r4;
    push @h,map { ['domain:hostAddr',$_,{ip=>'v6'}] } @$r6 if @$r6;
   }
   push @d,['domain:hostAttr',@h];
  }
 } else
 {
  @d=map { ['domain:hostObj',$_] } $ns->get_names();
 }

 $xmlns='domain' unless defined($xmlns);
 return [$xmlns.':ns',@d];
}

sub create_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $credata=$mes->get_content('creData',$mes->ns('domain'));
 return unless $credata;

 my $c=$credata->getFirstChild();
 while ($c)
 {
  my $name=$c->localname() || $c->nodeName();
  next unless $name;

  if ($name eq 'name')
  {
   $oname=lc($c->getFirstChild()->getData());
   $rinfo->{domain}->{$oname}->{action}='create';
   $rinfo->{domain}->{$oname}->{exist}=1;
  } elsif ($name=~m/^(crDate|exDate)$/)
  {
   $rinfo->{domain}->{$oname}->{$1}=DateTime::Format::ISO8601->new()->parse_datetime($c->getFirstChild()->getData());
  }
  $c=$c->getNextSibling();
 }
}

sub delete
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,'delete',$domain);
 $mes->command_body(\@d);
}

sub renew
{
 my ($epp,$domain,$period,$curexp,$rd)=@_;
 Net::DRI::Exception::usererr_insufficient_parameters("current expiration year") unless defined($curexp);
 $curexp=$curexp->set_time_zone('UTC')->strftime("%Y-%m-%d") if (ref($curexp) && UNIVERSAL::isa($curexp,'DateTime'));
 Net::DRI::Exception::usererr_invalid_parameters("current expiration year must be YYYY-MM-DD") unless $curexp=~m/^\d{4}-\d{2}-\d{2}$/;
 
 my $mes=$epp->message();
 my @d=build_command($mes,'renew',$domain);
 push @d,['domain:curExpDate',$curexp];
 if (defined($period))
 {
  Net::DRI::Util::check_isa($period,'DateTime::Duration');
  push @d,build_period($period);
 }

 $mes->command_body(\@d);
}

sub renew_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $rendata=$mes->get_content('renData',$mes->ns('domain'));
 return unless $rendata;

 my $c=$rendata->getFirstChild();
 while ($c)
 {
  my $name=$c->localname() || $c->nodeName();
  next unless $name;

  if ($name eq 'name')
  {
   $oname=lc($c->getFirstChild()->getData());
   $rinfo->{domain}->{$oname}->{action}='renew';
   $rinfo->{domain}->{$oname}->{exist}=1;
  } elsif ($name=~m/^(exDate)$/)
  {
   $rinfo->{domain}->{$oname}->{$1}=DateTime::Format::ISO8601->new()->parse_datetime($c->getFirstChild()->getData());
  }
  $c=$c->getNextSibling();
 }
}

sub transfer_request
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,['transfer',{'op'=>'request'}],$domain);

 if (verify_rd($rd,'duration'))
 {
  Net::DRI::Util::check_isa($rd->{duration},'DateTime::Duration');
  push @d,build_period($rd->{duration});
 }

 push @d,build_authinfo($rd->{auth}) if (verify_rd($rd,'auth') && (ref($rd->{auth}) eq 'HASH'));
 $mes->command_body(\@d);
}

sub transfer_answer
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,['transfer',{'op'=>(verify_rd($rd,'approve') && $rd->{approve})? 'approve' : 'reject'}],$domain);
 push @d,build_authinfo($rd->{auth}) if (verify_rd($rd,'auth') && (ref($rd->{auth}) eq 'HASH'));
 $mes->command_body(\@d);
}

sub transfer_cancel
{
 my ($epp,$domain,$rd)=@_;
 my $mes=$epp->message();
 my @d=build_command($mes,['transfer',{'op'=>'cancel'}],$domain);
 push @d,build_authinfo($rd->{auth}) if (verify_rd($rd,'auth') && (ref($rd->{auth}) eq 'HASH'));
 $mes->command_body(\@d);
}

sub update
{
 my ($epp,$domain,$todo)=@_;
 my $mes=$epp->message();

 Net::DRI::Exception::usererr_invalid_parameters($todo." must be a Net::DRI::Data::Changes object") unless ($todo && UNIVERSAL::isa($todo,'Net::DRI::Data::Changes'));

 if ((grep { ! /^(?:add|del)$/ } $todo->types('ns')) ||
     (grep { ! /^(?:add|del)$/ } $todo->types('status')) ||
     (grep { ! /^(?:add|del)$/ } $todo->types('contact')) ||
     (grep { ! /^set$/ } $todo->types('registrant')) ||
     (grep { ! /^set$/ } $todo->types('auth'))
    )
 {
  Net::DRI::Exception->die(0,'protocol/EPP',11,'Only ns/status/contact add/del or registrant/authinfo set available for domain');
 }

 my @d=build_command($mes,'update',$domain);

 my $nsadd=$todo->add('ns');
 my $nsdel=$todo->del('ns');
 my $sadd=$todo->add('status');
 my $sdel=$todo->del('status');
 my $cadd=$todo->add('contact');
 my $cdel=$todo->del('contact');
 my (@add,@del);

 push @add,build_ns($epp,$nsadd,$domain)            if $nsadd && !$nsadd->is_empty();
 push @add,build_contact_noregistrant($cadd)        if $cadd;
 push @add,$sadd->build_xml('domain:status','core') if $sadd;
 push @del,build_ns($epp,$nsdel,$domain)            if $nsdel && !$nsdel->is_empty();
 push @del,build_contact_noregistrant($cdel)        if $cdel;
 push @del,$sdel->build_xml('domain:status','core') if $sdel;

 push @d,['domain:add',@add] if @add;
 push @d,['domain:rem',@del] if @del;

 my $chg=$todo->set('registrant');
 my @chg;
 push @chg,['domain:registrant',$chg->srid()] if ($chg && ref($chg) && UNIVERSAL::can($chg,'srid'));
 $chg=$todo->set('auth');
 push @chg,build_authinfo($chg) if ($chg && ref($chg));
 push @d,['domain:chg',@chg] if @chg;

 ## RFC3731 is ambigous
 ## The text says that domain:add domain:rem or domain:chg must be there,
 ## but the XML schema has minOccurs=0 for each of them
 ## The consensus on the mailing-list is that the XML schema is normative
 ## However some server might follow the text, in which case we will need the following lines
 ## which were removed for Net::DRI 0.16
## my $hasext=(grep { ! /^(?:ns|status|contact|registrant|authinfo)$/ } $todo->types())? 1 : 0;
## push @d,['domain:chg'] if ($hasext && !@chg);
 
 $mes->command_body(\@d);
}

####################################################################################################
## RFC3731 �3.2.6  Offline Review of Requested Actions

sub pandata_parse
{
 my ($po,$otype,$oaction,$oname,$rinfo)=@_;
 my $mes=$po->message();
 return unless $mes->is_success();

 my $pandata=$mes->get_content('panData',$mes->ns('domain'));
 return unless $pandata;

 my $c=$pandata->firstChild();
 while ($c)
 {
  my $name=$c->localname() || $c->nodeName();
  next unless $name;

  if ($name eq 'name')
  {
   $oname=lc($c->getFirstChild()->getData());
   $rinfo->{domain}->{$oname}->{action}='create_review';
   $rinfo->{domain}->{$oname}->{result}=Net::DRI::Util::xml_parse_boolean($c->getAttribute('paResult'));
   $rinfo->{domain}->{$oname}->{exist}=$rinfo->{domain}->{$oname}->{result};
  } elsif ($name eq 'paTRID')
  {
   my @tmp=$c->getElementsByTagNameNS($mes->ns('_main'),'clTRID');
   $rinfo->{domain}->{$oname}->{trid}=$tmp[0]->getFirstChild()->getData() if (@tmp && $tmp[0]);
   $rinfo->{domain}->{$oname}->{svtrid}=($c->getElementsByTagNameNS($mes->ns('_main'),'svTRID'))[0]->getFirstChild()->getData();
  } elsif ($name eq 'paDate')
  {
   $rinfo->{domain}->{$oname}->{date}=DateTime::Format::ISO8601->new()->parse_datetime($c->firstChild->getData());
  }
  $c=$c->getNextSibling();
 }
}

####################################################################################################
1;