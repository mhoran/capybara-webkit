#include "Server.h"
#include "IgnoreDebugOutput.h"
#include "StdinNotifier.h"
#include <QApplication>
#include <iostream>
#ifdef Q_OS_UNIX
  #include <unistd.h>
#endif
#ifdef Q_OS_LINUX
#include "client/linux/handler/exception_handler.h"
#elif defined Q_OS_MAC
#include "client/mac/handler/exception_handler.h"
#endif

#ifdef Q_OS_LINUX
static bool dumpCallback(const google_breakpad::MinidumpDescriptor& descriptor, void* context, bool succeeded)
{
  Q_UNUSED(context);
  printf("Dump path: %s\n", descriptor.path());
  int child = fork();
  if (child == 0) {
    execl("bin/upload_dump.rb", "upload_dump.rb", descriptor.path(), (char *) NULL);
  }
  return succeeded;
}
#elif defined Q_OS_MAC
static bool dumpCallback(const char* dump_dir, const char* minidump_id, void* context, bool succeeded)
{
  Q_UNUSED(context);
  int child = fork();
  if (child == 0) {
    char dump_path[strlen(dump_dir) + strlen(minidump_id) + 6];
    sprintf(dump_path, "%s/%s.dmp", dump_dir, minidump_id);
    execl("bin/upload_dump.rb", "upload_dump.rb", dump_path, (char *) NULL);
  }
  return succeeded;
}
#endif

int main(int argc, char **argv) {
#ifdef Q_OS_LINUX
  google_breakpad::MinidumpDescriptor descriptor("/tmp");
  google_breakpad::ExceptionHandler eh(descriptor, NULL, dumpCallback, NULL, true, -1);
#elif defined Q_OS_MAC
  google_breakpad::ExceptionHandler eh("/tmp", NULL, dumpCallback, NULL, true, NULL);
#endif

#ifdef Q_OS_UNIX
  if (setpgid(0, 0) < 0) {
    std::cerr << "Unable to set new process group." << std::endl;
    return 1;
  }
#endif

  QApplication app(argc, argv);
  app.setApplicationName("capybara-webkit");
  app.setOrganizationName("thoughtbot, inc");
  app.setOrganizationDomain("thoughtbot.com");

  StdinNotifier notifier;
  QObject::connect(&notifier, SIGNAL(eof()), &app, SLOT(quit()));

  ignoreDebugOutput();
  Server server(0);

  if (server.start()) {
    std::cout << "Capybara-webkit server started, listening on port: " << server.server_port() << std::endl;
    return app.exec();
  } else {
    std::cerr << "Couldn't start capybara-webkit server" << std::endl;
    return 1;
  }
}
