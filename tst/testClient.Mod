MODULE testClient;
IMPORT Internet, Out;

VAR
  sock: Internet.Socket;
   str: ARRAY 32 OF CHAR;
BEGIN

IF Internet.Connect("127.0.0.1", "2023", sock) THEN
  IF Internet.Write(sock, "hello dave") THEN
    IF Internet.Read(sock, str) THEN
      Out.String(str); Out.Ln;
      Out.String(str); Out.Ln;
    END;
    Internet.Disconnect(sock);
 END;

END;


END testClient.
