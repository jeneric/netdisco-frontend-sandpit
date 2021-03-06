package Netdisco::DB::ResultSet::Device;
use base 'DBIx::Class::ResultSet';

use strict;
use warnings FATAL => 'all';
use NetAddr::IP::Lite ':lower';

=head1 ADDITIONAL METHODS

=head2 with_times

This is a modifier for any C<search()> (including the helpers below) which
will add the following additional synthesized columns to the result set:

=over 4

=item uptime_age

=item last_discover_stamp

=item last_macsuck_stamp

=item last_arpnip_stamp

=back

=cut

sub with_times {
  my ($rs, $cond, $attrs) = @_;

  return $rs
    ->search_rs($cond, $attrs)
    ->search({},
      {
        '+columns' => {
          uptime_age => \("replace(age(timestamp 'epoch' + uptime / 100 * interval '1 second', "
            ."timestamp '1970-01-01 00:00:00-00')::text, 'mon', 'month')"),
          last_discover_stamp => \"to_char(last_discover, 'YYYY-MM-DD HH24:MI')",
          last_macsuck_stamp => \"to_char(last_macsuck,  'YYYY-MM-DD HH24:MI')",
          last_arpnip_stamp => \"to_char(last_arpnip,   'YYYY-MM-DD HH24:MI')",
        },
      });
}

=head2 search_by_field( \%cond, \%attrs? )

This variant of the standard C<search()> method returns a ResultSet of Device
entries. It is written to support web forms which accept fields that match and
locate Devices in the database.

The hashref parameter should contain fields from the Device table which will
be intelligently used in a search query.

In addition, you can provide the key C<matchall> which, given a True or False
value, controls whether fields must all match or whether any can match, to
select a row.

Supported keys:

=over 4

=item matchall

If a True value, fields must all match to return a given row of the Device
table, otherwise any field matching will cause the row to be included in
results.

=item name

Can match the C<name> field as a substring.

=item location

Can match the C<location> field as a substring.

=item description

Can match the C<description> field as a substring (usually this field contains
a description of the vendor operating system).

=item model

Will match exactly the C<model> field.

=item os_ver

Will match exactly the C<os_ver> field, which is the operating sytem software version.

=item vendor

Will match exactly the C<vendor> (manufacturer).

=item dns

Can match any of the Device IP address aliases as a substring.

=item ip

Can be a string IP or a NetAddr::IP object, either way being treated as an
IPv4 or IPv6 prefix within which the device must have one IP address alias.

=back

=cut

sub search_by_field {
    my ($rs, $p, $attrs) = @_;

    die "condition parameter to search_by_field must be hashref\n"
      if ref {} ne ref $p or 0 == scalar keys %$p;

    my $op = $p->{matchall} ? '-and' : '-or';

    # this is a bit of an inelegant trick to catch junk data entry,
    # whilst avoiding returning *all* entries in the table
    if (length $p->{ip} and 'NetAddr::IP::Lite' ne ref $p->{ip}) {
      $p->{ip} = ( NetAddr::IP::Lite->new($p->{ip})
        || NetAddr::IP::Lite->new('255.255.255.255') );
    }

    return $rs
      ->search_rs({}, $attrs)
      ->search({
        $op => [
          ($p->{name} ? ('me.name' =>
            { '-ilike' => "\%$p->{name}\%" }) : ()),
          ($p->{location} ? ('me.location' =>
            { '-ilike' => "\%$p->{location}\%" }) : ()),
          ($p->{description} ? ('me.description' =>
            { '-ilike' => "\%$p->{description}\%" }) : ()),

          ($p->{model} ? ('me.model' =>
            { '-in' => $p->{model} }) : ()),
          ($p->{os_ver} ? ('me.os_ver' =>
            { '-in' => $p->{os_ver} }) : ()),
          ($p->{vendor} ? ('me.vendor' =>
            { '-in' => $p->{vendor} }) : ()),

          ($p->{dns} ? (
            -or => [
              'me.dns' => { '-ilike' => "\%$p->{dns}\%" },
              'device_ips.dns' => { '-ilike' => "\%$p->{dns}\%" },
            ]) : ()),

          ($p->{ip} ? (
            -or => [
              'me.ip' => { '<<=' => $p->{ip}->cidr },
              'device_ips.alias' => { '<<=' => $p->{ip}->cidr },
            ]) : ()),
        ],
      },
      {
        order_by => [qw/ me.dns me.ip /],
        (($p->{dns} or $p->{ip}) ? (
          join => 'device_ips',
          distinct => 1,
        ) : ()),
      }
    );
}

=head2 search_fuzzy( $value )

This method accepts a single parameter only and returns a ResultSet of rows
from the Device table where one field matches the passed parameter.

The following fields are inspected for a match:

=over 4

=item contact

=item serial

=item location

=item name

=item description

=item dns

=item ip (including aliases)

=back

=cut

sub search_fuzzy {
    my ($rs, $q) = @_;

    die "missing param to search_fuzzy\n"
      unless $q;
    $q = "\%$q\%" if $q !~ m/\%/;

    # basic IP check is a string match
    my $ip_clause = [
        'me.ip::text'  => { '-ilike' => $q },
        'device_ips.alias::text' => { '-ilike' => $q },
    ];

    # but also allow prefix search
    (my $qc = $q) =~ s/\%//g;
    if (my $ip = NetAddr::IP::Lite->new($qc)) {
        $ip_clause = [
            'me.ip'  => { '<<=' => $ip->cidr },
            'device_ips.alias' => { '<<=' => $ip->cidr },
        ];
    }

    return $rs->search(
      {
        -or => [
          'me.contact'  => { '-ilike' => $q },
          'me.serial'   => { '-ilike' => $q },
          'me.location' => { '-ilike' => $q },
          'me.name'     => { '-ilike' => $q },
          'me.description' => { '-ilike' => $q },
          -or => [
            'me.dns'      => { '-ilike' => $q },
            'device_ips.dns' => { '-ilike' => $q },
          ],
          -or => $ip_clause,
        ],
      },
      {
        order_by => [qw/ me.dns me.ip /],
        join => 'device_ips',
        distinct => 1,
      }
    );
}

=head2 carrying_vlan( \%cond, \%attrs? )

 my $set = $rs->carrying_vlan({ vlan => 123 });

Like C<search()>, this returns a ResultSet of matching rows from the Device
table.

The returned devices each are aware of the given Vlan and have at least one
Port configured in the Vlan (either tagged, or not).

=over 4

=item *

The C<cond> parameter must be a hashref containing a key C<vlan> with
the value to search for.

=item *

Results are ordered by the Device DNS and IP fields.

=item *

Related rows from the C<device_vlan> table will be prefetched.

=back

=cut

sub carrying_vlan {
    my ($rs, $cond, $attrs) = @_;

    die "vlan number required for carrying_vlan\n"
      if ref {} ne ref $cond or !exists $cond->{vlan};

    $cond->{'vlans.vlan'} = $cond->{vlan};
    $cond->{'port_vlans.vlan'} = delete $cond->{vlan};

    return $rs
      ->search_rs($cond,
        {
          order_by => [qw/ me.dns me.ip /],
          columns => [qw/ me.ip me.dns me.model me.os me.vendor /],
          join => 'port_vlans',
          prefetch => 'vlans',
        })
      ->search({}, $attrs);
}

=head2 carrying_vlan_name( \%cond, \%attrs? )

 my $set = $rs->carrying_vlan_name({ name => 'Branch Office' });

Like C<search()>, this returns a ResultSet of matching rows from the Device
table.

The returned devices each are aware of the named Vlan and have at least one
Port configured in the Vlan (either tagged, or not).

=over 4

=item *

The C<cond> parameter must be a hashref containing a key C<name> with
the value to search for. The value may optionally include SQL wildcard
characters.

=item *

Results are ordered by the Device DNS and IP fields.

=item *

Related rows from the C<device_vlan> table will be prefetched.

=back

=cut

sub carrying_vlan_name {
    my ($rs, $cond, $attrs) = @_;

    die "vlan name required for carrying_vlan_name\n"
      if ref {} ne ref $cond or !exists $cond->{name};

    $cond->{'vlans.description'} = { '-ilike' => $cond->{name} };

    return $rs
      ->search_rs({}, {
        order_by => [qw/ me.dns me.ip /],
        columns => [qw/ me.ip me.dns me.model me.os me.vendor /],
        prefetch => 'vlans',
      })
      ->search($cond, $attrs);
}

=head2 get_distinct( $column )

Returns an asciibetical sorted list of the distinct values in the given column
of the Device table. This is useful for web forms when you want to provide a
drop-down list of possible options.

=cut

sub get_distinct {
  my ($rs, $col) = @_;
  return $rs unless $col;

  return $rs->search({},
    {
      columns => [$col],
      order_by => $col,
      distinct => 1
    }
  )->get_column($col)->all;
}

1;
