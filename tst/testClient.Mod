MODULE testClient;
IMPORT Platform, Internet, Out;

VAR
  sock: Internet.Socket;
   str: ARRAY 32 OF CHAR;
   i: INTEGER;
   b: BOOLEAN;
BEGIN

  IF Internet.Connect("127.0.0.1", "2023", sock) THEN
    i := 0;
    REPEAT
      IF Internet.Write(sock, "hello dave") THEN
        IF Internet.Read(sock, str) THEN
          Out.String(str); Out.Ln;
        END;
      END;
      Platform.Delay(5000);
      INC(i);
      UNTIL i = 5;
  END;
b := Internet.Write(sock, "bye");
Internet.Disconnect(sock);

END testClient.
