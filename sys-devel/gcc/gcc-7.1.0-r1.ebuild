# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI="5"

PATCH_VER="1.1"
#UCLIBC_VER="1.0"

inherit epatch toolchain

KEYWORDS=""

RDEPEND=""
DEPEND="${RDEPEND}
	elibc_glibc? ( >=sys-libs/glibc-2.13 )
	>=${CATEGORY}/binutils-2.20"

if [[ ${CATEGORY} != cross-* ]] ; then
	PDEPEND="${PDEPEND} elibc_glibc? ( >=sys-libs/glibc-2.13 )"
fi

src_prepare() {
	toolchain_src_prepare

	# Upstream Patch
	epatch "${FILESDIR}"/${PN}-7.1.0-pr80706.patch

	if use elibc_musl || [[ ${CATEGORY} = cross-*-musl ]]; then
		epatch "${FILESDIR}"/6.3.0/cpu_indicator.patch
		epatch "${FILESDIR}"/7.1.0/posix_memalign.patch
	fi
}
