#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QJsonDocument>

class PackageManager;

class Catalog : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList appCategories READ appCategories NOTIFY catalogLoaded)
    Q_PROPERTY(QVariantList fixes READ fixes NOTIFY catalogLoaded)
    Q_PROPERTY(QVariantList tweaks READ tweaks NOTIFY catalogLoaded)

public:
    explicit Catalog(PackageManager *pm, QObject *parent = nullptr);

    QVariantList appCategories() const { return m_categories; }
    QVariantList fixes() const { return m_fixes; }
    QVariantList tweaks() const { return m_tweaks; }

    Q_INVOKABLE QVariantList filterApps(const QString &query);
    Q_INVOKABLE void refresh();

signals:
    void catalogLoaded();

private:
    void loadAll();
    QJsonDocument loadJson(const QString &resource);
    void markInstalled();

    PackageManager *m_pm;
    QVariantList m_categories;
    QVariantList m_fixes;
    QVariantList m_tweaks;
};
