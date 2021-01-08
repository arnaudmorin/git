#!/bin/sh
#
# Copyright (c) 2021 Jiang Xin
#

test_description='Test git-bundle'

GIT_TEST_DEFAULT_INITIAL_BRANCH_NAME=main
export GIT_TEST_DEFAULT_INITIAL_BRANCH_NAME

. ./test-lib.sh

# Check count of objects in a bundle file.
# We can use "--thin" opiton to check thin pack, which must be fixed by
# command `git-index-pack --fix-thin --stdin`.
test_bundle_object_count () {
	thin= &&
	if test "$1" = "--thin"
	then
		thin=yes
		shift
	fi &&
	if test $# -ne 2
	then
		echo >&2 "args should be: <bundle> <count>"
		return 1
	fi
	bundle=$1 &&
	pack=${bundle%.bdl}.pack &&
	convert_bundle_to_pack <"$bundle" >"$pack" &&
	if test -n "$thin"
	then
		test_must_fail git index-pack "$pack" &&
		mv "$pack" "$pack"-thin &&
		cat "$pack"-thin |
			git index-pack --stdin --fix-thin "$pack"
	else
		git index-pack "$pack"
	fi &&
	git verify-pack -v "$pack" >verify.out
	if test $? -ne 0
	then
		echo >&2 "error: fail to convert $bundle to $pack"
		return 1
	fi
	count=$(grep -c "^$OID_REGEX " verify.out) &&
	test $2 = $count && return 0
	echo >&2 "error: object count for $bundle is $count, not $2"
	return 1
}

# Display the pack data contained in the bundle file, bypassing the
# header that contains the signature, prerequisites and references.
convert_bundle_to_pack () {
	while read x && test -n "$x"
	do
		:;
	done
	cat
}

# Create a commit or tag and set the variable with the object ID.
test_commit_setvar () {
	notick= &&
	signoff= &&
	indir= &&
	merge= &&
	tag= &&
	var= &&
	while test $# != 0
	do
		case "$1" in
		--merge)
			merge=yes
			;;
		--tag)
			tag=yes
			;;
		--notick)
			notick=yes
			;;
		--signoff)
			signoff="$1"
			;;
		-C)
			indir="$2"
			shift
			;;
		-*)
			echo >&2 "error: unknown option $1"
			return 1
			;;
		*)
			test -n "$var" && break
			var=$1
			;;
		esac
		shift
	done &&
	indir=${indir:+"$indir"/} &&
	if test $# -eq 0
	then
		echo >&2 "no args provided"
		return 1
	fi &&
	if test -z "$notick"
	then
		test_tick
	fi &&
	if test -n "$merge"
	then
		git ${indir:+ -C "$indir"} merge --no-edit --no-ff \
			${2:+-m "$2"} "$1" &&
		oid=$(git ${indir:+ -C "$indir"} rev-parse HEAD)
	elif test -n "$tag"
	then
		git ${indir:+ -C "$indir"} tag -m "$1" "$1" &&
		oid=$(git ${indir:+ -C "$indir"} rev-parse "$1")
	else
		file=${2:-"$1.t"} &&
		echo "${3-$1}" > "$indir$file" &&
		git ${indir:+ -C "$indir"} add "$file" &&
		git ${indir:+ -C "$indir"} commit $signoff -m "$1" &&
		oid=$(git ${indir:+ -C "$indir"} rev-parse HEAD)
	fi &&
	eval $var=$oid
}


# Format the output of git commands to make a user-friendly and stable
# text.  We can easily prepare the expect text without having to worry
# about future changes of the commit ID and spaces of the output.
make_user_friendly_and_stable_output () {
	sed \
		-e "s/$A/<COMMIT-A>/" \
		-e "s/$B/<COMMIT-B>/" \
		-e "s/$C/<COMMIT-C>/" \
		-e "s/$D/<COMMIT-D>/" \
		-e "s/$E/<COMMIT-E>/" \
		-e "s/$F/<COMMIT-F>/" \
		-e "s/$G/<COMMIT-G>/" \
		-e "s/$H/<COMMIT-H>/" \
		-e "s/$I/<COMMIT-I>/" \
		-e "s/$J/<COMMIT-J>/" \
		-e "s/$K/<COMMIT-K>/" \
		-e "s/$L/<COMMIT-L>/" \
		-e "s/$M/<COMMIT-M>/" \
		-e "s/$N/<COMMIT-N>/" \
		-e "s/$O/<COMMIT-O>/" \
		-e "s/$P/<COMMIT-P>/" \
		-e "s/$TAG1/<TAG-1>/" \
		-e "s/$TAG2/<TAG-2>/" \
		-e "s/$TAG3/<TAG-3>/" \
		-e "s/$(echo $A | cut -c1-7)[0-9a-f]*/<OID-A>/g" \
		-e "s/$(echo $B | cut -c1-7)[0-9a-f]*/<OID-B>/g" \
		-e "s/$(echo $C | cut -c1-7)[0-9a-f]*/<OID-C>/g" \
		-e "s/$(echo $D | cut -c1-7)[0-9a-f]*/<OID-D>/g" \
		-e "s/$(echo $E | cut -c1-7)[0-9a-f]*/<OID-E>/g" \
		-e "s/$(echo $F | cut -c1-7)[0-9a-f]*/<OID-F>/g" \
		-e "s/$(echo $G | cut -c1-7)[0-9a-f]*/<OID-G>/g" \
		-e "s/$(echo $H | cut -c1-7)[0-9a-f]*/<OID-H>/g" \
		-e "s/$(echo $I | cut -c1-7)[0-9a-f]*/<OID-I>/g" \
		-e "s/$(echo $J | cut -c1-7)[0-9a-f]*/<OID-J>/g" \
		-e "s/$(echo $K | cut -c1-7)[0-9a-f]*/<OID-K>/g" \
		-e "s/$(echo $L | cut -c1-7)[0-9a-f]*/<OID-L>/g" \
		-e "s/$(echo $M | cut -c1-7)[0-9a-f]*/<OID-M>/g" \
		-e "s/$(echo $N | cut -c1-7)[0-9a-f]*/<OID-N>/g" \
		-e "s/$(echo $O | cut -c1-7)[0-9a-f]*/<OID-O>/g" \
		-e "s/$(echo $P | cut -c1-7)[0-9a-f]*/<OID-P>/g" \
		-e "s/$(echo $TAG1 | cut -c1-7)[0-9a-f]*/<OID-TAG-1>/g" \
		-e "s/$(echo $TAG2 | cut -c1-7)[0-9a-f]*/<OID-TAG-2>/g" \
		-e "s/$(echo $TAG3 | cut -c1-7)[0-9a-f]*/<OID-TAG-3>/g" \
		-e "s/ *\$//"
}

#            (C)   (D, pull/1/head, topic/1)
#             o --- o
#            /       \                              (L)
#           /         \        o (H, topic/2)             (M, tag:v2)
#          /    (F)    \      /                                 (N, tag:v3)
#         /      o --------- o (G, pull/2/head)      o --- o --- o (release)
#        /      /        \    \                      /       \
#  o --- o --- o -------- o -- o ------------------ o ------- o --- o (main)
# (A)   (B)  (E, tag:v1) (I)  (J)                  (K)       (O)   (P)
#
test_expect_success 'setup' '
	# Try to make a stable fixed width for abbreviated commit ID,
	# this fixed-width oid will be replaced with "<OID>".
	git config core.abbrev 7 &&

	# branch main: commit A & B
	test_commit_setvar A "Commit A" main.txt &&
	test_commit_setvar B "Commit B" main.txt &&

	# branch topic/1: commit C & D, refs/pull/1/head
	git checkout -b topic/1 &&
	test_commit_setvar C "Commit C" topic-1.txt &&
	test_commit_setvar D "Commit D" topic-1.txt &&
	git update-ref refs/pull/1/head HEAD &&

	# branch topic/1: commit E, tag v1
	git checkout main &&
	test_commit_setvar E "Commit E" main.txt &&
	test_commit_setvar TAG1 --tag v1 &&

	# branch topic/2: commit F & G, refs/pull/2/head
	git checkout -b topic/2 &&
	test_commit_setvar F "Commit F" topic-2.txt &&
	test_commit_setvar G "Commit G" topic-2.txt &&
	git update-ref refs/pull/2/head HEAD &&
	test_commit_setvar H "Commit H" topic-2.txt &&

	# branch main: merge commit I & J
	git checkout main &&
	test_commit_setvar I --merge topic/1 "Merge commit I" &&
	test_commit_setvar J --merge refs/pull/2/head "Merge commit J" &&

	# branch main: commit K
	git checkout main &&
	test_commit_setvar K "Commit K" main.txt &&

	# branch release:
	git checkout -b release &&
	test_commit_setvar L "Commit L" release.txt &&
	test_commit_setvar M "Commit M" release.txt &&
	test_commit_setvar TAG2 --tag v2 &&
	test_commit_setvar N "Commit N" release.txt &&
	test_commit_setvar TAG3 --tag v3 &&

	# branch main: merge commit O, commit P
	git checkout main &&
	test_commit_setvar O --merge tags/v2 "Merge commit O" &&
	test_commit_setvar P "Commit P" main.txt
'

test_expect_success 'create bundle from special rev: main^!' '
	git bundle create special-rev.bdl "main^!" &&

	git bundle list-heads special-rev.bdl |
		make_user_friendly_and_stable_output >actual &&
	cat >expect <<-EOF &&
		<COMMIT-P> refs/heads/main
		EOF
	test_i18ncmp expect actual &&

	git bundle verify special-rev.bdl |
		make_user_friendly_and_stable_output >actual &&
	cat >expect <<-EOF &&
		The bundle contains this ref:
		<COMMIT-P> refs/heads/main
		The bundle requires this ref:
		<COMMIT-O>
		EOF
	test_i18ncmp expect actual &&

	test_bundle_object_count special-rev.bdl 3
'

test_expect_success 'create bundle with --max-count option' '
	git bundle create max-count.bdl --max-count 1 \
		main \
		"^release" \
		refs/tags/v1 \
		refs/pull/1/head \
		refs/pull/2/head &&

	git bundle list-heads max-count.bdl |
		make_user_friendly_and_stable_output >actual &&
	cat >expect <<-EOF &&
		<COMMIT-P> refs/heads/main
		<TAG-1> refs/tags/v1
		EOF
	test_i18ncmp expect actual &&

	git bundle verify max-count.bdl |
		make_user_friendly_and_stable_output >actual &&
	cat >expect <<-EOF &&
		The bundle contains these 2 refs:
		<COMMIT-P> refs/heads/main
		<TAG-1> refs/tags/v1
		The bundle requires this ref:
		<COMMIT-O>
		EOF
	test_i18ncmp expect actual &&

	test_bundle_object_count max-count.bdl 4
'

test_expect_success 'create bundle with --since option' '
	since="Thu Apr 7 15:26:13 2005 -0700" &&
	git log -1 --pretty="%ad" $M >actual &&
	echo "$since" >expect &&
	test_cmp expect actual &&

	git bundle create since.bdl \
		--since "$since" --all &&

	git bundle list-heads since.bdl |
		make_user_friendly_and_stable_output >actual &&
	cat >expect <<-EOF &&
		<COMMIT-P> refs/heads/main
		<COMMIT-N> refs/heads/release
		<TAG-2> refs/tags/v2
		<TAG-3> refs/tags/v3
		<COMMIT-P> HEAD
		EOF
	test_i18ncmp expect actual &&

	git bundle verify since.bdl |
		make_user_friendly_and_stable_output >actual &&
	cat >expect <<-EOF &&
		The bundle contains these 5 refs:
		<COMMIT-P> refs/heads/main
		<COMMIT-N> refs/heads/release
		<TAG-2> refs/tags/v2
		<TAG-3> refs/tags/v3
		<COMMIT-P> HEAD
		The bundle requires these 2 refs:
		<COMMIT-L>
		<COMMIT-K>
		EOF
	test_i18ncmp expect actual &&

	test_bundle_object_count --thin since.bdl 16
'

test_expect_success 'create bundle 1 - no prerequisites' '
	git bundle create 1.bdl topic/1 topic/2 &&

	cat >expect <<-EOF &&
		The bundle contains these 2 refs:
		<COMMIT-D> refs/heads/topic/1
		<COMMIT-H> refs/heads/topic/2
		The bundle records a complete history.
		EOF

	# verify bundle, which has no prerequisites
	git bundle verify 1.bdl |
		make_user_friendly_and_stable_output >actual &&
	test_i18ncmp expect actual &&

	test_bundle_object_count 1.bdl 24
'

test_expect_success 'create bundle 2 - has prerequisites' '
	git bundle create 2.bdl \
		--ignore-missing \
		^topic/deleted \
		^$D \
		^topic/2 \
		release &&

	cat >expect <<-EOF &&
		The bundle contains this ref:
		<COMMIT-N> refs/heads/release
		The bundle requires these 3 refs:
		<COMMIT-D>
		<COMMIT-E>
		<COMMIT-G>
		EOF

	git bundle verify 2.bdl |
		make_user_friendly_and_stable_output >actual &&
	test_i18ncmp expect actual &&

	test_bundle_object_count 2.bdl 16
'

test_expect_success 'fail to verify bundle without prerequisites' '
	git init --bare test1.git &&

	cat >expect <<-EOF &&
		error: Repository lacks these prerequisite commits:
		error: <COMMIT-D>
		error: <COMMIT-E>
		error: <COMMIT-G>
		EOF

	test_must_fail git -C test1.git bundle verify ../2.bdl 2>&1 |
		make_user_friendly_and_stable_output >actual &&
	test_i18ncmp expect actual
'

test_expect_success 'create bundle 3 - two refs, same object' '
	git bundle create --version=3 3.bdl \
		^release \
		^topic/1 \
		^topic/2 \
		main \
		HEAD &&

	cat >expect <<-EOF &&
		The bundle contains these 2 refs:
		<COMMIT-P> refs/heads/main
		<COMMIT-P> HEAD
		The bundle requires these 2 refs:
		<COMMIT-M>
		<COMMIT-K>
		EOF

	git bundle verify 3.bdl |
		make_user_friendly_and_stable_output >actual &&
	test_i18ncmp expect actual &&

	test_bundle_object_count 3.bdl 4
'

test_expect_success 'create bundle 4 - with tags' '
	git bundle create 4.bdl \
		^main \
		^release \
		^topic/1 \
		^topic/2 \
		--all &&

	cat >expect <<-EOF &&
		The bundle contains these 3 refs:
		<TAG-1> refs/tags/v1
		<TAG-2> refs/tags/v2
		<TAG-3> refs/tags/v3
		The bundle records a complete history.
		EOF

	git bundle verify 4.bdl |
		make_user_friendly_and_stable_output >actual &&
	test_i18ncmp expect actual &&

	test_bundle_object_count 4.bdl 3
'

test_expect_success 'clone from bundle' '
	git clone --mirror 1.bdl mirror.git &&
	git -C mirror.git show-ref |
		make_user_friendly_and_stable_output >actual &&
	cat >expect <<-EOF &&
		<COMMIT-D> refs/heads/topic/1
		<COMMIT-H> refs/heads/topic/2
		EOF
	test_cmp expect actual &&

	git -C mirror.git fetch ../2.bdl "+refs/*:refs/*" &&
	git -C mirror.git show-ref |
		make_user_friendly_and_stable_output >actual &&
	cat >expect <<-EOF &&
		<COMMIT-N> refs/heads/release
		<COMMIT-D> refs/heads/topic/1
		<COMMIT-H> refs/heads/topic/2
		EOF
	test_cmp expect actual &&

	git -C mirror.git fetch ../3.bdl "+refs/*:refs/*" &&
	git -C mirror.git show-ref |
		make_user_friendly_and_stable_output >actual &&
	cat >expect <<-EOF &&
		<COMMIT-P> refs/heads/main
		<COMMIT-N> refs/heads/release
		<COMMIT-D> refs/heads/topic/1
		<COMMIT-H> refs/heads/topic/2
		EOF
	test_cmp expect actual &&

	git -C mirror.git fetch ../4.bdl "+refs/*:refs/*" &&
	git -C mirror.git show-ref |
		make_user_friendly_and_stable_output >actual &&
	cat >expect <<-EOF &&
		<COMMIT-P> refs/heads/main
		<COMMIT-N> refs/heads/release
		<COMMIT-D> refs/heads/topic/1
		<COMMIT-H> refs/heads/topic/2
		<TAG-1> refs/tags/v1
		<TAG-2> refs/tags/v2
		<TAG-3> refs/tags/v3
		EOF
	test_cmp expect actual
'

test_done
