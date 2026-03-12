cmake_minimum_required(VERSION 3.20)
project(void-command-welcome VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 6.6 REQUIRED COMPONENTS Quick QuickControls2)

qt_standard_project_setup(REQUIRES 6.6)

qt_add_executable(void-command-welcome
    src/main.cpp
    src/packagemanager.h src/packagemanager.cpp
    src/taskrunner.h src/taskrunner.cpp
    src/systeminfo.h src/systeminfo.cpp
    src/catalog.h src/catalog.cpp
    src/themewatcher.h src/themewatcher.cpp
    src/displaymanager.h src/displaymanager.cpp
)

set_source_files_properties(qml/Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(void-command-welcome
    URI VoidCommand
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/Theme.qml
        qml/components/VcButton.qml
        qml/components/VcCard.qml
        qml/components/VcToggle.qml
        qml/components/VcSearchBar.qml
        qml/components/VcProgressBar.qml
        qml/components/VcTerminalOutput.qml
        qml/components/VcCategoryHeader.qml
        qml/pages/WelcomePage.qml
        qml/pages/AppsPage.qml
        qml/pages/FixesPage.qml
        qml/pages/TweaksPage.qml
        qml/pages/DisplayPage.qml
        qml/pages/AboutPage.qml
        qml/dialogs/InstallDialog.qml
        qml/dialogs/FixDialog.qml
    RESOURCES
        data/apps.json
        data/fixes.json
        data/tweaks.json
)

target_link_libraries(void-command-welcome PRIVATE
    Qt6::Quick
    Qt6::QuickControls2
)

install(TARGETS void-command-welcome DESTINATION ${CMAKE_INSTALL_BINDIR})
install(FILES void-command-welcome.desktop DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/applications)
