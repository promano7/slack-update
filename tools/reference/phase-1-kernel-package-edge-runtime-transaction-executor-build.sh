#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

readonly EXPECTED_REFERENCE_SHA256='1014658196f384b29756827b9074fb0393aeaaf82dad857ff4da91762d9ca415'
readonly EXPECTED_CONFIG_SHA256='4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba'
readonly EXPECTED_BODY_SHA256='47fc2b067ac361562fc2921bf6df5b66bc4054456cea88297b9a53fb96514581'
readonly EXPECTED_FQDN='vbox-slackcurrent.vbox-slackcurrent.org'
readonly EXPECTED_KERNEL='6.18.45'
readonly EXPECTED_BOOT_ID='91901677-1dc3-4a39-a4b1-3f87e6875234'
readonly EXPECTED_PACKAGE_DATABASE_MANIFEST_SHA256='726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6'
readonly EXPECTED_SLACKPKG_CONF_SHA256='f1584eec58ed92c30d4514977ef7bb0a334fb9c54f2f5f47059fbefc877fe7a4'
readonly EXPECTED_SLACKPKG_MIRRORS_SHA256='71f0e8113d5cd8b7a84b92153ce7767ee4d708e8b26b225dc4aaafe15deebf12'
readonly EXPECTED_KERNEL_GENERIC_RECORD='kernel-generic-6.18.45-x86_64-1'
readonly PREDECESSOR_ARTIFACT='kernel-headers-6.18.44-x86-1.txz'
readonly PREDECESSOR_RECORD='kernel-headers-6.18.44-x86-1'
readonly PREDECESSOR_SHA256='3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d'
readonly PREDECESSOR_TRANSPORT='/home/promano/Descargas/kernel-headers-6.18.44-x86-1.txz'
readonly TARGET_ARTIFACT='kernel-headers-6.18.45-x86-1.txz'
readonly TARGET_RECORD='kernel-headers-6.18.45-x86-1'
readonly TARGET_SHA256='c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c'
readonly STAGED_TARGET='/var/tmp/slack-update-acceptance/kernel-package-edge/staging-input/kernel-headers-6.18.45-x86-1.txz'
readonly LOCAL_SOURCE_ROOT='/var/tmp/slack-update-acceptance/kernel-package-edge/local-source'
readonly LOCAL_SOURCE_URI='file:///var/tmp/slack-update-acceptance/kernel-package-edge/local-source/'
readonly TREE_MANIFEST='/var/tmp/slack-update-acceptance/kernel-package-edge/local-source.tree.sha256'
readonly EXPECTED_TREE_MANIFEST_SHA256='0a47285c0503565263e64369e2a3816e8fdfd34e18a0f5e25eb53ee378082e4e'
readonly EVIDENCE_ROOT='/var/tmp/slack-update-acceptance/kernel-package-edge/runtime-transaction'
readonly PUBLISHED_ARCHIVE='/home/promano/slack-update-phase-1-kernel-package-edge-runtime-evidence.tar.gz'
readonly PUBLISHED_SHA256='/home/promano/slack-update-phase-1-kernel-package-edge-runtime-evidence.tar.gz.sha256'

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-executor-build.sh \
       --repo-root REPO_ROOT --output OUTPUT

Build the reviewed standalone kernel-package-edge runtime transaction executor
from the exact frozen reference script, effective configuration, and reviewed
executor body. This command contacts no network and performs no package,
Slackpkg, boot, or reboot action.
USAGE
}

repo_root=
output=
while (($#)); do
    case "$1" in
        --repo-root)
            [[ $# -ge 2 ]] || { printf 'ERROR: --repo-root requires a value\n' >&2; exit 2; }
            repo_root=$2
            shift 2
            ;;
        --output)
            [[ $# -ge 2 ]] || { printf 'ERROR: --output requires a value\n' >&2; exit 2; }
            output=$2
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            printf 'ERROR: unknown option: %s\n' "$1" >&2
            exit 2
            ;;
    esac
done

[[ -n $repo_root && -n $output ]] || { usage >&2; exit 2; }
repo_root=$(CDPATH= cd -- "$repo_root" && pwd -P)
reference="$repo_root/tools/reference/slack-update-reference.sh"
config="$repo_root/data/config/slack-update.conf"
body="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-body.sh"
for path in "$reference" "$config" "$body"; do
    [[ -f $path && ! -L $path ]] || { printf 'ERROR: required frozen input is missing or unsafe: %s\n' "$path" >&2; exit 3; }
done
check_sha() {
    local path=$1 expected=$2 actual
    actual=$(sha256sum -- "$path" | awk '{print $1}')
    [[ $actual == "$expected" ]] || {
        printf 'ERROR: frozen input SHA-256 drift: %s\nexpected: %s\nactual:   %s\n' "$path" "$expected" "$actual" >&2
        exit 4
    }
}
check_sha "$reference" "$EXPECTED_REFERENCE_SHA256"
check_sha "$config" "$EXPECTED_CONFIG_SHA256"
check_sha "$body" "$EXPECTED_BODY_SHA256"

output_dir=$(dirname -- "$output")
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }
tmp=$(mktemp "$output_dir/.runtime-transaction-executor.XXXXXX")
trap 'rm -f -- "$tmp"' EXIT

cat > "$tmp" <<'HEADER'
#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
HEADER
cat >> "$tmp" <<EOF_CONSTANTS
readonly EXPECTED_FQDN='$EXPECTED_FQDN'
readonly EXPECTED_KERNEL='$EXPECTED_KERNEL'
readonly EXPECTED_BOOT_ID='$EXPECTED_BOOT_ID'
readonly EXPECTED_PACKAGE_DATABASE_MANIFEST_SHA256='$EXPECTED_PACKAGE_DATABASE_MANIFEST_SHA256'
readonly EXPECTED_SLACKPKG_CONF_SHA256='$EXPECTED_SLACKPKG_CONF_SHA256'
readonly EXPECTED_SLACKPKG_MIRRORS_SHA256='$EXPECTED_SLACKPKG_MIRRORS_SHA256'
readonly EXPECTED_KERNEL_GENERIC_RECORD='$EXPECTED_KERNEL_GENERIC_RECORD'
readonly EMBEDDED_REFERENCE_SHA256='$EXPECTED_REFERENCE_SHA256'
readonly EMBEDDED_CONFIG_SHA256='$EXPECTED_CONFIG_SHA256'
readonly PREDECESSOR_ARTIFACT='$PREDECESSOR_ARTIFACT'
readonly PREDECESSOR_RECORD='$PREDECESSOR_RECORD'
readonly PREDECESSOR_SHA256='$PREDECESSOR_SHA256'
readonly PREDECESSOR_TRANSPORT='$PREDECESSOR_TRANSPORT'
readonly TARGET_ARTIFACT='$TARGET_ARTIFACT'
readonly TARGET_RECORD='$TARGET_RECORD'
readonly TARGET_SHA256='$TARGET_SHA256'
readonly STAGED_TARGET='$STAGED_TARGET'
readonly LOCAL_SOURCE_ROOT='$LOCAL_SOURCE_ROOT'
readonly LOCAL_SOURCE_URI='$LOCAL_SOURCE_URI'
readonly TREE_MANIFEST='$TREE_MANIFEST'
readonly EXPECTED_TREE_MANIFEST_SHA256='$EXPECTED_TREE_MANIFEST_SHA256'
readonly EVIDENCE_ROOT='$EVIDENCE_ROOT'
readonly PUBLISHED_ARCHIVE='$PUBLISHED_ARCHIVE'
readonly PUBLISHED_SHA256='$PUBLISHED_SHA256'
EOF_CONSTANTS
cat -- "$body" >> "$tmp"
base64 --wrap=76 -- "$reference" >> "$tmp"
printf '__SLACK_UPDATE_REFERENCE_PAYLOAD_END__\n' >> "$tmp"
printf '__SLACK_UPDATE_CONFIG_PAYLOAD_BEGIN__\n' >> "$tmp"
base64 --wrap=76 -- "$config" >> "$tmp"
printf '__SLACK_UPDATE_CONFIG_PAYLOAD_END__\n' >> "$tmp"
chmod 0755 -- "$tmp"
bash -n "$tmp"
mv -f -- "$tmp" "$output"
trap - EXIT
printf 'Built %s\n' "$output"
printf 'executor_sha256\t%s\n' "$(sha256sum -- "$output" | awk '{print $1}')"
