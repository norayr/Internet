MODULE testNetSystem;  (* testNetSystem [net]: NetSystem over TCP and UDP on 127.0.0.1 (ports 18490,
  18491, 18492); with net also GetIP of example.com and an HTTP GET through NetSystem *)

IMPORT NetSystem, Args, Out, Platform;

CONST Port = 18490; UPort1 = 18491; UPort2 = 18492;

VAR checks, fails: LONGINT; arg: ARRAY 16 OF CHAR;

PROCEDURE Check(name: ARRAY OF CHAR; ok: BOOLEAN);
BEGIN
  INC(checks);
  IF ok THEN Out.String("ok   ") ELSE INC(fails); Out.String("FAIL ") END;
  Out.String(name); Out.Ln
END Check;

PROCEDURE Addresses;
VAR ip: NetSystem.IPAdr; s: ARRAY 32 OF CHAR; ok: BOOLEAN; b: ARRAY 4 OF CHAR; x: LONGINT; i: INTEGER;
BEGIN
  NetSystem.ToHost("192.168.1.20", ip, ok); NetSystem.ToNum(ip, s);
  Check("ToHost, ToNum 192.168.1.20", ok & (s = "192.168.1.20"));
  NetSystem.PutLInt(b, 0, -1062731500); NetSystem.GetLInt(b, 0, x);  (* 0C0A80114H *)
  Check("PutLInt, GetLInt: most significant first", (b[0] = CHR(192)) & (b[3] = CHR(20)) & (x = -1062731500));
  NetSystem.ToHost("1.2.3", ip, ok); Check("ToHost 1.2.3 refused", ~ok & (ip = NetSystem.anyIP));
  NetSystem.ToHost("256.1.1.1", ip, ok); Check("ToHost 256.1.1.1 refused", ~ok);
  NetSystem.GetIP("localhost", ip); NetSystem.ToNum(ip, s); Check("GetIP localhost = 127.0.0.1", s = "127.0.0.1");
  NetSystem.GetIP("10.0.0.7", ip); NetSystem.ToNum(ip, s); Check("GetIP 10.0.0.7", s = "10.0.0.7");
  NetSystem.GetIP("zq-no-such-host.invalid", ip); Check("GetIP of no host = anyIP", ip = NetSystem.anyIP);
  NetSystem.PutInt(b, 0, -2); NetSystem.GetInt(b, 0, i);
  Check("PutInt, GetInt -2", (b[0] = 0FFX) & (b[1] = 0FEX) & (i = -2));
  NetSystem.ToNum(NetSystem.hostIP, s);
  Out.String("     host "); Out.String(NetSystem.hostName); Out.String(" "); Out.String(s); Out.Ln
END Addresses;

PROCEDURE TCP;
VAR L, C, S: NetSystem.Connection; res, i, port: INTEGER; ip, lo: NetSystem.IPAdr; ok: BOOLEAN;
  s: ARRAY 64 OF CHAR; x: LONGINT; buf, got: ARRAY 10000 OF CHAR; n: LONGINT;
BEGIN
  NetSystem.OpenConnection(L, Port, NetSystem.anyIP, NetSystem.anyport, res);
  Check("listen", (res = NetSystem.done) & (NetSystem.State(L) = NetSystem.listening));
  Check("no request yet", ~NetSystem.Requested(L));
  NetSystem.ToHost("127.0.0.1", lo, ok);
  NetSystem.OpenConnection(C, NetSystem.anyport, lo, Port, res);
  Check("connect", (res = NetSystem.done) & (NetSystem.State(C) = NetSystem.inout));
  Check("requested", NetSystem.Requested(L));
  NetSystem.Accept(L, S, res);
  Check("accept", (res = NetSystem.done) & (NetSystem.State(S) = NetSystem.inout));
  NetSystem.GetPartner(S, ip, port); NetSystem.ToNum(ip, s); Check("partner 127.0.0.1", s = "127.0.0.1");
  NetSystem.GetPartner(C, ip, port); Check("partner port", port = Port);
  Check("nothing available", NetSystem.Available(S) = 0);

  NetSystem.WriteString(C, "HELLO server"); NetSystem.WriteInt(C, -300); NetSystem.WriteLInt(C, -123456789);
  NetSystem.WriteLInt(C, 7FFFFFFFH); NetSystem.Write(C, "z");
  Check("writes", C.res = NetSystem.done);
  NetSystem.ReadString(S, s); Check("ReadString without CRLF", s = "HELLO server");
  NetSystem.ReadInt(S, i); Check("ReadInt -300", i = -300);
  NetSystem.ReadLInt(S, x); Check("ReadLInt -123456789", x = -123456789);
  NetSystem.ReadLInt(S, x); Check("ReadLInt 7FFFFFFFH", x = 7FFFFFFFH);
  Check("one byte available", NetSystem.Available(S) = 1);
  NetSystem.Read(S, s[0]); Check("Read z", s[0] = "z");

  (* 10000 bytes from pos 5 *)
  i := 0; WHILE i < LEN(buf) DO buf[i] := CHR(i MOD 251); got[i] := 0X; INC(i) END;
  NetSystem.WriteBytes(S, 5, 9000, buf); Check("WriteBytes 9000", S.res = NetSystem.done);
  NetSystem.ReadBytes(C, 100, 9000, got); ok := C.res = NetSystem.done;
  i := 0; WHILE ok & (i < 9000) DO ok := got[100 + i] = buf[5 + i]; INC(i) END;
  Check("ReadBytes 9000 at 100", ok & (got[99] = 0X) & (got[9100] = 0X));

  NetSystem.CloseConnection(C);
  Check("closed", NetSystem.State(C) = NetSystem.closed);
  n := 0; WHILE (NetSystem.State(S) = NetSystem.inout) & (n < 100) DO Platform.Delay(10); INC(n) END;
  Check("server sees the end: out", NetSystem.State(S) = NetSystem.out);
  NetSystem.Read(S, s[0]); Check("Read after the end: error", S.res = NetSystem.error);
  NetSystem.CloseConnection(S); NetSystem.CloseConnection(L);
  Check("listener closed", NetSystem.State(L) = NetSystem.closed);
  NetSystem.OpenConnection(C, NetSystem.anyport, lo, Port, res);
  Check("connect to a closed port: error", res = NetSystem.error)
END TCP;

PROCEDURE UDP;
VAR A, B: NetSystem.Socket; res, port: INTEGER; lo, ip: NetSystem.IPAdr; ok: BOOLEAN;
  buf, got: ARRAY 100 OF CHAR; len, n: LONGINT;
BEGIN
  NetSystem.OpenSocket(A, UPort1, res); Check("open UDP socket", res = NetSystem.done);
  NetSystem.OpenSocket(B, UPort2, res); Check("open second UDP socket", res = NetSystem.done);
  NetSystem.ReceiveDG(B, ip, port, 0, len, got); Check("no datagram: len -1", (len = -1) & (B.res = NetSystem.error));
  NetSystem.ToHost("127.0.0.1", lo, ok);
  buf := "xxdatagram 1";
  NetSystem.SendDG(A, lo, UPort2, 2, 10, buf); Check("SendDG", A.res = NetSystem.done);
  n := 0; WHILE (NetSystem.AvailableDG(B) = 0) & (n < 100) DO Platform.Delay(10); INC(n) END;
  Check("AvailableDG 10", NetSystem.AvailableDG(B) = 10);
  NetSystem.ReceiveDG(B, ip, port, 3, len, got); got[3 + len] := 0X;
  Check("ReceiveDG at 3", (B.res = NetSystem.done) & (len = 10) & (got[3] = "d") & (got[12] = "1"));
  Check("sender port", port = UPort1);
  NetSystem.CloseSocket(A); NetSystem.CloseSocket(B)
END UDP;

PROCEDURE Passwords;
VAR user, pw: ARRAY 64 OF CHAR;
BEGIN
  NetSystem.SetPassword("ftp", "zq", "Example.ORG", "secret");
  user := ""; NetSystem.GetPassword("FTP", "example.org", user, pw);
  Check("GetPassword, any user", (user = "zq") & (pw = "secret"));
  NetSystem.DelPassword("ftp", "zq", "example.org");
  user := "zq"; NetSystem.GetPassword("ftp", "example.org", user, pw);
  Check("deleted", (user = "") & (pw = ""))
END Passwords;

PROCEDURE Net;
VAR C: NetSystem.Connection; ip: NetSystem.IPAdr; res: INTEGER; s: ARRAY 256 OF CHAR; lines: LONGINT;
BEGIN
  NetSystem.GetIP("example.com", ip); NetSystem.ToNum(ip, s);
  Out.String("     example.com "); Out.String(s); Out.Ln;
  Check("GetIP example.com", ip # NetSystem.anyIP);
  NetSystem.OpenConnection(C, NetSystem.anyport, ip, 80, res);
  Check("connect example.com:80", res = NetSystem.done);
  IF res = NetSystem.done THEN
    NetSystem.WriteString(C, "GET / HTTP/1.0"); NetSystem.WriteString(C, "Host: example.com");
    NetSystem.WriteString(C, "");
    NetSystem.ReadString(C, s); Out.String("     "); Out.String(s); Out.Ln;
    Check("HTTP/1.x 200", (s[0] = "H") & (s[9] = "2") & (s[10] = "0") & (s[11] = "0"));
    lines := 1;
    WHILE (NetSystem.State(C) IN {NetSystem.in, NetSystem.inout}) OR (NetSystem.Available(C) > 0) DO
      NetSystem.ReadString(C, s); IF C.res = NetSystem.done THEN INC(lines) END
    END;
    Out.String("     "); Out.Int(lines, 0); Out.String(" lines"); Out.Ln;
    Check("read to the end", lines > 5);
    NetSystem.CloseConnection(C)
  END
END Net;

BEGIN
  checks := 0; fails := 0; Args.Get(1, arg);
  Addresses; TCP; UDP; Passwords;
  IF arg = "net" THEN Net END;
  NetSystem.Show;
  Out.String("testNetSystem: "); Out.Int(checks, 0); Out.String(" checks, "); Out.Int(fails, 0); Out.String(" failed"); Out.Ln;
  IF fails # 0 THEN Platform.Exit(1) END
END testNetSystem.
