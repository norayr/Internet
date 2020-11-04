MODULE netForker;
IMPORT SYSTEM;

PROCEDURE -includeunistd "#include <unistd.h>";
PROCEDURE -fork*(): LONGINT "(LONGINT)fork()";


END netForker.
