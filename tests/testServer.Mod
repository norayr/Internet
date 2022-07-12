MODULE testServer;
IMPORT time, server, Internet, Out, Platform;

VAR s: server.server;

PROCEDURE DoSmth(VAR s: server.server);
VAR
  str, aff: ARRAY 256 OF CHAR;
  n:   LONGINT;
  startTime, endTime: time.unxTime;
  dfTime: LONGREAL;
  keep: BOOLEAN;
BEGIN
  keep := TRUE;
  time.unixTime(startTime);
  aff := "Affirmative, Dave";
  REPEAT
    (*Out.String("client IP: ");
    Out.String(s^.clientIP); Out.String(" ; ");
    Out.String("reading from client"); Out.Ln;*)
    IF ~Internet.ReadBuf(s^.newsockfd, str, n) THEN
      (*Out.String("no message"); Out.Ln;*)
      time.unixTime(endTime);
    ELSE
      time.unixTime(startTime);
      Out.String("got message from client"); Out.Ln;
      str[n] := 0X; (* Make sure that received message is zero terminated *)
      Out.String("received message is "); Out.String(str); Out.Ln;
      IF str = "bye" THEN keep := FALSE END;
      IF ~Internet.Write(s^.newsockfd, aff) THEN
        Out.String("error writing to socket"); Out.Ln
      END;
    END;
    time.unixTime(endTime);
    dfTime := time.unixTimeDiff(endTime, startTime);
    IF dfTime > s.timeoutval THEN keep := FALSE END;
    (*Out.String("waiting a bit..."); Out.Ln;*)
    Platform.Delay(500);
  UNTIL ~keep;
  Out.String("connection closed, exiting"); Out.Ln;
  Internet.Disconnect(s^.newsockfd);
  Out.String("disconnected"); Out.Ln; Out.Ln;
  HALT(0);
END DoSmth;

BEGIN
s := server.Create();
server.setPort(s, 2023);
server.setMaxQueue(s, 5);
server.setTimeOut(s, 10.0);
server.setHandler(s, DoSmth);

server.start(s);
server.serve(s, TRUE);

END testServer.
