MODULE DNS;  (** host names to addresses: /etc/hosts, then the name servers of /etc/resolv.conf *)

(* A name is looked up in /etc/hosts first, then asked of the name servers over UDP (A records
   for IPv4, AAAA for IPv6), each server waiting timeout milliseconds, Tries rounds. The servers
   are the nameserver lines of /etc/resolv.conf, or else 1.1.1.1 and 2606:4700:4700::1111; the
   environment variable DNS_SERVER (address, optionally #port) comes before them.
   The answers of a recursive server carry the whole CNAME chain, so every address record of the
   answer section is taken. Truncated answers are used as far as they go (no TCP yet).
   Bytes are read with LONG(ORD(c)): ORD gives an INTEGER (16 bits). *)

IMPORT Kernel, Linux0, Sockets, SYSTEM;

CONST
  Any* = 0;  (** Lookup family: IPv6 and IPv4 addresses *)
  (** res *)
  Ok* = 0; NotFound* = 1; NoAnswer* = 2; BadName* = 3;
  TypeA = 1; TypeAAAA = 28; ClassIN = 1;
  Port = 53; Tries = 2; MaxServers = 4; MaxMsg = 1500;

VAR
  res*: LONGINT;  (** the result of the last Lookup or Resolve *)
  timeout*: LONGINT;  (** milliseconds to wait for one server *)
  server: ARRAY MaxServers OF Sockets.Address;
  sport: ARRAY MaxServers OF LONGINT;
  nservers: LONGINT;
  first: LONGINT;  (* the server that answered last: asked first *)
  loaded: BOOLEAN;
  file: ARRAY 16384 OF CHAR;  (* /etc/hosts, /etc/resolv.conf *)
  flen: LONGINT;
  seq: LONGINT;

(* ----- files ----- *)

PROCEDURE ReadFile(path: ARRAY OF CHAR): BOOLEAN;
VAR fd, r: LONGINT;
BEGIN
  flen := 0;
  fd := Linux0.Openat0(Linux0.ATFDCWD, SYSTEM.ADR(path[0]), Linux0.ORDonly, 0);
  IF fd < 0 THEN RETURN FALSE END;
  LOOP
    r := Linux0.Read0(fd, SYSTEM.ADR(file[flen]), LEN(file) - 1 - flen);
    IF r <= 0 THEN EXIT END;
    INC(flen, r);
    IF flen >= LEN(file) - 1 THEN EXIT END
  END;
  file[flen] := 0X; r := Linux0.Close0(fd);
  RETURN TRUE
END ReadFile;

(* the next word of the line at i in file; FALSE at the line end or a comment *)
PROCEDURE Word(VAR i: LONGINT; VAR w: ARRAY OF CHAR): BOOLEAN;
VAR j: LONGINT;
BEGIN
  WHILE (i < flen) & ((file[i] = " ") OR (file[i] = 9X) OR (file[i] = 0DX)) DO INC(i) END;
  IF (i >= flen) OR (file[i] = 0AX) OR (file[i] = "#") OR (file[i] = ";") THEN RETURN FALSE END;
  j := 0;
  WHILE (i < flen) & (file[i] > " ") DO
    IF j < LEN(w) - 1 THEN w[j] := file[i]; INC(j) END;
    INC(i)
  END;
  w[j] := 0X;
  RETURN TRUE
END Word;

PROCEDURE NextLine(VAR i: LONGINT);
BEGIN
  WHILE (i < flen) & (file[i] # 0AX) DO INC(i) END;
  IF i < flen THEN INC(i) END
END NextLine;

PROCEDURE Cap(c: CHAR): CHAR;
BEGIN
  IF (c >= "a") & (c <= "z") THEN RETURN CHR(ORD(c) - 32) END;
  RETURN c
END Cap;

PROCEDURE SameName(VAR a, b: ARRAY OF CHAR): BOOLEAN;
VAR i: LONGINT;
BEGIN
  i := 0;
  WHILE (a[i] # 0X) & (Cap(a[i]) = Cap(b[i])) DO INC(i) END;
  RETURN (Cap(a[i]) = Cap(b[i])) OR (a[i] = 0X) & (b[i] = ".") & (b[i + 1] = 0X)
END SameName;

(* ----- servers ----- *)

PROCEDURE AddServer(VAR s: ARRAY OF CHAR);
VAR i, p: LONGINT;
BEGIN
  IF nservers >= MaxServers THEN RETURN END;
  p := Port; i := 0;
  WHILE (s[i] # 0X) & (s[i] # "#") DO INC(i) END;
  IF s[i] = "#" THEN
    s[i] := 0X; INC(i); p := 0;
    WHILE (s[i] >= "0") & (s[i] <= "9") DO p := p * 10 + ORD(s[i]) - ORD("0"); INC(i) END
  END;
  IF Sockets.ParseAddress(s, server[nservers]) THEN sport[nservers] := p; INC(nservers) END
END AddServer;

PROCEDURE LoadServers;
VAR i: LONGINT; w: ARRAY 64 OF CHAR;
BEGIN
  nservers := 0; first := 0;
  Kernel.GetConfig("DNS_SERVER", w);
  IF w # "" THEN AddServer(w) END;
  IF ReadFile("/etc/resolv.conf") THEN
    i := 0;
    WHILE i < flen DO
      IF Word(i, w) & (w = "nameserver") & Word(i, w) THEN AddServer(w) END;
      NextLine(i)
    END
  END;
  IF nservers = 0 THEN
    w := "1.1.1.1"; AddServer(w); w := "2606:4700:4700::1111"; AddServer(w)
  END;
  loaded := TRUE
END LoadServers;

(** forget the servers; the next lookup reads them again *)
PROCEDURE Reset*;
BEGIN loaded := FALSE
END Reset;

(* ----- /etc/hosts ----- *)

PROCEDURE Add(VAR x: Sockets.Address; family: INTEGER; VAR a: ARRAY OF Sockets.Address; VAR n: LONGINT);
VAR i, j, m: LONGINT; same: BOOLEAN;
BEGIN
  IF (family # Any) & (x.family # family) OR (n >= LEN(a)) THEN RETURN END;
  IF x.family = Sockets.Inet4 THEN m := 4 ELSE m := 16 END;
  i := 0;
  WHILE i < n DO  (* no duplicates *)
    IF a[i].family = x.family THEN
      same := TRUE; j := 0;
      WHILE j < m DO IF a[i].addr[j] # x.addr[j] THEN same := FALSE END; INC(j) END;
      IF same THEN RETURN END
    END;
    INC(i)
  END;
  a[n] := x; INC(n)
END Add;

PROCEDURE Hosts(VAR name: ARRAY OF CHAR; family: INTEGER; VAR a: ARRAY OF Sockets.Address; VAR n: LONGINT);
VAR i: LONGINT; w: ARRAY 256 OF CHAR; x: Sockets.Address; ok: BOOLEAN;
BEGIN
  IF ~ReadFile("/etc/hosts") THEN RETURN END;
  i := 0;
  WHILE i < flen DO
    IF Word(i, w) & Sockets.ParseAddress(w, x) THEN
      ok := FALSE;
      WHILE ~ok & Word(i, w) DO ok := SameName(w, name) END;
      IF ok THEN Add(x, family, a, n) END
    END;
    NextLine(i)
  END
END Hosts;

(* ----- messages ----- *)

PROCEDURE Put16(VAR m: ARRAY OF CHAR; VAR i: LONGINT; x: LONGINT);
BEGIN m[i] := CHR(x DIV 256 MOD 256); m[i + 1] := CHR(x MOD 256); INC(i, 2)
END Put16;

PROCEDURE Get16(VAR m: ARRAY OF CHAR; i: LONGINT): LONGINT;
BEGIN RETURN LONG(ORD(m[i])) * 256 + LONG(ORD(m[i + 1]))
END Get16;

PROCEDURE NewId(): LONGINT;
VAR fd, r: LONGINT; b: ARRAY 2 OF CHAR; path: ARRAY 16 OF CHAR;
BEGIN
  INC(seq); path := "/dev/urandom";
  fd := Linux0.Openat0(Linux0.ATFDCWD, SYSTEM.ADR(path[0]), Linux0.ORDonly, 0);
  IF fd >= 0 THEN
    r := Linux0.Read0(fd, SYSTEM.ADR(b[0]), 2); r := Linux0.Close0(fd);
    IF r = 2 THEN RETURN Get16(b, 0) END
  END;
  RETURN seq * 7919 MOD 65536
END NewId;

(* the query for name, type t, in m[0..len) *)
PROCEDURE Query(VAR name: ARRAY OF CHAR; id, t: LONGINT; VAR m: ARRAY OF CHAR; VAR len: LONGINT): BOOLEAN;
VAR i, j, l: LONGINT;
BEGIN
  i := 0; Put16(m, i, id); Put16(m, i, 100H);  (* recursion desired *)
  Put16(m, i, 1); Put16(m, i, 0); Put16(m, i, 0); Put16(m, i, 0);
  j := 0;
  WHILE name[j] # 0X DO
    l := 0;
    WHILE (name[j + l] # 0X) & (name[j + l] # ".") DO m[i + 1 + l] := name[j + l]; INC(l) END;
    IF (l = 0) OR (l > 63) OR (i + l > 12 + 253) THEN RETURN FALSE END;
    m[i] := CHR(l); INC(i, l + 1); INC(j, l);
    IF name[j] = "." THEN INC(j) END
  END;
  IF i = 12 THEN RETURN FALSE END;
  m[i] := 0X; INC(i); Put16(m, i, t); Put16(m, i, ClassIN);
  len := i;
  RETURN TRUE
END Query;

PROCEDURE SkipName(VAR m: ARRAY OF CHAR; len: LONGINT; VAR i: LONGINT): BOOLEAN;
VAR c: LONGINT;
BEGIN
  LOOP
    IF i >= len THEN RETURN FALSE END;
    c := ORD(m[i]);
    IF c = 0 THEN INC(i); EXIT
    ELSIF c >= 0C0H THEN INC(i, 2); EXIT
    ELSIF c >= 40H THEN RETURN FALSE
    ELSE INC(i, c + 1)
    END
  END;
  RETURN i <= len
END SkipName;

(* the addresses of type t in answer m; the result code *)
PROCEDURE Answer(VAR m: ARRAY OF CHAR; len, t: LONGINT; VAR a: ARRAY OF Sockets.Address; VAR n: LONGINT): LONGINT;
VAR i, j, k, qd, an, rt, rc, rl: LONGINT; x: Sockets.Address;
BEGIN
  rc := ORD(m[3]) MOD 16;
  IF rc = 3 THEN RETURN NotFound ELSIF rc # 0 THEN RETURN NoAnswer END;
  qd := Get16(m, 4); an := Get16(m, 6); i := 12;
  WHILE qd > 0 DO
    IF ~SkipName(m, len, i) THEN RETURN Ok END;
    INC(i, 4); DEC(qd)
  END;
  WHILE (an > 0) & (i < len) DO
    IF ~SkipName(m, len, i) OR (i + 10 > len) THEN RETURN Ok END;
    rt := Get16(m, i); rc := Get16(m, i + 2); rl := Get16(m, i + 8); INC(i, 10);
    IF i + rl > len THEN RETURN Ok END;
    IF (rc = ClassIN) & (rt = t) & ((t = TypeA) & (rl = 4) OR (t = TypeAAAA) & (rl = 16)) THEN
      IF t = TypeA THEN x.family := Sockets.Inet4 ELSE x.family := Sockets.Inet6 END;
      k := 0; WHILE k < 16 DO x.addr[k] := 0X; INC(k) END;
      j := 0; WHILE j < rl DO x.addr[j] := m[i + j]; INC(j) END;
      Add(x, Any, a, n)
    END;
    INC(i, rl); DEC(an)
  END;
  RETURN Ok
END Answer;

(* ask the servers for the records of type t; the result code *)
PROCEDURE Ask(VAR name: ARRAY OF CHAR; t: LONGINT; VAR a: ARRAY OF Sockets.Address; VAR n: LONGINT): LONGINT;
VAR q, m: ARRAY MaxMsg OF CHAR; qlen, len, id, try, j, k, r, fport, got: LONGINT;
  s: Sockets.Socket; from: Sockets.Address;
BEGIN
  IF ~loaded THEN LoadServers END;
  try := 0;
  WHILE try < Tries DO
    j := 0;
    WHILE j < nservers DO
      k := (first + j) MOD nservers; id := NewId();
      IF ~Query(name, id, t, q, qlen) THEN RETURN BadName END;
      s := Sockets.OpenUDP(server[k].family, 0);
      IF s # NIL THEN
        Sockets.SetTimeout(s, timeout);
        IF Sockets.SendTo(s, server[k], sport[k], q, qlen) = qlen THEN
          got := 0;
          WHILE got < 4 DO  (* a few stray datagrams are ignored *)
            len := Sockets.ReceiveFrom(s, m, LEN(m), from, fport);
            IF len < 0 THEN got := 4
            ELSIF (len >= 12) & (Get16(m, 0) = id) & (ORD(m[2]) >= 80H) & (fport = sport[k]) THEN
              r := Answer(m, len, t, a, n);
              IF r # NoAnswer THEN Sockets.Close(s); first := k; RETURN r END;
              got := 4
            ELSE INC(got)
            END
          END
        END;
        Sockets.Close(s)
      END;
      INC(j)
    END;
    INC(try)
  END;
  RETURN NoAnswer
END Ask;

(* ----- lookups ----- *)

(** the addresses of name (IPv6 first, then IPv4, for family Any), at most LEN(a), in a[0..n);
  an address literal gives itself. res tells what happened. *)
PROCEDURE Lookup*(name: ARRAY OF CHAR; family: INTEGER; VAR a: ARRAY OF Sockets.Address; VAR n: LONGINT);
VAR x: Sockets.Address; r: LONGINT;
BEGIN
  n := 0; res := Ok;
  IF Sockets.ParseAddress(name, x) THEN Add(x, family, a, n)
  ELSIF name[0] = 0X THEN res := BadName
  ELSE
    Hosts(name, family, a, n);
    IF n = 0 THEN
      r := Ok;
      IF family # Sockets.Inet4 THEN r := Ask(name, TypeAAAA, a, n) END;
      IF (family # Sockets.Inet6) & (r # NotFound) & (r # BadName) THEN r := Ask(name, TypeA, a, n) END;
      IF n = 0 THEN
        IF r = Ok THEN res := NotFound ELSE res := r END
      END
    END
  END;
  IF (n = 0) & (res = Ok) THEN res := NotFound END
END Lookup;

(** the first address of name, of family Any, Inet4 or Inet6 *)
PROCEDURE Resolve*(name: ARRAY OF CHAR; family: INTEGER; VAR a: Sockets.Address): BOOLEAN;
VAR x: ARRAY 1 OF Sockets.Address; n: LONGINT;
BEGIN
  Lookup(name, family, x, n);
  IF n > 0 THEN a := x[0] END;
  RETURN n > 0
END Resolve;

BEGIN
  res := Ok; timeout := 2000; loaded := FALSE; seq := 0
END DNS.
