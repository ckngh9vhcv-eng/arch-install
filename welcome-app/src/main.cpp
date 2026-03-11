#include <QGuiApplication>
#include <QLockFile>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QStandardPaths>

#include "packagemanager.h"
#include "taskrunner.h"
#include "systeminfo.h"
#include "catalog.h"
#include "themewatcher.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName("Void Command Welcome");
    app.setOrganizationName("VoidCommand");

    // Single-instance guard
    QString lockPath = QStandardPaths::writableLocation(QStandardPaths::RuntimeLocation)
                       + "/void-command-welcome.lock";
    QLockFile lockFile(lockPath);
    if (!lockFile.tryLock(100))
        return 0;

    QQuickStyle::setStyle("Basic");

    PackageManager packageManager;
    TaskRunner taskRunner;
    SystemInfo systemInfo;
    Catalog catalog(&packageManager);
    ThemeWatcher themeWatcher;

    QQmlApplicationEngine engine;

    engine.rootContext()->setContextProperty("PackageManager", &packageManager);
    engine.rootContext()->setContextProperty("TaskRunner", &taskRunner);
    engine.rootContext()->setContextProperty("SystemInfo", &systemInfo);
    engine.rootContext()->setContextProperty("Catalog", &catalog);
    engine.rootContext()->setContextProperty("ThemeWatcher", &themeWatcher);

    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.loadFromModule("VoidCommand", "Main");

    return app.exec();
}
