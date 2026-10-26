#!/usr/bin/env perl
# Lint markdown prose (parentheses, commas, prohibited words, pseudo-headings)
# and validate relative links and heading anchors.
# Usage: perl scripts/docs/check-docs.pl [files...]
use strict;
use warnings;
use utf8;
use open qw(:std :utf8);
use File::Basename qw(dirname);
use File::Spec;
use FindBin;
use lib $FindBin::RealBin;
use DocsLib qw(
  closes_fence
  fence_start
  get_repo_files
  get_repo_root
  normpath
  read_file
  relpath
  strip_fenced_code
  strip_front_matter
);

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

sub trimmed {
    my ($text) = @_;
    $text =~ s/^\s+//;
    $text =~ s/\s+$//;
    return $text;
}

sub leading_count {
    my ($text, $char) = @_;
    my $count = 0;
    $count++ while $count < length($text) && substr($text, $count, 1) eq $char;
    return $count;
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

sub blank_ignored_blocks {
    my (@lines) = @_;
    my @result = strip_front_matter(@lines);
    my $in_comment = 0;

    for my $index (0 .. $#result) {
        my $line = $result[$index];
        my $kept = '';
        my $pos  = 0;

        while ($pos < length $line) {
            if ($in_comment) {
                my $end = index($line, '-->', $pos);
                if ($end < 0) { $pos = length $line; next }
                $in_comment = 0;
                $pos        = $end + 3;
                next;
            }
            my $start = index($line, '<!--', $pos);
            if ($start < 0) {
                $kept .= substr($line, $pos);
                last;
            }
            $kept .= substr($line, $pos, $start - $pos);
            $in_comment = 1;
            $pos        = $start + 4;
        }

        $result[$index] = $kept;
    }

    return @result;
}

sub check_prose {
    my ($rel_display, $content, $errors) = @_;

    my $word_checks_enabled = 1;
    for my $exempt (@PROHIBITED_WORD_EXEMPT) {
        $word_checks_enabled = 0 if $rel_display =~ /\Q$exempt\E\z/;
    }

    my @lines = blank_ignored_blocks(split /\n/, $content, -1);
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
