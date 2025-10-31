/***************************************************************************
 *   Copyright (C) 2025 by Nicolas Keita - nicolaskeita2@@gmail.com        *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             *
 ***************************************************************************/

#include <QtTest/QtTest>
#include <cstdlib>
#include "TelnetServerStub.h"
#include "mudlet.h"
#include "ctelnet.h"

extern void qInitResources_mudlet();
extern void qInitResources_qm();
extern void qInitResources_additional_splash_screens();
extern void qInitResources_mudlet_fonts_common();
extern void qInitResources_mudlet_fonts_posix();
void        initializeQRCResources();

void initializeQRCResources() {
    #ifdef INCLUDE_VARIABLE_SPLASH_SCREEN
        qInitResources_additional_splash_screens();
    #endif

    #ifdef INCLUDE_FONTS
        qInitResources_mudlet_fonts_common();
        #if defined(__linux__) || defined(__FreeBSD__)
            qInitResources_mudlet_fonts_posix();
        #endif
    #endif

    qInitResources_mudlet();
    qInitResources_qm();
}

class TelnetTextDisplayedTest : public QObject {
    Q_OBJECT

private:
    TelnetServerStub*               server = nullptr;
    static constexpr const char*    HOSTNAME = "Test-Telnet";
    static constexpr const char*    PORT = "4000";
    static constexpr const char*    LOCALHOST = "127.0.0.1";

    void startProfile(const char *hostname)
    {
        QTimer::singleShot(0, qApp, [hostname]() {
            mudlet::self()->startAutoLogin(QStringList{hostname});
        });
        QSignalSpy spy(mudlet::self(), &mudlet::signal_profileLoaded);
        if (!spy.wait(1000)) {
            QFAIL("Profile took too long to load.");
        }
        QSignalSpy spy2(&(mudlet::self()->getActiveHost()->mTelnet), &cTelnet::signal_connected);
        if (!spy2.wait(500)) {
            QFAIL("Could not connect with the host.");
        }
    }

private slots:
    void initTestCase()
    {
        initializeQRCResources();
    }

    void init()
    {
        server = new TelnetServerStub(qApp);
        server->start(LOCALHOST, static_cast<quint16>(std::atoi(PORT)));
        mudlet::start();
        mudlet::self()->setupConfig();
        mudlet::self()->takeOwnershipOfInstanceCoordinator(
            std::make_unique<MudletInstanceCoordinator>("MudletInstanceCoordinator")
        );
        mudlet::self()->init();
        mudlet::self()->getHostManager().addHost(HOSTNAME, PORT, "", "");
        mudlet::self()->getHostManager().getHost(HOSTNAME)->setUrl(LOCALHOST);
    }

    void test_TelnetTextDisplayed()
    {
        QString messageToExpect("Greetings < hunters & sorcerers");

        server->setWelcomeMessage(messageToExpect);
        startProfile(HOSTNAME);
        QSignalSpy(mudlet::self()->getActiveHost()->mpConsole, &TMainConsole::signal_newDataAlert).wait(200);

        QCOMPARE(mudlet::self()->getActiveHost()->mpConsole->getCurrentLine(""), messageToExpect);
    }

    void cleanup()
    {
        delete server;
        server = nullptr;
    }
};

#include "TelnetTextDisplayedTest.moc"
QTEST_MAIN(TelnetTextDisplayedTest)
