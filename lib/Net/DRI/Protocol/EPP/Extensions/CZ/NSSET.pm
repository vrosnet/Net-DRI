## Domain Registry Interface, .CZ EPP NSSET extension commands
##
## Copyright (c) 2008 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
##                    All rights reserved.
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

package Net::DRI::Protocol::EPP::Extensions::CZ::NSSET;

use strict;

use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Data::Hosts;

our $VERSION=do { my @r=(q$Revision: 1.5 $=~/\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::CZ::NSSET - EPP NSSET extension commands for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>development@sygroup.chE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://oss.bsdprojects.net/projects/netdri/E<gt>

=head1 AUTHOR

Tonnerre Lombard, E<lt>tonnerre.lombard@sygroup.chE<gt>

=head1 COPYRIGHT

Copyright (c) 2008 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
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
	my ($class, $version) = @_;
	my %tmp1 = (
		create => [ \&create ],
		check  => [ \&check, \&check_parse ],
		info   => [ \&info, \&info_parse ],
		delete => [ \&delete ],
		update => [ \&update ],
		transfer_query => [ \&transfer_query ],
		transfer_request => [ \&transfer_request ],
		transfer_cancel => [ \&transfer_cancel ],
		transfer_answer => [ \&transfer_answer ],
	);

	$tmp1{check_multi} = $tmp1{check};
 
	return { 'nsset' => \%tmp1 };
}

sub capabilities_add
{
	return { 'nsset_update' => {
		'ns' =>			['add', 'del'],
		'contact' =>		['add', 'del'],
		'auth' =>		['set'],
		'reportlevel' =>	['set']
	} };
}

sub ns
{
	my ($mes) = @_;
	return (exists($mes->ns->{nsset})) ? $mes->ns->{nsset}->[0] :
		'http://www.nic.cz/xml/epp/nsset-1.2';
}

sub verify_rd
{
	my ($rd, $key) = @_;
	return 0 unless (defined($key) && $key);
	return 0 unless (defined($rd) && (ref($rd) eq 'HASH') &&
		exists($rd->{$key}) &&defined($rd->{$key}));
	return 1;
}

sub build_command
{
	my ($epp, $msg, $command, $hosts) = @_;
	my $tcommand = (ref($command) eq 'ARRAY' ? $command->[0] : $command);

	my @gn;

	foreach my $h (grep { defined } (ref($hosts) eq 'ARRAY') ?
		@$hosts : ($hosts))
	{
		my $gn = UNIVERSAL::isa($h,'Net::DRI::Data::Hosts') ?
			$h->name() : $h;
		Net::DRI::Exception->die(1, 'protocol/EPP', 10,
			'Invalid NSgroup name: ' . $gn)
			unless ($gn && Net::DRI::Util::xml_is_normalizedstring(
				$gn, 1, 100));
		push(@gn, $gn);
	}

	Net::DRI::Exception->die(1, 'protocol/EPP', 2, 'NSgroup name needed')
		unless @gn;

	my @ns = exists($msg->ns->{nsset}) ? @{$msg->ns->{nsset}} :
		('http://www.nic.cz/xml/epp/nsset-1.2', 'nsset-1.2.xsd');
	$msg->command([$command, 'nsset:' . $tcommand,
		sprintf('xmlns:nsset="%s" xsi:schemaLocation="%s %s"',
			$ns[0], $ns[0], $ns[1])]);

	return map { ['nsset:id', $_] } @gn;
}

sub add_nsname
{
	my ($ns) = @_;
	return () unless (defined($ns));
	my @a;

	if (!ref($ns))
	{
		return ['nsset:ns', ['nsset:name', $ns]];
	}
	elsif (ref($ns) eq 'ARRAY')
	{
		return ['nsset:ns', map { ['nsset:name', $_] } @$ns];
	}
	elsif (UNIVERSAL::isa($ns, 'Net::DRI::Data::Hosts'))
	{
		for (my $i = 1; $i <= $ns->count(); $i++)
		{
			my ($name, $v4, $v6) = $ns->get_details($i);
			my @b;
			push(@b, ['nsset:name', $name]);
			foreach my $addr (@{$v4}, @{$v6})
			{
				push(@b, ['nsset:addr', $addr]);
			}
			push(@a, ['nsset:ns', @b]);
		}
	}

	return @a;
}

sub build_contacts
{
	my ($cs) = @_;
	return () unless (defined($cs));
	my @a;

	foreach my $type ($cs->types())
	{
		push(@a, map { ['nsset:' . $type, $_->srid()] }
			$cs->get($type));
	}

	return @a;
}

sub build_authinfo
{
	my $rauth = shift;
	return unless (defined($rauth) && ref($rauth) eq 'HASH');
	return ['nsset:authInfo', $rauth->{pw}];
}

sub build_reportlevel
{
	my $level = int(shift);
	return unless (defined($level) && $level >= 0 && $level <= 10);
	return ['nsset:reportlevel', $level];
}

####################################################################################################
########### Query commands

sub check
{
	my $epp = shift;
	my @hosts = @_;
	my $mes = $epp->message();
	my @d = build_command($epp, $mes, 'check', \@hosts);

	$mes->command_body(\@d);
}

sub check_parse
{
	my ($po, $otype, $oaction, $oname, $rinfo) = @_;
	my $mes = $po->message();
	return unless $mes->is_success();

	my $ns = ns($mes);
	my $chkdata = $mes->get_content('chkData', $ns);
	return unless $chkdata;

	foreach my $cd ($chkdata->getElementsByTagNameNS($ns, 'cd'))
	{
		my $c = $cd->getFirstChild();
		my $nsset;
		while ($c)
		{
			## only for element nodes
			next unless ($c->nodeType() == 1);
			my $n = $c->localname() || $c->nodeName();
			if ($n eq 'id')
			{
				$nsset = $c->getFirstChild()->getData();
				$rinfo->{nsset}->{$nsset}->{exist} =
					1 - Net::DRI::Util::xml_parse_boolean
						($c->getAttribute('avail'));
				$rinfo->{nsset}->{$nsset}->{action} =
					'check';
			}
		} continue { $c = $c->getNextSibling(); }
	}
}

sub info
{
	my ($epp, $hosts) = @_;
	my $mes = $epp->message();
	my @d = build_command($epp, $mes, 'info', $hosts);

	$mes->command_body(\@d);
}

sub info_parse
{
	my ($po, $otype, $oaction, $oname, $rinfo) = @_;
	my $mes = $po->message();
	return unless $mes->is_success();

	my $infdata = $mes->get_content('infData', ns($mes));
	return unless $infdata;

	my $ns = Net::DRI::Data::Hosts->new();

	my $c = $infdata->getFirstChild();

	while ($c)
	{
		next unless ($c->nodeType() == 1); ## only for element nodes
		my $name = $c->localname() || $c->nodeName();
		next unless $name;
		if ($name eq 'name')
		{
			$oname = $c->getFirstChild()->getData();
			$ns->name($oname);
			$rinfo->{nsset}->{$oname}->{exist} = 1;
			$rinfo->{nsset}->{$oname}->{action} = 'info';
		}
		elsif ($name eq 'ns')
		{
			$ns->add($c->getFirstChild()->getData());
		}
	} continue { $c = $c->getNextSibling(); }

	$rinfo->{nsset}->{$oname}->{self} = $ns;
}

sub transfer_query
{
	my ($epp, $name, $rd) = @_;
	my $mes = $epp->message();
	my @d = build_command($epp, $mes, ['transfer', {'op' => 'query'}],
		$name);
	push(@d, build_authinfo($rd->{auth})) if (verify_rd($rd,'auth') &&
		(ref($rd->{auth}) eq 'HASH'));
	$mes->command_body(\@d);
}

############ Transform commands

sub create
{
	my ($epp, $name, $rd) = @_;
	my $mes = $epp->message();
	my @d = build_command($epp, $mes, 'create', $name);
	my $hosts = $rd->{ns};
	my $cs = $rd->{contact};

	push(@d, add_nsname($hosts));
	push(@d, build_contacts($cs));
	push(@d, build_authinfo($rd->{auth}));
	push(@d, build_reportlevel($rd->{reportlevel}));
	$mes->command_body(\@d);
}

sub delete
{
	my ($epp, $hosts) = @_;
	my $mes = $epp->message();
	my @d = build_command($epp, $mes, 'delete', $hosts);

	$mes->command_body(\@d);
}

sub transfer_request
{
	my ($epp, $name, $rd) = @_;
	my $mes = $epp->message();
	my @d = build_command($epp, $mes, ['transfer', {'op' => 'request'}],
		$name);

	push(@d, build_authinfo($rd->{auth})) if (verify_rd($rd, 'auth') &&
		(ref($rd->{auth}) eq 'HASH'));
	$mes->command_body(\@d);
}

sub transfer_answer
{
	my ($epp, $name, $rd) = @_;
	my $mes = $epp->message();
	my @d = build_command($epp, $mes, ['transfer',
		{'op' => (verify_rd($rd, 'approve') && $rd->{approve} ?
			'approve' : 'reject')}], $name);

	push(@d, build_authinfo($rd->{auth})) if (verify_rd($rd, 'auth') &&
		(ref($rd->{auth}) eq 'HASH'));
	$mes->command_body(\@d);
}

sub transfer_cancel
{
	my ($epp, $name, $rd) = @_;
	my $mes = $epp->message();
	my @d = build_command($epp, $mes, ['transfer', {'op' => 'cancel'}],
		$name);

	push(@d, build_authinfo($rd->{auth})) if (verify_rd($rd, 'auth') &&
		(ref($rd->{auth}) eq 'HASH'));
	$mes->command_body(\@d);
}

sub update
{
	my ($epp, $hosts, $todo) = @_;
	my $mes = $epp->message();

	Net::DRI::Exception::usererr_invalid_parameters($todo .
		' must be a Net::DRI::Data::Changes object')
		unless ($todo && UNIVERSAL::isa($todo,
			'Net::DRI::Data::Changes'));

	if ((grep { ! /^(?:ns|contact|auth|reportlevel)$/ } $todo->types()))
	{
		Net::DRI::Exception->die(0, 'protocol/EPP', 11,
			'Only ns/contact add/del and auth/reportlevel set ' .
			'available for nsset');
	}

	my @d = build_command($epp, $mes, 'update', $hosts);

	my $nsadd = $todo->add('ns');
	my $nsdel = $todo->del('ns');
	my $cadd = $todo->add('contact');
	my $cdel = $todo->del('contact');
	my $auth = $todo->set('auth');
	my $level = $todo->set('reportlevel');

	my (@add, @del, @set);
	push(@add, add_nsname($nsadd)) if ($nsadd && !$nsadd->is_empty());
	push(@add, build_contacts($cadd)) if ($cadd);

	push(@del, map { ['nsset:name', $_] } $nsdel->get_names())
		if ($nsdel && !$nsdel->is_empty());
	push(@del, build_contacts($cdel)) if ($cdel);

	push(@set, ['nsset:authInfo', $auth->{pw}])
		if (defined($auth) && verify_rd($auth, 'pw'));
	push(@set, build_reportlevel($level)) if (defined($level));

	push(@d, ['nsset:add', @add]) if (@add);
	push(@d, ['nsset:rem', @del]) if (@del);
	push(@d, ['nsset:chg', @set]) if (@set);

	$mes->command_body(\@d);
}

####################################################################################################
1;