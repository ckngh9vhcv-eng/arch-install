#ifndef DISPLAYMANAGER_H
#define DISPLAYMANAGER_H

#include <QObject>
#include <QProcess>
#include <QVariantList>
#include <QVariantMap>

class DisplayManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList monitors READ monitors NOTIFY monitorsChanged)
    Q_PROPERTY(QVariantMap modelines READ modelines NOTIFY modelinesChanged)

public:
    explicit DisplayManager(QObject *parent = nullptr);

    QVariantList monitors() const { return m_monitors; }
    QVariantMap modelines() const { return m_modelines; }

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void applyMonitor(const QString &name, const QString &resolution,
                                  double refreshRate, const QString &position, double scale);
    Q_INVOKABLE void applyModeline(const QString &name, const QString &modeline,
                                   const QString &position, double scale);
    Q_INVOKABLE void setTransform(const QString &name, int transform);
    Q_INVOKABLE void setVrr(int mode);
    Q_INVOKABLE QString generateModeline(int width, int height, double rate, bool reducedBlanking);
    Q_INVOKABLE void setMonitorModeline(const QString &name, const QString &modeline);
    Q_INVOKABLE void clearMonitorModeline(const QString &name);
    Q_INVOKABLE void saveConfig();
    Q_INVOKABLE void loadConfig();

signals:
    void monitorsChanged();
    void modelinesChanged();
    void saveResult(bool success, const QString &message);

private:
    void parseMonitors(const QByteArray &data);
    QString runHyprctl(const QStringList &args);
    QString configPath() const;

    QVariantList m_monitors;
    QVariantMap m_modelines; // monitorName -> modeline string
};

#endif // DISPLAYMANAGER_H
