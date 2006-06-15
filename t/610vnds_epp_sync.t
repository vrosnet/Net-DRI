#!/usr/bin/perl -w

use Net::DRI;
use Net::DRI::Data::Raw;

use Test::More tests => 1;

our $E1='<?xml version="1.0" encoding="UTF-8" standalone="no"?><epp xmlns="urn:ietf:params:xml:ns:epp-1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0 epp-1.0.xsd">';
our $E2='</epp>';
our $TRID='<trID><clTRID>ABC-12345</clTRID><svTRID>54322-XYZ</svTRID></trID>';

our $R1;
sub mysend
{
 my ($transport,$count,$msg)=@_;
 $R1=$msg->as_string();
 return 1;
}

our $R2;
sub myrecv
{
 return Net::DRI::Data::Raw->new_from_string($R2? $R2 : $E1.'<response>'.r().$TRID.'</response>'.$E2);
}

my $dri=Net::DRI->new(10);
$dri->{trid_factory}=sub { return 'ABC-12345'; };
$dri->add_registry('VNDS');
$dri->target('VNDS')->new_current_profile('p1','Net::DRI::Transport::Dummy',[{f_send=>\&mysend,f_recv=>\&myrecv}],'Net::DRI::Protocol::EPP',['1.0',['Net::DRI::Protocol::EPP::Extensions::VeriSign::Sync']]);

#########################################################################################################
## Example taken from draft-hollenbeck-epp-sync-01, updated (removed empty <domain:chg/>

my $toc=$dri->local_object('changes');
$toc->set('sync','05-31');
my $rc=$dri->domain_update('example2.com',$toc);
is($R1,$E1.'<command><update><domain:update xmlns:domain="urn:ietf:params:xml:ns:domain-1.0" xsi:schemaLocation="urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd"><domain:name>example2.com</domain:name><domain:chg/></domain:update></update><extension><sync:update xmlns:sync="http://www.verisign.com/epp/sync-1.0" xsi:schemaLocation="http://www.verisign.com/epp/sync-1.0 sync-1.0.xsd"><sync:expMonthDay>--05-31</sync:expMonthDay></sync:update></extension><clTRID>ABC-12345</clTRID></command>'.$E2,'domain_update build');

exit 0;

sub r
{
 my ($c,$m)=@_;
 return '<result code="'.($c || 1000).'"><msg>'.($m || 'Command completed successfully').'</msg></result>';
}
