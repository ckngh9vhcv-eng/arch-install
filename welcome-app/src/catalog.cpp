#include "catalog.h"
#include "packagemanager.h"
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonParseError>

Catalog::Catalog(PackageManager *pm, QObject *parent)
    : QObject(parent), m_pm(pm)
{
    loadAll();

    connect(m_pm, &PackageManager::packageStateChanged, this, [this]() {
        markInstalled();
        emit catalogLoaded();
    });
}

void Catalog::loadAll()
{
    auto apps = loadJson(":/qt/qml/VoidCommand/data/apps.json");
    if (apps.isObject())
        m_categories = apps.object().value("categories").toArray().toVariantList();

    auto fixes = loadJson(":/qt/qml/VoidCommand/data/fixes.json");
    if (fixes.isObject())
        m_fixes = fixes.object().value("fixes").toArray().toVariantList();

    auto tweaks = loadJson(":/qt/qml/VoidCommand/data/tweaks.json");
    if (tweaks.isObject())
        m_tweaks = tweaks.object().value("tweaks").toArray().toVariantList();

    markInstalled();
    emit catalogLoaded();
}

QJsonDocument Catalog::loadJson(const QString &resource)
{
    QFile file(resource);
    if (!file.open(QIODevice::ReadOnly))
        return {};

    QJsonParseError err;
    QJsonDocument doc = QJsonDocument::fromJson(file.readAll(), &err);
    if (err.error != QJsonParseError::NoError)
        return {};

    return doc;
}

void Catalog::markInstalled()
{
    for (int i = 0; i < m_categories.size(); ++i) {
        QVariantMap cat = m_categories[i].toMap();
        QVariantList apps = cat.value("apps").toList();

        for (int j = 0; j < apps.size(); ++j) {
            QVariantMap app = apps[j].toMap();
            if (app.value("flatpak").toBool())
                app["installed"] = m_pm->isFlatpakInstalled(app.value("package").toString());
            else
                app["installed"] = m_pm->isInstalled(app.value("package").toString());
            apps[j] = app;
        }

        cat["apps"] = apps;
        m_categories[i] = cat;
    }
}

QVariantList Catalog::filterApps(const QString &query)
{
    if (query.isEmpty())
        return m_categories;

    QString q = query.toLower();
    QVariantList filtered;

    for (const auto &catVar : m_categories) {
        QVariantMap cat = catVar.toMap();
        QVariantList apps = cat.value("apps").toList();
        QVariantList matching;

        for (const auto &appVar : apps) {
            QVariantMap app = appVar.toMap();
            if (app.value("name").toString().toLower().contains(q) ||
                app.value("description").toString().toLower().contains(q) ||
                app.value("package").toString().toLower().contains(q)) {
                matching.append(app);
            }
        }

        if (!matching.isEmpty()) {
            QVariantMap filteredCat = cat;
            filteredCat["apps"] = matching;
            filtered.append(filteredCat);
        }
    }

    return filtered;
}

void Catalog::refresh()
{
    m_pm->refreshInstalled();
}
