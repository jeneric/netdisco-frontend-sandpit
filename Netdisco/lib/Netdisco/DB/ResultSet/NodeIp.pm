package Netdisco::DB::ResultSet::NodeIp;
use base 'DBIx::Class::ResultSet';

use strict;
use warnings FATAL => 'all';

# some customize their node_ip table to have a dns column which
# is the cached record at the time of discovery

=head1 has_dns_col

Some sites customize their C<node_ip> table to include a C<dns> field which is
the cached record at the time of node discovery.

This method returns True if the C<node_ip> table is configured with a C<dns>
column.

=cut

sub has_dns_col {
    my $rs = shift;
    return $rs->result_source->has_column('dns');
}

my $search_attr = {
    order_by => {'-desc' => 'time_last'},
    '+columns' => [
      'oui.company',
      { time_first_stamp => \"to_char(time_first, 'YYYY-MM-DD HH24:MI')" },
      { time_last_stamp =>  \"to_char(time_last, 'YYYY-MM-DD HH24:MI')" },
    ],
    join => 'oui'
};

=head1 search_by_ip( \%cond, \%attrs? )

 my $set = $rs->search_by_ip({ip => '192.0.2.1', active => 1});

Like C<search()>, this returns a ResultSet of matching rows from the
NodeIp table.

=over 4

=item *

The C<cond> parameter must be a hashref containing a key C<ip> with the value
to search for. Value can either be a simple string of IPv4 or IPv6, or a
NetAddr::IP object in which case all results within the CIDR/Prefix will be
retrieved.

=item *

Results are ordered by time last seen.

=item *

Additional columns C<time_first_stamp> and C<time_last_stamp> provide
preformatted timestamps of the C<time_first> and C<time_last> fields.

=item *

A JOIN is performed on the OUI table and the OUI C<company> column prefetched.

=back

To limit results only to active IPs, set C<< {active => 1} >> in C<cond>.

=cut

sub search_by_ip {
    my ($rs, $cond, $attrs) = @_;

    die "ip address required for search_by_ip\n"
      if ref {} ne ref $cond or !exists $cond->{ip};

    # handle either plain text IP or NetAddr::IP (/32 or CIDR)
    my ($op, $ip) = ('=', delete $cond->{ip});

    if ('NetAddr::IP::Lite' eq ref $ip and $ip->num > 1) {
        $op = '<<=';
        $ip = $ip->cidr;
    }
    $cond->{ip} = { $op => $ip };

    $rs = $rs->search_rs({}, {'+columns' => 'dns'})
      if $rs->has_dns_col;

    return $rs
      ->search_rs({}, $search_attr)
      ->search($cond, $attrs);
}

=head1 search_by_name( \%cond, \%attrs? )

 my $set = $rs->search_by_name({dns => 'foo.example.com', active => 1});

Like C<search()>, this returns a ResultSet of matching rows from the
NodeIp table.

=over 4

=item *

The NodeIp table must have a C<dns> column for this search to work. Typically
this column is the IP's DNS PTR record, cached at the time of Netdisco Arpnip.

=item *

The C<cond> parameter must be a hashref containing a key C<dns> with the value
to search for. The value may optionally include SQL wildcard characters.

=item *

Results are ordered by time last seen.

=item *

Additional columns C<time_first_stamp> and C<time_last_stamp> provide
preformatted timestamps of the C<time_first> and C<time_last> fields.

=item *

A JOIN is performed on the OUI table and the OUI C<company> column prefetched.

=back

To limit results only to active IPs, set C<< {active => 1} >> in C<cond>.

=cut

sub search_by_dns {
    my ($rs, $cond, $attrs) = @_;

    die "search_by_dns requires a dns col on the node_ip table.\n"
      if not $rs->has_dns_col;

    die "dns field required for search_by_dns\n"
      if ref {} ne ref $cond or !exists $cond->{dns};

    $cond->{dns} = { '-ilike' => delete $cond->{dns} };

    return $rs
      ->search_rs({}, {'+columns' => 'dns'})
      ->search_rs({}, $search_attr)
      ->search($cond, $attrs);
}

=head1 search_by_mac( \%cond, \%attrs? )

 my $set = $rs->search_by_mac({mac => '00:11:22:33:44:55', active => 1});

Like C<search()>, this returns a ResultSet of matching rows from the
NodeIp table.

=over 4

=item *

The C<cond> parameter must be a hashref containing a key C<mac> with the value
to search for.

=item *

Results are ordered by time last seen.

=item *

Additional columns C<time_first_stamp> and C<time_last_stamp> provide
preformatted timestamps of the C<time_first> and C<time_last> fields.

=item *

A JOIN is performed on the OUI table and the OUI C<company> column prefetched.

=back

To limit results only to active IPs, set C<< {active => 1} >> in C<cond>.

=cut

sub search_by_mac {
    my ($rs, $cond, $attrs) = @_;

    die "mac address required for search_by_mac\n"
      if ref {} ne ref $cond or !exists $cond->{mac};

    $rs = $rs->search_rs({}, {'+columns' => 'dns'})
      if $rs->has_dns_col;

    return $rs
      ->search_rs({}, $search_attr)
      ->search($cond, $attrs);
}

1;
