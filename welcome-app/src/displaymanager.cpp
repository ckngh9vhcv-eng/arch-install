#include "displaymanager.h"

#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <QTextStream>
#include <QTimer>

DisplayManager::DisplayManager(QObject *parent)
    : QObject(parent)
{
    loadConfig();
    refresh();
}

void DisplayManager::refresh()
{
    QString output = runHyprctl({"monitors", "-j"});
    if (!output.isEmpty())
        parseMonitors(output.toUtf8());
}

void DisplayManager::parseMonitors(const QByteArray &data)
{
    QJsonParseError err;
    QJsonDocument doc = QJsonDocument::fromJson(data, &err);
    if (err.error != QJsonParseError::NoError || !doc.isArray())
        return;

    QVariantList list;
    const QJsonArray arr = doc.array();

    for (const QJsonValue &val : arr) {
        QJsonObject obj = val.toObject();
        QVariantMap mon;

        mon["name"] = obj["name"].toString();
        mon["description"] = obj["description"].toString();
        mon["make"] = obj["make"].toString();
        mon["model"] = obj["model"].toString();
        mon["width"] = obj["width"].toInt();
        mon["height"] = obj["height"].toInt();
        mon["refreshRate"] = obj["refreshRate"].toDouble();
        mon["scale"] = obj["scale"].toDouble();
        mon["transform"] = obj["transform"].toInt();
        mon["vrr"] = obj["vrr"].toBool();
        mon["x"] = obj["x"].toInt();
        mon["y"] = obj["y"].toInt();
        mon["dpmsStatus"] = obj["dpmsStatus"].toBool();
        mon["focused"] = obj["focused"].toBool();
        mon["disabled"] = obj["disabled"].toBool();

        // Parse available modes — strings like "2560x1440@59.95Hz"
        QVariantList modes;
        const QJsonArray modeArr = obj["availableModes"].toArray();
        for (const QJsonValue &m : modeArr) {
            QString modeStr = m.toString();
            int xPos = modeStr.indexOf('x');
            int atPos = modeStr.indexOf('@');
            int hzPos = modeStr.indexOf("Hz", atPos);
            if (xPos < 0 || atPos < 0)
                continue;

            QVariantMap mode;
            mode["width"] = modeStr.left(xPos).toInt();
            mode["height"] = modeStr.mid(xPos + 1, atPos - xPos - 1).toInt();
            mode["refreshRate"] = modeStr.mid(atPos + 1, (hzPos > 0 ? hzPos : modeStr.length()) - atPos - 1).toDouble();
            modes.append(mode);
        }
        mon["availableModes"] = modes;

        list.append(mon);
    }

    m_monitors = list;
    emit monitorsChanged();
}

void DisplayManager::applyMonitor(const QString &name, const QString &resolution,
                                  double refreshRate, const QString &position, double scale)
{
    QString value = QString("%1,%2@%3,%4,%5")
                        .arg(name, resolution)
                        .arg(refreshRate, 0, 'f', 2)
                        .arg(position)
                        .arg(scale, 0, 'f', 2);

    runHyprctl({"keyword", "monitor", value});
    QTimer::singleShot(500, this, &DisplayManager::refresh);
}

void DisplayManager::applyModeline(const QString &name, const QString &modeline,
                                   const QString &position, double scale)
{
    // Format: hyprctl keyword monitor NAME,modeline NUMBERS,POS,SCALE
    QString value = QString("%1,modeline %2,%3,%4")
                        .arg(name, modeline, position)
                        .arg(scale, 0, 'f', 2);

    runHyprctl({"keyword", "monitor", value});
    QTimer::singleShot(500, this, &DisplayManager::refresh);
}

void DisplayManager::setTransform(const QString &name, int transform)
{
    QString value = QString("%1,transform,%2").arg(name).arg(transform);
    runHyprctl({"keyword", "monitor", value});
    QTimer::singleShot(500, this, &DisplayManager::refresh);
}

void DisplayManager::setVrr(int mode)
{
    runHyprctl({"keyword", "misc:vrr", QString::number(mode)});
    QTimer::singleShot(500, this, &DisplayManager::refresh);
}

QString DisplayManager::generateModeline(int width, int height, double rate, bool reducedBlanking)
{
    QProcess proc;
    QStringList args;
    if (reducedBlanking)
        args << "-r";
    args << QString::number(width) << QString::number(height) << QString::number(rate, 'f', 0);

    proc.start("cvt", args);
    proc.waitForFinished(3000);
    QString output = QString::fromUtf8(proc.readAllStandardOutput()).trimmed();

    // Parse: Modeline "name"  497.25  2560 2608 2640 2720  1440 1443 1448 1525 +hsync -vsync
    // We want everything after the quoted name
    QRegularExpression re(R"(Modeline\s+"[^"]+"\s+(.+))");
    auto match = re.match(output);
    if (match.hasMatch()) {
        // Normalize whitespace — cvt uses double spaces between timing groups
        // but hyprctl requires single spaces
        return match.captured(1).trimmed().replace(QRegularExpression("\\s+"), " ");
    }

    return {};
}

void DisplayManager::setMonitorModeline(const QString &name, const QString &modeline)
{
    m_modelines[name] = modeline;
    emit modelinesChanged();
}

void DisplayManager::clearMonitorModeline(const QString &name)
{
    m_modelines.remove(name);
    emit modelinesChanged();
}

void DisplayManager::loadConfig()
{
    QFile file(configPath());
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return;

    QTextStream in(&file);
    // Parse lines like: monitor = DP-1, modeline 497.25 2560 ... +hsync -vsync, auto, 1
    QRegularExpression re(R"(^monitor\s*=\s*(\S+)\s*,\s*modeline\s+(.+?)\s*,\s*\S+\s*,\s*\S+\s*$)");

    while (!in.atEnd()) {
        QString line = in.readLine().trimmed();
        if (line.startsWith('#') || line.isEmpty())
            continue;

        auto match = re.match(line);
        if (match.hasMatch()) {
            m_modelines[match.captured(1)] = match.captured(2).trimmed().replace(QRegularExpression("\\s+"), " ");
        }
    }

    file.close();
    emit modelinesChanged();
}

void DisplayManager::saveConfig()
{
    QString path = configPath();
    QDir().mkpath(QFileInfo(path).absolutePath());

    QFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        emit saveResult(false, "Failed to write " + path);
        return;
    }

    QTextStream out(&file);
    out << "# Generated by Void Command Welcome App\n";
    out << "# Manual edits will be overwritten on next save\n\n";

    for (const QVariant &v : m_monitors) {
        QVariantMap mon = v.toMap();
        if (mon["disabled"].toBool())
            continue;

        QString name = mon["name"].toString();
        int x = mon["x"].toInt();
        int y = mon["y"].toInt();
        double scale = mon["scale"].toDouble();
        int transform = mon["transform"].toInt();

        QString position = QString("%1x%2").arg(x).arg(y);

        if (m_modelines.contains(name)) {
            // Write modeline entry
            QString modeline = m_modelines[name].toString();
            out << QString("monitor = %1, modeline %2, %3, %4")
                       .arg(name, modeline, position)
                       .arg(scale, 0, 'f', 2)
                   << "\n";
        } else {
            // Write standard entry
            int w = mon["width"].toInt();
            int h = mon["height"].toInt();
            double rate = mon["refreshRate"].toDouble();
            out << QString("monitor = %1, %2x%3@%4, %5, %6")
                       .arg(name)
                       .arg(w)
                       .arg(h)
                       .arg(rate, 0, 'f', 2)
                       .arg(position)
                       .arg(scale, 0, 'f', 2)
                   << "\n";
        }

        if (transform != 0)
            out << QString("monitor = %1, transform, %2").arg(name).arg(transform) << "\n";
    }

    file.close();
    emit saveResult(true, "Saved to " + path);
}

QString DisplayManager::configPath() const
{
    return QDir::homePath() + "/.config/hypr/monitors.conf";
}

QString DisplayManager::runHyprctl(const QStringList &args)
{
    QProcess proc;
    proc.start("hyprctl", args);
    proc.waitForFinished(3000);
    return QString::fromUtf8(proc.readAllStandardOutput()).trimmed();
}
