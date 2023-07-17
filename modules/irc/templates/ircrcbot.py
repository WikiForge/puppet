#!/usr/bin/python3

import base64
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

    def signedOn(self):
        global recver
        self.join(self.channel)
        print("Signed on as %s." % (self.nickname,))
        recver = self

    def joined(self, channel):
        print("Joined %s." % (channel,))

    def gotUDP(self, broadcast):
        # We ignore any errors, otherwise it will possibly fail
        # with 'unexpected end of data'.
        self.msg(self.channel, str(broadcast, 'utf-8', 'ignore'))


class SASLRCBot(RCBot):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.sasl_mechanism = "PLAIN"
        self.sasl_username = "wikiforgebots"
        self.sasl_password = "<%= @wikiforgebots_password %>"
        self._sasl_in_progress = False

    def signedOn(self):
        self.sendLine("CAP REQ :sasl")

    def irc_CAP(self, prefix, params):
        if params[1] == "ACK" and "sasl" in params[2]:
            self.initiate_sasl()

    def initiate_sasl(self):
        self._sasl_in_progress = True
        self.sendLine("AUTHENTICATE " + self.sasl_mechanism)

    def irc_900(self, prefix, params):
        if params[1] == self.nickname and params[2] == "SASL authentication successful":
            self.join(self.channel)

    def irc_904(self, prefix, params):
        if params[1] == self.nickname and params[2] == "SASL authentication failed":
            print("SASL authentication failed.")
            self.transport.loseConnection()

    def irc_906(self, prefix, params):
        if params[1] == self.nickname and params[2] == "SASL authentication aborted":
            print("SASL authentication aborted.")
            self.transport.loseConnection()

    def irc_903(self, prefix, params):
        if params[1] == self.nickname and params[2] == "SASL authentication successful":
            self.join(self.channel)

    def sendLine(self, line):
        if not self._sasl_in_progress:
            super().sendLine(line.encode("utf-8"))

    def lineReceived(self, line):
        if line == "AUTHENTICATE +":
            self.handle_sasl_challenge()
        else:
            super().lineReceived(line)

    def handle_sasl_challenge(self):
        if self.sasl_mechanism == "PLAIN":
            response = self.sasl_mechanism + " " + self.encode_plain()
        else:
            print("Unsupported SASL mechanism: %s" % self.sasl_mechanism)
            self.transport.loseConnection()
            return
        self.sendLine(response)

    def encode_plain(self):
        auth_string = "\x00".join((self.sasl_username, self.sasl_password))
        return base64.b64encode(auth_string.encode("utf-8")).decode("utf-8")

    def encode_base64(self, s):
        return s.encode("base64").strip()


class RCFactory(protocol.ClientFactory):
    protocol = SASLRCBot

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
