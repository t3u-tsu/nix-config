#!/usr/bin/env perl
# Convert in-text file references into relative markdown links.
# Usage: perl scripts/docs/linkify-markdown.pl [--check]
use strict;
use warnings;
use utf8;
use open qw(:std :utf8);
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Spec;
use Getopt::Long qw(GetOptions);

my $TOKEN_RE = qr/`([^`\n]+)`/;

sub get_repo_root {
    my $script = __FILE__;
    my $abs    = File::Spec->file_name_is_absolute($script)
      ? $script
      : File::Spec->rel2abs($script);
    my $dir      = dirname($abs);
    my $resolved = abs_path($dir);
    return defined $resolved ? dirname($resolved) : dirname($abs);
}

sub read_file {
    my ($path) = @_;
    open my $fh, '<:encoding(UTF-8)', $path or return undef;
    my $content = do {
        local $/;
        local $SIG{__WARN__} = sub { };
        <$fh>;
    };
    close $fh;
    return defined $content ? $content : '';
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, '>:encoding(UTF-8)', $path or return 0;
    print {$fh} $content;
    close $fh;
    return 1;
}

sub normpath {
    my ($path) = @_;
    return '.' if !defined $path || $path eq '';
    my $absolute = $path =~ m{^/} ? 1 : 0;
    my @parts;
    for my $component (split m{/+}, $path) {
        next if $component eq '' || $component eq '.';
        if ($component eq '..') {
            if (@parts && $parts[-1] ne '..') { pop @parts }
            elsif (!$absolute)               { push @parts, '..' }
            next;
        }
        push @parts, $component;
    }
    my $joined = join '/', @parts;
    if ($absolute) { return "/$joined" }
    return $joined eq '' ? '.' : $joined;
}

sub relpath {
    my ($target, $base) = @_;
    $target = normpath($target);
    $base   = normpath($base);
    return $target if $target eq $base;

    my $prefix = $base eq '/' ? '/' : "$base/";
    return substr($target, length $prefix) if index($target, $prefix) == 0;

    my @target_parts = split m{/}, $target;
    my @base_parts   = split m{/}, $base;
    shift @target_parts if @target_parts && $target_parts[0] eq '';
    shift @base_parts   if @base_parts   && $base_parts[0]   eq '';
    while (@target_parts && @base_parts && $target_parts[0] eq $base_parts[0]) {
        shift @target_parts;
        shift @base_parts;
    }
    return join '/', (('..') x scalar @base_parts), @target_parts;
}

sub glob_to_regex {
    my ($pattern) = @_;
    my $regex = '';
    my @chars = split //, $pattern;
    for (my $i = 0; $i < @chars; $i++) {
        my $char = $chars[$i];
        if    ($char eq '*') { $regex .= '.*' }
        elsif ($char eq '?') { $regex .= '.' }
        elsif ($char eq '[') {
            my $close = index($pattern, ']', $i + 1);
            if ($close < 0) { $regex .= '\['; next }
            my $set = substr($pattern, $i + 1, $close - $i - 1);
            $set =~ s/^!/^/;
            $set =~ s/\\/\\\\/g;
            $regex .= "[$set]";
            $i = $close;
        }
        else { $regex .= quotemeta($char) }
    }
    return qr/^$regex$/s;
}

sub git_listed_files {
    my ($repo_root) = @_;
    open my $saved_stderr, '>&', \*STDERR or return ();
    open STDERR, '>', File::Spec->devnull
      or do { open STDERR, '>&', $saved_stderr; return () };

    my $fh;
    {
        local $SIG{__WARN__} = sub { };
        open $fh, '-|', 'git', '-C', $repo_root, 'ls-files', '-co',
          '--exclude-standard';
    }
    unless ($fh) {
        open STDERR, '>&', $saved_stderr;
        return ();
    }
    my @lines = <$fh>;
    my $ok    = close $fh;
    open STDERR, '>&', $saved_stderr;
    return () unless $ok;
    chomp @lines;
    return grep { length } @lines;
}

sub matches_ignored {
    my ($rel, $regexes, $is_dir) = @_;
    for my $regex (@$regexes) {
        return 1 if $rel =~ $regex;
    }
    my @parts = split m{/}, $rel;
    my $name  = $parts[-1];
    for my $regex (@$regexes) {
        return 1 if $name =~ $regex;
    }
    return 0 unless $is_dir;
    for my $part (@parts) {
        for my $regex (@$regexes) {
            return 1 if $part =~ $regex;
        }
    }
    return 0;
}

sub walk_repo {
    my ($root, $rel, $regexes, $found) = @_;
    my $abs = length $rel ? "$root/$rel" : $root;
    opendir my $dh, $abs or return;
    my @entries = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
    closedir $dh;
    for my $entry (@entries) {
        my $rel_entry = length $rel ? "$rel/$entry" : $entry;
        my $abs_entry = "$abs/$entry";
        if (-d $abs_entry) {
            next if matches_ignored($rel_entry, $regexes, 1);
            walk_repo($root, $rel_entry, $regexes, $found);
        }
        elsif (-f $abs_entry) {
            next if matches_ignored($rel_entry, $regexes, 0);
            push @$found, $rel_entry;
        }
    }
    return;
}

sub walk_repo_files {
    my ($repo_root) = @_;
    my @patterns = ('.git');
    my $gitignore = File::Spec->catfile($repo_root, '.gitignore');
    if (-e $gitignore) {
        my $content = read_file($gitignore);
        if (defined $content) {
            for my $line (split /\n/, $content, -1) {
                $line =~ s/^\s+//;
                $line =~ s/\s+$//;
                next if $line eq '' || $line =~ /^#/;
                $line =~ s{/+\z}{};
                push @patterns, $line;
            }
        }
    }
    my @regexes = map { glob_to_regex($_) } grep { !/^!/ } @patterns;
    my @found;
    walk_repo($repo_root, '', \@regexes, \@found);
    return @found;
}

sub get_repo_files {
    my ($repo_root) = @_;
    my @files = grep { -f File::Spec->catfile($repo_root, $_) }
      git_listed_files($repo_root);
    return @files if @files;
    return walk_repo_files($repo_root);
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
    my $in_code_block = 0;
    my @new_lines;
    my @change_summaries;
    my $changes_count = 0;

    for my $line_index (0 .. $#lines) {
        my $line = $lines[$line_index];

        if ($line =~ /^\s*```/) {
            $in_code_block = !$in_code_block;
            push @new_lines, $line;
            next;
        }
        if ($in_code_block) {
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
