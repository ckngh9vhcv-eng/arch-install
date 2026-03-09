#pragma once

#include <QObject>
#include <QProcess>
#include <QStringList>

class TaskRunner : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool running READ isRunning NOTIFY runningChanged)

public:
    explicit TaskRunner(QObject *parent = nullptr);

    bool isRunning() const { return m_running; }

    Q_INVOKABLE void run(const QString &command);
    Q_INVOKABLE void runWithPkexec(const QString &command);
    Q_INVOKABLE void enqueue(const QString &command);
    Q_INVOKABLE void cancel();

signals:
    void outputLine(const QString &line);
    void finished(int exitCode);
    void runningChanged();

private:
    void startNext();
    void setupProcess(const QString &command);
    void onReadyRead();
    void onProcessFinished(int exitCode, QProcess::ExitStatus status);

    QProcess *m_process = nullptr;
    QStringList m_queue;
    bool m_running = false;
};
