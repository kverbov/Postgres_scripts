#!/bin/bash
set -euo pipefail 

function get_pg_dump {
	podman run \
		--name pg_dump \
		--rm \
		-ti \
		-e "PGHOST=${PGHOST}" \
		-e "PGDATABASE=${PGDATABASE}" \
		-e "PGUSER=${PGUSER}" \
		-e "PGPASSWORD=${PGPASSWORD}" \
		-e "PGPORT=${PGPORT}" \
		-v "${BPATH}":/data \
		"${POSTGRES_DOCKER_IMG}" \
		/bin/bash -c \
			"pg_dump -bFc > /data/${DUMP_NAME}"
		
	echo 'PG dump complete:' $(ls ${BPATH}/${DUMP_NAME}) $(du -h ${BPATH}/${DUMP_NAME}| cut -f1)
}

function get_pg_roles_dump {
    podman run \
        --name pg_dump \
        --rm \
        -ti \
        -e "PGHOST=${PGHOST}" \
        -e "PGDATABASE=${PGDATABASE}" \
        -e "PGUSER=${PGUSER}" \
        -e "PGPASSWORD=${PGPASSWORD}" \
        -e "PGPORT=${PGPORT}" \
        -v "${BPATH}":/data \
        "${POSTGRES_DOCKER_IMG}" \
        /bin/bash -c \
            "pg_dumpall --roles-only > /data/roles_${DUMP_NAME}"

    echo 'PG dump complete:' $(ls ${BPATH}/roles_${DUMP_NAME}) $(du -h ${BPATH}/roles_${DUMP_NAME}| cut -f1)
}

function delete_old_dumps {
	find ${BPATH} -ctime +7 -delete
}

function drop_all_db_on_cert {
    podman run \
        --name pg_restore_on_cert \
        --rm \
        -ti \
        -e "PGHOST=${PGHOST_CERT}" \
        -e "PGDATABASE=${PGDATABASE}" \
        -e "PGUSER=${PGUSER}" \
        -e "PGPASSWORD=${PGPASSWORD}" \
        -e "PGPORT=${PGPORT}" \
        -v "${BPATH}":/data \
        "${POSTGRES_DOCKER_IMG}" \
        /bin/bash -c \
			"echo 'DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA public;' | psql -U ${PGUSER}"
}

function restore_dump_on_cert {
    podman run \
        --name pg_restore_on_cert \
        --rm \
        -ti \
        -e "PGHOST=${PGHOST_CERT}" \
        -e "PGDATABASE=${PGDATABASE}" \
        -e "PGUSER=${PGUSER}" \
        -e "PGPASSWORD=${PGPASSWORD}" \
        -e "PGPORT=${PGPORT}" \
        -v "${BPATH}":/data \
        "${POSTGRES_DOCKER_IMG}" \
        /bin/bash -c \
            "pg_restore -d ${PGDATABASE} --clean /data/${DUMP_NAME}"	

	echo 'PG restore complete'
}

function restore_roles_dump_on_cert {
    podman run \
        --name pg_restore_on_cert \
        --rm \
        -ti \
        -e "PGHOST=${PGHOST_CERT}" \
        -e "PGDATABASE=${PGDATABASE}" \
        -e "PGUSER=${PGUSER}" \
        -e "PGPASSWORD=${PGPASSWORD}" \
        -e "PGPORT=${PGPORT}" \
        -v "${BPATH}":/data \
        "${POSTGRES_DOCKER_IMG}" \
        /bin/bash -c \
            "psql -U ${PGUSER} -f /data/roles_${DUMP_NAME}"
    echo 'PG restore complete'
}

function main {
	local POSTGRES_DOCKER_IMG="nexus.DOMAIN/general/postgres:14.1"
	local BPATH=/media/department_backups/
	local PGHOST="db1.prod.department.DOMAIN"
	local PGHOST_CERT="db1.cert.department.DOMAIN"
	local PGDATABASE=bank
	local PGUSER=bank
	local PGPASSWORD=""
	local PGPORT=5432
	local DUMP_NAME=${PGDATABASE}_$(date "+%Y-%m-%d_%H.%M").dump
	#local DUMP_NAME="bank_2022-07-24_01.17.dump"

	get_pg_dump
	get_pg_roles_dump
	delete_old_dumps
	#drop_all_db_on_cert
	#restore_roles_dump_on_cert
	#restore_dump_on_cert
	
}

main
