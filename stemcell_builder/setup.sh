export DISTRIB_CODENAME=trusty
export stemcell_operating_system=ubuntu
export stemcell_operating_system_version=14.04
export base_debootstrap_arch=x86_64
export bosh_users_password=Lasciapassare02

# Traces on file and on screen the received arguments plus an initial timestamp.
function log() {
    echo "$(date '+%F %T') $@" | tee -a $LOGFILE
}

# Trace (INFO level) on file and on screen the received arguments plus an initial timestamp and the level.
function logInfo() {
    log "INFO: $@"
}

# Trace (WARNING level) on file and on screen the received arguments plus an initial timestamp and the level.
function logWarning() {
    log "WARNING: $@"
}

# Trace (ERROR level) on file and on screen the received arguments plus an initial timestamp and the level.
function logError() {
    log "ERROR: $@"
}

# Trace (ERROR level) on file and on screen the received arguments plus an initial timestamp and the level.
# This is equivalent to a call to logError followed by exit 1.
function logFailure() {
    logError $@
    exit 1
}

function preset_env {
    if [ $UID -ne 0 ]; then
        echo 'You MUST BE root to run this script!'
        exit 1
    fi

    export PROJECT_DIR=$(readlink -f $(dirname $0))
    echo "PROJECT_DIR=$PROJECT_DIR"
    #export ASSETS_DIR=${PROJECT_DIR}/assets
    #export BIN_DIR=${PROJECT_DIR}/bin
    #export LIB_DIR=${BIN_DIR}/lib
    export STAGES_DIR=${PROJECT_DIR}/stages
    echo "STAGES_DIR=$STAGES_DIR"
    #export CONFIG_DIR=${PROJECT_DIR}/config
    #export UTILS_SCRIPT=${LIB_DIR}/utils.sh
    #export VCAP_DIR=/var/vcap
    #export DATA_DIR=${VCAP_DIR}/data
    #export BOSH_DIR=${VCAP_DIR}/bosh
    #export LOGFILE=/$(mktemp --tmpdir=/var/log baremetal_setup_XXXXX.log)
    #export JOBDATADIR=/var/vcap/data/jobs
    #export PKGDATADIR=/var/vcap/data/packages
    #export JOBDIR=/var/vcap/jobs
    #export PACKAGEDIR=/var/vcap/packages
}

# Execute a single script in stages; in case of failure main execution is aborted with an exit.
function doConfigureStage() {
    local STAGE_NAME=$1
    local STAGE_SCRIPT=${STAGES_DIR}/${STAGE_NAME}/config.sh

    shift
    logInfo "Executing stage $STAGE_NAME"
    if [ ! -f $STAGE_SCRIPT ]; then
        logInfo "No configuration required for $STAGE_NAME"
        return
    fi

    if [ ! -x $STAGE_SCRIPT ]; then
        logFailure "$STAGE_NAME/config,sh have no execution permissions"
    fi

    $STAGE_SCRIPT $* || logFailure "Execution failure during stage ${STAGE_NAME}"
    logInfo "Execution of $STAGE_NAME COMPLETED!"
}

# Execute a single script in stages; in case of failure main execution is aborted with an exit.
function doStage() {
    local STAGE_NAME=$1
    local STAGE_SCRIPT=${STAGES_DIR}/${STAGE_NAME}/apply.sh

    shift
    logInfo "Executing stage $STAGE_NAME"
    if [ ! -f $STAGE_SCRIPT ]; then
        logFailure "$STAGE_SCRIPT script not found"
    fi

    if [ ! -x $STAGE_SCRIPT ]; then
        logFailure "$STAGE_SCRIPT have no execution permissions"
    fi

    $STAGE_SCRIPT $* || logFailure "Execution failure during stage ${STAGE_NAME}"
    logInfo "Execution of $STAGE_NAME COMPLETED!"
}

# preload environment variables
preset_env

STAGES=(
    base_debootstrap
    base_ubuntu_firstboot
    base_apt
    base_ubuntu_build_essential
    base_ubuntu_packages
    base_file_permission
    base_ssh
    bosh_sysstat
    system_kernel
    system_kernel_modules
    system_ixgbevf
    password_policies
    restrict_su_command
    tty_config
    rsyslog_config
    make_rootdir_rprivate,
    delay_monit_start
    system_grub
    vim_tiny
    cron_config
    escape_ctrl_alt_del
    system_users
    bosh_audit_ubuntu
    bosh_log_audit_start
)

touch /etc/init.d/idmapd
touch /etc/init.d/gssd
touch /etc/init.d/statd

# Execute installation steps in the order they are provided
for (( I = 0; I < ${#STAGES[@]}; I++ )); do
    doConfigureStage ${STAGES[$I]}
done

# Execute installation steps in the order they are provided
for (( I = 0; I < ${#STAGES[@]}; I++ )); do
    doStage ${STAGES[$I]}
done
