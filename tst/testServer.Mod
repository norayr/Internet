MODULE testServer;
IMPORT server, Internet, Out, Platform;

VAR s: server.server;

PROCEDURE DoSmth(VAR s: server.server);
VAR
  str, aff: ARRAY 256 OF CHAR;
  n:   LONGINT;
BEGIN
  aff := "Affirmative, Dave";
  REPEAT
    IF ~Internet.ReadBuf(s^.newsockfd, str, n) THEN
      Out.String("error reading from socket"); Out.Ln;
    ELSE
      str[n] := 0X; (* Make sure that received message is zero terminated *)
      Out.String("received message is "); Out.String(str); Out.Ln;

      IF ~Internet.Write(s^.newsockfd, aff) THEN
        Out.String("error writing to socket"); Out.Ln
      END;
    END;
    Platform.Delay(500);
  UNTIL str = "bye";
  Internet.Disconnect(s^.newsockfd);
END DoSmth;

BEGIN
s := server.Create();
server.setPort(s, 2023);
server.setMaxQueue(s, 5);
server.setHandler(s, DoSmth);

server.start(s);
server.serve(s);

END testServer.
