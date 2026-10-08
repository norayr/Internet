# Internet

Networking for [voc](https://github.com/vishapoberon/compiler): TCP and UDP over IPv4 and IPv6, host
names, and the network interface of ETH Native Oberon for older programs.

The modern modules are the same as in [polpo](https://github.com/polpo-system/polpo): Sockets, DNS and Internet
compile unchanged in both; only their `IMPORT` lines differ. polpo makes the system calls itself,
in its kernel module `Linux0`; here `unixNet` makes them through the C library, and the shared
modules import it as `Linux0 := unixNet`.

## Modules

| module | what it is |
| --- | --- |
| `unixNet` | the system calls Sockets and DNS use (socket, connect, select, ...), through the C library, with polpo's `Linux0` names and results (negative error numbers) |
| `Kernel` | `Kernel.GetConfig`: an environment variable, as polpo's |
| `Sockets` | TCP and UDP sockets over IPv4 and IPv6 (`Listen` on all addresses, `ListenAt` on one), addresses as text and back |
| `DNS` | host names to addresses and back: `/etc/hosts`, then the name servers of `/etc/resolv.conf` (A, AAAA and PTR, over UDP); `Lookup`, `Resolve`, `Reverse` |
| `Internet` | the older interface: `Connect(host, port, conn)`, `Read`, `Write`, `Disconnect`, used by http |
| `netForker`, `server` | a forking TCP server over Sockets (`setListenOn` IPv4 or IPv6, one child process per connection); testServer and testClient show it |
| `native/NetSystem` | the NetSystem of Native Oberon (below) |

```
make            # build/: the modules (.o, .sym)
make tests      # testServer, testClient, testSockets, and testNetSystem run on 127.0.0.1
make tests NET=net   # testNetSystem also looks up example.com and gets its page over HTTP
build/testSockets lookup example.com
build/testSockets get example.com 80 /
```

## Deprecated: src/deprecated

`netTypes`, `netdb` and `netSockets` were the first wrappers of the C socket calls (IPv4 only).
Sockets and DNS replace them, and nothing here uses them any more; they are kept for old programs
and built only by `make deprecated`.

## Native Oberon compatibility: src/native

`NetSystem` is the portable network interface of ETH Oberon System 3 (Native Oberon), with the
same names, types and results: `OpenConnection`, `Accept`, `Read...`, `Write...`,
`CloseConnection`, `GetIP`, `OpenSocket`, `SendDG`, `ReceiveDG` and so on. Programs written for
it (mail, FTP, news, HTTP clients of the Oberon desktop) can use it unchanged. In Native Oberon it
sat on Oberon's own TCP/IP stack (NetBase, NetIP, NetTCP, NetUDP, NetDNS, network card drivers);
those were internal and are not here: NetSystem uses Sockets and DNS.

`IPAdr` is an IPv4 address in network byte order (the four bytes in memory order), and ports are
INTEGERs (above 32767 negative), as they were.

Where it differs from Native Oberon:

- **GetName** asks `DNS.Reverse` (/etc/hosts, then the PTR record) and gives `""` when there is
  no name, as Native Oberon did.
- **CloseConnection** closes both directions at once. In Native Oberon the connection could
  still receive after it (state `in`) until the other side closed; here read what you want
  before closing.
- **SetUser** does nothing. In Native Oberon it was a command that read
  `service:user[:password]@host` from the command text and the password from the keyboard.
  **SetPassword**(service, user, host, password) sets a password instead: it is *not* in Native
  Oberon, it is added here. GetPassword, DelPassword and ClearUser work as before (in memory).
- Names are looked up by DNS; the `NetSystem.Hosts` section of Oberon.Text is not read.
- The local port of an active connection is chosen by the system (`locPort` is not used).
- `Start` and `Stop` only switch `started`; `Show` prints to the terminal.
- Only IPv4, as in Native Oberon (`IPAdr` has 32 bits); Sockets has IPv6.

`test/native/testNetSystem.Mod` shows the use: a listening and a connecting connection in one
program, strings, integers and 9000 bytes each way, the end of a connection, and datagrams.
