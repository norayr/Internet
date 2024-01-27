MODULE Internet; (*noch 14.4.2017 / 14.4.2017*)
IMPORT netSockets, netdb, netTypes, Strings, Out, Platform, IntStr := oocIntStr, SYSTEM;

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
  r := Platform.Write(fd, l, len);
  IF r = -1 THEN
    (*Out.String("write() failed."); Out.Ln;*)
    RETURN FALSE
  ELSE
    (*Out.String("write() success."); Out.Ln;*)
    RETURN TRUE
  END;
END Write;

PROCEDURE ReadBuf*(VAR fd: Socket; VAR buf: ARRAY OF CHAR; VAR n: LONGINT): BOOLEAN;
VAR
  r : INTEGER;
BEGIN
  r := Platform.ReadBuf(fd, buf, n); (* returns buffer length as n *)
  IF r # 0 THEN RETURN FALSE ELSE RETURN TRUE END
END ReadBuf;

PROCEDURE Read*(VAR fd: Socket; VAR buf: ARRAY OF CHAR): BOOLEAN;
VAR
  p: SYSTEM.ADDRESS;
  l, f: LONGINT;
  r: INTEGER;
BEGIN
  p := SYSTEM.ADR(buf[0]);
  l := LEN(buf)-1;
  f := 0;
  r := Platform.Read(fd, p, l, f);
  IF r >= 0 THEN RETURN TRUE ELSE RETURN FALSE END
END Read;

PROCEDURE ReadBytes*(VAR fd: Socket; VAR buf: ARRAY OF CHAR; count: LONGINT): BOOLEAN;
VAR
  p: SYSTEM.ADDRESS;
  l, f: LONGINT;
  r: INTEGER;
BEGIN
  p := SYSTEM.ADR(buf[0]);
  l := LEN(buf)-1;
  f := 0;
  Out.String("count is "); Out.Int(count, 0); Out.Ln;
  Out.String("len buf is "); Out.Int(l, 0); Out.Ln;
  IF l < count THEN Out.String("warning, more bytes requested than the buffer has"); Out.Ln; count := l END;
  r := Platform.Read(fd, p, count, f);
  IF r >= 0 THEN RETURN TRUE ELSE RETURN FALSE END
END ReadBytes;

PROCEDURE Connect*(host, port: ARRAY OF CHAR; VAR conn: Socket): BOOLEAN;
VAR
  hints, res : netdb.addrInfo;
  pres, pres2, phints: netdb.PaddrInfo;
  tmpaddr : SYSTEM.ADDRESS;
  tmp32 : netdb.Int32;
  (*conn : netdb.Int32;*)
BEGIN
  hints.aiFamily := netSockets.AfUnspec;
  hints.aiSockType := netSockets.SockStream;
  hints.aiFlags := 0;
  hints.aiProtocol := netdb.ipprotoTCP;
  hints.aiAddrLen := 0;
  hints.aiAddr := 0; hints.aiCanonName := 0; hints.aiNext := 0;

  phints := SYSTEM.VAL(netdb.PaddrInfo, SYSTEM.ADR(hints));
  pres := SYSTEM.VAL(netdb.PaddrInfo, SYSTEM.ADR(res));
  pres2 := SYSTEM.VAL(netdb.PaddrInfo, SYSTEM.ADR(pres));

  tmp32 := netdb.getAddrInfo(host, port, phints, pres2);

  IF tmp32 # 0 THEN
    Out.String("getaddrinfo() failed"); Out.Ln;
    HALT(1);
  ELSE
    Out.String("getaddrinfo() returned 0, success"); Out.Ln;
  END;

  conn := netSockets.Socket(pres^.aiFamily, pres^.aiSockType, pres^.aiProtocol);

  IF conn = -1 THEN
    Out.String("socket() returned -1, error"); Out.Ln;
    HALT(1);
  ELSE
    Out.String("socket() succeeded."); Out.Ln;
  END;

  tmpaddr := SYSTEM.ADR(pres^.aiAddr);

  tmp32 := netSockets.Connect(conn, pres^.aiAddr, pres^.aiAddrLen);
  netdb.freeAddrInfo(pres);
  IF tmp32 = 0 THEN
    Out.String("connect() succeeded."); Out.Ln;
    RETURN TRUE
  ELSE
    Out.String("connect() failed."); Out.Ln;
    RETURN FALSE
  END;
END Connect;

PROCEDURE -shtdwn (VAR fd: Socket)
  "shutdown (fd, 2)";

PROCEDURE Disconnect*(VAR fd: Socket);
VAR
  i : INTEGER;
BEGIN
  (*i := Platform.Close(fd);*)
  shtdwn(fd)
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
