MODULE Internet; (*noch 14.4.2017 / 14.4.2017*)
IMPORT netSockets, netdb, netTypes, Strings, Out, Platform, IntStr := oocIntStr, SYSTEM;

TYPE

  Socket* = LONGINT; (* INT32 *)

  Int16 = netTypes.Int16;
  Int32 = netTypes.Int32;
  Int64 = netTypes.Int64;

PROCEDURE -A002 "#include <netdb.h>";

PROCEDURE Write*(VAR fd: Socket; buf: ARRAY OF CHAR): BOOLEAN;
VAR
   l: SYSTEM.ADDRESS;
   r: INTEGER;
   len: LONGINT;
BEGIN
  l := SYSTEM.ADR(buf[0]);
  len := Strings.Length(buf);
  Out.String("Client attempting to write: "); Out.String(buf); Out.Ln;
  Out.String("Buffer length: "); Out.Int(len, 0); Out.Ln;
  Out.String("Address of buffer: "); Out.Hex(SYSTEM.VAL(SYSTEM.INT64, l), 16); Out.Ln;

  r := Platform.Write(fd, l, len);

  IF r = -1 THEN
    Out.String("Client write() failed with error code: ");
    r := Platform.Error();
    Out.Int(r, 0); Out.Ln;
    RETURN FALSE
  ELSE
    Out.String("Client write() succeeded."); Out.Ln;
    RETURN TRUE
  END;
END Write;

PROCEDURE ReadBuf*(VAR fd: Socket; VAR buf: ARRAY OF CHAR; VAR n: LONGINT): BOOLEAN;
VAR
  r : INTEGER;
BEGIN
  Out.String("entered ReadBuf"); Out.Ln;
  r := Platform.ReadBuf(fd, buf, n); (* returns buffer length as n *)
  Out.String("ReadBuf() called. Result: "); Out.Int(r, 0); Out.String(", Bytes read: "); Out.Int(n, 0); Out.Ln;

  IF n > 0 THEN
    Out.String("Data read into buffer: "); Out.String(buf); Out.Ln;
  ELSE
    Out.String("No data read."); Out.Ln;
  END;

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
  Out.String("Reading from socket..."); Out.Ln;
  Out.String("Buffer address: "); Out.Hex(SYSTEM.VAL(SYSTEM.INT64, p), 16); Out.Ln;
  Out.String("Buffer length: "); Out.Int(l, 0); Out.Ln;

  IF p = 0 THEN
    Out.String("Error: Buffer address is 0!"); Out.Ln;
    HALT(10); (* Use a positive value within the allowed range *)
  END;

  r := Platform.Read(fd, p, l, f);
  Out.String("Read result: "); Out.Int(r, 0); Out.Ln;

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
  Out.String("entered ReadBytes"); Out.Ln;
  p := SYSTEM.ADR(buf[0]);
  l := LEN(buf)-1;
  f := 0;
  IF l < count THEN Out.String("warning, more bytes requested than the buffer has"); Out.Ln; count := l END;
  r := Platform.Read(fd, p, count, f);
     buf[l] := 0X;
  IF r >= 0 THEN RETURN TRUE ELSE RETURN FALSE END
END ReadBytes;

PROCEDURE Connect*(host, port: ARRAY OF CHAR; VAR conn: Socket): BOOLEAN;
VAR
  hints, res: netdb.addrInfo;
  pres: netdb.PaddrInfo;
  tmp32: netdb.Int32;
  aiFamily, aiSockType, aiProtocol: INTEGER;
  errno: Platform.ErrorCode;
  aiAddrLen: INTEGER;
BEGIN
  hints.aiFamily := netSockets.AfUnspec;
  hints.aiSockType := netSockets.SockStream;
  hints.aiFlags := 0;
  hints.aiProtocol := netdb.ipprotoTCP;
  hints.aiAddrLen := 0;
  hints.aiAddr := 0;
  hints.aiCanonName := 0;
  hints.aiNext := 0;

  pres := SYSTEM.VAL(netdb.PaddrInfo, SYSTEM.ADR(res));
  tmp32 := netdb.getAddrInfo(host, port, SYSTEM.ADR(hints), SYSTEM.ADR(pres));

  IF tmp32 # 0 THEN
    Out.String("getaddrinfo() failed"); Out.Ln;
    HALT(1);
  ELSE
    Out.String("getaddrinfo() returned 0, success"); Out.Ln;
  END;

  (* Extract and log values for debugging *)
  aiFamily := SYSTEM.VAL(INTEGER, pres^.aiFamily);
  aiSockType := SYSTEM.VAL(INTEGER, pres^.aiSockType);
  aiProtocol := SYSTEM.VAL(INTEGER, pres^.aiProtocol);
  aiAddrLen := SYSTEM.VAL(INTEGER, pres^.aiAddrLen);

  Out.String("aiFamily: "); Out.Int(aiFamily, 0);
  Out.String(", aiSockType: "); Out.Int(aiSockType, 0);
  Out.String(", aiProtocol: "); Out.Int(aiProtocol, 0); Out.Ln;
  Out.String("aiAddrLen: "); Out.Int(aiAddrLen, 0); Out.Ln;

  (* Create the socket *)
  conn := netSockets.Socket(aiFamily, aiSockType, aiProtocol);

  IF conn = -1 THEN
    Out.String("socket() returned -1, error."); Out.Ln;
    errno := Platform.Error();
    Out.String("Error code: "); Out.Int(errno, 0); Out.Ln;
    HALT(2);
  ELSE
    Out.String("socket() succeeded."); Out.Ln;
  END;

  IF pres = NIL THEN
    Out.String("Error: pres pointer is NIL."); Out.Ln;
    HALT(3);
  END;

  IF pres^.aiAddr = 0 THEN
    Out.String("Error: pres^.aiAddr is NIL."); Out.Ln;
    HALT(4);
  ELSE
    Out.String("aiAddr is valid for connection."); Out.Ln;
    Out.String("aiAddr address: "); Out.Hex(SYSTEM.VAL(INTEGER, pres^.aiAddr), 8); Out.Ln;
  END;

  (* Attempt to connect *)
  tmp32 := netSockets.Connect(conn, pres^.aiAddr, aiAddrLen);

  IF tmp32 # 0 THEN
    Out.String("connect() failed with error code: ");
    Out.Int(tmp32, 0); Out.Ln;
    errno := Platform.Error();
    Out.String("Connect error code: "); Out.Int(errno, 0); Out.Ln;
    HALT(5);
  ELSE
    Out.String("connect() succeeded."); Out.Ln;
  END;

  (* Free the address info structure after the connection attempt *)
  IF pres # NIL THEN
    Out.String("trying to free addrinfo"); Out.Ln;
    netdb.freeAddrInfo(SYSTEM.VAL(SYSTEM.ADDRESS, pres));
    Out.String("Addrinfo freed"); Out.Ln;
  ELSE
    Out.String("Skipping freeAddrInfo as pres is NIL."); Out.Ln;
  END;

  RETURN TRUE
END Connect;

PROCEDURE -shtdwn (fd: Socket)
  "shutdown (fd, 2)";

PROCEDURE Disconnect*(fd: Socket);
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
