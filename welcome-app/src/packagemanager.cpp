#include "packagemanager.h"
#include <QDir>
#include <QStandardPaths>

static constexpr int PACKAGE_LIST_TIMEOUT_MS = 15000;

PackageManager::PackageManager(QObject *parent)
    : QObject(parent)
{
    detectHelper();
    loadInstalledPackages();
    loadInstalledFlatpaks();
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

void PackageManager::loadInstalledFlatpaks()
{
    QProcess proc;
    proc.start("flatpak", {"list", "--app", "--columns=application"});
    if (!proc.waitForFinished(PACKAGE_LIST_TIMEOUT_MS))
        return;
    if (proc.exitStatus() != QProcess::NormalExit)
        return;

    m_installedFlatpaks.clear();
    QByteArray output = proc.readAllStandardOutput();
    for (const auto &line : output.split('\n')) {
        QString appId = QString::fromUtf8(line).trimmed();
        if (!appId.isEmpty())
            m_installedFlatpaks.insert(appId);
    }
}

bool PackageManager::isInstalled(const QString &package)
{
    return m_installed.contains(package);
}

bool PackageManager::isFlatpakInstalled(const QString &appId)
{
    return m_installedFlatpaks.contains(appId);
}

void PackageManager::refreshInstalled()
{
    loadInstalledPackages();
    loadInstalledFlatpaks();
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

void PackageManager::installFlatpak(const QString &appId)
{
    if (m_busy || appId.isEmpty())
        return;

    emit installStarted({appId});
    runFlatpakCommand({"install", "--system", "--noninteractive", "flathub", appId});
}

void PackageManager::removeFlatpak(const QString &appId)
{
    if (m_busy || appId.isEmpty())
        return;

    emit installStarted({appId});
    runFlatpakCommand({"uninstall", "--system", "--noninteractive", appId});
}

void PackageManager::updateDesktopDatabase()
{
    // Refresh desktop entry caches so app launchers pick up changes
    QStringList dirs = {
        "/usr/share/applications",
        "/var/lib/flatpak/exports/share/applications",
        QDir::homePath() + "/.local/share/applications",
        QDir::homePath() + "/.local/share/flatpak/exports/share/applications"
    };
    for (const auto &dir : dirs) {
        if (QDir(dir).exists())
            QProcess::startDetached("update-desktop-database", {dir});
    }
}

void PackageManager::runPackageCommand(const QStringList &args)
{
    if (m_helper == "pacman") {
        startProcess("pkexec", QStringList{"pacman"} + args);
    } else {
        QStringList helperArgs = {"--sudo", "pkexec"};
        helperArgs.append(args);
        startProcess(m_helper, helperArgs);
    }
}

void PackageManager::runFlatpakCommand(const QStringList &args)
{
    startProcess("flatpak", args);
}

void PackageManager::startProcess(const QString &program, const QStringList &args)
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

    m_process->start(program, args);
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
        loadInstalledFlatpaks();
        updateDesktopDatabase();
        emit packageStateChanged();
    }

    emit installFinished(success);
}
