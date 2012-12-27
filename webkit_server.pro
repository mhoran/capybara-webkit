TEMPLATE = subdirs
CONFIG += ordered
SUBDIRS += breakpad/breakpad.pro src/webkit_server.pro
test {
  SUBDIRS += test/testwebkitserver.pro
}
