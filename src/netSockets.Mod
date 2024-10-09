MODULE netSockets; (*noch 23.2.2017 / 14.4.2017*)
IMPORT netTypes, SYS := SYSTEM;

TYPE
     Int8* = netTypes.Int8; (* INTEGER on 32 bit platform *)
     Int16* = netTypes.Int16; (* INTEGER on 32 bit platform *)
     Int32* = netTypes.Int32;
     Int64* = netTypes.Int64;

CONST
   SockStream*    = 1;
   SockDgram*     = 2;
   SockRaw*       = 3;
   SockRdm*       = 4;
   SockSeqpacket* = 5;
   SockDccp*      = 6;
   SockPacket*    = 10;

   AfUnspec*    = 0;      (* Unspecified.  *)
   AfLocal*     = 1;      (* Local to host (pipes and file-domain).  *)
   AfUnix*      = 1;      (* POSIX name for PF_LOCAL.  *)
   AfFile*      = 1;      (* Another non-standard name for PF_LOCAL.  *)
   AfInet*      = 2;      (* IP protocol family.  *)
   AfAx25*      = 3;      (* Amateur Radio AX.25.  *)
   AfIpx*       = 4;      (* Novell Internet Protocol.  *)
   AfAppletalk* = 5;   (* Appletalk DDP.  *)
   AfNetrom*    = 6;      (* Amateur radio NetROM.  *)
   AfBridge*    = 7;      (* Multiprotocol bridge.  *)
   AfAtmpvc*    = 8;      (* ATM PVCs.  *)
   AfX25*       = 9;      (* Reserved for X.25 project.  *)
   AfInet6*     = 10;     (* IP version 6.  *)
   AfRose*      = 11;     (* Amateur Radio X.25 PLP.  *)
   AfDecnet*    = 12;     (* Reserved for DECnet project.  *)
   AfNetbeui*   = 13;     (* Reserved for 802.2LLC project.  *)
   AfSecurity*  = 14;     (* Security callback pseudo AF.  *)
   AfKey*       = 15;     (* PF_KEY key management API.  *)
   AfNetlink*   = 16;
   AfRoute*     = 16;     (* Alias to emulate 4.4BSD.  *)
   AfPacket     = 17;     (* Packet family.  *)
   AfAsh        = 18;     (* Ash.  *)
   AfEconet*    = 19;     (* Acorn Econet.  *)
   AfAtmsvc*    = 20;     (* ATM SVCs.  *)
   AfRds*       = 21;     (* RDS sockets.  *)
   AfSna        = 22;     (* Linux SNA Project *)
   AfIrda*      = 23;     (* IRDA sockets.  *)
   AfPppox      = 24;     (* PPPoX sockets.  *)
   AfWanpipe*   = 25;     (* Wanpipe API sockets.  *)
   AfLlc*       = 26;     (* Linux LLC.  *)
   AfCan*       = 29;     (* Controller Area Network.  *)
   AfTipc*      = 30;     (* TIPC sockets.  *)
   AfBluetooth* = 31;  (* Bluetooth sockets.  *)
   AfIucv*   = 32;     (* IUCV sockets.  *)
   AfRxrpc*  = 33;     (* RxRPC sockets.  *)
   AfIsdn*   = 34;     (* mISDN sockets.  *)
   AfPhonet* = 35;     (* Phonet sockets.  *)
   AfIeee802154* = 36; (* IEEE 802.15.4 sockets.  *)
   AfCaif*   = 37;     (* CAIF sockets.  *)
   AfAlg*    = 38;     (* Algorithm sockets.  *)
   AfNfc*    = 39;     (* NFC sockets.  *)
   AfVsock*  = 40;     (* vSockets.  *)
   AfMax*    = 41;     (* For now..  *)

   InAddrAny* = 0;

TYPE

   (* /usr/include/netinet/in.h *)
   InAddr* = RECORD
    SAddr* : Int32;
   END;

   SockAddrIn* = RECORD
    SinFamily* : Int16;
    SinPort*   : Int16;
    SinAddr*   : InAddr;
    SinZero*   : ARRAY 8 OF CHAR;
   END;

   (* /usr/include/sys/socket.h *)

   SockAddr* = RECORD
    SaFamily* : Int16;
    SaData*   : ARRAY 14 OF CHAR
   END;



   (* include socekt *)
   PROCEDURE -A000
      "#include <sys/socket.h>";
   PROCEDURE -A001
      "#include <sys/types.h>";

   PROCEDURE -socket(domain, type, protocol: Int32): Int32
      "(int)socket(domain, type, protocol)";

   PROCEDURE Socket*(domain, type, protocol: Int32): Int32;
   BEGIN
      RETURN socket(domain, type, protocol)
   END Socket;

  PROCEDURE -bind(sockfd: Int32; VAR addr: SockAddr; addrlen: Int32): Int32
      "(int)bind(sockfd, (struct sockaddr*)addr, addrlen)";

   PROCEDURE Bind*(sockfd: Int32; VAR addr: SockAddr; addrlen: Int32): Int32;
   BEGIN
      RETURN bind(sockfd, addr, addrlen)
   END Bind;

   PROCEDURE -listen(sockfd, backlog: Int32): Int32
      "(int)listen(sockfd, backlog)";

   PROCEDURE Listen*(sockfd, backlog: Int32): Int32;
   BEGIN
      RETURN listen(sockfd, backlog)
   END Listen;

   PROCEDURE -accept(sockfd: Int32; VAR addr: SockAddr; VAR addrlen: Int32): Int32
      "(int)accept(sockfd, (struct sockaddr*)addr, addrlen)";

   PROCEDURE -inclFcntl() "#include <fcntl.h>"; (* for O_NONBLOCK *)

   PROCEDURE Accept*(sockfd: Int32; VAR addr: SockAddr; VAR addrlen: Int32): Int32;
   BEGIN
      RETURN accept(sockfd, addr, addrlen)
   END Accept;
(*
   PROCEDURE AcceptNB*(sockfd: Int32; VAR addr: SockAddr; VAR addrlen: Int32): Int32;
   BEGIN
      RETURN acceptnb(sockfd, addr, addrlen)
   END AcceptNB;
*)

    (* int connect(int sockfd, const struct sockaddr *addr,
                   socklen_t addrlen); *)

   PROCEDURE -connect(sockfd: Int32; addr: SYS.ADDRESS; addrlen: Int32): Int32
     "(int)connect(sockfd, (struct sockaddr*)addr, addrlen)";


   PROCEDURE Connect*(sockfd: Int32; sockaddr: SYS.ADDRESS; addrlen: Int32): Int32;
   BEGIN
     RETURN connect(sockfd, sockaddr, addrlen)
   END Connect;

  (* ssize_t recv(int sockfd, void *buf, size_t len, int flags); *)

  PROCEDURE -recv(sockfd: Int32; buf: SYS.ADDRESS; len: Int64; flags: Int32):Int64
    "(HUGEINT)recv(sockfd, buf, len, flags)";

(*
 PROCEDURE -SizeofSockaddr(): INTEGER
    "sizeof(sockaddr)";

  PROCEDURE -Error(msg: ARRAY OF CHAR; len: INTEGER)
    "write(1/*stdout*/, msg, len); char ch = 0xa; write(1, &ch, 1)";

  PROCEDURE sockaddrCheck; (* check for inconsistent usage of sigjmp_buf; better avoid Unix_JmpBuf *)
    VAR x, y: LONGINT;
  BEGIN
    x := SizeofSockaddr();
    y := SIZE(SockAddr);
    IF x # y THEN
      Error("sockets.sockaddrCheck: inconsistent usage of sockaddr", 52);
      HALT(1);
    END
END sockaddrCheck;
*)

PROCEDURE -SetCShort(i: INTEGER; VAR si: Int16)
     "*(short*)si = i";

PROCEDURE -SetCShortSwapped(i: INTEGER; VAR si: Int16)
     "*(short*)si = ((i >> 8) & 0x00ff) | ((i << 8) & 0xff00)";

PROCEDURE SetSockAddrIn*(family, port, inaddr: Int16; VAR sai: SockAddrIn);
   VAR i: INTEGER;
   BEGIN
     SetCShort(family, sai.SinFamily);
     SetCShortSwapped(port, sai.SinPort);
     sai.SinAddr.SAddr := inaddr;
     i := 0; WHILE i < 8 DO sai.SinZero[i] := 0X; INC(i) END
END SetSockAddrIn;

(* functions below require include fcntl.h which is done above
   also for using accept4, but that's linux only way
   these functions are the portable way of setting socket to non-blocking mode *)

PROCEDURE -getFlags(VAR fd: LONGINT): LONGINT
  "(LONGINT)fcntl( *fd, F_GETFL)";

(* here be careful with the parentheses and the following asterisk, it is interpreted as an open comment by oberon parser *)

PROCEDURE -setNonBlocking(VAR fd: LONGINT; flags: LONGINT): LONGINT
  "(LONGINT)fcntl( *fd, F_SETFL, flags| O_NONBLOCK)";

PROCEDURE SetSocketNonBlocking*(VAR fd: LONGINT): BOOLEAN;
VAR
  currentFlags, res: LONGINT;
BEGIN
  currentFlags := getFlags(fd);
  IF currentFlags # -1 THEN
    res := setNonBlocking(fd, currentFlags);
    IF res = -1 THEN RETURN FALSE ELSE RETURN TRUE END;
  ELSE
    RETURN FALSE
  END;
END SetSocketNonBlocking;

END netSockets.
