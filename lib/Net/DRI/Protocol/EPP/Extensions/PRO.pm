## Domain Registry Interface, .PRO EPP extensions
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

package Net::DRI::Protocol::EPP::Extensions::PRO;

use strict;

#use Net::DRI::Data::Contact::PRO;
use base qw/Net::DRI::Protocol::EPP/;

our $VERSION = do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf("%d".".%02d" x $#r, @r); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::PRO - .PRO EPP extensions for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>development@sygroup.chE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt> and
E<lt>http://oss.bsdprojects.net/projects/netdri/E<gt>

=head1 AUTHOR

Tonnerre Lombard E<lt>tonnerre.lombard@sygroup.chE<gt>,
Alexander Biehl E<lt>info@hexonet.netE<gt>, HEXONET Support GmbH,
E<lt>http://www.hexonet.net/E<gt>

=head1 COPYRIGHT

Copyright (c) 2008 Tonnerre Lombard <tonnerre.lombard@sygroup.ch>.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

############################################################################

sub new
{
 my $h = shift;
 my $c = ref($h) || $h;

 my ($drd, $version, $extrah, $defproduct) = @_;
 my %e = map { $_ => 1 } (defined($extrah) ? (ref($extrah) ? @$extrah :
	($extrah)) : ());

 $e{'Net::DRI::Protocol::EPP::Extensions::PRO::Domain'} = 1;
 $e{'Net::DRI::Protocol::EPP::Extensions::PRO::AV'} = 1;
 if (exists($e{':full'})) ## useful shortcut, modeled after Perl itself
 {
  delete($e{':full'});
  $e{'Net::DRI::Protocol::EPP::Extensions::GracePeriod'} = 1;
 }

 ## we are now officially a Net::DRI::Protocol::EPP object
 my $self = $c->SUPER::new($drd, $version, [keys(%e)]);

 # Namespaces
 $self->{ns}->{av} = ['http://registrypro.pro/2003/epp/1/av-2.0', 'av-2.0.xsd'];

 my $rcapa = $self->capabilities();
 $rcapa->{domain_update}->{pro} = ['set'];

 bless($self, $c); ## rebless
 return $self;
}

############################################################################
1;