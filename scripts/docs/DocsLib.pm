package DocsLib;

use strict;
use warnings;
use Cwd qw(abs_path);
use Exporter 'import';
use File::Basename qw(dirname);
use File::Spec;

our @EXPORT_OK = qw(
  get_repo_root
  read_file
  normpath
  relpath
  glob_to_regex
  git_listed_files
  matches_ignored
  walk_repo
  walk_repo_files
  get_repo_files
  fence_start
  closes_fence
  strip_fenced_code
  strip_front_matter
);

sub get_repo_root {
    my $script = __FILE__;
    my $abs    = File::Spec->file_name_is_absolute($script)
      ? $script
      : File::Spec->rel2abs($script);
    my $dir      = dirname($abs);
    my $resolved = abs_path($dir);
    return defined $resolved
      ? dirname(dirname($resolved))
      : dirname(dirname($abs));
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
    my @patterns  = ('.git');
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

sub leading_count {
    my ($text, $char) = @_;
    my $count = 0;
    $count++ while $count < length($text) && substr($text, $count, 1) eq $char;
    return $count;
}

sub fence_start {
    my ($line) = @_;
    (my $stripped = $line) =~ s/^\s+//;
    my $indent     = length($line) - length($stripped);
    my $fence_char = substr($stripped, 0, 1);
    return undef
      if $indent > 3 || ($fence_char ne '`' && $fence_char ne '~');
    my $count = leading_count($stripped, $fence_char);
    return undef if $count < 3;
    return { char => $fence_char, count => $count };
}

sub closes_fence {
    my ($line, $fence) = @_;
    (my $stripped = $line) =~ s/^\s+//;
    my $indent = length($line) - length($stripped);
    return 0 if $indent > 3 || substr($stripped, 0, 1) ne $fence->{char};
    my $count = leading_count($stripped, $fence->{char});
    (my $rest = substr($stripped, $count)) =~ s/^\s+//;
    $rest =~ s/\s+$//;
    return $count >= $fence->{count} && $rest eq '' ? 1 : 0;
}

sub _blank_preserving_newlines {
    my ($text) = @_;
    $text =~ s/[^\n]/ /g;
    return $text;
}

sub strip_fenced_code {
    my ($content) = @_;
    my @lines = split /\n/, $content, -1;
    my @blanked;
    my $fence;

    for my $line (@lines) {
        if ($fence) {
            $fence = undef if closes_fence($line, $fence);
            push @blanked, '';
            next;
        }

        my $start = fence_start($line);
        if ($start) {
            $fence = $start;
            push @blanked, '';
            next;
        }

        push @blanked, $line;
    }

    my $text = join "\n", @blanked;
    $text =~ s/<!--.*?-->/_blank_preserving_newlines($&)/gse;
    return $text;
}

sub strip_front_matter {
    my (@lines) = @_;
    return @lines if @lines < 2;
    return @lines unless $lines[0] =~ /^\s*---\s*$/;
    return @lines unless $lines[1] =~ /^[A-Za-z0-9_-]+:/;

    for my $end (1 .. $#lines) {
        next unless $lines[$end] =~ /^\s*(?:---|\.\.\.)\s*$/;
        return (('') x ($end + 1), @lines[$end + 1 .. $#lines]);
    }
    return @lines;
}

1;
