AC_INIT([gdrive-sync], [0.0.3])

AM_INIT_AUTOMAKE([foreign -Wall -Wno-portability])

AC_PATH_PROG([POD2MAN], [pod2man])
AS_IF([test -z "$POD2MAN"], [AC_MSG_ERROR([pod2man is required])])

AC_PATH_PROG([RSYNC], [rsync])
AS_IF([test -z "$RSYNC"], [AC_MSG_ERROR([rsync is required])])

AC_PATH_PROG([FINDMNT], [findmnt])
AS_IF([test -z "$FINDMNT"], [AC_MSG_ERROR([findmnt is required])])

AC_PATH_PROG([GIT], [git])
AS_IF([test -z "$GIT"], [AC_MSG_ERROR([git is required])])

AC_PATH_PROG([FUSERMOUNT], [fusermount])
AS_IF([test -z "$FUSERMOUNT"], [AC_MSG_ERROR([fusermount is required])])

AC_PATH_PROG([GOOGLE_DRIVE_OCAMLFUSE], [google-drive-ocamlfuse])
AS_IF([test -z "$GOOGLE_DRIVE_OCAMLFUSE"], [AC_MSG_ERROR([google-drive-ocamlfuse is required])])

AC_CONFIG_FILES([
  Makefile
  scripts/Makefile
])

AC_OUTPUT
