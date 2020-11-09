MODULE server;

IMPORT netForker, netSockets, Internet, Out, SYSTEM, Platform, Strings;

CONST
  defaultPort = 2055;
  defaultMaxQ = 64;
  msgNotInitialized = "server was not created, nil pointer received";
  msgHandlerNotSet  = "response handler is not set";

TYPE

     server* = POINTER TO serverDesc;
    handler* = PROCEDURE (VAR s: server);
  serverDesc = RECORD
        Port : INTEGER;
    MaxQueue : INTEGER;
    sockfd   : LONGINT;
  newsockfd* : LONGINT;
    ServAddr : netSockets.SockAddrIn;
   clientIP- : ARRAY 16 OF CHAR;
         pid : LONGINT;
         res : Platform.ErrorCode;
 sockaddrlen : LONGINT;
 timeoutval- : LONGREAL;
      handle : handler
      END;

PROCEDURE -inclSgnl() "#include <signal.h>";
PROCEDURE -ingoreChildExit() "signal(SIGCHLD,SIG_IGN)";
(* if this is not done, exiting child remains zombie unless parent exits *)

PROCEDURE Create*(): server;
VAR s: server;
BEGIN
  NEW(s);
  s^.Port := defaultPort;
  s^.MaxQueue := defaultMaxQ; 
  s^.handle := NIL;
  s^.timeoutval := 60.0;
  RETURN s
END Create;

PROCEDURE setHandler*(VAR s: server; h: handler);
BEGIN
  IF s # NIL THEN
    s^.handle := h
  ELSE
    Out.String(msgNotInitialized); Out.Ln
  END
END setHandler;

PROCEDURE setTimeOut*(VAR s: server; to: LONGREAL);
BEGIN
  s^.timeoutval := to
END setTimeOut;

PROCEDURE setPort*(VAR s: server; p: INTEGER);
BEGIN
  IF s # NIL THEN
    s^.Port := p
  ELSE
    Out.String(msgNotInitialized); Out.Ln
  END
END setPort;

PROCEDURE setMaxQueue*(VAR s: server; p: INTEGER);
BEGIN
  IF s # NIL THEN
    s^.MaxQueue := p
  ELSE
    Out.String(msgNotInitialized); Out.Ln
  END
END setMaxQueue;

PROCEDURE start*(VAR s: server);
BEGIN
  IF s^.handle = NIL THEN
    Out.String(msgHandlerNotSet); Out.Ln; HALT(1);
  END;
  s^.sockfd := netSockets.Socket(netSockets.AfInet, netSockets.SockStream, 0);
  IF s^.sockfd < 0 THEN
    Out.String("error opening socket")
  ELSE
    Out.String("socket created.")
  END;
  Out.Ln;

  netSockets.SetSockAddrIn(netSockets.AfInet, s^.Port, 0, s^.ServAddr);

  IF netSockets.Bind(s^.sockfd, SYSTEM.VAL(netSockets.SockAddr, s^.ServAddr), SIZE(netSockets.SockAddr)) < 0 THEN
    Out.String("error on binding")
  ELSE
    Out.String("binding completed.")
  END;
  Out.Ln;
    
  IF netSockets.Listen(s^.sockfd, s^.MaxQueue) # 0 THEN
    Out.String("listen() failed");
  ELSE
    Out.String("listen okay");
  END;
  Out.Ln;
END start;

PROCEDURE serve*(VAR s: server; newNonBlock: BOOLEAN);
VAR
  nb: BOOLEAN;
BEGIN
     
  LOOP
    s^.sockaddrlen := SIZE(netSockets.SockAddrIn);
(* linux only way would be this *)
(*    IF newNonBlock THEN
      s^.newsockfd := netSockets.AcceptNB(s^.sockfd, SYSTEM.VAL(netSockets.SockAddr, s^.ServAddr), s^.sockaddrlen);
    ELSE
      s^.newsockfd := netSockets.Accept(s^.sockfd, SYSTEM.VAL(netSockets.SockAddr, s^.ServAddr), s^.sockaddrlen);
    END;*)

      (* portable way is this *)
      s^.newsockfd := netSockets.Accept(s^.sockfd, SYSTEM.VAL(netSockets.SockAddr, s^.ServAddr), s^.sockaddrlen);

    IF s^.newsockfd < 0 THEN
      Out.String("error on accept")
    ELSE
      Out.String("accept okay")
    END;
    Out.Ln;
    Out.String(s^.clientIP); Out.Ln;
    s^.pid := netForker.fork();
    IF s^.pid < 0 THEN
      Out.String("error on fork")
    ELSIF s^.pid = 0 THEN (* child *)

      (* portable way *)
      IF newNonBlock THEN
        nb := netSockets.SetSocketNonBlocking(s^.newsockfd);
      END;
      IF nb THEN Out.String("socket set as non-blocking");
      ELSE Out.String("setting socket as non-blocking failed");
      END; Out.Ln;
 


      Out.String("forked okay"); Out.Ln;
      Internet.getClientIP4(s^.ServAddr, s^.clientIP);
      (* getting current pid *)
      s^.pid := Platform.PID;
      s^.res := Platform.Close(s^.sockfd);
      s^.handle(s);
      EXIT
    ELSE
      s^.res := Platform.Close(s^.newsockfd)
    END
  END
END serve;

BEGIN
  ingoreChildExit()
END server.
