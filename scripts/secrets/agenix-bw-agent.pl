#!/usr/bin/env perl
#
# In-memory Bitwarden session holder for the agenix secret scripts.
#
# The session token lives only in this process: it is never written to a file,
# and every exit path zero-fills it before the process ends. Clients talk to it
# over a mode 0600 Unix socket. After AGENIX_BW_SESSION_TTL seconds without a
# SET or GET the agent locks the vault, drops the token, and exits.
#
# Usage:
#   agenix-bw-agent.pl get          Print the token (exit 1 when empty)
#   agenix-bw-agent.pl set <token>  Store the token, starting the agent if needed
#   agenix-bw-agent.pl status       Print "OK active <sec>" or "OK empty <sec>"
#   agenix-bw-agent.pl lock         Lock the vault and purge the agent memory
#
# Environment:
#   AGENIX_BW_AGENT_SOCK   Socket path (default: $XDG_RUNTIME_DIR/agenix-bw-agent.sock,
#                          otherwise /tmp/agenix-bw-agent-<uid>.sock)
#   AGENIX_BW_SESSION_TTL  Inactivity timeout in seconds (default: 900)

use strict;
use warnings;
use IO::Socket::UNIX;
use IO::Select;
use POSIX qw(setsid);
use Socket qw(SOCK_STREAM);

my $DEFAULT_TTL = 900;
my $MAX_LINE = 65536;

my $TOKEN = '';
my $TTL = session_ttl();
my $DEADLINE = time + $TTL;
my $SOCK_PATH = agent_socket_path();
my $IS_DAEMON = 0;
my $SOCKET_OWNED = 0;
my $SHUTTING_DOWN = 0;

# struct sockaddr_un truncates longer paths, which would silently move the
# socket away from the path the caller asked for.
if (length $SOCK_PATH > 107) {
  print STDERR "agenix-bw-agent.pl: socket path is too long: $SOCK_PATH\n";
  exit 2;
}

END {
  unlink $SOCK_PATH if $IS_DAEMON and $SOCKET_OWNED;
}

sub session_ttl {
  my $raw = $ENV{AGENIX_BW_SESSION_TTL};
  return $DEFAULT_TTL unless defined $raw and $raw =~ /\A[0-9]+\z/;
  return $raw > 0 ? int($raw) : $DEFAULT_TTL;
}

sub agent_socket_path {
  my $configured = $ENV{AGENIX_BW_AGENT_SOCK};
  return $configured if defined $configured and $configured ne '';
  my $runtime_dir = $ENV{XDG_RUNTIME_DIR};
  return "$runtime_dir/agenix-bw-agent.sock" if defined $runtime_dir and $runtime_dir ne '';
  return sprintf('/tmp/agenix-bw-agent-%d.sock', $<);
}

sub connect_agent {
  return IO::Socket::UNIX->new(Type => SOCK_STREAM, Peer => $SOCK_PATH);
}

sub read_line {
  my ($fh) = @_;
  my $line = '';
  while (length $line < $MAX_LINE) {
    my $read = sysread($fh, $line, $MAX_LINE - length $line, length $line);
    return undef unless defined $read;
    return undef if $read == 0;
    return $line if $line =~ /\n/;
  }
  return $line;
}

sub write_all {
  my ($fh, $text) = @_;
  my $offset = 0;
  while ($offset < length $text) {
    my $written = syswrite($fh, $text, length($text) - $offset, $offset);
    return 0 unless defined $written;
    $offset += $written;
  }
  return 1;
}

sub request {
  my ($conn, $command) = @_;
  return undef unless write_all($conn, "$command\n");
  return read_line($conn);
}

sub purge_token {
  if (length $TOKEN) {
    substr($TOKEN, 0, length $TOKEN) = "\0" x length $TOKEN;
  }
  $TOKEN = '';
}

sub shutdown_agent {
  return if $SHUTTING_DOWN;
  $SHUTTING_DOWN = 1;
  purge_token();
  system('sh', '-c', 'bw lock >/dev/null 2>&1');
  if ($SOCKET_OWNED) {
    unlink $SOCK_PATH;
    $SOCKET_OWNED = 0;
  }
  exit 0;
}

sub notify_ready {
  my ($fh, $message) = @_;
  return unless $fh;
  write_all($fh, "$message\n");
  close $fh;
}

sub reply {
  my ($conn, $message) = @_;
  write_all($conn, "$message\n");
}

sub handle_command {
  my ($conn, $line) = @_;
  my $command = $line;
  $command =~ s/\r?\n\z//;

  if ($command eq 'GET') {
    if (length $TOKEN) {
      $DEADLINE = time + $TTL;
      reply($conn, "OK $TOKEN");
    } else {
      reply($conn, 'ERR empty');
    }
    return;
  }
  if ($command =~ /\ASET (.*)\z/s) {
    purge_token();
    $TOKEN = $1;
    $DEADLINE = time + $TTL;
    reply($conn, 'OK');
    return;
  }
  if ($command eq 'STATUS') {
    my $remaining = $DEADLINE - time;
    $remaining = 0 if $remaining < 0;
    my $state = length $TOKEN ? 'active' : 'empty';
    reply($conn, "OK $state $remaining");
    return;
  }
  if ($command eq 'LOCK') {
    reply($conn, 'OK');
    shutdown_agent();
  }
  reply($conn, 'ERR unknown');
}

sub serve {
  my ($listener) = @_;
  my $selector = IO::Select->new($listener);
  while (1) {
    my $remaining = $DEADLINE - time;
    shutdown_agent() if $remaining <= 0;
    my @readable = $selector->can_read($remaining);
    next unless @readable;
    my $conn = $listener->accept();
    next unless $conn;
    my $line = read_line($conn);
    handle_command($conn, $line) if defined $line;
    close $conn;
  }
}

sub run_as_daemon {
  my ($ready_fh) = @_;
  $IS_DAEMON = 1;
  setsid();
  chdir '/';
  umask 0177;
  # The caller may hold a pipe on our stdio, so detach before serving.
  open(STDIN, '<', '/dev/null');
  open(STDOUT, '>', '/dev/null');
  open(STDERR, '>', '/dev/null');

  if (lstat $SOCK_PATH) {
    my $probe = connect_agent();
    if ($probe) {
      close $probe;
      notify_ready($ready_fh, 'ready');
      exit 0;
    }
    unlink $SOCK_PATH;
  }

  my $listener = IO::Socket::UNIX->new(
    Type   => SOCK_STREAM,
    Local  => $SOCK_PATH,
    Listen => 16,
  );
  unless ($listener) {
    my $probe = connect_agent();
    if ($probe) {
      close $probe;
      notify_ready($ready_fh, 'ready');
      exit 0;
    }
    notify_ready($ready_fh, 'error');
    exit 1;
  }
  chmod 0600, $SOCK_PATH;
  $SOCKET_OWNED = 1;

  $SIG{PIPE} = 'IGNORE';
  $SIG{TERM} = \&shutdown_agent;
  $SIG{INT}  = \&shutdown_agent;
  $SIG{HUP}  = \&shutdown_agent;

  notify_ready($ready_fh, 'ready');
  serve($listener);
}

# Fork the detached daemon and report back once it owns the socket.
sub spawn_daemon {
  pipe(my $ready_read, my $ready_write) or return 1;
  my $pid = fork();
  unless (defined $pid) {
    close $ready_read;
    close $ready_write;
    return 1;
  }
  if ($pid) {
    close $ready_write;
    my $selector = IO::Select->new($ready_read);
    my $ready = '';
    sysread($ready_read, $ready, 16) if $selector->can_read(10);
    close $ready_read;
    return $ready =~ /\Aready/ ? 0 : 1;
  }
  close $ready_read;
  run_as_daemon($ready_write);
  exit 0;
}

sub client_get {
  my $conn = connect_agent();
  return 1 unless $conn;
  my $response = request($conn, 'GET');
  close $conn;
  return 1 unless defined $response;
  if ($response =~ /\AOK ([^\n]*)/) {
    print "$1\n";
    return 0;
  }
  return 1;
}

sub client_set {
  my ($token) = @_;
  if (!defined $token or $token eq '-' or $token eq '') {
    $token = <STDIN> // '';
    chomp $token;
  }
  return 1 unless defined $token and $token ne '';
  my $conn = connect_agent();
  unless ($conn) {
    return 1 if system($^X, $0, '--daemon') != 0;
    for (1 .. 50) {
      $conn = connect_agent();
      last if $conn;
      select(undef, undef, undef, 0.1);
    }
  }
  return 1 unless $conn;
  my $response = request($conn, "SET $token");
  close $conn;
  return defined $response && $response =~ /\AOK/ ? 0 : 1;
}

sub client_status {
  my $conn = connect_agent();
  return 1 unless $conn;
  my $response = request($conn, 'STATUS');
  close $conn;
  return 1 unless defined $response;
  $response =~ s/\r?\n\z//;
  print "$response\n";
  return $response =~ /\AOK / ? 0 : 1;
}

sub client_lock {
  my $conn = connect_agent();
  if ($conn) {
    request($conn, 'LOCK');
    close $conn;
    return 0;
  }
  system('sh', '-c', 'bw lock >/dev/null 2>&1');
  return 0;
}

sub usage {
  print STDERR "usage: agenix-bw-agent.pl <get|set <token>|status|lock>\n";
}

my $command = shift @ARGV // '';

if ($command eq '--daemon') {
  exit spawn_daemon();
}
if ($command eq 'get') {
  exit client_get();
}
if ($command eq 'set') {
  exit client_set($ARGV[0]);
}
if ($command eq 'status') {
  exit client_status();
}
if ($command eq 'lock') {
  exit client_lock();
}
usage();
exit 2;
