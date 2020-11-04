MODULE testServer;
IMPORT server, Internet, Platform, Out, Strings, SYSTEM;

VAR s: server.server;

PROCEDURE DoSmth(sock: Platform.FileHandle);
VAR
  str, aff: ARRAY 256 OF CHAR;
  n:   LONGINT;
BEGIN
  aff := "Affirmative, Dave";
(*  IF Platform.Read(sock, SYSTEM.ADR(str), 256, n) # 0 THEN *)
  IF ~Internet.ReadBuf(sock, str, n) THEN
    Out.String("error reading from socket"); Out.Ln;
  ELSE
    str[n] := 0X; (* Make sure that received message is zero terminated *)
    Out.String("received message is "); Out.String(str); Out.Ln;

    IF Platform.Write(sock, SYSTEM.ADR(aff), Strings.Length(aff)) # 0 THEN
      Out.String("error writing to socket"); Out.Ln
    END;
  END;
END DoSmth;

BEGIN
s := server.Create();
server.setPort(s, 2023);
server.setMaxQueue(s, 5);
server.setHandler(s, DoSmth);

server.start(s);
server.serve(s);

END testServer.
