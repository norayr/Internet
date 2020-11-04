MODULE server;

IMPORT netForker, netSockets, Out, SYSTEM, Platform, Strings;

CONST
  defaultPort = 2055;
  defaultMaxQ = 64;
  msgNotInitialized = "server was not created, nil pointer received";

TYPE

      handler* = PROCEDURE(sock: Platform.FileHandle);

      server = RECORD
        Port : INTEGER;
    MaxQueue : INTEGER;
    sockfd   : LONGINT;
   newsockfd : LONGINT;
    ServAddr : netSockets.SockAddrIn;
         pid : LONGINT;
         res : Platform.ErrorCode;
 sockaddrlen : LONGINT;
      handle : handler
      END;

PROCEDURE Create*(): server;
VAR s: server;
BEGIN
  NEW(s);
  s.Port := defaultPort;
  s.MaxQueue := defaultMaxQ; 
END Create;

PROCEDURE setHandler*(VAR s: server; h: handler);
begin
  IF s # NIL THEN
    s.handle := h
  ELSE
    Out.String(msgNotInitialized); Out.Ln
  END;
END setHandler;

PROCEDURE setPort*(VAR s: server; p: INTEGER);
BEGIN
  IF s # NIL THEN
    s.Port := p
  ELSE
    Out.String(msgNotInitialized); Out.Ln
  END
END setPort;

PROCEDURE setMaxQueue*(VAR s: server; p: INTEGER);
BEGIN
  IF s # NIL THEN
    s.MaxQueue := p
  ELSE
    Out.String(msgNotInitialized); Out.Ln
  END
END setMaxQueue;

PROCEDURE start*(VAR s: server);
BEGIN
  s.sockfd := netSockets.Socket(netSockets.AfInet, netSockets.SockStream, 0);
  IF s.sockfd < 0 THEN
    Out.String("error opening socket")
  ELSE
    Out.String("socket created.")
  END;
  Out.Ln;

  netSockets.SetSockAddrIn(netSockets.AfInet, s.Port, 0, ServAddr);

  IF netSockets.Bind(sockfd, SYSTEM.VAL(netSockets.SockAddr, ServAddr), SIZE(netSockets.SockAddr)) < 0 THEN
    Out.String("error on binding")
  ELSE
    Out.String("binding completed.")
  END;
  Out.Ln;
    
  IF netSockets.Listen(s.sockfd, s.MaxQueue) # 0 THEN
    Out.String("listen() failed");
  ELSE
    Out.String("listen okay");
  END;
  Out.Ln;
END start;

PROCEDURE serve*(VAR s: server);
BEGIN
  LOOP
    s.sockaddrlen := SIZE(netSockets.SockAddrIn);
    s.newsockfd := netSockets.Accept(sockfd, SYSTEM.VAL(netSockets.SockAddr, ServAddr), sockaddrlen);
    IF newsockfd < 0 THEN
      Out.String("error on accept")
    ELSE
      Out.String("accept okay")
    END;
    Out.Ln;

    s.pid := netForker.fork();
    IF s.pid < 0 THEN
      Out.String("error on fork")
    ELSIF pid = 0 THEN
      Out.String("forked okay"); Out.Ln;
      res := Platform.Close(sockfd);
      s.handle(newsockfd);
      EXIT
    ELSE
      res := Platform.Close(newsockfd)
    END
  END
END serve;

PROCEDURE DoSmth(sock: Platform.FileHandle);
VAR 
  str, aff: ARRAY 256 OF CHAR;
  n:   LONGINT;
BEGIN
  aff := "Affirmative, Dave";
(*  IF Platform.Read(sock, SYSTEM.ADR(str), 256, n) # 0 THEN *)
  IF Platform.ReadBuf(sock, str, n) # 0 THEN
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


END server.
