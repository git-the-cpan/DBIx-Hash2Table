package DBIx::Hash2Table;

# Name:
#	DBIx::Hash2Table.
#
# Documentation:
#	POD-style documentation is at the end. Extract it with pod2html.*.
#
# Reference:
#	Object Oriented Perl
#	Damian Conway
#	Manning
#	1-884777-79-1
#	P 114
#
# Note:
#	o Tab = 4 spaces || die.
#
# Author:
#	Ron Savage <ron@savage.net.au>
#	Home page: http://savage.net.au/index.html
#
# Licence:
#	Australian copyright (c) 1999-2002 Ron Savage.
#
#	All Programs of mine are 'OSI Certified Open Source Software';
#	you can redistribute them and/or modify them under the terms of
#	The Artistic License, a copy of which is available at:
#	http://www.opensource.org/licenses/index.html

use strict;
use warnings;

use CGI;

require 5.005_62;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use DBIx::Hash2Table ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);
our $VERSION = '1.00';

# -----------------------------------------------

# Preloaded methods go here.

# -----------------------------------------------

# Encapsulated class data.

{
	my(%_attr_data) =
	(
		_columns	=> '',
		_dbh		=> '',
		_hash_ref	=> '',
		_table_name	=> '',
	);

	sub _default_for
	{
		my($self, $attr_name) = @_;

		$_attr_data{$attr_name};
	}

	sub _save
	{
		my($self, $sth, $hash_ref, $parent) = @_;

		my(@bind, @sub_key);

		for my $key (keys %$hash_ref)
		{
			# If we have a hash ref, which we almost always do have...

			if (ref($$hash_ref{$key}) eq 'HASH')
			{
				$$self{'_id'}++;

				@bind = ($$self{'_id'}, $parent, $key);

				# Then, get it's keys...

				@sub_key = keys %{$$hash_ref{$key} };

				# And see if the caller wants any of them written to the db.
				# Warning: The caller must set up columns => [...] correctly.
				# That is, the column order must match the SQL insert statement below.
				# We can't sort columns => [...] because then we would lose the fact
				# that the first 3 column names are special.

				for (sort @sub_key)
				{
					push(@bind, $$hash_ref{$key}{$_}) if ($$self{'_sub_keys'}{$_});
				}

				push(@bind, undef) while (@bind < @{$$self{'_columns'} });

				$sth -> execute(@bind);

				# Curse again. (Aka 'recurse', for non-native speakers of English.)

				$self -> _save($sth, $$hash_ref{$key}, $$self{'_id'});
			}
		}

	}	# End of _save.

	sub _standard_keys
	{
		keys %_attr_data;
	}
}

# -----------------------------------------------

sub insert
{
	my($self)		= @_;
	my($sql)		= "insert into $$self{'_table_name'} (" . join(', ', @{$$self{'_columns'} }) . ') values (' . join(', ', ('?') x @{$$self{'_columns'} }) . ')';
	my($sth)		= $$self{'_dbh'} -> prepare($sql);
	$$self{'_id'}	= 0;
	my(@other_keys)	= @{$$self{'_columns'} };

	shift @other_keys; # Discard id.
	shift @other_keys; # Discard name.
	shift @other_keys; # Discard parent_id.

	# Convert array other_keys into hash ref _sub_keys
	# so sub _save can easily look up any keys it comes across.

	$$self{'_sub_keys'}						= {};
	@{$$self{'_sub_keys'} }{@other_keys}	= (1) x @other_keys;

	$self -> _save($sth, $$self{'_hash_ref'}, 0);

}	# End of insert.

# -----------------------------------------------

sub new
{
	my($caller, %arg)		= @_;
	my($caller_is_obj)		= ref($caller);
	my($class)				= $caller_is_obj || $caller;
	my($self)				= bless({}, $class);

	for my $attr_name ($self -> _standard_keys() )
	{
		my($arg_name) = $attr_name =~ /^_(.*)/;

		if (exists($arg{$arg_name}) )
		{
			$$self{$attr_name} = $arg{$arg_name};
		}
		elsif ($caller_is_obj)
		{
			$$self{$attr_name} = $$caller{$attr_name};
		}
		else
		{
			$$self{$attr_name} = $self -> _default_for($attr_name);
		}
	}

	croak(__PACKAGE__ . '. You must supply a value for each parameter')
		if (! ($$self{'_columns'} && $$self{'_dbh'} && $$self{'_hash_ref'} && $$self{'_table_name'}) );

	return $self;

}	# End of new.

# -----------------------------------------------

1;

__END__

=head1 NAME

C<DBIx::Hash2Table> - Save a hash into a database table

=head1 Version

This document refers to version 1.00 of C<DBIx::Hash2Table>, released 8-Jan-2003.

=head1 Synopsis

	#!/usr/bin/perl

	my(%entity)     = create_a_hash(...);
	my($dbh)        = DBI -> connect(...);
	my($table_name) = 'entity';

	# Cope with MySQL-specific SQL.
	eval{$dbh -> do("drop table if exists $table_name")};

	# Cope with non-existant table.
	eval{$dbh -> do("drop table $table_name")};

	my($sql) = "create table $table_name (id int, parent_id int, " .
				"code char(5), name varchar(255) )";

	$dbh -> do($sql);

	DBIx::Hash2Table -> new
	(
		hash_ref   => \%entity,
		dbh        => $dbh,
		table_name => $table_name,
#		columns    => ['id', 'parent_id', 'name'] # or
		columns    => ['id', 'parent_id', 'name', 'code']
	) -> insert();

=head1 Description

C<DBIx::Hash2Table> is a pure Perl module.

This module saves a hash into an existing database table of at least 3 columns.

I suggest you display the script examples/hash2table.pl in another window while reading the following.

In fact, you are I<strongly> recommended to run the demo now, and examine the resultant database table, before reading
further. Then, move the comment # up from line 72 to 71 and run it again.

Hash keys normally point to hash refs. This nested structure is preserved when the data is written to the table.

That is, when a hash key points to a hash ref, the hash key is written to the table. The module keeps track of the
row in the table containing the parent of the 'current' hash key, and the parent's id (row number) is written to the
'current' row of the table.

Inside the hash ref you can have hash keys which are column names, or you can have hash keys which are 'normal'
hash keys.

If the nested hash key is a column name, then it should point to a non-ref, ie a number or a string. In that case,
you can optionally have the value it points to written to the table. In the example code, such a nested hash key is
called code, and at lines 71 .. 72 you can control whether or not the code values are written to the table.

If the nested hash key is not a column name, then it should point to a hash ref, and when its turn comes, it too
will be written to the table.

So, each row in the table will consist of these 3 columns, at least: id (row number), parent's id, and hash key.

In more detail, the 3 columns are:

=over 4

=item *

An id column

This column is for the unique id of the row containing the hash key.

You do not have to define this column of the table to be unique, or to be a database key, but that might be a Good Idea.

C<DBIx::Hash2Table> counts an integer up from 1, to generate the values for this column.

=item *

The parent's id column

This column is for the non-unique id of the row of the parent of the hash key.

=item *

A name column

This column is for the hash key itself.

=back

=head1 Constructor and initialization

new(...) returns a C<DBIx::Hash2Table> object.

This is the class's contructor.

Parameters:

=over 4

=item *

hash_ref

A reference to the hash to be inserted in the table.

=item *

dbh

This is a database handle.

=item *

table_name

This is the name of the table to populate.

=item *

columns

This is an array ref of column names.

Warning: The order of entries in this array ref is of great significance. Of course, just because the column
names must be in this order does not mean the table itself must be declared with the columns in the same order.

=over 4

=item *

Index 0

This is the column name used for the id column.

=item *

Index 1

This is the column name used for the id of the parent of the hash key.

The root key(s) of the hash will have a parent id of 0.

=item *

Index 2

This is the column name used for the hash key itself.

=item *

Indexes 3 .. N (optional)

Any other column names must be hash keys which satisfy these conditions:

=over 4

=item *

The column names 3 .. N are sorted alphabetically

See below.

=item *

It's a column name

The hash key is actually the name of a column in the table.

=item *

It's a child

The hash key is a child of the 'current' hash key.

=item *

It's value is a constant

It's value is a non-ref, ie a number or a string.

=item *

Save me!

You want the hash key's value to be written to the 'current' row of the table.

In other words, even though this hash key (which is a column name!) is a child of the 'current' hash key, the
value pointed to by this hash key is written to the same row has the 'current' hash key.

=back

The program examples/hash2table.pl shows exactly what this means.

Warning: The names of these columns 3 .. N must be sorted alphabetically. That's the only way the module can know how
to bind the values associated with these columns into their correct places in the SQL insert statement.

=back

=back

=head1 Method: new(...)

Returns an object of type C<DBIx::Hash2Table>.

See above, in the section called 'Constructor and initialization'.

=head1 Method: insert()

Returns nothing.

Calling insert() actually executes the SQL insert statement, and recursively writes all hash keys to the table.

=head1 Required Modules

DBI, since you must provide a database handle.

=head1 Changes

See Changes.txt.

=head1 FAQ

Q: What is the point of this module?

A: To be able to save a hash to permanent storage via a database rather than via a file.

Q: Can your other module C<DBIx::Table2Hash> reconstruct a hash written by this module?

A: No. Sorry. Perhaps one day.

=head1 Author

C<DBIx::Hash2Table> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2003.

Home page: http://savage.net.au/index.html

=head1 Copyright

Australian copyright (c) 2003, Ron Savage. All rights reserved.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut