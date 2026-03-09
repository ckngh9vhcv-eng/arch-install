#include "taskrunner.h"

TaskRunner::TaskRunner(QObject *parent)
    : QObject(parent)
{
}

void TaskRunner::run(const QString &command)
{
    m_queue.clear();
    setupProcess(command);
}

void TaskRunner::runWithPkexec(const QString &command)
{
    run(QString("pkexec bash -c '%1'").arg(command));
}

void TaskRunner::enqueue(const QString &command)
{
    m_queue.append(command);
    if (!m_running)
        startNext();
}

void TaskRunner::cancel()
{
    m_queue.clear();
    if (m_process && m_process->state() != QProcess::NotRunning) {
        m_process->kill();
        m_process->waitForFinished(3000);
    }
    if (m_running) {
        m_running = false;
        emit runningChanged();
    }
}

void TaskRunner::startNext()
{
    if (m_queue.isEmpty()) {
        if (m_running) {
            m_running = false;
            emit runningChanged();
        }
        return;
    }
    setupProcess(m_queue.takeFirst());
}

void TaskRunner::setupProcess(const QString &command)
{
    if (m_process) {
        m_process->deleteLater();
        m_process = nullptr;
    }

    m_process = new QProcess(this);
    m_process->setProcessChannelMode(QProcess::MergedChannels);

    connect(m_process, &QProcess::readyRead, this, &TaskRunner::onReadyRead);
    connect(m_process, &QProcess::finished, this, &TaskRunner::onProcessFinished);

    if (!m_running) {
        m_running = true;
        emit runningChanged();
    }

    m_process->start("/bin/bash", {"-c", command});
}

void TaskRunner::onReadyRead()
{
    while (m_process->canReadLine()) {
        QString line = QString::fromUtf8(m_process->readLine()).trimmed();
        if (!line.isEmpty())
            emit outputLine(line);
    }
}

void TaskRunner::onProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    // Flush remaining output
    QByteArray remaining = m_process->readAll();
    for (const auto &line : remaining.split('\n')) {
        QString l = QString::fromUtf8(line).trimmed();
        if (!l.isEmpty())
            emit outputLine(l);
    }

    // Treat crashes as failures
    int code = (exitStatus == QProcess::NormalExit) ? exitCode : -1;
    emit finished(code);

    if (!m_queue.isEmpty()) {
        startNext();
    } else {
        m_running = false;
        emit runningChanged();
    }
}
