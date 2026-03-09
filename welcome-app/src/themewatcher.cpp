#include "themewatcher.h"
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>

ThemeWatcher::ThemeWatcher(QObject *parent)
    : QObject(parent)
{
    m_filePath = QDir::homePath() + "/.local/share/quickshell/colorscheme.json";

    connect(&m_watcher, &QFileSystemWatcher::fileChanged,
            this, &ThemeWatcher::onFileChanged);

    readSchemeFile();

    if (QFile::exists(m_filePath)) {
        m_watcher.addPath(m_filePath);
    }
}

void ThemeWatcher::readSchemeFile()
{
    QFile file(m_filePath);
    if (!file.open(QIODevice::ReadOnly))
        return;

    QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    if (doc.isNull())
        return;

    QString scheme = doc.object().value("scheme").toString();
    if (!scheme.isEmpty() && scheme != m_currentScheme) {
        m_currentScheme = scheme;
        emit schemeChanged(m_currentScheme);
    }
}

void ThemeWatcher::onFileChanged(const QString &path)
{
    readSchemeFile();

    // Re-add watch — atomic writes (temp + rename) remove the old watch
    if (!m_watcher.files().contains(m_filePath) && QFile::exists(m_filePath)) {
        m_watcher.addPath(m_filePath);
    }
}
