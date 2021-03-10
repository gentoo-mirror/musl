# Copyright 2003-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools flag-o-matic multilib-minimal toolchain-funcs

DESCRIPTION="Libraries/utilities to handle ELF objects (drop in replacement for libelf)"
HOMEPAGE="http://elfutils.org/"
SRC_URI="https://sourceware.org/elfutils/ftp/${PV}/${P}.tar.bz2"

LICENSE="|| ( GPL-2+ LGPL-3+ ) utils? ( GPL-3+ )"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 ~mips ppc ppc64"
IUSE="bzip2 lzma nls static-libs test +threads +utils valgrind"

RDEPEND=">=sys-libs/zlib-1.2.8-r1[static-libs?,${MULTILIB_USEDEP}]
	bzip2? ( >=app-arch/bzip2-1.0.6-r4[static-libs?,${MULTILIB_USEDEP}] )
	lzma? ( >=app-arch/xz-utils-5.0.5-r1[static-libs?,${MULTILIB_USEDEP}] )
	elibc_musl? (
		sys-libs/argp-standalone
		sys-libs/fts-standalone
		sys-libs/obstack-standalone
		dev-libs/libbsd
	)
	!dev-libs/libelf"
DEPEND="${RDEPEND}
	valgrind? ( dev-util/valgrind )
"
BDEPEND="nls? ( sys-devel/gettext )
	>=sys-devel/flex-2.5.4a
	sys-devel/m4"

RESTRICT="!test? ( test )"

PATCHES=(
	"${FILESDIR}"/${PN}-0.175-disable-biarch-test-PR24158.patch
	"${FILESDIR}"/${PN}-0.177-disable-large.patch
	"${FILESDIR}"/${PN}-0.180-PaX-support.patch
	"${FILESDIR}"/${PN}-0.179-CC-in-tests.patch
	"${FILESDIR}"/${PN}-0.180-readelf.patch

	# Musl Patches
	"${FILESDIR}"/0.178/fix-aarch64_fregs.patch
	"${FILESDIR}"/0.178/musl-asm_ptrace_h.patch
	"${FILESDIR}"/0.178/musl-cdefs.patch
	"${FILESDIR}"/0.178/musl-macros.patch
	"${FILESDIR}"/0.178/musl-fts-obstack.patch
	"${FILESDIR}"/0.178/musl-qsort_r.patch
	"${FILESDIR}"/0.178/musl-strerror_r.patch
	"${FILESDIR}"/0.178/musl-strndupa.patch
	"${FILESDIR}"/0.178/musl-error_h.patch
)

src_prepare() {
	default

	eautoreconf

	if ! use static-libs; then
		sed -i -e '/^lib_LIBRARIES/s:=.*:=:' -e '/^%.os/s:%.o$::' lib{asm,dw,elf}/Makefile.in || die
	fi
	# https://sourceware.org/PR23914
	sed -i 's:-Werror::' */Makefile.in || die

	if use elibc_musl; then
		cat > lib/libintl.h <<-EOF
			#ifndef LIBINTL_H
			#define LIBINTL_H
			#define _(x) (x)
			#endif
		EOF
	fi
}

src_configure() {
	use test && append-flags -g #407135

	# Symbol aliases are implemented as asm statements.
	# Will require porting: https://gcc.gnu.org/PR48200
	filter-flags '-flto*'

	multilib-minimal_src_configure
}

multilib_src_configure() {
	ECONF_SOURCE="${S}" econf \
		$(use_enable nls) \
		$(use_enable threads thread-safety) \
		$(use_enable valgrind) \
		--disable-debuginfod \
		--program-prefix="eu-" \
		--with-zlib \
		$(use_with bzip2 bzlib) \
		$(use_with lzma)
}

multilib_src_test() {
	# CC is a workaround for tests using ${CC-gcc}
	env	LD_LIBRARY_PATH="${BUILD_DIR}/libelf:${BUILD_DIR}/libebl:${BUILD_DIR}/libdw:${BUILD_DIR}/libasm" \
		LC_ALL="C" \
		CC="$(tc-getCC)" \
		emake check VERBOSE=1
}

multilib_src_install_all() {
	einstalldocs
	dodoc NOTES
	# These build quick, and are needed for most tests, so don't
	# disable their building when the USE flag is disabled.
	if ! use utils; then
		rm -rf "${ED}"/usr/bin || die
	fi
}
