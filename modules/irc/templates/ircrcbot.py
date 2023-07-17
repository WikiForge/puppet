#!/usr/bin/python3

from twisted.internet.protocol import DatagramProtocol
from twisted.internet import reactor, ssl
from twisted.words.protocols import irc
from twisted.internet import protocol

recver = None


class RCBot(irc.IRCClient):
    nickname = "<%= @nickname %>"
    password = "wikiforgebots:<%= @wikiforgebots_password %>"
    channel = "<%= @channel %>"
    lineRate = 1
    sasl_in_progress = False

    def signedOn(self):
        global recver
        self.join(self.channel)
        print("Signed on as %s." % (self.nickname,))
        recver = self
        self.sasl_start()

    def joined(self, channel):
        print("Joined %s." % (channel,))

    def gotUDP(self, broadcast):
        # We ignore any errors, otherwise it will possibly fail
        # with 'unexpected end of data'.
        self.msg(self.channel, str(broadcast, 'utf-8', 'ignore'))

    def sasl_start(self):
        self.sendLine("CAP REQ :sasl")

    def sasl_response(self, response):
        if response == "+":
            username = "wikiforgebots"
            password = "<%= @wikiforgebots_password %>"
            auth_string = f"{username}\0{password}"
            self.sendLine(f"AUTHENTICATE PLAIN {auth_string}")
            self.sasl_in_progress = True

    def lineReceived(self, line):
        if self.sasl_in_progress:
            if line.startswith("+"):
                self.sasl_in_progress = False
                self.sasl_response(line)
                return
            elif line.startswith("-"):
                self.sasl_in_progress = False
                print("SASL authentication failed.")
                self.transport.loseConnection()
                return

        super().lineReceived(line)


class RCFactory(protocol.ClientFactory):
    protocol = RCBot

    def clientConnectionLost(self, connector, reason):
        print("Lost connection (%s), reconnecting." % (reason,))
        connector.connect()

    def clientConnectionFailed(self, connector, reason):
        print("Could not connect: %s" % (reason,))


class Echo(DatagramProtocol):

    def datagramReceived(self, data, host_port):
        global recver
        (host, port) = host_port
        if recver:
            recver.gotUDP(data)


reactor.listenUDP(<%= @udp_port %>, Echo())  # noqa: E225,E999
<% if @network_port == '6697' %>  # noqa: E225
reactor.connectSSL("<%= @network %>", <%= @network_port %>, RCFactory(), ssl.ClientContextFactory())  # noqa: E225
<% else %>  # noqa: E225
reactor.connectTCP("<%= @network %>", <%= @network_port %>, RCFactory())  # noqa: E225
<% end %>  # noqa: E225
reactor.run()
