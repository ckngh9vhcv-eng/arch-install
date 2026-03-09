#pragma once

#include <QObject>
#include <QFileSystemWatcher>
#include <QString>

class ThemeWatcher : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString currentScheme READ currentScheme NOTIFY schemeChanged)

public:
    explicit ThemeWatcher(QObject *parent = nullptr);
    QString currentScheme() const { return m_currentScheme; }

signals:
    void schemeChanged(const QString &scheme);

private:
    void readSchemeFile();
    void onFileChanged(const QString &path);

    QFileSystemWatcher m_watcher;
    QString m_currentScheme = "void-command";
    QString m_filePath;
};
