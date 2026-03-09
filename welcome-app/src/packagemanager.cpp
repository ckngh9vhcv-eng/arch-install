#include "packagemanager.h"
#include <QStandardPaths>

static constexpr int PACKAGE_LIST_TIMEOUT_MS = 15000;

PackageManager::PackageManager(QObject *parent)
    : QObject(parent)
{
    detectHelper();
    loadInstalledPackages();
}

void PackageManager::detectHelper()
{
    for (const auto &name : {"paru", "yay"}) {
        if (!QStandardPaths::findExecutable(name).isEmpty()) {
            m_helper = name;
            return;
        }
    }
    m_helper = "pacman";
}

void PackageManager::loadInstalledPackages()
{
    QProcess proc;
    proc.start("pacman", {"-Qq"});
    if (!proc.waitForFinished(PACKAGE_LIST_TIMEOUT_MS))
        return;
    if (proc.exitStatus() != QProcess::NormalExit)
        return;

    m_installed.clear();
    QByteArray output = proc.readAllStandardOutput();
    for (const auto &line : output.split('\n')) {
        QString pkg = QString::fromUtf8(line).trimmed();
        if (!pkg.isEmpty())
            m_installed.insert(pkg);
    }
}

bool PackageManager::isInstalled(const QString &package)
{
    return m_installed.contains(package);
}

void PackageManager::refreshInstalled()
{
    loadInstalledPackages();
    emit packageStateChanged();
}

void PackageManager::install(const QStringList &packages)
{
    if (m_busy || packages.isEmpty())
        return;

    QStringList args = {"-S", "--noconfirm", "--needed"};
    args.append(packages);

    emit installStarted(packages);
    runPackageCommand(args);
}

void PackageManager::remove(const QStringList &packages)
{
    if (m_busy || packages.isEmpty())
        return;

    QStringList args = {"-Rns", "--noconfirm"};
    args.append(packages);

    emit installStarted(packages);
    runPackageCommand(args);
}

void PackageManager::runPackageCommand(const QStringList &args)
{
    if (m_process) {
        m_process->deleteLater();
        m_process = nullptr;
    }

    m_process = new QProcess(this);
    m_process->setProcessChannelMode(QProcess::MergedChannels);

    connect(m_process, &QProcess::readyRead, this, &PackageManager::onReadyRead);
    connect(m_process, &QProcess::finished, this, &PackageManager::onProcessFinished);

    m_busy = true;
    emit busyChanged();

    m_process->start(m_helper, args);
}

void PackageManager::onReadyRead()
{
    while (m_process->canReadLine()) {
        QString line = QString::fromUtf8(m_process->readLine()).trimmed();
        if (!line.isEmpty())
            emit outputLine(line);
    }
}

void PackageManager::onProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    QByteArray remaining = m_process->readAll();
    for (const auto &line : remaining.split('\n')) {
        QString l = QString::fromUtf8(line).trimmed();
        if (!l.isEmpty())
            emit outputLine(l);
    }

    m_busy = false;
    emit busyChanged();

    bool success = (exitStatus == QProcess::NormalExit && exitCode == 0);
    if (success) {
        loadInstalledPackages();
        emit packageStateChanged();
    }

    emit installFinished(success);
}
