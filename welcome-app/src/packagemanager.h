#pragma once

#include <QObject>
#include <QProcess>
#include <QSet>
#include <QStringList>

class PackageManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString helperName READ helperName CONSTANT)
    Q_PROPERTY(bool busy READ isBusy NOTIFY busyChanged)

public:
    explicit PackageManager(QObject *parent = nullptr);

    QString helperName() const { return m_helper; }
    bool isBusy() const { return m_busy; }

    Q_INVOKABLE void install(const QStringList &packages);
    Q_INVOKABLE void remove(const QStringList &packages);
    Q_INVOKABLE bool isInstalled(const QString &package);
    Q_INVOKABLE void refreshInstalled();

signals:
    void installStarted(const QStringList &packages);
    void outputLine(const QString &line);
    void installFinished(bool success);
    void busyChanged();
    void packageStateChanged();

private:
    void detectHelper();
    void loadInstalledPackages();
    void runPackageCommand(const QStringList &args);
    void onReadyRead();
    void onProcessFinished(int exitCode, QProcess::ExitStatus status);

    QString m_helper;
    QProcess *m_process = nullptr;
    QSet<QString> m_installed;
    bool m_busy = false;
};
