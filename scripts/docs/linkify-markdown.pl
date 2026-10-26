#!/usr/bin/env perl
# Convert in-text file references into relative markdown links.
# Usage: perl scripts/docs/linkify-markdown.pl [--check]
use strict;
use warnings;
use utf8;
use open qw(:std :utf8);
use File::Basename qw(dirname);
use FindBin;
use lib $FindBin::RealBin;
use Getopt::Long qw(GetOptions);
use DocsLib qw(
  closes_fence
  fence_start
  get_repo_files
  get_repo_root
  normpath
  read_file
  relpath
);

my $TOKEN_RE = qr/`([^`\n]+)`/;

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>:encoding(UTF-8)', $path or return 0;
    print {$fh} $content;
    close $fh;
    return 1;
}

sub process_markdown_file {
    my ($md_path, $repo_root, $existing_files, $apply_changes) = @_;
    my $rel_md = relpath($md_path, $repo_root);
    my $md_dir_rel = dirname($rel_md);
    $md_dir_rel = '' if $md_dir_rel eq '.';
    my $md_dir_abs = length $md_dir_rel ? "$repo_root/$md_dir_rel" : $repo_root;

    my $content = read_file($md_path);
    if (!defined $content) {
        print STDERR "$rel_md: failed to read file\n";
        return (0, []);
    }

    my @lines = split /\n/, $content, -1;
    my $fence;
    my @new_lines;
    my @change_summaries;
    my $changes_count = 0;

    for my $line_index (0 .. $#lines) {
        my $line = $lines[$line_index];

        if ($fence) {
            $fence = undef if closes_fence($line, $fence);
            push @new_lines, $line;
            next;
        }

        my $start_fence = fence_start($line);
        if ($start_fence) {
            $fence = $start_fence;
            push @new_lines, $line;
            next;
        }

        my @tokens;
        while ($line =~ /$TOKEN_RE/g) {
            push @tokens, { token => $1, start => $-[0], end => $+[0] };
        }

        my @replacements;
        for my $match (@tokens) {
            my $token = $match->{token};
            $token =~ s/^\s+//;
            $token =~ s/\s+$//;
            my ($start, $end) = ($match->{start}, $match->{end});

            next
              if $start > 0
              && substr($line, $start - 1, 1) eq '['
              && $end < length($line)
              && substr($line, $end, 2) eq '](';
            next if $start >= 2 && substr($line, $start - 2, 2) eq '](';

            my $left  = substr($line, 0, $start);
            my $right = substr($line, $end);
            if (index($left, '[') >= 0 && index($right, '](') >= 0) {
                my $last_open  = rindex($left, '[');
                my $last_close = rindex($left, ']');
                next if $last_open > $last_close;
            }

            next if $token eq 'README.md'
              && index($left, 'サブディレクトリ') >= 0;

            my $target_rel_to_repo;
            if ($existing_files->{$token}) {
                $target_rel_to_repo = $token;
            }
            else {
                my $candidate = normpath(
                    length $md_dir_rel ? "$md_dir_rel/$token" : $token);
                $target_rel_to_repo = $candidate
                  if $existing_files->{$candidate};
            }
            next unless defined $target_rel_to_repo;

            my $target_abs = "$repo_root/$target_rel_to_repo";
            next unless -f $target_abs;

            my $rel_link = relpath($target_abs, $md_dir_abs);
            push @replacements, {
                start => $start,
                end   => $end,
                text  => "[$token]($rel_link)",
                token => $token,
                link  => $rel_link,
            };
        }

        if (@replacements) {
            $changes_count += scalar @replacements;
            my $current = $line;
            for my $replacement (reverse @replacements) {
                $current =
                    substr($current, 0, $replacement->{start})
                  . $replacement->{text}
                  . substr($current, $replacement->{end});
                push @change_summaries, "$rel_md:" . ($line_index + 1)
                  . " `$replacement->{token}` -> $replacement->{link}";
            }
            push @new_lines, $current;
        }
        else {
            push @new_lines, $line;
        }
    }

    if ($apply_changes && $changes_count > 0) {
        write_file($md_path, join "\n", @new_lines);
    }

    return ($changes_count, \@change_summaries);
}

sub main {
    my ($check_only, $help);
    my $options_ok = GetOptions(
        'check'   => \$check_only,
        'help|h'  => \$help,
    );
    if (!$options_ok) {
        print STDERR
"Usage: perl scripts/docs/linkify-markdown.pl [--check]\n";
        return 2;
    }
    if ($help) {
        print
"Usage: perl scripts/docs/linkify-markdown.pl [--check]\n\nConvert in-text file references to relative markdown links.\n";
        return 0;
    }

    my $repo_root = get_repo_root();
    my @all_files = get_repo_files($repo_root);
    my %existing_files = map { $_ => 1 } @all_files;
    my @md_files =
      sort map { "$repo_root/$_" } grep { /\.md$/ } @all_files;

    my $total_changes = 0;
    my @all_summaries;

    for my $md_path (@md_files) {
        my ($count, $summaries) =
          process_markdown_file($md_path, $repo_root, \%existing_files,
            !$check_only);
        $total_changes += $count;
        push @all_summaries, @$summaries;
    }

    if ($total_changes > 0) {
        if ($check_only) {
            print
"Found $total_changes unlinked file references in markdown documents:\n";
            my $shown = 0;
            for my $summary (@all_summaries) {
                last if $shown >= 20;
                print "  $summary\n";
                $shown++;
            }
            if (@all_summaries > 20) {
                my $remaining = @all_summaries - 20;
                print "  ... and $remaining more.\n";
            }
            print
"\nRun 'perl scripts/docs/linkify-markdown.pl' to convert them automatically.\n";
            return 1;
        }
        print
"Successfully linked $total_changes file references across markdown documents.\n";
        return 0;
    }

    print "All file references in markdown documents are properly linked.\n";
    return 0;
}

exit main();
