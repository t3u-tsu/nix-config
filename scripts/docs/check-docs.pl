#!/usr/bin/env perl
# Lint markdown prose (parentheses, commas, prohibited words, pseudo-headings)
# and validate relative links and heading anchors.
# Usage: perl scripts/docs/check-docs.pl [files...]
use strict;
use warnings;
use utf8;
use open qw(:std :utf8);
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Spec;

my @PROHIBITED_JA = (
    '堅牢', '包括的', '網羅的', 'シームレス', '活用', 'レバレッジ',
    '担保', '看取', '企図', '包摂', '敷設', '資する',
    '直叩き', '直結で叩く', '正本', '土台', '配線する', '引き回す',
    '側に倒す', '素通り', '一手に担う', 'という形になる',
    '念頭に置', '留意する', '非常に', '極めて',
    'を可能にする', '静かに動く', '効く', '原本',
);

my @PROHIBITED_EN = (
    'delve', 'delves', 'delved', 'delving',
    'testament', 'testaments', 'tapestry',
    'robust', 'robustly', 'robustness',
    'seamless', 'seamlessly',
    'streamline', 'streamlines', 'streamlined', 'streamlining',
    'leverage', 'leverages', 'leveraged', 'leveraging',
    'crucial', 'crucially', 'paramount', 'vital', 'vitally',
    'comprehensive', 'comprehensively',
    'foster', 'fosters', 'fostered', 'fostering',
    'cultivate', 'cultivates', 'cultivated', 'cultivating',
    'plethora', 'myriad', 'ssot',
);

my $ASCII_WORD_CHARS =
  'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_';
my $ASCII_CHARS =
    q{ !"#$%&()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`}
  . q{abcdefghijklmnopqrstuvwxyz{|}~}
  . q{'}
  . "\t";

my @PROHIBITED_WORD_EXEMPT = ('.agents/skills/documentation-guide/SKILL.md');

my $LINK_RE =
  qr/\[([^\]]*)\]\(\s*(<[^>]*>|[^)\s]+)(?:\s+(?:"[^"]*"|'[^']*'|\([^)]*\)))?\s*\)/;
my $ATX_HEADING_RE      = qr/^ {0,3}(#{1,6})(?:[ \t]+(.*?))?\s*$/;
my $SETEXT_UNDERLINE_RE = qr/^ {0,3}(=+|-+)[ \t]*$/;
my $SCHEME_RE           = qr/^[a-zA-Z][a-zA-Z0-9+.-]*:/;

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

sub trimmed {
    my ($text) = @_;
    $text =~ s/^\s+//;
    $text =~ s/\s+$//;
    return $text;
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

sub strip_inline_code {
    my ($line) = @_;
    my $out  = '';
    my $rest = $line;
    while (1) {
        my $start = index($rest, '`');
        if ($start < 0) {
            $out .= $rest;
            last;
        }
        $out .= substr($rest, 0, $start);
        my $run       = leading_count(substr($rest, $start), '`');
        my $delimiter = substr($rest, $start, $run);
        my $after     = substr($rest, $start + $run);
        my $close     = index($after, $delimiter);
        if ($close < 0) {
            $out .= $delimiter;
            $rest = $after;
        }
        else {
            $out .= 'CODE';
            $rest = substr($after, $close + $run);
        }
    }
    return $out;
}

sub is_ascii_char {
    my ($char) = @_;
    return 0 if $char eq '';
    return index($ASCII_CHARS, $char) >= 0 ? 1 : 0;
}

sub has_comma_adjacent_to_non_ascii {
    my ($line) = @_;
    my $length = length $line;
    for (my $i = 0; $i < $length; $i++) {
        next unless substr($line, $i, 1) eq ',';
        if ($i > 0) {
            my $prev = substr($line, $i - 1, 1);
            return 1 unless is_ascii_char($prev);
        }
        my $next_index = $i + 1;
        $next_index++
          if $next_index < $length && substr($line, $next_index, 1) eq ' ';
        if ($next_index < $length) {
            my $next = substr($line, $next_index, 1);
            return 1 unless is_ascii_char($next);
        }
    }
    return 0;
}

sub is_pseudo_heading {
    my ($line) = @_;
    (my $stripped = $line) =~ s/^\s+//;
    my $marker = substr($stripped, 0, 2);
    return 0 unless $marker eq '- ' || $marker eq '* ' || $marker eq '+ ';

    my $rest = substr($stripped, 2);
    return 0 unless substr($rest, 0, 2) eq '**';
    my $end = index($rest, '**:');
    return 0 if $end <= 2;
    return index(substr($rest, 2, $end - 2), '*') < 0 ? 1 : 0;
}

sub is_ascii_word_char {
    my ($char) = @_;
    return 0 if $char eq '';
    return index($ASCII_WORD_CHARS, $char) >= 0 ? 1 : 0;
}

sub contains_ascii_word {
    my ($haystack, $word) = @_;
    my $offset = 0;
    while (1) {
        my $index = index($haystack, $word, $offset);
        return 0 if $index < 0;
        my $before =
          $index == 0 ? '' : substr($haystack, $index - 1, 1);
        my $after_index = $index + length($word);
        my $after = $after_index >= length($haystack)
          ? ''
          : substr($haystack, $after_index, 1);
        return 1
          unless is_ascii_word_char($before) || is_ascii_word_char($after);
        $offset = $index + 1;
    }
}

sub blank_preserving_newlines {
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
        (my $stripped = $line) =~ s/^ +//;
        my $indent     = length($line) - length($stripped);
        my $fence_char = substr($stripped, 0, 1);

        if ($fence) {
            if ($indent <= 3 && $fence_char eq $fence->{char}) {
                my $char = $fence->{char};
                my $run  = 0;
                $run++ while substr($stripped, $run, 1) eq $char;
                my $rest = substr($stripped, $run);
                $fence = undef if $run >= $fence->{count} && $rest =~ /^\s*$/;
            }
            push @blanked, '';
            next;
        }

        if ($indent <= 3 && $stripped =~ /^(?:```|~~~)/) {
            my $char = substr($stripped, 0, 1);
            my $run  = 0;
            $run++ while substr($stripped, $run, 1) eq $char;
            if ($run >= 3) {
                $fence = { char => $char, count => $run };
                push @blanked, '';
                next;
            }
        }

        push @blanked, $line;
    }

    my $text = join "\n", @blanked;
    $text =~ s/<!--.*?-->/blank_preserving_newlines($&)/gse;
    return $text;
}

sub strip_markdown_code {
    my ($content) = @_;
    my $text = strip_fenced_code($content);
    $text =~ s/(`+)([^\n]+?)\1/blank_preserving_newlines($&)/ge;
    return $text;
}

sub heading_text {
    my ($raw) = @_;
    my @code_spans;
    my $text = $raw;
    $text =~ s/(`+)(.+?)\1/do {
        push @code_spans, $2;
        "\x00" . $#code_spans . "\x00";
    }/ge;
    $text =~ s/<[^>]+>//g;
    $text =~ s/!\[([^\]]*)\]\([^)]*\)/$1/g;
    $text =~ s/\[([^\]]*)\]\([^)]*\)/$1/g;
    $text =~ s/\\([\\`*_{}\[\]()#+\-.!>])/$1/g;
    $text =~ s/\*\*(.+?)\*\*/$1/g;
    $text =~ s/(?<![A-Za-z0-9])__([^_]+)__(?![A-Za-z0-9])/$1/g;
    $text =~ s/\*(.+?)\*/$1/g;
    $text =~ s/(?<![A-Za-z0-9])_([^_]+)_(?![A-Za-z0-9])/$1/g;
    $text =~ s/~~(.+?)~~/$1/g;
    for my $index (0 .. $#code_spans) {
        $text =~ s/\x00$index\x00/$code_spans[$index]/g;
    }
    return $text;
}

sub slugify {
    my ($raw) = @_;
    my $text = lc trimmed(heading_text($raw));
    my $slug = '';
    for my $char (split //, $text) {
        if    ($char eq '-' || $char eq '_') { $slug .= $char }
        elsif ($char =~ /\p{Space}/)         { $slug .= '-' }
        elsif ($char =~ /[\p{P}\p{S}\p{C}]/) { next }
        else                                 { $slug .= $char }
    }
    return $slug;
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

sub extract_headings {
    my ($content) = @_;
    my @lines = strip_front_matter(split /\n/, strip_fenced_code($content), -1);
    my @headings;

    for my $index (0 .. $#lines) {
        my $line = $lines[$index];

        if ($line =~ $ATX_HEADING_RE) {
            my $text = defined $2 ? $2 : '';
            $text =~ s/[ \t]+#+[ \t]*$//;
            push @headings, trimmed($text);
            next;
        }

        next if $index + 1 > $#lines;
        next unless $line =~ /\S/;
        (my $without_indent = $line) =~ s/^ +//;
        next if length($line) - length($without_indent) > 3;
        next unless $lines[$index + 1] =~ $SETEXT_UNDERLINE_RE;
        next if $line =~ /^ {0,3}([-*+>=~#|]|\d+[.)]\s)/;
        push @headings, trimmed($line);
    }

    return @headings;
}

sub heading_anchors {
    my ($path, $cache) = @_;
    return $cache->{$path} if exists $cache->{$path};

    my $content = read_file($path);
    if (!defined $content) {
        return $cache->{$path} = {};
    }

    my (%seen, %anchors);
    for my $heading (extract_headings($content)) {
        my $base = slugify($heading);
        next if $base eq '';
        my $count = $seen{$base} // 0;
        $anchors{$count == 0 ? $base : "$base-$count"} = 1;
        $seen{$base} = $count + 1;
    }
    return $cache->{$path} = \%anchors;
}

sub unquote {
    my ($text) = @_;
    $text =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
    return $text;
}

sub check_prose {
    my ($rel_display, $content, $errors) = @_;

    my $word_checks_enabled = 1;
    for my $exempt (@PROHIBITED_WORD_EXEMPT) {
        $word_checks_enabled = 0 if $rel_display =~ /\Q$exempt\E\z/;
    }

    my @lines = split /\n/, $content, -1;
    pop @lines if @lines && $lines[-1] eq '';

    my $fence;
    my $lineno = 0;
    for my $line (@lines) {
        $lineno++;

        if ($fence) {
            $fence = undef if closes_fence($line, $fence);
            next;
        }

        my $start = fence_start($line);
        if ($start) {
            $fence = $start;
            next;
        }

        my $clean = strip_inline_code($line);
        if (index($clean, '（') >= 0 || index($clean, '）') >= 0) {
            push @$errors, "$rel_display:$lineno: full-width parentheses: $line";
        }
        if (has_comma_adjacent_to_non_ascii($clean)) {
            push @$errors,
              "$rel_display:$lineno: half-width comma adjacent to Japanese prose: $line";
        }
        if ($word_checks_enabled) {
            for my $word (@PROHIBITED_JA) {
                push @$errors, "$rel_display:$lineno: prohibited word '$word': $line"
                  if index($clean, $word) >= 0;
            }
            my $lowered = lc $clean;
            for my $word (@PROHIBITED_EN) {
                push @$errors, "$rel_display:$lineno: prohibited word '$word': $line"
                  if contains_ascii_word($lowered, $word);
            }
        }
        if (is_pseudo_heading($clean)) {
            push @$errors, "$rel_display:$lineno: pseudo-heading bullet: $line";
        }
    }
}

sub check_links {
    my ($md_path, $rel_display, $content, $repo_root, $anchor_cache, $errors) = @_;

    my $clean  = strip_markdown_code($content);
    my $md_dir = dirname($md_path);

    while ($clean =~ /$LINK_RE/g) {
        my $raw_target = trimmed($2);
        my $link_start = $-[0];

        $raw_target = substr($raw_target, 1, -1)
          if $raw_target =~ /^</ && $raw_target =~ />$/;

        my ($path_part, $fragment) = ('', '');
        if ($raw_target =~ /^([^#]*)(?:#(.*))?\z/s) {
            $path_part = $1;
            $fragment  = defined $2 ? $2 : '';
        }
        $path_part = unquote((split /\?/, $path_part, 2)[0] // '');
        $fragment  = unquote($fragment // '');

        next if $raw_target =~ $SCHEME_RE || $raw_target =~ m{^//};

        my $resolved;
        if ($path_part eq '') {
            $resolved = $md_path;
        }
        elsif ($path_part =~ m{^/}) {
            $resolved = normpath("$repo_root/$path_part");
        }
        else {
            $resolved = normpath("$md_dir/$path_part");
        }

        my $prefix      = substr($clean, 0, $link_start);
        my $line_number = 1 + ($prefix =~ tr/\n//);
        my $location    = "$rel_display:$line_number";

        if (!-e $resolved) {
            push @$errors,
              "$location: broken link -> '$raw_target' (resolved: '$resolved')";
            next;
        }

        next if $fragment eq '' || $resolved !~ /\.md$/i;

        my $anchors = heading_anchors($resolved, $anchor_cache);
        if (!exists $anchors->{$fragment}) {
            my $target_display = relpath($resolved, $repo_root);
            push @$errors,
"$location: broken anchor -> '#$fragment' not found in '$target_display'";
        }
    }
}

sub check_file {
    my ($abs_path, $repo_root, $anchor_cache, $errors) = @_;
    my $content = read_file($abs_path);
    if (!defined $content) {
        push @$errors, "$abs_path: failed to read file: $!";
        return;
    }

    my $rel_display = relpath($abs_path, $repo_root);
    check_prose($rel_display, $content, $errors);
    check_links($abs_path, $rel_display, $content, $repo_root, $anchor_cache, $errors);
}

sub main {
    my $repo_root = get_repo_root();
    my @files;

    if (@ARGV) {
        @files = grep { /\.md$/ && -e $_ }
          map {
            File::Spec->file_name_is_absolute($_)
              ? $_
              : File::Spec->rel2abs($_)
          } @ARGV;
    }
    else {
        @files = map { File::Spec->catfile($repo_root, $_) }
          grep { /\.md$/ } get_repo_files($repo_root);
    }

    @files = sort @files;

    my %anchor_cache;
    my @errors;
    for my $file (@files) {
        check_file($file, $repo_root, \%anchor_cache, \@errors);
    }

    if (@errors) {
        print 'FAILED: Found ' . scalar(@errors)
          . " documentation error(s):\n";
        print "  $_\n" for @errors;
        return 1;
    }

    print 'PASSED: Checked ' . scalar(@files)
      . " markdown files - all prose rules and links are valid.\n";
    return 0;
}

exit main();
