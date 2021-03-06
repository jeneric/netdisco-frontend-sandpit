use utf8;
package Netdisco::DB::Result::UserLog;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->table("user_log");
__PACKAGE__->add_columns(
  "entry",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "user_log_entry_seq",
  },
  "username",
  { data_type => "varchar", is_nullable => 1, size => 50 },
  "userip",
  { data_type => "inet", is_nullable => 1 },
  "event",
  { data_type => "text", is_nullable => 1 },
  "details",
  { data_type => "text", is_nullable => 1 },
  "creation",
  {
    data_type     => "timestamp",
    default_value => \"current_timestamp",
    is_nullable   => 1,
    original      => { default_value => \"now()" },
  },
);


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-01-07 14:20:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:BFrhjYJOhcLIHeWviu9rjw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
