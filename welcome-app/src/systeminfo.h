#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>

class SystemInfo : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString cpuModel READ cpuModel CONSTANT)
    Q_PROPERTY(QString gpuModel READ gpuModel CONSTANT)
    Q_PROPERTY(QString gpuDriver READ gpuDriver CONSTANT)
    Q_PROPERTY(QString ramTotal READ ramTotal CONSTANT)
    Q_PROPERTY(QString kernelVersion READ kernelVersion CONSTANT)
    Q_PROPERTY(QString hostname READ hostname CONSTANT)
    Q_PROPERTY(QString uptime READ uptime CONSTANT)
    Q_PROPERTY(QString bootMode READ bootMode CONSTANT)
    Q_PROPERTY(QVariantList diskLayout READ diskLayout CONSTANT)

public:
    explicit SystemInfo(QObject *parent = nullptr);

    QString cpuModel() const { return m_cpuModel; }
    QString gpuModel() const { return m_gpuModel; }
    QString gpuDriver() const { return m_gpuDriver; }
    QString ramTotal() const { return m_ramTotal; }
    QString kernelVersion() const { return m_kernelVersion; }
    QString hostname() const { return m_hostname; }
    QString uptime() const { return m_uptime; }
    QString bootMode() const { return m_bootMode; }
    QVariantList diskLayout() const { return m_diskLayout; }

private:
    void detect();
    QString readFile(const QString &path) const;
    QString runCommand(const QString &cmd) const;

    QString m_cpuModel;
    QString m_gpuModel;
    QString m_gpuDriver;
    QString m_ramTotal;
    QString m_kernelVersion;
    QString m_hostname;
    QString m_uptime;
    QString m_bootMode;
    QVariantList m_diskLayout;
};
