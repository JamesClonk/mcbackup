#!/bin/bash

# fail on error
set -e

# trace shell
set -x

# =============================================================================================
function retry() {
	local -r -i max_attempts="$1"; shift
	local -r -i sleep_time="$1"; shift
	local -i attempt_num=1
	until "$@"; do
		if (( attempt_num == max_attempts ))
	then
		echo "#$attempt_num failures!"
		exit 1
	else
		echo "#$(( attempt_num++ )): trying again in $sleep_time seconds ..."
		sleep $sleep_time
		fi
	done
}

# =============================================================================================
# check for env vars
set +x
if [[ -z "${RCON_HOST}" ]]; then
	echo "RCON_HOST is missing"
	exit 1
fi
if [[ -z "${RCON_PORT}" ]]; then
	echo "RCON_PORT is missing"
	exit 1
fi
if [[ -z "${RCON_PASSWORD}" ]]; then
	echo "RCON_PASSWORD is missing"
	exit 1
fi
if [[ -z "${RCON_WORLDPATH}" ]]; then
	echo "RCON_WORLDPATH is missing"
	exit 1
fi
if [[ -z "${RCON_SAVEPATH}" ]]; then
	echo "RCON_SAVEPATH is missing"
	exit 1
fi
if [[ -z "${FILE_RETENTION}" ]]; then
	echo "FILE_RETENTION is missing"
	exit 1
fi
if [[ -z "${S3_UPLOAD_ENABLED}" ]]; then
	echo "S3_UPLOAD_ENABLED is missing"
	exit 1
fi
if [[ "${S3_UPLOAD_ENABLED}" == "true" ]]; then
	if [[ -z "${S3_ACCESS_KEY}" ]]; then
		echo "S3_ACCESS_KEY is missing"
		exit 1
	fi
	if [[ -z "${S3_SECRET_KEY}" ]]; then
		echo "S3_SECRET_KEY is missing"
		exit 1
	fi
	if [[ -z "${S3_ENDPOINT}" ]]; then
		echo "S3_ENDPOINT is missing"
		exit 1
	fi
	if [[ -z "${S3_BUCKET}" ]]; then
		echo "S3_BUCKET is missing"
		exit 1
	fi
	if [[ -z "${S3_RETENTION}" ]]; then
		echo "S3_RETENTION is missing"
		exit 1
	fi
fi
set -x


# =============================================================================================
echo "waiting on minecraft server ..."
retry 5 5 rcon-cli say "mcbackup here, preparing to backup world ..."
echo "minecraft server is up!"

# =============================================================================================
# backup minecraft world
mkdir -p "${RCON_SAVEPATH}" || true
TIMESTAMP=$(date "+%Y%m%d%H%M%S")
BACKUPFILE="${RCON_SAVEPATH}/${TIMESTAMP}.tar.gz"

# create backup
rcon-cli save-off
sleep 5
rcon-cli save-all
sleep 60
retry 5 15 tar -cvzf "${BACKUPFILE}" "${RCON_WORLDPATH}"
rcon-cli save-on
rcon-cli say "backup complete!"

# file retention policy
ls -dt ${RCON_SAVEPATH}/* | tail -n +${FILE_RETENTION} | xargs -d '\n' -r rm --

if [[ "${S3_UPLOAD_ENABLED}" == "true" ]]; then
	# upload to s3
	set +x
	mc alias set s3 "${S3_ENDPOINT}" "${S3_ACCESS_KEY}" "${S3_SECRET_KEY}" --api S3v4 || true
	set -x
	mc mb --ignore-existing "s3/${S3_BUCKET}"
	S3_FILENAME=$(basename "${BACKUPFILE}")
	mc cp "${BACKUPFILE}" "s3/${S3_BUCKET}/mcbackup/${S3_FILENAME}"

	# s3 retention policy
	mc rm --recursive --force --older-than "${S3_RETENTION}" "s3/${S3_BUCKET}/mcbackup/"
fi

exit 0
