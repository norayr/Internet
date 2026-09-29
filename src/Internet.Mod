MODULE Internet; (*noch 14.4.2017 / 14.4.2017*)
(* The old interface, now over polpo's Sockets and DNS (Sockets.Mod and DNS.Mod are the files
   of polpo, src/lib/sockets and src/lib/dns, unchanged; Linux0 and Kernel give them the few
   calls they need here): Connect takes host names and IPv6, and returns FALSE instead of
   halting. New code can use Sockets and DNS directly, the same as in polpo. *)
IMPORT Sockets, DNS, Linux0, netSockets, netTypes, Strings, Out, Platform, IntStr := oocIntStr, SYSTEM;

TYPE

  Socket* = LONGINT; (* INT32 *)

  Int16 = netTypes.Int16;
  Int32 = netTypes.Int32;
  Int64 = netTypes.Int64;

PROCEDURE Write*(VAR fd: Socket; buf: ARRAY OF CHAR): BOOLEAN;
VAR
   l: SYSTEM.ADDRESS;
   r: INTEGER;
   len: LONGINT;
BEGIN
  l := SYSTEM.ADR(buf[0]);
  len := Strings.Length(buf);
  (*
  Out.String("Client attempting to write: "); Out.String(buf); Out.Ln;
  Out.String("Buffer length: "); Out.Int(len, 0); Out.Ln;
  Out.String("Address of buffer: "); Out.Hex(SYSTEM.VAL(SYSTEM.INT64, l), 16); Out.Ln;
  *)
  r := Platform.Write(fd, l, len);

  IF r = -1 THEN
    Out.String("Client write() failed with error code: ");
    r := Platform.Error();
    Out.Int(r, 0); Out.Ln;
    RETURN FALSE
  ELSE
    (* Out.String("Client write() succeeded."); Out.Ln; *)
    RETURN TRUE
  END;
END Write;

PROCEDURE ReadBuf*(VAR fd: Socket; VAR buf: ARRAY OF CHAR; VAR n: LONGINT): BOOLEAN;
VAR
  r : INTEGER;
BEGIN
  (* Out.String("entered ReadBuf"); Out.Ln; *)
  r := Platform.ReadBuf(fd, buf, n); (* returns buffer length as n *)
  (* Out.String("ReadBuf() called. Result: "); Out.Int(r, 0); Out.String(", Bytes read: "); Out.Int(n, 0); Out.Ln; *)
  (*
  IF n > 0 THEN
    Out.String("Data read into buffer: "); Out.String(buf); Out.Ln;
  ELSE
    Out.String("No data read."); Out.Ln;
  END;
  *)
  IF r # 0 THEN
    RETURN FALSE
  ELSE
    RETURN TRUE
  END
END ReadBuf;

PROCEDURE Read*(VAR fd: Socket; VAR buf: ARRAY OF CHAR): BOOLEAN;
VAR
  p: SYSTEM.ADDRESS;
  l, f: LONGINT;
  r: INTEGER;
BEGIN
  p := SYSTEM.ADR(buf[0]);
  l := LEN(buf) - 1;
  f := 0;
  (*
  Out.String("Reading from socket..."); Out.Ln;
  Out.String("Buffer address: "); Out.Hex(SYSTEM.VAL(SYSTEM.INT64, p), 16); Out.Ln;
  Out.String("Buffer length: "); Out.Int(l, 0); Out.Ln;
  *)

  IF p = 0 THEN
    Out.String("Error: Buffer address is 0!"); Out.Ln;
    HALT(10); (* Use a positive value within the allowed range *)
  END;

  r := Platform.Read(fd, p, l, f);
  (*Out.String("Read result: "); Out.Int(r, 0); Out.Ln;*)

  IF r >= 0 THEN
    RETURN TRUE
  ELSE
    Out.String("Read failed with error."); Out.Ln;
    RETURN FALSE
  END;
END Read;

PROCEDURE ReadBytes*(VAR fd: Socket; VAR buf: ARRAY OF CHAR; count: LONGINT): BOOLEAN;
VAR
  p: SYSTEM.ADDRESS;
  l, f: LONGINT;
  r: INTEGER;
BEGIN
  (*Out.String("entered ReadBytes"); Out.Ln;*)
  p := SYSTEM.ADR(buf[0]);
  l := LEN(buf)-1;
  f := 0;
  IF l < count THEN Out.String("warning, more bytes requested than the buffer has"); Out.Ln; count := l END;
  r := Platform.Read(fd, p, count, f);
     buf[l] := 0X;
  IF r >= 0 THEN RETURN TRUE ELSE RETURN FALSE END
END ReadBytes;

(* the port: a number, or http, https *)
PROCEDURE PortNumber(VAR port: ARRAY OF CHAR): LONGINT;
VAR i, n: LONGINT;
BEGIN
  IF port = "http" THEN RETURN 80 ELSIF port = "https" THEN RETURN 443 END;
  n := 0; i := 0;
  WHILE (port[i] >= "0") & (port[i] <= "9") DO n := n * 10 + ORD(port[i]) - ORD("0"); INC(i) END;
  IF (i = 0) OR (port[i] # 0X) THEN RETURN -1 END;
  RETURN n
END PortNumber;

(** connect to host (a name, an IPv4 or an IPv6 address) and port; its addresses are tried in turn.
  With polpo's DNS and Sockets, as in polpo. *)
PROCEDURE Connect*(host, port: ARRAY OF CHAR; VAR conn: Socket): BOOLEAN;
VAR a: ARRAY 8 OF Sockets.Address; n, i, p: LONGINT; s: Sockets.Socket;
BEGIN
  conn := -1;
  p := PortNumber(port);
  IF p < 0 THEN Out.String("Internet.Connect: bad port "); Out.String(port); Out.Ln; RETURN FALSE END;
  DNS.Lookup(host, DNS.Any, a, n);
  IF n = 0 THEN
    Out.String("Internet.Connect: "); Out.String(host);
    IF DNS.res = DNS.NotFound THEN Out.String(" not found") ELSE Out.String(": no answer from the name servers") END;
    Out.Ln; RETURN FALSE
  END;
  i := 0; s := NIL;
  WHILE (s = NIL) & (i < n) DO s := Sockets.Connect(a[i], p); INC(i) END;
  IF s = NIL THEN
    Out.String("Internet.Connect: connect() failed, error "); Out.Int(-Sockets.res, 0); Out.Ln; RETURN FALSE
  END;
  conn := s.fd;
  RETURN TRUE
END Connect;

(** shut the connection down and close the socket *)
PROCEDURE Disconnect*(fd: Socket);
VAR r: LONGINT;
BEGIN
  r := Linux0.Shutdown0(fd, 2); r := Linux0.Close0(fd)
END Disconnect;

PROCEDURE getClientIP4*(VAR sai: netSockets.SockAddrIn; VAR str: ARRAY OF CHAR);
(* https://stackoverflow.com/questions/3060950/how-to-get-ip-address-from-sock-structure-in-c *)
CONST
  one      = 0FFH;       (* 255 *)
  two      = 0FF00H;     (* 65280 *)
  three    = 0FF0000H;   (* 16711680 *)
  four     = 0FF000000H; (* 4278190080 *)
VAR
  setSAddr : SET;
  set1, set2, set3, set4: SET;
  first, second, third, fourth: SET;
  o1, o2, o3, o4 : LONGINT;
  str0 : ARRAY 4 OF CHAR;
BEGIN
 set1 := SYSTEM.VAL(SET, one);
 set2 := SYSTEM.VAL(SET, two);
 set3 := SYSTEM.VAL(SET, three);
 set4 := SYSTEM.VAL(SET, four);

 setSAddr := SYSTEM.VAL(SET, sai.SinAddr.SAddr);

 first    := setSAddr * set1;
 second   := setSAddr * set2;
 third    := setSAddr * set3;
 fourth   := setSAddr * set4;

 o1 := SYSTEM.VAL(INTEGER, first);
 o2 := SYSTEM.VAL(LONGINT, SYSTEM.LSH(second, -8));
 o3 := SYSTEM.VAL(LONGINT, SYSTEM.LSH(third,  -16));
 o4 := SYSTEM.VAL(LONGINT, SYSTEM.LSH(fourth, -24));

 IntStr.IntToStr(o1, str);
 Strings.Append(".", str);
 IntStr.IntToStr(o2, str0);
 Strings.Append(str0, str);
 Strings.Append(".", str);
 IntStr.IntToStr(o3, str0);
 Strings.Append(str0, str);
 Strings.Append(".", str);
 IntStr.IntToStr(o4, str0);
 Strings.Append(str0, str);

END getClientIP4;
(*
PROCEDURE setNB*(VAR fd: LONGINT): BOOLEAN;
BEGIN
  RETURN netSockets.SetSocketNonBlocking(fd)
END setNB;
*)
END Internet.
