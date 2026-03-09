#include "systeminfo.h"
#include <QFile>
#include <QDir>
#include <QFileInfo>
#include <QProcess>
#include <QSysInfo>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QRegularExpression>

static constexpr int CMD_TIMEOUT_MS = 5000;

SystemInfo::SystemInfo(QObject *parent)
    : QObject(parent)
{
    detect();
}

void SystemInfo::detect()
{
    // CPU model from /proc/cpuinfo
    QString cpuinfo = readFile("/proc/cpuinfo");
    QRegularExpression cpuRe("model name\\s*:\\s*(.+)");
    auto match = cpuRe.match(cpuinfo);
    m_cpuModel = match.hasMatch() ? match.captured(1).trimmed() : "Unknown";

    // GPU model from lspci
    QString lspci = runCommand("lspci");
    QRegularExpression gpuRe("VGA.*:\\s*(.+)", QRegularExpression::CaseInsensitiveOption);
    match = gpuRe.match(lspci);
    m_gpuModel = match.hasMatch() ? match.captured(1).trimmed() : "Unknown";

    // GPU driver from sysfs
    m_gpuDriver = "Unknown";
    QDir drmDir("/sys/class/drm");
    if (drmDir.exists()) {
        for (const auto &entry : drmDir.entryList({"card[0-9]*"}, QDir::Dirs)) {
            QString driverLink = QString("/sys/class/drm/%1/device/driver").arg(entry);
            QFileInfo fi(driverLink);
            if (fi.exists() && fi.isSymLink()) {
                QString target = fi.symLinkTarget();
                if (!target.isEmpty()) {
                    m_gpuDriver = QFileInfo(target).fileName();
                    break;
                }
            }
        }
    }

    // RAM from /proc/meminfo
    QString meminfo = readFile("/proc/meminfo");
    QRegularExpression memRe("MemTotal:\\s*(\\d+)\\s*kB");
    match = memRe.match(meminfo);
    if (match.hasMatch()) {
        double gb = match.captured(1).toDouble() / 1024.0 / 1024.0;
        m_ramTotal = QString::number(gb, 'f', 1) + " GB";
    } else {
        m_ramTotal = "Unknown";
    }

    m_kernelVersion = QSysInfo::kernelVersion();
    m_hostname = QSysInfo::machineHostName();

    // Uptime from /proc/uptime
    QString uptimeStr = readFile("/proc/uptime").split(' ').value(0);
    double secs = uptimeStr.toDouble();
    int hours = static_cast<int>(secs) / 3600;
    int mins = (static_cast<int>(secs) % 3600) / 60;
    if (hours >= 24) {
        int days = hours / 24;
        hours = hours % 24;
        m_uptime = QString("%1d %2h %3m").arg(days).arg(hours).arg(mins);
    } else {
        m_uptime = QString("%1h %2m").arg(hours).arg(mins);
    }

    m_bootMode = QDir("/sys/firmware/efi").exists() ? "UEFI" : "BIOS";

    // Disk layout from lsblk
    QString lsblk = runCommand("lsblk -J -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE");
    QJsonParseError parseErr;
    QJsonDocument doc = QJsonDocument::fromJson(lsblk.toUtf8(), &parseErr);
    if (parseErr.error == QJsonParseError::NoError && doc.isObject()) {
        QJsonArray devices = doc.object().value("blockdevices").toArray();
        for (const auto &dev : devices) {
            QJsonObject obj = dev.toObject();
            if (obj.value("type").toString() == "disk") {
                QVariantMap disk;
                disk["name"] = obj.value("name").toString();
                disk["size"] = obj.value("size").toString();
                disk["type"] = obj.value("fstype").toString();
                disk["mount"] = obj.value("mountpoint").toString();
                m_diskLayout.append(disk);
            }
        }
    }
}

QString SystemInfo::readFile(const QString &path) const
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return {};
    return QString::fromUtf8(file.readAll());
}

QString SystemInfo::runCommand(const QString &cmd) const
{
    QProcess proc;
    proc.start("/bin/bash", {"-c", cmd});
    if (!proc.waitForFinished(CMD_TIMEOUT_MS))
        return {};
    if (proc.exitStatus() != QProcess::NormalExit)
        return {};
    return QString::fromUtf8(proc.readAllStandardOutput());
}
