# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="5"
inherit autotools base systemd

DESCRIPTION="Provides a daemon for managing internet connections"
HOMEPAGE="https://01.org/connman"
SRC_URI="mirror://kernel/linux/network/${PN}/${P}.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm ppc x86"
IUSE="bluetooth debug doc examples +ethernet l2tp ofono openvpn openconnect pptp policykit tools vpnc +wifi wispr"

RDEPEND=">=dev-libs/glib-2.16
	>=sys-apps/dbus-1.2.24
	>=net-firewall/iptables-1.4.8
	bluetooth? ( net-wireless/bluez )
	l2tp? ( net-dialup/xl2tpd )
	ofono? ( net-misc/ofono )
	openconnect? ( net-vpn/openconnect )
	openvpn? ( net-vpn/openvpn )
	policykit? ( sys-auth/polkit )
	pptp? ( net-dialup/pptpclient )
	vpnc? ( net-vpn/vpnc )
	wifi? ( >=net-wireless/wpa_supplicant-2.0[dbus] )
	wispr? ( net-libs/gnutls )"

DEPEND="${RDEPEND}
	>=sys-kernel/linux-headers-2.6.39"

PATCHES=(
	"${FILESDIR}/${PN}-musl.patch"
	"${FILESDIR}/${PN}-musl-log.patch"
	"${FILESDIR}/${PN}-musl-libresolv.patch"
	"${FILESDIR}/${P}-musl-sockaddr.patch"
)

src_prepare() {
	default

	eautoreconf
}

src_configure() {
	econf \
		--localstatedir=/var \
		--enable-client \
		--enable-datafiles \
		--enable-loopback=builtin \
		$(use_enable examples test) \
		$(use_enable ethernet ethernet builtin) \
		$(use_enable wifi wifi builtin) \
		$(use_enable bluetooth bluetooth builtin) \
		$(use_enable l2tp l2tp builtin) \
		$(use_enable ofono ofono builtin) \
		$(use_enable openconnect openconnect builtin) \
		$(use_enable openvpn openvpn builtin) \
		$(use_enable policykit polkit builtin) \
		$(use_enable pptp pptp builtin) \
		$(use_enable vpnc vpnc builtin) \
		$(use_enable wispr wispr builtin) \
		$(use_enable debug) \
		$(use_enable tools) \
		--disable-iospm \
		--disable-hh2serial-gps
}

src_install() {
	emake DESTDIR="${D}" install
	dobin client/connmanctl || die "client installation failed"

	if use doc; then
		dodoc doc/*.txt
	fi
	keepdir /var/lib/${PN}
	newinitd "${FILESDIR}"/${PN}.initd2 ${PN}
	newconfd "${FILESDIR}"/${PN}.confd ${PN}
	systemd_dounit "${FILESDIR}"/connman.service
}
